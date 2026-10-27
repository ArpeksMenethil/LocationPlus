local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

--------------------------------------------------------------------
--------------------------------------------------------------------
do
    local format, select = string.format, select

    local BNGetNumFriends = BNGetNumFriends
    local IsAltKeyDown = IsAltKeyDown
    local ToggleFriendsFrame = ToggleFriendsFrame

    local CF_GetNumOnlineFriends = C_FriendList and C_FriendList.GetNumOnlineFriends

    LPS:RegisterDatatext({
        key = "friends",
        nameKey = "Friends",
        events = { 'BN_FRIEND_ACCOUNT_ONLINE', 'BN_FRIEND_ACCOUNT_OFFLINE', 'BN_FRIEND_INFO_CHANGED', 'FRIENDLIST_UPDATE', 'CHAT_MSG_SYSTEM' },
        update = function(f)
            -- ElvUI OnEvent: счётчик = wow-онлайн + BNet-онлайн
            local onlineFriends = (CF_GetNumOnlineFriends and CF_GetNumOnlineFriends()) or 0
            local numBNetOnline = 0
            if BNGetNumFriends then
                numBNetOnline = select(2, BNGetNumFriends()) or 0
            end
            if f.text then
                f.text:SetText(format('%s: |cFFFFFFFF%d|r', FRIENDS, onlineFriends + numBNetOnline))
            end
        end,
        onClick = function(self, button)
            if button ~= 'LeftButton' then return end
            if ToggleFriendsFrame then
                ToggleFriendsFrame(1)
            end
        end,
        create = function()
            local friendOffline = ERR_FRIEND_OFFLINE_S and (string.gsub(ERR_FRIEND_OFFLINE_S, '%%s', '')) or ''
            local friendOnline = ERR_FRIEND_ONLINE_SS and (string.gsub(ERR_FRIEND_ONLINE_SS, '|Hplayer:%%s|h%%[%%s%%]|h', '')) or nil

            local bridge = CreateFrame('Frame')
            bridge:RegisterEvent('PLAYER_ENTERING_WORLD')
            bridge:RegisterEvent('FRIENDLIST_UPDATE')
            bridge:RegisterEvent('BN_FRIEND_ACCOUNT_ONLINE')
            bridge:RegisterEvent('BN_FRIEND_ACCOUNT_OFFLINE')
            bridge:RegisterEvent('BN_FRIEND_INFO_CHANGED')
            bridge:RegisterEvent('BN_RECONNECT')
            bridge:RegisterEvent('BN_DISCONNECT')
            bridge:RegisterEvent('MODIFIER_STATE_CHANGED')
            bridge:RegisterEvent('CHAT_MSG_SYSTEM')
            bridge:SetScript('OnEvent', function(_, event, arg1)
                if event == 'CHAT_MSG_SYSTEM' then
                    if type(arg1) == 'string' and friendOnline and (string.find(arg1, friendOnline, 1, true) or string.find(arg1, friendOffline, 1, true)) then
                        local panel = LPS.frame and LPS.frame.friends
                        if panel and panel._lpsUpdateFunc and not IsAltKeyDown() then
                            panel._lpsUpdateFunc(panel)
                        end
                    end
                    return
                end

                if event == 'MODIFIER_STATE_CHANGED' then
                    return
                end

                local panel = LPS.frame and LPS.frame.friends
                if panel and panel._lpsUpdateFunc and not IsAltKeyDown() then
                    panel._lpsUpdateFunc(panel)
                end
            end)
        end,
    })
end
