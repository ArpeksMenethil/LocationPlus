local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local F = LPS.F

LPS.datatexts = {}

LPS.datatextsHiddenSlotKeys = { microBar = true }

--- Название панели для списков: ВСЕГДА актуально локализованное (язык
--- клиента). Раньше имя замораживалось в момент загрузки файла
--- (name = L.BAGS), а панели грузятся ПОСЛЕ datatexts.lua и до
--- полного построения локали — из-за этого списки сортировались по
--- АНГЛИЙСКИМ названиям ("Bags", "Mail"...), даже на русском клиенте.
--- Теперь хранится ключ перевода (def.nameKey), а перевод выполняется
--- при каждом обращении к имени.
function LPS:GetDatatextDisplayName(key)
    if key == "location" then return L.LOCATION end
    local def = LPS.datatexts[key]
    if def then
        if def.nameKey then return L[def.nameKey] or def.nameKey end
        if def.name then return tostring(def.name) end
    end
    return key
end

--- Список ключей панелей для слотов страницы макета.
--- Порядок: сначала "none" (не выбран фрейм), затем собственные панели
--- аддона, затем LDB-панели (префикс "LDB_"). В каждой группе — по
--- названию на языке клиента: сортировка выполняется ПОСЛЕ локализации,
--- компаратор каждый раз берёт свежий перевод через GetDatatextDisplayName.
--- Кэш сбрасывается при каждой новой регистрации панели.
LPS._datatextsSortedKeysCache = LPS._datatextsSortedKeysCache
function LPS:InvalidateDatatextsSortedKeys()
    LPS._datatextsSortedKeysCache = nil
end

