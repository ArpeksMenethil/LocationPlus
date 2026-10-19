local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "General" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.general()
	return {
			type = "group",
			name = LPS:L("GENERAL"),
			order = 1,
			args = {
				generalGroup = {
					order = 4,
					type = "group",
					name = LPS:L("GENERAL"),
					inline = true,
					args = {
						left = {
							order = 1,
							type = "group",
							name = " ",
							inline = true,
							
							args = {
								loginMessage = {
									order = 1,
									name = LPS:L("LOGIN_MESSAGE"),
									desc = LPS:L("SHOW_A_MESSAGE_IN_CHAT_ON_LOGIN"),
									type = "toggle",
									
									get = function() return OH:getDb().general.loginMessage end,
									set = function(_, v) OH:getDb().general.loginMessage = v end,
								},
								spacer1_is24H = {
									order = 2.1,
									type = "description",
									name = "",
								},
								is24H = {
									type = "toggle",
									name = LPS:L("_24H_TIME_FORMAT"),
									desc = LPS:L("USE_24_HOUR_TIME_FORMAT"),
									order = 3,
									
									get = function() return OH:getDb().general.is24H end,
									set = function(_, v)
									OH:getDb().general.is24H = v
									if LPS.ApplyTimeFormat then
									LPS:ApplyTimeFormat()
									end
									end,
								},
								seconds = {
									type = "toggle",
									name = LPS:L("SHOW_SECONDS"),
									desc = LPS:L("SHOW_SECONDS_WHEN_USING_LOCAL_TIME"),
									order = 4,
									
									get = function() return OH:getDb().general.seconds end,
									set = function(_, v)
									OH:getDb().general.seconds = v
									if LPS.ApplyTimeFormat then
									LPS:ApplyTimeFormat()
									end
									end,
								},
							},
						},
						right = {
							order = 2,
							type = "group",
							name = " ",
							inline = true,
							
							args = {
								minimapIcon = {
									type = "toggle",
									name = LPS:L("MINIMAP_ICON"),
									desc = LPS:L("SHOW_HIDE_MINIMAP_ICON"),
									order = 1,
									
									get = function()
									local mm = OH:getDb().show and OH:getDb().show.minimap
									return not (mm and mm.hide)
									end,
									set = function(_, v)
									OH:getDb().show.minimap = OH:getDb().show.minimap or { hide = false, angle = 220 }
									OH:getDb().show.minimap.hide = not v
									if v and LPS.CreateMinimapButton then
									LPS:CreateMinimapButton()
									end
									if LPS.UpdateMinimapButton then
									LPS:UpdateMinimapButton()
									end
									end,
								},
								addonCompartment = {
									type = "toggle",
									name = LPS:L("ADDON_COMPARTMENT"),
									desc = LPS:L("SHOW_HIDE_ADDON_IN_THE_ADDON_COMPARTMENT"),
									order = 2,
									
									hidden = function() return not (LPS.Retail or LPS.Forever) end,
									disabled = function() return not (LPS.Retail or LPS.Forever) end,
									get = function() return OH:getDb().show.addonCompartment end,
									set = function(_, v)
									OH:getDb().show.addonCompartment = v
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
									name = LPS:L("COMBAT_HIDE"),
									desc = LPS:L("SHOW_HIDE_ALL_PANELS_WHEN_IN_COMBAT"),
									type = "toggle",
									
									get = function() return OH:getDb().show.visibility.combat end,
									set = function(_, v)
									OH:getDb().show.visibility.combat = v
									if LPS.ApplyVisibility then
									LPS:ApplyVisibility()
									end
									end,
								},
							},
						},
					},
				},
				actionsGroup = {
					order = 99,
					type = "group",
					name = LPS:L("ACTIONS"),
					inline = true,
					args = {
						moveFrame = {
							type = "execute",
							name = LPS:L("MOVE_FRAME"),
							desc = LPS:L("TOGGLE_MOVE_MODE_FOR_THE_FRAME"),
							order = 1,
							func = function() LPS:ToggleMoveMode() end,
						},
						resetPosition = {
							type = "execute",
							name = LPS:L("RESET_HOLDER_POSITION"),
							desc = LPS:L("RESET_THE_HOLDER_FRAME_POSITION"),
							order = 2,
							func = function() LPS:ResetFramePosition() end,
						},
						resetValues = {
							type = "execute",
							name = LPS:L("RESET_VALUES"),
							desc = LPS:L("RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES"),
							order = 3,
							func = function()
							if LPS.ResetAllSettingsToDefaults then
							LPS:ResetAllSettingsToDefaults()
							end
							end,
						},
					},
				},
			}
}
end
