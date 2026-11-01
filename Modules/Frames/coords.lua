local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local function getDB() return LPS:GetDB() or {} end

LPS:RegisterDatatext({
key = "coords",
nameKey = "Coords",
events = { "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS" },
ticker = math.max(tonumber(getDB().general and getDB().general.coordsTimeUpdate) or 0.2, 0.05),
update = function(f)
local db = getDB()

local x, y = LPS:GetPlayerCoords()
if f.text then
if x and y then
local dig = (db.show and db.show.dig) and 2 or 0
local xf = LPS:Round(x * 100, dig)
local yf = LPS:Round(y * 100, dig)
local newText
if dig == 0 then
newText = string.format("%d | %d", xf, yf)
else
newText = string.format("%.2f | %.2f", xf, yf)
end
if f._lpsLastText ~= newText then
f._lpsLastText = newText
f.text:SetText(newText)
end
elseif f._lpsLastText ~= "N/A" then
f._lpsLastText = "N/A"
f.text:SetText("N/A")
end
end
end,
onClick = function(self, button)
if button == "LeftButton" then
ToggleWorldMap()
if WorldMapFrame then
WorldMapFrame:ClearAllPoints()
WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
end
end
end,
})
