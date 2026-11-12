local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

do
    ---@type table?
    local LDB

    --- Регистрирует панель для одного LDB-объекта
    ---@param name string имя объекта (например "WIM")
    ---@param obj table LDB-объект (прокси библиотеки)
    local function registerBroker(name, obj)
        if not name or not obj or not obj.type then return end
        if obj.type ~= "data source" and obj.type ~= "launcher" then return end

        local key = "LDB_" .. tostring(name):gsub("%W", "_")
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
                local logError = function(msg)
                    if LPS.Print then
                        LPS:Print(displayName .. " " .. msg)
                    end
                end
                local hasLines = function()
                    return tt:NumLines() > 0
                end

                local t = obj.tooltip
                if type(t) == "table" and type(t.show) == "function" then
                    local ok, err = pcall(t.show, obj, tt)
                    shown = ok and hasLines()
                    if not ok then
                        logError("tooltip.show: " .. tostring(err))
                    end
                end

                if not shown and type(obj.OnTooltipShow) == "function" then
                    local ok, err = pcall(obj.OnTooltipShow, obj, tt)
                    shown = ok and hasLines()
                    if not ok then
                        logError("OnTooltipShow: " .. tostring(err))
                    end
                end

                local f = LPS.frame and LPS.frame[key]
                if not shown and type(obj.OnEnter) == "function" and f then
                    local ok, err = pcall(obj.OnEnter, f)
                    shown = ok and hasLines()
                    if not ok then
                        logError("OnEnter: " .. tostring(err))
                    end
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
    local function init()
        if LDB then return end
        LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
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