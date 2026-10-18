local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Haste
do
        local haste
        LPS:RegisterDatatext({
                key = "haste",
                name = LPS:L("Haste") or STAT_HASTE or "Haste",
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        haste = GetHaste and GetHaste() or 0
                        if f.text then
                                f.text:SetText(string.format("%+d%%", haste))
                        end
                end,
                tooltip = function(tt)
                        tt:AddLine((STAT_HASTE or "Haste") .. ": " .. string.format("%+d%%", haste or 0), 1, 0.82, 0)
                        if GetCombatRating and GetCombatRatingBonus and CR_HASTE_MELEE then
                                local rating = GetCombatRating(CR_HASTE_MELEE) or 0
                                tt:AddDoubleLine(LPS:L("Rating") or "Rating", tostring(rating), 1, 1, 1, 1, 1, 1)
                                tt:AddDoubleLine(LPS:L("Bonus") or "Bonus", string.format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE) or 0), 1, 1, 1, 1, 1, 1)
                        end
                end,
        })
end
