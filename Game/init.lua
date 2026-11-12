local addonName, LPS = ...

LPS.GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata

_G.ArpeksLPS = _G.ArpeksLPS or {}
_G.ArpeksLPS.LPS = LPS or {}
LPS_DB = LPS_DB or {}

local F = _G.Foundry_1_0
if not F then
    error("LocationPlus requires the Foundry-1.0 library. Please install or enable it.", 0)
end
LPS.F = F

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

LPS.L = LPS.L or {}
LPS.GAME_LOCALE = GetLocale()
LPS.ACTIVE_LOCALE = LPS.GAME_LOCALE
LPS.RegisteredLocales = LPS.RegisteredLocales or {}

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

--- Уровни зон и уровни рыбалки:
---  - minLevel/maxLevel: диапазоны уровней зон;
---  - fishing: уровень рыбалки, с которого броски в зоне успешны (из OpenMap Fishing.lua;
---    для зон с отрицательным base там хранится base + 95, например Elwynn: -70 => 25)
LPS.levelTableConst = {

    -- Eastern Kingdoms
        --[[Dun Morogh]]			[1426] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Elwynn Forest]]			[1429] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Tirisfal Glades]]		[1420] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Loch Modan]]			[1432] = {minLevel = 10,	maxLevel = 20,		fishing = 75,},
        --[[Silverpine Forest]]		[1421] = {minLevel = 10, 	maxLevel = 20,		fishing = 75,},
        --[[Westfall]]				[1436] = {minLevel = 10, 	maxLevel = 20,		fishing = 75,},
        --[[Redridge Mountains]]	[1433] = {minLevel = 15, 	maxLevel = 25,		fishing = 55,},
        --[[Duskwood]]				[1431] = {minLevel = 18, 	maxLevel = 30,		fishing = 55,},
        --[[Hillsbrad Foothills]]	[1424] = {minLevel = 20, 	maxLevel = 30,		fishing = 55,},
        --[[Wetlands]]				[1437] = {minLevel = 20, 	maxLevel = 30,		fishing = 55,},
        --[[Alterac Mountains]]		[1416] = {minLevel = 30, 	maxLevel = 40,		fishing = 130,},
        --[[Arathi Highlands]]		[1417] = {minLevel = 30, 	maxLevel = 40,		fishing = 130,},
        --[[Stranglethorn Vale]]	[1434] = {minLevel = 30, 	maxLevel = 45,		fishing = 130,},
        --[[Badlands]]				[1418] = {minLevel = 35, 	maxLevel = 45,		fishing = 130,},
        --[[Swamp of Sorrows]]		[1435] = {minLevel = 35, 	maxLevel = 45,		fishing = 130,},
        --[[The Hinterlands]]		[1425] = {minLevel = 40, 	maxLevel = 50,		fishing = 205,},
        --[[Blasted Lands]]			[1419] = {minLevel = 45, 	maxLevel = 55,		fishing = 205,},
        --[[Searing Gorge]]			[1427] = {minLevel = 45, 	maxLevel = 50,		fishing = 205,},
        --[[Burning Steppes]]		[1428] = {minLevel = 50, 	maxLevel = 58,		fishing = 330,},
        --[[Western Plaguelands]]	[1422] = {minLevel = 51, 	maxLevel = 58,		fishing = 205,},
        --[[Eastern Plaguelands]]	[1423] = {minLevel = 53, 	maxLevel = 60,		fishing = 330,},
        --[[Deadwind Pass]]			[1430] = {minLevel = 55, 	maxLevel = 60,		fishing = 330,},

    -- Kalimdor
        --[[Durotar]]				[1411] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Mulgore]]				[1412] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Teldrassil]]			[1438] = {minLevel = 1, 	maxLevel = 10,		fishing = 25,},
        --[[Darkshore]]				[1439] = {minLevel = 10,	maxLevel = 20,		fishing = 75,},
        --[[The Barrens]]			[1413] = {minLevel = 10, 	maxLevel = 25,		fishing = 75,},
        --[[Stonetalon Mountains]]	[1442] = {minLevel = 15, 	maxLevel = 27,		fishing = 55,},
        --[[Ashenvale]]				[1440] = {minLevel = 18, 	maxLevel = 30,		fishing = 55,},
        --[[Thousand Needles]]		[1441] = {minLevel = 25, 	maxLevel = 35,		fishing = 130,},
        --[[Desolace]]				[1443] = {minLevel = 30, 	maxLevel = 40,		fishing = 130,},
        --[[Dustwallow Marsh]]		[1445] = {minLevel = 35, 	maxLevel = 45,		fishing = 130,},
        --[[Feralas]]				[1444] = {minLevel = 40, 	maxLevel = 50,		fishing = 205,},
        --[[Tanaris]]				[1446] = {minLevel = 40, 	maxLevel = 50,		fishing = 205,},
        --[[Azshara]]				[1447] = {minLevel = 45, 	maxLevel = 55,		fishing = 205,},
        --[[Felwood]]				[1448] = {minLevel = 48, 	maxLevel = 55,		fishing = 205,},
        --[[Un'Goro Crater]]		[1449] = {minLevel = 48, 	maxLevel = 55,		fishing = 205,},
        --[[Moonglade]]				[1450] = {minLevel = 55, 	maxLevel = 60,		fishing = 205,},
        --[[Silithus]]				[1451] = {minLevel = 55, 	maxLevel = 60,		fishing = 330,},
        --[[Winterspring]]			[1452] = {minLevel = 55, 	maxLevel = 60,		fishing = 330,},

    -- Forever
        --[[Zephras Isle]]			[2521] = {minLevel = 1, 	maxLevel = 12,		fishing = 25,},
        --[[Riverglades]]			[2548] = {minLevel = 35, 	maxLevel = 45,		fishing = 130,},
        --[[Shen'dralas]]			[2652] = {minLevel = 35, 	maxLevel = 45,		fishing = 130,},
        --[[Hyjal]]					[2482] = {minLevel = 60, 	maxLevel = 60,		fishing = 330,},

    -- Dungeons and Raids
        --[[Wailing Caverns]]		[718]  = {minLevel = 15, 	maxLevel = 25,		fishing = 50,},
        --[[Deadmines]]				[1581] = {minLevel = 17, 	maxLevel = 26,		fishing = 50,},
        --[[Blackfathom Deeps]]		[719]  = {minLevel = 20, 	maxLevel = 32,		fishing = 75,},
        --[[Scarlet Monastery]]		[796]  = {minLevel = 26, 	maxLevel = 45,		fishing = 75,},
        --[[Maraudon]]				[2100] = {minLevel = 30, 	maxLevel = 50,		fishing = 130,},
        --[[Sunken Temple]]			[1477] = {minLevel = 40, 	maxLevel = 50,		fishing = 175,},
        --[[Stratholme]]			[2017] = {minLevel = 46, 	maxLevel = 60,		fishing = 225,},
        --[[Zul'Gurub]]				[1977] = {minLevel = 50, 	maxLevel = 60,		fishing = 225,},
        --[[Naxxramas]]				[3456] = {minLevel = 60, 	maxLevel = 60,		fishing = 330,},

    -- Cities
        --[[Stormwind City]]		[1453] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},
        --[[Orgrimmar]]				[1454] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},
        --[[Ironforge]]				[1455] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},
        --[[Thunder Bluff]]			[1456] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},
        --[[Darnassus]]				[1457] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},
        --[[Undercity]]				[1458] = {minLevel = 60, 	maxLevel = 60,      fishing = 75,},

}

