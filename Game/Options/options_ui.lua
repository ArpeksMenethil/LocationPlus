local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local UI = {}

local WIDGET_TYPE = {
    toggle = "toggle",
    range = "slider",
    select = "dropdown",
    multiselect = "dropdown",
    input = "input",
    color = "color",
    description = "label",
    header = "header",
    execute = "button",
    image = "image",
    link = "link",
}

--- Вызов get-функции пункта (нативный рендерер передаёт uiInfo — аргумент сохранён для совместимости).
function LPS:OptionCallGet(entry)
    if type(entry.get) == "function" then
        local ok, v = pcall(entry.get, false)
        if ok then return v end
    elseif entry.get ~= nil then
        return entry.get
    end
end

--- Вызов set-функции пункта. Для color передаётся таблица {r,g,b,a}
--- (разворачивается в r, g, b — сигнатура get/set одинакова в обоих UI).
function LPS:OptionCallSet(entry, value)
    if type(entry.set) == "function" then
        if type(value) == "table" and tonumber(value.r) then
            pcall(entry.set, false, value.r, value.g, value.b, value.a or 1)
        else
            pcall(entry.set, false, value)
        end
    end
end

--- Значение для color-строки билдера: {r,g,b} из get().
--- get() в Ace-формате возвращает компоненты как ОТСУЛЬНЫЕ значения
--- (например, userColor: return r, g, b), а callGet ловит только первое из
--- них — из-за этого свотч был белым (одно число — не цвет). Здесь ловим
--- все возвращаемые значения; табличная форма {r,g,b[,a]} тоже поддерживается.
function LPS:ReadOptionColor(entry)
    local r, g, b, a
    if type(entry.get) == "function" then
        local ok
        ok, r, g, b, a = pcall(entry.get, false)
        if not ok then
            r, g, b, a = 1, 1, 1, 1
        end
    elseif entry.get ~= nil then
        r = entry.get
    end
    if type(r) == "table" then
        local v = r
        if tonumber(v.r) then
            return { r = v.r, g = v.g or v.r, b = v.b or v.r, a = tonumber(v.a) or 1 }
        end
        if tonumber(v[1]) then
            return { r = v[1], g = v[2] or v[1], b = v[3] or v[1], a = tonumber(v[4]) or 1 }
        end
    end
    return {
        r = tonumber(r) or 1,
        g = tonumber(g) or tonumber(r) or 1,
        b = tonumber(b) or tonumber(r) or 1,
        a = tonumber(a) or 1,
    }
end

--- Дефолт color-пункта (entry.default): {r,g,b[,a]} или [1..4].
--- Нужен пикеру для кнопки «сбросить» — сброс возвращает дефолт опции.
function LPS:ReadOptionDefaultColor(entry)
    local d = entry.default
    if type(d) == "table" then
        if tonumber(d.r) then
            return { r = d.r, g = d.g or d.r, b = d.b or d.r, a = tonumber(d.a) or 1 }
        end
        if tonumber(d[1]) then
            return { r = d[1], g = d[2] or d[1], b = d[3] or d[1], a = tonumber(d[4]) or 1 }
        end
    end
    return nil
end

--- Обёртка над disabled-функцией пункта (для серых строк в нативном UI).
function LPS:MakeOptionDisabled(node)
    if not node.disabled then return nil end
    return function()
        local d = node.disabled
        if type(d) == "function" then
            local ok, v = pcall(d, false)
            return ok and v or false
        end
        return d and true or false
    end
end

--- Текст всплывающей подсказки пункта (desc в дереве настроек).
function LPS:NodeTooltip(node)
    local d = node.desc
    if type(d) == "function" then
        local ok, v = pcall(d, false)
        d = ok and v or nil
    end
    return (type(d) == "string" and d ~= "") and d or nil
end

