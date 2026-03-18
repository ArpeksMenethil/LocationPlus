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
	if battleTag == "Arpeks#21468" then
		LPS.DEBUG = true
		print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: Debug mode enabled")
	end
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
		hideBlizzardZoneText = true,
		seconds = false,
		is24H = true,
	},

	show = {
		zone = false,
		both = true,
		icon = true,
		selectIcon = nil,
		addonCompartment = true,
		showicon = true,
		hideCoords = false,
		hideTime = false,
		gold = false,
		system = false,
		hideCoordsInInstance = true,
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
			settings = true,
			hints = true,
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
			currency = true,
			proffession = true,
			proffessionHideMaxLevel = false,

			hides = {
				pvp = false,
				raids = false,
			},
		},
		time = {
			enable = true,
			raids = true,
			dungeons = true,
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
	},

	layout = {
		ht = true,
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
		sideSlots = {
			left = { frame = "coords", offsetX = 0, offsetY = 0 },
			right = { frame = "time", offsetX = 0, offsetY = 0 },
		},
		sideFrames = {
			coords = { attachTo = "location", side = "LEFT", offsetX = 0, offsetY = 0 },
			time = { attachTo = "location", side = "RIGHT", offsetX = 0, offsetY = 0 },
			gold = { attachTo = "time", side = "RIGHT", offsetX = 0, offsetY = 0 },
			system = { attachTo = "time", side = "RIGHT", offsetX = 0, offsetY = 0 },
		},
	},

	settings = {
		colors = {
			text            = {1, 1, 1, 1},
			bgEnable        = true,
			bg			        = {0, 0, 0, 0.6},
			border		      = {0.3, 0.3, 0.3, 1},
			tooltip		      = {1, 0.824, 0, 1},
			tooltipSetting  = {0.41, 0.8, 0.94, 1},
		},

		fontSize = 12,
		borderSize = 2,
	},
}
