local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Show" дерева настроек (формат AceConfig-3.0).
function LPS.Options.BuildTree.tabs.show()
	return {
			type = "group",
			name = LPS:L("Display"),
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
							name = LPS:L("Crest"),
							desc = LPS:L("Show an icon next to the additional info."),
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
							name = LPS:L("Other"),
							desc = LPS:L("Show additional info in the Location Panel"),
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
					name = LPS:L("Coords"),
					inline = true,
					
					args = {
						dig = {
							order = 1,
							name = LPS:L("Detailed Coords"),
							desc = LPS:L("Adds 2 digits in the coords"),
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
							name = LPS:L("Update Timer"),
							desc = LPS:L("Adjust coords updates (in seconds) to avoid cpu load."),
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
					name = LPS:L("Experience"),
					inline = true,
					
					args = {
						experience = {
							order = 1,
							type = "select",
							name = LPS:L("Value format"),
							desc = LPS:L("Choose how the value is shown on the panel."),
							values = {
								PERCENT = LPS:L("Percent"),
								CURMAX = LPS:L("Current / Max"),
								CUR = LPS:L("Current"),
								REM = LPS:L("Remaining"),
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
					name = LPS:L("Bags"),
					inline = true,
					
					args = {
						bags = {
							order = 1,
							type = "select",
							name = LPS:L("Value format"),
							desc = LPS:L("Choose how the value is shown on the panel."),
							values = {
								USED_TOTAL = LPS:L("Used / Total"),
								FREE = LPS:L("Free slots"),
								USED = LPS:L("Used slots"),
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
							name = LPS:L("Custom label"),
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
							name = LPS:L("Hide label"),
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
