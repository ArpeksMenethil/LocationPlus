local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildMailTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

        			tt:AddLine(MAIL_LABEL, 1, 0.82, 0)
        			tt:AddLine(" ")
        			local senders = { GetLatestThreeSenders and GetLatestThreeSenders() or nil }
        			local any = false
        			for _, s in ipairs(senders) do
        				if s then tt:AddLine(s, 1, 1, 1); any = true end
        			end
        			if not any then
        				tt:AddLine(LPS:L("No mail"), 0.65, 0.65, 0.65)
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
