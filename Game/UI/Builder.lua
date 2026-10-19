local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
--- Автогенерация строк настроек из flat-описаний (порт Config/Builder из CharacterStats).
local Builder = {}
LPS.UI = LPS.UI or {}
LPS.UI.Builder = Builder
local CS = LPS.UI
CS.ConfigBuilder = Builder
local ROW_GAP = 4
local SECTION_GAP = 14
local COLUMN_GAP = 16
local ROW_HEIGHTS = {
    header = 18,
    slider = 22,
    dropdown = 22,
    toggle = 20,
    color = 20,
    button = 24,
    label = 16,
    input = 24,
}
--- Строка обязана занять всю ширину страницы (слайдер/dropdown/input слева+справа).
local function NeedsFullRow(entry)
    return entry.fullRow == true or entry.kind == "slider"
        or entry.kind == "dropdown" or entry.kind == "input"
end
--- Двухколоночная сетка: строки распределяются по колонкам как в CharacterStats.
--- Если у записи задана column ("left"/"right"), она всегда идёт в эту колонку;
--- иначе включается в балансировку. Заголовок секции начинает новый блок:
--- он занимает всю ширину, а его группа коротких строк раскладывается по
--- обеим колонкам (как inline-группа в дереве настроек CharacterStats).
local function SplitColumns(entries)
    local left, right = {}, {}
    local hL, hR = 0, 0
    local function push(col, entry, h)
        col[#col + 1] = { entry = entry, height = h }
        return h + ROW_GAP
    end
    local i = 1
    while i <= #entries do
        local entry = entries[i]
        local h = (ROW_HEIGHTS[entry.kind] or 20)
        if entry.multiline then h = entry.rowHeight or 100 end
        local forced = entry.column
        if entry.kind == "header" then
            -- заголовок на всю ширину
            local target = forced == "right" and right or left
            if target == left then hL = hL + push(target, entry, h) else hR = hR + push(target, entry, h) end
            i = i + 1
            -- группа строк до следующего заголовка: balance или left/right-колонки
            local group = {}
            while i <= #entries and entries[i].kind ~= "header" and not NeedsFullRow(entries[i]) and not entries[i].column do
                group[#group + 1] = entries[i]
                i = i + 1
            end
            for _, e in ipairs(group) do
                local eh = (ROW_HEIGHTS[e.kind] or 20)
                if hL <= hR then hL = hL + push(left, e, eh) else hR = hR + push(right, e, eh) end
            end
        elseif forced == "left" or forced == "right" then
            local col = (forced == "left") and left or right
            if col == left then hL = hL + push(col, entry, h) else hR = hR + push(col, entry, h) end
            i = i + 1
        elseif NeedsFullRow(entry) then
            -- широкая строка: целиком в более высокую колонку? нет — как в CS:
            -- full-row строки идут в левую колонку, занимая её всю ширину только
            -- если правая пуста; иначе балансируем по высоте колонок.
            if hL <= hR then hL = hL + push(left, entry, h) else hR = hR + push(right, entry, h) end
            i = i + 1
        else
            -- одиночные короткие строки вне группы: в более высокую колонку
            if hL <= hR then hL = hL + push(left, entry, h) else hR = hR + push(right, entry, h) end
            i = i + 1
        end
    end
    return left, right
end
local DISABLED_TEXT = { r = 0.4, g = 0.4, b = 0.4 }
local function GetDB()
    return LPS:GetDB() or {}
end
--- Чтение значения: через entry.get (путь в БД задаёт options.lua), иначе по entry.key.
local function ReadValue(entry, db)
    if entry.get then
        return entry.get()
    end
    if entry.key then
        local v = db[entry.key]
        if v == nil then v = entry.default end
        return v
    end
end
--- Запись значения: через entry.set (путь в БД задаёт options.lua), иначе по entry.key.
local function WriteValue(entry, value)
    if not LPS:GetDB() then return end
    if entry.set then
        entry.set(value)
    elseif entry.key then
        LPS.Options:SetByPath(entry.key, value)
    end
end
local function ResolveItems(entry)
    if type(entry.items) == "function" then
        return entry.items()
    end
    return entry.items or {}
end
local function TextForValue(items, value)
    for _, item in ipairs(items) do
        if item.value == value then
            return item.text
        end
    end
    return value ~= nil and tostring(value) or ""
end
local function SetLabelEnabled(label, enabled)
    if not label then return end
    if enabled then
        CS.ConfigWidgets.ApplyFontColor(label, "textMuted")
    else
        label:SetTextColor(DISABLED_TEXT.r, DISABLED_TEXT.g, DISABLED_TEXT.b)
    end
end
local function CreateRowLabel(row, text)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    CS.ConfigWidgets.ApplyFontColor(label, "textMuted")
    return label
end
local function SetRowTooltip(row, entry)
    if not (entry.tooltip or entry.desc) then return end
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if entry.label and entry.label ~= "" and entry.label ~= " " then
            GameTooltip:AddLine(entry.label, 1, 1, 1)
        end
        GameTooltip:AddLine((entry.tooltip or entry.desc), nil, nil, nil, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
--- Подбирает тему шрифта многострочного label'а по содержимому: заголовки
--- секций (без цвета/переносов строк) — heading, остальное — обычный текст.
local function ApplyLabelRole(text, str)
    if str:find("\n") or str:find("|c") then
        text.themeRole = "body"
    else
        text.themeRole = "heading"
    end
end
--- Многострочный description (About-тексты): высота считается по строкам,
--- иначе метка с \n обрезается фиксированной высотой строки 16px.
local function BuildMultilineLabel(row, entry)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    text:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    local str = tostring(entry.label or "")
    ApplyLabelRole(text, str)
    text:SetText(str)
    CS.ConfigWidgets.ApplyFontColor(text, "textMuted")
    -- верхняя оценка высоты; точная (с переносом слов) — в RelayoutMultiline
    local lines = 1 + select(2, str:gsub("\n", ""))
    local height = math.max(16, lines * 15 + 4)
    row:SetHeight(height)
    entry.rowHeight = height
    return { entry = entry, row = row, text = text, multiline = true }
end
--- Точный пересчёт высоты многострочной метки после применения темы шрифта.
local function RelayoutMultiline(control)
    if not control.multiline then return end
    local text, row, entry = control.text, control.row, control.entry
    if not text or not row then return end
    local h = math.max(16, (text:GetStringHeight() or 0) + 4)
    if h ~= entry.rowHeight then
        entry.rowHeight = h
        row:SetHeight(h)
    end
end
local function BuildControl(page, entry, row)
    local Widgets = CS.ConfigWidgets
    if entry.available then
        local ok, v = pcall(entry.available)
        if ok and v == false then
            row:Hide()
            return { entry = entry, row = row, hidden = true }
        end
    end
    local control = { entry = entry, row = row }
    local kind = entry.kind
    if kind == "header" then
        control.header = Widgets.CreateSectionHeader(row, entry.label)
        control.header:SetAllPoints(row)
    elseif kind == "label" then
        if entry.multiline then
            return BuildMultilineLabel(row, entry)
        end
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 0, 0)
        text:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
        text:SetText(entry.label or "")
        CS.ConfigWidgets.ApplyFontColor(text, "textMuted")
        control.text = text
    elseif kind == "button" then
        -- ширина по тексту, чтобы подпись кнопки не залезала за края
        local probe = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        probe:SetText(entry.label or "")
        local textWidth = probe:GetStringWidth() or 0
        probe:Freeze()
        probe:SetParent(nil)
        local btn = Widgets.CreateFlatButton(row, math.max(90, textWidth + 24), ROW_HEIGHTS.button, entry.label)
        btn:SetPoint("LEFT", row, "LEFT", 0, 0)
        btn:SetScript("OnClick", function()
            if entry.func then entry.func() end
        end)
        control.button = btn
    elseif kind == "toggle" then
        local toggle = Widgets.CreateToggle(row, entry.label)
        toggle:SetPoint("LEFT", row, "LEFT", 0, 0)
        toggle:SetOnClick(function(self)
            WriteValue(entry, self:GetChecked())
            page:OnValueChanged(entry, self:GetChecked())
        end)
        control.toggle = toggle
    elseif kind == "slider" then
        control.label = CreateRowLabel(row, entry.label)
        local slider = Widgets.CreateSlider(row, {
            min = entry.min,
            max = entry.max,
            step = entry.step,
            format = entry.format,
            formatValue = entry.formatValue,
            value = entry.min,
            commitOnRelease = entry.commitOnRelease,
            onChange = function(val)
                WriteValue(entry, val)
                page:OnValueChanged(entry, val)
            end,
        })
        slider:ClearAllPoints()
        slider:SetPoint("LEFT", row, "CENTER", 8, 0)
        slider:SetPoint("RIGHT", row, "RIGHT", -48, 0)
        slider:SetHeight(12)
        slider.track:ClearAllPoints()
        slider.track:SetPoint("LEFT", slider, "LEFT", 0, 0)
        slider.track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        slider.valueText:ClearAllPoints()
        slider.valueText:SetPoint("LEFT", slider.track, "RIGHT", 8, 0)
        slider.valueText:SetWidth(40)
        slider.valueText:SetJustifyH("LEFT")
        control.slider = slider
    elseif kind == "dropdown" then
        control.label = CreateRowLabel(row, entry.label)
        local _, dropdown = Widgets.CreateDropdown(row, "", 150, { fixedWidth = true })
        dropdown:ClearAllPoints()
        dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
        dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        dropdown:SetHeight(ROW_HEIGHTS.dropdown)
        dropdown:SetItems(ResolveItems(entry))
        dropdown:SetOnChange(function(value)
            WriteValue(entry, value)
            page:OnValueChanged(entry, value)
        end)
        control.dropdown = dropdown
    elseif kind == "color" then
        control.label = CreateRowLabel(row, entry.label)
        local swatch = Widgets.CreateSwatch(row)
        swatch:SetPoint("LEFT", row, "CENTER", 8, 0)
        swatch:SetScript("OnClick", function()
            local db = GetDB()
            local c = ReadValue(entry, db) or { r = 1, g = 1, b = 1 }
            Widgets.OpenColorPicker(c.r or 1, c.g or 1, c.b or 1, function(r, g, b)
                WriteValue(entry, { r = r, g = g, b = b })
                page:OnValueChanged(entry)
            end, function(r, g, b)
                WriteValue(entry, { r = r, g = g, b = b })
                page:OnValueChanged(entry)
            end)
        end)
        control.swatch = swatch
    elseif kind == "input" then
        control.label = CreateRowLabel(row, entry.label)
        local edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        edit:SetAutoFocus(false)
        edit:ClearAllPoints()
        if entry.multiline then
            -- многострочное поле: метка сверху, поле на всю ширину строки
            row:SetHeight(entry.rowHeight or math.min(180, 20 + (entry.multiline or 6) * 13))
            control.label:ClearAllPoints()
            control.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            control.label:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
            edit:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -18)
            edit:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            edit:SetMultiLine(true)
            if edit.SetMaxLetters then edit:SetMaxLetters(20000) end
        else
            edit:SetPoint("LEFT", row, "CENTER", 8, 0)
            edit:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            edit:SetHeight(ROW_HEIGHTS.input)
            if edit.SetMaxLetters then edit:SetMaxLetters(200) end
        end
        local function commit(self)
            local text = self:GetText() or ""
            WriteValue(entry, text)
            page:OnValueChanged(entry, text)
        end
        edit:SetScript("OnEnterPressed", function(self)
            commit(self)
            self:ClearFocus()
        end)
        edit:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            page:Refresh()
        end)
        if not entry.multiline then
            -- live-применение при вводе (как хук LPSEditBoxNoButton в Ace-версии)
            edit:SetScript("OnTextChanged", function(self, userInput)
                if userInput then commit(self) end
            end)
        end
        control.edit = edit
    end
    return control
