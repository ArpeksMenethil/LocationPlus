local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- HPS (лечений в секунду, боевой лог)
do
local subHeal = {
SWING_HEALING = true, RANGE_HEALING = true, SPELL_HEALING = true,
SPELL_PERIODIC_HEALING = true,
}
local combatLogFrame
local lastSegment, timeStamp, combatTime, healTotal = 0, 0, 0, 0

local function getCLE()
return (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo
end

local function ensureLog()
if combatLogFrame then return end
combatLogFrame = CreateFrame("Frame")
combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatLogFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatLogFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
combatLogFrame:RegisterEvent("UNIT_PET")
local myGUID = nil
combatLogFrame:SetScript("OnEvent", function(self, event)
if event == "UNIT_PET" then
myGUID = myGUID or UnitGUID("player")
elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVE_COMBAT" then
local now = time()
if now - lastSegment > 20 then
timeStamp, combatTime, healTotal = 0, 0, 0
end
lastSegment = now
elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
myGUID = myGUID or UnitGUID("player")
local timestamp, subEvent, _, sourceGUID = getCLE()()
if sourceGUID ~= myGUID then return end
if subHeal[subEvent] then
if timeStamp == 0 then timeStamp = timestamp end
lastSegment = timestamp
combatTime = timestamp - timeStamp
local amount, overhealing
if subEvent == "SWING_HEALING" then
amount, _, _, _, _, _, _, _, _, overhealing = select(10, getCLE()())
else
amount, _, _, _, _, _, overhealing = select(12, getCLE()())
end
healTotal = healTotal + math.max(0, (amount or 0) - (overhealing or 0))
                        LPS._combatStats = { dmg = 0, heal = healTotal, time = combatTime }

end
end
end)
end

LPS:RegisterDatatext({
key = "hps",
name = LPS:L("HPS"),
ticker = 0.5,
create = function(f)
ensureLog()
end,
update = function(f)
if f.text then
f.text:SetText(string.format("%s: %s", LPS:L("HPS"), DT.shortValue(combatTime > 0 and (healTotal / combatTime) or 0)))
end
end,
onClick = function(self)
timeStamp, combatTime, healTotal = 0, 0, 0
if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end
end,
})
end
