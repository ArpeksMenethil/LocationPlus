local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------
-- Нативное окно настроек (дизайн портирован из исходного аддона)
-------------------------------------------------
-- Единственный источник пунктов — внутреннее дерево формата options.lua
-- (LPS.Options.tree, без Ace3). Здесь оно превращается в страницы панели UI/Panel.
local UI = {}
LPS.UI_Options = UI

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
}

--- Вызов get-функции пункта (нативный рендерер передаёт uiInfo — аргумент сохранён для совместимости).
local function callGet(entry)
    if type(entry.get) == "function" then
        local ok, v = pcall(entry.get, false)
        if ok then return v end
    elseif entry.get ~= nil then
        return entry.get
    end
end

--- Вызов set-функции пункта. Для color передаётся таблица {r,g,b,a}
--- (разворачивается в r, g, b — сигнатура get/set одинакова в обоих UI).
local function callSet(entry, value)
    if type(entry.set) == "function" then
        if type(value) == "table" and tonumber(value.r) then
            pcall(entry.set, false, value.r, value.g, value.b, value.a or 1)
        else
            pcall(entry.set, false, value)
        end
    end
end

--- Значение для color-строки билдера: {r,g,b} из get().
local function readColor(entry)
    local v = callGet(entry)
    if type(v) == "table" and tonumber(v.r) then
        return { r = v.r, g = v.g, b = v.b, a = tonumber(v.a) or 1 }
    end
    if type(v) == "table" and tonumber(v[1]) then
        return { r = v[1], g = v[2], b = v[3], a = tonumber(v[4]) or 1 }
    end
    return { r = 1, g = 1, b = 1 }
end

--- Обёртка над disabled-функцией пункта (для серых строк в нативном UI).
local function makeDisabled(node)
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
local function nodeTooltip(node)
    local d = node.desc
    if type(d) == "function" then
        local ok, v = pcall(d, false)
        d = ok and v or nil
    end
    return (type(d) == "string" and d ~= "") and d or nil
end

