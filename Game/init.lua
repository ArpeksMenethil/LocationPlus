local addonName, LPS = ...

_G.ArpeksLPS = _G.ArpeksLPS or {}
_G.ArpeksLPS.LPS = LPS or {}
_G.ArpeksLPS.L = setmetatable({}, {
	__index = function(t, key)
		if LPS.DEBUG then
			local c = LPS.addonTextColor or "ffffffff"
			local n = LPS.addonName or addonName or "LocationPlus"
			print("|c"..c..n.."|r: Missing locale: |cFFE24444"..key.."|r")
		end
		return key
	end
})
LPS_DB = LPS_DB or {} -- SavedVariables


LPS.wowpatch, LPS.wowbuild, LPS.wowdate, LPS.wowtoc = GetBuildInfo()
do
	LPS.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
	LPS.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	LPS.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end
LPS.frame = LPS.frame or {}

LPS.DEBUG = false

LPS.addonTextColor = "ff1784d1"
LPS.addonName = addonName

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
	},

	layout = {
		ht = true,
		frameStrata = "LOW",
		frameLevel = 2,
		lpwidth = 200,
		dtshow = true,
		dtauto = true,
		dtwidth = 100,
		dtheight = 21,
		lpauto = true,
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
