local ADDON_NAME, LPS = ...

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
		hideBlizzardZoneText = true
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