end
local function RefreshControl(control, db)
    local entry = control.entry
    if control.hidden then return end
    if entry.kind == "header" then return end
    local value = ReadValue(entry, db)
    local enabled = not (entry.disabled and entry.disabled(db))
    if control.toggle then
        control.toggle:SetChecked(value == true)
        control.toggle:EnableMouse(enabled)
        SetLabelEnabled(control.toggle.text, enabled)
        control.toggle:SetAlpha(enabled and 1 or 0.6)
    elseif control.slider then
        control.slider:SetValue(value, false)
        control.slider.hit:EnableMouse(enabled)
        control.slider:SetAlpha(enabled and 1 or 0.4)
        SetLabelEnabled(control.label, enabled)
    elseif control.dropdown then
        local items = ResolveItems(entry)
        if entry.dynamicItems then
            control.dropdown:SetItems(items)
        end
        control.dropdown:SetValue(value, TextForValue(items, value))
        if enabled then
            control.dropdown:Enable()
        else
            control.dropdown:Disable()
        end
        SetLabelEnabled(control.label, enabled)
    elseif control.swatch then
        local r, g, b, a
        if entry.displayColor then
            r, g, b, a = entry.displayColor(db)
        end
        if not r then
            local c = value or { r = 1, g = 1, b = 1 }
            r, g, b, a = c.r, c.g, c.b, 1
        end
        control.swatch:SetColor(r, g, b, a)
        control.swatch:SetDisabled(not enabled)
        SetLabelEnabled(control.label, enabled)
    elseif control.button then
        if enabled then
            control.button:Enable()
        else
            control.button:Disable()
        end
    elseif control.edit then
        local text = value ~= nil and tostring(value) or ""
        if control.edit:GetText() ~= text then
            control.edit:SetText(text)
        end
        if enabled then
            control.edit:Enable()
        else
            control.edit:Disable()
        end
        SetLabelEnabled(control.label, enabled)
    end
