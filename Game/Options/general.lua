local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "General" дерева настроек (формат AceConfig-3.0).
function LPS.Options.BuildTree.tabs.general()
	return {
			type = "group",
			name = LPS:L("General"),
			order = 1,
			args = {
				generalGroup = {
					order = 4,
					type = "group",
					name = LPS:L("General"),
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
									name = LPS:L("Login message"),
									desc = LPS:L("Show a message in chat on login."),
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
									name = LPS:L("24H time format"),
									desc = LPS:L("Use 24-hour time format."),
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
									name = LPS:L("Show seconds"),
									desc = LPS:L("Show seconds when using local time."),
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
									name = LPS:L("Minimap icon"),
									desc = LPS:L("Show/Hide minimap icon."),
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
									name = LPS:L("Addon Compartment"),
									desc = LPS:L("Show/Hide addon in the Addon Compartment."),
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
									name = LPS:L("Combat Hide"),
									desc = LPS:L("Show/Hide all panels when in combat"),
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
					name = LPS:L("Actions"),
					inline = true,
					args = {
						moveFrame = {
							type = "execute",
							name = LPS:L("Move frame"),
							desc = LPS:L("Toggle move mode for the frame."),
							order = 1,
							func = function() LPS:ToggleMoveMode() end,
						},
						resetPosition = {
							type = "execute",
							name = LPS:L("Reset holder position"),
							desc = LPS:L("Reset the holder frame position."),
							order = 2,
							func = function() LPS:ResetFramePosition() end,
						},
						resetValues = {
							type = "execute",
							name = LPS:L("Reset values"),
							desc = LPS:L("Reset all addon settings to default values."),
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
