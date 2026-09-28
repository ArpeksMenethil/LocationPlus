local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
LPS_DB = LPS_DB or {}

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LPS.TBC and LibStub:GetLibrary("LibTouristClassicBCA", true) then
	Tourist = LibStub("LibTouristClassicBCA")
elseif LPS.Mists and LibStub:GetLibrary("LibTouristClassic-1.0", true) then
	Tourist = LibStub("LibTouristClassic-1.0")
elseif LPS.Classic and LibStub:GetLibrary("LibTouristClassicEra", true) then
	Tourist = LibStub("LibTouristClassicEra")
end


-- Icons on Location Panel
local PET_ICON = LPS.icons.Pet
local LEVEL_ICON = LPS.icons.Level
local FISH_ICON = LPS.icons.Fish


-- Zone level range
function LPS:GetLevelRange(uiMapID)
	local zoneText = C_Map.GetMapInfo(uiMapID).name

	local minLvl, maxLvl, fishLvl

	if uiMapID and C_Map and C_Map.GetMapLevels then
		local ok, a, b = pcall(C_Map.GetMapLevels, uiMapID)
		if ok then
			minLvl, maxLvl = a, b
		end
	end

	local dlevel
	if not Tourist then
		if LPS.Forever then
			minLvl = LPS:GetDB().levelTable[uiMapID].minLevel or nil
			maxLvl = LPS:GetDB().levelTable[uiMapID].maxLevel or nil
		end

		if minLvl and maxLvl and minLvl > 0 and maxLvl > 0 then
			if minLvl ~= maxLvl then
				dlevel = format("|cff%02x%02x%02x%d-%d|r", 255, 255, 255, minLvl, maxLvl)
			else
				dlevel = format("|cff%02x%02x%02x%d|r", 255, 255, 255, maxLvl)
			end
			return dlevel
		end
	end

	if Tourist and zoneText then
		local low, high = Tourist:GetLevel(zoneText)
		if low and high and low > 0 and high > 0 then
			local r, g, b = Tourist:GetLevelColor(zoneText)
			if low ~= high then
				dlevel = format("|cff%02x%02x%02x%d-%d|r", r*255, g*255, b*255, low, high)
			else
				dlevel = format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, high)
			end
		end
	end

	return dlevel
end

-- Fishing Level
function LPS:GetFishingLvl()
	if LPS.Retail then return end

	local mapID = C_Map.GetBestMapForUnit("player")
	local minFish, maxFish

	if Tourist then
		local zoneText = Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN
		minFish, maxFish = Tourist:GetFishingLevel(zoneText)
	else
		minFish = LPS:GetDB().levelTable[mapID].minFish
	end

	if minFish then
			return minFish, maxFish
	else
		return
	end
end

-- PetBattle Range
function LPS:GetBattlePetLvl(zoneText)
	if not (LPS.Retail or LPS.Mists) then return end
	if not Tourist or not Tourist.GetBattlePetLevel then return end

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
		plevel = format("|cff%02x%02x%02x%s|r", 255, 255, 255, plevel)
	else
		plevel = "25 "
	end

	return plevel
end

-- Dungeon coords
local function GetDungeonCoords(zone)
	local db = LPS:GetDB()
	local z, x, y = "", 0, 0;
	local dcoords

	if Tourist:IsInstance(zone) then
		z, x, y = Tourist:GetEntrancePortalLocation(zone);
	end

	if z == nil then
		dcoords = ""
	elseif db.tooltips.location.recomDungeonCoords then
		x = tonumber(LPS:Round(x*100, 2))
		y = tonumber(LPS:Round(y*100, 2))
		dcoords = format(" |cffffffff(%d, %d)|r", x, y)
	else
		dcoords = ""
	end

	return dcoords
end

