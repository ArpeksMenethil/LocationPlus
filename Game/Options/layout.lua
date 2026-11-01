local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Layout" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.layout()
    return {
        name = L.LAYOUT,
        order = 4,
        args = {
            chainAnchor = {
                order = 3,
                type = "select",
                name = L.FRAME_ANCHOR_MODE,
                desc = L.SIDE_PANELS_ALWAYS_GROW_ALONG_THEIR_EDGE_LEFT_PANELS_ATTACH_TO_THE_LEFT_SIDE_OF_THE_GROUP_RIGHT_PANELS_ATTACH_TO_THE_RIGHT_SIDE_THIS_OPTION_CONTROLS_WHAT_THE_FIRST_PANEL_OF_EACH_CHAIN_ANCHORS_TO_THE_LOCATION_PANEL_EDGES_DEFAULT_OR_THE_OUTER_EDGES_OF_THE_WHOLE_HOLDER_FRAME,
                values = {
                    chain = L.LOCATION_PANEL_EDGES,
                    location = L.HOLDER_OUTER_EDGES,
                },
                get = function() return OH:getDb().layout.chainAnchor or "chain" end,
                set = function(_, v)
                    OH:getDb().layout.chainAnchor = v
                    LPS.Options:ApplyRefresh()
                end,
            },
            locpanel = {
                order = 4,
                name = L.LOCATION_PANEL,
                args = {
                    locMinWidth = {
                        order = 0,
                        type = "range",
                        name = L.MINIMUM_WIDTH,
                        desc = L.SETS_THE_MINIMUM_WIDTH_OF_THE_LOCATION_PANEL,
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
                        name = L.TEXT_PADDING_X,
                        desc = L.ADJUST_HORIZONTAL_TEXT_PADDING_INSIDE_LOCATION_PANEL,
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
                        name = L.TEXT_PADDING_Y,
                        desc = L.ADJUST_VERTICAL_TEXT_PADDING_INSIDE_LOCATION_PANEL,
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
                name = L.PANELS,
                args = {
                    dtshow = {
                        order = 0.3,
                        name = L.SHOW_PANELS,
                        desc = L.SHOW_HIDE_THE_EXTRA_PANELS_COORDS_AND_TIME,
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
                        name = L.MINIMUM_WIDTH,
                        desc = L.SETS_THE_MINIMUM_WIDTH_OF_THE_EXTRA_PANELS,
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
                        name = L.TEXT_PADDING_X,
                        desc = L.ADJUST_HORIZONTAL_TEXT_PADDING_INSIDE_PANELS,
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
                        name = L.TEXT_PADDING_Y,
                        desc = L.ADJUST_VERTICAL_TEXT_PADDING_INSIDE_PANELS,
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
                name = L.SIDE_PANELS,
                args = {
                    leftSlot1 = {
                        order = 1.1,
                        name = L.LEFT_SLOT_1,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.LEFT_OFFSET_X_1,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.LEFT_OFFSET_Y_1,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                        name = L.RIGHT_SLOT_1,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.RIGHT_OFFSET_X_1,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.RIGHT_OFFSET_Y_1,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                        name = L.LEFT_SLOT_2,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.LEFT_OFFSET_X_2,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.LEFT_OFFSET_Y_2,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                        name = L.RIGHT_SLOT_2,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.RIGHT_OFFSET_X_2,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.RIGHT_OFFSET_Y_2,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                        name = L.LEFT_SLOT_3,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.LEFT_OFFSET_X_3,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.LEFT_OFFSET_Y_3,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                        name = L.RIGHT_SLOT_3,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
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
                        name = L.RIGHT_OFFSET_X_3,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
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
                        name = L.RIGHT_OFFSET_Y_3,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
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
                name = L.SPACING,
                args = {
                    spacingAuto = {
                        order = 1,
                        type = "toggle",
                        name = L.AUTO,
                        desc = L.AUTOMATICALLY_MANAGE_SPACING_BETWEEN_PANELS,
                        get = function() return OH:getDb().layout.spacingAuto end,
                        set = function(_, v)
                            OH:getDb().layout.spacingAuto = v
                            LPS.Options:ApplyRefresh()
                        end,
                    },
                    spacingManual = {
                        order = 2,
                        type = "range",
                        name = L.MANUAL,
                        desc = L.SET_SPACING_BETWEEN_PANELS,
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
                name = L.STYLE,
                order = 8,
                args = {
                    frameStrata = {
                        type = "select",
                        name = L.FRAME_STRATA,
                        desc = L.CONTROLS_HOW_HIGH_THE_LOCATIONPLUS_PANELS_ARE_DRAWN,
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
                        name = L.FRAME_LEVEL,
                        desc = L.FINE_TUNE_DRAW_ORDER_WITHIN_THE_SELECTED_STRATA,
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
                        name = L.FONT_SIZE,
                        desc = L.SET_FONT_SIZE,
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
                        name = L.BORDER_SIZE,
                        desc = L.SET_BORDER_THICKNESS,
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
                        name = L.ENABLE_BACKGROUND,
                        desc = L.TOGGLE_BACKGROUND_ON_THE_PANEL,
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
                        name = L.BACKGROUND_COLOR,
                        desc = L.SET_BACKGROUND_COLOR,
                        order = 2.2,
                        hasAlpha = true,
                        default = { r = 0, g = 0, b = 0, a = 0.6 },
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
                        name = L.BORDER_COLOR,
                        desc = L.SET_BORDER_COLOR,
                        order = 3.3,
                        hasAlpha = true,
                        default = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
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
                name = L.COLORS,
                args = {
                    customColor = {
                        order = 1,
                        name = L.TEXT_COLOR,
                        desc = L.CHOOSE_HOW_PANEL_TEXT_IS_COLORED_THE_LOCATION_PANEL_ALWAYS_KEEPS_ITS_OWN_ZONE_STATUS_COLOR,
                        type = "select",
                        values = {
                            [1] = L.CUSTOM,
                            [2] = L.CLASS_COLORS,
                            [3] = L.DEFAULT,
                        },
                        get = function() return OH:getDb().layout.customColor end,
                        set = function(_, v)
                            OH:getDb().layout.customColor = v
                            LPS.Options:ApplyRefresh()
                        end,
                    },
                    userColor = {
                        order = 2,
                        name = L.TEXT_CUSTOM_COLOR,
                        desc = L.PICK_A_CUSTOM_COLOR_FOR_PANEL_TEXT,
                        type = "color",
                        default = { r = 1, g = 1, b = 1 },
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
