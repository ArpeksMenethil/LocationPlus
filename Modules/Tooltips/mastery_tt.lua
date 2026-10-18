local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildMasteryTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local mastery = (LPS._dtState or {}).masteryVal

                        tt:AddLine((STAT_MASTERY or "Mastery") .. ": " .. string.format("%.2f%%", mastery or 0), 1, 0.82, 0)
                        if GetCombatRating and GetCombatRatingBonus and CR_MASTERY then
                                local rating = GetCombatRating(CR_MASTERY) or 0
                                tt:AddDoubleLine(LPS:L("Rating"), tostring(rating), 1, 1, 1, 1, 1, 1)
                                tt:AddDoubleLine(LPS:L("Bonus"), string.format("%.2f%%", GetCombatRatingBonus(CR_MASTERY) or 0), 1, 1, 1, 1, 1, 1)
                        end

end
