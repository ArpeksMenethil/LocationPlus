local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:ApplyLayout()
	local db = LPS:GetDB()
	local frames = LPS.frame
	if not db or not frames then return end

	local layout = db.layout or {}
	local dtPaddingX = tonumber(layout.dtPaddingX)
	if dtPaddingX == nil then dtPaddingX = 10 end
	local dtPaddingY = tonumber(layout.dtPaddingY)
	if dtPaddingY == nil then dtPaddingY = 6 end
	local dtMinWidth = tonumber(layout.dtMinWidth)
	if dtMinWidth == nil then dtMinWidth = 60 end
	local locPaddingX = tonumber(layout.locPaddingX)
	if locPaddingX == nil then locPaddingX = 10 end
	local locPaddingY = tonumber(layout.locPaddingY)
	if locPaddingY == nil then locPaddingY = 6 end
	local locMinWidth = tonumber(layout.locMinWidth)
	if locMinWidth == nil then locMinWidth = 80 end
	local spacing = (layout.spacingAuto == false) and (tonumber(layout.spacingManual) or 5) or 5

	local function getClassColor()
		local _, class = UnitClass("player")
		local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
		if c then
			return c.r, c.g, c.b
		end
		return 1, 1, 1
	end

	local function getLayoutTextColor(mode, user)
		if mode == 1 then
			return (user and user.r) or 1, (user and user.g) or 1, (user and user.b) or 1
		end
		if mode == 2 then
			return getClassColor()
		end
		if mode == 3 then
			return LPS:GetZoneStatus(true)
		end
		return nil
	end

	local function resolveFont()
		local file, _, flags = GameFontNormalSmall:GetFont()
		return file, flags
	end

	if frames.location then
		frames.location._lpsPaddingX = locPaddingX
		frames.location._lpsPaddingY = locPaddingY
		frames.location._lpsMinWidth = locMinWidth
	end
	for _, f in pairs({frames.coords, frames.time, frames.gold, frames.system}) do
		if f then
			f._lpsPaddingX = dtPaddingX
			f._lpsPaddingY = dtPaddingY
			f._lpsMinWidth = dtMinWidth
		end
	end

	local showDT = layout.dtshow ~= false
	if frames.coords then
		frames.coords:SetShown(showDT)
	end
	if frames.time then
		frames.time:SetShown(showDT)
	end
	if frames.gold then
		frames.gold:SetShown(showDT)
	end
	if frames.system then
		frames.system:SetShown(showDT)
	end

	local sideSlots = layout.sideSlots or {}
	local leftSlot = sideSlots.left or {}
	local rightSlot = sideSlots.right or {}

	local function normalizeSlotFrameKey(key)
		if not key or key == "" then return "NONE" end
		if key == "none" then return "NONE" end
		if key == "None" then return "NONE" end
		return key
	end

	local function isSelectedInSlots(frameKey)
		local l = normalizeSlotFrameKey(leftSlot.frame)
		local r = normalizeSlotFrameKey(rightSlot.frame)
		if l == frameKey then return true end
		if r == frameKey then return true end
		return false
	end

	local function applySideSlotVisibility()
		-- Hide non-selected frames, even if global "show" flags are enabled.
		if frames.coords then
			frames.coords:SetShown(frames.coords:IsShown() and isSelectedInSlots("coords"))
		end
		if frames.time then
			frames.time:SetShown(frames.time:IsShown() and isSelectedInSlots("time"))
		end
		if frames.gold then
			frames.gold:SetShown(frames.gold:IsShown() and isSelectedInSlots("gold"))
		end
		if frames.system then
			frames.system:SetShown(frames.system:IsShown() and isSelectedInSlots("system"))
		end
	end

	local function getFrameByKey(key)
		if key == "coords" then return frames.coords end
		if key == "time" then return frames.time end
		if key == "gold" then return frames.gold end
		if key == "system" then return frames.system end
		return nil
	end

	local function positionSlot(slotCfg, side)
		if not (frames.location and slotCfg) then return end
		local key = normalizeSlotFrameKey(slotCfg.frame)
		if key == "NONE" then return end

		-- Prevent anchoring the same frame twice.
		local otherKey
		if side == "LEFT" then
			otherKey = normalizeSlotFrameKey(rightSlot.frame)
		else
			otherKey = normalizeSlotFrameKey(leftSlot.frame)
		end
		if otherKey == key then
			if side == "RIGHT" then
				return
			end
		end

		local frame = getFrameByKey(key)
		if not (frame and frame.IsShown and frame:IsShown()) then return end

		local ox = tonumber(slotCfg.offsetX) or 0
		local oy = tonumber(slotCfg.offsetY) or 0
		frame:ClearAllPoints()
		if side == "LEFT" then
			frame:SetPoint("RIGHT", frames.location, "LEFT", -spacing + ox, oy)
		else
			frame:SetPoint("LEFT", frames.location, "RIGHT", spacing + ox, oy)
		end
	end

	-- Apply the base visibility rules first, then constrain to selected slots.
	applySideSlotVisibility()
	positionSlot(leftSlot, "LEFT")
	positionSlot(rightSlot, "RIGHT")

	if frames.holder and not frames.holder.isMoving then
		if layout.frameStrata then
			frames.holder:SetFrameStrata(layout.frameStrata)
		end
		if layout.frameLevel then
			frames.holder:SetFrameLevel(tonumber(layout.frameLevel) or 1)
		end
	end

	local fontFile, defaultFlags = resolveFont()
	local size = (db.settings and db.settings.fontSize) or 12
	local flags = defaultFlags or "NONE"
	for _, f in pairs({frames.location, frames.time, frames.coords, frames.gold, frames.system}) do
		if f and f.text then
			f.text:SetFont(fontFile, size, flags)
			local mode = layout.customColor
			if mode == nil then
				mode = 3
			end
			local r, g, b
			if f == frames.gold or f == frames.time then
				r, g, b = 1, 1, 1
			elseif mode == 3 then
				if f ~= frames.location then
					r, g, b = LPS:GetColor("text")
				end
			else
				r, g, b = getLayoutTextColor(mode, layout.userColor)
			end
			if r then
				f.text:SetTextColor(r, g, b)
			end
		end
	end

	-- Re-run updates after font is applied so auto-sizing uses correct font metrics.
	if frames.location and frames.location._lpsUpdateFunc then
		frames.location._lpsUpdateFunc(frames.location)
	end
	if frames.coords and frames.coords._lpsUpdateFunc then
		frames.coords._lpsUpdateFunc(frames.coords)
	end
	if frames.time and frames.time._lpsUpdateFunc then
		frames.time._lpsUpdateFunc(frames.time)
	end
	if frames.gold and frames.gold._lpsUpdateFunc then
		frames.gold._lpsUpdateFunc(frames.gold)
	end
	if frames.system and frames.system._lpsUpdateFunc then
		frames.system._lpsUpdateFunc(frames.system)
	end


	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyDTVisibility()
	local db = LPS:GetDB()
	local show = db and db.layout and db.layout.dtshow
	local frames = LPS.frame
	local timeF = frames and frames.time
	local coordsF = frames and frames.coords
	local goldF = frames and frames.gold
	local systemF = frames and frames.system
	if show == false then
		if timeF then
			timeF:Hide()
		end
		if coordsF then
			coordsF:Hide()
		end
		if goldF then
			goldF:Hide()
		end
		if systemF then
			systemF:Hide()
		end
	end
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyTimeVisibility()
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame.time
	if not db or not f then return end
	local layout = db.layout or {}
	local slots = layout.sideSlots or {}
	local left = slots.left and slots.left.frame
	local right = slots.right and slots.right.frame
	local selected = (left == "time") or (right == "time")
	if db.layout and db.layout.dtshow == false then
		f:Hide()
		if LPS.UpdateFrameSize then
			LPS:UpdateFrameSize()
		end
		return
	end
	if not selected then
		f:Hide()
		if LPS.UpdateFrameSize then
			LPS:UpdateFrameSize()
		end
		return
	end
	f:Show()
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyCoordsVisibility()
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame.coords
	if not db or not f then return end
	local layout = db.layout or {}
	local slots = layout.sideSlots or {}
	local left = slots.left and slots.left.frame
	local right = slots.right and slots.right.frame
	local selected = (left == "coords") or (right == "coords")
	if db.layout and db.layout.dtshow == false then
		f:Hide()
		if LPS.UpdateFrameSize then
			LPS:UpdateFrameSize()
		end
		return
	end
	if not selected then
		f:Hide()
		if LPS.UpdateFrameSize then
			LPS:UpdateFrameSize()
		end
		return
	end
	f:Show()
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyVisibility()
	local db = LPS:GetDB()
	local holder = LPS.frame and LPS.frame.holder
	if not db or not holder or not db.show or not db.show.visibility then return end

	local vis = db.show.visibility

	if vis.combat then
		if not holder._lpsCombatVisEvents then
			holder._lpsCombatVisEvents = true
			holder:RegisterEvent("PLAYER_REGEN_DISABLED")
			holder:RegisterEvent("PLAYER_REGEN_ENABLED")
			holder:HookScript("OnEvent", function()
				local d = LPS:GetDB()
				local h = LPS.frame and LPS.frame.holder
				if not d or not h or not d.show or not d.show.visibility then return end
				if d.show.visibility.combat and InCombatLockdown() then
					h:Hide()
				else
					h:Show()
				end
			end)
		end
		if InCombatLockdown() then
			holder:Hide()
		else
			holder:Show()
		end
	else
		if holder._lpsCombatVisEvents then
			holder._lpsCombatVisEvents = nil
			holder:UnregisterEvent("PLAYER_REGEN_DISABLED")
			holder:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		holder:Show()
	end

	if not holder.isMoving then
		holder:EnableMouse(false)
	end
	holder:SetAlpha(1)
