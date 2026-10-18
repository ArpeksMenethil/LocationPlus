local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildGuildTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

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
                                local limit = (DT.tooltipCfg("guild") or {}).maxLimit or 15
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
