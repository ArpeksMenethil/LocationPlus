local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Crit Chance
do
        local critMelee, spellIndex, ratingIndex = 0, 0, CR_CRIT_MELEE or 1
        LPS:RegisterDatatext({
                key = "crit",
                name = LPS:L("Crit Chance") or CR_CRIT_CHANCE or "Crit",
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        critMelee = GetCritChance() or 0
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
                tooltip = function(tt)
                        tt:AddLine(string.format("|cffFFFFFF%s:|r %.2f%%", MELEE_CRIT_CHANCE or "Melee", critMelee))
                        if GetCombatRatingBonus and ratingIndex then
                                local rating = GetCombatRating and GetCombatRating(ratingIndex) or 0
                                tt:AddDoubleLine(CR_CRIT_TOOLTIP or "Crit Rating", format("%.2f%% from %d", GetCombatRatingBonus(ratingIndex) or 0, rating or 0), 1, 1, 1, 1, 1, 1)
                        end
                end,
        })
end
