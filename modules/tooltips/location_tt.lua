local Tourist = LibStub("LibTourist-3.0") -- подключаем Tourist

local MyAddon = _G.MyAddon
local LPS = MyAddon.LPS
local L = MyAddon.L

LPS_DB = LPS_DB or {}

-- Icons on Location Panel
local PET_ICON = "|TInterface\\AddOns\\LocationPlus\\media\\pet.tga:14:14|t"
local LEVEL_ICON = "|TInterface\\AddOns\\LocationPlus\\media\\levelup.tga:14:14|t"

-- Zone level range
local function GetLevelRange(zoneText)
	local low, high = Tourist:GetLevel(zoneText)
	local dlevel
	if low > 0 and high > 0 then
		local r, g, b = Tourist:GetLevelColor(zoneText)
		if low ~= high then
			dlevel = format("|cff%02x%02x%02x%d-%d|r", r*255, g*255, b*255, low, high) or ""
		else
			dlevel = format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, high) or ""
		end
	end
    if dlevel ~= nil then
        dlevel = format(" (%s) ", dlevel)..LEVEL_ICON
    end
	return dlevel or ""
end

-- PetBattle Range
local function GetBattlePetLvl(zoneText)
	local uniqueZone = Tourist:GetUniqueZoneNameForLookup(zoneText, LPS:GetContinentID())
	local low,high = Tourist:GetBattlePetLevel(uniqueZone)
	local plevel
	if low ~= nil or high ~= nil then
		if low ~= high then
			plevel = format("%d-%d", low, high)
		else
			plevel = format("%d", high)
		end
	end
    if plevel ~= nil then
        plevel = format(" (%s) ", plevel)..PET_ICON
    end
	return plevel or ""
end

function LPS:BuildLocationTooltip()	
	local mapID = C_Map.GetBestMapForUnit("player")
	local zoneText = Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN;
	local r, g, b = unpack(LPS_DB.colors)

  GameTooltip:ClearLines()

    -- Zone
	GameTooltip:AddDoubleLine(L["Zone"]..": ", zoneText, r, g, b)

	-- Continent
	GameTooltip:AddDoubleLine(L["Continent"]..": ", Tourist:GetContinent(zoneText), r, g, b)

	-- Home
	GameTooltip:AddDoubleLine(L["Home"]..": ", GetBindLocation(), r, g, b, 0.41, 0.8, 0.94)

	-- Status
	GameTooltip:AddDoubleLine(L["Status"]..": ", LPS:GetZoneStatus(), r, g, b)

	if LPS_DB.tooltips.location.zoneLevel or LPS_DB.tooltips.location.battlePets then
		GameTooltip:AddLine(" ")
	end

	-- Zone level range
	if LPS_DB.tooltips.location.zoneLevel then
		local checklvl = GetLevelRange(zoneText)
		if checklvl ~= "" then
				GameTooltip:AddDoubleLine(L["Level range"]..": ", checklvl, r, g, b)
		end
	end

	-- BaGameTooltiple Pet Levels
	if LPS_DB.tooltips.location.battlePets then
		local checkbpet = GetBattlePetLvl(zoneText)
		if checkbpet ~= "" then
				GameTooltip:AddDoubleLine(L["Battle Pet level"].. ": ", checkbpet, r, g, b)
		end
	end

	if GameTooltipTextLeft1 then
			GameTooltipTextLeft1:SetFontObject(GameTooltipText)
	end
end
