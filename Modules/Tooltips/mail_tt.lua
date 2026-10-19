local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

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
        				tt:AddLine(LPS:L("NO_MAIL_2"), 0.65, 0.65, 0.65)
        			end

end
