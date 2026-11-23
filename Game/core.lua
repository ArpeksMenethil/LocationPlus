local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
LPS_DB = LPS_DB or {}

LPS.addon.version = (
    (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Version"))
    or (LPS.GetAddOnMetadata and LPS.GetAddOnMetadata(LPS.addon.name, "Version"))
    or "?.?.?"
)
LPS.addon.title = (
    (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Title"))
    or (LPS.GetAddOnMetadata and LPS.GetAddOnMetadata(LPS.addon.name, "Title"))
    or "?.?.?"
)

--- Описание аддона: Notes из .toc для текущего языка клиента (fallback на enUS).
function LPS:GetAddonNotes()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata)
        or LPS.GetAddOnMetadata
    if not (getMeta and LPS.addon.name) then return "" end
    local locale = LPS.ACTIVE_LOCALE or GetLocale()
    local notes = getMeta(LPS.addon.name, "Notes-" .. tostring(locale))
        or getMeta(LPS.addon.name, "Notes") or ""
    return (notes ~= "") and notes or ""
end

function LPS:SVGetCurrentProfile()
    return self.db.sv.profileKeys[self.db.charKey] or "Default"
end

--- Переключает текущего персонажа на профиль name (создаёт, если нет).
--- @param name string
function LPS:SVSetProfile(name)
    local db = self.db
    if type(name) ~= "string" or name == "" then return end
    if db.sv.profiles[name] == nil then db.sv.profiles[name] = {} end
    db.sv.profileKeys[db.charKey] = name
    db.profile = db.sv.profiles[name]
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Копирует настройки профиля srcName в ТЕКУЩИЙ профиль.
--- @param srcName string
function LPS:SVCopyProfileFrom(srcName)
    local db = self.db
    local src = db.sv.profiles[srcName]
    if type(src) ~= "table" then return end
    local dst = db.profile
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(src) do dst[k] = LPS:DeepCopy(v) end
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Удаляет профиль name; привязанные персонажи переводятся на Default.
--- @param name string
function LPS:SVDeleteProfile(name)
    local db = self.db
    if name == "Default" or db.sv.profiles[name] == nil then return end
    db.sv.profiles[name] = nil
    for ck, pn in pairs(db.sv.profileKeys) do
        if pn == name then db.sv.profileKeys[ck] = "Default" end
    end
    db.profile = db.sv.profiles[LPS:SVGetCurrentProfile()]
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

--- Сбрасывает ТЕКУЩИЙ профиль к дефолтам (не подменяя объект SavedVariables).
function LPS:SVResetProfile()
    local fresh = CopyTable(LPS.defaults) or {}
    fresh.gold = nil
    local dst = self.db.profile
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(fresh) do dst[k] = v end
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
    if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
end

function LPS:SVGetProfilesList()
    local list = {}
    for name in pairs(self.db.sv.profiles) do list[#list + 1] = name end
    table.sort(list)
    return list
end

--- Миграция старых/плоских SavedVariables в профилевую структуру и создание БД.
function LPS:InitDB()
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

    LPS.sv = sv
    LPS.db = {
        sv = sv,
        charKey = charKey,
        profile = sv.profiles[profName],
        global = sv.global,
    }
end

function LPS:onLoaded()
    if self._loaded then return end
    self._loaded = true

    if LPS.ApplyLocaleOverride then
        LPS:ApplyLocaleOverride(_G.LPS_DB and _G.LPS_DB.localeOverride)
    end

    LPS:InitDB()

    --- Тумблер режима отладки (только у разработчика): состояние хранится на аккаунт.
    if LPS.IsDev then
        local a = LPS:GetAccountDB()
        LPS.DEBUG = a.debugMode ~= false
    end

    if LPS.DEBUG then
        LPS:Print("WOW PATCH: "..LPS.wow.patch, false)
        LPS:Print("WOW BUILD: "..LPS.wow.build, false)
        LPS:Print("WOW DATE: "..LPS.wow.date, false)
        LPS:Print("WOW TOC: "..LPS.wow.toc, false)
        LPS:Print("WOW PROJECT: "..LPS.wow.project, false)
    end

    local db = LPS:GetDB()
    LPS:ApplyDefaults(db or {}, LPS.defaults)

    --- Одноразовая очистка для тех, кто обновился до этой версии:
    --- данные о золоте всех персонажей (все серверы); флаг UPDATE_2_2_0
    --- после очистки становится true.
    if db.UPDATE_2_2_0 ~= true then
        local goldRoot = LPS:GetGoldRoot()
        local wiped = 0
        for k in pairs(goldRoot) do
            goldRoot[k] = nil
            wiped = wiped + 1
        end
        db.UPDATE_2_2_0 = true
        if wiped > 0 then
            LPS:Print(L.LPS_GOLD_WIPE_MSG or "All gold data (all servers) has been cleared in the new version.", false)
            if LPS.DEBUG then
                LPS:Print(format("[debug] gold data wiped: %d entries", wiped), false)
            end
        end
    end

    LPS:ApplyTimeFormat()
    LPS.frame.location = LPS:CreateLocationFrame()
    LPS:ApplyLocationPosition()
    LPS:ApplyAllSettings()
    if LPS.ApplyAddonCompartmentRegistration then
        LPS:ApplyAddonCompartmentRegistration()
    end
    if LPS.CreateMinimapButton then
        LPS:CreateMinimapButton()
    end
    if LPS.EditModeRegisterFrame then
        LPS:EditModeRegisterFrame()
    end

    if LPS.RegisterSettingsCategory then
        LPS:RegisterSettingsCategory()
    end

    if LPS.Retail and db.general.is24H then
        SetCVar("timeMgrUseMilitaryTime", 1)
    end

    LPS.coreEvents = LPS.Events:New("LPS.Core")
    LPS.coreEvents:Register("PLAYER_ENTERING_WORLD", function()
        LPS:ApplyLayout()
        if not LPS:EditModeIsEditing() then
            LPS:ApplyLocationPosition()
            LPS:RepairLocationLayoutCache()
        end
    end)

    if IsLoggedIn and IsLoggedIn() then
        LPS:ApplyLayout()
        if not LPS:EditModeIsEditing() then
            LPS:ApplyLocationPosition()
        end
    end
    --- Клиент применяет свой кэш раскладки (layout-local.txt) по завершении
    --- загрузки мира — это может быть заметно позже PEW. Держим позицию из DB
    --- под контролем ~35 секунд после логина (не трогаем во время драга из
    --- редактора интерфейса).
    local loginTicks = 0
    local function runLoginTick()
        loginTicks = loginTicks + 1
        if loginTicks == 1 then
            LPS:ApplyLayout()
        end
        if not LPS:EditModeIsEditing() then
            LPS:ApplyLocationPosition()
            LPS:RepairLocationLayoutCache()
        end
        if loginTicks < 14 then
            C_Timer.After(2.5, runLoginTick)
        end
    end
    C_Timer.After(1, runLoginTick)

    if db and db.general and db.general.loginMessage then
        LPS:Print(format(L.LOADED_CURRENT_VERSION.." |c%sv%s|r", LPS.addon.textColor, LPS.addon.version), false)
    end
end

--- Запуск onLoaded по PLAYER_ENTERING_WORLD / при уже вошедшем игроке: на
--- клиентах с region-unique именами (Forever/Camelot) фамилия может
--- «уладиться» только после входа в мир. Ключ профиля — realm - UnitName
--- (без фамилии), поэтому запуск безопасен.
LPS._bootFrame = CreateFrame("Frame")
LPS._bootFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LPS._bootFrame:SetScript("OnEvent", function(_, ev)
    if ev == "PLAYER_ENTERING_WORLD" then
        LPS:onLoaded()
    end
end)
if IsLoggedIn and IsLoggedIn() then
    LPS:onLoaded()
end

--- Слэш-команда /lps: реестр подкоманд с алиасами, автогенерация помощи
--- (/lps help), fallback на настройки и сообщение об неизвестной команде.
local commands = {}
local commandOrder = {}

local function defineCommand(name, handler, opts)
    local lower = name:lower()
    if commands[lower] then
        error("LPS command collision: " .. lower, 2)
    end
    local entry = {
        name = name,
        handler = handler,
        aliases = {},
        help = (opts and opts.help) or "",
    }
    commands[lower] = entry
    commandOrder[#commandOrder + 1] = lower
    if opts and type(opts.aliases) == "table" then
        for _, alias in ipairs(opts.aliases) do
            local al = alias:lower()
            if commands[al] then
                error("LPS command alias collision: " .. al, 2)
            end
            commands[al] = entry
            entry.aliases[#entry.aliases + 1] = alias
        end
    end
end

local function findCommand(input)
    local lowered = input:lower()
    local best, bestLen
    for key, entry in pairs(commands) do
        local klen = #key
        if (not bestLen or klen > bestLen)
            and (lowered == key
                or (lowered:sub(1, klen) == key and lowered:sub(klen + 1, klen + 1) == " ")) then
            best = entry
            bestLen = klen
        end
    end
    if not best then return nil end
    return best, (input:sub(bestLen + 1)):match("^%s*(.-)%s*$")
end

local function printHelp()
    LPS:Print(L.CMD_DESCRIPTION)
    for _, key in ipairs(commandOrder) do
        local entry = commands[key]
        local aliases = {}
        for _, alias in ipairs(entry.aliases) do
            aliases[#aliases + 1] = alias
        end
        table.sort(aliases)
        local line = "/lps " .. entry.name
        if #aliases > 0 then
            line = line .. " (" .. table.concat(aliases, ", ") .. ")"
        end
        if entry.help ~= "" then
            line = line .. "  -- " .. entry.help
        end
        LPS:Print(line)
    end
end

if not _G["SLASH_" .. "LOCATIONPLUS1"] then
    _G["SLASH_" .. "LOCATIONPLUS1"] = "/lps"
end
SlashCmdList["LOCATIONPLUS"] = function(input)
    local trimmed = (input or ""):match("^%s*(.-)%s*$")
    if trimmed == "" then
        LPS:ToggleOptions()
        return
    end
    local lowered = trimmed:lower()
    if lowered == "help" or lowered:match("^help%s") then
        printHelp()
        return
    end
    local entry, args = findCommand(trimmed)
    if entry then
        entry.handler(args)
        return
    end
    LPS:Print(format(L.CMD_UNKNOWN, trimmed))
end

defineCommand("reset", function()
    if LPS.ResetAllSettingsToDefaults then
        LPS:ResetAllSettingsToDefaults()
        LPS:Print(L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES)
    end
end, {
    help = L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES,
})

defineCommand("resetpanels", function()
    if LPS.ResetPanelsToDefaults then
        LPS:ResetPanelsToDefaults()
        LPS:Print(L.PANEL_SETTINGS_HAVE_BEEN_RESET_TO_DEFAULTS)
    end
end, {
    help = L.RESET_VALUES,
})

defineCommand("resetpos", function()
    if LPS.ResetFramePosition then
        LPS:ResetFramePosition()
    end
end, {
    help = L.RESET_POSITION_DESC,
})
function LPS:BuildDebugReport()
    local lines = {}
    local function p(msg) lines[#lines + 1] = msg end
        local function section(title) p("=== " .. title .. " ===") end
        local function norm(k) return (tostring(k):lower():gsub("[^%w%d]", "")) end

        local function safe(label, fn)
            local ok, res = pcall(fn)
            if ok then p(label .. " = " .. tostring(res)) else p(label .. " = ERROR: " .. tostring(res)) end
        end

        local function keysOf(t)
            if type(t) ~= "table" then return "(not a table: " .. type(t) .. ")" end
            local k = {}
            for key in pairs(t) do k[#k + 1] = tostring(key) end
            table.sort(k)
            return #k .. " keys: [" .. (table.concat(k, ", ") or "(empty)") .. "]"
        end

        local function ptable(t, label)
            if type(t) ~= "table" then p(label .. " = " .. tostring(t)); return end
            local list = {}
            for k, v in pairs(t) do
                list[#list + 1] = tostring(k) .. "=" .. (type(v) == "table" and "<table>" or tostring(v))
            end
            table.sort(list)
            p(label .. ": " .. (table.concat(list, ", ") or "(empty)"))
        end

        local function frameShown(f)
            if type(f) ~= "table" or type(f.IsShown) ~= "function" then return "?" end
            local ok, shown = pcall(f.IsShown, f)
            return ok and tostring(shown) or "?"
        end

        section("LPS DEBUG (v" .. tostring(LPS.addon and LPS.addon.version) .. ")")

        section("CLIENT")
        safe("wow.patch", function() return LPS.wow and LPS.wow.patch or "?" end)
        safe("wow.build", function() return LPS.wow and LPS.wow.build or "?" end)
        safe("wow.date", function() return LPS.wow and LPS.wow.date or "?" end)
        safe("wow.toc", function() return LPS.wow and LPS.wow.toc or "?" end)
        safe("wow.project", function() return LPS.wow and LPS.wow.project or "?" end)

        section("ADDON")
        p("name = " .. tostring(LPS.addon and LPS.addon.name))
        p("version = " .. tostring(LPS.addon and LPS.addon.version))
        p("_loaded = " .. tostring(LPS._loaded))
        safe("IsLoggedIn()", function() return IsLoggedIn() end)
        safe("InCombatLockdown()", function() return InCombatLockdown() end)

        section("API")
        p("External libraries: none (native Blizzard APIs only)")
        p("LPS.Events = " .. tostring(type(LPS.Events) == "table"))
        p("LPS.Commands: " .. (next(commands) and "ok" or "MISSING"))
        p("Tourist (LPS.Tourist) exists = " .. tostring(LPS.Tourist ~= nil))
        safe("LibDataBroker-1.1", function() return LibStub and (LibStub("LibDataBroker-1.1", true) ~= nil) end)
        safe("LibDBIcon-1.0", function() return LibStub and (LibStub("LibDBIcon-1.0", true) ~= nil) end)

        section("PLAYER")
        safe("GetPlayerFullName()", function() return LPS:GetPlayerFullName() end)
        safe("UnitName('player')", function() return UnitName("player") end)
        safe("GetRealmName()", function() return GetRealmName() end)
        safe("GetNormalizedRealmName()", function() return GetNormalizedRealmName() end)
        safe("GetGoldRealmKey()", function() return LPS:GetGoldRealmKey() end)
        safe("GetFaction()", function() return (GetFaction and GetFaction()) or "n/a" end)
        safe("UnitFactionGroup('player')", function() return UnitFactionGroup("player") end)

        section("MAP")
        safe("GetBestMapForUnit('player')", function()
            return (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")) or "?"
        end)
        safe("zone name (C_Map.GetMapInfo)", function()
            local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if not mapID or not C_Map or not C_Map.GetMapInfo then return "?" end
            local ok, info = pcall(C_Map.GetMapInfo, mapID)
            return (ok and info and info.name) or "?"
        end)

        section("DB")
        p("LPS.db keys: " .. keysOf(LPS.db))
        p("charKey = [" .. tostring(LPS.db and LPS.db.charKey) .. "]")
        safe("sv.current profile", function() return LPS:SVGetCurrentProfile() end)
        safe("AccountDB (global) keys", function() return keysOf(LPS:GetAccountDB()) end)
        safe("ProfileDB keys", function() return keysOf(LPS:GetDB()) end)

        section("GOLD")
        local key = LPS:GetGoldRealmKey()
        local gold = LPS:GetGoldRoot()
        local realms = gold and gold.realms
        if not (realms and next(realms)) then
            p("gold.realms: EMPTY (no characters stored yet)")
        else
            local n = 0
            for rk, rt in pairs(realms) do
                n = n + 1
                local ccount, names = 0, {}
                for cn, ci in pairs((rt and rt.chars) or {}) do
                    ccount = ccount + 1
                    names[#names + 1] = tostring(cn) .. "=" .. tostring(ci and ci.money)
                end
                p(string.format("  realm[%d]=[%s] chars=%d exact=%s normMatch=%s | %s",
                    n, tostring(rk), ccount,
                    tostring(rk == key),
                    tostring(norm(rk) == norm(key) and norm(key) ~= ""),
                    table.concat(names, ", ")))
            end
        end
        local dk, dt = LPS:GetGoldRealmTable()
        local dcount = 0
        for _ in pairs((dt and dt.chars) or {}) do dcount = dcount + 1 end
        p("GetGoldRealmTable() -> key=[" .. tostring(dk) .. "] chars=" .. tostring(dcount))

        section("FRAMES (LPS.frame)")
        p("keys: " .. keysOf(LPS.frame))
        if type(LPS.frame) == "table" then
            local names = {}
            for key2, f in pairs(LPS.frame) do
                local shown = frameShown(f)
                if key2 == "_posGeometry" and type(f) == "table" then
                    shown = "{point=" .. tostring(f.point) .. " relPoint=" .. tostring(f.relPoint)
                        .. " x=" .. tostring(f.x) .. " y=" .. tostring(f.y) .. "}"
                end
                names[#names + 1] = tostring(key2) .. "=" .. shown
            end
            table.sort(names)
            p("shown: " .. table.concat(names, ", "))
        end

        section("DATATEXTS (LPS.datatexts)")
        p(keysOf(LPS.datatexts))

        section("SETTINGS (profile)")
        local db = LPS:GetDB()
        ptable(db and db.show, "show")
        ptable(db and db.panels, "panels")
        local tt = db and db.tooltips
        ptable(tt and tt.visibility, "tooltips.visibility")
        ptable(tt and tt.gold, "tooltips.gold")
        ptable(db and db.layout, "layout")
        ptable(db and db.appearance, "appearance")

        section("END")
    return table.concat(lines, "\n")
end

function LPS:ShowDebugWindow()
    local report = LPS:BuildDebugReport()
    if type(LPS.CreateProfilePopupBase) ~= "function" then
        LPS:Print(report, false)
        return
    end

    local ok, err = pcall(function()
    local FIELD_H = 340
    local popup, titleFs, bodyFs, okBtn, cancelBtn = LPS:CreateProfilePopupBase(560, 440)
    titleFs:SetText(L.DEBUG_WINDOW_TITLE or "Location Plus Debug")
    bodyFs:SetText(L.DEBUG_COPY_HINT or "Press Ctrl+C to copy the report and send it to the author on GitHub.")

    local scroll = LPS:CreateScrollFrame(popup)
    scroll:SetSize(528, FIELD_H)
    scroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -58)
    LPS:ThemeBox(scroll, "field", "border", (LPS:ThemeGet()).windowRadius)

    local text = scroll.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 8, -8)
    text:SetWidth(512)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    local fieldText = LPS:GetWidgetColor("text")
    text:SetTextColor(fieldText.r, fieldText.g, fieldText.b)
    text:SetText(report)
    local lineCount = select(2, report:gsub("\n", "")) + 1
    C_Timer.After(0, function()
        local h = text:GetHeight() or 0
        if h < lineCount * 12 then
            h = (lineCount + math.floor(#report / 70)) * 14
        end
        text:SetHeight(h + 2)
        scroll:SetContentHeight(h + 32)
        scroll:SetVerticalScroll(0)
    end)

    local copyBox = CreateFrame("EditBox", nil, popup)
    copyBox:SetSize(1, 1)
    copyBox:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
    copyBox:SetAlpha(0)
    copyBox:SetMultiLine(true)
    copyBox:SetAutoFocus(true)
    copyBox:EnableMouse(false)
    copyBox:SetText(report)

    local copied = false
    local function onCopy()
        if copied then return end
        copied = true
        LPS:Print("LocationPlus: debug report copied to the clipboard. Send it to the author as a GitHub issue.", false)
        C_Timer.After(0.1, function()
            LPS:CloseActivePopup()
        end)
    end
    pcall(function() copyBox:SetScript("OnCopy", onCopy) end)
    copyBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= report then
            self:SetText(report)
        end
        self:SetSize(1, 1)
    end)
    copyBox:SetScript("OnKeyDown", function(self, key)
        if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
            self.ctrlDown = true
        end
    end)
    copyBox:SetScript("OnKeyUp", function(self, key)
        if key == "LCTRL" or key == "RCTRL" or key == "LMETA" or key == "RMETA" then
            C_Timer.After(0.2, function() self.ctrlDown = nil end)
            return
        end
        if key == "C" and self.ctrlDown then
            C_Timer.After(0.1, onCopy)
        end
    end)

    if cancelBtn then cancelBtn:Hide() end
    okBtn:SetText(L.DEBUG_CLOSE_BUTTON or "Закрыть")
    okBtn:SetScript("OnClick", function()
        LPS:CloseActivePopup()
    end)

    copyBox:HighlightText()
    C_Timer.After(0, function() copyBox:HighlightText() end)
        return popup
    end)
    if not ok then
        pcall(function() LPS:CloseActivePopup() end)
        LPS:Print(report, false)
        LPS:Print("LocationPlus: debug window error -> " .. tostring(err), false)
    end
end

defineCommand("debug", function()
    LPS:ShowDebugWindow()
end, {
    help = "Open the diagnostic window (Ctrl+C to copy the report and send it to the author)",
})

defineCommand("clear-all", function()
    if InCombatLockdown and InCombatLockdown() then
        LPS:Print("Cannot clear the data in combat.", false)
        return
    end
    if type(LPS_DB) == "table" then
        for k in pairs(LPS_DB) do
            LPS_DB[k] = nil
        end
    end
    LPS:Print("All LocationPlus data has been deleted. Reloading the interface...", false)
    ReloadUI()
end, {
    help = "Delete all LocationPlus data (settings, gold, positions) and reload the interface",
})

LPS.Commands = commands
