local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Crit Chance
do
        local critMelee, spellIndex, ratingIndex = 0, 0, CR_CRIT_MELEE or 1
        LPS:RegisterDatatext({
                key = "crit",
                name = MELEE_CRIT_CHANCE or "Melee Crit Chance",
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        critMelee = GetCritChance() or 0
                        LPS._dtState = LPS._dtState or {}
                        LPS._dtState.crit = { critMelee = critMelee, ratingIndex = ratingIndex }
                        local text = critMelee
                        if GetRangedCritChance then
                                local critRanged = GetRangedCritChance() or 0
                                if critRanged > critMelee then text = critRanged end
                        end
                        if GetSpellCritChance then
                                local minimum = GetSpellCritChance(2)
                                if DT.NotSecret(minimum) then
                                        for i = 3, (MAX_SPELL_SCHOOLS or 7) do
                                                local chance = GetSpellCritChance(i)
                                                if DT.NotSecret(chance) and chance < minimum then
                                                        minimum = chance
                                                end
                                        end
                                        text = minimum
                                end
                        end
                        if f.text then
                                f.text:SetText(string.format("%.2f%%", text))
                        end
                end,
        })
end