-- PvP/Raid filter
local function PvPorRaidFilter(zone)
	local db = LPS:GetDB()
	local isPvP, isRaid;

	isPvP = nil;
	isRaid = nil;

	local isArena = false
	if not LPS.TBC then
		isArena = Tourist.IsArena and Tourist:IsArena(zone) or false
	end
	local isBattleground = Tourist.IsBattleground and Tourist:IsBattleground(zone) or false
	if isArena or isBattleground then
		isPvP = true;
	end

	local groupMinSize = Tourist.GetInstanceGroupMinSize and Tourist:GetInstanceGroupMinSize(zone) or 0
	if(not isPvP and groupMinSize >= 10) then
		isRaid = true;
	end

	if db.tooltips.location.hides.pvp and isPvP then
		return nil
	end
	if db.tooltips.location.hides.raids and isRaid then
		return nil
	end

	return (isPvP and "|cffff0000 "..PVP.."|r" or "")..(isRaid and "|cffff4400 "..RAID.."|r" or "")
end

-- Recommended zones
local function GetRecomZones(zone)
	local low, high = Tourist:GetLevel(zone)
	local r, g, b = Tourist:GetLevelColor(zone)
	local zContinent = Tourist:GetContinent(zone)
	local continentName = LPS:GetContinentName()

	if PvPorRaidFilter(zone) == nil then return end

	GameTooltip:AddDoubleLine(
		zone..PvPorRaidFilter(zone),
		format("|cff%02xff00%s|r", continentName == zContinent and 0 or 255, zContinent)
		..(" |cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))),
		1, 1, 1
	);

	return true
end

-- Dungeons in the zone
local function GetZoneDungeons(dungeon)
	local low, high = Tourist:GetLevel(dungeon)
	local r, g, b = Tourist:GetLevelColor(dungeon)
	local groupSize = Tourist.GetInstanceGroupMinSize and Tourist:GetInstanceGroupMinSize(dungeon) or 0
	local groupSizeStyle = (groupSize > 0 and format("|cFFFFFF00|r (%d)", groupSize) or "")
	local name = dungeon

	if PvPorRaidFilter(dungeon) == nil then return end

	local levelText = (low == 0 and high == 0) and "" or ("|cff%02x%02x%02x%s|r"):format(
		r * 255, g * 255, b * 255, (low == high and low or ("%d-%d"):format(low, high))
	)

	GameTooltip:AddDoubleLine(
		name..groupSizeStyle.." "..GetDungeonCoords(dungeon)..PvPorRaidFilter(dungeon),
		levelText,
		1, 1, 1
	)

	return true

end

-- Recommended Dungeons
local function GetRecomDungeons(dungeon)
	local low, high = Tourist:GetLevel(dungeon);
	local r, g, b = Tourist:GetLevelColor(dungeon);
	local instZone = Tourist:GetInstanceZone(dungeon);
	local name = dungeon

	if PvPorRaidFilter(dungeon) == nil then return end

	if instZone == nil then
		instZone = ""
	else
		instZone = "|cFFFFA500 ("..instZone..")"
	end

	GameTooltip:AddDoubleLine(
		name..instZone..GetDungeonCoords(dungeon)..PvPorRaidFilter(dungeon),
		("|cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))),
		1, 1, 1
	)

	return true
end

function LPS:GetContinentName()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    
    if not currentMapID then
        return "UNKNOWN"
    end
    
    local mapID = currentMapID
    local continentName = nil
    
    for i = 1, 10 do
        local mapInfo = C_Map.GetMapInfo(mapID)
        
        if not mapInfo then
            break
        end
        
        if mapInfo.mapType == Enum.UIMapType.Continent or mapInfo.mapType == Enum.UIMapType.World then
            continentName = mapInfo.name
            break
        end
        
        if mapInfo.parentMapID and mapInfo.parentMapID ~= 0 then
            mapID = mapInfo.parentMapID
        else
            if not continentName then
                continentName = mapInfo.name
            end
            break
        end
    end
    
    return continentName or "UNKNOWN"
end

function LPS:BuildLocationTooltip()
	local db = LPS:GetDB()
	local mapID = C_Map.GetBestMapForUnit("player")
	local zoneText = C_Map.GetMapInfo(mapID).name

	local r, g, b = LPS:GetColor("text")
	local rB, gB, bB = LPS:GetColor("tooltipSetting")
	local rY, gY, bY = LPS:GetColor("tooltip")

	GameTooltip:ClearLines()

	-- Zone
	GameTooltip:AddDoubleLine(LPS:L("Zone")..": ", zoneText, r, g, b)

	-- Continent
	GameTooltip:AddDoubleLine(LPS:L("Continent")..": ", LPS:GetContinentName(), r, g, b)

	-- Home
	GameTooltip:AddDoubleLine(LPS:L("Home")..": ", GetBindLocation(), r, g, b, 0.41, 0.8, 0.94)

	-- Status
	if db.tooltips.location.status then
		GameTooltip:AddDoubleLine(LPS:L("Status")..": ", LPS:GetZoneStatus(), r, g, b)
	end

	local willShowExtra = false
	if db.tooltips.location.level then
		local zoneLevel = LPS:GetLevelRange(mapID)
		if zoneLevel then
			willShowExtra = true
		end
	end
	if not LPS.Retail and db.tooltips.location.fish then
		local minFish, maxFish = LPS:GetFishingLvl()
		if minFish or maxFish then
			willShowExtra = true
		end
	end
	if (LPS.Retail or LPS.Mists) and db.tooltips.location.battlePets then
		local checkbpet = LPS:GetBattlePetLvl(zoneText)
		if checkbpet then
			willShowExtra = true
		end
	end
	if willShowExtra then
		GameTooltip:AddLine(" ")
	end

	-- Zone level range
	if db.tooltips.location.level then
		local zoneLevel = LPS:GetLevelRange(mapID)
		if zoneLevel then
				GameTooltip:AddDoubleLine(LEVEL_RANGE..": ", zoneLevel.." "..LEVEL_ICON, r, g, b)
		end
	end

	-- Fishing
	if not LPS.Retail and db.tooltips.location.fish then
			local minFish, maxFish = LPS:GetFishingLvl()
			if minFish and maxFish then
				GameTooltip:AddDoubleLine(PROFESSIONS_FISHING..": ", format("%s-%s %s", minFish, maxFish, FISH_ICON), r, g, b)
			elseif minFish then
				GameTooltip:AddDoubleLine(PROFESSIONS_FISHING..": ", format("%s %s", minFish, FISH_ICON), r, g, b)
			end
	end

	-- Pet Levels
	if (LPS.Retail or LPS.Mists) and db.tooltips.location.battlePets then
		local checkbpet = LPS:GetBattlePetLvl(zoneText)
		if checkbpet then
				GameTooltip:AddDoubleLine(LPS:L("Battle Pet level").. ": ", checkbpet.." "..PET_ICON, r, g, b)
		end
	end

	-- Recommended zones
	if db.tooltips.location.recomZone then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LPS:L("Recommended Zones")..": ", rY, gY, bY)
		local max = tonumber(db.tooltips.location.recomZoneMax) or 5
		if max < 3 then max = 3 elseif max > 10 then max = 10 end
		local shown = 0
		for zone in Tourist:IterateRecommendedZones() do
			if shown >= max then break end
			if GetRecomZones(zone) then
				shown = shown + 1
			end
		end
	end

	-- Instances in the zone
	if db.tooltips.location.zoneDungeon and Tourist:DoesZoneHaveInstances(zoneText) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(DUNGEONS.." "..LPS:L("in").." "..zoneText..": ", rY, gY, bY)
		local max = tonumber(db.tooltips.location.zoneDungeonMax) or 5
		if max < 3 then max = 3 elseif max > 10 then max = 10 end
		local shown = 0
		for dungeon in Tourist:IterateZoneInstances(zoneText) do
			if shown >= max then break end
			if GetZoneDungeons(dungeon) then
				shown = shown + 1
			end
		end
	end

	-- Recommended Instances
	local level = UnitLevel('player')
	if db.tooltips.location.recomDungeon and Tourist:HasRecommendedInstances() and level >= 15 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LPS:L("Recommended Dungeons")..": ", rY, gY, bY)
		local max = tonumber(db.tooltips.location.recomDungeonMax) or 5
		if max < 3 then max = 3 elseif max > 10 then max = 10 end
		local shown = 0
		for dungeon in Tourist:IterateRecommendedInstances() do
			if shown >= max then break end
			if GetRecomDungeons(dungeon) then
				shown = shown + 1
			end
		end
	end

	if LPS.Retail or LPS.Forever then
		-- Professions
		local prof1, prof2, archy, fishing, cooking = GetProfessions()
		if db.tooltips.location.proffession and (prof1 or prof2 or archy or fishing or cooking) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(TRADE_SKILLS..":", rY, gY, bY)

			local proftable = { GetProfessions() }
			for _, id in ipairs(proftable) do
				if id then
					local name, icon, rank, maxRank, _, _, _, rankModifier = GetProfessionInfo(id)

					if rank < maxRank or not db.tooltips.location.proffessionHideMaxLevel then
						icon = ("|T%s:12:12:1:0|t"):format(icon)

						if rankModifier and rankModifier > 0 then
							GameTooltip:AddDoubleLine(
								format("%s %s:", icon, name),
								format("%d |cFF6b8df4+ %d|r / %d", rank, rankModifier, maxRank),
								1, 1, 1,
								rY, gY, bY
							)
						else
							GameTooltip:AddDoubleLine(
								format("%s %s:", icon, name),
								format("%d / %d", rank, maxRank),
								1, 1, 1,
								rY, gY, bY
							)
						end
					end
				end
			end
		end
	else
		if db.tooltips.location.proffession then
			local lines = {}

			-- Список профессий, которые нужно показывать
			local professions = {
				-- Primary Professions
				LPS:L("Alchemy"), LPS:L("Blacksmithing"), LPS:L("Enchanting"), LPS:L("Engineering"), LPS:L("Jewelcrafting"),
				LPS:L("Herbalism"), LPS:L("Leatherworking"), LPS:L("Mining"), LPS:L("Skinning"), LPS:L("Tailoring"),
				-- Secondary Professions
				LPS:L("Cooking"), LPS:L("First Aid"), LPS:L("Fishing")
			}

			local professionsSet = {}
			for _, name in ipairs(professions) do
				professionsSet[name] = true
			end

			for skillIndex = 1, GetNumSkillLines() do
				local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank =
					GetSkillLineInfo(skillIndex)

				if skillName and not isHeader and professionsSet[skillName] then
					if skillRank < skillMaxRank or not db.tooltips.location.proffessionHideMaxLevel then
						local rightText

						if skillModifier and skillModifier > 0 then
							rightText = format(
								"%s |cFF6b8df4+ %s|r / %s",
								skillRank, skillModifier, skillMaxRank
							)
						else
							rightText = format("%s / %s", skillRank, skillMaxRank)
						end

						table.insert(lines, { skillName .. ":", rightText })
					end
				end
			end

			-- 🔑 выводим только если есть профессии
			if #lines > 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(TRADE_SKILLS .. ":", rY, gY, bY)

				for _, line in ipairs(lines) do
					GameTooltip:AddDoubleLine(
						line[1], line[2],
						1, 1, 1, rY, gY, bY
					)
				end
			end
		end

	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Toggle WorldMap"), rB, gB, bB, rB, gB, bB)
	GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), rB, gB, bB, rB, gB, bB)
	GameTooltip:AddDoubleLine(LPS:L("Shift+LMB"), LPS:L("Send the coordinates to the chat"), rB, gB, bB, rB, gB, bB)


	if GameTooltipTextLeft1 then
		local rT, gT, bT = GameTooltipTextLeft1:GetTextColor()
		GameTooltipTextLeft1:SetFontObject(GameTooltipText)
		GameTooltipTextLeft1:SetTextColor(rT, gT, bT)
	end
	if GameTooltipTextRight1 then
		local rT, gT, bT = GameTooltipTextRight1:GetTextColor()
		GameTooltipTextRight1:SetFontObject(GameTooltipText)
		GameTooltipTextRight1:SetTextColor(rT, gT, bT)
	end
end
