local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------- LDB-брокеры (LibDataBroker-1.1)
-- Тот же подход, что у ElvUI (DataTexts: SetupObjectLDB / RegisterLDB):
-- объекты берутся из общей библиотеки LibDataBroker-1.1, зарегистрированной
-- самими аддонами (например WIM/Modules/ldb.lua регистрирует "WIM").
-- Функционал НЕ дублируем: текст — obj.text, клик — obj.OnClick(f, button),
-- тултип — obj.OnTooltipShow(tooltip) — всё предоставляет сам брокер.
-- Имя панели получает приписку "LDB: AddonName" — как у ElvUI
-- (localizedName = 'LDB: '..name).
do
    ---@type table?
    local LDB

    --- Регистрирует панель для одного LDB-объекта
    ---@param name string имя объекта (например "WIM")
    ---@param obj table LDB-объект (прокси библиотеки)
    local function registerBroker(name, obj)
        if not name or not obj or not obj.type then return end
        -- Как у ElvUI: только источники данных и лаунчеры
        if obj.type ~= "data source" and obj.type ~= "launcher" then return end

        -- Ключ панели — без спецсимволов (в именах объектов бывают
        -- двоеточия и пробелы, например "Broker: Time")
        local key = "LDB_" .. tostring(name):gsub("%W", "_")
        if LPS.datatexts[key] then return end

        local displayName = "LDB: " .. tostring(name)

        LPS:RegisterDatatext({
            key = key,
            name = displayName,
            -- Опрос раз в секунду: WIM сам обновляет obj.text своим
            -- 1-секундным OnUpdate-фреймом (как и его LDB-иконка)
            ticker = 1,
            update = function(f)
                local text = obj.text
                if not text or text == "" then return end
                if f.text then
                    f.text:SetText(tostring(text))
                end
            end,
            clicks = { "LeftButtonUp", "RightButtonUp", "MiddleButtonUp" },
            -- Делегируем клики самому брокеру (у WIM — полный разбор
            -- ЛКМ/ПКМ/Shift+ПКМ/Shift+СКМ и настройка rightClickNew)
            onClick = function(f, button)
                if type(obj.OnClick) ~= "function" then return end
                local ok, err = pcall(obj.OnClick, f, button)
                if not ok then
                    if LPS.Print then
                        LPS:Print(displayName .. " OnClick: " .. tostring(err))
                    end
                end
            end,
            -- Тултип брокера (у WIM — "WIM <версия>" + уведомления)
            tooltip = function(tt)
                if type(obj.OnTooltipShow) == "function" then
                    local ok = pcall(obj.OnTooltipShow, obj, tt)
                    if not ok then
                        tt:Hide()
                        return false
                    end
                    return true
                end
                tt:AddLine(displayName)
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

        -- Позднее появление объектов (например WIM на ADDON_LOADED).
        -- CallbackHandler-1.0 вызывает метод как method(self, ...) — первым
        -- аргументом приходит "self" (мост), поэтому оборачиваем.
        LDB.RegisterCallback(bridge, "LibDataBroker_DataObjectCreated", function(_, name, obj)
            registerBroker(name, obj)
        end)
        -- Уже существующие объекты (как DT:RegisterLDB у ElvUI)
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