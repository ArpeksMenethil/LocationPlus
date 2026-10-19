local L = LPS.L
local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
LPS_DB = LPS_DB or {}

local Tourist = LPS.Tourist

-- Icons on Location Panel
local PET_ICON = LPS.icons.Pet
local LEVEL_ICON = LPS.icons.Level
local FISH_ICON = LPS.icons.Fish


-- Zone level range
---@param uiMapID number
---@return string playerMinLevel
---@return string playerMaxLevel
---@return string playerLevelColor
function LPS:GetLevelRange(uiMapID)
	if not uiMapID then return end

	local playerMinLevel, playerMaxLevel, playerLevelColor
	local zoneText, info
	local color = { r = 1, g = 1, b = 1 }

	if uiMapID and C_Map then
		if C_Map.GetMapInfo then
			info = C_Map.GetMapInfo(uiMapID)
			if info and info.name then
				zoneText = info.name
			end
		end

		if C_Map.GetMapLevels then
			playerMinLevel, playerMaxLevel = C_Map.GetMapLevels(uiMapID)
		end
	end

	if not Tourist and (playerMinLevel == 0 or playerMaxLevel == 0) then
		if LPS.Forever then
			local levelTable = LPS:GetLevelTable()

			if levelTable and levelTable[uiMapID] then
				local levelCell = levelTable[uiMapID]

				if levelCell then
					if levelCell.minLevel then
						playerMinLevel = levelCell.minLevel
					end
					if levelCell.maxLevel then
						playerMaxLevel = levelCell.maxLevel
					end
				end
			end
		end

		if playerMinLevel and playerMaxLevel and playerMinLevel > 0 and playerMaxLevel > 0 then
			local playerLevel = UnitLevel("player")

			if playerLevel < playerMinLevel then
				color = GetQuestDifficultyColor(playerMinLevel)
			elseif playerLevel > playerMaxLevel then
				color = GetQuestDifficultyColor(playerMaxLevel - 2)
			else
				color = QuestDifficultyColors["difficult"]
			end
		end
	end

	if Tourist and zoneText then
		playerMinLevel, playerMaxLevel = Tourist:GetLevel(zoneText)
		color.r, color.g, color.b = Tourist:GetLevelColor(zoneText)
	end
	
	playerLevelColor = LPS:ConvertRGBtoColorString(color)
	return playerMinLevel, playerMaxLevel, playerLevelColor
end

