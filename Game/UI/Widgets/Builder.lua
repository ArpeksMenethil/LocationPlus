local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
--- Автогенерация строк настроек из flat-описаний
local ROW_GAP = 4
local SECTION_GAP = 14
local TOGGLE_GUTTER = 8
local ROW_HEIGHTS = {
    header = 18,
    slider = 22,
    dropdown = 22,
    toggle = 20,
    color = 20,
    button = 24,
    label = 16,
    input = 24,
    image = 64,
    link = 16,
}
local DISABLED_TEXT = { r = 0.4, g = 0.4, b = 0.4 }

function LPS:ReadEntryValue(entry, db)
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
function LPS:WriteEntryValue(entry, value)
    if not LPS:GetDB() then return end
    if entry.set then
        entry.set(value)
    elseif entry.key then
        LPS:SetOptionByPath(entry.key, value)
    end
end
function LPS:BuilderResolveItems(entry)
    if type(entry.items) == "function" then
        return entry.items()
    end
    return entry.items or {}
end
function LPS:TextForValue(items, value)
    for _, item in ipairs(items) do
        if item.value == value then
            return item.text
        end
    end
    return value ~= nil and tostring(value) or ""
end
function LPS:SetLabelEnabled(label, enabled)
    if not label then return end
    if enabled then
        LPS:ApplyFontColor(label, "textMuted")
    else
        label:SetTextColor(DISABLED_TEXT.r, DISABLED_TEXT.g, DISABLED_TEXT.b)
    end
end
function LPS:CreateRowLabel(row, text)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")
    LPS:ApplyFontColor(label, "textMuted")
    return label
end

