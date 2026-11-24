local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L


--- Возвращает вкладку "General" дерева настроек (внутренний формат дерева настроек).
LPS.Options.BuildTree.tabs.general = function()
    return {
        name = L.GENERAL,
        order = 1,
        args = {
            generalGroup = {
                order = 4,
                name = L.GENERAL,
                args = {
                    left = {
                        order = 1,
                        name = " ",

                        args = {
                            loginMessage = {
                                order = 1,
                                name = L.LOGIN_MESSAGE,
                                desc = L.SHOW_A_MESSAGE_IN_CHAT_ON_LOGIN,
                                type = "toggle",

                                get = function() return LPS:GetOptionDB().general.loginMessage end,
                                set = function(_, v) LPS:GetOptionDB().general.loginMessage = v end,
                            },
                            spacer1_is24H = {
                                order = 2.1,
                                type = "description",
                                name = "",
                            },
                            is24H = {
                                type = "toggle",
                                name = L._24H_TIME_FORMAT,
                                desc = L.USE_24_HOUR_TIME_FORMAT,
                                order = 3,

                                get = function() return LPS:GetOptionDB().general.is24H end,
                                set = function(_, v)
                                    LPS:GetOptionDB().general.is24H = v
                                    if LPS.ApplyTimeFormat then
                                        LPS:ApplyTimeFormat()
                                    end
                                end,
                            },
                            seconds = {
                                type = "toggle",
                                name = L.SHOW_SECONDS,
                                desc = L.SHOW_SECONDS_WHEN_USING_LOCAL_TIME,
                                order = 4,

                                get = function() return LPS:GetOptionDB().general.seconds end,
                                set = function(_, v)
                                    LPS:GetOptionDB().general.seconds = v
                                    if LPS.ApplyTimeFormat then
                                        LPS:ApplyTimeFormat()
                                    end
                                end,
                            },
                        },
                    },
                    right = {
                        order = 2,
                        name = " ",

                        args = {
                            minimapIcon = {
                                type = "toggle",
                                name = L.MINIMAP_ICON,
                                desc = L.SHOW_HIDE_MINIMAP_ICON,
                                order = 1,

                                get = function()
                                    local mm = LPS:GetOptionDB().show and LPS:GetOptionDB().show.minimap
                                    return not (mm and mm.hide)
                                end,
                                set = function(_, v)
                                    LPS:GetOptionDB().show.minimap = LPS:GetOptionDB().show.minimap or { hide = false, angle = 220 }
                                    LPS:GetOptionDB().show.minimap.hide = not v
                                    if v and LPS.CreateMinimapButton then
                                        LPS:CreateMinimapButton()
                                    end
                                    if LPS.UpdateMinimapButton then
                                        LPS:UpdateMinimapButton()
                                    end
                                end,
                            },
                            minimapShape = {
                                type = "select",
                                name = L.MINIMAP_SHAPE,
                                desc = L.MINIMAP_SHAPE_DESC,
                                order = 1.5,

                                values = {
                                    ROUND = L.MINIMAP_SHAPE_ROUND,
                                    SQUARE = L.MINIMAP_SHAPE_SQUARE,
                                },
                                disabled = function()
                                    local mm = LPS:GetOptionDB().show and LPS:GetOptionDB().show.minimap
                                    return mm and mm.hide
                                end,
                                get = function()
                                    local mm = LPS:GetOptionDB().show and LPS:GetOptionDB().show.minimap
                                    if mm and mm.shape == "square" then return "SQUARE" end
                                    return "ROUND"
                                end,
                                set = function(_, v)
                                    LPS:GetOptionDB().show.minimap = LPS:GetOptionDB().show.minimap or { hide = false, angle = 220 }
                                    if v == "SQUARE" then
                                        LPS:GetOptionDB().show.minimap.shape = "square"
                                    else
                                        LPS:GetOptionDB().show.minimap.shape = "round"
                                    end
                                    if LPS.UpdateMinimapButton then
                                        LPS:UpdateMinimapButton()
                                    end
                                end,
                            },
                            addonCompartment = {
                                type = "toggle",
                                name = L.ADDON_COMPARTMENT,
                                desc = L.SHOW_HIDE_ADDON_IN_THE_ADDON_COMPARTMENT,
                                order = 2,

                                hidden = function() return not (LPS.Retail or LPS.Forever) end,
                                disabled = function() return not (LPS.Retail or LPS.Forever) end,
                                get = function() return LPS:GetOptionDB().show.addonCompartment end,
                                set = function(_, v)
                                    LPS:GetOptionDB().show.addonCompartment = v
                                    if LPS.ApplyAddonCompartmentRegistration then
                                        LPS:ApplyAddonCompartmentRegistration()
                                    end
                                end,
                            },
                            spacer1_combatHide = {
                                order = 2.1,
                                type = "description",
                                name = "",
                            },
                            combatHide = {
                                order = 4,
                                name = L.COMBAT_HIDE,
                                desc = L.SHOW_HIDE_ALL_PANELS_WHEN_IN_COMBAT,
                                type = "toggle",

                                get = function() return LPS:GetOptionDB().show.visibility.combat end,
                                set = function(_, v)
                                    LPS:GetOptionDB().show.visibility.combat = v
                                    if LPS.ApplyVisibility then
                                        LPS:ApplyVisibility()
                                    end
                                end,
                            },
                        },
                    },
                },
            },
            systemGroup = {
                order = 50,
                name = L.SYSTEM,
                args = {
                    checkForUpdates = {
                        type = "toggle",
                        name = L.CHECK_FOR_UPDATES,
                        desc = L.CHECK_FOR_UPDATES_DESC,
                        order = 1,

                        get = function()
                            local g = LPS:GetOptionDB().general
                            return g and g.checkForUpdates ~= false
                        end,
                        set = function(_, v)
                            LPS:GetOptionDB().general.checkForUpdates = v
                            if LPS.PanelApplyVersionColor then
                                LPS:PanelApplyVersionColor()
                            end
                        end,
                    },
                    debugMode = {
                        type = "toggle",
                        name = L.DEBUG_MODE,
                        desc = L.DEBUG_MODE_DESC,
                        order = 2,

                        hidden = function() return not LPS.IsDev end,
                        get = function() return LPS.DEBUG end,
                        set = function(_, v)
                            LPS.DEBUG = v
                            local a = LPS:GetAccountDB()
                            a.debugMode = v
                            LPS:Print(
                                "Debug mode " ..
                                    (v and (LPS:HexFromRGB(0.2, 1, 0.2) .. "enabled|r")
                                        or (LPS:HexFromRGB(1, 0.2, 0.2) .. "disabled|r")),
                                false)
                        end,
                    },
                },
            },
            actionsGroup = {
                order = 99,
                name = L.ACTIONS,
                sortKeys = { "btnOrder" },
                args = {
                    resetPosition = {
                        type = "execute",
                        name = L.RESET_POSITION,
                        desc = L.RESET_POSITION_DESC,
                        order = 1,
                        btnOrder = 1,
                        func = function()
                            if LPS.ResetFramePosition then
                                LPS:ResetFramePosition()
                            end
                        end,
                    },
                    resetValues = {
                        type = "execute",
                        name = L.RESET_VALUES,
                        desc = L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES,
                        order = 1,
                        btnOrder = 2,
                        func = function()
                            if LPS.ResetAllSettingsToDefaults then
                                LPS:ResetAllSettingsToDefaults()
                            end
                            if LPS.Options and LPS.Options.ApplyRefresh then
                                LPS:ApplyOptionsRefresh()
                            end
                        end,
                    },
                },
            },
        }
    }
end
