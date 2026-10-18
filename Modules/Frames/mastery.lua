local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Mastery
do
        local mastery
        LPS:RegisterDatatext({
                key = "mastery",
                name = LPS:L("Mastery") or STAT_MASTERY or "Mastery",
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        mastery = GetMasteryEffect and select(1, GetMasteryEffect()) or 0
                        if f.text then
                                f.text:SetText(string.format("%.2f%%", mastery))
                        end
                end,
                tooltip = function(tt)
                        tt:AddLine((STAT_MASTERY or "Mastery") .. ": " .. string.format("%.2f%%", mastery or 0), 1, 0.82, 0)
                        if GetCombatRating and GetCombatRatingBonus and CR_MASTERY then
                                local rating = GetCombatRating(CR_MASTERY) or 0
                                tt:AddDoubleLine(LPS:L("Rating") or "Rating", tostring(rating), 1, 1, 1, 1, 1, 1)
                                tt:AddDoubleLine(LPS:L("Bonus") or "Bonus", string.format("%.2f%%", GetCombatRatingBonus(CR_MASTERY) or 0), 1, 1, 1, 1, 1, 1)
                        end
                end,
        })
end
