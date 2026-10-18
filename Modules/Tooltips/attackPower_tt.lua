local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildAttackPowerTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local st = (LPS._dtState or {}).attackPower or {}
    local totalAP, baseAPText, isHunter = st.totalAP, st.baseAPText, st.isHunter

                        tt:AddLine(isHunter and (RANGED_ATTACK_POWER or "Ranged Attack Power") or (MELEE_ATTACK_POWER or "Attack Power"), 1, 0.82, 0)
                        if totalAP then
                                tt:AddDoubleLine(" ", tostring(math.floor(totalAP)), 1, 1, 1, 1, 1, 1)
                        else
                                tt:AddDoubleLine(" ", "|cFF888888" .. tostring(baseAPText or "?") .. "|r", 1, 1, 1, 1, 1, 1)
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
