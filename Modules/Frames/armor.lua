local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Armor
do
local armorStale
LPS:RegisterDatatext({
key = "armor",
name = ARMOR or "Armor",
events = { "UNIT_armor", "PLAYER_ENTERING_WORLD" },
update = function(f)
local _, effective = UnitArmor("player")
if DT.NotSecret(effective) then armorStale = effective end
local value = DT.NotSecret(effective) and effective or armorStale
if f.text then
f.text:SetText(string.format("%s: %d", ARMOR or "Armor", math.floor(value or 0)))
end
end,
})
end
