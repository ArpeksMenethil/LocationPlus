local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Mail
do
	LPS:RegisterDatatext({
		key = "mail",
		name = LPS:L("Mail"),
		events = { "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_CLOSED", "MAIL_SHOW" },
		update = function(f)
			local has = HasNewMail and HasNewMail()
			if f.text then
				f.text:SetText(has and ("|cFFFFFF00" .. (LPS:L("New Mail") or HAVE_MAIL) .. "|r")
					or (LPS:L("No Mail") or "—"))
			end
		end,
tooltip = function(tt)
        			tt:AddLine(MAIL_LABEL or LPS:L("Mail"), 1, 0.82, 0)
        			tt:AddLine(" ")
        			local senders = { GetLatestThreeSenders and GetLatestThreeSenders() or nil }
        			local any = false
        			for _, s in ipairs(senders) do
        				if s then tt:AddLine(s, 1, 1, 1); any = true end
        			end
        			if not any then
        				tt:AddLine(LPS:L("No mail"), 0.65, 0.65, 0.65)
        			end
		end,
	})
end
