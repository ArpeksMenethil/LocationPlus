local addonName, LPS = ...

if C_AddOns and C_AddOns.GetAddOnMetadata then
	GetAddOnMetadata = C_AddOns.GetAddOnMetadata
end

_G.ArpeksLPS = _G.ArpeksLPS or {}
_G.ArpeksLPS.LPS = LPS or {}
LPS_DB = LPS_DB or {} -- SavedVariables


LPS.wow = LPS.wow or {}
LPS.wow.patch, LPS.wow.build, LPS.wow.date, LPS.wow.toc = GetBuildInfo()
LPS.wow.project = WOW_PROJECT_ID
do
	LPS.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
	LPS.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	LPS.Mists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
	LPS.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
	LPS.Forever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT
end
LPS.frame = LPS.frame or {}

LPS.addon = LPS.addon or {}
LPS.addon.textColor = LPS.addon.textColor or "ff1784d1"
LPS.addon.name = LPS.addon.name or addonName
LPS.addon.version = LPS.addon.version or "?.?.?"
LPS.addon.title = LPS.addon.title or ""

LPS.icons = LPS.icons or {}
LPS.icons.Pet = LPS.icons.Pet or "|TInterface\\AddOns\\"..LPS.addon.name.."\\Media\\Pet.png:16:16|t"
LPS.icons.Fish = LPS.icons.Fish or "|TInterface\\AddOns\\"..LPS.addon.name.."\\Media\\Fish.png:16:16|t"
LPS.icons.Level = LPS.icons.Level or "|TInterface\\AddOns\\"..LPS.addon.name.."\\Media\\Level.png:16:16|t"
LPS.icons.PathLogo = LPS.icons.PathLogo or "Interface\\AddOns\\"..LPS.addon.name.."\\Media\\Logo.png"
LPS.icons.PathLogoModern = LPS.icons.PathLogoModern or "Interface\\AddOns\\"..LPS.addon.name.."\\Media\\Logo-Modern.png"

LPS.DEBUG = false
if BNGetInfo then
    local battleTag = select(2, BNGetInfo())
    
    local function GetHash(str)
        local hash = 0
        for i = 1, #str do
            hash = (hash * 31 + string.byte(str, i)) % 4294967296
        end
        return hash
    end
    
    if type(battleTag) == "string" and GetHash(battleTag) == 237995138 then
        LPS.DEBUG = true
        print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: Debug mode enabled")
    end
end


