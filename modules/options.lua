local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------
-- OPTIONS
-------------------------------------------------
LPS.Options = {}

if LibStub and LibStub:GetLibrary("AceConfig-3.0", true) and LibStub:GetLibrary("AceConfigDialog-3.0", true) then
	local AceConfig = LibStub("AceConfig-3.0")
	local AceDialog = LibStub("AceConfigDialog-3.0")

	LPS.Options.aceAppName = "LocationPlus"

	local function getDb()
		return LPS:GetDB()
	end

	local function getDisplayOtherValues()
		local t = {
			["NONE"] = LPS:L("None"),
			["RLEVEL"] = LPS:L("Level range"),
		}
		if LPS.Retail then
			t["PET"] = LPS:L("Battle pets")
		else
			t["PFISH"] = LPS:L("Fishing")
		end
		return t
	end

	local strataValues = {
		["BACKGROUND"] = "BACKGROUND",
		["LOW"] = "LOW",
		["MEDIUM"] = "MEDIUM",
		["HIGH"] = "HIGH",
		["DIALOG"] = "DIALOG",
		["TOOLTIP"] = "TOOLTIP",
	}

	local fontFlagValues = {
		["NONE"] = LPS:L("None"),
		["OUTLINE"] = "OUTLINE",
		["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
		["THICKOUTLINE"] = "THICKOUTLINE",
	}

	local options = {
		type = "group",
		name = LPS:L("Location Plus"),
		childGroups = "tab",
		args = {
			general = {
				type = "group",
				name = LPS:L("General"),
				order = 1,
				args = {
					name = {
						order = 1,
						type = "header",
						name = LPS:L("Location Plus"),
					},
					desc = {
						order = 2,
						type = "description",
						name = LPS:L("Shows your location and coordinates on screen"),
					},
					spacer1 = {
						order = 3,
						type = "description",
						name = " ",
					},
					generalGroup = {
						order = 4,
						type = "group",
						name = LPS:L("General"),
						inline = true,
						args = {
							loginMessage = {
								order = 1,
								name = LPS:L("Login message"),
								desc = LPS:L("Show a message in chat on login."),
								type = "toggle",
								width = "full",
								get = function() return getDb().general.loginMessage end,
								set = function(_, v) getDb().general.loginMessage = v end,
							},
							is24H = {
								type = "toggle",
								name = LPS:L("24H time format"),
								desc = LPS:L("Use 24-hour time format."),
								order = 2,
								hidden = function() return not LPS.Retail end,
								get = function() return getDb().general.is24H end,
								set = function(_, v)
									getDb().general.is24H = v
									if LPS.ApplyTimeFormat then
										LPS:ApplyTimeFormat()
									end
								end,
							},
							seconds = {
								type = "toggle",
								name = LPS:L("Show seconds (local time)"),
								desc = LPS:L("Show seconds when using local time."),
								order = 3,
								hidden = function() return not LPS.Retail end,
								get = function() return getDb().general.seconds end,
								set = function(_, v)
									getDb().general.seconds = v
									if LPS.ApplyTimeFormat then
										LPS:ApplyTimeFormat()
									end
								end,
							},
							coordsTimeUpdate = {
								order = 4,
								name = LPS:L("Update Timer"),
								desc = LPS:L("Adjust coords updates (in seconds) to avoid cpu load."),
								type = "range",
								min = 0.05,
								max = 1,
								step = 0.05,
								get = function() return getDb().general.coordsTimeUpdate end,
								set = function(_, v)
									getDb().general.coordsTimeUpdate = v
									if LPS.ApplyCoordsUpdateInterval then
										LPS:ApplyCoordsUpdateInterval()
									end
								end,
							},
							hideBlizzardZoneText = {
								order = 5,
								name = LPS:L("Hide Blizzard Zone Text"),
								type = "toggle",
								get = function() return getDb().general.hideBlizzardZoneText end,
								set = function(_, v)
									getDb().general.hideBlizzardZoneText = v
									if LPS.ApplyHideBlizzardZoneText then
										LPS:ApplyHideBlizzardZoneText()
									end
								end,
							},
						},
					},
					actionsGroup = {
						order = 5,
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
				},
			},
			show = {
				type = "group",
				name = LPS:L("Show"),
				order = 2,
				args = {
					zone = {
						type = "toggle",
						name = LPS:L("Show zone"),
						desc = LPS:L("Show zone name on the panel."),
						order = 1,
						get = function() return getDb().show.zone end,
						set = function(_, v)
							getDb().show.zone = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
								f._lpsUpdateFunc(f)
							end
						end,
					},
					dig = {
						order = 2,
						name = LPS:L("Detailed Coords"),
						desc = LPS:L("Adds 2 digits in the coords"),
						type = "toggle",
						get = function() return getDb().show.dig end,
						set = function(_, v)
							getDb().show.dig = v
							local f = LPS.frame and LPS.frame.coords
							if f and f._lpsUpdateFunc then
								f._lpsUpdateFunc(f)
							end
						end,
					},
					displayOther = {
						order = 3,
						name = LPS:L("Other"),
						desc = LPS:L("Show additional info in the Location Panel"),
						type = "select",
						values = getDisplayOtherValues,
						get = function() return getDb().show.displayOther end,
						set = function(_, v)
							local values = getDisplayOtherValues()
							if values[v] == nil then
								v = "RLEVEL"
							end
							getDb().show.displayOther = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
								f._lpsUpdateFunc(f)
							end
						end,
					},
					showicon = {
						order = 4,
						name = LPS:L("Show icon"),
						type = "toggle",
						disabled = function() return getDb().show.displayOther == "NONE" end,
						get = function() return getDb().show.showicon end,
						set = function(_, v)
							getDb().show.showicon = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
								f._lpsUpdateFunc(f)
							end
						end,
					},
					spacer = {
						order = 5,
						type = "header",
						name = "",
					},
					visibilityGroup = {
						order = 20,
						name = LPS:L("Visibility"),
						type = "group",
						inline = true,
						args = {
							combat = {
								order = 1,
								name = LPS:L("Combat Hide"),
								desc = LPS:L("Show/Hide all panels when in combat"),
								type = "toggle",
								get = function() return getDb().show.visibility.combat end,
								set = function(_, v)
									getDb().show.visibility.combat = v
									if LPS.ApplyVisibility then
										LPS:ApplyVisibility()
									end
								end,
							},
						},
					},
					minimapIcon = {
						type = "toggle",
						name = LPS:L("Minimap icon"),
						desc = LPS:L("Show / hide minimap icon."),
						order = 40,
						get = function()
							local mm = getDb().show and getDb().show.minimap
							return not (mm and mm.hide)
						end,
						set = function(_, v)
							getDb().show.minimap = getDb().show.minimap or { hide = false, angle = 220 }
							getDb().show.minimap.hide = not v
							if v and LPS.CreateMinimapButton then
								LPS:CreateMinimapButton()
							end
							if LPS.UpdateMinimapButton then
								LPS:UpdateMinimapButton()
							end
						end,
					},
				},
			},
			tooltip = {
				type = "group",
				name = LPS:L("Tooltip"),
				order = 3,
				args = {
					tt_grp = {
						order = 1,
						type = "group",
						name = LPS:L("Tooltip"),
						inline = true,
						args = {
							tt = {
								order = 1,
								name = LPS:L("Show/Hide tooltip"),
								type = "toggle",
								get = function() return getDb().tooltips.visibility.enable end,
								set = function(_, v) getDb().tooltips.visibility.enable = v end,
							},
							ttcombathide = {
								order = 2,
								name = LPS:L("Combat Hide"),
								desc = LPS:L("Hide tooltip while in combat."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.visibility.combat end,
								set = function(_, v) getDb().tooltips.visibility.combat = v end,
							},
							tthint = {
								order = 3,
								name = LPS:L("Show Hints"),
								desc = LPS:L("Enable/Disable hints on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.visibility.hints end,
								set = function(_, v) getDb().tooltips.visibility.hints = v end,
							},
						},
					},
					tt_options = {
						order = 2,
						type = "group",
						name = LPS:L("Show"),
						inline = true,
						args = {
							ttst = {
								order = 1,
								name = LPS:L("Status"),
								desc = LPS:L("Enable/Disable status on Tooltip."),
								type = "toggle",
								width = "full",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.status end,
								set = function(_, v) getDb().tooltips.location.status = v end,
							},
							ttlvl = {
								order = 2,
								name = LPS:L("Level range"),
								desc = LPS:L("Enable/Disable level range on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.level end,
								set = function(_, v) getDb().tooltips.location.level = v end,
							},
							fish = {
								order = 3,
								name = LPS:L("Area Fishing level"),
								desc = LPS:L("Enable/Disable fishing level on the area."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								hidden = function() return LPS.Retail end,
								get = function() return getDb().tooltips.location.fish end,
								set = function(_, v) getDb().tooltips.location.fish = v end,
							},
							petlevel = {
								order = 4,
								name = LPS:L("Battle Pet level"),
								desc = LPS:L("Enable/Disable battle pet level on the area."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								hidden = function() return not LPS.Retail end,
								get = function() return getDb().tooltips.location.battlePets end,
								set = function(_, v) getDb().tooltips.location.battlePets = v end,
							},
							spacer2 = {
								order = 5,
								type = "description",
								width = "full",
								name = " ",
							},
							ttreczones = {
								order = 6,
								name = LPS:L("Recommended Zones"),
								desc = LPS:L("Enable/Disable recommended zones on Tooltip."),
								type = "toggle",
								width = "full",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.recomZone end,
								set = function(_, v) getDb().tooltips.location.recomZone = v end,
							},
							ttinst = {
								order = 7,
								name = LPS:L("Zone Dungeons"),
								desc = LPS:L("Enable/Disable dungeons in the zone, on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.zoneDungeon end,
								set = function(_, v) getDb().tooltips.location.zoneDungeon = v end,
							},
							ttrecinst = {
								order = 8,
								name = LPS:L("Recommended Dungeons"),
								desc = LPS:L("Enable/Disable recommended dungeons on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.recomDungeon end,
								set = function(_, v) getDb().tooltips.location.recomDungeon = v end,
							},
							ttcoords = {
								order = 9,
								name = LPS:L("with Entrance Coords"),
								desc = LPS:L("Enable/Disable the coords for area dungeons and recommended dungeon entrances, on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.recomDungeonCoords end,
								set = function(_, v) getDb().tooltips.location.recomDungeonCoords = v end,
							},
							spacer3 = {
								order = 10,
								type = "description",
								width = "full",
								name = " ",
							},
							curr = {
								order = 11,
								name = LPS:L("Currency"),
								desc = LPS:L("Enable/Disable the currencies, on Tooltip."),
								type = "toggle",
								width = "full",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								hidden = function() return not LPS.Retail end,
								get = function() return getDb().tooltips.location.currency end,
								set = function(_, v) getDb().tooltips.location.currency = v end,
							},
							prof = {
								order = 12,
								name = LPS:L("Professions"),
								desc = LPS:L("Enable/Disable the professions, on Tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.proffession end,
								set = function(_, v) getDb().tooltips.location.proffession = v end,
							},
							profcap = {
								order = 13,
								name = LPS:L("Hide capped"),
								desc = LPS:L("Hides a profession when the player reaches its highest level."),
								type = "toggle",
								disabled = function()
									return not getDb().tooltips.visibility.enable or not getDb().tooltips.location.proffession
								end,
								get = function() return getDb().tooltips.location.proffessionHideMaxLevel end,
								set = function(_, v) getDb().tooltips.location.proffessionHideMaxLevel = v end,
							},
						},
					},
					tt_filters = {
						order = 3,
						type = "group",
						name = LPS:L("Filters"),
						inline = true,
						args = {
							tthideraid = {
								order = 1,
								name = LPS:L("Hide Raid"),
								desc = LPS:L("Show/Hide raids on recommended dungeons."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.hides.raids end,
								set = function(_, v) getDb().tooltips.location.hides.raids = v end,
							},
							tthidepvp = {
								order = 2,
								name = LPS:L("Hide PvP"),
								desc = LPS:L("Show/Hide PvP zones, Arenas and BGs on recommended dungeons and zones."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.hides.pvp end,
								set = function(_, v) getDb().tooltips.location.hides.pvp = v end,
							},
						},
					},
					time = {
						order = 20,
						type = "group",
						name = LPS:L("Time tooltip"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Time tooltip"),
								desc = LPS:L("Enable tooltip on the time panel."),
								type = "toggle",
								get = function() return getDb().tooltips.time.enable end,
								set = function(_, v) getDb().tooltips.time.enable = v end,
							},
							raids = {
								order = 2,
								name = LPS:L("Cooldown raids"),
								desc = LPS:L("Show saved raids list."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.time.enable end,
								get = function() return getDb().tooltips.time.raids end,
								set = function(_, v) getDb().tooltips.time.raids = v end,
							},
							dungeons = {
								order = 3,
								name = LPS:L("Cooldown dungeons"),
								desc = LPS:L("Show saved dungeons list."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.time.enable end,
								get = function() return getDb().tooltips.time.dungeons end,
								set = function(_, v) getDb().tooltips.time.dungeons = v end,
							},
						},
					},
				},
			},
			layout = {
				type = "group",
				name = LPS:L("Layout"),
				order = 4,
				args = {
					locpanel = {
						order = 1,
						type = "group",
						name = LPS:L("Location Panel"),
						inline = true,
						args = {
							lpauto = {
								order = 5,
								type = "toggle",
								name = LPS:L("Auto width"),
								desc = LPS:L("Auto resized Location Panel."),
								get = function() return getDb().layout.lpauto end,
								set = function(_, v)
									getDb().layout.lpauto = v
									if v then
										getDb().layout.trunc = false
									end
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							lpwidth = {
								order = 6,
								type = "range",
								name = LPS:L("Width"),
								desc = LPS:L("Adjust the Location Panel Width."),
								min = 100,
								max = 300,
								step = 1,
								disabled = function() return getDb().layout.lpauto end,
								get = function() return getDb().layout.lpwidth end,
								set = function(_, v)
									getDb().layout.lpwidth = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							trunc = {
								order = 7,
								type = "toggle",
								name = LPS:L("Truncate text"),
								desc = LPS:L("Truncates the text rather than auto enlarge"),
								disabled = function() return getDb().layout.lpauto end,
								get = function() return getDb().layout.trunc end,
								set = function(_, v)
									getDb().layout.trunc = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
						},
					},
					panels = {
						order = 2,
						type = "group",
						name = LPS:L("DataTexts"),
						inline = true,
						args = {
							dtshow = {
								order = 0,
								name = LPS:L("Show panels"),
								desc = LPS:L("Show/Hide the extra panels (Coords and Time)."),
								type = "toggle",
								width = "full",
								get = function() return getDb().layout.dtshow end,
								set = function(_, v)
									getDb().layout.dtshow = v
									if LPS.ApplyDTVisibility then
										LPS:ApplyDTVisibility()
									end
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							hideCoords = {
								order = 0.2,
								name = LPS:L("Hide Coords"),
								desc = LPS:L("Show/Hide the coords panel."),
								type = "toggle",
								width = "full",
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().show.hideCoords end,
								set = function(_, v)
									getDb().show.hideCoords = v
									if v then
										getDb().show.hideCoordsInInstance = false
									end
									if LPS.ApplyCoordsVisibility then
										LPS:ApplyCoordsVisibility()
									end
									if LPS.UpdateFrameSize then
										LPS:UpdateFrameSize()
									end
								end,
							},
							hideTime = {
								order = 0.25,
								name = LPS:L("Hide Time"),
								desc = LPS:L("Show/Hide the time panel."),
								type = "toggle",
								width = "full",
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().show.hideTime end,
								set = function(_, v)
									getDb().show.hideTime = v
									if LPS.ApplyTimeVisibility then
										LPS:ApplyTimeVisibility()
									end
									if LPS.UpdateFrameSize then
										LPS:UpdateFrameSize()
									end
								end,
							},
							hideCoordsInInstance = {
								order = 0.3,
								name = LPS:L("Hide Coords in Instance"),
								desc = LPS:L("Show/Hide the coords panel in instances."),
								type = "toggle",
								width = "full",
								disabled = function() return getDb().layout.dtshow == false or getDb().show.hideCoords end,
								get = function() return getDb().show.hideCoordsInInstance end,
								set = function(_, v)
									getDb().show.hideCoordsInInstance = v
									if LPS.ApplyCoordsVisibility then
										LPS:ApplyCoordsVisibility()
									end
									if LPS.UpdateFrameSize then
										LPS:UpdateFrameSize()
									end
								end,
							},
							spacer_dt = {
								order = 0.5,
								type = "description",
								width = "full",
								name = " ",
							},
							dtwidth = {
								order = 1,
								type = "range",
								name = LPS:L("DataTexts Width"),
								desc = LPS:L("Adjust the DataTexts Width."),
								min = 70,
								max = 200,
								step = 1,
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().layout.dtwidth end,
								set = function(_, v)
									getDb().layout.dtwidth = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							dtheight = {
								order = 2,
								type = "range",
								name = LPS:L("All Panels Height"),
								desc = LPS:L("Adjust All Panels Height."),
								min = 10,
								max = 32,
								step = 1,
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().layout.dtheight end,
								set = function(_, v)
									getDb().layout.dtheight = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
						},
					},
					colors = {
						order = 4.5,
						type = "group",
						name = LPS:L("Colors"),
						inline = true,
						args = {
							customColor = {
								order = 1,
								name = LPS:L("Text color"),
								type = "select",
								values = {
									[1] = LPS:L("Custom"),
									[2] = LPS:L("Class Colors"),
									[3] = LPS:L("Default"),
								},
								get = function() return getDb().layout.customColor end,
								set = function(_, v)
									getDb().layout.customColor = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							userColor = {
								order = 2,
								name = LPS:L("Text custom color"),
								desc = LPS:L("Pick a custom color for panel text."),
								type = "color",
								disabled = function() return getDb().layout.customColor ~= 1 end,
								get = function()
									local c = getDb().layout.userColor
									return (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
								end,
								set = function(_, r, g, b)
									local c = getDb().layout.userColor
									if not c then
										c = { r = 1, g = 1, b = 1 }
										getDb().layout.userColor = c
									end
									c.r, c.g, c.b = r, g, b
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
						},
					},
					spacingGroup = {
						order = 5,
						type = "group",
						name = LPS:L("Spacing"),
						inline = true,
						args = {
							spacingAuto = {
								order = 1,
								type = "toggle",
								name = LPS:L("Auto"),
								get = function() return getDb().layout.spacingAuto end,
								set = function(_, v)
									getDb().layout.spacingAuto = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
							spacingManual = {
								order = 2,
								type = "range",
								name = LPS:L("Manual"),
								min = 0,
								max = 200,
								step = 1,
								disabled = function() return getDb().layout.spacingAuto end,
								get = function() return getDb().layout.spacingManual end,
								set = function(_, v)
									getDb().layout.spacingManual = v
									if LPS.ApplyLayout then
										LPS:ApplyLayout()
									end
								end,
							},
						},
					},
					style = {
						type = "group",
						name = LPS:L("Style"),
						order = 20,
						inline = true,
						args = {
							bgEnable = {
								type = "toggle",
								name = LPS:L("Enable background"),
								desc = LPS:L("Toggle background on the panel."),
								order = 1,
								get = function() return getDb().settings.colors.bgEnable end,
								set = function(_, v)
									getDb().settings.colors.bgEnable = v
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
							fontSize = {
								type = "range",
								name = LPS:L("Font size"),
								desc = LPS:L("Set font size."),
								order = 2,
								min = 8,
								max = 20,
								step = 1,
								get = function() return getDb().settings.fontSize end,
								set = function(_, v)
									getDb().settings.fontSize = v
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
							borderSize = {
								type = "range",
								name = LPS:L("Border size"),
								desc = LPS:L("Set border thickness."),
								order = 3,
								min = 1,
								max = 6,
								step = 1,
								get = function() return getDb().settings.borderSize end,
								set = function(_, v)
									getDb().settings.borderSize = v
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
							bgColor = {
								type = "color",
								name = LPS:L("Background color"),
								desc = LPS:L("Set background color."),
								order = 4,
								hasAlpha = true,
								get = function()
									local c = getDb().settings.colors.bg
									return c[1], c[2], c[3], c[4]
								end,
								set = function(_, r, g, b, a)
									local c = getDb().settings.colors.bg
									c[1], c[2], c[3], c[4] = r, g, b, a
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
							borderColor = {
								type = "color",
								name = LPS:L("Border color"),
								desc = LPS:L("Set border color."),
								order = 5,
								hasAlpha = true,
								get = function()
									local c = getDb().settings.colors.border
									return c[1], c[2], c[3], c[4]
								end,
								set = function(_, r, g, b, a)
									local c = getDb().settings.colors.border
									c[1], c[2], c[3], c[4] = r, g, b, a
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
						},
					},
				},
			},
		},
	}

	AceConfig:RegisterOptionsTable(LPS.Options.aceAppName, options)
	AceDialog:AddToBlizOptions(LPS.Options.aceAppName, LPS:L("Location Plus"))

	if LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db then
		local AceDBOptions = LibStub("AceDBOptions-3.0")
		AceConfig:RegisterOptionsTable(LPS.Options.aceAppName .. "_Profiles", AceDBOptions:GetOptionsTable(LPS.db))
		AceDialog:AddToBlizOptions(LPS.Options.aceAppName .. "_Profiles", LPS:L("Profiles"), LPS:L("Location Plus"))
	end

	return
end

-------------------------------------------------
-- UI HELPERS
-------------------------------------------------
function LPS:CreateCheck(parent, text, tooltip, get, set, x, y)
	local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", x, y)
	cb.Text:SetText(text)

	if tooltip then
		cb.tooltipText = tooltip
	end

	cb:SetChecked(get())

	cb:SetScript("OnClick", function(self)
		set(self:GetChecked())
	end)

	return cb
end

function LPS:CreateSlider(parent, text, minVal, maxVal, step, get, set, x, y)
	local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	s:SetPoint("TOPLEFT", x, y)
	s:SetMinMaxValues(minVal, maxVal)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)

	local valText = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	valText:SetPoint("TOP", s, "BOTTOM", 0, -2)

	local function update(val)
		val = tonumber(string.format(step < 1 and "%.1f" or "%d", val))
		valText:SetText(val)
		set(val)
	end

	s.Text:SetText(text)
	s.Low:SetText(minVal)
	s.High:SetText(maxVal)

	local startVal = get()
	s:SetValue(startVal)
	valText:SetText(startVal)

	s:SetScript("OnValueChanged", function(self, val)
		update(val)
	end)

	return s
end


-------------------------------------------------
-- MAIN PANEL
-------------------------------------------------
local panel = CreateFrame("Frame")
panel.name = LPS:L("Location Plus")
LPS.Options.panel = panel

-------------------------------------------------
-- SIMPLE TABS (SAFE FOR SETTINGS)
-------------------------------------------------
function LPS.Options:CreateTabs(parent)
	self.tabs = {}
	self.pages = {}

	local tabData = {
		{ key = "general",	text = LPS:L("General") },
		{ key = "show",		text = LPS:L("Show") },
		{ key = "tooltips",	text = LPS:L("Tooltips") },
		{ key = "style",	text = LPS:L("Style") },
	}

	local prev

	for i, info in ipairs(tabData) do
		local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		b:SetSize(100, 22)
		b:SetText(info.text)
		b.key = info.key

		if not prev then
			b:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -50)
		else
			b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
		end

		b:SetScript("OnClick", function(self)
			LPS.Options:SelectTab(self.key)
		end)

		self.tabs[info.key] = b
		prev = b

		local page = CreateFrame("Frame", nil, parent)
		page:SetPoint("TOPLEFT", 0, -80)
		page:SetPoint("BOTTOMRIGHT", 0, 0)
		page:Hide()

		self.pages[info.key] = page
	end

	self:SelectTab("general")
end

function LPS.Options:SelectTab(key)
	for k, btn in pairs(self.tabs) do
		if k == key then
			btn:Disable()
		else
			btn:Enable()
		end
	end

	for k, page in pairs(self.pages) do
		page:SetShown(k == key)
	end
end

-------------------------------------------------
-- RESET
-------------------------------------------------
function LPS.Options:CreateResetButton(parent)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(160, 22)
	b:SetPoint("BOTTOMLEFT", 16, 16)
	b:SetText(LPS:L("Reset values"))

	b:SetScript("OnClick", function()
		if LPS.ResetAllSettingsToDefaults then
			LPS:ResetAllSettingsToDefaults()
		end
	end)
end

function LPS.Options:CreateResetPositionButton(parent)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(160, 22)
	b:SetPoint("BOTTOMLEFT", 190, 16)
	b:SetText(LPS:L("Reset holder position"))

	b:SetScript("OnClick", function()
		if LPS.ResetFramePosition then
			LPS:ResetFramePosition()
		end
	end)
end

function LPS.Options:CreateToggleMoveButton(parent)
	local move = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	move:SetSize(140, 22)
	move:SetPoint("TOPRIGHT", -100, -32)
	move:SetText(LPS:L("Move frame"))

	move:SetScript("OnClick", function()
		LPS:ToggleMoveMode()
	end)

end

-------------------------------------------------
-- GENERAL TAB
-------------------------------------------------
function LPS:CreateGeneralOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Login message",
		nil,
		function() return LPS_DB.general.loginMessage end,
		function(v) LPS_DB.general.loginMessage = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"24H time format",
		nil,
		function() return LPS_DB.general.is24H end,
		function(v)
			LPS_DB.general.is24H = v
			if LPS.ApplyTimeFormat then
				LPS:ApplyTimeFormat()
			end
		end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Show seconds (local time)",
		nil,
		function() return LPS_DB.general.seconds end,
		function(v)
			LPS_DB.general.seconds = v
			if LPS.ApplyTimeFormat then
				LPS:ApplyTimeFormat()
			end
		end,
		16, y
	)

	y = y - 40

	self:CreateSlider(parent,
		"Coords update (sec)",
		0.1, 2, 0.1,
		function() return LPS_DB.general.coordsTimeUpdate end,
		function(v) LPS_DB.general.coordsTimeUpdate = v end,
		16, y
	)
end

-------------------------------------------------
-- SHOW TAB
-------------------------------------------------
function LPS:CreateShowOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Show zone",
		nil,
		function() return LPS_DB.show.zone end,
		function(v) LPS_DB.show.zone = v end,
		16, y
	)

end

-------------------------------------------------
-- TOOLTIPS TAB
-------------------------------------------------
function LPS:CreateTooltipOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Enable tooltips",
		nil,
		function() return LPS_DB.tooltips.visibility.enable end,
		function(v) LPS_DB.tooltips.visibility.enable = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Hide in combat",
		nil,
		function() return LPS_DB.tooltips.visibility.combat end,
		function(v) LPS_DB.tooltips.visibility.combat = v end,
		16, y
	)
end

-------------------------------------------------
-- STYLE TAB
-------------------------------------------------
function LPS:CreateStyleOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Enable background",
		nil,
		function() return LPS_DB.settings.colors.bgEnable end,
		function(v)
			LPS_DB.settings.colors.bgEnable = v
			if LPS.ApplyBackground then
				LPS:ApplyBackground()
			end
		end,
		16, y
	)

	y = y - 40

	self:CreateSlider(parent,
		"Font size",
		8, 20, 1,
		function() return LPS_DB.settings.fontSize end,
		function(v) LPS_DB.settings.fontSize = v end,
		16, y
	)

	y = y - 50

	self:CreateSlider(parent,
		"Border size",
		1, 6, 1,
		function() return LPS_DB.settings.borderSize end,
		function(v) LPS_DB.settings.borderSize = v end,
		16, y
	)
end

-------------------------------------------------
-- INIT
-------------------------------------------------
panel:SetScript("OnShow", function(self)
	if self.inited then return end
	self.inited = true

	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("|c"..LPS.addonTextColor..LPS.addonName.."|r")

	LPS.Options:CreateTabs(self)

	LPS:CreateGeneralOptions(LPS.Options.pages.general)
	LPS:CreateShowOptions(LPS.Options.pages.show)
	LPS:CreateTooltipOptions(LPS.Options.pages.tooltips)
	LPS:CreateStyleOptions(LPS.Options.pages.style)

	LPS.Options:CreateResetButton(self)
	LPS.Options:CreateResetPositionButton(self)
	LPS.Options:CreateToggleMoveButton(self)
end)

LPS.Options.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(LPS.Options.category)