function LPS:AttachRowTooltip(target, entry)
    if not target then return end
    local tip = entry.tooltip or entry.desc
    if not tip then return end
    if type(target.SetScript) ~= "function" then return end
    target:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if entry.label and entry.label ~= "" and entry.label ~= " " then
            GameTooltip:AddLine(entry.label, 1, 1, 1)
        end
        GameTooltip:AddLine(tip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    target:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
function LPS:SetRowTooltip(row, control, entry)
    if not (entry.tooltip or entry.desc) then return end
    local kind = entry.kind
    if kind == "toggle" then
        LPS:AttachRowTooltip(control.toggle, entry)
    elseif kind == "slider" then
        LPS:AttachRowTooltip(control.label, entry)
    elseif kind == "dropdown" then
        LPS:AttachRowTooltip(control.dropdown, entry)
    elseif kind == "color" then
        LPS:AttachRowTooltip(control.swatch, entry)
    elseif kind == "input" then
        LPS:AttachRowTooltip(control.edit, entry)
    elseif kind == "button" then
        LPS:AttachRowTooltip(control.button, entry)
    elseif kind == "label" then
        LPS:AttachRowTooltip(control.text or row, entry)
    elseif kind == "link" then
        LPS:AttachRowTooltip(control.link or row, entry)
    else
        LPS:AttachRowTooltip(row, entry)
    end
end
--- Подбирает тему шрифта многострочного label'а по содержимому: заголовки
--- секций (без цвета/переносов строк) — heading, остальное — обычный текст.
function LPS:ApplyLabelRole(text, str)
    if str:find("\n") or str:find("|c") then
        text.themeRole = "body"
    else
        text.themeRole = "heading"
    end
end
--- Многострочный description (About-тексты): высота считается по строкам,
--- иначе метка с \n обрезается фиксированной высотой строки 16px.
function LPS:BuildMultilineLabel(row, entry)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    text:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    local str = tostring(entry.label or "")
    LPS:ApplyLabelRole(text, str)
    text:SetText(str)
    LPS:ApplyFontColor(text, "textMuted")
    local lines = 1 + select(2, str:gsub("\n", ""))
    local height = math.max(16, lines * 15 + 4)
    row:SetHeight(height)
    entry.rowHeight = height
    return { entry = entry, row = row, text = text, multiline = true }
end
--- Точный пересчёт высоты многострочной метки после применения темы шрифта.
function LPS:RelayoutMultiline(control)
    if not control.multiline then return end
    local text, row, entry = control.text, control.row, control.entry
    if not text or not row then return end
    local h = math.max(16, (text:GetStringHeight() or 0) + 4)
    if h ~= entry.rowHeight then
        entry.rowHeight = h
        row:SetHeight(h)
    end
end
--- Фиксация текста многострочного поля (экспорт/импорт): вызывается при вводе.
function LPS:CommitMultiline(self, entry, page)
    local text = self:GetText() or ""
    LPS:WriteEntryValue(entry, text)
    if page and page.OnValueChanged then page:OnValueChanged(entry, text) end
end

--- Строка-картинка (логотип на вкладке About): вписывает изображение в
--- прямоугольник boxW x boxH с сохранением пропорций. SetTexture сам
--- подгоняет размер texture-фрейма под исходник; на современных клиентах
--- размеры дополнительно доступны через Game.GetTextureDimensions.
function LPS:BuildImage(row, entry)
    local boxW = math.max(16, tonumber(entry.width) or 64)
    local boxH = math.max(16, tonumber(entry.height) or 64)
    local tex = row:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(entry.file)
    local tw, th = tex:GetWidth() or boxW, tex:GetHeight() or boxH
    local Game = _G.Game
    if Game and Game.GetTextureDimensions then
        local ok, w, h = pcall(Game.GetTextureDimensions, entry.file)
        if ok and w and h and w > 0 and h > 0 then
            tw, th = w, h
        end
    end
    local scale = math.min(boxW / tw, boxH / th)
    tex:SetSize(math.max(1, tw * scale), math.max(1, th * scale))
    if entry.align == "CENTER" then
        tex:SetPoint("CENTER", row, "CENTER", 0, 0)
    else
        tex:SetPoint("LEFT", row, "LEFT", 0, 0)
    end
    row:SetHeight(math.max(16, tex:GetHeight() or boxH))
    return tex
end
--- Строка-ссылка: статичный текст (подпись обычным цветом + URL синий),
--- без кликов и копирования.
function LPS:BuildLink(row, entry)
    local url = tostring(entry.url or "")
    if url == "" then return nil end
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", row, "LEFT", 0, 0)
    text:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    local prefix = tostring(entry.label or "")
    local prefixPart = prefix ~= "" and prefix .. ": " or ""
    text:SetText(prefixPart .. "|cff4aa3ff" .. url .. "|r")
    LPS:ApplyFontColor(text, "textMuted")
    return text
end
function LPS:BuildControl(page, entry, row)
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
        control.header = LPS:CreateSectionHeader(row, entry.label)
        control.header:SetAllPoints(row)
    elseif kind == "label" then
        if entry.multiline then
            return LPS:BuildMultilineLabel(row, entry)
        end
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 0, 0)
        text:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
        text:SetText(entry.label or "")
        LPS:ApplyFontColor(text, "textMuted")
        control.text = text
    elseif kind == "image" then
        control.image = LPS:BuildImage(row, entry)
    elseif kind == "link" then
        control.link = LPS:BuildLink(row, entry)
    elseif kind == "button" then
        local btn = LPS:CreateFlatButton(row, 90, ROW_HEIGHTS.button, entry.label)
        local textWidth = btn.text:GetStringWidth() or 0
        btn:SetWidth(math.max(90, textWidth + 24))
        btn:SetPoint("LEFT", row, "LEFT", 0, 0)
        btn:SetScript("OnClick", function()
            if entry.func then entry.func() end
        end)
        control.button = btn
        control._btnAutoWidth = true
    elseif kind == "toggle" then
        local toggle = LPS:CreateToggle(row, entry.label)
        toggle:SetPoint("LEFT", row, "LEFT", 0, 0)
        toggle:SetOnClick(function(self)
            LPS:WriteEntryValue(entry, self:GetChecked())
            page:OnValueChanged(entry, self:GetChecked())
        end)
        control.toggle = toggle
    elseif kind == "slider" then
        control.label = LPS:CreateRowLabel(row, entry.label)
        local slider = LPS:CreateSlider(row, {
            min = entry.min,
            max = entry.max,
            step = entry.step,
            format = entry.format,
            formatValue = entry.formatValue,
            value = entry.min,
            commitOnRelease = entry.commitOnRelease,
            onChange = function(val)
                LPS:WriteEntryValue(entry, val)
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
        control.label = LPS:CreateRowLabel(row, entry.label)
        local _, dropdown = LPS:CreateDropdown(row, "", 150, { fixedWidth = true })
        dropdown:ClearAllPoints()
        dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
        dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        dropdown:SetHeight(ROW_HEIGHTS.dropdown)
        dropdown:SetItems(LPS:BuilderResolveItems(entry))
        dropdown:SetOnChange(function(value)
            LPS:WriteEntryValue(entry, value)
            page:OnValueChanged(entry, value)
        end)
        control.dropdown = dropdown
    elseif kind == "color" then
        control.label = LPS:CreateRowLabel(row, entry.label)
        local swatch = LPS:CreateSwatch(row)
        swatch:SetPoint("LEFT", row, "CENTER", 8, 0)
        swatch:SetScript("OnClick", function()
            local db = LPS:GetDB() or {}
            local c = LPS:ReadEntryValue(entry, db) or { r = 1, g = 1, b = 1 }
            local function write(r, g, b, a)
                local v = { r = r, g = g, b = b }
                if entry.alpha then v.a = a or 1 end
                LPS:WriteEntryValue(entry, v)
                page:OnValueChanged(entry)
            end
            LPS:OpenColorPicker(c.r or 1, c.g or 1, c.b or 1, c.a or 1,
                function(r, g, b, a) write(r, g, b, a) end,
                function(r, g, b, a) write(r, g, b, a) end,
                    { hasAlpha = entry.alpha == true, title = entry.label,
                        defaultColor = entry.default })
        end)
        control.swatch = swatch
    elseif kind == "input" then
        control.label = LPS:CreateRowLabel(row, entry.label)
        if entry.multiline then
            local boxHeight = entry.rowHeight or math.min(220, 24 + (entry.multiline or 6) * 15)
            row:SetHeight(boxHeight)
            control.label:ClearAllPoints()
            control.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            control.label:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)

            local scroll = CreateFrame("ScrollFrame", nil, row)
            scroll:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -18)
            scroll:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
            local inner = CreateFrame("Frame", nil, scroll)
            inner:SetPoint("TOPLEFT")
            inner:SetPoint("TOPRIGHT")
            inner:SetHeight(1)
            scroll:SetScrollChild(inner)

            local edit = CreateFrame("EditBox", nil, inner, "InputBoxTemplate")
            edit:SetAutoFocus(false)
            edit:SetPoint("TOPLEFT", inner, "TOPLEFT", 4, 0)
            edit:SetPoint("TOPRIGHT", inner, "TOPRIGHT", -4, 0)
            edit:SetHeight(boxHeight - 22)
            edit:SetMultiLine(true)
            edit:SetFontObject(GameFontHighlightSmall)
            if edit.SetMaxLetters then edit:SetMaxLetters(200000) end

            local function SyncInnerHeight(self)
                local h = math.max((self:GetTextHeight() or 0) + 8, boxHeight - 22)
                inner:SetHeight(h)
                self:SetHeight(h)
            end
            edit:SetScript("OnTextChanged", function(self, userInput)
                SyncInnerHeight(self)
            end)
            edit:SetScript("OnEnterPressed", function(self)
                LPS:CommitMultiline(self, entry, page)
                self:ClearFocus()
            end)
            edit:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
                if page and page.Refresh then page:Refresh() end
            end)
            scroll:EnableMouseWheel(true)
            scroll:SetScript("OnMouseWheel", function(self, delta)
                local maxScroll = math.max(0, inner:GetHeight() - self:GetHeight())
                local cur = self:GetVerticalScroll()
                self:SetVerticalScroll(math.max(0, math.min(maxScroll, cur - delta * 20)))
            end)
            edit:HookScript("OnMouseWheel", function(self, delta)
                local parent = scroll
                if parent then
                    local maxScroll = math.max(0, inner:GetHeight() - parent:GetHeight())
                    local cur = parent:GetVerticalScroll()
                    parent:SetVerticalScroll(math.max(0, math.min(maxScroll, cur - delta * 20)))
                end
            end)
            control.edit = edit
            control.scroll = scroll
            control.inner = inner
            control.syncHeight = SyncInnerHeight
            return control
        end
        local edit = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
        edit:SetAutoFocus(false)
        edit:SetPoint("LEFT", row, "CENTER", 8, 0)
        edit:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        edit:SetHeight(ROW_HEIGHTS.input)
        if edit.SetMaxLetters then edit:SetMaxLetters(200) end
        local function commit(self)
            local text = self:GetText() or ""
            LPS:WriteEntryValue(entry, text)
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
            edit:SetScript("OnTextChanged", function(self, userInput)
                if userInput then commit(self) end
            end)
        end
        control.edit = edit
    end
    return control
