local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

-------------------------------------------------- Mail
do
    LPS:RegisterDatatext({
        key = "mail",
        nameKey = "MAIL",
        events = { "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_CLOSED", "MAIL_SHOW" },
        update = function(f)
            local has = HasNewMail and HasNewMail()
            if f.text then
                f.text:SetText(has and ("|cFFFFFF00" .. (L.NEW_MAIL) .. "|r")
                or (L.NO_MAIL))
            end
        end,
    })
end
