local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--- Регистрация переводов локали: enUS всегда базовый слой,
--- локаль клиента перекрывает его. Вызывается файлами Locales/.
--- @param code string Код локали ("enUS", "ruRU", ...)
--- @param translations table<string, string> Переводы по константам
function LPS:RegisterLocale(code, translations)
    LPS.RegisteredLocales[code] = translations
    if code == "enUS" or code == LPS.GAME_LOCALE then
        for k, v in pairs(translations) do
            LPS.L[k] = v
        end
    end
end

--- Применение переопределения языка (LPS_DB.localeOverride):
--- LPS.L собирается заново как enUS + выбранная локаль.
--- @param code string|nil Код локали
function LPS:ApplyLocaleOverride(code)
    if not code or code == LPS.ACTIVE_LOCALE then return end
    local target = LPS.RegisteredLocales[code]
    if not target then return end
    for k in pairs(LPS.L) do
        LPS.L[k] = nil
    end
    local base = LPS.RegisteredLocales["enUS"]
    if base then
        for k, v in pairs(base) do
            LPS.L[k] = v
        end
    end
    for k, v in pairs(target) do
        LPS.L[k] = v
    end
    LPS.ACTIVE_LOCALE = code
end

--- @param classToken string? Токен класса ("DEATHKNIGHT", "Evoker"...)
--- @return number?, number?, number?
function LPS:GetClassColor(classToken)
    if not classToken then return nil end
    local key = classToken:upper()
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(key)
        if c then return c.r, c.g, c.b end
    end
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
    if c then return c.r, c.g, c.b end
    return nil
end

local cachedPlayerClass
--- @return number, number, number
function LPS:GetPlayerClassColor()
    if not cachedPlayerClass then
        local _, classFile = UnitClass("player")
        if classFile and classFile ~= "" then
            cachedPlayerClass = classFile
        end
    end
    if cachedPlayerClass then
        local r, g, b = LPS:GetClassColor(cachedPlayerClass)
        if r and g and b then return r, g, b end
    end
    return 1, 1, 1
end

--- Имя персонажа с учётом проекта: на Forever (Camelot) имя
--- может быть дополнено фамилией (второе имя) из UnitNameUnmodified.
--- @return string|nil
function LPS:GetPlayerFullName()
    local name = UnitName("player")
    if LPS.Forever and UnitNameUnmodified then
        local first, surname = UnitNameUnmodified("player")
        if surname and surname ~= "" then
            name = first .. " " .. surname
        end
    end
    return name
end

---@type fun(...): ...
local unpackFn = table.unpack or unpack

local normalizedLayoutCache

function LPS:NormalizeLayoutDB(raw)
    if not raw then
        raw = {}
        local db = LPS:GetDB()
        if db then db.layout = raw end
    end
    local out = normalizedLayoutCache and normalizedLayoutCache.out or {}
    out.dtPaddingX  = tonumber(raw.dtPaddingX)
    out.dtPaddingY  = tonumber(raw.dtPaddingY)
    out.dtMinWidth  = tonumber(raw.dtMinWidth)
    out.locPaddingX = tonumber(raw.locPaddingX)
    out.locPaddingY = tonumber(raw.locPaddingY)
    out.locMinWidth = tonumber(raw.locMinWidth)
    local defLayout = LPS.defaults and LPS.defaults.layout or {}
    if raw.spacingAuto == false then
        out.spacing = tonumber(raw.spacingManual) or tonumber(defLayout.spacingManual) or 20
    else
        out.spacing = 5
    end
    if raw.dtshow == nil and LPS.defaults and LPS.defaults.layout then
        raw.dtshow = LPS.defaults.layout.dtshow
    end
    if raw.sideSlots == nil and LPS.defaults and LPS.defaults.layout then
        local copy = {}
        for k, v in pairs(LPS.defaults.layout.sideSlots) do
            if type(v) == "table" then
                local t = {}
                for kk, vv in pairs(v) do t[kk] = vv end
                copy[k] = t
            else
                copy[k] = v
            end
        end
        copy.userTouched = {}
        raw.sideSlots = copy
    end
    out.dtshow      = raw.dtshow ~= false
    out.slotCount   = tonumber(raw.slotCount) or 2
    out.frameStrata = raw.frameStrata
    out.frameLevel  = tonumber(raw.frameLevel)
    out.customColor = raw.customColor
    out.userColor   = raw.userColor
    out.sideSlots   = LPS:CopyLayoutSlots(raw.sideSlots)
    normalizedLayoutCache = { raw = raw, out = out }
    return out
end

function LPS:InvalidateLayoutCache()
    normalizedLayoutCache = nil
    local loc = LPS.frame and LPS.frame.location
    if loc then loc._lpsLastLayoutKey = nil end
end

function LPS:NormalizeSlotFrameKey(key)
    if not key or key == "" or key == "none" or key == "None" then return "NONE" end
    return key
end

function LPS:SlotListContains(slotList, frameKey)
    for _, slot in ipairs(slotList or {}) do
        if LPS:NormalizeSlotFrameKey(slot.cfg and slot.cfg.frame) == frameKey then return true end
    end
    return false
end

