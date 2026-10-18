local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildExperienceTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                local level = UnitLevel("player")
                                tt:AddDoubleLine(LPS:L("Experience"), string.format("%s %d", LPS:L("Level"), level), 1, 0.82, 0, 1, 1, 1)
                                tt:AddLine(" ")
                                local cur, max = UnitXP("player"), UnitXPMax("player")
                                if max and max > 0 then
                                        tt:AddDoubleLine(LPS:L("XP:"), string.format("%s / %s (%.2f%%)", DT.shortValue(cur), DT.shortValue(max), cur / max * 100), 1, 1, 1, 1, 1, 1)
                                        tt:AddDoubleLine(LPS:L("Remaining:"), string.format("%s (%.2f%%)", DT.shortValue(max - cur), (max - cur) / max * 100), 1, 1, 1, 1, 1, 1)
                                end
                                local rested = GetXPExhaustion and GetXPExhaustion()
                                if rested and rested > 0 then
                                        tt:AddDoubleLine(LPS:L("Rested:"), "+" .. DT.shortValue(rested), 1, 1, 1, 0, 1, 0)
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
