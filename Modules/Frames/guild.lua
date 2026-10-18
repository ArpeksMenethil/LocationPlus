local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Guild
do
	LPS:RegisterDatatext({
		key = "guild",
		name = LPS:L("Guild"),
		events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD", "CHAT_MSG_SYSTEM" },
		update = function(f)
			if not IsInGuild or not IsInGuild() then
				if f.text then f.text:SetText(LPS:L("No Guild")) end
				return
			end
			local total, _, online = GetNumGuildMembers()
			if f.text then
				f.text:SetText(string.format("%s: %d/%d", GUILD or LPS:L("Guild"), online or 0, total or 0))
			end
		end,
		onClick = function()
			if not InCombatLockdown() and ToggleGuildFrame then
				ToggleGuildFrame()
			end
		end,
tooltip = function(tt)
        			if not IsInGuild or not IsInGuild() then return end
        			local guildName, guildRank = GetGuildInfo("player")
        			local total, _, online = GetNumGuildMembers()
        			tt:AddDoubleLine(guildName or "", string.format("%d/%d", online or 0, total or 0), 0.4, 0.78, 1, 0.4, 0.78, 1)
        			if guildRank then tt:AddLine(guildRank, 0.4, 0.78, 1) end
        			local motd = C_GuildInfo and C_GuildInfo.GetMOTD and C_GuildInfo.GetMOTD() or (GetGuildRosterMOTD and GetGuildRosterMOTD())
        			if motd and motd ~= "" then
        				tt:AddLine(" ")
        				tt:AddLine(GUILD_MOTD .. ": " .. motd, 0.75, 0.9, 1)
        			end
        			tt:AddLine(" ")
        			local limit = (DT.panelCfg("guild") or {}).maxLimit or 15
        			local shown = 0
        			for i = 1, total or 0 do
        				local name, rank, rankIndex, level, classLocal, zone, _, _, connected, _, classFile = GetGuildRosterInfo(i)
        				if name and connected then
        					shown = shown + 1
        					if shown <= limit then
        						tt:AddDoubleLine(
        							string.format("%s%d|r %s", DT.levelColorHex(level), level, name),
        							classLocal or "", 1, 1, 1,
        							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.r or 1 end)(),
        							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.g or 1 end)(),
        							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.b or 1 end)())
        					end
        				end
        			end
        			if shown == 0 then
        				tt:AddLine(LPS:L("No members online"), 0.65, 0.65, 0.65)
        			end
		end,
	})
end
