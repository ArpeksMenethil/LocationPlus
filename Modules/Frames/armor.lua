local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Armor
do
local armorStale
LPS:RegisterDatatext({
key = "armor",
name = LPS:L("Armor"),
-- UNIT_ARMOR не существует в WoW API. Для отслеживания смены экипировки
-- используем PLAYER_EQUIPMENT_CHANGED (основное событие надевания/снятия
-- предметов), EQUIPMENT_SETS_CHANGED и UNIT_INVENTORY_CHANGED как страховку.
events = { "PLAYER_EQUIPMENT_CHANGED", "EQUIPMENT_SETS_CHANGED", "UNIT_INVENTORY_CHANGED", "PLAYER_ENTERING_WORLD" },
update = function(f)
local _, effective = UnitArmor("player")
if DT.NotSecret(effective) then armorStale = effective end
local value = DT.NotSecret(effective) and effective or armorStale
if f.text then
f.text:SetText(string.format("%s: %d", LPS:L("Armor"), math.floor(value or 0)))
end
end,
})
end
