local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local F = LPS.F
LPS_DB = LPS_DB or {}

LPS.addon.version = (
    (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Version"))
    or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Version"))
    or "?.?.?"
)
LPS.addon.title = (
    (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Title"))
    or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Title"))
    or "?.?.?"
)

--- Описание аддона: Notes из .toc для текущего языка клиента (fallback на enUS).
function LPS:GetAddonNotes()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata)
        or GetAddOnMetadata
    if not (getMeta and LPS.addon.name) then return "" end
    local locale = LPS.ACTIVE_LOCALE or GetLocale()
    local notes = getMeta(LPS.addon.name, "Notes-" .. tostring(locale))
        or getMeta(LPS.addon.name, "Notes") or ""
    return (notes ~= "") and notes or ""
end

---@type LPSFrameParams
local params = {
    name = "LPS_Holder",
    parent = UIParent,
    frameType = "Frame",
    size = {400, 25},
    backdrop = { bgFile = "Interface\\Buttons\\WHITE8x8" },
    bgColor = {1, 1, 1, 0},
    borderColor = {1, 1, 1, 0}
}
LPS.frame.holder = LPS:CreateFrame(params)
LPS.frame.holder:SetFrameStrata("HIGH")

LPS.Lifecycle = F.Lifecycle:New(LPS, LPS.addon.name)
LPS.Lifecycle:OnAddonLoaded(function()
    LPS:onLoaded()
end)

local svMeta = {}
svMeta.__index = svMeta

function svMeta:GetCurrentProfile()
    return self.sv.profileKeys[self.charKey] or "Default"
end

--- Переключает текущий персонажа на профиль name (создаёт, если нет).
function svMeta:SetProfile(name)
    if type(name) ~= "string" or name == "" then return end
    if self.sv.profiles[name] == nil then self.sv.profiles[name] = {} end
    self.sv.profileKeys[self.charKey] = name
    self.profile = self.sv.profiles[name]
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Копирует настройки профиля srcName в ТЕКУЩИЙ профиль.
function svMeta:CopyProfileFrom(srcName)
    local src = self.sv.profiles[srcName]
    if type(src) ~= "table" then return end
    local dst = self.profile
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(src) do dst[k] = LPS.OptionsHelper:deepCopy(v) end
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Удаляет профиль name; привязанные персонажи переводятся на Default.
function svMeta:DeleteProfile(name)
    if name == "Default" or self.sv.profiles[name] == nil then return end
    self.sv.profiles[name] = nil
    for ck, pn in pairs(self.sv.profileKeys) do
        if pn == name then self.sv.profileKeys[ck] = "Default" end
    end
    self.profile = self.sv.profiles[self:GetCurrentProfile()]
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Сбрасывает ТЕКУЩИЙ профиль к дефолтам (не подменяя объект SavedVariables).
function svMeta:ResetProfile()
    local fresh = CopyTable(LPS.defaults) or {}
    fresh.gold = nil
    local dst = self.profile
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(fresh) do dst[k] = v end
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

function svMeta:GetProfilesList()
    local list = {}
    for name in pairs(self.sv.profiles) do list[#list + 1] = name end
    table.sort(list)
    return list
end

--- Миграция старых/плоских SavedVariables в профилевую структуру и создание БД.
local function InitDB()
    local sv = _G.LPS_DB
    if type(sv) ~= "table" then sv = {}; _G.LPS_DB = sv end
    sv.global = sv.global or {}
    if type(sv.gold) == "table" and not sv.global.gold then
        sv.global.gold = sv.gold
    end
    sv.gold = nil
    if not (sv.profiles or sv.profileKeys) then
        local flat = {}
        for k, v in pairs(sv) do
            if k ~= "global" and k ~= "profiles" and k ~= "profileKeys" then
                flat[k] = v
                sv[k] = nil
            end
        end
        sv.profiles = { Default = flat }
    elseif sv.profiles then
        for _, p in pairs(sv.profiles) do
            if type(p) == "table" and p.gold then
                if not sv.global.gold then sv.global.gold = p.gold end
                p.gold = nil
            end
        end
    else
        sv.profiles = { Default = {} }
    end
    if type(sv.profileKeys) ~= "table" then sv.profileKeys = {} end
    for ck, pk in pairs(sv.profileKeys) do
        if type(pk) ~= "string" or sv.profiles[pk] == nil then
            sv.profileKeys[ck] = "Default"
        end
    end
    if sv.profiles.Default == nil then sv.profiles.Default = {} end

    local charKey = (GetRealmName and GetRealmName() or "") .. " - " .. (UnitName and UnitName("player") or "")
    if sv.profileKeys[charKey] == nil then
        sv.profileKeys[charKey] = "Default"
    end
    local profName = sv.profileKeys[charKey]
    if sv.profiles[profName] == nil then sv.profiles[profName] = {} end

    local db = setmetatable({
        sv = sv,
        charKey = charKey,
        profile = sv.profiles[profName],
        global = sv.global,
    }, svMeta)
    LPS.sv = sv
    LPS.db = db
end

function LPS:onLoaded()
    if self._loaded then return end
    self._loaded = true

    if LPS.ApplyLocaleOverride then
        LPS.ApplyLocaleOverride(_G.LPS_DB and _G.LPS_DB.localeOverride)
    end

    InitDB()

    if LPS.DEBUG then
        LPS:Print("WOW PATCH: "..LPS.wow.patch, false)
        LPS:Print("WOW BUILD: "..LPS.wow.build, false)
        LPS:Print("WOW DATE: "..LPS.wow.date, false)
        LPS:Print("WOW TOC: "..LPS.wow.toc, false)
        LPS:Print("WOW PROJECT: "..LPS.wow.project, false)
    end

    local db = LPS:GetDB()
    LPS:ApplyDefaults(db or {}, LPS.defaults)
    LPS:ApplyTimeFormat()
    LPS:ApplyHolderPosition()
    LPS.frame.location = LPS:CreateLocationFrame()
    LPS:ApplyAllSettings()
    if LPS.ApplyAddonCompartmentRegistration then
        LPS:ApplyAddonCompartmentRegistration()
    end
    if LPS.CreateMinimapButton then
        LPS:CreateMinimapButton()
    end

    if LPS.RegisterSettingsCategory then
        LPS:RegisterSettingsCategory()
    end

    if LPS.Retail and db.general.is24H then
        SetCVar("timeMgrUseMilitaryTime", 1)
    end

    if IsLoggedIn and IsLoggedIn() then
        LPS:UpdateFrameSize()
        LPS:ApplyLayout()
    else
        LPS.coreEvents = F.Events:New("LPS.Core")
        LPS.coreEvents:RegisterOnce("PLAYER_ENTERING_WORLD", function()
            LPS:UpdateFrameSize()
            LPS:ApplyLayout()
        end)
        C_Timer.After(1, function()
            LPS:UpdateFrameSize()
            LPS:ApplyLayout()
        end)
    end

    if db and db.general and db.general.loginMessage then
        LPS:Print(format(L.LOADED_CURRENT_VERSION.." |c%sv%s|r", LPS.addon.textColor, LPS.addon.version), false)
    end
end

local cmd = F.Commands:New({
    name = "LocationPlus",
    slashes = { "/lps" },
    description = L.CMD_DESCRIPTION,
    defaultHandler = function()
        LPS:ToggleOptions()
    end,
    unknownMessage = function(input)
        return format(L.CMD_UNKNOWN, input)
    end,
})
cmd:Register({
    name = "reset",
    help = L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES,
    handler = function()
        if LPS.ResetAllSettingsToDefaults then
            LPS:ResetAllSettingsToDefaults()
            LPS:Print(L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES)
        end
    end,
})
cmd:Register({
    name = "resetpanels",
    help = L.RESET_VALUES,
    handler = function()
        if LPS.ResetPanelsToDefaults then
            LPS:ResetPanelsToDefaults()
            LPS:Print(L.PANEL_SETTINGS_HAVE_BEEN_RESET_TO_DEFAULTS)
        end
    end,
})
cmd:Register({
    name = "move",
    help = L.TOGGLE_PANEL_MOVE_MODE,
    handler = function()
        if LPS.ToggleMoveMode then
            LPS:ToggleMoveMode()
        end
    end,
})
cmd:Register({
    name = "resetpos",
    help = L.RESET_POSITION_DESC,
    handler = function()
        if LPS.ResetFramePosition then
            LPS:ResetFramePosition()
        end
    end,
})
LPS.cmd = cmd
