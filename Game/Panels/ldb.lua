local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

do
    ---@type LPSLDB?
    local LDB

    --- Регистрирует панель для одного LDB-объекта
    ---@param name string имя объекта (например "WIM")
    ---@param obj table LDB-объект (прокси библиотеки)
    local function registerBroker(name, obj)
        if not name or not obj or not obj.type then return end
        if obj.type ~= "data source" and obj.type ~= "launcher" then return end

        --- Ключ панели: кириллица и латиница сохраняются, только ASCII-
        --- символы/пробелы заменяются на «_», серии подчёркиваний
        --- схлопываются. Наивный gsub("%W", "_") превращал кириллицу в
        --- подчёркивания (Lua 5.1 без UTF-8), из-за чего два брокера с
        --- русскими именами получали одинаковый ключ, а второй
        --- замечался без предупреждения.
        local key = ("LDB_" .. tostring(name):gsub("[%p%s]", "_")):gsub("%_+", "_"):gsub("_+$", "")
        if LPS.datatexts[key] then return end

        local displayName = "LDB: " .. tostring(name)

        LPS:RegisterDatatext({
            key = key,
            name = displayName,
            ticker = 1,
            update = function(f)
                if not f.text then return end
                local text = obj.text
                if not text or text == "" then
                    f.text:SetText(displayName)
                else
                    f.text:SetText(tostring(text))
                end
            end,
            clicks = { "LeftButtonUp", "RightButtonUp", "MiddleButtonUp" },
            onClick = function(f, button)
                if type(obj.OnClick) ~= "function" then return end
                local ok, err = pcall(obj.OnClick, f, button)
                if not ok then
                    if LPS.Print then
                        LPS:Print(displayName .. " OnClick: " .. tostring(err))
                    end
                end
            end,
            tooltip = function(tt)
                local shown = false
                local hasLines = function()
                    return tt:NumLines() > 0
                end

                local t = obj.tooltip
                if type(t) == "table" and type(t.show) == "function" then
                    local ok, err = pcall(t.show, obj, tt)
                    shown = ok and hasLines()
                    if not ok and LPS.Print then
                        LPS:Print(displayName .. " tooltip.show: " .. tostring(err))
                    end
                end

                --- Callback'и 1.1 вызываем без self (первый аргумент —
                --- сам tooltip). Ошибки стороннего кода глотаем молча:
                --- просто отступаем на строку с именем объекта.
                if not shown and type(obj.OnTooltipShow) == "function" then
                    local ok = pcall(obj.OnTooltipShow, tt)
                    shown = ok and hasLines()
                end

                local f = LPS.frame and LPS.frame[key]
                if not shown and type(obj.OnEnter) == "function" and f then
                    local ok = pcall(obj.OnEnter, f)
                    shown = ok and hasLines()
                end

                if not shown then
                    tt:AddLine(displayName)
                end
                return true
            end,
        })
    end

    --- Инициализация: найти библиотеку и зарегистрировать все объекты.
    --- Вызывается при загрузке и при каждом ADDON_LOADED, пока библиотека
    --- не найдена (WIM регистрирует свой объект именно на ADDON_LOADED,
    --- если библиотека появилась позже).
    local bridge
    ---@return any
    local function getLDB()
        return LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
    end
    local function init()
        if LDB then return end
        LDB = getLDB()
        if not LDB then return end

        LDB.RegisterCallback(bridge, "LibDataBroker_DataObjectCreated", function(_, name, obj)
            registerBroker(name, obj)
        end)
        for name, obj in LDB:DataObjectIterator() do
            registerBroker(name, obj)
        end
        if bridge then
            bridge:UnregisterEvent("ADDON_LOADED")
        end
    end

    if LibStub then
        bridge = CreateFrame("Frame")
        bridge:SetScript("OnEvent", function()
            init()
        end)
        bridge:RegisterEvent("ADDON_LOADED")
    end
    init()
end