local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Spell Power
do
        local MAX_SCHOOLS = MAX_SPELL_SCHOOLS or 7
        local lastSchool = 2
        LPS:RegisterDatatext({
                key = "spellPower",
                name = SPELL_POWER or "Spell Power",
                events = { "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UNIT_STATS" },
                update = function(f)
                        local minSP, schoolIdx
                        for i = 2, MAX_SCHOOLS do
                                local value = GetSpellBonusDamage and GetSpellBonusDamage(i)
                                if value and DT.NotSecret(value) then
                                        if not minSP or value < minSP then
                                                minSP, schoolIdx = value, i
                                        end
                                end
                        end
                        if minSP then
                                lastSchool = schoolIdx
                        else
                                minSP = 0
                        end
                        if f.text then
                                f.text:SetText(string.format("%s: %d", SPELL_POWER or "Spell Power", math.floor(minSP)))
                        end
                end,
        })
end
