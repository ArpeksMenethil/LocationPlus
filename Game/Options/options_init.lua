local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

LPS.Options = LPS.Options or {}
LPS.Options.BuildTree = LPS.Options.BuildTree or {}
LPS.Options.BuildTree.tabs = LPS.Options.BuildTree.tabs or {}

--- Единая точка применения настроек: инвалидация кэша, пересчёт layout,
--- обновление нативного окна опций.
function LPS:ApplyOptionsRefresh()
    if LPS.RefreshAfterProfileChange then
        LPS:RefreshAfterProfileChange()
    end
    if LPS.RefreshOptionWindowPage then
        LPS:RefreshOptionWindowPage()
    end
end

--- Запись значения по «точечному» пути в БД ("general.is24H").
--- @param path string
--- @param value any
function LPS:SetOptionByPath(path, value)
    local db = LPS:GetDB()
    if not db or type(path) ~= "string" then return end
    local cur, segs = db, {}
    for seg in path:gmatch("[^%.]+") do segs[#segs + 1] = seg end
    for i = 1, #segs - 1 do
        cur[segs[i]] = cur[segs[i]] or {}
        cur = cur[segs[i]]
    end
    cur[segs[#segs]] = value
    LPS:ApplyOptionsRefresh()
end

--- Собирает и возвращает полное дерево настроек.
function LPS:GetOptionsTree()
    local tabs = LPS.Options.BuildTree.tabs
    return {
        name = LPS.addon.title .. " v" .. LPS.addon.version,
        childGroups = "tab",
        args = {
            general = tabs.general and tabs.general() or {},
            show = tabs.show and tabs.show() or {},
            tooltip = tabs.tooltip and tabs.tooltip() or {},
            layout = tabs.layout and tabs.layout() or {},
            profiles = tabs.profiles and tabs.profiles() or {},
            about = tabs.about and tabs.about() or {},
        },
    }
end

local aboutAuthor = nil
if LPS.GetAddOnMetadata and LPS.addon and LPS.addon.name then
    aboutAuthor = LPS.GetAddOnMetadata(LPS.addon.name, "Author")
end
if not aboutAuthor or aboutAuthor == "" then
    aboutAuthor = "Arpeks"
end
LPS.Options.aboutAuthor = aboutAuthor
