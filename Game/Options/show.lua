local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Show" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.show()
	return {
			type = "group",
			name = LPS:L("DISPLAY"),
			order = 2,
			args = {
				locationGroup = {
					order = 1,
					type = "group",
					name = LPS:L("LOCATION"),
					inline = true,
					
					args = {
						zone = {
							order = 1,
							type = "toggle",
							name = LPS:L("SHOW_ZONE"),
							desc = LPS:L("SHOW_ZONE_NAME_ON_THE_PANEL"),
							
							get = function() return OH:getDb().show.zone end,
							set = function(_, v)
							OH:getDb().show.zone = v
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
							name = LPS:L("CREST"),
							desc = LPS:L("SHOW_AN_ICON_NEXT_TO_THE_ADDITIONAL_INFO"),
							type = "toggle",
							
							disabled = function() return OH:getDb().show.displayOther == "NONE" end,
							get = function() return OH:getDb().show.showicon end,
							set = function(_, v)
							OH:getDb().show.showicon = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
						displayOther = {
							order = 3,
							name = LPS:L("OTHER"),
							desc = LPS:L("SHOW_ADDITIONAL_INFO_IN_THE_LOCATION_PANEL"),
							type = "select",
							
							values = OH:getDisplayOtherValues(),
							get = function() return OH:getDb().show.displayOther end,
							set = function(_, v)
							local values = OH:getDisplayOtherValues()
							if values[v] == nil then
							v = "RLEVEL"
							end
							OH:getDb().show.displayOther = v
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
					name = LPS:L("COORDS"),
					inline = true,
					
					args = {
						dig = {
							order = 1,
							name = LPS:L("DETAILED_COORDS"),
							desc = LPS:L("ADDS_2_DIGITS_IN_THE_COORDS"),
							type = "toggle",
							
							get = function() return OH:getDb().show.dig end,
							set = function(_, v)
							OH:getDb().show.dig = v
							local f = LPS.frame and LPS.frame.coords
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
						coordsTimeUpdate = {
							order = 2,
							name = LPS:L("UPDATE_TIMER"),
							desc = LPS:L("ADJUST_COORDS_UPDATES_IN_SECONDS_TO_AVOID_CPU_LOAD"),
							type = "range",
							
							min = 0.05,
							max = 1,
							step = 0.05,
							get = function() return OH:getDb().general.coordsTimeUpdate end,
							set = function(_, v)
								OH:getDb().general.coordsTimeUpdate = v
								if LPS.ApplyCoordsUpdateInterval then
									LPS:ApplyCoordsUpdateInterval()
								end
							end,
						},
					},
				},
				experienceGroup = {
					order = 3,
					type = "group",
					name = LPS:L("EXPERIENCE"),
					inline = true,
					
					args = {
						experience = {
							order = 1,
							type = "select",
							name = LPS:L("VALUE_FORMAT"),
							desc = LPS:L("CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL"),
							values = {
								PERCENT = LPS:L("PERCENT"),
								CURMAX = LPS:L("CURRENT_MAX"),
								CUR = LPS:L("CURRENT"),
								REM = LPS:L("REMAINING"),
							},
							get = function() return OH:getDb().show.experience.display or "PERCENT" end,
							set = function(_, v)
								OH:getDb().show.experience.display = v
								LPS.Options:ApplyRefresh()
							end,
						},
					},
				},
				bagsGroup = {
					order = 4,
					type = "group",
					name = LPS:L("BAGS"),
					inline = true,
					
					args = {
						bags = {
							order = 1,
							type = "select",
							name = LPS:L("VALUE_FORMAT"),
							desc = LPS:L("CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL"),
							values = {
								USED_TOTAL = LPS:L("USED_TOTAL"),
								FREE = LPS:L("FREE_SLOTS"),
								USED = LPS:L("USED_SLOTS"),
							},
							get = function() return OH:getDb().show.bags.display or "USED_TOTAL" end,
							set = function(_, v)
								OH:getDb().show.bags.display = v
								LPS.Options:ApplyRefresh()
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
							name = LPS:L("CUSTOM_LABEL"),
							disabled = function() return OH:getDb().show.bags.noLabel end,
							get = function() return OH:getDb().show.bags.label or "" end,
							set = function(_, v)
								OH:getDb().show.bags.label = v or ""
								LPS.Options:ApplyRefresh()
							end,
						},
						bagsNoLabel = {
							order = 3,
							type = "toggle",
							name = LPS:L("HIDE_LABEL"),
							get = function() return OH:getDb().show.bags.noLabel or false end,
							set = function(_, v)
								OH:getDb().show.bags.noLabel = v and true or false
								LPS.Options:ApplyRefresh()
							end,
						},
					},
				},
			}
}
end
