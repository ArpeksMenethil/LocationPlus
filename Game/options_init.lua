local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

-- Не пересоздаём LPS.Options: в options.lua и Game/Options/*.lua
-- фабрики вкладок уже зарегистрированы в LPS.Options.BuildTree.tabs.
LPS.Options = LPS.Options or {}
LPS.Options.aceAppName = "LocationPlus"
LPS.Options.BuildTree = LPS.Options.BuildTree or {}
LPS.Options.BuildTree.tabs = LPS.Options.BuildTree.tabs or {}

--- Единая точка применения настроек: инвалидация кэша, пересчёт layout,
--- обновление нативного окна опций (Ace3 больше не используется).
function LPS.Options:ApplyRefresh()
if LPS.RefreshAfterProfileChange then
LPS:RefreshAfterProfileChange()
end
if LPS.UI_Options and LPS.UI_Options.RefreshActivePage then
LPS.UI_Options:RefreshActivePage()
end
end

--- Запись значения по «точечному» пути в БД ("general.is24H").
function LPS.Options:SetByPath(path, value)
local db = LPS:GetDB()
if not db or type(path) ~= "string" then return end
local cur, segs = db, {}
for seg in path:gmatch("[^%.]+") do segs[#segs + 1] = seg end
for i = 1, #segs - 1 do
cur[segs[i]] = cur[segs[i]] or {}
cur = cur[segs[i]]
end
cur[segs[#segs]] = value
self:ApplyRefresh()
end

--- Собирает и возвращает полное дерево настроек (внутренний формат дерева настроек).
function LPS.Options:GetTree()
local tabs = self.BuildTree.tabs
return {
name = LPS.addon.title .. " v" .. LPS.addon.version,
childGroups = "tab",
args = {
general = tabs.general and tabs.general() or {},
show = tabs.show and tabs.show() or {},
tooltip = tabs.tooltip and tabs.tooltip() or {},
layout = tabs.layout and tabs.layout() or {},
appearance = tabs.appearance and tabs.appearance() or {},
profiles = tabs.profiles and tabs.profiles() or {},
importexport = tabs.importexport and tabs.importexport() or {},
about = tabs.about and tabs.about() or {},
},
}
end

local aboutAuthor = nil
if GetAddOnMetadata and LPS.addon and LPS.addon.name then
aboutAuthor = GetAddOnMetadata(LPS.addon.name, "Author")
end
if not aboutAuthor or aboutAuthor == "" then
aboutAuthor = "Arpeks"
end
LPS.Options.aboutAuthor = aboutAuthor