end

function LPS:ResetAllSettingsToDefaults()
	if LPS.db and LPS.db.ResetProfile then
		LPS.db:ResetProfile()
	else
		local old = LPS_DB
		local oldGlobal = type(old) == "table" and old.global or nil
		local oldGold = type(old) == "table" and old.gold or nil
		LPS_DB = CopyTable(LPS.defaults)
		LPS_DB.global = LPS_DB.global or {}
		if oldGlobal then
			for k, v in pairs(oldGlobal) do
				if LPS_DB.global[k] == nil then
					LPS_DB.global[k] = v
				end
			end
		end
		if oldGold and not LPS_DB.global.gold then
			LPS_DB.global.gold = oldGold
		end
		LPS_DB.gold = nil
	end
	LPS:ApplyHolderPosition()
	if LPS.ApplyAllSettings then
		LPS:ApplyAllSettings()
	end
	if LPS.UpdateMinimapButton then
		LPS:UpdateMinimapButton()
	end
	if LPS.CreateMinimapButton then
		LPS:CreateMinimapButton()
	end
end

function LPS:RefreshAfterProfileChange()
	self.profileDB = nil
	local db = self:GetProfileDB()
	if self.ApplyDefaults then
		self:ApplyDefaults(db or {}, self.defaults)
	end
	if self.ApplyHolderPosition then
		self:ApplyHolderPosition()
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

