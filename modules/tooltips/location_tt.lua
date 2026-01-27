local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
LPS_DB = LPS_DB or {}

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LibStub:GetLibrary("LibTouristClassicBCA", true) then
	Tourist = LibStub("LibTouristClassicBCA")
end


-- Icons on Location Panel
local PET_ICON = "|TInterface\\AddOns\\LocationPlus\\media\\pet.tga:14:14|t"
local LEVEL_ICON = "|TInterface\\AddOns\\LocationPlus\\media\\levelup.tga:14:14|t"
local FISH_ICON = "|TInterface\\AddOns\\LocationPlus\\media\\fish.tga:14:14|t"


-- Zone level range
function LPS:GetLevelRange(zoneText)
	local low, high = Tourist:GetLevel(zoneText)
	local dlevel
	if low > 0 and high > 0 then
		local r, g, b = Tourist:GetLevelColor(zoneText)
		if low ~= high then
			dlevel = format("|cff%02x%02x%02x%d-%d|r", r*255, g*255, b*255, low, high)
		else
			dlevel = format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, high)
		end
	end

	return dlevel
end

-- Fishing Level
function LPS:GetFishingLvl()
	if LPS.Retail then return end

	local mapID = C_Map.GetBestMapForUnit("player")
	local zoneText = Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN;
	local minFish, maxFish = Tourist:GetFishingLevel(zoneText)

	if minFish then
			return minFish, maxFish
	else
		return
	end
end

-- PetBattle Range
function LPS:GetBattlePetLvl(zoneText)
	if not LPS.Retail then return end

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
	local z, x, y = "", 0, 0;
	local dcoords

	if Tourist:IsInstance(zone) then
		z, x, y = Tourist:GetEntrancePortalLocation(zone);
	end

	if z == nil then
		dcoords = ""
	elseif LPS:GetDB().show.exactCoords then
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
	local isPvP, isRaid;

	isPvP = nil;
	isRaid = nil;

	if(not LPS.TBC and Tourist:IsArena(zone) or Tourist:IsBattleground(zone)) then
		isPvP = true;
	end

	if(not isPvP and Tourist:GetInstanceGroupMinSize(zone) >= 10) then
		isRaid = true;
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
end

-- Dungeons in the zone
local function GetZoneDungeons(dungeon)
	local low, high = Tourist:GetLevel(dungeon)
	local r, g, b = Tourist:GetLevelColor(dungeon)
	local groupSize = Tourist:GetInstanceGroupMinSize(dungeon)
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
end

function LPS:BuildLocationTooltip()
	local db = LPS:GetDB()
	local mapID = C_Map.GetBestMapForUnit("player")
	local zoneText = Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN;

	local r, g, b = LPS:GetColor("text")
	local rB, gB, bB = LPS:GetColor("tooltipSetting")
	local rY, gY, bY = LPS:GetColor("tooltip")

	GameTooltip:ClearLines()

	-- Zone
	GameTooltip:AddDoubleLine(LPS:L("Zone")..": ", zoneText, r, g, b)

	-- Continent
	GameTooltip:AddDoubleLine(LPS:L("Continent")..": ", Tourist:GetContinent(zoneText), r, g, b)

	-- Home
	GameTooltip:AddDoubleLine(LPS:L("Home")..": ", GetBindLocation(), r, g, b, 0.41, 0.8, 0.94)

	-- Status
	GameTooltip:AddDoubleLine(LPS:L("Status")..": ", LPS:GetZoneStatus(), r, g, b)

	if db.tooltips.location.level or db.tooltips.location.battlePets or db.tooltips.location.fish then
		GameTooltip:AddLine(" ")
	end

	-- Zone level range
	if db.tooltips.location.level then
		local zoneLevel = LPS:GetLevelRange(zoneText)
		if zoneLevel then
				GameTooltip:AddDoubleLine(LEVEL_RANGE..": ", zoneLevel.." "..LEVEL_ICON, r, g, b)
		end
	end

	-- Fishing
	if not LPS.Retail and db.tooltips.location.fish then
			local minFish, maxFish = LPS:GetFishingLvl()
			if minFish and maxFish then
				GameTooltip:AddDoubleLine(PROFESSIONS_FISHING..": ", format("%s-%s %s", minFish, maxFish, FISH_ICON), r, g, b)
			end
	end

	-- Pet Levels
	if LPS.Retail and db.tooltips.location.battlePets then
		local checkbpet = LPS:GetBattlePetLvl(zoneText)
		if checkbpet then
				GameTooltip:AddDoubleLine(LPS:L("Battle Pet level").. ": ", checkbpet.." "..PET_ICON, r, g, b)
		end
	end

	-- Recommended zones
	if db.tooltips.location.recomZone then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LPS:L("Recommended Zones")..": ", rY, gY, bY)

		for zone in Tourist:IterateRecommendedZones() do
			GetRecomZones(zone);
		end
	end

	-- Instances in the zone
	if db.tooltips.location.zoneDungeon and Tourist:DoesZoneHaveInstances(zoneText) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(DUNGEONS.." "..LPS:L("in").." "..zoneText..": ", rY, gY, bY)

		for dungeon in Tourist:IterateZoneInstances(zoneText) do
			GetZoneDungeons(dungeon);
		end
	end

	-- Recommended Instances
	local level = UnitLevel('player')
	if db.tooltips.location.recomDungeon and Tourist:HasRecommendedInstances() and level >= 15 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LPS:L("Recommended Dungeons")..": ", rY, gY, bY)

		for dungeon in Tourist:IterateRecommendedInstances() do
			GetRecomDungeons(dungeon);
		end
	end

	if LPS.Retail then
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
