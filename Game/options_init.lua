local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

LPS.Options = {}
LPS.Options.aceAppName = "LocationPlus"
LPS.Options.BuildTree = LPS.Options.BuildTree or {}
LPS.Options.BuildTree.tabs = {}

--- Единая точка применения настроек: инвалидация кэша, пересчёт layout,
--- обновление окон AceConfigDialog и нативного UI. Работает и без Ace3.
function LPS.Options:ApplyRefresh()
if LPS.RefreshAfterProfileChange then
LPS:RefreshAfterProfileChange()
end
if OH.Ace.Registry and OH.Ace.Registry.NotifyChange then
OH.Ace.Registry:NotifyChange(self.aceAppName)
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

--- Собирает и возвращает полное дерево настроек (формат AceConfig-3.0).
function LPS.Options:GetTree()
local tabs = self.BuildTree.tabs
return {
type = "group",
name = LPS.addon.title .. " v" .. LPS.addon.version,
childGroups = "tab",
args = {
general = tabs.general(),
show = tabs.show(),
tooltip = tabs.tooltip(),
layout = tabs.layout(),
profiles = tabs.profiles(),
importexport = tabs.importexport(),
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
