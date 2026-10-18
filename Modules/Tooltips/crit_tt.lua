local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildCritTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local st = (LPS._dtState or {}).crit or {}
    local critMelee, ratingIndex = st.critMelee or 0, st.ratingIndex or (CR_CRIT_MELEE or 1)

                        tt:AddLine(string.format("|cffFFFFFF%s:|r %.2f%%", MELEE_CRIT_CHANCE or "Melee", critMelee))
                        if GetCombatRatingBonus and ratingIndex then
                                local rating = GetCombatRating and GetCombatRating(ratingIndex) or 0
                                tt:AddDoubleLine(CR_CRIT_TOOLTIP or "Crit Rating", format("%.2f%% from %d", GetCombatRatingBonus(ratingIndex) or 0, rating or 0), 1, 1, 1, 1, 1, 1)
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
