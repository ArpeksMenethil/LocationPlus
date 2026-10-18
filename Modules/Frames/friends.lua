local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Friends
do
	local friendOnlinePattern = ERR_FRIEND_ONLINE_SS and (ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "")) or nil

	LPS:RegisterDatatext({
		key = "friends",
		nameKey = "Friends",
		events = { "FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_INFO_CHANGED", "CHAT_MSG_SYSTEM" },
		update = function(f)
			-- Как в ElvUI: онлайн-счётчик берём из C_FriendList.GetNumOnlineFriends
			-- (ручной обход списка — только если API недоступен).
			local online = 0
			if C_FriendList and C_FriendList.GetNumOnlineFriends then
				online = C_FriendList.GetNumOnlineFriends() or 0
			elseif C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
				for i = 1, C_FriendList.GetNumFriends() or 0 do
					local info = C_FriendList.GetFriendInfoByIndex(i)
					if info and info.connected then online = online + 1 end
				end
			end
			if f.text then
				f.text:SetText(string.format("%s: %d", FRIENDS, online))
			end
		end,
		onClick = function()
			if ToggleFriendsFrame then ToggleFriendsFrame(1) end
		end,
	})
end
