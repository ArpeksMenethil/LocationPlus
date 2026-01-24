local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = _G.ArpeksLPS.L
LPS_DB = LPS_DB or {}

function LPS:print(msg)
	print("|c"..LPS.addonTextColor.."LocationPlus|r: " .. L[msg])
end

function LPS:ResetPosition()
	-- дефолтные координаты
	local defaultPos = { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }

	-- сохраняем в DB
	LPS_DB.position.point = defaultPos.point
	LPS_DB.position.relativePoint = defaultPos.relativePoint
	LPS_DB.position.x = defaultPos.x
	LPS_DB.position.y = defaultPos.y

	-- применяем позицию
	LPS:ApplyHolderPosition()

	LPS:print("The frame position is reset")
end

function LPS:ToggleMove()
	-- проверяем, включен ли режим
	local moving = LPS.holder.isMoving or false
	if moving then
		-- выключаем
		LPS:SetMoveMode(false)
		LPS.holder.isMoving = false
	else
		-- включаем
		LPS:SetMoveMode(true)
		LPS.holder.isMoving = true
	end
end

function LPS:GetContinentID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	local mapInfo = C_Map.GetMapInfo(mapID)
	return mapInfo and mapInfo.parentMapID or nil
end

function LPS:GetContinentName()
	local mapID = C_Map.GetBestMapForUnit("player")
	local continentID = C_Map.GetMapInfo(mapID).parentMapID
	return C_Map.GetMapInfo(continentID).name or nil
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

function LPS:GetFormattedGameTime()
	local is24h = GetCVarBool("timeMgrUseMilitaryTime")
	local useLocal = GetCVarBool("timeMgrUseLocalTime")

	local h, m
	if useLocal then
		h = tonumber(date("%H"))
		m = tonumber(date("%M"))
	else
		h, m = GetGameTime()
	end

	if not is24h then
		local suffix = (h >= 12) and "PM" or "AM"
		h = h % 12
		if h == 0 then h = 12 end
		return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r %s", h, m, suffix)
	end

	return string.format("|cFFFFFFFF%02d|r:|cFFFFFFFF%02d|r", h, m)
end

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

function LPS:GetColor(key)
	local c = LPS_DB.settings.colors and LPS_DB.settings.colors[key]
	return unpack(c or {1, 1, 1, 1})
end

----------------------------------------------------------------
-- Применение позиции
----------------------------------------------------------------
function LPS:ApplyHolderPosition()
	LPS_DB.position = LPS_DB.position or { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
	local p = LPS_DB.position
	self.holder:ClearAllPoints()
	self.holder:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

function LPS:Round(num, decimals)
	local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
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