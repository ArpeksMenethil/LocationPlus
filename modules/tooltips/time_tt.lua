local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

LPS_DB = LPS_DB or {}

local OVERRIDE_ICON = [[Interface\EncounterJournal\UI-EJ-Dungeonbutton-%s]]

-- Таблица для перевода сложности в букву
local difficultyLetter = {
	[1] = "О",
	[2] = "Г",
	[3] = "О",
	[4] = "О",
	[5] = "Г",
	[6] = "Г",
	[7] = "П",
	[8] = "Э+",
	[9] = "О",
	[11] = "Г",
	[12] = "О",
	[14] = "О",
	[15] = "Г",
	[16] = "Э",
	[17] = "П",
	[23] = "Э",
	[24] = "В",
	[33] = "В",
	[38] = "О",
	[39] = "Г",
	[40] = "Э",
	[147] = "О",
	[149] = "Г",
	[150] = "О",
	[151] = "П",
}

local ICON_EJ = {
	[521746] = 'default',
	[522349] = 'baradinhold',
	[522350] = 'blackrockcaverns',
	[522351] = 'blackwingdescent',
	[522352] = 'deadmines',
	[522353] = 'firelands1',
	[522354] = 'grimbatol',
	[522355] = 'grimbatolraid',
	[522356] = 'hallsoforigination',
	[522357] = 'lostcityoftolvir',
	[522358] = 'shadowfangkeep',
	[522359] = 'skywallraid',
	[522360] = 'thestonecore',
	[522361] = 'thevortexpinnacle',
	[522362] = 'throneofthetides',
	[522363] = 'zulaman',
	[522364] = 'zulgurub',
	[571753] = 'dragonsoul',
	[571754] = 'endtime',
	[571755] = 'houroftwilight',
	[571756] = 'wellofeternity',
	[608192] = 'ahnkahettheoldkingdom',
	[608193] = 'auchindoun',
	[608194] = 'azjolnerub',
	[608195] = 'blackfathomdeeps',
	[608196] = 'blackrockdepths',
	[608197] = 'blackrockspire',
	[608198] = 'cavernsoftime',
	[608199] = 'coilfangreservoir',
	[608200] = 'diremaul',
	[608201] = 'draktharonkeep',
	[608202] = 'gnomeregan',
	[608203] = 'gundrak',
	[608204] = 'hallsoflightning',
	[608205] = 'hallsofreflection',
	[608206] = 'hallsofstone',
	[608207] = 'hellfirecitadel',
	[608208] = 'magistersterrace',
	[608209] = 'maraudon',
	[608210] = 'pitofsaron',
	[608211] = 'ragefirechasm',
	[608212] = 'razorfendowns',
	[608213] = 'razorfenkraul',
	[608214] = 'scarletmonastery',
	[608215] = 'scholomance',
	[608216] = 'stratholme',
	[608217] = 'sunkentemple',
	[608218] = 'tempestkeep',
	[608219] = 'thecullingofstratholme',
	[608220] = 'theforgeofsouls',
	[608221] = 'thenexus',
	[608222] = 'theoculus',
	[608223] = 'thestockade',
	[608224] = 'trialofthechampion',
	[608225] = 'uldaman',
	[608226] = 'utgardekeep',
	[608227] = 'utgardepinnacle',
	[608228] = 'violethold',
	[608229] = 'wailingcaverns',
	[608230] = 'zulfarrak',
	[632270] = 'gateofthesettingsun',
	[632271] = 'heartoffear',
	[632272] = 'mogushanpalace',
	[632273] = 'mogushanvaults',
	[632274] = 'shadowpanmonastery',
	[632275] = 'stormstoutbrewery',
	[632276] = 'templeofthejadeserpent',
	[643262] = 'scarlethalls',
	[643263] = 'siegeofnizaotemple',
	[643264] = 'terraceoftheendlessspring',
	[652218] = 'pandaria',
	[828453] = 'thunderkingraid',
	[904981] = 'siegeoforgrimmar',
	[1041992] = 'auchindounwod',
	[1041993] = 'blackrockfoundry',
	[1041994] = 'bloodmaulslagmines',
	[1041995] = 'draenor',
	[1041996] = 'grimraildepot',
	[1041997] = 'highmaul',
	[1041998] = 'shadowmoonburialgrounds',
	[1041999] = 'skyreach',
	[1042000] = 'upperblackrockspire',
	[1060547] = 'everbloom',
	[1060548] = 'irondocks',
	[1135118] = 'hellfireraid',
	[1396579] = 'blacktemple',
	[1396580] = 'blackwinglair',
	[1396581] = 'eyeofeternity',
	[1396582] = 'gruulslair',
	[1396583] = 'icecrowncitadel',
	[1396584] = 'karazhan',
	[1396585] = 'magtheridonslair',
	[1396586] = 'moltencore',
	[1396587] = 'naxxramas',
	[1396588] = 'obsidiansanctum',
	[1396589] = 'onyxia',
	[1396590] = 'rubysanctum',
	[1396591] = 'ruinsofahnqiraj',
	[1396592] = 'sunwellplateau',
	[1396593] = 'templeofahnqiraj',
	[1396594] = 'trialofthecrusader',
	[1396595] = 'ulduar',
	[1396596] = 'vaultofarchavon',
	[1411853] = 'blackrookhold',
	[1411854] = 'brokenisles',
	[1411855] = 'darkheartthicket',
	[1411856] = 'mawofsouls',
	[1411857] = 'thearcway',
	[1411858] = 'vaultofthewardens',
	[1450574] = 'neltharionslair',
	[1450575] = 'thenighthold',
	[1452687] = 'theemeraldnightmare',
	[1498155] = 'assaultonviolethold',
	[1498156] = 'courtofstars',
	[1498157] = 'eyeofazshara',
	[1498158] = 'hallsofvalor',
	[1537283] = 'returntokarazhan',
	[1537284] = 'trialofvalor',
	[1616106] = 'tombofsargeras',
	[1616922] = 'cathedralofeternalnight',
	[1718211] = 'antorus',
	[1718212] = 'argus',
	[1718213] = 'seatofthetriumvirate',
	[1778892] = 'ataldazar',
	[1778893] = 'freehold',
	[2178269] = 'kingsrest',
	[2178270] = 'kultiras',
	[2178271] = 'shrineofthestorm',
	[2178272] = 'siegeofboralus',
	[2178273] = 'templeofsethraliss',
	[2178274] = 'themotherlode',
	[2178275] = 'theunderrot',
	[2178276] = 'toldagor',
	[2178277] = 'uldir',
	[2178278] = 'waycrestmanor',
	[2178279] = 'zandalar',
	[2482729] = 'battleofdazaralor',
	[2498193] = 'crucibleofstorms',
	[3025320] = 'eternalpalace',
	[3025325] = 'mechagon',
	[3221463] = 'nyalotha',
	[3759906] = 'castlenathria',
	[3759907] = 'darkmaulcitadel',
	[3759908] = 'hallsofatonement',
	[3759909] = 'mistsoftirnascithe',
	[3759910] = 'necroticwake',
	[3759911] = 'plaguefall',
	[3759912] = 'sanguinedepths',
	[3759913] = 'spiresofascension',
	[3759914] = 'theaterofpain',
	[3759915] = 'theotherside',
	[3850569] = 'shadowlands',
	[4182020] = 'sanctumofdomination',
	[4182022] = 'tazaveshtheveiledmarket',
	[4423752] = 'sepulcherofthefirstones',
	[4742829] = 'arcanevaults',
	[4742923] = 'brackenhidehollow',
	[4742924] = 'centaurplains',
	[4742925] = 'dragonislescontinent',
	[4742926] = 'hallsofinfusion',
	[4742927] = 'lifepools',
	[4742928] = 'neltharius',
	[4742929] = 'theacademy',
	[4742930] = 'uldamanlegacyoftyr',
	[4742931] = 'vaultoftheincarnates',
	[5149418] = 'aberrus',
	[5221768] = 'dawnoftheinfinite',
	[5409261] = 'emeralddream',
	[5912546] = 'arakaracityofechoes',
	[5912547] = 'cinderbrewmeadery',
	[5912548] = 'cityofthreads',
	[5912549] = 'darkflamecleft',
	[5912550] = 'nerubarpalace',
	[5912551] = 'prioryofthesacredflames',
	[5912552] = 'thedawnbreaker',
	[5912553] = 'therookery',
	[5912554] = 'thestonevault',
	[5917063] = 'khazalgar',
	[6422411] = 'casino',
	[6422412] = 'waterworks',
	[7050019] = 'manaforge',
	[7074042] = 'ecodome'
}

