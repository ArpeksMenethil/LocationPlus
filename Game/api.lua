local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LibStub:GetLibrary("LibTouristClassicBCA", true) then
	Tourist = LibStub("LibTouristClassicBCA")
end

-- Выводит сообщение в чат с префиксом аддона и поддержкой локализации
function LPS:Print(msg)
	print("|c"..LPS.addonTextColor..LPS.addonName.."|r: " .. LPS:L(msg))
end

-- Возвращает локализованную строку по ключу или сам ключ, если значение = true
function LPS:L(key)
	local val = _G.ArpeksLPS.L[key]
	return val == true and key or val
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
			return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r:|cFFFFFFFF%02d|r %s", h, m, s, suffix)
		else
			return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r %s", h, m, suffix)
		end
	end

	if db.general.seconds and useLocal then
			return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r:|cFFFFFFFF%02d|r", h, m, s)
		else
			return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r", h, m)
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
			if f.text then
				f.text:SetFont(GameFontNormalSmall:GetFont(), db.settings.fontSize or 12)
			end
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
	LPS:ApplyStyle()
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

-- Открыть вкладку с натсройками аддона
function LPS:OpenOptions()
	local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true) and LibStub("AceConfigDialog-3.0")
	if aceDialog and LPS.Options and LPS.Options.aceAppName then
		aceDialog:Open(LPS.Options.aceAppName)
		return
	end
	if LPS.Options and LPS.Options.category then
		Settings.OpenToCategory(LPS.Options.category:GetID())
	end
end
