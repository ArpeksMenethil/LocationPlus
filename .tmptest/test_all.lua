-- Прогон ВСЕХ вкладок дерева настроек через реальный Builder (mock WoW API).
local frameMT = {}
frameMT.__index = function(self, key)
    local v = rawget(self, key)
    if v ~= nil then return v end
    if key == "GetWidth" or key == "GetHeight" or key == "GetStringWidth" or key == "GetStringHeight" or key == "GetTextHeight" then
        return function() return 100 end
    end
    if key == "CreateFontString" or key == "CreateTexture" then
        return function() return setmetatable({}, frameMT) end
    end
    if key == "GetText" then return function() return "" end end
    if key == "GetVerticalScroll" then return function() return 0 end end
    return function() end
end
_G.CreateFrame = function(ft, name, parent) return setmetatable({tag = ft}, frameMT) end
_G.UIParent = setmetatable({}, frameMT)
_G.GetLocale = function() return "enUS" end
_G.C_Timer = { After = function() end }
_G.GameTooltip = setmetatable({}, frameMT)
local namespace = {} _G.ArpeksLPS = namespace
local LPS = {
    addon = { title = "Location Plus", version = "1.0.0", name = "ArpeksLPS" },
    Print = function() end,
    db = { profile = { show = { minimap = {}, visibility = {} }, general = {}, layout = { sideSlots = {} } }, SetProfile = function() end, GetCurrentProfile = function() return "Default" end },
}
namespace.LPS = LPS
LPS.GetDB = function(self) return LPS.db.profile end
LPS.icons = setmetatable({}, {__index = function() return "tex" end})
assert(loadfile("/workspace/Locales/enUS.lua"))("ArpeksLPS", LPS)
assert(loadfile("/workspace/Game/options_helper.lua"))("ArpeksLPS", LPS)
assert(loadfile("/workspace/Game/options.lua"))("ArpeksLPS", LPS)
for _, f in ipairs({"general","show","tooltip","layout","profiles","importexport","about"}) do
    assert(loadfile("/workspace/Game/Options/"..f..".lua"))("ArpeksLPS", LPS)
end
assert(loadfile("/workspace/Game/ui_options.lua"))("ArpeksLPS", LPS)
assert(loadfile("/workspace/Game/UI/Builder.lua"))("ArpeksLPS", LPS)
local registered = {}
LPS.UI = LPS.UI or {}
LPS.UI.Panel = {
    RegisterPage = function(key, def) registered[key] = def end,
    CreateScrollPage = function(container)
        local content = setmetatable({}, frameMT); content.rows = {}
        return setmetatable({}, frameMT), content
    end,
    IsShown = function() return false end, OnSettingChanged = function() end,
}
LPS.UI.Theme = { key = "classic" }
LPS.UI.ConfigWidgets = setmetatable({}, {__index = function(t, k)
    return function(...)
        if k == "CreateFlatButton" then
            local btn = setmetatable({ text = setmetatable({}, frameMT) }, frameMT); return btn
        end
        if k == "CreateToggle" then
            local tg = setmetatable({}, frameMT); tg.text = setmetatable({}, frameMT); return tg
        end
        if k == "CreateDropdown" then return nil, setmetatable({}, frameMT) end
        if k == "CreateSectionHeader" or k == "CreateSwatch" then return setmetatable({}, frameMT) end
        return nil
    end
end})
assert(loadfile("/workspace/Game/options_init.lua"))("ArpeksLPS", LPS)
LPS.UI_Options.BuildPages()
local container = setmetatable({}, frameMT)
local names = {"general","show","tooltip","layout","profiles","importexport","about"}
for _, id in ipairs(names) do
    local def = registered["tree_"..id]
    if not def then print("MISSING PAGE:", id) else
        local ok, err = pcall(function()
            local page = def.create(container)
            page:Build(true)
            assert(page._built, "not built (empty rows?)")
            page:Refresh()
        end)
        print(string.format("%-12s %s %s", id, ok and "OK" or "FAIL", ok and "" or tostring(err)))
    end
end
