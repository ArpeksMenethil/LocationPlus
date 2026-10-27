local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local OH = LPS.OptionsHelper

--- Значения dropdown'а тем оформления окна (из таблицы Theme.THEMES).
local function themeItems()
    local Theme = LPS.UI and LPS.UI.Theme
    if not (Theme and Theme.THEMES) then return {} end
    local items = {}
    for _, key in ipairs(Theme.ORDER or {}) do
        if Theme.THEMES[key] then
            items[#items + 1] = { value = key, text = Theme.GetName(key) }
        end
    end
    return items
end

--- Возвращает вкладку "Appearance" дерева настроек (внутренний формат дерева настроек).
--- Тема окна, цвет акцента, цвет фона окна и масштаб.
function LPS.Options.BuildTree.tabs.appearance()
    local Theme = LPS.UI and LPS.UI.Theme
    return {
        name = L.APPEARANCE,
        order = 2,
        args = {
            themeGroup = {
                order = 1,
                name = L.THEME,
                args = {
                    left = {
                        order = 1,
                        name = " ",
                        args = {
                            theme = {
                                type = "select",
                                name = L.THEME_STYLE,
                                desc = L.THEME_STYLE_DESC,
                                order = 1,
                                values = themeItems,
                                get = function()
                                    local db = OH:getDb()
                                    return (db.uiOptions and db.uiOptions.theme) or "modern"
                                end,
                                set = function(_, v)
                                    if Theme and Theme.Set then Theme.Set(v) end
                                end,
                            },
                            windowColorMode = {
                                type = "select",
                                name = L.WINDOW_COLOR_MODE,
                                desc = L.WINDOW_COLOR_MODE_DESC,
                                order = 2,
                                values = {
                                    { value = "theme", text = L.WINDOW_COLOR_BY_THEME },
                                    { value = "custom", text = L.WINDOW_COLOR_CUSTOM },
                                },
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    return (ui and ui.windowColorMode) or "theme"
                                end,
                                set = function(_, v)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.windowColorMode = v
                                end,
                            },
                            windowColor = {
                                type = "color",
                                name = L.WINDOW_COLOR,
                                desc = L.WINDOW_COLOR_DESC,
                                order = 3,
                                default = { r = 0.09, g = 0.10, b = 0.12 },
                                disabled = function()
                                    local ui = OH:getDb().uiOptions
                                    return not (ui and ui.windowColorMode == "custom")
                                end,
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    local c = ui and ui.windowColor
                                    if c and tonumber(c.r) then return c end
                                    return { r = 0.09, g = 0.10, b = 0.12 }
                                end,
                                set = function(_, r, g, b)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.windowColor = { r = r, g = g, b = b }
                                end,
                            },
                            windowColorKeepHeader = {
                                type = "toggle",
                                name = L.WINDOW_COLOR_KEEP_HEADER,
                                desc = L.WINDOW_COLOR_KEEP_HEADER_DESC,
                                order = 4,
                                disabled = function()
                                    local ui = OH:getDb().uiOptions
                                    return not (ui and ui.windowColorMode == "custom")
                                end,
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    return ui and ui.windowColorKeepHeader or false
                                end,
                                set = function(_, v)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.windowColorKeepHeader = v and true or false
                                end,
                            },
                        },
                    },
                    right = {
                        order = 2,
                        name = " ",
                        args = {
                            themeUseClassColor = {
                                type = "toggle",
                                name = L.USE_CLASS_COLOR,
                                desc = L.USE_CLASS_COLOR_DESC,
                                order = 1,
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    return ui and ui.themeUseClassColor or false
                                end,
                                set = function(_, v)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.themeUseClassColor = v and true or false
                                end,
                            },
                            spacer_classColor = {
                                order = 1.5,
                                type = "description",
                                name = "",
                            },
                            themeColor = {
                                type = "select",
                                name = L.THEME_COLOR,
                                desc = L.THEME_COLOR_DESC,
                                order = 2,
                                disabled = function()
                                    local ui = OH:getDb().uiOptions
                                    return ui and ui.themeUseClassColor
                                end,
                                values = function()
                                    if Theme and Theme.GetAccentItems then return Theme.GetAccentItems() end
                                    return {}
                                end,
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    return (ui and ui.themeColor) or "default"
                                end,
                                set = function(_, v)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.themeColor = v
                                end,
                            },
                            accentColor = {
                                type = "color",
                                name = L.ACCENT_COLOR,
                                desc = L.ACCENT_COLOR_DESC,
                                order = 3,
                                default = { r = 0.78, g = 0.66, b = 0.22 },
                                get = function()
                                    local ui = OH:getDb().uiOptions
                                    local c = ui and ui.accentColor
                                    if c and tonumber(c.r) then return c end
                                    if Theme and Theme.GetAccentColor then
                                        local r, g, b = Theme.GetAccentColor()
                                        if r then return { r = r, g = g, b = b } end
                                    end
                                    return { r = 0.78, g = 0.66, b = 0.22 }
                                end,
                                set = function(_, r, g, b)
                                    local db = OH:getDb()
                                    db.uiOptions = db.uiOptions or {}
                                    db.uiOptions.accentColor = { r = r, g = g, b = b }
                                end,
                            },
                        },
                    },
                },
            },
            sizeGroup = {
                order = 2,
                name = L.SIZE_AND_SCALE,
                args = {
                    scale = {
                        type = "range",
                        name = L.WINDOW_SCALE,
                        desc = L.WINDOW_SCALE_DESC,
                        order = 1,
                        min = 0.7,
                        max = 1.6,
                        step = 0.05,
                        bigStep = 0.05,
                        get = function()
                            local ui = OH:getDb().uiOptions
                            return (ui and tonumber(ui.scale)) or 1.0
                        end,
                        set = function(_, v)
                            local Panel = LPS.UI and LPS.UI.Panel
                            if Panel and Panel.SetWindowScale then
                                Panel.SetWindowScale(v)
                            else
                                local db = OH:getDb()
                                db.uiOptions = db.uiOptions or {}
                                db.uiOptions.scale = v
                            end
                        end,
                    },
                    resetAppearance = {
                        type = "execute",
                        name = L.RESET_APPEARANCE,
                        desc = L.RESET_APPEARANCE_DESC,
                        order = 2,
                        func = function()
                            local db = OH:getDb()
                            db.uiOptions = db.uiOptions or {}
                            db.uiOptions.theme = nil
                            db.uiOptions.themeColor = nil
                            db.uiOptions.themeUseClassColor = nil
                            db.uiOptions.accentColor = nil
                            db.uiOptions.windowColorMode = nil
                            db.uiOptions.windowColor = nil
                            db.uiOptions.windowColorKeepHeader = nil
                            db.uiOptions.scale = 1.0
                            if Theme and Theme.Set then Theme.Set("modern") end
                            local Panel = LPS.UI and LPS.UI.Panel
                            if Panel and Panel.GetFrame and Panel.GetFrame() and Panel.GetFrame():IsShown() then
                                Panel.SetWindowScale(1.0)
                            end
                        end,
                    },
                },
            },
        },
    }
end
