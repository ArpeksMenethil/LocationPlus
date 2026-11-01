local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

-------------------------------------------------- Guild
do
    LPS:RegisterDatatext({
        key = "guild",
        nameKey = "Guild",
        events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD", "CHAT_MSG_SYSTEM" },
        update = function(f)
            if not IsInGuild or not IsInGuild() then
                if f.text then f.text:SetText(L.NO_GUILD) end
                return
            end
            local total, online = GetNumGuildMembers()
            if f.text then
                f.text:SetText(string.format("%s: %d/%d", GUILD, online or 0, total or 0))
            end
        end,
        onClick = function()
            if not InCombatLockdown() and ToggleGuildFrame then
                ToggleGuildFrame()
            end
        end,
    })
end