function LPS:GetSlotKeyList()
    if not LPS._datatextsSortedKeysCache then
        local own, ldb = {}, {}
        for key in pairs(LPS.datatexts) do
            if not LPS.datatextsHiddenSlotKeys[key] then
                if key:sub(1, 4) == "LDB_" then
                    ldb[#ldb + 1] = key
                else
                    own[#own + 1] = key
                end
            end
        end
        local sortByName = function(arr)
            table.sort(arr, function(a, b)
                local na = tostring(LPS:GetDatatextDisplayName(a)):lower()
                local nb = tostring(LPS:GetDatatextDisplayName(b)):lower()
                if na == nb then return a < b end
                return na < nb
            end)
        end
        sortByName(own)
        sortByName(ldb)
        local keys = {}
        for i = 1, #own do keys[#keys + 1] = own[i] end
        for i = 1, #ldb do keys[#keys + 1] = ldb[i] end
        LPS._datatextsSortedKeysCache = keys
    end
    local keys = { "none" }
    for i = 1, #LPS._datatextsSortedKeysCache do
        keys[#keys + 1] = LPS._datatextsSortedKeysCache[i]
    end
    return keys
end

LPS.datatextsEventBridge = CreateFrame("Frame")
LPS._datatextsCreateQueueRegistered = false

--- Регистрирует панель инфотекста.
---@param def table { key, name, events, ticker, update(f), onClick(self,button), tooltip(tt), create(f) }
function LPS:RegisterDatatext(def)
    assert(def and def.key and (def.name or def.nameKey), "LPS RegisterDatatext: bad definition")
    LPS.datatexts[def.key] = def
    LPS:InvalidateDatatextsSortedKeys()
end

--- Создаёт фрейм панели по её конфигу (вызывается из ApplyLayout при первом использовании слота)
function LPS:CreateDatatextFrame(key)
    local def = LPS.datatexts[key]
    if not def then return nil end
    local db = LPS:GetDB()
    if not db or not LPS.frame.holder or not LPS.frame.location then return nil end
    local pCfg = db.panels and db.panels[key]
    if pCfg and pCfg.enable == false then return nil end

    local bgR, bgG, bgB, bgA = LPS:GetColor("bg")
    local bdR, bdG, bdB, bdA = LPS:GetColor("border")
    ---@type LPSFrameParams
    local params = {
        name = "LPS_" .. key:gsub("^%l", string.upper),
        frameType = "Button",
        parent = LPS.frame.holder or LPS.frame.location,
        anchor = { "CENTER", LPS.frame.holder or UIParent, "CENTER", 0, 0 },
        hidden = true,
        padding = { ((db.layout and db.layout.dtPaddingX) or 20), ((db.layout and db.layout.dtPaddingY) or 7) },
        fontSize = db.settings.fontSize or 12,
        bgColor = { bgR, bgG, bgB, bgA },
        borderColor = { bdR, bdG, bdB, bdA },
        updateFunc = function(f)
            local lay = LPS.GetDB and (LPS:GetDB().layout or {})
            local px = tonumber(lay and lay.dtPaddingX) or 20
            local py = tonumber(lay and lay.dtPaddingY) or 7
            f._lpsPaddingX = px
            f._lpsPaddingY = py
            f._lpsMinWidth = tonumber(lay and lay.dtMinWidth) or f._lpsMinWidth or 60
            if def.update then def.update(f) end
        end,
    }

    if def.events then
        params.updateEvent = { events = def.events }
    elseif def.ticker then
        params.updateTicker = { interval = def.ticker }
    end

    if def.onClick then
        params.registerClicks = def.clicks or { "LeftButtonUp", "RightButtonUp" }
        params.onClick = function(self, button) def.onClick(self, button) end
    end

    local builderName = "Build" .. key:gsub("^%l", string.upper) .. "Tooltip"
    if def.customTooltip and def.buildTooltip then
        params.tooltipFunc = function(self)
            LPS._lpsOursTooltip = nil
            if LPS.ResetTooltipFont then LPS:ResetTooltipFont(GameTooltip) end
            def.buildTooltip(self)
        end
    elseif def.tooltip or LPS[builderName] then
        params.tooltipFunc = function(self)
            if not LPS._DT.tooltipGuard(key) then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:ClearLines()
            LPS:ApplyTooltipFont(GameTooltip)
            local built = true
            if LPS[builderName] then
                built = LPS[builderName](LPS, GameTooltip)
            elseif def.tooltip then
                def.tooltip(GameTooltip)
            end
            if built == false then
                LPS._lpsOursTooltip = nil
                if LPS.ResetTooltipFont then LPS:ResetTooltipFont(GameTooltip) end
                GameTooltip:Hide()
                return
            end
            GameTooltip:Show()
        end
    end

    local function runCreateCallback()
        if not def.create then return true end
        local ok = pcall(def.create)
        return ok
    end

    local f = LPS:CreateFrame(params)
    if f then
        if InCombatLockdown() then
            f._lpsPendingCreate = def.create
            if not LPS._datatextsCreateQueueRegistered then
                LPS._datatextsCreateQueueRegistered = true
                LPS.datatextsEventBridge:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
        else
            runCreateCallback()
        end
        if f._lpsUpdateFunc then f._lpsUpdateFunc(f) end
        if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
        if LPS.ApplyLayout then LPS:ApplyLayout() end
    end
    return f
end

LPS.datatextsEvents = F.Events:New("LPS.Datatexts")
LPS.datatextsEvents:RegisterOnce("PLAYER_ENTERING_WORLD", function()
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    if LPS.ApplyLayout then LPS:ApplyLayout() end
end)

LPS.datatextsEventBridge:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_REGEN_ENABLED" then return end
    local done = true
    for _, f in pairs(LPS.frame or {}) do
        if type(f) == "table" and f._lpsPendingCreate then
            local ok = pcall(f._lpsPendingCreate)
            if ok then
                f._lpsPendingCreate = nil
            else
                done = false
            end
        end
    end
    if done then
        LPS._datatextsCreateQueueRegistered = false
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end)

function LPS:GetDatatextName(key)
    return LPS:GetDatatextDisplayName(key)
end

--- Публичный доступ к отсортированному по алфавиту списку ключей панелей
--- реализован выше через LPS:GetSlotKeyList().

function LPS:IsDatatextKey(key)
    return key ~= nil and LPS.datatexts[key] ~= nil
end

--- Возвращает фрейм панели по ключу слота (создаёт при необходимости)
local _lpsCreatingPanels = {}

function LPS:GetOrCreatePanelFrame(key)
    local frames = LPS.frame
    if not frames then return nil end
    if frames[key] then return frames[key] end
    local creating = _lpsCreatingPanels
    if creating[key] then return nil end
    creating[key] = true
    local f = LPS:CreateDatatextFrame(key)
    creating[key] = nil
    if f then
        frames[key] = f
        LPS:ScheduleFrameSizeUpdate()
    end
    return f
end
