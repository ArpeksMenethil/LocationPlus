local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildFriendsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(FRIENDS, 1, 0.82, 0)
                                tt:AddLine(" ")
                                local shown = 0
                                local limit = (DT.tooltipCfg("friends") or {}).maxLimit or 15
                                if C_FriendList and C_FriendList.GetFriendInfoByIndex and C_FriendList.GetNumFriends then
                                        for i = 1, C_FriendList.GetNumFriends() or 0 do
                                                local info = C_FriendList.GetFriendInfoByIndex(i)
                                                if info and info.connected then
                                                        shown = shown + 1
                                                        if shown <= limit then
                                                                local status = ""
                                                                if info.afk then status = " |cFFFF9900[" .. LPS:L("AFK") .. "]|r"
                                                                elseif info.dnd then status = " |cFFFF3333[" .. LPS:L("DND") .. "]|r" end
                                                                tt:AddDoubleLine(string.format("|cff%02x%02x%02x%d|r %s%s", 255, 255, 255, info.level or 0, info.name, status),
                                                                        info.className or "", 1, 1, 1, 1, 1, 1)
                                                        end
                                                end
                                        end
                                end
                                if shown == 0 then
                                        tt:AddLine(LPS:L("No friends online"), 0.65, 0.65, 0.65)
                                elseif shown > limit then
                                        tt:AddLine(string.format("+%d ...", shown - limit), 0.75, 0.9, 1)
                                end

    tt:AddLine(" ")
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open friends list"), rB, gB, bB, rB, gB, bB)
end
