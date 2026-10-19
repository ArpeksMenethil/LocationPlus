local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
LPS_DB = LPS_DB or {}

LPS.addon.version = (
        (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Version"))
                or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Version"))
                or "?.?.?"
) -- Версия аддона
LPS.addon.title = (
        (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Title"))
                or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Title"))
                or "?.?.?"
) -- Название аддона

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
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

----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.frame.holder:RegisterEvent("ADDON_LOADED")
LPS.frame.holder:SetScript("OnEvent", function(self, event, name)
        if name ~= LPS.addon.name then return end
        if event == "ADDON_LOADED" then LPS:onLoaded(name) end
end)

----------------------------------------------------------------
-- Собственная система профилей (без AceDB/Ace3).
-- Структура SavedVariables:
--   LPS_DB = { profiles = { [имя] = {...настройки...} },
--              profileKeys = { ["realm - character"] = имя },
--              global = { gold = { realms = {...} } } }
----------------------------------------------------------------
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
        -- золото всегда в global (по аккаунту), раньше лежало в корне/профилях
        if type(sv.gold) == "table" and not sv.global.gold then
                sv.global.gold = sv.gold
        end
        sv.gold = nil
        if not (sv.profiles or sv.profileKeys) then
                -- плоская структура старой версии: всё, кроме служебных ключей,
                -- переносим в профиль Default
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
        -- привязка к несуществующему профилю -> Default
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

function LPS:onLoaded(name)
        if self._loaded then return end
        self._loaded = true

    -- Язык аддона: переопределение из SavedVariables (система CharacterStats:
    -- Locales/enUS.lua определяет LPS.RegisterLocale / LPS.ApplyLocaleOverride).
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
        LPS.frame.location = LPS.CreateLocationFrame()
        LPS:ApplyAllSettings()
        if LPS.ApplyAddonCompartmentRegistration then
                LPS:ApplyAddonCompartmentRegistration()
        end
        if LPS.CreateMinimapButton then
                LPS:CreateMinimapButton()
        end

        if LPS.Retail and db.general.is24H then
            SetCVar("timeMgrUseMilitaryTime", 1)
        end

        if IsLoggedIn and IsLoggedIn() then
                LPS:UpdateFrameSize()
                LPS:ApplyLayout()
        else
                local f = CreateFrame("Frame")
                f:RegisterEvent("PLAYER_ENTERING_WORLD")
                f:SetScript("OnEvent", function(self)
                        self:UnregisterAllEvents()
                        LPS:UpdateFrameSize()
                        LPS:ApplyLayout()
                end)
                C_Timer.After(1, function()
                        LPS:UpdateFrameSize()
                        LPS:ApplyLayout()
                end)
        end

        if db and db.general and db.general.loginMessage then
                LPS:Print(format(L.LOADED_CURRENT_VERSION..": |c%sv%s|r", LPS.addon.textColor, LPS.addon.version), false)
        end
end

--- Возвращает список slash-команд аддона для страницы «О модификации».
function LPS:GetCommandList()
        return {
                { cmd = "/lps",             desc = L.OPEN_OPTIONS_WINDOW },
                { cmd = "/lps reset",       desc = L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES },
                { cmd = "/lps resetpanels", desc = L.PANEL_SETTINGS_HAVE_BEEN_RESET_TO_DEFAULTS },
                { cmd = "/lps move",        desc = L.CMD_MOVE },
                { cmd = "/lps resetpos",    desc = L.CMD_RESET_POSITION },
        }
end

SLASH_LPS1 = "/lps"
SlashCmdList["LPS"] = function(input)
        local arg = (input or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if arg == "reset" then
                if LPS.ResetAllSettingsToDefaults then
                        LPS:ResetAllSettingsToDefaults()
                        LPS:Print(L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES)
                end
        elseif arg == "resetpanels" then
                if LPS.ResetPanelsToDefaults then
                        LPS:ResetPanelsToDefaults()
                        LPS:Print(L.PANEL_SETTINGS_HAVE_BEEN_RESET_TO_DEFAULTS)
                end
        elseif arg == "move" then
                if LPS.ToggleMoveMode then
                        LPS:ToggleMoveMode()
                end
        elseif arg == "resetpos" then
                if LPS.ResetFramePosition then
                        LPS:ResetFramePosition()
                end
        else
                LPS:ToggleOptions()
        end
end