end
--- Ширина колонки относительно родительского контейнера.
local function AnchorColumn(colFrame, parent, side, colWidth)
    colFrame:SetPoint("TOP", parent, "TOP", 0, 0)
    colFrame:SetPoint("BOTTOM", parent, "BOTTOM", 0, 0)
    if side == "left" then
        colFrame:SetPoint("LEFT", parent, "LEFT", 0, 0)
        colFrame:SetPoint("RIGHT", parent, "CENTER", -COLUMN_GAP / 2, 0)
    else
        colFrame:SetPoint("LEFT", parent, "CENTER", COLUMN_GAP / 2, 0)
        colFrame:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    end
    if colWidth then colFrame:SetWidth(colWidth) end
end
--- Раскладка колонок по записям [{entry=..., height=...}]. Возвращает высоту.
local function LayoutColumn(colFrame, items, page, opts)
    local y = -(opts.topPadding or 4)
    for idx, item in ipairs(items) do
        local entry = item.entry
        local row = CreateFrame("Frame", nil, colFrame)
        if entry.kind == "header" and idx > 1 then
            y = y - (SECTION_GAP - ROW_GAP)
        end
        row:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", 0, y)
        row:SetHeight(item.height)
        SetRowTooltip(row, entry)
        if opts.onRow then opts.onRow(row) end
        local control = BuildControl(page, entry, row)
        -- многострочные метки могли получить больше высоты из-за переноса слов
        if control.multiline and row:GetHeight() > item.height then
            item.height = row:GetHeight()
        end
        y = y - item.height - ROW_GAP
        page.controls[#page.controls + 1] = control
    end
    return math.abs(y) + 8
end
function Builder.Build(parent, entries, opts)
    opts = opts or {}
    local page = {
        controls = {},
        onChange = opts.onChange,
    }
    -- двухколоночная сетка (как меню настроек CharacterStats): строки
    -- распределяются по левой/правой колонкам, высота страницы = max колонки
    local leftItems, rightItems = SplitColumns(entries)
    local hasRight = #rightItems > 0
    local parentWidth = parent:GetWidth()
    if not (parentWidth and parentWidth > 1) then parentWidth = nil end
    local leftCol = CreateFrame("Frame", nil, parent)
    AnchorColumn(leftCol, parent, "left", hasRight and parentWidth and (parentWidth / 2 - COLUMN_GAP / 2) or nil)
    local hLeft = LayoutColumn(leftCol, leftItems, page, opts)
    local hRight = 0
    if hasRight then
        local rightCol = CreateFrame("Frame", nil, parent)
        AnchorColumn(rightCol, parent, "right", parentWidth and (parentWidth / 2 - COLUMN_GAP / 2) or nil)
        hRight = LayoutColumn(rightCol, rightItems, page, opts)
        page.columns = { leftCol, rightCol }
    else
        page.columns = { leftCol }
    end
    page.height = math.max(hLeft, hRight)
    --- Пересчёт ширины колонок при изменении ширины контента (resize окна).
    function page:ResizeColumns(width)
        if not width or width <= 1 then return end
        local half = width / 2 - COLUMN_GAP / 2
        for _, col in ipairs(page.columns) do
            col:SetWidth(hasRight and half or width)
        end
    end
    function page:Refresh()
        Builder.RefreshPage(self)
    end
    function page:OnValueChanged(entry, value)
        local themeBefore = CS.Theme.key
        if entry.onChange then
            entry.onChange(value)
        elseif self.onChange then
            self.onChange(entry, value)
        end
        if CS.Theme.key == themeBefore then
            self:Refresh()
        end
    end
    return page
end
--- Публичный рефреш значений контролов страницы (используется и ленивыми
--- страницами ui_options, и самим Builder при изменении значений).
function Builder.RefreshPage(page)
    if not page or not page.controls then return end
    local db = GetDB()
    for _, control in ipairs(page.controls) do
        RefreshControl(control, db)
    end
end
return Builder