end
function LPS:RefreshControl(control, db)
    local entry = control.entry
    if control.hidden then return end
    if entry.kind == "header" then return end
    local value = LPS:ReadEntryValue(entry, db)
    local enabled = not (entry.disabled and entry.disabled(db))
    if control.toggle then
        control.toggle:SetChecked(value == true)
        control.toggle:EnableMouse(enabled)
        LPS:SetLabelEnabled(control.toggle.text, enabled)
        control.toggle:SetAlpha(enabled and 1 or 0.6)
    elseif control.slider then
        control.slider:SetValue(value, false)
        control.slider.hit:EnableMouse(enabled)
        control.slider:SetAlpha(enabled and 1 or 0.4)
        LPS:SetLabelEnabled(control.label, enabled)
    elseif control.dropdown then
        local items = LPS:BuilderResolveItems(entry)
        if entry.dynamicItems then
            control.dropdown:SetItems(items)
        end
        control.dropdown:SetValue(value, LPS:TextForValue(items, value))
        if enabled then
            control.dropdown:Enable()
        else
            control.dropdown:Disable()
        end
        LPS:SetLabelEnabled(control.label, enabled)
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
        LPS:SetLabelEnabled(control.label, enabled)
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
            if control.syncHeight then control.syncHeight(control.edit) end
        end
        if enabled then
            control.edit:Enable()
        else
            control.edit:Disable()
        end
        LPS:SetLabelEnabled(control.label, enabled)
    end