--- Список items для dropdown из поля values (таблица или функция).
local function resolveItems(entry)
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
    if #values > 0 then
        for _, v in ipairs(values) do
            if type(v) == "table" then add(v.value, v.text or v.label) else add(v, v) end
        end
    else
        for k, name in pairs(values) do add(k, name) end
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
local function collectRows(group, out, additionalSortKeys)
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
            -- чекбоксы (toggle) в исходном аддоне идут парами в один ряд;
            -- fullRow=true оставляет чекбокс на всю ширину строки
            local isTogglePair = (kind == "toggle") and node.fullRow ~= true
            if type(node.args) == "table" or type(node.args) == "function" then
                local groupName = tostring(node.name or "")
                local isSpacer = (groupName == "" or groupName == " ")
                if not isSpacer then
                    out[#out + 1] = { kind = "header", label = groupName }
                end
                collectRows(node, out, node.sortKeys)
            elseif kind == "label" then
                if node.name and node.name ~= " " and node.name ~= "" then
                    out[#out + 1] = {
                        kind = "label", label = tostring(node.name),
                        tooltip = nodeTooltip(node),
                        multiline = true,
                    }
                end
            elseif kind == "header" then
                out[#out + 1] = { kind = "header", label = tostring(node.name or "") }
            elseif kind == "toggle" and node.get then
                out[#out + 1] = {
                    kind = "toggle", fullRow = not isTogglePair,
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    disabled = makeDisabled(node),
                    get = function() return callGet(node) == true end,
                    set = function(v) callSet(node, v and true or false) end,
                }
            elseif kind == "slider" and node.get then
                out[#out + 1] = {
                    kind = "slider",
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    min = tonumber(node.min) or 0,
                    max = tonumber(node.max) or 100,
                    step = tonumber(node.bigStep) or tonumber(node.step) or 1,
                    format = (tonumber(node.step) or 1) % 1 == 0 and "%.0f" or "%.2f",
                    disabled = makeDisabled(node),
                    get = function() return tonumber(callGet(node)) or (tonumber(node.min) or 0) end,
                    set = function(v) callSet(node, v) end,
                }
            elseif kind == "dropdown" and node.get then
                out[#out + 1] = {
                    kind = "dropdown", dynamicItems = true,
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    disabled = makeDisabled(node),
                    items = function() return resolveItems(node) end,
                    get = function() return callGet(node) end,
                    set = function(v) callSet(node, v) end,
                }
            elseif kind == "input" and node.get then
                out[#out + 1] = {
                    kind = "input",
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    disabled = makeDisabled(node),
                    multiline = tonumber(node.multiline),
                    get = function() return tostring(callGet(node) or "") end,
                    set = function(v) callSet(node, v) end,
                }
            elseif kind == "color" and node.get then
                out[#out + 1] = {
                    kind = "color",
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    disabled = makeDisabled(node),
                    get = function() return readColor(node) end,
                    set = function(c) callSet(node, c) end,
                }
            elseif kind == "button" and node.func then
                out[#out + 1] = {
                    kind = "button",
                    label = tostring(node.name or ""),
                    tooltip = nodeTooltip(node),
                    disabled = makeDisabled(node),
                    func = function()
                        local ok = pcall(node.func, false)
                        if not ok and LPS.DEBUG then print("LPS options execute error: " .. tostring(node.name)) end
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
local function createTreePage(group)
    local Panel, Builder = LPS.UI.Panel, LPS.UI.Builder
    return function(container)
        local scroll, content = Panel.CreateScrollPage(container)
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
            local entries = collectRows(self._group, {})
            if #entries == 0 then
                -- пусто: оставляем страницу unbuilt — следующий Refresh
                -- (повторное открытие окна/вкладки) попробует собрать заново.
                self._built = false
                return
            end
            self._built = true
            -- пересборка поверх старых строк: удаляем прежние row-фреймы
            if content.rows then
                for _, row in ipairs(content.rows) do row:Hide(); row:ClearAllPoints() end
            end
            content.rows = {}
            local built = Builder.Build(content, entries, {
                onChange = function() Panel.OnSettingChanged() end,
                onRow = function(row) content.rows[#content.rows + 1] = row end,
            })
            -- переносим состояние построенной страницы в этот ленивый контейнер
            page.controls = built.controls
            page.height = built.height
            page.onChange = built.onChange
            -- подгоняем ширину и высоту скролл-контента под содержимое:
            -- без этого строки нулевой ширины остаются невидимыми (пустые вкладки)
            local cw = scroll:GetWidth()
            if cw and cw > 1 then content:SetWidth(cw) end
            if scroll.SetContentHeight then
                scroll:SetContentHeight(built.height)
            end
        end
        function page:Refresh()
            self:Build()
            Builder.RefreshPage(page)
        end
        -- Делегат OnValueChanged: без него любой клик по чекбоксу/слайдеру на
        -- ленивой странице падал с "attempt to call a nil value" (Builder.lua),
        -- из-за чего половина элементов вкладки оставалась непостроенной.
        function page:OnValueChanged(entry, value)
            local built = self.controls[1] and self.controls[1].entry and true or false
            if not built then return end
            local themeBefore = LPS.UI.Theme.key
            if entry.onChange then
                entry.onChange(value)
            elseif self.onChange then
                self.onChange(entry, value)
            end
            if LPS.UI.Theme.key == themeBefore then
                Builder.RefreshPage(self)
            end
        end
        -- если страница была построена до того, как фрейм получил реальные
        -- размеры (свернутое окно, первый кадр), достраиваем её после Show
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
local function pageKeyFor(node)
    -- ключ — имя таба в дереве (стабилен между пересборками и сменами локали)
    return "tree_" .. tostring(node._pageId or node.name or "")
end

--- Построение/обновление списка страниц по текущему дереву опций.
--- Идемпотентно: вызывается каждый раз при открытии окна, чтобы подтянуть
--- свежие переводы/вкладки после смены языка или профиля.
function UI.BuildPages()
    -- дерево пересобирается при каждом построении страниц: фабрики вкладок
    -- читают переводы L в момент вызова, поэтому смена языка (ApplyLocaleOverride)
    -- автоматически попадает в заголовки страниц.
    if LPS.Options.GetTree then
        LPS.Options.tree = LPS.Options:GetTree()
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
        -- страница регистрируется, если у узла есть args (даже когда первая
        -- попытка collectRows дала пусто: строки могут появиться позже —
        -- ленивая сборка в createTreePage пересоберёт их при следующем открытии)
        if node.args ~= nil then
            local key = pageKeyFor(node)
            if not UI._pageKeys[key] then
                UI._pageKeys[key] = true
                local create = createTreePage(node)
                -- страница профилей берётся из Game/Options/page_profiles.lua:
                -- дропдаун активного профиля + кнопки New/Copy/Delete/Reset
                -- и попапы. Если фабрика недоступна — остаётся обычная дерево-страница.
                if node._pageId == "profiles" and LPS.CreateProfilesPanelPage then
                    create = LPS.CreateProfilesPanelPage
                end
                Panel.RegisterPage(key, {
                    label = tostring(node.name or ""),
                    order = tonumber(node.order) or 99,
                    create = create,
                })
            end
        end
    end
end

UI._pageKeys = {}

--- Открыть/закрыть нативное окно (используется при отсутствии Ace3).
function UI.Toggle()
    local Panel = LPS.UI and LPS.UI.Panel
    if not Panel then return end
    UI.BuildPages()
    Panel.Toggle()
end

function UI.IsShown()
    local Panel = LPS.UI and LPS.UI.Panel
    return Panel and Panel.IsShown and Panel.IsShown()
end

function UI.Close()
    local Panel = LPS.UI and LPS.UI.Panel
    if Panel and Panel.Hide then Panel.Hide() end
end

--- Обновить активную страницу (вызывается из LPS.Options:ApplyRefresh).
function UI.RefreshActivePage()
    local Panel = LPS.UI and LPS.UI.Panel
    if Panel and Panel.RefreshActivePage and Panel.IsShown and Panel.IsShown() then
        Panel.RefreshActivePage()
    end
end