--- Список items для dropdown из поля values (таблица или функция).
function LPS:ResolveOptionItems(entry)
    local values = entry.values
    if type(values) == "function" then
        local ok, v = pcall(values, false)
        values = ok and v or nil
    end
    if type(values) ~= "table" then return {} end
    local items, seen = {}, {}
    local function add(value, text)
        if seen[value] then return end
        seen[value] = true
        items[#items + 1] = { value = value, text = tostring(text or value) }
    end
    local count = 0
    for _ in pairs(values) do count = count + 1 end
    local isList = count > 0
    if isList then
        for k, v in pairs(values) do
            if type(k) ~= "number" or k < 1 or k > count or type(v) ~= "table" then
                isList = false
                break
            end
        end
    end
    if isList then
        for _, v in ipairs(values) do
            if type(v) == "table" then add(v.value, v.text or v.label) else add(v, v) end
        end
    else
        for k, name in pairs(values) do add(k, name) end
    end
    local sorting = entry.sorting
    if type(sorting) == "function" then
        local ok, v = pcall(sorting, false)
        sorting = ok and v or nil
    end
    if type(sorting) == "table" then
        local ordered = {}
        local seenOrdered = {}
        for _, value in ipairs(sorting) do
            if values[value] ~= nil and not seenOrdered[value] then
                seenOrdered[value] = true
                ordered[#ordered + 1] = { value = value, text = tostring(values[value] or value) }
            end
        end
        local seen = {}
        for _, item in ipairs(ordered) do seen[item.value] = true end
        for _, item in ipairs(items) do
            if not seen[item.value] then
                ordered[#ordered + 1] = item
            end
        end
        return ordered
    end
    table.sort(items, function(a, b)
        return tostring(a.text):lower() < tostring(b.text):lower()
    end)
    return items
end

--- Плоский список строк страницы: группы (узлы с args) схлопываются в заголовки.
--- Ace3 больше не используется, поэтому поля type = "group" / inline в дереве
--- настроек не нужны: группа определяется наличием args, по умолчанию.
--- additionalSortKeys — необязательный список доп. ключей сортировки
--- (стабильный порядок при одинаковом order; см. actionsGroup в general.lua).
function LPS:CollectOptionRows(group, out, additionalSortKeys)
    local args = group.args
    if type(args) == "function" then
        local ok, t = pcall(args, false)
        args = ok and t or nil
    end
    if type(args) ~= "table" then return out end
    local rows = {}
    for key, node in pairs(args) do
        if type(node) == "table" then
            node._key = tostring(key)
            rows[#rows + 1] = node
        end
    end
    table.sort(rows, function(a, b)
        local oa, ob = tonumber(a.order) or 999, tonumber(b.order) or 999
        if oa ~= ob then return oa < ob end
        for _, k in ipairs(additionalSortKeys or {}) do
            local ka, kb = a[k], b[k]
            if ka ~= kb then
                if ka == nil then return false end
                if kb == nil then return true end
                return tostring(ka) < tostring(kb)
            end
        end
        return tostring(a._key) < tostring(b._key)
    end)
    for _, node in ipairs(rows) do
        local hidden = node.hidden
        if type(hidden) == "function" then
            local ok, v = pcall(hidden, false)
            hidden = ok and v
        end
        if not hidden then
            local kind = WIDGET_TYPE[node.type]
            local isTogglePair = (kind == "toggle") and node.fullRow ~= true
            if type(node.args) == "table" or type(node.args) == "function" then
                local groupName = tostring(node.name or "")
                local isSpacer = (groupName == "" or groupName == " ")
                if not isSpacer then
                    out[#out + 1] = { kind = "header", label = groupName }
                end
                LPS:CollectOptionRows(node, out, node.sortKeys)
            elseif kind == "label" then
                if node.name and node.name ~= " " and node.name ~= "" then
                    out[#out + 1] = {
                        kind = "label", label = tostring(node.name),
                        tooltip = LPS:NodeTooltip(node),
                        multiline = true,
                    }
                end
            elseif kind == "image" and node.file then
                out[#out + 1] = {
                    kind = "image",
                    file = tostring(node.file),
                    width = tonumber(node.width) or 64,
                    height = tonumber(node.height) or 64,
                    align = node.align or "LEFT",
                }
            elseif kind == "link" and node.url then
                out[#out + 1] = {
                    kind = "link",
                    label = tostring(node.name or ""),
                    url = tostring(node.url),
                    tooltip = LPS:NodeTooltip(node),
                }
            elseif kind == "header" then
                out[#out + 1] = { kind = "header", label = tostring(node.name or "") }
            elseif kind == "toggle" and node.get then
                out[#out + 1] = {
                    kind = "toggle", fullRow = not isTogglePair,
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    disabled = LPS:MakeOptionDisabled(node),
                    get = function() return LPS:OptionCallGet(node) == true end,
                    set = function(v) LPS:OptionCallSet(node, v and true or false) end,
                }
            elseif kind == "slider" and node.get then
                out[#out + 1] = {
                    kind = "slider",
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    min = tonumber(node.min) or 0,
                    max = tonumber(node.max) or 100,
                    step = tonumber(node.bigStep) or tonumber(node.step) or 1,
                    format = (tonumber(node.step) or 1) % 1 == 0 and "%.0f" or "%.2f",
                    disabled = LPS:MakeOptionDisabled(node),
                    get = function() return tonumber(LPS:OptionCallGet(node)) or (tonumber(node.min) or 0) end,
                    set = function(v) LPS:OptionCallSet(node, v) end,
                }
            elseif kind == "dropdown" and node.get then
                out[#out + 1] = {
                    kind = "dropdown", dynamicItems = true,
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    disabled = LPS:MakeOptionDisabled(node),
                    items = function() return LPS:ResolveOptionItems(node) end,
                    get = function() return LPS:OptionCallGet(node) end,
                    set = function(v) LPS:OptionCallSet(node, v) end,
                }
            elseif kind == "input" and node.get then
                out[#out + 1] = {
                    kind = "input",
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    disabled = LPS:MakeOptionDisabled(node),
                    multiline = tonumber(node.multiline),
                    get = function() return tostring(LPS:OptionCallGet(node) or "") end,
                    set = function(v) LPS:OptionCallSet(node, v) end,
                }
            elseif kind == "color" and node.get then
                out[#out + 1] = {
                    kind = "color",
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    disabled = LPS:MakeOptionDisabled(node),
                    alpha = node.alpha == true or node.hasAlpha == true,
                    default = LPS:ReadOptionDefaultColor(node),
                    get = function() return LPS:ReadOptionColor(node) end,
                    set = function(c) LPS:OptionCallSet(node, c) end,
                }
            elseif kind == "button" and node.func then
                out[#out + 1] = {
                    kind = "button",
                    label = tostring(node.name or ""),
                    tooltip = LPS:NodeTooltip(node),
                    disabled = LPS:MakeOptionDisabled(node),
                    func = function()
                        local ok = pcall(node.func, false)
                        if not ok and LPS.DEBUG then LPS:DebugPrint("options execute error: " .. tostring(node.name), false) end
                    end,
                }
            end
        end
    end
    return out
end

--- Создание контейнера страницы: скролл-фрейм + строки из Builder.
--- Содержимое строится лениво — при первом Refresh (он вызывается из
--- Panel.ShowPage перед показом страницы). Если первая попытка дала пустой
--- список строк (например, фабрика вкладки упала или дерево собралось до
--- готовности БД), страница будет пересобрана при следующем открытии.
function LPS:CreateTreePage(group)
    return function(container)
        local scroll, content = LPS:PanelCreateScrollPage(container)
        local page = {
            controls = {},
            height = 0,
            _container = container,
            _content = content,
            _group = group,
            _built = false,
            scroll = scroll,
        }
        function page:Build(force)
            if self._built and not force then return end
            local entries = LPS:CollectOptionRows(self._group, {})
            if #entries == 0 then
                self._built = false
                return
            end
            self._built = true
            if content.rows then
                for _, row in ipairs(content.rows) do row:Hide(); row:ClearAllPoints() end
            end
            content.rows = {}
            local built = LPS:BuildOptionPage(content, entries, {
                onChange = function() LPS:PanelOnSettingChanged() end,
                onRow = function(row) content.rows[#content.rows + 1] = row end,
            })
            page.controls = built.controls
            page.height = built.height
            page.onChange = built.onChange
            local cw = scroll:GetWidth()
            if cw and cw > 1 then content:SetWidth(cw) end
            if scroll.SetContentHeight then
                scroll:SetContentHeight(built.height)
            end
        end
        function page:Refresh()
            self:Build()
            LPS:RefreshOptionPage(page)
        end
        function page:OnValueChanged(entry, value)
            local built = self.controls[1] and self.controls[1].entry and true or false
            if not built then return end
            local themeBefore = LPS:GetThemeKey()
            if entry.onChange then
                entry.onChange(value)
            elseif self.onChange then
                self.onChange(entry, value)
            end
            if LPS:GetThemeKey() == themeBefore then
                LPS:RefreshOptionPage(self)
            end
        end
        if container then
            container:HookScript("OnShow", function()
                if page._built and scroll.SetContentHeight then
                    local cw = scroll:GetWidth()
                    if cw and cw > 1 then content:SetWidth(cw) end
                    scroll:SetContentHeight(page.height)
                end
            end)
        end
        return page
    end
end

--- Ключ страницы в Panel для узла дерева (стабилен между пересборками).
function LPS:PageKeyFor(node)
    return "tree_" .. tostring(node._pageId or node.name or "")
end

--- Построение/обновление списка страниц по текущему дереву опций.
--- Идемпотентно: вызывается каждый раз при открытии окна, чтобы подтянуть
--- свежие переводы/вкладки после смены языка или профиля.
local pageKeys = {}
function LPS:BuildOptionPages()
    if LPS.GetOptionsTree then
        LPS.Options.tree = LPS:GetOptionsTree()
    end
    local tree = LPS.Options.tree
    if not tree or type(tree.args) ~= "table" then return end
    local Panel = LPS.UI and LPS.UI.Panel
    if not Panel then return end
    local nodes = {}
    for key, node in pairs(tree.args) do
        if type(node) == "table" then
            node._pageId = tostring(key)
            nodes[#nodes + 1] = node
        end
    end
    table.sort(nodes, function(a, b)
        return (tonumber(a.order) or 999) < (tonumber(b.order) or 999)
    end)
    for _, node in ipairs(nodes) do
        if node.args ~= nil then
            local key = LPS:PageKeyFor(node)
            if not pageKeys[key] then
                pageKeys[key] = true
                local create = LPS:CreateTreePage(node)
                if node._pageId == "profiles" and LPS.CreateProfilesPanelPage then
                    create = function(c) return LPS:CreateProfilesPanelPage(c) end
                end
                LPS:RegisterPanelPage(key, {
                    label = tostring(node.name or ""),
                    order = tonumber(node.order) or 99,
                    create = create,
                })
            end
        end
    end
end

--- Открыть/закрыть нативное окно.
function LPS:ToggleOptionWindow()
    LPS:BuildOptionPages()
    LPS:PanelToggle()
end

function LPS:IsOptionWindowShown()
    return LPS:PanelIsShown()
end

function LPS:CloseOptionWindow()
    LPS:PanelHide()
end

--- Обновить активную страницу (вызывается из LPS:ApplyOptionsRefresh).
function LPS:RefreshOptionWindowPage()
    if LPS:PanelIsShown() then
        LPS:PanelRefreshActivePage()
    end
end
