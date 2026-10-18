local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildHpsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local st = LPS._combatStats or {}
    local healTotal, combatTime = st.heal or 0, st.time or 0

                        tt:AddLine(LPS:L("HPS"), 1, 0.82, 0)
                        tt:AddLine(" ")
                        tt:AddDoubleLine(LPS:L("Healing:"), DT.shortValue(healTotal), 1, 1, 1, 1, 1, 1)
                        tt:AddDoubleLine(LPS:L("Time:"), string.format("%.0f s", combatTime), 1, 1, 1, 1, 1, 1)
                        tt:AddLine(" ")
                        tt:AddLine(LPS:L("Click") .. ": " .. LPS:L("Reset counters"), 0.65, 0.65, 0.65)

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