function LPS:OnAceProfileChanged()
	self:RefreshAfterProfileChange()
end

function LPS:OnAceProfileCopied()
	self:RefreshAfterProfileChange()
end

function LPS:OnAceProfileReset()
	self:RefreshAfterProfileChange()
end

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LPS.TBC and  LibStub:GetLibrary("LibTouristClassicBCA", true) then
	Tourist = LibStub("LibTouristClassicBCA")
elseif LPS.Mists and LibStub:GetLibrary("LibTouristClassic-1.0", true) then
	Tourist = LibStub("LibTouristClassic-1.0")
elseif LPS.Classic and  LibStub:GetLibrary("LibTouristClassicEra", true) then
	Tourist = LibStub("LibTouristClassicEra")
end

local AceLocale = LibStub and LibStub:GetLibrary("AceLocale-3.0", true)
local Locale
if AceLocale then
	Locale = AceLocale:GetLocale("LocationPlus", true)
end

-- Выводит сообщение в чат с префиксом аддона и поддержкой локализации
function LPS:Print(msg, translate)
	if translate ~= false then
		msg = LPS:L(msg)
	end
	print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: " .. tostring(msg))
end

-- Возвращает локализованную строку по ключу или сам ключ, если значение = true
function LPS:L(key)
	if not Locale and AceLocale then
		Locale = AceLocale:GetLocale("LocationPlus", true)
	end
	if Locale then
		local val = rawget(Locale, key)
		if val ~= nil then
			return val
		end
	end

	if LPS.DEBUG then
		LPS:Print("Missing locale: |cFFE24444"..tostring(key).."|r", false)
	end

	return key
