local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildSpellPowerTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                        tt:AddLine(SPELL_POWER, 1, 0.82, 0)
                        for i = 2, (MAX_SPELL_SCHOOLS or 7) do
                                local value = GetSpellBonusDamage and GetSpellBonusDamage(i)
                                if value and DT.NotSecret(value) then
                                        tt:AddDoubleLine(_G["SCHOOL_" .. i .. "_NAME"] or ("School " .. i), tostring(math.floor(value)), 1, 1, 1, 1, 1, 1)
                                end
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
