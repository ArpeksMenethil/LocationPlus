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

    tt:AddLine(" ")
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open mailbox"), rB, gB, bB, rB, gB, bB)
end
