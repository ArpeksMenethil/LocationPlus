local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------
-- OPTIONS
-------------------------------------------------
LPS.Options = {}

if LibStub and LibStub:GetLibrary("AceConfig-3.0", true) and LibStub:GetLibrary("AceConfigDialog-3.0", true) then
	local AceConfig = LibStub("AceConfig-3.0")
	local AceDialog = LibStub("AceConfigDialog-3.0")
	local AceConfigRegistry = LibStub:GetLibrary("AceConfigRegistry-3.0", true)
	local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
	local LibDeflate = LibStub:GetLibrary("LibDeflate", true)
	local PROFILE_EXPORT_PREFIX = "!LPS1!"
	local AceGUI = LibStub:GetLibrary("AceGUI-3.0", true)

	LPS.Options.aceAppName = "LocationPlus"

	if AceGUI and (AceGUI:GetWidgetVersion("LPSEditBoxNoButton") or 0) < 2 then
		local baseCtor = AceGUI.WidgetRegistry and AceGUI.WidgetRegistry["EditBox"]
		if baseCtor then
			AceGUI:RegisterWidgetType("LPSEditBoxNoButton", function()
				local widget = baseCtor()
				widget.type = "LPSEditBoxNoButton"
				local baseOnAcquire = widget.OnAcquire
				widget.OnAcquire = function(self)
					if baseOnAcquire then baseOnAcquire(self) end
					if self.DisableButton then
						self:DisableButton(true)
					end
				end
				if widget.editbox and widget.GetUserData then
					widget.editbox:HookScript("OnTextChanged", function(frame, userInput)
						if not userInput then return end
						local option = widget:GetUserData("option")
						if option and type(option.set) == "function" then
							option.set(nil, frame:GetText())
						end
					end)
				end
				return widget
			end, 2)
		end
	end

	if AceGUI and (AceGUI:GetWidgetVersion("LPSMultiLineEditBoxNoButton") or 0) < 2 then
		local baseCtor = AceGUI.WidgetRegistry and AceGUI.WidgetRegistry["MultiLineEditBox"]
		if baseCtor then
			AceGUI:RegisterWidgetType("LPSMultiLineEditBoxNoButton", function()
				local widget = baseCtor()
				widget.type = "LPSMultiLineEditBoxNoButton"
				local baseOnAcquire = widget.OnAcquire
				widget.OnAcquire = function(self)
					if baseOnAcquire then baseOnAcquire(self) end
					if self.DisableButton then
						self:DisableButton(true)
					end
				end
				if widget.editBox and widget.GetUserData then
					widget.editBox:HookScript("OnTextChanged", function(frame, userInput)
						if not userInput then return end
						local option = widget:GetUserData("option")
						if option and type(option.set) == "function" then
							option.set(nil, frame:GetText())
						end
					end)
				end
				return widget
			end, 2)
		end
	end

	local function getDb()
		return LPS:GetDB()
	end

	-- ==== Хелперы панелей и слотов (Panel Options / Side Panels) ====
	-- Каскад слотов: нет панели в слоте N — слоты N+1..3 неактивны.
	local function slotIsFilled(side, n)
		local ss = getDb().layout and getDb().layout.sideSlots
		local s = ss and ss[side .. n]
		if not s then return false end
		local v = s.frame
		return v ~= nil and v ~= "" and v ~= "NONE" and v ~= "None" and v ~= "none"
	end

	local function makeSlotDisabledFunc(side, n)
		return function()
			if n == 2 then
				return not slotIsFilled(side, 1)
			elseif n == 3 then
				return not slotIsFilled(side, 1) or not slotIsFilled(side, 2)
			end
			return false
		end
	end

	-- При выборе «none» в слоте N очищаем нижележащие слоты этой же стороны.
	local function cascadeClearSlots(ss, side, n)
		if not ss then return end
		for i = n + 1, 3 do
			local other = ss[side .. i]
			if type(other) == "table" then other.frame = "NONE" end
		end
	end

	-- Дополнительные настройки конкретных панелей для автогенерации Panel Options
	local PANEL_EXTRA = {
		bags = {
			display = {
				order = 3,
				name = LPS:L("Display"),
				values = {
					USED_TOTAL = LPS:L("Used / Total"),
					FREE = LPS:L("Free slots"),
					USED = LPS:L("Used slots"),
				},
			},
		},
		experience = {
			display = {
				order = 3,
				name = LPS:L("Display"),
				values = {
					PERCENT = LPS:L("Percent"),
					CURMAX = LPS:L("Current / Max"),
					CUR = LPS:L("Current"),
					REM = LPS:L("Remaining"),
				},
			},
		},
		friends = { maxLimit = true },
		guild = { maxLimit = true },
		quests = { maxLimit = true },
	}

	-- Фабрика группы настроек одной панели (tooltip + display/maxLimit/label)
	-- Включение/выключение панелей не является настройкой: панель активна,
	-- когда выбрана в слот (Side Panels), и скрыта, когда слот пуст.
	local function makePanelOptionGroup(key, def, order)
		local args = {}
		local extra = PANEL_EXTRA[key]
		if extra then
			if extra.display then
				args.display = {
					order = extra.display.order - 2,
					type = "select",
					name = extra.display.name,
					values = extra.display.values,
					get = function(info)
						local p = getDb().panels and getDb().panels[info[#info]]
						return (p and p.display) or next(extra.display.values)
					end,
					set = function(info, v)
						local k = info[#info]
						local db = getDb()
						db.panels = db.panels or {}
						local p = db.panels[k]
						if type(p) ~= "table" then
							p = {}
							db.panels[k] = p
						end
						p.display = v
						if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
					end,
				}
			end
			if extra.maxLimit then
				args.maxLimit = {
					order = 2,
					type = "range",
					name = LPS:L("Max entries in tooltip"),
					min = 1,
					max = 30,
					step = 1,
					get = function(info)
						local p = getDb().panels and getDb().panels[info[#info]]
						return (p and tonumber(p.maxLimit)) or 15
					end,
					set = function(info, v)
						local k = info[#info]
						local db = getDb()
						db.panels = db.panels or {}
						local p = db.panels[k]
						if type(p) ~= "table" then
							p = {}
							db.panels[k] = p
						end
						p.maxLimit = math.floor(v)
					end,
				}
			end
		end
		if key == "bags" then
			args.noLabel = {
				order = 5,
				type = "toggle",
				name = LPS:L("Hide label"),
				width = "half",
				get = function()
					local p = getDb().panels and getDb().panels.bags
					return p and p.noLabel or false
				end,
				set = function(_, v)
					local db = getDb()
					db.panels = db.panels or {}
					local p = db.panels.bags
					if type(p) ~= "table" then p = {}; db.panels.bags = p end
					p.noLabel = v and true or false
					if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
				end,
			}
			args.label = {
				order = 6,
				type = "input",
				name = LPS:L("Custom label"),
				width = "half",
				disabled = function()
					local p = getDb().panels and getDb().panels.bags
					return p and p.noLabel or false
				end,
				get = function()
					local p = getDb().panels and getDb().panels.bags
					return (p and p.label) or ""
				end,
				set = function(_, v)
					local db = getDb()
					db.panels = db.panels or {}
					local p = db.panels.bags
					if type(p) ~= "table" then p = {}; db.panels.bags = p end
					p.label = v or ""
					if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
				end,
			}
		end
		return {
			order = order,
			type = "group",
			inline = true,
			name = def.name,
			args = args,
		}
	end


	local function getDisplayOtherValues()
		local t = {
			["NONE"] = LPS:L("None"),
			["RLEVEL"] = LPS.icons.Level.." "..LPS:L("Level range"),
		}
		if not LPS.Retail and not LPS.Mists then
			t["PFISH"] = LPS.icons.Fish.." "..LPS:L("Fishing")
		end
		if LPS.Retail or LPS.Mists then
			t["PET"] = LPS.icons.Pet.." "..LPS:L("Battle pets")
		end
		return t
	end

	local deepCopy

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
		name = LPS.addon.title.." v"..LPS.addon.version,
		childGroups = "tab",
		args = {
			general = {
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
										
										get = function() return getDb().general.loginMessage end,
										set = function(_, v) getDb().general.loginMessage = v end,
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
										name = LPS:L("Show seconds"),
										desc = LPS:L("Show seconds when using local time."),
										order = 4,
										
										get = function() return getDb().general.seconds end,
										set = function(_, v)
											getDb().general.seconds = v
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
									addonCompartment = {
										type = "toggle",
										name = LPS:L("Addon Compartment"),
										desc = LPS:L("Show/Hide addon in the Addon Compartment."),
										order = 2,
										
										hidden = function() return not (LPS.Retail or LPS.Forever) end,
										disabled = function() return not (LPS.Retail or LPS.Forever) end,
										get = function() return getDb().show.addonCompartment end,
										set = function(_, v)
											getDb().show.addonCompartment = v
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
				},
				show = {
					type = "group",
					name = LPS:L("Show"),
					order = 2,
					args = {
						locationGroup = {
							order = 1,
							type = "group",
							name = LPS:L("Location"),
							inline = true,
							
							args = {
								zone = {
									order = 1,
									type = "toggle",
									name = LPS:L("Show zone"),
									desc = LPS:L("Show zone name on the panel."),
									
									get = function() return getDb().show.zone end,
									set = function(_, v)
										getDb().show.zone = v
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
									name = LPS:L("Crest"),
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
							},
						},
						coordsGroup = {
							order = 2,
							type = "group",
							name = LPS:L("Coords"),
							inline = true,
							
							args = {
								dig = {
									order = 1,
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
								coordsTimeUpdate = {
									order = 2,
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
							},
						},
					},
					panelDisplayGroup = {
						order = 3,
						type = "group",
						name = LPS:L("Panels"),
						inline = true,

						args = {
							experience = {
								order = 1,
								type = "select",
								name = LPS:L("Experience") .. " " .. LPS:L("Display"),
								values = {
									PERCENT = LPS:L("Percent"),
									CURMAX = LPS:L("Current / Max"),
									CUR = LPS:L("Current"),
									REM = LPS:L("Remaining"),
								},
								get = function() return getDb().show.experience.display or "PERCENT" end,
								set = function(_, v)
									getDb().show.experience.display = v
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							bags = {
								order = 2,
								type = "select",
								name = LPS:L("Bags") .. " " .. LPS:L("Display"),
								values = {
									USED_TOTAL = LPS:L("Used / Total"),
									FREE = LPS:L("Free slots"),
									USED = LPS:L("Used slots"),
								},
								get = function() return getDb().show.bags.display or "USED_TOTAL" end,
								set = function(_, v)
									getDb().show.bags.display = v
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							bagsNoLabel = {
								order = 3,
								type = "toggle",
								name = LPS:L("Hide label"),
								width = "half",
								get = function() return getDb().show.bags.noLabel or false end,
								set = function(_, v)
									getDb().show.bags.noLabel = v and true or false
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							bagsLabel = {
								order = 4,
								type = "input",
								name = LPS:L("Custom label"),
								width = "half",
								disabled = function() return getDb().show.bags.noLabel end,
								get = function() return getDb().show.bags.label or "" end,
								set = function(_, v)
									getDb().show.bags.label = v or ""
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
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
						name = LPS:L("Visibility"),
						inline = true,
						args = {
							tt = {
								order = 1,
								name = LPS:L("Show tooltip"),
								type = "toggle",
								get = function() return getDb().tooltips.visibility.enable end,
								set = function(_, v) getDb().tooltips.visibility.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							hide_in_combat = {
								order = 2,
								name = LPS:L("Hide in combat"),
								desc = LPS:L("Hide tooltips while in combat."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.visibility.combat end,
								set = function(_, v) getDb().tooltips.visibility.combat = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					tt_options = {
						order = 2,
						type = "group",
						name = LPS:L("Location"),
						inline = true,
						args = {
							ttst = {
								order = 1,
								name = LPS:L("Status"),
								desc = LPS:L("Enable/Disable status on Tooltip."),
								type = "toggle",
								
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.status end,
								set = function(_, v) getDb().tooltips.location.status = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							petlevel = {
								order = 1.1,
								name = LPS.icons.Pet.." "..LPS:L("Battle Pet level"),
								desc = LPS:L("Enable/Disable battle pet level on the area."),
								type = "toggle",
								
								disabled = function() return not getDb().tooltips.visibility.enable or not (LPS.Retail or LPS.Mists) end,
								hidden = function() return not (LPS.Retail or LPS.Mists) end,
								get = function() return getDb().tooltips.location.battlePets end,
								set = function(_, v) getDb().tooltips.location.battlePets = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							ttlvl = {
								order = 2,
								name = LPS.icons.Level.." "..LPS:L("Level range"),
								desc = LPS:L("Enable/Disable level range on Tooltip."),
								type = "toggle",
								
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.level end,
								set = function(_, v) getDb().tooltips.location.level = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							fish = {
								order = 2.1,
								name = LPS.icons.Fish.." "..LPS:L("Area Fishing level"),
								desc = LPS:L("Enable/Disable fishing level on the area."),
								type = "toggle",
								
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Retail or LPS.Mists end,
								hidden = function() return LPS.Retail or LPS.Mists end,
								get = function() return getDb().tooltips.location.fish end,
								set = function(_, v) getDb().tooltips.location.fish = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer2_prof = {
								order = 2.2,
								type = "description",
								name = "",
							},
							prof = {
								order = 3,
								name = LPS:L("Professions"),
								desc = LPS:L("Enable/Disable the professions, on Tooltip."),
								type = "toggle",
								
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.location.profession end,
								set = function(_, v) getDb().tooltips.location.profession = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							profcap = {
								order = 3.1,
								name = LPS:L("Hide capped"),
								desc = LPS:L("Hides a profession when the player reaches its highest level."),
								type = "toggle",
								
								disabled = function()
									return not getDb().tooltips.visibility.enable or not getDb().tooltips.location.profession
								end,
								get = function() return getDb().tooltips.location.professionHideMaxLevel end,
								set = function(_, v) getDb().tooltips.location.professionHideMaxLevel = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							filters = {
								order = 50,
								type = "group",
								name = LPS:L("Filters"),
								inline = true,
								hidden = function() return LPS.Forever end,
								args = {
									tthideraid = {
										order = 1,
										name = LPS:L("Hide Raid"),
										desc = LPS:L("Show/Hide raids on recommended dungeons."),
										type = "toggle",
										disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
										get = function() return getDb().tooltips.location.hides.raids end,
										set = function(_, v) getDb().tooltips.location.hides.raids = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
									},
									tthidepvp = {
										order = 2,
										name = LPS:L("Hide PvP"),
										desc = LPS:L("Show/Hide PvP zones, Arenas and BGs on recommended dungeons and zones."),
										type = "toggle",
										disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
										get = function() return getDb().tooltips.location.hides.pvp end,
										set = function(_, v) getDb().tooltips.location.hides.pvp = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
									},
								},
							},
							spacer1_ttreczones = {
								order = 4,
								type = "description",
								name = "",
							},
							ttreczones = {
								order = 6,
								name = LPS:L("Recommended Zones"),
								desc = LPS:L("Enable/Disable recommended zones on Tooltip."),
								type = "toggle",
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
								get = function() return getDb().tooltips.location.recomZone end,
								set = function(_, v) getDb().tooltips.location.recomZone = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							ttreczonesmax = {
								order = 6.1,
								name = LPS:L("Max entries"),
								desc = LPS:L("Limit how many entries are shown in this list."),
								type = "range",
								
								min = 3,
								max = 20,
								step = 1,
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not getDb().tooltips.location.recomZone end,
								get = function() return tonumber(getDb().tooltips.location.recomZoneMax) or 5 end,
								set = function(_, v) getDb().tooltips.location.recomZoneMax = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_ttinst = {
								order = 6.2,
								type = "description",
								name = "",
							},
							ttinst = {
								order = 7,
								name = LPS:L("Zone Dungeons"),
								desc = LPS:L("Enable/Disable dungeons in the zone, on Tooltip."),
								type = "toggle",
								
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
								get = function() return getDb().tooltips.location.zoneDungeon end,
								set = function(_, v) getDb().tooltips.location.zoneDungeon = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							ttinstmax = {
								order = 7.1,
								name = LPS:L("Max entries"),
								desc = LPS:L("Limit how many entries are shown in this list."),
								type = "range",
								
								min = 3,
								max = 20,
								step = 1,
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not getDb().tooltips.location.zoneDungeon end,
								get = function() return tonumber(getDb().tooltips.location.zoneDungeonMax) or 5 end,
								set = function(_, v) getDb().tooltips.location.zoneDungeonMax = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_ttrecinst = {
								order = 7.2,
								type = "description",
								name = "",
							},
							ttrecinst = {
								order = 8,
								name = LPS:L("Recommended Dungeons"),
								desc = LPS:L("Enable/Disable recommended dungeons on Tooltip."),
								type = "toggle",
								
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
								get = function() return getDb().tooltips.location.recomDungeon end,
								set = function(_, v) getDb().tooltips.location.recomDungeon = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							ttcoords = {
								order = 9,
								name = LPS:L("with Entrance Coords"),
								desc = LPS:L("Enable/Disable the coords for area dungeons and recommended dungeon entrances, on Tooltip."),
								type = "toggle",
								
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not (getDb().tooltips.location.recomDungeon or getDb().tooltips.location.zoneDungeon) end,
								get = function() return getDb().tooltips.location.recomDungeonCoords end,
								set = function(_, v) getDb().tooltips.location.recomDungeonCoords = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							ttrecinstmax = {
								order = 8.1,
								name = LPS:L("Max entries"),
								desc = LPS:L("Limit how many entries are shown in this list."),
								type = "range",
								
								min = 3,
								max = 20,
								step = 1,
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.location.recomDungeon end,
								get = function() return tonumber(getDb().tooltips.location.recomDungeonMax) or 5 end,
								set = function(_, v) getDb().tooltips.location.recomDungeonMax = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					gold = {
						order = 30,
						type = "group",
						name = LPS:L("Gold"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Enable tooltip on the gold panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.gold.enable end,
								set = function(_, v) getDb().tooltips.gold.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							session = {
								order = 2,
								name = LPS:L("Session"),
								desc = LPS:L("Show session information in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
								get = function() return getDb().tooltips.gold.session end,
								set = function(_, v) getDb().tooltips.gold.session = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_characters = {
								order = 2.1,
								type = "description",
								name = "",
							},
							characters = {
								order = 3,
								name = LPS:L("Characters"),
								desc = LPS:L("Show character gold list in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
								get = function() return getDb().tooltips.gold.characters end,
								set = function(_, v) getDb().tooltips.gold.characters = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							charactersMax = {
								order = 3.1,
								name = LPS:L("Max entries"),
								desc = LPS:L("Limit how many entries are shown in this list."),
								type = "range",
								min = 3,
								max = 40,
								step = 1,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or not getDb().tooltips.gold.characters end,
								get = function() return tonumber(getDb().tooltips.gold.charactersMax) or 20 end,
								set = function(_, v) getDb().tooltips.gold.charactersMax = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_serverTotals = {
								order = 3.2,
								type = "description",
								name = "",
							},
							serverTotals = {
								order = 4,
								name = LPS:L("On server"),
								desc = LPS:L("Show faction/server totals in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
								get = function() return getDb().tooltips.gold.serverTotals end,
								set = function(_, v) getDb().tooltips.gold.serverTotals = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							warband = {
								order = 5,
								name = LPS:L("Warband"),
								desc = LPS:L("Show Warband money in the tooltip (Retail)."),
								type = "toggle",
								hidden = function() return not LPS.Retail end,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or LPS.Forever end,
								get = function() return getDb().tooltips.gold.warband end,
								set = function(_, v) getDb().tooltips.gold.warband = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							token = {
								order = 6,
								name = LPS:L("WoW Token"),
								desc = LPS:L("Show WoW Token price in the tooltip (Retail)."),
								type = "toggle",
								hidden = function() return not LPS.Retail end,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or LPS.Forever end,
								get = function() return getDb().tooltips.gold.token end,
								set = function(_, v) getDb().tooltips.gold.token = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							currency = {
								order = 7,
								name = LPS:L("Currency"),
								desc = LPS:L("Enable/Disable the currencies, on Tooltip."),
								type = "toggle",
								
								hidden = function() return not LPS.Retail end,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or not LPS.Retail end,
								get = function() return getDb().tooltips.gold.currency end,
								set = function(_, v) getDb().tooltips.gold.currency = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							resetHints = {
								order = 8,
								name = LPS:L("Show Hints"),
								desc = LPS:L("Show reset keybind hints at the bottom of the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
								get = function() return getDb().tooltips.gold.resetHints end,
								set = function(_, v) getDb().tooltips.gold.resetHints = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					system = {
						order = 40,
						type = "group",
						name = LPS:L("System"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Enable tooltip on the system panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.system.enable end,
								set = function(_, v) getDb().tooltips.system.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							network = {
								order = 2,
								name = LPS:L("Bandwidth"),
								desc = LPS:L("Show FPS and network information in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
								get = function() return getDb().tooltips.system.network end,
								set = function(_, v) getDb().tooltips.system.network = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_addons = {
								order = 2.2,
								type = "description",
								name = "",
							},
							addons = {
								order = 3,
								name = LPS:L("AddOns"),
								desc = LPS:L("Show addon memory usage list in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
								get = function() return getDb().tooltips.system.addons end,
								set = function(_, v) getDb().tooltips.system.addons = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							addonsMax = {
								order = 3.1,
								name = LPS:L("Max entries"),
								desc = LPS:L("Limit how many entries are shown in this list."),
								type = "range",
								min = 3,
								max = 40,
								step = 1,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable or not getDb().tooltips.system.addons end,
								get = function() return tonumber(getDb().tooltips.system.addonsMax) or 15 end,
								set = function(_, v) getDb().tooltips.system.addonsMax = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							spacer1_total = {
								order = 3.2,
								type = "description",
								name = "",
							},
							total = {
								order = 4,
								name = LPS:L("Total"),
								desc = LPS:L("Show total addon memory usage line in the tooltip."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
								get = function() return getDb().tooltips.system.total end,
								set = function(_, v) getDb().tooltips.system.total = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					time = {
						order = 20,
						type = "group",
						name = LPS:L("Time"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Enable tooltip on the time panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.time.enable end,
								set = function(_, v) getDb().tooltips.time.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							raids = {
								order = 2,
								name = LPS:L("Cooldown raids"),
								desc = LPS:L("Show saved raids list."),
								type = "toggle",
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable or LPS.Forever end,
								get = function() return getDb().tooltips.time.raids end,
								set = function(_, v) getDb().tooltips.time.raids = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							dungeons = {
								order = 3,
								name = LPS:L("Cooldown dungeons"),
								desc = LPS:L("Show saved dungeons list."),
								type = "toggle",
								hidden = function() return LPS.Forever end,
								disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable or LPS.Forever end,
								get = function() return getDb().tooltips.time.dungeons end,
								set = function(_, v) getDb().tooltips.time.dungeons = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							playedTime = {
								order = 4,
								name = LPS:L("Played Time"),
								desc = LPS:L("Show played time across all your characters (Required 'Broker: Played Time')"),
								type = "toggle",
								disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.time.playedTime end,
								set = function(_, v) getDb().tooltips.time.playedTime = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							}
						},
					},
					quests = {
						order = 50,
						type = "group",
						name = LPS:L("Quest Log"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Show a tooltip when hovering over this panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.quests.enable end,
								set = function(_, v) getDb().tooltips.quests.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							maxLimit = {
								order = 2,
								type = "range",
								name = LPS:L("Max entries in tooltip"),
								min = 1,
								max = 30,
								step = 1,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.quests.enable end,
								get = function() return tonumber(getDb().tooltips.quests.maxLimit) or 15 end,
								set = function(_, v) getDb().tooltips.quests.maxLimit = math.floor(v) if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					friends = {
						order = 51,
						type = "group",
						name = LPS:L("Friends"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Show a tooltip when hovering over this panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.friends.enable end,
								set = function(_, v) getDb().tooltips.friends.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							maxLimit = {
								order = 2,
								type = "range",
								name = LPS:L("Max entries in tooltip"),
								min = 1,
								max = 30,
								step = 1,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.friends.enable end,
								get = function() return tonumber(getDb().tooltips.friends.maxLimit) or 15 end,
								set = function(_, v) getDb().tooltips.friends.maxLimit = math.floor(v) if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
					guild = {
						order = 52,
						type = "group",
						name = LPS:L("Guild"),
						inline = true,
						args = {
							enable = {
								order = 1,
								name = LPS:L("Enable"),
								desc = LPS:L("Show a tooltip when hovering over this panel."),
								type = "toggle",
								disabled = function() return not getDb().tooltips.visibility.enable end,
								get = function() return getDb().tooltips.guild.enable end,
								set = function(_, v) getDb().tooltips.guild.enable = v if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
							maxLimit = {
								order = 2,
								type = "range",
								name = LPS:L("Max entries in tooltip"),
								min = 1,
								max = 30,
								step = 1,
								disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.guild.enable end,
								get = function() return tonumber(getDb().tooltips.guild.maxLimit) or 15 end,
								set = function(_, v) getDb().tooltips.guild.maxLimit = math.floor(v) if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end end,
							},
						},
					},
			layout = {
				type = "group",
				name = LPS:L("Layout"),
				order = 4,
				args = {
					chainAnchor = {
						order = 3,
						type = "select",
						name = LPS:L("Frame anchor mode"),
						desc = LPS:L("Side panels always grow along their edge: left panels attach to the LEFT side of the group, right panels attach to the RIGHT side. This option controls what the FIRST panel of each chain anchors to: the location panel edges (default) or the outer edges of the whole holder frame."),
						values = {
							chain = LPS:L("Location panel edges"),
							location = LPS:L("Holder outer edges"),
						},
						get = function() return getDb().layout.chainAnchor or "chain" end,
						set = function(_, v)
							getDb().layout.chainAnchor = v
							if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
							if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
						end,
					},
					locpanel = {
						order = 4,
						type = "group",
						name = LPS:L("Location Panel"),
						inline = true,
						args = {
							locMinWidth = {
								order = 0,
								type = "range",
								name = LPS:L("Minimum width"),
								desc = LPS:L("Sets the minimum width of the location panel."),
								min = 200,
								max = 300,
								step = 1,
								get = function() return getDb().layout.locMinWidth end,
								set = function(_, v)
									getDb().layout.locMinWidth = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							locPaddingX = {
								order = 1,
								type = "range",
								name = LPS:L("Text padding X"),
								desc = LPS:L("Adjust horizontal text padding inside location panel."),
								min = 20,
								max = 30,
								step = 1,
								get = function() return getDb().layout.locPaddingX end,
								set = function(_, v)
									getDb().layout.locPaddingX = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							locPaddingY = {
								order = 2,
								type = "range",
								name = LPS:L("Text padding Y"),
								desc = LPS:L("Adjust vertical text padding inside location panel."),
								min = 7,
								max = 20,
								step = 1,
								get = function() return getDb().layout.locPaddingY end,
								set = function(_, v)
									getDb().layout.locPaddingY = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
						},
					},
					panels = {
						order = 5,
						type = "group",
						name = LPS:L("Panels"),
						inline = true,
						args = {
							dtshow = {
								order = 0.3,
								name = LPS:L("Show panels"),
								desc = LPS:L("Show/Hide the extra panels (Coords and Time)."),
								type = "toggle",
								
								get = function() return getDb().layout.dtshow end,
								set = function(_, v)
									getDb().layout.dtshow = v
									if LPS.ApplyDTVisibility then
										LPS:ApplyDTVisibility()
									end
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							
							spacer1_dtMinWidth = {
								order = 0.6,
								type = "description",
								name = "",
							},
							spacer2_dtMinWidth = {
								order = 0.7,
								type = "description",
								name = "",
							},
							dtMinWidth = {
								order = 1,
								type = "range",
								name = LPS:L("Minimum width"),
								desc = LPS:L("Sets the minimum width of the extra panels."),
								min = 100,
								max = 200,
								step = 1,
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().layout.dtMinWidth end,
								set = function(_, v)
									getDb().layout.dtMinWidth = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							dtPaddingX = {
								order = 2,
								type = "range",
								name = LPS:L("Text padding X"),
								desc = LPS:L("Adjust horizontal text padding inside panels."),
								min = 20,
								max = 30,
								step = 1,
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().layout.dtPaddingX end,
								set = function(_, v)
									getDb().layout.dtPaddingX = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							dtPaddingY = {
								order = 3,
								type = "range",
								name = LPS:L("Text padding Y"),
								desc = LPS:L("Adjust vertical text padding inside panels."),
								min = 7,
								max = 20,
								step = 1,
								disabled = function() return getDb().layout.dtshow == false end,
								get = function() return getDb().layout.dtPaddingY end,
								set = function(_, v)
									getDb().layout.dtPaddingY = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
						},
					},
					panelsGroup = {
						order = 6,
						type = "group",
						name = LPS:L("Side Panels"),
						inline = true,
						args = {
							leftSlot1 = {
								order = 1.1,
								name = LPS:L("Left Slot 1"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left1"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.left1 = ss.left1 or { offsetX = 0, offsetY = 0 }
									local cur = ss.left1
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if v == "none" then cascadeClearSlots(ss, "left", 1) end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetX1 = {
								order = 1.11,
								name = LPS:L("Left Offset X 1"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left1"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left1"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetY1 = {
								order = 1.12,
								name = LPS:L("Left Offset Y 1"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left1"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left1"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightSlot1 = {
								order = 1.2,
								name = LPS:L("Right Slot 1"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right1"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.right1 = ss.right1 or { offsetX = 0, offsetY = 0 }
									local cur = ss.right1
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if v == "none" then cascadeClearSlots(ss, "right", 1) end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetX1 = {
								order = 1.21,
								name = LPS:L("Right Offset X 1"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right1"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right1"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetY1 = {
								order = 1.22,
								name = LPS:L("Right Offset Y 1"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right1"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right1"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftSlot2 = {
							disabled = makeSlotDisabledFunc("left", 2),
								order = 2.1,
								name = LPS:L("Left Slot 2"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left2"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.left2 = ss.left2 or { offsetX = 0, offsetY = 0 }
									local cur = ss.left2
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if v == "none" then cascadeClearSlots(ss, "left", 2) end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetX2 = {
							disabled = makeSlotDisabledFunc("left", 2),
								order = 2.11,
								name = LPS:L("Left Offset X 2"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left2"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left2"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetY2 = {
							disabled = makeSlotDisabledFunc("left", 2),
								order = 2.12,
								name = LPS:L("Left Offset Y 2"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left2"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left2"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightSlot2 = {
							disabled = makeSlotDisabledFunc("right", 2),
								order = 2.2,
								name = LPS:L("Right Slot 2"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right2"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.right2 = ss.right2 or { offsetX = 0, offsetY = 0 }
									local cur = ss.right2
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if v == "none" then cascadeClearSlots(ss, "right", 2) end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetX2 = {
							disabled = makeSlotDisabledFunc("right", 2),
								order = 2.21,
								name = LPS:L("Right Offset X 2"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right2"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right2"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetY2 = {
							disabled = makeSlotDisabledFunc("right", 2),
								order = 2.22,
								name = LPS:L("Right Offset Y 2"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right2"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right2"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftSlot3 = {
							disabled = makeSlotDisabledFunc("left", 3),
								order = 3.1,
								name = LPS:L("Left Slot 3"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left3"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.left3 = ss.left3 or { offsetX = 0, offsetY = 0 }
									local cur = ss.left3
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetX3 = {
							disabled = makeSlotDisabledFunc("left", 3),
								order = 3.11,
								name = LPS:L("Left Offset X 3"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left3"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left3"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							leftOffsetY3 = {
							disabled = makeSlotDisabledFunc("left", 3),
								order = 3.12,
								name = LPS:L("Left Offset Y 3"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left3"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["left3"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightSlot3 = {
							disabled = makeSlotDisabledFunc("right", 3),
								order = 3.2,
								name = LPS:L("Right Slot 3"),
								type = "select",
								values = function()
									local vals = { none = LPS:L("None"), coords = LPS:L("Coords"), time = LPS:L("Time"), gold = LPS:L("Gold"), system = LPS:L("System") }
									if LPS.GetSlotKeyList then
										for _, k in ipairs(LPS:GetSlotKeyList()) do
											local def = LPS.datatexts and LPS.datatexts[k]
											vals[k] = def and def.name or k
										end
									end
									return vals
								end,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right3"]
									local v = (s and s.frame) or "NONE"
									if v == "NONE" or v == "None" or v == "" or v == nil then
										return "none"
									end
									return v
								end,
								set = function(_, v)
									local db = getDb()
									db.layout.sideSlots = db.layout.sideSlots or {}
									local ss = db.layout.sideSlots
									ss.right3 = ss.right3 or { offsetX = 0, offsetY = 0 }
									local cur = ss.right3
									v = v or "none"
									if v ~= "none" then
										for _, other in pairs(ss) do
											if type(other) == "table" and other ~= cur and other.frame == v then
												other.frame = "NONE"
											end
										end
									end
									cur.frame = (v == "none") and "NONE" or v
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetX3 = {
							disabled = makeSlotDisabledFunc("right", 3),
								order = 3.21,
								name = LPS:L("Right Offset X 3"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right3"]
									return tonumber(s and s.offsetX) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right3"]
									if s then s.offsetX = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
							rightOffsetY3 = {
							disabled = makeSlotDisabledFunc("right", 3),
								order = 3.22,
								name = LPS:L("Right Offset Y 3"),
								type = "range",
								min = -200,
								max = 200,
								step = 1,
								get = function()
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right3"]
									return tonumber(s and s.offsetY) or 0
								end,
								set = function(_, v)
									local ss = getDb().layout.sideSlots
									local s = ss and ss["right3"]
									if s then s.offsetY = v end
									if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
									if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
								end,
							},
						},
					},
					spacingGroup = {
						order = 7,
						type = "group",
						name = LPS:L("Spacing"),
						inline = true,
						args = {
							spacingAuto = {
								order = 1,
								type = "toggle",
								name = LPS:L("Auto"),
								desc = LPS:L("Automatically manage spacing between panels."),
								get = function() return getDb().layout.spacingAuto end,
								set = function(_, v)
									getDb().layout.spacingAuto = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							spacingManual = {
								order = 2,
								type = "range",
								name = LPS:L("Manual"),
								desc = LPS:L("Set spacing between panels."),
								min = 0,
								max = 50,
								step = 1,
								disabled = function() return getDb().layout.spacingAuto end,
								get = function() return getDb().layout.spacingManual end,
								set = function(_, v)
									getDb().layout.spacingManual = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
						},
					},
					style = {
						type = "group",
						name = LPS:L("Style"),
						order = 8,
						inline = true,
						args = {
							frameStrata = {
								type = "select",
								name = LPS:L("Frame strata"),
								desc = LPS:L("Controls how high the LocationPlus panels are drawn."),
								order = 0,
								values = strataValues,
								get = function() return getDb().layout.frameStrata end,
								set = function(_, v)
									getDb().layout.frameStrata = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							frameLevel = {
								type = "range",
								name = LPS:L("Frame level"),
								desc = LPS:L("Fine-tune draw order within the selected strata."),
								order = 0.1,
								min = 0,
								max = 1000,
								step = 1,
								get = function() return tonumber(getDb().layout.frameLevel) or 1 end,
								set = function(_, v)
									getDb().layout.frameLevel = v
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
							spacer1_fontSize = {
								type = "description",
								name = " ",
								order = 0.5,
							},
							fontSize = {
								type = "range",
								name = LPS:L("Font size"),
								desc = LPS:L("Set font size."),
								order = 1.1,
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
								order = 1.2,
								min = 0,
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
							spacer1_bgEnable = {
								type = "description",
								name = " ",
								order = 1.5,
							},
							bgEnable = {
								type = "toggle",
								name = LPS:L("Enable background"),
								desc = LPS:L("Toggle background on the panel."),
								order = 2.1,
								get = function() return getDb().settings.colors.bgEnable end,
								set = function(_, v)
									getDb().settings.colors.bgEnable = v
									if LPS.ApplyStyle then
										LPS:ApplyStyle()
									end
								end,
							},
							bgColor = {
								type = "color",
								name = LPS:L("Background color"),
								desc = LPS:L("Set background color."),
								order = 2.2,
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
								order = 3.3,
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
					colors = {
						order = 9,
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
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
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
									if LPS.ScheduleRefresh then
										LPS:ScheduleRefresh()
									end
								end,
							},
						},
					},
				},
			},
			profiles = {
				type = "group",
				name = LPS:L("Profiles"),
				order = 90,
				args = {},
			},
			-- NOTE: the AceConfigRegistry validator only allows a fixed set of
			-- keys on each option entry (type/name/desc/order/args/childGroups...).
			-- Any extra key (e.g. an accidental "path") makes every dialog open
			-- fail with "ValidateOptionsTable(): <app>.<key>: unknown parameter".
			importexport = {
				type = "group",
				name = LPS:L("Import/Export"),
				order = 91,
				args = {
					export = {
						type = "group",
						name = LPS:L("Export"),
						order = 1,
						args = {
							header = {
								order = 1,
								type = "header",
								name = LPS:L("Export"),
							},
							generate = {
								order = 2,
								type = "execute",
								name = LPS:L("Generate export string"),
								desc = LPS:L("Generate an export string for the current profile."),
								disabled = function()
									return not (AceSerializer and LPS.db and LPS.db.profile)
								end,
								func = function()
									local serialString = AceSerializer:Serialize(LPS.db.profile or {})
									if LibDeflate and LibDeflate.CompressDeflate and LibDeflate.EncodeForPrint then
										local compressedData = LibDeflate:CompressDeflate(serialString, { level = 5 })
										local printableString = compressedData and LibDeflate:EncodeForPrint(compressedData)
										if printableString then
											LPS.Options._profileExportText = PROFILE_EXPORT_PREFIX .. printableString
											return
										end
									end
									LPS.Options._profileExportText = serialString
								end,
							},
							text = {
								order = 3,
								type = "input",
								name = LPS:L("Export string"),
								desc = LPS:L("Copy this string to export your current profile."),
								width = "full",
								multiline = 12,
								dialogControl = "LPSMultiLineEditBoxNoButton",
								disabled = function()
									return not (AceSerializer and LPS.db and LPS.db.profile)
								end,
								get = function() return tostring(LPS.Options._profileExportText or "") end,
								set = function(_, v) LPS.Options._profileExportText = v end,
							},
						},
					},
					import = {
						type = "group",
						name = LPS:L("Import"),
						order = 2,
						args = {
							header = {
								order = 1,
								type = "header",
								name = LPS:L("Import"),
							},
							asName = {
								order = 2,
								type = "input",
								name = LPS:L("Profile name"),
								desc = LPS:L("Name of the profile to import into."),
								dialogControl = "LPSEditBoxNoButton",
								disabled = function()
									return not (AceSerializer and LPS.db and LPS.db.SetProfile and LPS.db.profile)
								end,
								get = function() return tostring(LPS.Options._profileImportAsName or "") end,
								set = function(_, v) LPS.Options._profileImportAsName = v end,
							},
							text = {
								order = 3,
								type = "input",
								name = LPS:L("Import string"),
								desc = LPS:L("Paste an export string here to import a profile."),
								width = "full",
								multiline = 12,
								dialogControl = "LPSMultiLineEditBoxNoButton",
								disabled = function()
									return not (AceSerializer and LPS.db and LPS.db.profile)
								end,
								get = function() return tostring(LPS.Options._profileImportText or "") end,
								set = function(_, v) LPS.Options._profileImportText = v end,
							},
							doImport = {
								order = 4,
								type = "execute",
								name = LPS:L("Import"),
								desc = LPS:L("Import the string into the selected profile name."),
								disabled = function()
									return not (AceSerializer and LPS.db and LPS.db.profile and LPS.db.SetProfile)
								end,
								func = function()
									local s = tostring(LPS.Options._profileImportText or "")
									if s == "" then return end
									local importName = tostring(LPS.Options._profileImportAsName or "")
									local currentProfile = LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()
									if importName == "" then
										importName = tostring(currentProfile or "")
									end
									if importName == "" then return end
									local decodeString = s
									if LibDeflate and LibDeflate.DecodeForPrint and LibDeflate.DecompressDeflate and s:sub(1, #PROFILE_EXPORT_PREFIX) == PROFILE_EXPORT_PREFIX then
										local encoded = s:sub(#PROFILE_EXPORT_PREFIX + 1)
										encoded = encoded:gsub("%s+", "")
										local compressed = LibDeflate:DecodeForPrint(encoded)
										if not compressed then return end
										local decompressed = LibDeflate:DecompressDeflate(compressed)
										if not decompressed then return end
										decodeString = decompressed
									end
									local ok, t = AceSerializer:Deserialize(decodeString)
									if not ok or type(t) ~= "table" then
										return
									end
									if currentProfile and importName ~= currentProfile then
										LPS.db:SetProfile(importName)
									end
									local p2 = LPS.db.profile
									for k in pairs(p2) do
										p2[k] = nil
									end
									for k, v in pairs(t) do
										p2[k] = deepCopy(v)
									end
									if LPS.RefreshAfterProfileChange then
										LPS:RefreshAfterProfileChange()
									end
								end,
							},
						},
					},
				},
			},
		},
	}

	-- NOTE: the root table is registered by registerRootAndSubCategories() below,
	-- which runs at load time and again (idempotently) from LPS.Options:FinalizeAce()
	-- once the AceDB profile exists (see Game/core.lua onLoaded). This avoids the
	-- "RegisterOptionsTable(appName, options): 'options' - expected table or function
	-- reference" error when a get/set function inlined in the table throws during
	-- the registry's validation pass (e.g. because the database was not ready yet).

	local function deepCopyAce(v)
		return deepCopy(v)
	end

	local function resolveAceName(v)
		if type(v) == "function" then
			local ok, r = pcall(v)
			if ok and r ~= nil then
				return tostring(r)
			end
			return ""
		end
		return tostring(v or "")
	end

	local function registerSubCategory(suffix, group)
		if type(group) ~= "table" then return end
		local displayName = resolveAceName(group.name)
		if displayName == "" then
			displayName = suffix
		end
		local appName = LPS.Options.aceAppName .. suffix
		AceConfig:RegisterOptionsTable(appName, group)
		AceDialog:AddToBlizOptions(appName, displayName, LPS.addon.title)
	end

	local aboutAuthor = nil
	if GetAddOnMetadata and LPS.addon and LPS.addon.name then
		aboutAuthor = GetAddOnMetadata(LPS.addon.name, "Author")
	end
	if not aboutAuthor or aboutAuthor == "" then
		aboutAuthor = "Arpeks"
	end

	-- Root options table + subcategory tabs are registered later, from
	-- LPS.Options:FinalizeAce() (called by Game/core.lua once the AceDB
	-- profile exists), so that get/set functions inside the table can
	-- safely rely on a fully initialised database.
	local rootRegistered = false
	local subCategoriesRegistered = false

	local function registerRootAndSubCategories()
		if type(options) ~= "table" then return end
		if not rootRegistered then
			rootRegistered = true
			local ok, err = pcall(AceConfig.RegisterOptionsTable, AceConfig, LPS.Options.aceAppName, options)
			-- if ok then
			-- 	AceDialog:AddToBlizOptions(LPS.Options.aceAppName, LPS.addon.title)
			-- else
				-- The registry validates every value of the table; if a single
				-- value has an unsupported type (e.g. userdata leaked into the
				-- table by another addon), fall back to a sanitized deep copy
				-- that keeps only cleanable values and re-registers it.
			-- 	local function sanitize(v)
			-- 		local t = type(v)
			-- 		if t == "function" or t == "number" or t == "boolean" or t == "string" then
			-- 			return v
			-- 		elseif t == "table" then
			-- 			local out = {}
			-- 			for k, val in pairs(v) do
			-- 				if type(k) == "string" or type(k) == "number" then
			-- 					out[k] = sanitize(val)
			-- 				end
			-- 			end
			-- 			return out
			-- 		end
			-- 		return nil
			-- 	end
			-- 	local copy = sanitize(options)
			-- 	local ok2, err2 = pcall(AceConfig.RegisterOptionsTable, AceConfig, LPS.Options.aceAppName, copy)
			-- 	if ok2 then
			-- 		AceDialog:AddToBlizOptions(LPS.Options.aceAppName, LPS.addon.title)
			-- 	elseif LPS.DEBUG then
			-- 		print("LPS: RegisterOptionsTable failed:", tostring(err), "/", tostring(err2))
			-- 	end
			-- end
		end
		if not subCategoriesRegistered then
			subCategoriesRegistered = true
			registerSubCategory("_General", options.args.general)
			registerSubCategory("_Show", options.args.show)
			registerSubCategory("_Tooltip", options.args.tooltip)
			registerSubCategory("_Layout", options.args.layout)
			if options.args.importexport then
				registerSubCategory("_ImportExport", options.args.importexport)
			end
		end
	end

	AceConfig:RegisterOptionsTable(LPS.Options.aceAppName .. "_About", {
	type = "group",
	name = LPS.addon.title.." v"..LPS.addon.version,
	args = {
		logo = {
			order = 1,
			type = "description",
			name = " ",
			image = LPS.icons.PathLogoModern,
			imageWidth = 128,
			imageHeight = 128,
		},
		spacer = {
			order = 2,
			type = "description",
			name = " ",
		},
		creditsHeader = {
			order = 3,
			type = "header",
			name = "Credits",
		},
		creditsList = {
			order = 4,
			type = "description",
			fontSize = "medium",
			name = table.concat({
				"|cffffd200Author:|r "..aboutAuthor,
				"",
				"|cffffd200Special Thanks:|r",
				" |cff00ff00The WoW addon community|r",
			}, "\n"),
		},
	},
})
	AceDialog:AddToBlizOptions(LPS.Options.aceAppName .. "_About", LPS.addon.title)

	registerRootAndSubCategories()

	deepCopy = function(v)
		if type(v) ~= "table" then
			return v
		end
		local out = {}
		for k2, v2 in pairs(v) do
			out[deepCopy(k2)] = deepCopy(v2)
		end
		return out
	end

	function LPS.Options:EnsureAceProfilesTab()
		if self._profilesTabEnsured then return end
		if not (LibStub and LibStub.GetLibrary) then return end
		if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
		local AceDBOptions = LibStub("AceDBOptions-3.0")
		local p = AceDBOptions:GetOptionsTable(LPS.db)
		if type(p) ~= "table" then return end
		p.order = 90
		p.name = LPS:L("Profiles")
		options.args.profiles = p
		self._profilesTabEnsured = true
		if AceConfigRegistry and AceConfigRegistry.NotifyChange then
			AceConfigRegistry:NotifyChange(self.aceAppName)
		end
	end

	function LPS.Options:RegisterAceProfiles()
		if self._profilesRegistered then return end
		if not (LibStub and LibStub.GetLibrary) then return end
		if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
		local AceDBOptions = LibStub("AceDBOptions-3.0")
		AceConfig:RegisterOptionsTable(LPS.Options.aceAppName .. "_Profiles", AceDBOptions:GetOptionsTable(LPS.db))
		if AceDialog and not self._profilesBlizAdded then
			AceDialog:AddToBlizOptions(LPS.Options.aceAppName .. "_Profiles", LPS:L("Profiles"), LPS.addon.title)
			self._profilesBlizAdded = true
		end
		self._profilesRegistered = true
	end

	function LPS.Options:FinalizeAce()
		registerRootAndSubCategories()
		if AceConfigRegistry and AceConfigRegistry.NotifyChange then
			AceConfigRegistry:NotifyChange(self.aceAppName)
		end
	end

	LPS.Options:EnsureAceProfilesTab()
	LPS.Options:RegisterAceProfiles()
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
--------------------------------------------------
if false and Settings and Settings.RegisterCanvasLayoutCategory then
	local panel = CreateFrame("Frame")
	panel.name = LPS.addon.title
	LPS.Options.panel = panel

	local function ensureInited(self, initFunc)
		if self.inited then return end
		self.inited = true
		initFunc(self)
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
	local function getDb()
		return LPS:GetDB()
	end

	self:CreateCheck(parent,
		"Login message",
		nil,
		function() return getDb().general.loginMessage end,
		function(v) getDb().general.loginMessage = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"24H time format",
		nil,
		function() return getDb().general.is24H end,
		function(v)
			getDb().general.is24H = v
			if LPS.ApplyTimeFormat then
				LPS:ApplyTimeFormat()
			end
		end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Show seconds",
		nil,
		function() return getDb().general.seconds end,
		function(v)
			getDb().general.seconds = v
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
		function() return getDb().general.coordsTimeUpdate end,
		function(v) getDb().general.coordsTimeUpdate = v end,
		16, y
	)
end

-------------------------------------------------
-- SHOW TAB
-------------------------------------------------
function LPS:CreateShowOptions(parent)
	local y = -10
	local function getDb()
		return LPS:GetDB()
	end

	self:CreateCheck(parent,
		"Show zone",
		nil,
		function() return getDb().show.zone end,
		function(v) getDb().show.zone = v end,
		16, y
	)

end

-------------------------------------------------
-- TOOLTIPS TAB
-------------------------------------------------
function LPS:CreateTooltipOptions(parent)
	local y = -10
	local function getDb()
		return LPS:GetDB()
	end

	self:CreateCheck(parent,
		"Enable tooltips",
		nil,
		function() return getDb().tooltips.visibility.enable end,
		function(v)
                        getDb().tooltips.visibility.enable = v
                        if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
                end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Hide in combat",
		nil,
		function() return getDb().tooltips.visibility.combat end,
		function(v)
                        getDb().tooltips.visibility.combat = v
                        if LPS.ScheduleRefresh then LPS:ScheduleRefresh() end
                end,
		16, y
	)
end

-------------------------------------------------
-- STYLE TAB
-------------------------------------------------
function LPS:CreateStyleOptions(parent)
	local y = -10
	local function getDb()
		return LPS:GetDB()
	end

	self:CreateCheck(parent,
		"Enable background",
		nil,
		function() return getDb().settings.colors.bgEnable end,
		function(v)
			getDb().settings.colors.bgEnable = v
			if LPS.ApplyStyle then
				LPS:ApplyStyle()
			end
		end,
		16, y
	)

	y = y - 40

	self:CreateSlider(parent,
		"Font size",
		8, 20, 1,
		function() return getDb().settings.fontSize end,
		function(v)
			getDb().settings.fontSize = v
			if LPS.ApplyStyle then
				LPS:ApplyStyle()
			end
		end,
		16, y
	)

	y = y - 50

	self:CreateSlider(parent,
		0, 6, 1,
		function() return getDb().settings.borderSize end,
		function(v)
			getDb().settings.borderSize = v
			if LPS.ApplyStyle then
				LPS:ApplyStyle()
			end
		end,
		16, y
	)
end

-------------------------------------------------
-- INIT
-------------------------------------------------
panel:SetScript("OnShow", function(self)
	ensureInited(self, function(p)
		local title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -18)
		title:SetText(LPS.addon.title)

		local version = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
		version:SetText("v" .. tostring(LPS.addon.version or ""))

		local logo = p:CreateTexture(nil, "ARTWORK")
		logo:SetPoint("TOPRIGHT", -18, -18)
		logo:SetSize(64, 64)
		logo:SetTexture(LPS.icons.PathLogo)

		local notes = nil
		if GetAddOnMetadata and LPS.addon and LPS.addon.name then
			notes = GetAddOnMetadata(LPS.addon.name, "Notes")
		end
		if not notes or notes == "" then
			notes = LPS:L("Adds location, coords,\nextra panels and an info-rich tooltip\n(no ElvUI required)")
		end
		local desc = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		desc:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -10)
		desc:SetWidth(520)
		desc:SetJustifyH("LEFT")
		desc:SetJustifyV("TOP")
		desc:SetText(tostring(notes))
	end)
end)

LPS.Options.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(LPS.Options.category)

local function makeSubPanel(key, displayName, initFunc)
	local p = CreateFrame("Frame")
	p.name = displayName
	p.parent = panel.name
	p:SetScript("OnShow", function(self)
		ensureInited(self, initFunc)
	end)
	LPS.Options["settings_" .. key] = p
	Settings.RegisterCanvasLayoutSubcategory(LPS.Options.category, p, displayName)
end

makeSubPanel("general", LPS:L("General"), function(p)
	LPS:CreateGeneralOptions(p)
	LPS.Options:CreateResetButton(p)
	LPS.Options:CreateResetPositionButton(p)
	LPS.Options:CreateToggleMoveButton(p)
end)

makeSubPanel("show", LPS:L("Show"), function(p)
	LPS:CreateShowOptions(p)
end)

makeSubPanel("tooltips", LPS:L("Tooltips"), function(p)
	LPS:CreateTooltipOptions(p)
end)

makeSubPanel("style", LPS:L("Style"), function(p)
	LPS:CreateStyleOptions(p)
end)

end