LPS.levelTableConst = {

		-- Eastern Kingdoms
		--[[Alterac Mountains]]		[1416] = {minLevel = 30, 	maxLevel = 40,		minFish = "130",},
		--[[Arathi Highlands]]		[1417] = {minLevel = 30, 	maxLevel = 40,		minFish = "130",},
		--[[Badlands]]				[1418] = {minLevel = 35, 	maxLevel = 45,},
		--[[Blasted Lands]]			[1419] = {minLevel = 45, 	maxLevel = 55},
		--[[Burning Steppes]]		[1428] = {minLevel = 50, 	maxLevel = 58,		minFish = "330",},
		--[[Deadwind Pass]]			[1430] = {minLevel = 55, 	maxLevel = 60,		minFish = "330",},
		--[[Dun Morogh]]			[1426] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[Duskwood]]				[1431] = {minLevel = 18, 	maxLevel = 30,		minFish = "55",},
		--[[Eastern Plaguelands]]	[1423] = {minLevel = 53, 	maxLevel = 60,		minFish = "330",},
		--[[Elwynn Forest]]			[1429] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[Hillsbrad Foothills]]	[1424] = {minLevel = 20, 	maxLevel = 30,		minFish = "55",},
		--[[Ironforge]]				[1455] = {minFish = 1,},
		--[[Loch Modan]]			[1432] = {minLevel = 10,	maxLevel = 20,		minFish = "1",},
		--[[Redridge Mountains]]	[1433] = {minLevel = 15, 	maxLevel = 25,		minFish = "55",},
		--[[Searing Gorge]]			[1427] = {minLevel = 43, 	maxLevel = 50},
		--[[Silverpine Forest]]		[1421] = {minLevel = 10, 	maxLevel = 20,		minFish = "1",},
		--[[Stormwind City]]		[1453] = {minFish = 1,},
		--[[Stranglethorn Vale]]	[1434] = {minLevel = 30, 	maxLevel = 45,		minFish = "130 (205)",},
		--[[Swamp of Sorrows]]		[1435] = {minLevel = 35, 	maxLevel = 45,		minFish = "130",},
		--[[The Hinterlands]]		[1425] = {minLevel = 40, 	maxLevel = 50,		minFish = "205",},
		--[[Tirisfal Glades]]		[1420] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[Undercity]]				[1458] = {minFish = 1,},
		--[[Westfall]]				[1436] = {minLevel = 10, 	maxLevel = 20,		minFish = "1",},
		--[[Western Plaguelands]]	[1422] = {minLevel = 51, 	maxLevel = 58,		minFish = "205",},
		--[[Wetlands]]				[1437] = {minLevel = 20, 	maxLevel = 30,		minFish = "55",},

		-- Kalimdor
		--[[Ashenvale]]				[1440] = {minLevel = 18, 	maxLevel = 30,		minFish = "55",},
		--[[Azshara]]				[1447] = {minLevel = 45, 	maxLevel = 55,		minFish = "205 (330)",},
		--[[Darkshore]]				[1439] = {minLevel = 10,	maxLevel = 20,		minFish = "1",},
		--[[Darnassus]]				[1457] = {minFish = 1,},
		--[[Desolace]]				[1443] = {minLevel = 30, 	maxLevel = 40,		minFish = "130",},
		--[[Durotar]]				[1411] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[Dustwallow Marsh]]		[1445] = {minLevel = 35, 	maxLevel = 45,		minFish = "130",},
		--[[Felwood]]				[1448] = {minLevel = 48, 	maxLevel = 55,		minFish = "205",},
		--[[Feralas]]				[1444] = {minLevel = 40, 	maxLevel = 50,		minFish = "205 (330)",},
		--[[Moonglade]]				[1450] = {minFish = 205,},
		--[[Mulgore]]				[1412] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[Orgrimmar]]				[1454] = {minFish = 1,},
		--[[Silithus]]				[1451] = {minLevel = 55, 	maxLevel = 60,		minFish = "330",},
		--[[Stonetalon Mountains]]	[1442] = {minLevel = 15, 	maxLevel = 27,		minFish = "55",},
		--[[Tanaris]]				[1446] = {minLevel = 40, 	maxLevel = 50,		minFish = "205",},
		--[[Teldrassil]]			[1438] = {minLevel = 1, 	maxLevel = 10,		minFish = "1",},
		--[[The Barrens]]			[1413] = {minLevel = 10, 	maxLevel = 25,		minFish = "1",},
		--[[Thousand Needles]]		[1441] = {minLevel = 25, 	maxLevel = 35,		minFish = "130",},
		--[[Thunder Bluff]]			[1456] = {minFish = 1,},
		--[[Un'Goro Crater]]		[1449] = {minLevel = 48, 	maxLevel = 55,		minFish = "205",},
		--[[Winterspring]]			[1452] = {minLevel = 55, 	maxLevel = 60,		minFish = "330",},

		-- Forever
		--[[Hyjal]]					[2482] = {minLevel = 60, 	maxLevel = 60,},
		--[[Zephras Isle]]			[2521] = {minLevel = 1, 	maxLevel = 12,},
		--[[Riverglades]]			[2548] = {minLevel = 35, 	maxLevel = 45,},
		--[[Shen'dralas]]			[2652] = {minLevel = 35, 	maxLevel = 45,},

}

function LPS:GetLevelTable()
	return LPS.levelTableConst
end

LPS.defaults = {
	position = {
		point = "TOP",
		relativePoint = "TOP",
		x = 0,
		y = -10,
	},

	general = {
		loginMessage = true,
		coordsTimeUpdate = 0.5,
		seconds = true,
		is24H = true,
	},

	show = {
		zone = true,
		addonCompartment = false,
		showicon = true,
		gold = true,
		system = true,
		dig = true,
		displayOther = "RLEVEL",
		minimap = {
			hide = false,
			angle = 220,
		},

		visibility = {
			combat = false,
		},
	},

	tooltips = {
		visibility = {
			enable = true,
			combat = true,
		},

		location = {
			enable = true,
			status = true,
			level = true,
			battlePets = true,
			fish = true,
			recomZone = false,
			recomZoneMax = 5,
			zoneDungeon = false,
			zoneDungeonMax = 5,
			recomDungeon = false,
			recomDungeonMax = 5,
			recomDungeonCoords = false,
			profession = true,
			professionHideMaxLevel = false,

			hides = {
				pvp = false,
				raids = false,
			},
		},
		time = {
			enable = true,
			raids = true,
			dungeons = true,
			playedTime = true,
		},
		gold = {
			enable = true,
			session = true,
			characters = true,
			charactersMax = 20,
			serverTotals = true,
			warband = true,
			token = true,
			currency = true,
			resetHints = true,
		},
		system = {
			enable = true,
			network = true,
			addons = true,
			addonsMax = 15,
			total = true,
		},
		quests = {
			enable = true,
			maxLimit = 15,
		},
		friends = {
			enable = true,
			maxLimit = 15,
		},
		guild = {
			enable = true,
			maxLimit = 15,
		},
		experience = {
			enable = true,
			display = "PERCENT",
		},
		bags = {
			enable = true,
			display = "USED_TOTAL",
			noLabel = false,
			label = "",
		},
	},

	layout = {
		frameStrata = "LOW",
		frameLevel = 2,
		dtshow = true,
		dtMinWidth = 100,
		dtPaddingX = 20,
		dtPaddingY = 7,
		locMinWidth = 200,
		locPaddingX = 20,
		locPaddingY = 9,
		spacingAuto = true,
		spacingManual = 20,
		customColor = 3,
		userColor = { r = 1, g = 1, b = 1 },
		-- По умолчанию видны панели ПЕРВОЙ группы (slot1): слева — координаты,
		-- справа — время. Если пользователь ещё ничего не менял в настройках,
		-- именно эти фреймы отображаются сразу после установки аддона.
		slotCount = 3,
		sideSlots = {
			left1 = { frame = "coords", offsetX = 0, offsetY = 0 },
			left2 = { frame = "NONE", offsetX = 0, offsetY = 0 },
			left3 = { frame = "NONE", offsetX = 0, offsetY = 0 },
			right1 = { frame = "time", offsetX = 0, offsetY = 0 },
			right2 = { frame = "NONE", offsetX = 0, offsetY = 0 },
			right3 = { frame = "NONE", offsetX = 0, offsetY = 0 },
		}
	},

	panels = {
bags = { enable = true },,
		combatIndicator = { enable = true },
		combatTime = { enable = true },
		currencies = { enable = true },
		dps = { enable = true },
		hps = { enable = true },
		difficulty = { enable = true },
		durability = { enable = true },
experience = { enable = true },,
friends = { enable = true },,
guild = { enable = true },,
		itemLevel = { enable = true },
		mail = { enable = true },
		microBar = { enable = true },
quests = { enable = true },,
		reputation = { enable = true },
		volume = { enable = true },
		armor = { enable = true },
		attackPower = { enable = true },
		spellPower = { enable = true },
		healPower = { enable = true },
		crit = { enable = true },
		haste = { enable = true },
		mastery = { enable = true },
		strength = { enable = true },
		agility = { enable = true },
		stamina = { enable = true },
		intellect = { enable = true },
		spirit = { enable = true },
	},

	settings = {
		colors = {
			text            = {1, 1, 1, 1},
			bgEnable        = true,
			bg			    = {0, 0, 0, 0.6},
			border		    = {0.3, 0.3, 0.3, 1},
			tooltip		    = {1, 0.824, 0, 1},
			tooltipSetting  = {0.41, 0.8, 0.94, 1},
		},

		fontSize = 12,
		borderSize = 2,
	},

}