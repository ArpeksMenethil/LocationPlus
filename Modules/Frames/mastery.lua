local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Mastery
do
        local mastery
        LPS:RegisterDatatext({
                key = "mastery",
                name = STAT_MASTERY or "Mastery",
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        LPS._dtState = LPS._dtState or {}
                        LPS._dtState.masteryVal = nil
                        mastery = GetMasteryEffect and select(1, GetMasteryEffect()) or 0
                        LPS._dtState.masteryVal = mastery
                        if f.text then
                                f.text:SetText(string.format("%.2f%%", mastery))
                        end
                end,
        })
end
