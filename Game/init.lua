local addonName, LPS = ...

_G.ArpeksLPS = _G.ArpeksLPS or {}
_G.ArpeksLPS.LPS = LPS or {}
_G.ArpeksLPS.L = setmetatable({}, {
	__index = function(t, key)
		if LPS.DEBUG then
			print("|c"..LPS.addonTextColor.."LocationPlus|r: Missing locale: |cFFE24444"..key.."|r")
		end
		return key
	end
})
LPS_DB = LPS_DB or {} -- SavedVariables


LPS.wowpatch, LPS.wowbuild, LPS.wowdate, LPS.wowtoc = GetBuildInfo()
do
	LPS.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	LPS.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end
LPS.frame = LPS.frame or {}
LPS.DEBUG = true

LPS.addonTextColor = "ff1784d1"
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
		seconds = true,
		is24H = true,
	},

	show = {
		zone = true,
		exactCoords = true,
		icon = true,
		selectIcon = nil,

		visibility = {
			combat = true,
			mouse = false,
			mouseOpacity = 0.5,
		},
	},

	tooltips = {
		visibility = {
			enable = true,
			combat = true,
			settings = true
		},

		location = {
			enable = true,
			status = true,
			level = true,
			battlePets = true,
			fish = true,
			recomZone = true,
			zoneDungeon = true,
			recomDungeon = true,
			recomDungeonCoords = true,
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

	settings = {
		colors = {
			text            = {1, 1, 1, 1},
			bg			        = {0, 0, 0, 0.6},
			border		      = {0.3, 0.3, 0.3, 1},
			tooltip		      = {1, 0.824, 0, 1},
			tooltipSetting  = {0.41, 0.8, 0.94, 1},
		},

		fontSize = 12,
		borderSize = 2,
	},
}
