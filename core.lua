local _, LPS, LPS_DB, L = ...

_G.MyAddon = _G.MyAddon or {}
_G.MyAddon.LPS = LPS or {}
_G.MyAddon.LPS_DB = LPS_DB or {}
_G.MyAddon.L = L or {}

local Tourist = LibStub("LibTourist-3.0")

local addonName = _
local addonVersion = C_AddOns.GetAddOnMetadata(_, "Version") or "?.?.?"

LPS.holder = CreateFrame("Frame", "LPS_Holder", UIParent, "BackdropTemplate")
LPS.holder:SetSize(420, 22)
LPS.holder:SetPoint("TOP", UIParent, "TOP", 0, -10)

LPS.holder:RegisterEvent("ADDON_LOADED")
LPS.holder:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        print("|cff1784d1" .. addonName .. "|r загружен. Версия: |cff1784d1" .. addonVersion .. "|r")
    end
end)

function LPS:getContinentID()
	-- Получаем ID карты, на которой находится игрок
	local mapID = C_Map.GetBestMapForUnit("player")
	local continentID = nil

	if mapID then
			local mapInfo = C_Map.GetMapInfo(mapID)
			if mapInfo then
					continentID = mapInfo.parentMapID -- родительская карта — это континент
			end
	end

	return continentID
end

-- Status
function LPS:GetZoneStatus(color)
	local status = ""
	local statusText
	local r, g, b = 1, 1, 0
	local pvpType = C_PvP.GetZonePVPInfo()
	local inInstance, _ = IsInInstance()

	if (pvpType == "sanctuary") then
		status = SANCTUARY_TERRITORY
		r, g, b = 0.41, 0.8, 0.94
	elseif(pvpType == "arena") then
		status = ARENA
		r, g, b = 1, 0.1, 0.1
	elseif(pvpType == "friendly") then
		status = FRIENDLY
		r, g, b = 0.1, 1, 0.1
	elseif(pvpType == "hostile") then
		status = HOSTILE
		r, g, b = 1, 0.1, 0.1
	elseif(pvpType == "contested") then
		status = CONTESTED_TERRITORY
		r, g, b = 1, 0.7, 0.10
	elseif(pvpType == "combat" ) then
		status = COMBAT
		r, g, b = 1, 0.1, 0.1
	elseif inInstance then
		status = AGGRO_WARNING_IN_INSTANCE
		r, g, b = 1, 0.1, 0.1
	else
		status = CONTESTED_TERRITORY
	end

	statusText = format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status)

	if color then
		return r, g, b
	else
		return statusText
	end
end

_G.MyAddon = MyAddon