end
--- Одноколоночная раскладка: строки идут одна под другой на всю ширину; только короткие чекбоксы
--- (toggle без fullRow) группируются по два — вторая строка встаёт в правую
--- половину той же высоты, не сдвигая последующие строки.
--- Подряд идущие кнопки (kind == "button") группируются в ряды максимум по
--- BUTTON_COLUMNS (3) — в стиле страницы «Профиль»: одинаковая ширина кнопок
--- в ряду (по самой длинной подписи), равные зазоры, выравнивание по левому краю.
local BUTTON_COLUMNS = 3
local BUTTON_GAP = 6

--- Раскладка ряда кнопок: уравнивает ширины и ставит их слева направо.
function LPS:LayoutButtonRow(buttons, row)
    local textMax = 0
    for _, btn in ipairs(buttons) do
        if btn.text then
            local tw = btn.text:GetStringWidth() or 0
            if tw > textMax then textMax = tw end
        end
    end
    local width = math.max(80, textMax + BUTTON_GAP * 4)
    local x = 0
    for i, btn in ipairs(buttons) do
        btn:SetWidth(width)
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("LEFT", row, "LEFT", 0, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", BUTTON_GAP, 0)
        end
        x = x + width + BUTTON_GAP
    end
end

function LPS:BuildOptionPage(parent, entries, opts)
    opts = opts or {}
    local page = {
        controls = {},
        onChange = opts.onChange,
    }
    local y = -(opts.topPadding or 4)
    local leftToggleRowY = nil
    local first = true

    --- Индекс следующей записи, которую стоит обработать (для захвата
    --- подряд идущих кнопок в один ряд); nil = идти по циклу.
    local skipTo = nil

    local i = 0
    while i < #entries do
        i = i + 1
        if skipTo then
            if i < skipTo then i = skipTo end
            skipTo = nil
        end
        if i > #entries then break end
        local entry = entries[i]
        if not entry.available or entry.available() then
            local kind = entry.kind
            local height = ROW_HEIGHTS[kind] or 20
            if entry.multiline then
                if kind == "input" then
                    height = entry.rowHeight or math.min(220, 24 + (tonumber(entry.multiline) or 6) * 15)
                else
                    height = entry.rowHeight or height
                end end

            local btnGroup = nil
            if kind == "button" then
                btnGroup = { entry }
                local j = i + 1
                while j <= #entries and #btnGroup < BUTTON_COLUMNS do
                    local e2 = entries[j]
                    if e2.kind == "button" and (not e2.available or e2.available()) then
                        btnGroup[#btnGroup + 1] = e2
                        j = j + 1
                    else
                        break
                    end
                end
                skipTo = j
            end

            local row = CreateFrame("Frame", nil, parent)
            local placedRight = false
            if kind == "toggle" and leftToggleRowY and not entry.fullRow then
                row:SetPoint("TOPLEFT", parent, "TOP", TOGGLE_GUTTER, leftToggleRowY)
                row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, leftToggleRowY)
                leftToggleRowY = nil
                placedRight = true
            else
                if kind == "header" and not first then
                    y = y - (SECTION_GAP - ROW_GAP)
                end
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                if kind == "toggle" and not entry.fullRow then
                    row:SetPoint("TOPRIGHT", parent, "TOP", -TOGGLE_GUTTER, y)
                    leftToggleRowY = y
                else
                    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
                    leftToggleRowY = nil
                end
            end
            row:SetHeight(height)
            if not placedRight then
                y = y - height - ROW_GAP
            end
            if opts.onRow then opts.onRow(row) end

            if btnGroup then
                local groupControls = {}
                for bi, bentry in ipairs(btnGroup) do
                    local control = LPS:BuildControl(page, bentry, row)
                    LPS:SetRowTooltip(row, control, bentry)
                    if control.button then
                        control.button.index = bi
                    end
                    groupControls[#groupControls + 1] = control
                    page.controls[#page.controls + 1] = control
                end
                LPS:LayoutButtonRow((function()
                    local list = {}
                    for _, c in ipairs(groupControls) do
                        if c.button then list[#list + 1] = c.button end
                    end
                    return list
                end)(), row)
                first = false
            else
                local control = LPS:BuildControl(page, entry, row)
                LPS:SetRowTooltip(row, control, entry)
                if (control.multiline and row:GetHeight() > height)
                    or (control.image and row:GetHeight() ~= height) then
                        if not placedRight then
                            y = y + height - row:GetHeight()
                        end
                        height = row:GetHeight()
                    end
                first = false
                page.controls[#page.controls + 1] = control
            end
        end
    end
    page.height = math.abs(y) + 8
    function page:Refresh()
        LPS:RefreshOptionPage(self)
    end
    function page:OnValueChanged(entry, value)
        local themeBefore = LPS:GetThemeKey()
        if entry.onChange then
            entry.onChange(value)
        elseif self.onChange then
            self.onChange(entry, value)
        end
        if LPS:GetThemeKey() == themeBefore then
            self:Refresh()
        end
    end
    return page
end
--- Публичный рефреш значений контролов страницы (используется и ленивыми
--- страницами ui_options, и самим Builder при изменении значений).
function LPS:RefreshOptionPage(page)
    if not page or not page.controls then return end
    local db = LPS:GetDB() or {}
    for _, control in ipairs(page.controls) do
        LPS:RefreshControl(control, db)
    end
end
