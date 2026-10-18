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

    GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Click"), rB, gB, bB, rB, gB, bB)

        if GameTooltipTextLeft1 then
                local rT, gT, bT = GameTooltipTextLeft1:GetTextColor()
                GameTooltipTextLeft1:SetFontObject(GameTooltipText)
                GameTooltipTextLeft1:SetTextColor(rT, gT, bT)
        end
        if GameTooltipTextRight1 then
                local rT, gT, bT = GameTooltipTextRight1:GetTextColor()
                GameTooltipTextRight1:SetFontObject(GameTooltipText)
                GameTooltipTextRight1:SetTextColor(rT, gT, bT)
        end
end
