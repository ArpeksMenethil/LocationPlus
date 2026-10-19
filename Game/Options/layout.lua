local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Layout" дерева настроек (формат AceConfig-3.0).
function LPS.Options.BuildTree.tabs.layout()
	return {
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
					get = function() return OH:getDb().layout.chainAnchor or "chain" end,
					set = function(_, v)
					OH:getDb().layout.chainAnchor = v
					LPS.Options:ApplyRefresh()
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
							get = function() return OH:getDb().layout.locMinWidth end,
							set = function(_, v)
							OH:getDb().layout.locMinWidth = v
							LPS.Options:ApplyRefresh()
							end,
						},
						locPaddingX = {
							order = 1,
							type = "range",
							name = LPS:L("Text padding X"),
							desc = LPS:L("Adjust horizontal text padding inside location panel."),
							min = 0,
							max = 60,
							step = 1,
							get = function() return OH:getDb().layout.locPaddingX end,
							set = function(_, v)
							OH:getDb().layout.locPaddingX = v
							LPS.Options:ApplyRefresh()
							end,
						},
						locPaddingY = {
							order = 2,
							type = "range",
							name = LPS:L("Text padding Y"),
							desc = LPS:L("Adjust vertical text padding inside location panel."),
							min = 0,
							max = 30,
							step = 1,
							get = function() return OH:getDb().layout.locPaddingY end,
							set = function(_, v)
							OH:getDb().layout.locPaddingY = v
							LPS.Options:ApplyRefresh()
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
							
							get = function() return OH:getDb().layout.dtshow end,
							set = function(_, v)
							OH:getDb().layout.dtshow = v
							if LPS.ApplyDTVisibility then
							LPS:ApplyDTVisibility()
							end
							LPS.Options:ApplyRefresh()
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
							disabled = function() return OH:getDb().layout.dtshow == false end,
							get = function() return OH:getDb().layout.dtMinWidth end,
							set = function(_, v)
							OH:getDb().layout.dtMinWidth = v
							LPS.Options:ApplyRefresh()
							end,
						},
						dtPaddingX = {
							order = 2,
							type = "range",
							name = LPS:L("Text padding X"),
							desc = LPS:L("Adjust horizontal text padding inside panels."),
							min = 0,
							max = 60,
							step = 1,
							disabled = function() return OH:getDb().layout.dtshow == false end,
							get = function() return OH:getDb().layout.dtPaddingX end,
							set = function(_, v)
							OH:getDb().layout.dtPaddingX = v
							LPS.Options:ApplyRefresh()
							end,
						},
						dtPaddingY = {
							order = 3,
							type = "range",
							name = LPS:L("Text padding Y"),
							desc = LPS:L("Adjust vertical text padding inside panels."),
							min = 0,
							max = 30,
							step = 1,
							disabled = function() return OH:getDb().layout.dtshow == false end,
							get = function() return OH:getDb().layout.dtPaddingY end,
							set = function(_, v)
							OH:getDb().layout.dtPaddingY = v
							LPS.Options:ApplyRefresh()
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
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left1"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							if v == "none" then OH:cascadeClearSlots(ss, "left", 1) end
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["left1"] = true
							LPS.Options:ApplyRefresh()
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
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left1"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left1"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
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
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left1"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left1"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						rightSlot1 = {
							order = 1.2,
							name = LPS:L("Right Slot 1"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right1"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							if v == "none" then OH:cascadeClearSlots(ss, "right", 1) end
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["right1"] = true
							LPS.Options:ApplyRefresh()
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
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right1"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right1"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
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
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right1"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right1"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						leftSlot2 = {
							disabled = OH:makeSlotDisabledFunc("left", 2),
							order = 2.1,
							name = LPS:L("Left Slot 2"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left2"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							if v == "none" then OH:cascadeClearSlots(ss, "left", 2) end
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["left2"] = true
							LPS.Options:ApplyRefresh()
							end,
						},
						leftOffsetX2 = {
							disabled = OH:makeSlotDisabledFunc("left", 2),
							order = 2.11,
							name = LPS:L("Left Offset X 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left2"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left2"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						leftOffsetY2 = {
							disabled = OH:makeSlotDisabledFunc("left", 2),
							order = 2.12,
							name = LPS:L("Left Offset Y 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left2"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left2"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						rightSlot2 = {
							disabled = OH:makeSlotDisabledFunc("right", 2),
							order = 2.2,
							name = LPS:L("Right Slot 2"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right2"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							if v == "none" then OH:cascadeClearSlots(ss, "right", 2) end
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["right2"] = true
							LPS.Options:ApplyRefresh()
							end,
						},
						rightOffsetX2 = {
							disabled = OH:makeSlotDisabledFunc("right", 2),
							order = 2.21,
							name = LPS:L("Right Offset X 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right2"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right2"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						rightOffsetY2 = {
							disabled = OH:makeSlotDisabledFunc("right", 2),
							order = 2.22,
							name = LPS:L("Right Offset Y 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right2"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right2"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						leftSlot3 = {
							disabled = OH:makeSlotDisabledFunc("left", 3),
							order = 3.1,
							name = LPS:L("Left Slot 3"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left3"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							local _ss = OH:getDb().layout.sideSlots
							_ss.userTouched = _ss.userTouched or {}
							_ss.userTouched["left3"] = true
							LPS.Options:ApplyRefresh()
							end,
						},
						leftOffsetX3 = {
							disabled = OH:makeSlotDisabledFunc("left", 3),
							order = 3.11,
							name = LPS:L("Left Offset X 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left3"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left3"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						leftOffsetY3 = {
							disabled = OH:makeSlotDisabledFunc("left", 3),
							order = 3.12,
							name = LPS:L("Left Offset Y 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left3"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["left3"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						rightSlot3 = {
							disabled = OH:makeSlotDisabledFunc("right", 3),
							order = 3.2,
							name = LPS:L("Right Slot 3"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right3"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = OH:getDb()
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
							local _ss = OH:getDb().layout.sideSlots
							_ss.userTouched = _ss.userTouched or {}
							_ss.userTouched["right3"] = true
							LPS.Options:ApplyRefresh()
							end,
						},
						rightOffsetX3 = {
							disabled = OH:makeSlotDisabledFunc("right", 3),
							order = 3.21,
							name = LPS:L("Right Offset X 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right3"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right3"]
							if s then s.offsetX = v end
							LPS.Options:ApplyRefresh()
							end,
						},
						rightOffsetY3 = {
							disabled = OH:makeSlotDisabledFunc("right", 3),
							order = 3.22,
							name = LPS:L("Right Offset Y 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right3"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = OH:getDb().layout.sideSlots
							local s = ss and ss["right3"]
							if s then s.offsetY = v end
							LPS.Options:ApplyRefresh()
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
							get = function() return OH:getDb().layout.spacingAuto end,
							set = function(_, v)
							OH:getDb().layout.spacingAuto = v
							LPS.Options:ApplyRefresh()
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
							disabled = function() return OH:getDb().layout.spacingAuto end,
							get = function() return OH:getDb().layout.spacingManual end,
							set = function(_, v)
							OH:getDb().layout.spacingManual = v
							LPS.Options:ApplyRefresh()
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
							values = OH:strataValues(),
							get = function() return OH:getDb().layout.frameStrata end,
							set = function(_, v)
							OH:getDb().layout.frameStrata = v
							LPS.Options:ApplyRefresh()
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
							get = function() return tonumber(OH:getDb().layout.frameLevel) or 1 end,
							set = function(_, v)
							OH:getDb().layout.frameLevel = v
							LPS.Options:ApplyRefresh()
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
							get = function() return OH:getDb().settings.fontSize end,
							set = function(_, v)
							OH:getDb().settings.fontSize = v
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
							get = function() return OH:getDb().settings.borderSize end,
							set = function(_, v)
							OH:getDb().settings.borderSize = v
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
							get = function() return OH:getDb().settings.colors.bgEnable end,
							set = function(_, v)
							OH:getDb().settings.colors.bgEnable = v
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
							local c = OH:getDb().settings.colors.bg
							return c[1], c[2], c[3], c[4]
							end,
							set = function(_, r, g, b, a)
							local c = OH:getDb().settings.colors.bg
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
							local c = OH:getDb().settings.colors.border
							return c[1], c[2], c[3], c[4]
							end,
							set = function(_, r, g, b, a)
							local c = OH:getDb().settings.colors.border
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
							desc = LPS:L("Choose how panel text is colored. The location panel always keeps its own zone-status color."),
							type = "select",
							values = {
								[1] = LPS:L("Custom"),
								[2] = LPS:L("Class Colors"),
								[3] = LPS:L("Default"),
							},
							get = function() return OH:getDb().layout.customColor end,
							set = function(_, v)
							OH:getDb().layout.customColor = v
							LPS.Options:ApplyRefresh()
							end,
						},
						userColor = {
							order = 2,
							name = LPS:L("Text custom color"),
							desc = LPS:L("Pick a custom color for panel text."),
							type = "color",
							disabled = function() return OH:getDb().layout.customColor ~= 1 end,
							get = function()
							local c = OH:getDb().layout.userColor
							return (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
							end,
							set = function(_, r, g, b)
							local c = OH:getDb().layout.userColor
							if not c then
							c = { r = 1, g = 1, b = 1 }
							OH:getDb().layout.userColor = c
							end
							c.r, c.g, c.b = r, g, b
							LPS.Options:ApplyRefresh()
							end,
						},
					},
				},
			}
}
end
