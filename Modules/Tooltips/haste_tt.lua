local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildHasteTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local haste = (LPS._dtState or {}).hasteVal

                        tt:AddLine((STAT_HASTE or "Haste") .. ": " .. string.format("%+d%%", haste or 0), 1, 0.82, 0)
                        if GetCombatRating and GetCombatRatingBonus and CR_HASTE_MELEE then
                                local rating = GetCombatRating(CR_HASTE_MELEE) or 0
                                tt:AddDoubleLine(LPS:L("Rating"), tostring(rating), 1, 1, 1, 1, 1, 1)
                                tt:AddDoubleLine(LPS:L("Bonus"), string.format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE) or 0), 1, 1, 1, 1, 1, 1)
                        end

end