function LPS:GetLevelTable()
    return LPS.levelTableConst
end

LPS.defaults = {
    position = {
        -- NOTE: key is `relPoint` (Foundry.Window geometry). Do NOT use the
        -- legacy `relativePoint` key here: ApplyDefaults injects missing
        -- keys from these defaults into every profile, and a stray
        -- `relativePoint` entry would be migrated on top of the real
        -- `relPoint`, silently corrupting saved positions.
        point = "TOP",
        relPoint = "TOP",
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
            shape = "round",
        },

        visibility = {
            combat = false,
        },

        experience = {
            display = "PERCENT",
        },
        bags = {
            display = "USED_TOTAL",
            noLabel = false,
            label = "",
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
        },
        bags = {
            enable = true,
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
        slotCount = 3,
        sideSlots = {
            left1 = { frame = "gold", offsetX = -5, offsetY = 0 },
            left2 = { frame = "NONE", offsetX = 0, offsetY = 0 },
            left3 = { frame = "NONE", offsetX = 0, offsetY = 0 },
            right1 = { frame = "system", offsetX = 5, offsetY = 0 },
            right2 = { frame = "NONE", offsetX = 0, offsetY = 0 },
            right3 = { frame = "NONE", offsetX = 0, offsetY = 0 },
        }
    },

    settings = {
        colors = {
            text                = {1, 1, 1, 1},
            bgEnable            = true,
            bg                  = {0, 0, 0, 0.6},
            border              = {0.3, 0.3, 0.3, 1},
            tooltip             = {1, 0.824, 0, 1},
            tooltipSetting      = {0.41, 0.8, 0.94, 1},
        },

        fontSize = 12,
        borderSize = 2,
    },

}
