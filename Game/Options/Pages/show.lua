local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L


--- Возвращает вкладку "Show" дерева настроек (внутренний формат дерева настроек).
LPS.Options.BuildTree.tabs.show = function()
    return {
        name = L.DISPLAY,
        order = 2,
        args = {
            locationGroup = {
                order = 1,
                name = L.LOCATION,

                args = {
                    zone = {
                        order = 1,
                        type = "toggle",
                        name = L.SHOW_ZONE,
                        desc = L.SHOW_ZONE_NAME_ON_THE_PANEL,

                        get = function() return LPS:GetOptionDB().show.zone end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.zone = v
                            local f = LPS.frame and LPS.frame.location
                            if f and f._lpsUpdateFunc then
                                f._lpsUpdateFunc(f)
                            end
                        end,
                    },
                    spacer1_showicon = {
                        order = 1.1,
                        type = "description",
                        name = "",
                    },
                    showicon = {
                        order = 2,
                        name = L.CREST,
                        desc = L.SHOW_AN_ICON_NEXT_TO_THE_ADDITIONAL_INFO,
                        type = "toggle",

                        disabled = function() return LPS:GetOptionDB().show.displayOther == "NONE" end,
                        get = function() return LPS:GetOptionDB().show.showicon end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.showicon = v
                            local f = LPS.frame and LPS.frame.location
                            if f and f._lpsUpdateFunc then
                                f._lpsUpdateFunc(f)
                            end
                        end,
                    },
                    displayOther = {
                        order = 3,
                        name = L.OTHER,
                        desc = L.SHOW_ADDITIONAL_INFO_IN_THE_LOCATION_PANEL,
                        type = "select",

                        values = LPS:GetDisplayOtherValues(),
                        get = function() return LPS:GetOptionDB().show.displayOther end,
                        set = function(_, v)
                            local values = LPS:GetDisplayOtherValues()
                            if values[v] == nil then
                                v = "RLEVEL"
                            end
                            LPS:GetOptionDB().show.displayOther = v
                            local f = LPS.frame and LPS.frame.location
                            if f and f._lpsUpdateFunc then
                                f._lpsUpdateFunc(f)
                            end
                        end,
                    },
                },
            },
            coordsGroup = {
                order = 2,
                name = L.COORDS,

                args = {
                    dig = {
                        order = 1,
                        name = L.DETAILED_COORDS,
                        desc = L.ADDS_2_DIGITS_IN_THE_COORDS,
                        type = "toggle",

                        get = function() return LPS:GetOptionDB().show.dig end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.dig = v
                            local f = LPS.frame and LPS.frame.coords
                            if f and f._lpsUpdateFunc then
                                f._lpsUpdateFunc(f)
                            end
                        end,
                    },
                    coordsTimeUpdate = {
                        order = 2,
                        name = L.UPDATE_TIMER,
                        desc = L.ADJUST_COORDS_UPDATES_IN_SECONDS_TO_AVOID_CPU_LOAD,
                        type = "range",

                        min = 0.05,
                        max = 1,
                        step = 0.05,
                        get = function() return LPS:GetOptionDB().general.coordsTimeUpdate end,
                        set = function(_, v)
                            LPS:GetOptionDB().general.coordsTimeUpdate = v
                            if LPS.ApplyCoordsUpdateInterval then
                                LPS:ApplyCoordsUpdateInterval()
                            end
                        end,
                    },
                },
            },
            experienceGroup = {
                order = 3,
                name = L.EXPERIENCE,

                args = {
                    experience = {
                        order = 1,
                        type = "select",
                        name = L.VALUE_FORMAT,
                        desc = L.CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL,
                        values = {
                            PERCENT = L.PERCENT,
                            CURMAX = L.CURRENT_MAX,
                            CUR = L.CURRENT,
                            REM = L.REMAINING,
                        },
                        get = function() return LPS:GetOptionDB().show.experience.display or "PERCENT" end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.experience.display = v
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                },
            },
            bagsGroup = {
                order = 4,
                name = L.BAGS,

                args = {
                    bags = {
                        order = 1,
                        type = "select",
                        name = L.VALUE_FORMAT,
                        desc = L.CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL,
                        values = {
                            USED_TOTAL = L.USED_TOTAL,
                            FREE = L.FREE_SLOTS,
                            USED = L.USED_SLOTS,
                        },
                        get = function() return LPS:GetOptionDB().show.bags.display or "USED_TOTAL" end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.bags.display = v
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    spacer1_bags = {
                        order = 1.2,
                        type = "description",
                        name = "",
                    },
                    spacer2_bags = {
                        order = 1.3,
                        type = "description",
                        name = "",
                    },
                    bagsLabel = {
                        order = 2,
                        type = "input",
                        name = L.CUSTOM_LABEL,
                        desc = L.CUSTOM_LABEL_DESC,
                        disabled = function() return LPS:GetOptionDB().show.bags.noLabel end,
                        get = function() return LPS:GetOptionDB().show.bags.label or "" end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.bags.label = v or ""
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    bagsNoLabel = {
                        order = 3,
                        type = "toggle",
                        name = L.HIDE_LABEL,
                        desc = L.HIDE_LABEL_DESC,
                        get = function() return LPS:GetOptionDB().show.bags.noLabel or false end,
                        set = function(_, v)
                            LPS:GetOptionDB().show.bags.noLabel = v and true or false
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                },
            },
        }
    }
end