function LPS:ApplyPanelVisibility(frames, slotList, showDT)
    if not frames then return end
    local shownNow = {}
    for key, f in pairs(frames) do
        if key ~= "location" and key ~= "minimapButton"
            and type(f) == "table" and f.SetShown and f.IsShown then
                f:SetShown(showDT and LPS:SlotListContains(slotList, key))
                if f:IsShown() then shownNow[#shownNow + 1] = f end
            end
    end
    LPS._pendingPanelPrimes = shownNow
end

function LPS:CopyLayoutSlots(slots)
    if type(slots) ~= "table" then return nil end
    local res = {}
    for side, s in pairs(slots) do
        if side == "userTouched" then
            res[side] = s
        elseif type(s) == "table" then
            res[side] = { frame = s.frame, offsetX = s.offsetX, offsetY = s.offsetY }
        else
            res[side] = {}
        end
    end
    return res
end

function LPS:CollectSlotKeys(sideSlots)
    local res = {}
    if type(sideSlots) ~= "table" then return res end
    local names = {}
    for name in pairs(sideSlots) do
        if name ~= "userTouched" then names[#names + 1] = tostring(name) end
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local s = sideSlots[name]
        if type(s) == "table" then
            res[#res + 1] = name .. "=" .. tostring(s.frame) .. "," .. tostring(s.offsetX) .. "," .. tostring(s.offsetY)
        else
            res[#res + 1] = name .. "=nil"
        end
    end
    return res
end

function LPS:LayoutTextColor(mode, userColor)
    if mode == 1 then
        return (userColor and userColor.r) or 1, (userColor and userColor.g) or 1, (userColor and userColor.b) or 1
    end
    if mode == 2 then
        return LPS:GetPlayerClassColor()
    end
    if mode == 3 then
        return LPS:GetColor("text")
    end
    return nil
end

function LPS:ResolveLayoutFont()
    local file, _, flags = GameFontNormalSmall:GetFont()
    return file, flags
end

function LPS:ForceResizeFrame(f)
    if not f then return end
    if f._lpsResizeToFit then f._lpsResizeToFit() end
end

function LPS:SlotGetFrameByKey(key)
    return LPS:GetOrCreatePanelFrame(key)
end

function LPS:PositionSlotChain(chain, side, frames, spacing)
    local isLeft = (side == "LEFT")
    local ownPoint = isLeft and "RIGHT" or "LEFT"
    local edgePoint = isLeft and "LEFT" or "RIGHT"
    local sign = isLeft and -1 or 1
    local anchorTo, anchorPoint = frames.location, edgePoint
    local seen = {}
    for idx = 1, #chain do
        local entry = chain[idx]
        local key = entry.key
        if not seen[key] then
            seen[key] = true
            local frame = LPS:SlotGetFrameByKey(key)
            if frame then
                local ox = tonumber(entry.cfg.offsetX) or 0
                local oy = tonumber(entry.cfg.offsetY) or 0
                frame:ClearAllPoints()
                local dx = ((idx == 1) and 0 or (sign * spacing)) + ox
                frame:SetPoint(ownPoint, anchorTo, anchorPoint, dx, oy)
                anchorTo, anchorPoint = frame, edgePoint
            end
        end
    end
end

function LPS:ApplyLayout()
    local db = LPS:GetDB()
    local frames = LPS.frame
    if not db or not frames then return end

    local layout = LPS:NormalizeLayoutDB(db.layout)

    local user = layout.userColor
    local layoutKey = tostring(layout.dtPaddingX) .. "," .. tostring(layout.dtPaddingY) .. ","
        .. tostring(layout.dtMinWidth) .. "," .. tostring(layout.locPaddingX) .. ","
        .. tostring(layout.locPaddingY) .. "," .. tostring(layout.locMinWidth) .. ","
        .. tostring(layout.spacing) .. "," .. tostring(layout.dtshow) .. ","
        .. tostring(layout.frameStrata) .. "," .. tostring(layout.frameLevel) .. ","
        .. tostring(layout.customColor) .. ","
        .. tostring(user and user.r) .. "," .. tostring(user and user.g) .. "," .. tostring(user and user.b) .. ","
        .. tostring(layout.slotCount or 2) .. ","
        .. table.concat(LPS:CollectSlotKeys(layout.sideSlots), ";") .. ","
        .. tostring(db.settings and db.settings.fontSize or 12) .. ","
        .. LPS:PanelFontKey(db)

    local forcePass = not (frames.location and frames.location._lpsEverApplied)
    if not forcePass and LPS:ConsumePendingRefresh() then forcePass = true end
    if not forcePass and frames.location and frames.location._lpsLastLayoutKey == layoutKey then
        return
    end
    local prevKey = frames.location and frames.location._lpsLastLayoutKey
    if frames.location then
        frames.location._lpsLastLayoutKey = layoutKey
    end

    local defaultsLayout = (LPS.defaults and LPS.defaults.layout) or {}
    local dtPaddingX  = tonumber(layout.dtPaddingX)  or tonumber(defaultsLayout.dtPaddingX)  or 20
    local dtPaddingY  = tonumber(layout.dtPaddingY)  or tonumber(defaultsLayout.dtPaddingY)  or 7
    local dtMinWidth  = tonumber(layout.dtMinWidth)  or tonumber(defaultsLayout.dtMinWidth)  or 100
    local locPaddingX = tonumber(layout.locPaddingX) or tonumber(defaultsLayout.locPaddingX) or 20
    local locPaddingY = tonumber(layout.locPaddingY) or tonumber(defaultsLayout.locPaddingY) or 9
    local locMinWidth = tonumber(layout.locMinWidth) or tonumber(defaultsLayout.locMinWidth) or 200
    local spacing     = tonumber(layout.spacing) or 5
    local firstPass = forcePass

    if frames.location then
        frames.location._lpsPaddingX = locPaddingX
        frames.location._lpsPaddingY = locPaddingY
        frames.location._lpsMinWidth = locMinWidth
    end
    for key, f in pairs(frames) do
        if key ~= "location" and key ~= "minimapButton" and f then
            f._lpsPaddingX = dtPaddingX
            f._lpsPaddingY = dtPaddingY
            f._lpsMinWidth = dtMinWidth
        end
    end

    local showDT = layout.dtshow ~= false

    local sideSlots = layout.sideSlots or {}

    local leftChain, rightChain = {}, {}
    for _, side in ipairs({ "left", "right" }) do
        for i = 1, math.max(tonumber(layout.slotCount) or 2, 2) do
            local cfg = sideSlots[side .. i]
            if cfg then
                local key = LPS:NormalizeSlotFrameKey(cfg.frame)
                if key ~= "NONE" then
                    local entry = { key = key, cfg = cfg, side = side }
                    if side == "left" then leftChain[#leftChain + 1] = entry
                    else rightChain[#rightChain + 1] = entry end
                end
            end
        end
    end
    local slotList = {}
    for _, e in ipairs(leftChain) do slotList[#slotList + 1] = e end
    for _, e in ipairs(rightChain) do slotList[#slotList + 1] = e end

    for _, e in ipairs(slotList) do
        local f = LPS:SlotGetFrameByKey(e.key)
        if f then frames[e.key] = f end
    end

    LPS:PositionSlotChain(leftChain, "LEFT", frames, spacing)
    LPS:PositionSlotChain(rightChain, "RIGHT", frames, spacing)

    LPS:ApplyPanelVisibility(frames, slotList, showDT)

    if LPS._pendingPanelPrimes then
        for _, f in ipairs(LPS._pendingPanelPrimes) do
            if f and f:IsShown() and f._lpsUpdateFunc then
                f._lpsUpdateFunc(f)
                if f._lpsResizeToFit then f._lpsResizeToFit() end
            end
        end
        LPS._pendingPanelPrimes = nil
    end

    if frames.location then
        if layout.frameStrata then
            frames.location:SetFrameStrata(layout.frameStrata)
        end
        if layout.frameLevel then
            frames.location:SetFrameLevel(tonumber(layout.frameLevel) or 1)
        end
    end

    local fontFile, defaultFlags = LPS:ResolveLayoutFont()
    local size = (db.settings and db.settings.fontSize) or 12
    local flags = defaultFlags or "NONE"
    local fontChanged = false
    local fontSizeChanged = false

    --- Обратная карта: ключ фрейма (datatext) → ключ слота (location / left1..3 / right1..3).
    local slotOfFrame = { location = "location" }
    for _, side in ipairs({ "left", "right" }) do
        for i = 1, math.max(tonumber(layout.slotCount) or 2, 2) do
            local slotKey = side .. i
            local cfg = sideSlots[slotKey]
            if cfg then
                local fkey = LPS:NormalizeSlotFrameKey(cfg.frame)
                if fkey ~= "NONE" then
                    slotOfFrame[fkey] = slotKey
                end
            end
        end
    end

    for key, f in pairs(frames) do
        if key ~= "minimapButton" and type(f) == "table" and f.text then
            local slot = slotOfFrame[key]
            local file = fontFile
            local fl = flags
            if slot then
                local ok, resolved = pcall(LPS.ResolveSlotFontFile, LPS, slot)
                if ok and resolved then
                    file = resolved
                    fl = ""
                end
            end
            local fontKey = tostring(file) .. "|" .. tostring(size) .. "|" .. tostring(fl)
            if f._lpsAppliedFontKey ~= fontKey then
                pcall(f.text.SetFont, f.text, file, size, fl)
                f._lpsAppliedFontKey = fontKey
                fontChanged = true
                fontSizeChanged = true
                if f._lpsResizeToFit then f._lpsResizeToFit() end
            elseif f._lpsAppliedFontSize ~= size then
                fontSizeChanged = true
            end
            f._lpsAppliedFontSize = size
            local mode = layout.customColor
            if mode == nil then
                mode = 3
            end
            local r, g, b
            if f == LPS.frame.location then
            elseif f._lpsForceWhite then
                r, g, b = 1, 1, 1
            elseif mode == 3 then
                r, g, b = LPS:GetColor("text")
            else
                r, g, b = LPS:LayoutTextColor(mode, layout.userColor)
            end
            if r then
                local nr, ng, nb = f.text:GetTextColor()
                if math.abs(nr - r) > 0.001 or math.abs(ng - g) > 0.001 or math.abs(nb - b) > 0.001 then
                    f.text:SetTextColor(r, g, b)
                    fontChanged = true
                end
            end
        end
    end

    if frames.location then
        LPS:ForceResizeFrame(frames.location)
    end
    for key, f in pairs(frames) do
        if key ~= "location" and key ~= "minimapButton" and f then
            LPS:ForceResizeFrame(f)
        end
    end

    local layoutNumsChanged = ((prevKey ~= nil) and (prevKey ~= layoutKey)) or forcePass
    if fontChanged or fontSizeChanged or layoutNumsChanged or forcePass then
        for key, f in pairs(frames) do
            if key ~= "minimapButton" and f and f._lpsUpdateFunc then
                f._lpsUpdateFunc(f)
            end
        end
    end

    if firstPass or layoutNumsChanged then
        local loc = frames.location
        if loc and loc._lpsUpdateFunc then
            loc._lpsUpdateFunc(loc)
        end
        for key, f in pairs(frames) do
            if key ~= "location" and key ~= "minimapButton"
                and type(f) == "table" and f._lpsUpdateFunc and f.IsShown and f:IsShown() then
                    f._lpsUpdateFunc(f)
                end
        end
    end

    if frames.location then
        frames.location._lpsEverApplied = true
    end
end

function LPS:ConvertRGBtoColorString(color)
    if not color then color = { r = 1, g = 1, b = 1 } end

    local colorString = "|cff";
    local r = color.r * 255;
    local g = color.g * 255;
    local b = color.b * 255;
    colorString = colorString..string.format("%02x%02x%02x", r, g, b);

    return colorString;
end

function LPS:ApplyDTVisibility()
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    LPS:ApplyLayout()
end

function LPS:ApplyTimeVisibility()
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    LPS:ApplyLayout()
end

function LPS:ApplyCoordsVisibility()
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    LPS:ApplyLayout()
end

function LPS:ApplyVisibility()
    local db = LPS:GetDB()
    local loc = LPS.frame and LPS.frame.location
    if not db or not loc or not db.show or not db.show.visibility then return end

    local vis = db.show.visibility

    if vis.combat then
        if not loc._lpsCombatVisEvents then
            loc._lpsCombatVisEvents = true
            loc:RegisterEvent("PLAYER_REGEN_DISABLED")
            loc:RegisterEvent("PLAYER_REGEN_ENABLED")
            loc:HookScript("OnEvent", function()
                local d = LPS:GetDB()
                local l = LPS.frame and LPS.frame.location
                if not d or not l or not d.show or not d.show.visibility then return end
                if d.show.visibility.combat and InCombatLockdown() then
                    l:Hide()
                else
                    l:Show()
                end
            end)
        end
        if InCombatLockdown() then
            loc:Hide()
        else
            loc:Show()
        end
    else
        if loc._lpsCombatVisEvents then
            loc._lpsCombatVisEvents = nil
            loc:UnregisterEvent("PLAYER_REGEN_DISABLED")
            loc:UnregisterEvent("PLAYER_REGEN_ENABLED")
        end
        loc:Show()
    end

    loc:SetAlpha(1)
end

function LPS:ResetPanelsToDefaults()
    local db = self:GetDB()
    if not db then return end

    db.panels = nil

    if type(db.layout) == "table" then
        local defSS = (LPS.defaults and LPS.defaults.layout and LPS.defaults.layout.sideSlots) or {}
        local fresh = {}
        for name, slot in pairs(defSS) do
            if name ~= "userTouched" and type(slot) == "table" then
                fresh[name] = { frame = slot.frame, offsetX = 0, offsetY = 0 }
            end
        end
        fresh.userTouched = {}
        db.layout.sideSlots = fresh
    end

    if LPS.frame then
        for k, f in pairs(LPS.frame) do
            if type(f) == "table" and k ~= "location" and k ~= "minimapButton"
                and LPS.datatexts and LPS.datatexts[k] then
                    f:Hide()
                    if f.UnregisterAllEvents then f:UnregisterAllEvents() end
                    if f._lpsTicker then f._lpsTicker:Cancel(); f._lpsTicker = nil end
                    LPS.frame[k] = nil
                end
        end
    end

    if db.layout and type(db.layout.sideSlots) == "table" then
        db.layout.sideSlots.userTouched = {}
    end

    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    if LPS.ApplyAllSettings then LPS:ApplyAllSettings() end
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    if LPS.ApplyLayout then LPS:ApplyLayout() end
end

function LPS:ResetAllSettingsToDefaults()
    if LPS.db and LPS.db.ResetProfile then
        pcall(function() LPS.db:ResetProfile() end)
    end
    if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end

    if LPS.frame then
        for _, k in ipairs({ "bags", "combatIndicator",
            "difficulty", "durability", "experience", "friends", "guild", "itemLevel", "mail",
            "microBar", "volume" }) do
                local f = LPS.frame[k]
                if f then
                    f:Hide()
                    if f.UnregisterAllEvents then f:UnregisterAllEvents() end
                    if f._lpsTicker then f._lpsTicker:Cancel(); f._lpsTicker = nil end
                    LPS.frame[k] = nil
                end
            end
        for k in pairs(LPS.datatexts) do
            if k:sub(1, 4) == "LDB_" then
                local f = LPS.frame[k]
                if f then
                    f:Hide()
                    if f.UnregisterAllEvents then f:UnregisterAllEvents() end
                    if f._lpsTicker then f._lpsTicker:Cancel(); f._lpsTicker = nil end
                    LPS.frame[k] = nil
                end
            end
        end
    end
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    if not LPS:EditModeIsEditing() then
        LPS:ApplyLocationPosition()
    end
    LPS:ApplyAllSettings()
    if LPS.UpdateMinimapButton then
        LPS:UpdateMinimapButton()
    end
    if LPS.CreateMinimapButton then
        LPS:CreateMinimapButton()
    end
end

function LPS:RefreshAfterProfileChange()
    if self.InvalidateDBCache then self:InvalidateDBCache() end
    if self.InvalidateLayoutCache then self:InvalidateLayoutCache() end
    local db = self:GetProfileDB()
    if self.ApplyDefaults then
        self:ApplyDefaults(db or {}, self.defaults)
    end
    if self.ApplyLocationPosition and not self:EditModeIsEditing() then
        self:ApplyLocationPosition()
    end
    if self.ApplyAllSettings then
        self:ApplyAllSettings()
    end
    if self.UpdateMinimapButton then
        self:UpdateMinimapButton()
    end
    if self.CreateMinimapButton then
        self:CreateMinimapButton()
    end
    if self.ApplyLayout then
        self:ApplyLayout()
    end
end

local Tourist
if LibStub then
    if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
        Tourist = LibStub("LibTourist-3.0")
    elseif LPS.TBC and LibStub:GetLibrary("LibTouristClassicBCA", true) then
        Tourist = LibStub("LibTouristClassicBCA")
    elseif LPS.Mists and LibStub:GetLibrary("LibTouristClassic-1.0", true) then
        Tourist = LibStub("LibTouristClassic-1.0")
    elseif LPS.Classic and LibStub:GetLibrary("LibTouristClassicEra", true) then
        Tourist = LibStub("LibTouristClassicEra")
    end
end
LPS.Tourist = Tourist

--- @param msg string Сообщение
--- @param isTranslate boolean? Флаг перевода msg
function LPS:Print(msg, isTranslate)
    if isTranslate ~= false then
        msg = LPS.L[msg] or msg
    end
    print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: " .. tostring(msg))
end

function LPS:InvalidateDBCache()
    self.profileDB = nil
    self.accountDB = nil
end

function LPS:GetProfileDB()
    if self.db and self.db.profile then
        return self.db.profile
    end
    if type(LPS_DB) == "table" and LPS_DB.profiles and LPS_DB.profiles.Default then
        self.profileDB = LPS_DB.profiles.Default
        return self.profileDB
    end
    self.profileDB = LPS_DB
    return self.profileDB
end

function LPS:GetAccountDB()
    if self.db and self.db.global then
        return self.db.global
    end
    if self.accountDB then
        return self.accountDB
    end
    LPS_DB = LPS_DB or {}
    LPS_DB.global = LPS_DB.global or {}
    self.accountDB = LPS_DB.global
    return self.accountDB
end

function LPS:GetDB()
    return self:GetProfileDB()
end

function LPS:GetGoldRealmKey()
    if GetNormalizedRealmName then
        return GetNormalizedRealmName() or GetRealmName() or ""
    end
    return GetRealmName() or ""
end

function LPS:GetGoldRoot()
    local a = self:GetAccountDB()
    if a then
        a.gold = a.gold or {}
        return a.gold
    end
    LPS_DB = LPS_DB or {}
    LPS_DB.global = LPS_DB.global or {}
    LPS_DB.global.gold = LPS_DB.global.gold or {}
    return LPS_DB.global.gold
end

function LPS:ResetFramePosition()
    local loc = LPS.frame and LPS.frame.location
    if not loc then return end
    local def = (LPS.defaults and LPS.defaults.position) or { point = "TOP", relPoint = "TOP", x = 0, y = -10 }
    local geo = LPS.frame._posGeometry
    if type(geo) == "table" then
        geo.point, geo.relPoint, geo.x, geo.y = def.point, def.relPoint, def.x, def.y
    end
    loc:ClearAllPoints()
    loc:SetPoint(def.point, UIParent, def.relPoint, def.x, def.y)
    if loc.SetUserPlaced then
        loc:SetUserPlaced(false)
    end
    local p = LPS:GetDB().position
    if type(p) == "table" then
        for k in pairs(p) do
            p[k] = nil
        end
    end
    if LPS.EditModeCaptureLayout then
        LPS:EditModeCaptureLayout()
    end
    LPS:Print("The frame position is reset")
end

function LPS:GetContinentID()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local mapInfo = C_Map.GetMapInfo(mapID)
    return mapInfo and mapInfo.parentMapID or nil
end

function LPS:GetContinentName()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        return UNKNOWN
    end

    local mapID = currentMapID
    local continentName
    for _ = 1, 10 do
        local mapInfo = C_Map.GetMapInfo(mapID)
        if not mapInfo then break end
        if mapInfo.mapType == Enum.UIMapType.Continent or mapInfo.mapType == Enum.UIMapType.World then
            continentName = mapInfo.name
            break
        end
        if mapInfo.parentMapID and mapInfo.parentMapID ~= 0 then
            mapID = mapInfo.parentMapID
        else
            if not continentName then continentName = mapInfo.name end
            break
        end
    end

    return continentName or UNKNOWN
end

function LPS:GetZoneStatus(color)
    local status = ""
    local r, g, b = 1, 1, 0
    local pvpType = C_PvP.GetZonePVPInfo()
    local inInstance = IsInInstance()

    if pvpType == "sanctuary" then
        status = SANCTUARY_TERRITORY; r, g, b = 0.41, 0.8, 0.94
    elseif pvpType == "arena" then
        status = ARENA; r, g, b = 1, 0.1, 0.1
    elseif pvpType == "friendly" then
        status = FRIENDLY; r, g, b = 0.1, 1, 0.1
    elseif pvpType == "hostile" then
        status = HOSTILE; r, g, b = 1, 0.1, 0.1
    elseif pvpType == "contested" then
        status = CONTESTED_TERRITORY; r, g, b = 1, 0.7, 0.1
    elseif pvpType == "combat" or inInstance then
        status = COMBAT; r, g, b = 1, 0.1, 0.1
    else
        status = CONTESTED_TERRITORY
    end

    if color then
        return r, g, b
    end
    return format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status)
end

function LPS:RGBToHex(r, g, b)
    r = tonumber(r) or 1
    g = tonumber(g) or 1
    b = tonumber(b) or 1
    local rr = math.floor(r * 255 + 0.5)
    local gg = math.floor(g * 255 + 0.5)
    local bb = math.floor(b * 255 + 0.5)
    return string.format("%02x%02x%02x", rr, gg, bb)
end

--- Возвращает отформатированное игровое время с учетом CVar (12/24ч, локальное/серверное).
function LPS:GetFormattedGameTime()
    local db = LPS:GetDB()
    local layout = db and db.layout or {}
    local is24h = db and db.general and db.general.is24H
    local useLocal = GetCVarBool("timeMgrUseLocalTime")

    local mode = layout.customColor
    if mode == nil then
        mode = 3
    end
    local r, g, b
    if mode == 1 then
        local user = layout.userColor
        r, g, b = (user and user.r) or 1, (user and user.g) or 1, (user and user.b) or 1
    elseif mode == 2 then
        r, g, b = LPS:GetPlayerClassColor()
    else
        r, g, b = LPS:GetColor("text")
    end
    local colon = "|cff" .. LPS:RGBToHex(r, g, b) .. ":|r"

    local h, m, s
    if useLocal then
        local t = date("*t")
        h, m, s = t.hour, t.min, t.sec
    else
        h, m = GetGameTime()
    end

    local showSeconds = db.general.seconds and useLocal
    if not is24h then
        local suffix = (h >= 12) and "PM" or "AM"
        h = h % 12
        if h == 0 then h = 12 end
        if showSeconds then
            return string.format("%02d%s%02d%s%02d %s", h, colon, m, colon, s, suffix)
        else
            return string.format("%02d%s%02d %s", h, colon, m, suffix)
        end
    end

    if showSeconds then
        return string.format("%02d%s%02d%s%02d", h, colon, m, colon, s)
    else
        return string.format("%02d%s%02d", h, colon, m)
    end
end

function LPS:ApplyDefaults(db, defaults)
    if type(db) ~= "table" then db = {} end
    if rawequal(db, defaults) then
        local copy = {}
        for k, v in pairs(db) do copy[k] = v end
        return copy
    end

    for k, v in pairs(defaults) do
        if type(v) == "table" then
            db[k] = LPS:ApplyDefaults(db[k], v)
        elseif db[k] == nil and k ~= "addonTextColor" then
            db[k] = v
        end
    end

    if defaults.layout and db.layout and type(db.layout) == "table" then
        local defL = defaults.layout
        if rawequal(db.layout, defaults.layout) then
            local copy = {}
            for k, v in pairs(db.layout) do copy[k] = v end
            if type(copy.sideSlots) == "table" then
                local ssCopy = {}
                for k, v in pairs(copy.sideSlots) do
                    if type(v) == "table" then
                        local t = {}
                        for kk, vv in pairs(v) do t[kk] = vv end
                        ssCopy[k] = t
                    else
                        ssCopy[k] = v
                    end
                end
                copy.sideSlots = ssCopy
            end
            db.layout = copy
        end
        if defL.sideSlots ~= nil and rawequal(db.layout.sideSlots, defL.sideSlots) then
            local ssCopy = {}
            for k, v in pairs(defL.sideSlots) do
                if type(v) == "table" then
                    local t = {}
                    for kk, vv in pairs(v) do t[kk] = vv end
                    ssCopy[k] = t
                else
                    ssCopy[k] = v
                end
            end
            ssCopy.userTouched = {}
            db.layout.sideSlots = ssCopy
        end
        for _, key in ipairs({"dtPaddingX","dtPaddingY","dtMinWidth","locPaddingX","locPaddingY","locMinWidth","frameLevel","spacingManual"}) do
            if tonumber(db.layout[key]) == nil then db.layout[key] = defL[key] end
        end
        if db.layout.dtshow == nil then db.layout.dtshow = defL.dtshow end
        if db.layout.spacingAuto == nil then db.layout.spacingAuto = defL.spacingAuto end
        if db.layout.customColor == nil then db.layout.customColor = defL.customColor end
        if db.layout.frameStrata == nil or db.layout.frameStrata == "" then db.layout.frameStrata = defL.frameStrata end
        if db.layout.frameStrata == "DIALOG" or db.layout.frameStrata == "TOOLTIP" then db.layout.frameStrata = "HIGH" end
        if type(db.layout.userColor) ~= "table" then db.layout.userColor = { r = 1, g = 1, b = 1 } end
        if type(db.layout.sideSlots) ~= "table" then db.layout.sideSlots = {} end
        local ss = db.layout.sideSlots
        if defL.sideSlots ~= nil and rawequal(ss, defL.sideSlots) then
            local copy = {}
            for k, v in pairs(ss) do
                if type(v) == "table" then
                    local t = {}
                    for kk, vv in pairs(v) do t[kk] = vv end
                    copy[k] = t
                else
                    copy[k] = v
                end
            end
            copy.userTouched = {}
            db.layout.sideSlots = copy
            ss = db.layout.sideSlots
        end
        if type(ss.userTouched) ~= "table" then ss.userTouched = {} end

        for _, side in ipairs({"left","right"}) do
            local oldSlot = ss[side]
            if type(oldSlot) == "table" then
                if ss[side .. "1"] == nil then
                    ss[side .. "1"] = { frame = oldSlot.frame, offsetX = oldSlot.offsetX, offsetY = oldSlot.offsetY }
                    ss.userTouched[side .. "1"] = true
                end
                ss[side] = nil
            elseif oldSlot ~= nil then
                ss[side] = nil
            end
        end
        for _, slot in pairs(ss) do
            if type(slot) == "table" and slot.frame == "quests" then
                slot.frame = "NONE"
            end
        end
        if tonumber(db.layout.slotCount) == nil then db.layout.slotCount = defL.slotCount or 3 end
        for i = 1, 3 do
            for _, side in ipairs({"left","right"}) do
                local name = side .. i
                local s = ss[name]
                if type(s) ~= "table" then
                    s = {}
                    ss[name] = s
                end
                local defS = defL.sideSlots and defL.sideSlots[name]
                if not ss.userTouched[name] and defS and (s.frame == nil or s.frame == "" or s.frame == "NONE") then
                    s.frame = defS.frame
                elseif s.frame == nil or s.frame == "" then
                    s.frame = "NONE"
                end
                if tonumber(s.offsetX) == nil then s.offsetX = 0 end
                if tonumber(s.offsetY) == nil then s.offsetY = 0 end
            end
        end
    end

    return db
end

function LPS:GetColor(key)
    local db = LPS:GetDB()
    local colors = db.settings and db.settings.colors
    local c = colors and colors[key]
    if key == "bg" and colors and colors.bgEnable == false then
        local r, g, b = unpackFn(c or {0, 0, 0, 0})
        return r, g, b, 0
    end
    return unpackFn(c or {1, 1, 1, 1})
end

local refreshPending = false
local pendingRefresh = false
function LPS:ConsumePendingRefresh()
    if pendingRefresh then
        pendingRefresh = false
        return true
    end
    return false
end
function LPS:ScheduleRefresh()
    pendingRefresh = true
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.05, function()
        refreshPending = false
        if not pendingRefresh then return end
        pendingRefresh = false
        if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
        if LPS.ApplyLayout then
            LPS:ApplyLayout()
        end
    end)
end

function LPS:ApplyCoordsUpdateInterval()
    local db = LPS:GetDB()
    local f = LPS.frame and LPS.frame.coords
    if not f or not f._lpsUpdateFunc then return end
    local interval = tonumber(db.general and db.general.coordsTimeUpdate) or 0.2
    interval = math.max(interval, 0.05)
    if f._lpsTicker then
        f._lpsTicker:Cancel()
        f._lpsTicker = nil
    end
    f._lpsTicker = C_Timer.NewTicker(interval, function()
        if f._lpsUpdateFunc and f:IsShown() and (not f:GetParent() or f:GetParent():IsShown()) then
            f._lpsUpdateFunc(f)
        end
    end)
end

function LPS:ApplyStyle()
    local db = LPS:GetDB()
    local frames = LPS.frame
    if not frames then return end
    for key, f in pairs(frames) do
        if key ~= "minimapButton"
            and type(f) == "table" and f.SetBackdropColor then
                local bs = tonumber(db.settings.borderSize)
                if not bs then bs = 2 end
                bs = math.max(0, math.min(bs, 6))
                f:SetBackdrop({
                    bgFile   = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = (bs > 0 and "Interface\\Buttons\\WHITE8x8") or nil,
                    tile     = false,
                    edgeSize = bs,
                    insets   = {left=1,right=1,top=1,bottom=1},
                })
                if f._lpsUpdateFunc then
                    f._lpsUpdateFunc(f)
                end
                f:SetBackdropColor(LPS:GetColor("bg"))
                f:SetBackdropBorderColor(LPS:GetColor("border"))
            end
    end
    if LPS.ApplyLayout then
        LPS:ApplyLayout()
    end
end

function LPS:ApplyTimeFormat()
    local db = LPS:GetDB()

    local f = LPS.frame and LPS.frame.time
    if f and f._lpsUpdateFunc then
        f._lpsUpdateFunc(f)
    end
    if LPS.ApplyLayout then
        LPS:ApplyLayout()
    end
end

function LPS:ApplyAllSettings()
    if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
    LPS:ApplyTimeFormat()
    LPS:ApplyCoordsUpdateInterval()
    LPS:ApplyLayout()
    LPS:ApplyStyle()
    LPS:ApplyVisibility()
end

function LPS:GetPlayerCoords()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        return pos.x, pos.y
    else
        return
    end
end

function LPS:GetMapNameByIDAlt(mapID)
    if not Tourist then return GetZoneText() end
    return Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN
end

--- Упаковка всех возвращаемых значений вызова в таблицу — аналог `table.pack` из Lua 5.2+,
--- которого нет в старых клиентах. В отличие от конструктора `{ f() }`, значения после
--- первого `nil` не отбрасываются: каждое значение записывается в свой индекс,
--- а их количество (включая nil) хранится в поле `n`.
--- Использование: `LPS:PackValues(GetProfessions())`.
--- @param ... any Список возвращаемых значений (вызов другой функции)
--- @return table Таблица вида `{ [1] = v1, [2] = v2, ..., n = количество_значений }`
function LPS:PackValues(...)
    local t = {}
    for i = 1, select('#', ...) do
        t[i] = select(i, ...)
    end
    t.n = select('#', ...)
    return t
end

--- Главное переключение меню: нативное окно настроек
--- (Game/UI/Views/Panel.lua + Game/Options/options_ui.lua → LPS:ToggleOptionWindow).
--- Fallback — закрытие стандартных панелей Blizzard.
function LPS:ToggleOptions()
    if LPS.ToggleOptionWindow then
        LPS:ToggleOptionWindow()
        return
    end

    if _G.SettingsPanel and _G.SettingsPanel.IsShown and _G.SettingsPanel:IsShown() then
        _G.SettingsPanel:Hide()
        return
    end
    if _G.InterfaceOptionsFrame and _G.InterfaceOptionsFrame.IsShown and _G.InterfaceOptionsFrame:IsShown() then
        _G.InterfaceOptionsFrame:Hide()
        return
    end

end

--- @param v any
--- @return boolean
function LPS:IsNotSecret(v)
    return v ~= nil
end

--- Короткое число (1.2M, 3k...)
--- @param n number?
--- @return string
function LPS:ShortValue(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.2fk", n / 1e3) end
    return tostring(math.floor(n))
end

--- @param r number?
--- @param g number?
--- @param b number?
--- @return string
function LPS:HexFromRGB(r, g, b)
    return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

--- Цвет по трёхточечному градиенту (pct 0..1)
function LPS:ColorGradient(pct, r1, g1, b1, r2, g2, b2, r3, g3, b3)
    pct = math.max(0, math.min(1, tonumber(pct) or 0))
    local r, g, b
    if pct < 0.5 then
        local f = pct * 2
        r, g, b = r1 + (r2 - r1) * f, g1 + (g2 - g1) * f, b1 + (b2 - b1) * f
    else
        local f = (pct - 0.5) * 2
        r, g, b = r2 + (r3 - r2) * f, g2 + (g3 - g2) * f, b2 + (b3 - b2) * f
    end
    return r, g, b
end

--- @param classFile string?
--- @return string
function LPS:ClassColorHex(classFile)
    local r, g, b = LPS:GetClassColor(classFile)
    if r then return LPS:HexFromRGB(r, g, b) end
    return "|cFFFFFFFF"
end

--- @param level number
--- @return string
function LPS:LevelColorHex(level)
    level = tonumber(level) or 0
    if GetQuestDifficultyColor then
        local c = GetQuestDifficultyColor(level)
        return LPS:HexFromRGB(c.r, c.g, c.b)
    end
    return "|cFFFFFFFF"
end

--- @param num number
--- @param decimals number?
--- @return number
function LPS:Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function LPS:ColorByThreshold(v, good, warn, invert)
    v = tonumber(v) or 0
    local r, g, b
    if invert then
        if v <= good then
            r, g, b = 0.1, 1, 0.1
        elseif v <= warn then
            r, g, b = 1, 0.82, 0
        else
            r, g, b = 1, 0.1, 0.1
        end
    else
        if v >= good then
            r, g, b = 0.1, 1, 0.1
        elseif v >= warn then
            r, g, b = 1, 0.82, 0
        else
            r, g, b = 1, 0.1, 0.1
        end
    end
    return string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, v)
end

--- Контекстное меню: единый API MenuUtil (современные клиенты) с fallback на
--- классические фреймы (старые клиенты). Формат пунктов:
--- {text, isTitle, disabled, icon, func}.
--- @param anchorFrame Frame
--- @param list table[]
local function ShowNativeMenu(anchorFrame, list)
    if MenuUtil and MenuUtil.CreateContextMenu
        and C_ExpandFrame and C_ExpandFrame.CreateMenuEntry then
        local entries = {}
        for _, entry in ipairs(list or {}) do
            if entry.isTitle then
                entries[#entries + 1] = {
                    text = entry.text or "",
                    isTitle = true,
                    notCheckable = true,
                }
            else
                entries[#entries + 1] = {
                    text = entry.text or "",
                    notCheckable = true,
                    isDisabled = (entry.disabled and true) or nil,
                    icon = (type(entry.icon) == "string") and entry.icon or nil,
                    iconWidth = 32,
                    iconHeight = 32,
                    func = entry.func,
                }
            end
        end
        local controller = MenuUtil.CreateContextMenu(
            entries,
            1, 1,
            C_ExpandFrame.CreateMenuEntry,
            400, 350,
            function(self, info)
                if info and info.func then
                    if self:IsShown() then self:Hide() end
                    info.func()
                end
            end,
            1
        )
        if controller then
            controller:Open(anchorFrame, "BOTTOMLEFT", 0, -2)
        end
        return
    end

    local fMenu = CreateFrame("Frame", "LPS_ShowMenu", UIParent)
    fMenu:SetFrameStrata("TOOLTIP")
    fMenu:EnableMouse(true)
    fMenu:SetClampedToScreen(true)
    local width, offset = 120, 2
    for _, entry in ipairs(list or {}) do
        if entry.isTitle then
            local fs = fMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("TOPLEFT", fMenu, "TOPLEFT", 10, -offset)
            fs:SetPoint("TOPRIGHT", fMenu, "TOPRIGHT", -10, -offset)
            fs:SetJustifyH("LEFT")
            fs:SetText("|cffffffff" .. (entry.text or "") .. "|r")
            offset = offset + 18
        else
            local text = entry.text or ""
            if utf8 and utf8.len then
                width = math.max(width, utf8.len(text) * 7 + 24)
            end
            local btn = CreateFrame("Button", nil, fMenu)
            btn.bg = LPS:ThemeBox(btn, "button", "buttonBorder", LPS:WidgetRadius())
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
            fs:SetJustifyH("LEFT")
            fs:SetText(text)
            btn.text = fs
            btn:SetPoint("TOPLEFT", fMenu, "TOPLEFT", 2, -offset)
            btn:SetPoint("TOPRIGHT", fMenu, "TOPRIGHT", -2, -offset)
            btn:SetHeight(20)
            if entry.disabled then
                btn:SetEnabled(false)
            elseif entry.func then
                btn:SetScript("OnClick", function()
                    fMenu:Hide()
                    entry.func()
                end)
            else
                btn:SetScript("OnClick", function()
                    fMenu:Hide()
                end)
            end
            btn:SetScript("OnEnter", function(self)
                if self:IsEnabled() and self.bg then
                    LPS:PaintWidgetTexture(self.bg, "buttonHover")
                    LPS:ApplyFontColor(self.text, "text")
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if self.bg then
                    LPS:PaintWidgetTexture(self.bg, "button")
                    LPS:ApplyFontColor(self.text, "buttonText")
                end
            end)
            offset = offset + 20
        end
    end
    fMenu:SetSize(width, offset)
    fMenu:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2)
    fMenu:Show()
    fMenu:SetScript("OnMouseLeave", function()
        C_Timer.After(0.5, function()
            if fMenu:IsShown() then
                fMenu:Hide()
            end
        end)
    end)
end

--- Открывает контекстное меню у заданной точки привязки.
--- @param anchorFrame Frame
--- @param list {LPSMenuEntry}
function LPS:ShowMenu(anchorFrame, list)
    if type(anchorFrame) ~= "table" or type(list) ~= "table" then
        return
    end
    ShowNativeMenu(anchorFrame, list)
end

--- @param self Frame
--- @param buildFunc fun(tt: Frame)
function LPS:OpenTooltip(self, buildFunc)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    buildFunc(GameTooltip)
    GameTooltip:Show()
end

--- Панели, у которых есть собственные тултип-настройки (db.tooltips[key])
local PANEL_TT_KEYS = {
    location = true, gold = true, system = true, time = true,
    friends = true, guild = true, experience = true, bags = true,
}

--- @param key string
--- @return table?
function LPS:PanelCfg(key)
    local db = LPS:GetDB()
    return db and db.panels and db.panels[key]
end

--- @param key string
--- @return table?
function LPS:TooltipCfg(key)
    local d = LPS:GetDB()
    if not d then return nil end
    if PANEL_TT_KEYS[key] and d.tooltips and d.tooltips[key] then
        return d.tooltips[key]
    end
    return LPS:PanelCfg(key)
end

--- @param key string
--- @return boolean
function LPS:TooltipGuard(key)
    local d = LPS:GetDB()
    if not d then return false end
    if not (d.tooltips and d.tooltips.visibility and d.tooltips.visibility.enable) then return false end
    if d.tooltips.visibility.combat and InCombatLockdown() then return false end
    if PANEL_TT_KEYS[key] then
        local tcfg = d.tooltips[key]
        if tcfg and tcfg.enable == false then return false end
    else
        local cfg = LPS:PanelCfg(key)
        if cfg and cfg.tooltip == false then return false end
    end
    return true
end

LPS._DT = LPS._DT or {}
LPS._DT.NotSecret = function(v) return LPS:IsNotSecret(v) end
LPS._DT.shortValue = function(n) return LPS:ShortValue(n) end
LPS._DT.hexFromRGB = function(r, g, b) return LPS:HexFromRGB(r, g, b) end
LPS._DT.colorGradient = function(...) return LPS:ColorGradient(...) end
LPS._DT.classColorHex = function(classFile) return LPS:ClassColorHex(classFile) end
LPS._DT.levelColorHex = function(level) return LPS:LevelColorHex(level) end
LPS._DT.panelCfg = function(key) return LPS:PanelCfg(key) end
LPS._DT.tooltipCfg = function(key) return LPS:TooltipCfg(key) end
LPS._DT.tooltipGuard = function(key) return LPS:TooltipGuard(key) end
LPS._DT.openTooltip = function(self, buildFunc) return LPS:OpenTooltip(self, buildFunc) end
LPS._DT.showMenu = function(anchorFrame, list) return LPS:ShowMenu(anchorFrame, list) end