-- Fishing Level
function LPS:GetFishingLvl()
	if LPS.Retail then return end

	local uiMapID = C_Map.GetBestMapForUnit("player")
	local minFish, maxFish

	if Tourist then
		local zoneText = Tourist:GetMapNameByIDAlt(uiMapID) or UNKNOWN
		minFish, maxFish = Tourist:GetFishingLevel(zoneText)
	else
		local db = LPS:GetDB()
		local lvls = LPS.GetLevelTable and LPS:GetLevelTable() or (db and db.levelTable)
	local levelTable = lvls and uiMapID and lvls[uiMapID]

		if levelTable and levelTable.minFish then
			minFish = levelTable.minFish
		end
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
	local low, high = Tourist:GetBattlePetLevel(uniqueZone)
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
	if not Tourist then return end

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
	if not Tourist then return end

	local db = LPS:GetDB()
	local isPvP, isRaid


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
	if not Tourist then return end

	local low, high = Tourist:GetLevel(zone)
	local r, g, b = Tourist:GetLevelColor(zone)
	local zContinent = Tourist:GetContinent(zone)
	local pvpRaidTag = PvPorRaidFilter(zone)
	if pvpRaidTag == nil then return end
	local continentName = LPS:GetContinentName()

	GameTooltip:AddDoubleLine(
		zone..pvpRaidTag,
		format("|cff%02xff00%s|r", continentName == zContinent and 0 or 255, zContinent)
		..(" |cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))),
		1, 1, 1
	);

	return true
end

-- Dungeons in the zone
local function GetZoneDungeons(dungeon)
	if not Tourist then return end

	local low, high = Tourist:GetLevel(dungeon)
	local r, g, b = Tourist:GetLevelColor(dungeon)
	local groupSize = Tourist.GetInstanceGroupMinSize and Tourist:GetInstanceGroupMinSize(dungeon) or 0
	local groupSizeStyle = (groupSize > 0 and format("|cFFFFFF00|r (%d)", groupSize) or "")
	local name = dungeon

	local pvpRaidTag = PvPorRaidFilter(dungeon)
	if pvpRaidTag == nil then return end

	local levelText = (low == 0 and high == 0) and "" or ("|cff%02x%02x%02x%s|r"):format(
		r * 255, g * 255, b * 255, (low == high and low or ("%d-%d"):format(low, high))
	)

	GameTooltip:AddDoubleLine(
		name..groupSizeStyle.." "..GetDungeonCoords(dungeon)..pvpRaidTag,
		levelText,
		1, 1, 1
	)

	return true

end

-- Recommended Dungeons
local function GetRecomDungeons(dungeon)
	if not Tourist then return end

	local low, high = Tourist:GetLevel(dungeon);
	local r, g, b = Tourist:GetLevelColor(dungeon);
	local instZone = Tourist:GetInstanceZone(dungeon);
	local name = dungeon

	local pvpRaidTag = PvPorRaidFilter(dungeon)
	if pvpRaidTag == nil then return end

	if instZone == nil then
		instZone = ""
	else
		instZone = "|cFFFFA500 ("..instZone..")"
	end

	GameTooltip:AddDoubleLine(
		name..instZone..GetDungeonCoords(dungeon)..pvpRaidTag,
		("|cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))),
		1, 1, 1
	)

	return true
end


function LPS:BuildLocationTooltip()
	local db = LPS:GetDB()
	local mapID = C_Map.GetBestMapForUnit("player")
	local mapInfo = mapID and C_Map.GetMapInfo(mapID)
	local zoneText = (mapInfo and mapInfo.name) or UNKNOWN

	local r, g, b = LPS:GetColor("text")
	local rB, gB, bB = LPS:GetColor("tooltipSetting")
	local rY, gY, bY = LPS:GetColor("tooltip")

	GameTooltip:ClearLines()

	-- Zone
	GameTooltip:AddDoubleLine(L.ZONE..": ", zoneText, r, g, b)

	-- Continent
	GameTooltip:AddDoubleLine(L.CONTINENT..": ", LPS:GetContinentName(), r, g, b)

	-- Home
	GameTooltip:AddDoubleLine(L.HOME..": ", GetBindLocation(), r, g, b, 0.41, 0.8, 0.94)

	-- Status
	if db.tooltips.location.status then
		GameTooltip:AddDoubleLine(L.STATUS..": ", LPS:GetZoneStatus(), r, g, b)
	end

	-- Предварительно получаем данные для проверки необходимости пробела
	local levelMin, levelMax, levelColor
	local fishMin, fishMax
	local battlePetLevel

	if db.tooltips.location.level then
		levelMin, levelMax, levelColor = LPS:GetLevelRange(mapID)
	end

	if not LPS.Retail and db.tooltips.location.fish then
		fishMin, fishMax = LPS:GetFishingLvl()
	end

	if (LPS.Retail or LPS.Mists) and db.tooltips.location.battlePets then
		battlePetLevel = LPS:GetBattlePetLvl(zoneText)
	end

	-- Добавляем пробел, если будет дополнительная информация
	local willShowExtra = (levelMin or levelMax) or (fishMin or fishMax) or battlePetLevel
	if willShowExtra then
		GameTooltip:AddLine(" ")
	end

	-- Zone level range
	if db.tooltips.location.level and levelMin then
		local zoneLevel
				
		if levelMin ~= levelMax then
			zoneLevel = levelColor..levelMin.."-"..levelMax..FONT_COLOR_CODE_CLOSE
		else
			zoneLevel = levelColor..levelMax..FONT_COLOR_CODE_CLOSE
		end

		if zoneLevel then
			GameTooltip:AddDoubleLine(LEVEL_RANGE..": ", zoneLevel.." "..LEVEL_ICON, r, g, b)
		end
	end

	-- Fishing
	if not LPS.Retail and db.tooltips.location.fish then
		if fishMin and fishMax then
			GameTooltip:AddDoubleLine(PROFESSIONS_FISHING..": ", format("%s-%s %s", fishMin, fishMax, FISH_ICON), r, g, b)
		elseif fishMin then
			GameTooltip:AddDoubleLine(PROFESSIONS_FISHING..": ", format("%s %s", fishMin, FISH_ICON), r, g, b)
		end
	end

	-- Pet Levels
	if (LPS.Retail or LPS.Mists) and db.tooltips.location.battlePets and battlePetLevel then
		GameTooltip:AddDoubleLine(L.BATTLE_PET_LEVEL.. ": ", battlePetLevel.." "..PET_ICON, r, g, b)
	end

	-- Recommended zones
	if db.tooltips.location.recomZone and Tourist then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L.RECOMMENDED_ZONES..": ", rY, gY, bY)
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
	if db.tooltips.location.zoneDungeon and Tourist and Tourist.DoesZoneHaveInstances and Tourist:DoesZoneHaveInstances(zoneText) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(DUNGEONS.." "..L.IN.." "..zoneText..": ", rY, gY, bY)
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
	if db.tooltips.location.recomDungeon and Tourist and Tourist.HasRecommendedInstances and Tourist:HasRecommendedInstances() and level >= 15 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L.RECOMMENDED_DUNGEONS..": ", rY, gY, bY)
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
		if db.tooltips.location.profession and (prof1 or prof2 or archy or fishing or cooking) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(TRADE_SKILLS..":", rY, gY, bY)

			local proftable = { GetProfessions() }
			for _, id in ipairs(proftable) do
				if id then
					local name, icon, rank, maxRank, _, _, _, rankModifier = GetProfessionInfo(id)

					if rank < maxRank or not db.tooltips.location.professionHideMaxLevel then
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
		if db.tooltips.location.profession then
			local lines = {}

			-- Список профессий, которые нужно показывать
			local professions = {
				-- Primary Professions
				L.ALCHEMY, L.BLACKSMITHING, L.ENCHANTING, L.ENGINEERING, L.JEWELCRAFTING,
				L.HERBALISM, L.LEATHERWORKING, L.MINING, L.SKINNING, L.TAILORING,
				-- Secondary Professions
				L.COOKING, L.FIRST_AID, L.FISHING
			}

			local professionsSet = {}
			for _, name in ipairs(professions) do
				professionsSet[name] = true
			end

			for skillIndex = 1, GetNumSkillLines() do
				local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank =
					GetSkillLineInfo(skillIndex)

				if skillName and not isHeader and professionsSet[skillName] then
					if skillRank < skillMaxRank or not db.tooltips.location.professionHideMaxLevel then
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
	GameTooltip:AddDoubleLine(L.LMB, L.TOGGLE_WORLDMAP, rB, gB, bB, rB, gB, bB)
	GameTooltip:AddDoubleLine(L.RMB, L.TOGGLE_CONFIGURATION, rB, gB, bB, rB, gB, bB)
	GameTooltip:AddDoubleLine(L.SHIFT_LMB, L.SEND_THE_COORDINATES_TO_THE_CHAT, rB, gB, bB, rB, gB, bB)
end
