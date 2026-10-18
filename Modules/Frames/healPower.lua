local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Heal Power
do
        LPS:RegisterDatatext({
                key = "healPower",
                name = HEALING or "Healing",
                events = { "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UNIT_STATS" },
                update = function(f)
                        local heal = GetSpellHealingBonus and GetSpellHealingBonus(4)
                        if heal and DT.NotSecret(heal) then
                                if f.text then f.text:SetText(string.format("%s: %d", HEALING or "Healing", math.floor(heal))) end
                        else
                                if f.text then f.text:SetText(string.format("%s: |cFF888888?|r", HEALING or "Healing")) end
                        end
                end,
        })
end
