local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Friends
do
	local friendOnlinePattern = ERR_FRIEND_ONLINE_SS and (ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "")) or nil

	LPS:RegisterDatatext({
		key = "friends",
		name = LPS:L("Friends"),
		events = { "FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_INFO_CHANGED", "CHAT_MSG_SYSTEM" },
		update = function(f)
			local online = 0
			if C_FriendList and C_FriendList.GetNumOnlineFriends then
				online = C_FriendList.GetNumOnlineFriends() or 0
			end
			if BNConnected and BNConnected() and BNGetNumFriends then
				online = online + (select(2, BNGetNumFriends()) or 0)
			end
			if f.text then
				f.text:SetText(string.format("%s: %d", FRIENDS or LPS:L("Friends"), online))
			end
		end,
		onClick = function()
			if ToggleFriendsFrame then ToggleFriendsFrame(1) end
		end,
tooltip = function(tt)
        			tt:AddLine(FRIENDS or LPS:L("Friends"), 1, 0.82, 0)
        			tt:AddLine(" ")
        			local shown = 0
        			local limit = (DT.panelCfg("friends") or {}).maxLimit or 15
        			if C_FriendList and C_FriendList.GetFriendInfoByIndex and C_FriendList.GetNumFriends then
        				for i = 1, C_FriendList.GetNumFriends() or 0 do
        					local info = C_FriendList.GetFriendInfoByIndex(i)
        					if info and info.connected then
        						shown = shown + 1
        						if shown <= limit then
        							local status = ""
        							if info.afk then status = " |cFFFF9900[" .. (LPS:L("AFK") or "AFK") .. "]|r"
        							elseif info.dnd then status = " |cFFFF3333[" .. (LPS:L("DND") or "DND") .. "]|r" end
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
		end,
	})
end