local InstanceNameByID = {
	-- NOTE: for some reason the instanceID from EJ_GetInstanceByIndex doesn't match,
	-- the instanceID from GetInstanceInfo, so use the collectIDs to find the ID to add.
	[749] = C_Map.GetAreaInfo(3845) -- 'The Eye' -> 'Tempest Keep'
}

local difficultyColor = {
	["О"] = "|cFFFFFFFF",  -- белый (Normal)
	["Г"] = "|cFFFF7F00",  -- оранжевый (Heroic)
	["Э"] = "|cFFC000FF",  -- фиолетовый (Mythic)
	["Э+"] = "|cFF00FF00", -- зелёный (Mythic+)
	["П"] = "|cFF007FFF",  -- синий (LookingForRaid)
	["В"] = "|cFFFFFF00",  -- жёлтый (Timewalking / placeholder)
}

function LPS:FormatTime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	local parts = {}
	if days > 0 then
		table.insert(parts, string.format("%d "..LPS:L("day"), days))
	end
	if hours > 0 then
		table.insert(parts, string.format("%d "..LPS:L("hour"), hours))
	end
	if minutes > 0 then
		table.insert(parts, string.format("%d "..LPS:L("minute"), minutes))
	end

	-- Если всё равно 0 (секунды < 60), показываем "0 мин"
	if #parts == 0 then
		table.insert(parts, "0 "..LPS:L("minute"))
	end

	return table.concat(parts, " ")
