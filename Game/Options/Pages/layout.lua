local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Фреймы, уже назначенные в ДРУГИХ слотах (для пометки в выпадающем
--- списке, чтобы не назначать один и тот же фрейм повторно).
local function framesUsedInOtherSlots(slotKey)
    local used = {}
    local ss = LPS:GetOptionDB().layout.sideSlots
    if type(ss) == "table" then
        for k, s in pairs(ss) do
            if type(s) == "table" and k ~= slotKey then
                local f = s.frame
                if f and f ~= "NONE" and f ~= "None" and f ~= "none" and f ~= "" then
                    used[f] = true
                end
            end
        end
    end
    return used
end


--- Возвращает вкладку "Layout" дерева настроек (внутренний формат дерева настроек).
LPS.Options.BuildTree.tabs.layout = function()
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
                get = function() return LPS:GetOptionDB().layout.chainAnchor or "chain" end,
                set = function(_, v)
                    LPS:GetOptionDB().layout.chainAnchor = v
                    LPS:ApplyOptionsRefresh()
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
                        get = function() return LPS:GetOptionDB().layout.locMinWidth end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.locMinWidth = v
                            LPS:ApplyOptionsRefresh()
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
                        get = function() return LPS:GetOptionDB().layout.locPaddingX end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.locPaddingX = v
                            LPS:ApplyOptionsRefresh()
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
                        get = function() return LPS:GetOptionDB().layout.locPaddingY end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.locPaddingY = v
                            LPS:ApplyOptionsRefresh()
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

                        get = function() return LPS:GetOptionDB().layout.dtshow end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.dtshow = v
                            if LPS.ApplyDTVisibility then
                                LPS:ApplyDTVisibility()
                            end
                            LPS:ApplyOptionsRefresh()
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
                        disabled = function() return LPS:GetOptionDB().layout.dtshow == false end,
                        get = function() return LPS:GetOptionDB().layout.dtMinWidth end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.dtMinWidth = v
                            LPS:ApplyOptionsRefresh()
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
                        disabled = function() return LPS:GetOptionDB().layout.dtshow == false end,
                        get = function() return LPS:GetOptionDB().layout.dtPaddingX end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.dtPaddingX = v
                            LPS:ApplyOptionsRefresh()
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
                        disabled = function() return LPS:GetOptionDB().layout.dtshow == false end,
                        get = function() return LPS:GetOptionDB().layout.dtPaddingY end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.dtPaddingY = v
                            LPS:ApplyOptionsRefresh()
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
                                local used = framesUsedInOtherSlots("left1")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left1"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            if v == "none" then LPS:CascadeClearSlots(ss, "left", 1) end
                            ss.userTouched = ss.userTouched or {}
                            ss.userTouched["left1"] = true
                            LPS:ApplyOptionsRefresh()
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
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left1"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left1"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
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
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left1"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left1"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
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
                                local used = framesUsedInOtherSlots("right1")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right1"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            if v == "none" then LPS:CascadeClearSlots(ss, "right", 1) end
                            ss.userTouched = ss.userTouched or {}
                            ss.userTouched["right1"] = true
                            LPS:ApplyOptionsRefresh()
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
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right1"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right1"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
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
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right1"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right1"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftSlot2 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 2),
                        order = 2.1,
                        name = L.LEFT_SLOT_2,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
                            if LPS.GetSlotKeyList then
                                local used = framesUsedInOtherSlots("left2")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left2"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            if v == "none" then LPS:CascadeClearSlots(ss, "left", 2) end
                            ss.userTouched = ss.userTouched or {}
                            ss.userTouched["left2"] = true
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftOffsetX2 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 2),
                        order = 2.11,
                        name = L.LEFT_OFFSET_X_2,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left2"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left2"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftOffsetY2 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 2),
                        order = 2.12,
                        name = L.LEFT_OFFSET_Y_2,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left2"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left2"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightSlot2 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 2),
                        order = 2.2,
                        name = L.RIGHT_SLOT_2,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
                            if LPS.GetSlotKeyList then
                                local used = framesUsedInOtherSlots("right2")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right2"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            if v == "none" then LPS:CascadeClearSlots(ss, "right", 2) end
                            ss.userTouched = ss.userTouched or {}
                            ss.userTouched["right2"] = true
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightOffsetX2 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 2),
                        order = 2.21,
                        name = L.RIGHT_OFFSET_X_2,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right2"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right2"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightOffsetY2 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 2),
                        order = 2.22,
                        name = L.RIGHT_OFFSET_Y_2,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right2"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right2"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftSlot3 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 3),
                        order = 3.1,
                        name = L.LEFT_SLOT_3,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
                            if LPS.GetSlotKeyList then
                                local used = framesUsedInOtherSlots("left3")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left3"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            local _ss = LPS:GetOptionDB().layout.sideSlots
                            _ss.userTouched = _ss.userTouched or {}
                            _ss.userTouched["left3"] = true
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftOffsetX3 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 3),
                        order = 3.11,
                        name = L.LEFT_OFFSET_X_3,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left3"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left3"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    leftOffsetY3 = {
                        disabled = LPS:MakeSlotDisabledFunc("left", 3),
                        order = 3.12,
                        name = L.LEFT_OFFSET_Y_3,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left3"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["left3"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightSlot3 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 3),
                        order = 3.2,
                        name = L.RIGHT_SLOT_3,
                        desc = L.SELECT_A_PANEL_FOR_THIS_SLOT,
                        type = "select",
                        values = function()
                            local vals = { none = L.NONE }
                            if LPS.GetSlotKeyList then
                                local used = framesUsedInOtherSlots("right3")
                                for _, k in ipairs(LPS:GetSlotKeyList()) do
                                    if k ~= "none" then
                                        local name = LPS:GetDatatextName(k)
                                        if used[k] and L.FRAME_USED then
                                            name = name .. "  (" .. L.FRAME_USED .. ")"
                                        end
                                        vals[k] = name
                                    end
                                end
                            end
                            return vals
                        end,
                        sorting = function()
                            if LPS.GetSlotKeyList then
                                return LPS:GetSlotKeyList()
                            end
                            return { "none" }
                        end,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right3"]
                            local v = (s and s.frame) or "NONE"
                            if v == "NONE" or v == "None" or v == "" or v == nil then
                                return "none"
                            end
                            return v
                        end,
                        set = function(_, v)
                            local db = LPS:GetOptionDB()
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
                            local _ss = LPS:GetOptionDB().layout.sideSlots
                            _ss.userTouched = _ss.userTouched or {}
                            _ss.userTouched["right3"] = true
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightOffsetX3 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 3),
                        order = 3.21,
                        name = L.RIGHT_OFFSET_X_3,
                        desc = L.SIDE_SLOT_OFFSET_X_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right3"]
                            return tonumber(s and s.offsetX) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right3"]
                            if s then s.offsetX = v end
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    rightOffsetY3 = {
                        disabled = LPS:MakeSlotDisabledFunc("right", 3),
                        order = 3.22,
                        name = L.RIGHT_OFFSET_Y_3,
                        desc = L.SIDE_SLOT_OFFSET_Y_DESC,
                        type = "range",
                        min = -200,
                        max = 200,
                        step = 1,
                        get = function()
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right3"]
                            return tonumber(s and s.offsetY) or 0
                        end,
                        set = function(_, v)
                            local ss = LPS:GetOptionDB().layout.sideSlots
                            local s = ss and ss["right3"]
                            if s then s.offsetY = v end
                            LPS:ApplyOptionsRefresh()
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
                        get = function() return LPS:GetOptionDB().layout.spacingAuto end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.spacingAuto = v
                            LPS:ApplyOptionsRefresh()
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
                        disabled = function() return LPS:GetOptionDB().layout.spacingAuto end,
                        get = function() return LPS:GetOptionDB().layout.spacingManual end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.spacingManual = v
                            LPS:ApplyOptionsRefresh()
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
                        values = LPS:GetStrataValues(),
                        get = function() return LPS:GetOptionDB().layout.frameStrata end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.frameStrata = v
                            LPS:ApplyOptionsRefresh()
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
                        get = function() return tonumber(LPS:GetOptionDB().layout.frameLevel) or 1 end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.frameLevel = v
                            LPS:ApplyOptionsRefresh()
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
                        get = function() return LPS:GetOptionDB().settings.fontSize end,
                        set = function(_, v)
                            LPS:GetOptionDB().settings.fontSize = v
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
                        get = function() return LPS:GetOptionDB().settings.borderSize end,
                        set = function(_, v)
                            LPS:GetOptionDB().settings.borderSize = v
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
                        get = function() return LPS:GetOptionDB().settings.colors.bgEnable end,
                        set = function(_, v)
                            LPS:GetOptionDB().settings.colors.bgEnable = v
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
                            local c = LPS:GetOptionDB().settings.colors.bg
                            return c[1], c[2], c[3], c[4]
                        end,
                        set = function(_, r, g, b, a)
                            local c = LPS:GetOptionDB().settings.colors.bg
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
                            local c = LPS:GetOptionDB().settings.colors.border
                            return c[1], c[2], c[3], c[4]
                        end,
                        set = function(_, r, g, b, a)
                            local c = LPS:GetOptionDB().settings.colors.border
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
                        get = function() return LPS:GetOptionDB().layout.customColor end,
                        set = function(_, v)
                            LPS:GetOptionDB().layout.customColor = v
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                    userColor = {
                        order = 2,
                        name = L.TEXT_CUSTOM_COLOR,
                        desc = L.PICK_A_CUSTOM_COLOR_FOR_PANEL_TEXT,
                        type = "color",
                        default = { r = 1, g = 1, b = 1 },
                        disabled = function() return LPS:GetOptionDB().layout.customColor ~= 1 end,
                        get = function()
                            local c = LPS:GetOptionDB().layout.userColor
                            return (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
                        end,
                        set = function(_, r, g, b)
                            local c = LPS:GetOptionDB().layout.userColor
                            if not c then
                                c = { r = 1, g = 1, b = 1 }
                                LPS:GetOptionDB().layout.userColor = c
                            end
                            c.r, c.g, c.b = r, g, b
                            LPS:ApplyOptionsRefresh()
                        end,
                    },
                },
            },
        }
    }
end
