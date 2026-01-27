local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:ApplyLayout()
	local db = LPS:GetDB()
	local frames = LPS.frame
	if not db or not frames then return end

	local layout = db.layout or {}
	local dtWidth = tonumber(layout.dtwidth) or 100
	local dtHeight = tonumber(layout.dtheight) or 22
	local locHeight = dtHeight + ((layout.ht and 6) or 0)
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

	if frames.coords then
		frames.coords:SetSize(dtWidth, dtHeight)
	end
	if frames.time then
		frames.time:SetSize(dtWidth, dtHeight)
	end
	if frames.location and frames.location.SetHeight then
		frames.location:SetHeight(locHeight)
	end

	if frames.location and frames.coords then
		frames.coords:ClearAllPoints()
		frames.coords:SetPoint("RIGHT", frames.location, "LEFT", -spacing, 0)
	end
	if frames.location and frames.time then
		frames.time:ClearAllPoints()
		frames.time:SetPoint("LEFT", frames.location, "RIGHT", spacing, 0)
	end

	if frames.holder and not frames.holder.isMoving then
		if layout.frameStrata then
			frames.holder:SetFrameStrata(layout.frameStrata)
		end
		if layout.frameLevel then
			frames.holder:SetFrameLevel(tonumber(layout.frameLevel) or 1)
		end
	end

	if frames.location and frames.location.text then
		if layout.lpauto == false then
			frames.location:SetWidth(tonumber(layout.lpwidth) or 200)
			frames.location.text:SetWidth((tonumber(layout.lpwidth) or 200) - 20)
			frames.location.text:SetWordWrap(false)
			frames.location.text:SetMaxLines(1)
		else
			frames.location.text:SetWidth(0)
		end
	end

	if frames.location and frames.location._lpsUpdateFunc then
		frames.location._lpsUpdateFunc(frames.location)
		if frames.location.SetHeight then
			frames.location:SetHeight(locHeight)
		end
	end
	if frames.coords and frames.coords._lpsUpdateFunc then
		frames.coords._lpsUpdateFunc(frames.coords)
	end
	if frames.time and frames.time._lpsUpdateFunc then
		frames.time._lpsUpdateFunc(frames.time)
	end

	local fontFile, defaultFlags = resolveFont()
	local size = (db.settings and db.settings.fontSize) or 12
	local flags = defaultFlags or "NONE"
	for _, f in pairs({frames.location, frames.time}) do
		if f and f.text then
			f.text:SetFont(fontFile, size, flags)
			local r, g, b = getLayoutTextColor(layout.customColor, layout.userColor)
			if r then
				f.text:SetTextColor(r, g, b)
			end
		end
	end
	if frames.coords and frames.coords.text then
		frames.coords.text:SetFont(fontFile, size, flags)
		local r, g, b = getLayoutTextColor(layout.customColor, layout.userColor)
		if r then
			frames.coords.text:SetTextColor(r, g, b)
		end
	end

	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyHideBlizzardZoneText()
	local db = LPS:GetDB()
	local hide = db and db.general and db.general.hideBlizzardZoneText
	if ZoneTextFrame then
		ZoneTextFrame:SetShown(not hide)
	end
	if SubZoneTextFrame then
		SubZoneTextFrame:SetShown(not hide)
	end
end

function LPS:ApplyDTVisibility()
	local db = LPS:GetDB()
	local show = db and db.layout and db.layout.dtshow
	local frames = LPS.frame
	local timeF = frames and frames.time
	local coordsF = frames and frames.coords
	if show == false then
		if timeF then
			timeF:Hide()
		end
		if coordsF then
			coordsF:Hide()
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
	if db.layout and db.layout.dtshow == false then
		f:Hide()
		if LPS.UpdateFrameSize then
			LPS:UpdateFrameSize()
		end
		return
	end
	local hide = db.show and db.show.hideTime
	f:SetShown(not hide)
	if LPS.UpdateFrameSize then
		LPS:UpdateFrameSize()
	end
end

function LPS:ApplyCoordsVisibility()
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame.coords
	if not db or not f then return end
	local hide = false
	if db.show and db.show.hideCoords then
		hide = true
	elseif db.show and db.show.hideCoordsInInstance and IsInInstance() then
		hide = true
	end

	f:SetShown(not hide)
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
		LPS_DB = CopyTable(LPS.defaults)
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
LPS_DB = LPS_DB or {}

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LibStub:GetLibrary("LibTouristClassicBCA", true) then
	Tourist = LibStub("LibTouristClassicBCA")
end

local AceLocale = LibStub and LibStub:GetLibrary("AceLocale-3.0", true)
local Locale
if AceLocale then
	Locale = AceLocale:GetLocale("LocationPlus", true)
end

-- Выводит сообщение в чат с префиксом аддона и поддержкой локализации
function LPS:Print(msg)
	print("|c"..LPS.addonTextColor..LPS.addonName.."|r: " .. LPS:L(msg))
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

	local legacy = _G.ArpeksLPS and _G.ArpeksLPS.L
	if legacy then
		local val = legacy[key]
		if val == true then
			return key
		end
		if val ~= nil then
			return val
		end
	end

	return key
end

function LPS:GetDB()
	if LPS.db and LPS.db.profile then
		return LPS.db.profile
	end
	return LPS_DB
end

-- Сбрасывает позицию основного фрейма к значениям по умолчанию
function LPS:ResetFramePosition()
	local db = LPS:GetDB()
	db.position = { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
	LPS:ApplyHolderPosition()
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
	local continentID = C_Map.GetMapInfo(mapID).parentMapID
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
	local is24h = GetCVarBool("timeMgrUseMilitaryTime")
	local useLocal = GetCVarBool("timeMgrUseLocalTime")

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
			return string.format("%d:%02d:%02d %s", h, m, s, suffix)
		else
			return string.format("%d:%02d %s", h, m, suffix)
		end
	end

	if db.general.seconds and useLocal then
			return string.format("%d:%02d:%02d", h, m, s)
		else
			return string.format("%d:%02d", h, m)
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
	for _, f in pairs({frames.location, frames.coords, frames.time}) do
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
	if LPS.Retail then
		SetCVar("timeMgrUseMilitaryTime", db.general.is24H and 1 or 0)
	end
	local f = LPS.frame and LPS.frame.time
	if f and f._lpsUpdateFunc then
		f._lpsUpdateFunc(f)
	end
end

function LPS:ApplyAllSettings()
	LPS:ApplyTimeFormat()
	LPS:ApplyCoordsUpdateInterval()
	LPS:ApplyLayout()
	LPS:ApplyStyle()
	LPS:ApplyHideBlizzardZoneText()
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

function LPS:ToggleOptions()
	local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true) and LibStub("AceConfigDialog-3.0")
	if aceDialog and LPS.Options and LPS.Options.aceAppName then
		local appName = LPS.Options.aceAppName
		if aceDialog.OpenFrames and aceDialog.OpenFrames[appName] then
			aceDialog:Close(appName)
		else
			aceDialog:Open(appName)
		end
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

	if LPS.Options and LPS.Options.category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(LPS.Options.category:GetID())
	end
end