end

function LPS:GetProfileDB()
	if self.profileDB then
		return self.profileDB
	end
	if self.db and self.db.profile then
		self.profileDB = self.db.profile
		return self.profileDB
	end
	if type(LPS_DB) == "table" and LPS_DB.profiles and LPS_DB.profiles.Default then
		self.profileDB = LPS_DB.profiles.Default
		return self.profileDB
	end
	self.profileDB = LPS_DB
	return self.profileDB
end

function LPS:GetAccountDB()
	if self.accountDB then
		return self.accountDB
	end
	if self.db and self.db.global then
		self.accountDB = self.db.global
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

-- Сбрасывает позицию основного фрейма к значениям по умолчанию
function LPS:ResetFramePosition()
	local db = LPS:GetDB()
	db.position = { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
	db.layout = db.layout or {}
	db.layout.sideSlots = db.layout.sideSlots or {}
	db.layout.sideSlots.left = db.layout.sideSlots.left or {}
	db.layout.sideSlots.right = db.layout.sideSlots.right or {}
	db.layout.sideSlots.left.offsetX = 0
	db.layout.sideSlots.left.offsetY = 0
	db.layout.sideSlots.right.offsetX = 0
	db.layout.sideSlots.right.offsetY = 0
	local holder = LPS.frame and LPS.frame.holder
	if holder and holder.isMoving then
		if LPS.SetMoveMode then
			LPS:SetMoveMode(false)
		end
		holder.isMoving = false
	end
	LPS:ApplyHolderPosition()
	if LPS.ApplyLayout then
		LPS:ApplyLayout()
	end
	LPS:Print("The frame position is reset")
end

-- Включает или выключает режим перемещения фрейма
function LPS:ToggleMoveMode()
	-- проверяем, включен ли режим
	local moving = LPS.frame.holder.isMoving or false
	if moving then
		-- выключаем
		LPS:SetMoveMode(false)
		LPS.frame.holder.isMoving = false
	else
		-- включаем
		LPS:SetMoveMode(true)
		LPS.frame.holder.isMoving = true
	end
end

-- Возвращает ID континента, на котором находится игрок
function LPS:GetContinentID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	local mapInfo = C_Map.GetMapInfo(mapID)
	return mapInfo and mapInfo.parentMapID or nil
end

-- Возвращает название континента, на котором находится игрок
function LPS:GetContinentName()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return end
    local continentID = mapInfo.parentMapID
    if not continentID then return end
    return C_Map.GetMapInfo(continentID).name or nil
end

-- Возвращает статус зоны (PVP/мирная и т.п.), опционально цвет или цветной текст
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

-- Возвращает отформатированное игровое время с учетом CVar (12/24ч, локальное/серверное)
function LPS:GetFormattedGameTime()
	local db = LPS:GetDB()
	local layout = db and db.layout or {}
	local is24h = db and db.general and db.general.is24H
	local useLocal = GetCVarBool("timeMgrUseLocalTime")

	local function getClassColor()
		local _, class = UnitClass("player")
		local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
		if c then
			return c.r, c.g, c.b
		end
		return 1, 1, 1
	end

	local function rgbToHex(r, g, b)
		r = tonumber(r) or 1
		g = tonumber(g) or 1
		b = tonumber(b) or 1
		local rr = math.floor(r * 255 + 0.5)
		local gg = math.floor(g * 255 + 0.5)
		local bb = math.floor(b * 255 + 0.5)
		return string.format("%02x%02x%02x", rr, gg, bb)
	end

	local function getColonToken()
		local mode = layout.customColor
		if mode == nil then
			mode = 3
		end
		local r, g, b
		if mode == 1 then
			local user = layout.userColor
			r, g, b = (user and user.r) or 1, (user and user.g) or 1, (user and user.b) or 1
		elseif mode == 2 then
			r, g, b = getClassColor()
		else
			r, g, b = 1, 1, 1
		end
		return "|cff" .. rgbToHex(r, g, b) .. ":|r"
	end

	local colon = getColonToken()

	local h, m, s
	if useLocal then
		h = tonumber(date("%H"))
		m = tonumber(date("%M"))
		s = tonumber(date("%S"))
	else
		h, m = GetGameTime()
	end

	if not is24h then
		local suffix = (h >= 12) and "PM" or "AM"
		h = h % 12
		if h == 0 then h = 12 end
		if db.general.seconds and useLocal then
			return string.format("%02d%s%02d%s%02d %s", h, colon, m, colon, s, suffix)
		else
			return string.format("%02d%s%02d %s", h, colon, m, suffix)
		end
	end

	if db.general.seconds and useLocal then
			return string.format("%02d%s%02d%s%02d", h, colon, m, colon, s)
		else
			return string.format("%02d%s%02d", h, colon, m)
		end
end

-- Применяет значения по умолчанию к таблице базы данных рекурсивно
function LPS:ApplyDefaults(db, defaults)
	if type(db) ~= "table" then db = {} end

	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = LPS:ApplyDefaults(db[k], v)
		elseif db[k] == nil and k ~= "addonTextColor" then
			db[k] = v
		end
	end

	return db
end

-- Возвращает цвет из настроек аддона по ключу
function LPS:GetColor(key)
	local db = LPS:GetDB()
	local colors = db.settings and db.settings.colors
	local c = colors and colors[key]
	if key == "bg" and colors and colors.bgEnable == false then
		local r, g, b = unpack(c or {0, 0, 0, 0})
		return r, g, b, 0
	end
	return unpack(c or {1, 1, 1, 1})
end

function LPS:ApplyCoordsUpdateInterval()
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame.coords
	if not f or not f._lpsUpdateFunc then return end
	local interval = tonumber(db.general.coordsTimeUpdate) or 0.2
	if interval < 0.05 then interval = 0.05 end
	if f._lpsTicker then
		f._lpsTicker:Cancel()
		f._lpsTicker = nil
	end
	f._lpsTicker = C_Timer.NewTicker(interval, function()
		if f._lpsUpdateFunc then
			f._lpsUpdateFunc(f)
		end
	end)
end

function LPS:ApplyStyle()
	local db = LPS:GetDB()
	local frames = LPS.frame
	if not frames then return end
	for _, f in pairs({frames.location, frames.coords, frames.time, frames.gold, frames.system}) do
		if f then
			f:SetBackdrop({
				bgFile   = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				tile     = false,
				edgeSize = db.settings.borderSize or 2,
				insets   = {left=1,right=1,top=1,bottom=1},
			})
			f:SetBackdropColor(LPS:GetColor("bg"))
			f:SetBackdropBorderColor(LPS:GetColor("border"))
			if f._lpsUpdateFunc then
				f._lpsUpdateFunc(f)
			end
		end
	end
	if LPS.ApplyLayout then
		LPS:ApplyLayout()
	end
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
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
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyAllSettings()
	LPS:ApplyTimeFormat()
	LPS:ApplyCoordsUpdateInterval()
	LPS:ApplyLayout()
	LPS:ApplyStyle()
	LPS:ApplyDTVisibility()
	LPS:ApplyCoordsVisibility()
	LPS:ApplyTimeVisibility()
	LPS:ApplyVisibility()
end

-- Возвращает координаты игрока на текущей карте
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

-- Обертка для Tourist:GetMapNameByIDAlt(mapID)
function LPS:GetMapNameByIDAlt(mapID)
	return Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN
end

function LPS:DisableMoveModeIfActive()
	local holder = LPS.frame and LPS.frame.holder
	if holder and holder.isMoving then
		if LPS.SetMoveMode then
			LPS:SetMoveMode(false)
		end
		holder.isMoving = false
	end
end

function LPS:EnsureOptionsCloseHooks()
	if not LPS._optionsCloseHooks then
		LPS._optionsCloseHooks = {}
	end

	local function hookOnHide(frame, key)
		if not (frame and frame.HookScript) then return end
		if LPS._optionsCloseHooks[key] then return end
		LPS._optionsCloseHooks[key] = true
		frame:HookScript("OnHide", function()
			if LPS.DisableMoveModeIfActive then
				LPS:DisableMoveModeIfActive()
			end
		end)
	end

	hookOnHide(_G.SettingsPanel, "SettingsPanel")
	hookOnHide(_G.InterfaceOptionsFrame, "InterfaceOptionsFrame")
end

function LPS:ToggleOptions()
	local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true) and LibStub("AceConfigDialog-3.0")
	if LPS.EnsureOptionsCloseHooks then
		LPS:EnsureOptionsCloseHooks()
	end
	if aceDialog and LPS.Options and LPS.Options.aceAppName then
		local appName = LPS.Options.aceAppName
		if aceDialog.OpenFrames and aceDialog.OpenFrames[appName] then
			if LPS.DisableMoveModeIfActive then
				LPS:DisableMoveModeIfActive()
			end
			aceDialog:Close(appName)
		else
			aceDialog:Open(appName)
			local f = aceDialog.OpenFrames and aceDialog.OpenFrames[appName]
			if f then
				if not LPS._aceOptionsTitleOffsetApplied then
					LPS._aceOptionsTitleOffsetApplied = true
					local titleText = f.titletext or (f.frame and f.frame.titletext)
					if titleText and titleText.ClearAllPoints and titleText.SetPoint then
						titleText:ClearAllPoints()
						titleText:SetPoint("TOP", f.frame, "TOP", 0, -14)
					end
				end
				if f.EnableResize then
					f:EnableResize(false)
				end
				local frame = f.frame
				if frame and frame.SetResizable then
					frame:SetResizable(false)
				end
				if frame and frame.HookScript then
					LPS._optionsCloseHooks = LPS._optionsCloseHooks or {}
					if not LPS._optionsCloseHooks.AceConfigDialogFrame then
						LPS._optionsCloseHooks.AceConfigDialogFrame = true
						frame:HookScript("OnHide", function()
							if LPS.DisableMoveModeIfActive then
								LPS:DisableMoveModeIfActive()
							end
						end)
					end
				end
			end
		end
		return
	end

	if _G.SettingsPanel and _G.SettingsPanel.IsShown and _G.SettingsPanel:IsShown() then
		if LPS.DisableMoveModeIfActive then
			LPS:DisableMoveModeIfActive()
		end
		_G.SettingsPanel:Hide()
		return
	end
	if _G.InterfaceOptionsFrame and _G.InterfaceOptionsFrame.IsShown and _G.InterfaceOptionsFrame:IsShown() then
		if LPS.DisableMoveModeIfActive then
			LPS:DisableMoveModeIfActive()
		end
		_G.InterfaceOptionsFrame:Hide()
		return
	end

	if LPS.Options and LPS.Options.category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(LPS.Options.category:GetID())
	end
end
