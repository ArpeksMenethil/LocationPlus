local ADDON_NAME, LPS = ...

LPS.defaults = {
    position = {
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -10,
    },

    tooltips = {
        coords = {
            enable = true,
        },
        location = {
            enable = true,
            zoneLevel = true,
            battlePets = true,
        },
        time = {
            enable = true,
            raids = false,
            dungeons = false,
        },
    },

    colors = {
        text           = {1, 1, 1, 1},
        bg             = {0, 0, 0, 0.6},
        border         = {0.3, 0.3, 0.3, 1},
        tooltip        = {1, 0.824, 0, 1},
        tooltipSetting = {0.41, 0.8, 0.94, 1},
    },

    fontSize = 12,
}
