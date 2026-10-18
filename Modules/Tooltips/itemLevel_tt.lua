local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildItemLevelTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                if not GetAverageItemLevel then return end
                                local avg, avgEquipped, avgPvp = GetAverageItemLevel()
                                tt:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL, string.format("%.2f", avg or 0), 1, 1, 1, 1, 1, 1)
                                tt:AddDoubleLine(LPS:L("Equipped"), string.format("%.2f", avgEquipped or avg or 0), 1, 1, 1, 1, 1, 1)
                                if avgPvp then
                                        tt:AddDoubleLine(PVP_LEVEL, string.format("%.2f", avgPvp), 1, 1, 1, 1, 1, 1)
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