end

local instanceIconByName = {}
function LPS:GetInstanceImages(index, raid)
	local instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, raid)
	while instanceID do
		local overrideImage = ICON_EJ[buttonImage]
		local overrideName = InstanceNameByID[instanceID] or name
		instanceIconByName[overrideName] = overrideImage and format(OVERRIDE_ICON, overrideImage) or buttonImage

		index = index + 1
		instanceID, name, _, _, buttonImage = EJ_GetInstanceByIndex(index, raid)
	end
end

local collectedImages = false
function LPS:CollectImages()
	local numTiers = (EJ_GetNumTiers() or 0)
	if numTiers > 0 then
		-- Loop through the expansions to collect the textures
		for i=1, numTiers do
			EJ_SelectTier(i)
			LPS:GetInstanceImages(1, false) -- Populate for dungeon icons
			LPS:GetInstanceImages(1, true) -- Populate for raid icons
		end

		-- Set it back to the previous tier
		local currentTier = EJ_GetCurrentTier()
		if currentTier then
			EJ_SelectTier(currentTier)
		end

		collectedImages = true
	end
end

function LPS:BuildTimeTooltip()
	local r, g, b = LPS:GetColor("text")
	local rB, gB, bB = LPS:GetColor("tooltipSetting")
	local rY, gY, bY = LPS:GetColor("tooltip")


	GameTooltip:ClearLines()

	if LPS.Retail then
		local raids = {}
		local dungeons = {}

		if not collectedImages then
				LPS:CollectImages()
		end

		for i = 1, GetNumSavedInstances() do
				local name, _, reset, difficulty, locked, _, _, isRaid, maxPlayers, _, numEncounters, encounterProgress, _ = GetSavedInstanceInfo(i)

				if locked then
						local diffChar = difficultyLetter[difficulty] or "?"
						local color = difficultyColor[diffChar] or "|cFFFFFFFF"

						local left = string.format(
								"|T%s:16:16|t%d %s%s|r |cFFAAAAAA(%s, %d/%d)|r",
								instanceIconByName[name],
								maxPlayers,
								color,
								diffChar,
								name,
								encounterProgress,
								numEncounters
						)

						local right = LPS:FormatTime(reset)
						local entry = {left = left, right = right}

						if isRaid then
								table.insert(raids, entry)
						else
								table.insert(dungeons, entry)
						end
				end
		end

		-- рейды
		if LPS_DB.tooltips.time.raids and #raids > 0 then
			GameTooltip:AddLine(LPS:L("Cooldown raids"), rY, gY, bY)
			for _, v in ipairs(raids) do
					GameTooltip:AddDoubleLine(v.left, v.right, r, g, b, rB, gB, bB)
			end
			GameTooltip:AddLine(" ")
		end

		if LPS_DB.tooltips.time.dungeons and #dungeons > 0 then
			GameTooltip:AddLine(LPS:L("Cooldown dungeons"), rY, gY, bY)
			for _, v in ipairs(dungeons) do
					GameTooltip:AddDoubleLine(v.left, v.right, r, g, b, rB, gB, bB)
			end
			GameTooltip:AddLine(" ")
		end
	end

	-- таймеры внизу
	local dailySeconds = C_DateAndTime.GetSecondsUntilDailyReset()
	GameTooltip:AddDoubleLine(LPS:L('Daily reset'), LPS:FormatTime(dailySeconds), r, g, b, r, g, b)

	local weeklySeconds = C_DateAndTime.GetSecondsUntilWeeklyReset()
	GameTooltip:AddDoubleLine(LPS:L("Weekly reset"), LPS:FormatTime(weeklySeconds), r, g, b, r, g, b)

	local calTime = C_DateAndTime.GetCurrentCalendarTime()
	GameTooltip:AddDoubleLine(LPS:L("Server time"), string.format("%02d:%02d", calTime.hour, calTime.minute), r, g, b, r, g, b)

	GameTooltip:AddDoubleLine(" ")
	GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Toggle time"), rB, gB, bB, rB, gB, bB)

	if not LPS.TBC then
		GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle calendar"), rB, gB, bB, rB, gB, bB)
	end

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
