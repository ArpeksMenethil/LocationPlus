local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Mail
do
	LPS:RegisterDatatext({
		key = "mail",
		nameKey = "Mail",
		events = { "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_CLOSED", "MAIL_SHOW" },
		update = function(f)
			local has = HasNewMail and HasNewMail()
			if f.text then
				f.text:SetText(has and ("|cFFFFFF00" .. (LPS:L("NEW_MAIL")) .. "|r")
					or (LPS:L("NO_MAIL")))
			end
		end,
	})
end
