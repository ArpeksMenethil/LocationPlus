local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT
local F = LPS.F

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

            local function refresh()
                local panel = LPS.frame and LPS.frame.friends
                if panel and panel._lpsUpdateFunc and not IsAltKeyDown() then
                    panel._lpsUpdateFunc(panel)
                end
            end

            local function onFriendsEvent(event, arg1)
                if event == 'CHAT_MSG_SYSTEM' then
                    if type(arg1) == 'string' and friendOnline
                        and (string.find(arg1, friendOnline, 1, true) or string.find(arg1, friendOffline, 1, true)) then
                        refresh()
                    end
                    return
                end

                if event == 'MODIFIER_STATE_CHANGED' then
                    return
                end

                refresh()
            end

            -- Foundry.Events: один контроллер на все события Friends-панели.
            -- create() вызывается вне боёвки (в бою ставится в очередь),
            -- поэтому регистрация событий безопасна.
            -- Не все события валидны на каждом клиенте
            -- (BN_RECONNECT/BN_DISCONNECT — только Retail):
            -- фильтруем через IsEventValid.
            local function eventValid(ev)
                return C_EventUtils.IsEventValid(ev)
            end

            local events = F.Events:New("LPS.Friends")
            for _, ev in ipairs({
                'PLAYER_ENTERING_WORLD', 'FRIENDLIST_UPDATE',
                'BN_FRIEND_ACCOUNT_ONLINE', 'BN_FRIEND_ACCOUNT_OFFLINE',
                'BN_FRIEND_INFO_CHANGED', 'BN_RECONNECT', 'BN_DISCONNECT',
                'MODIFIER_STATE_CHANGED', 'CHAT_MSG_SYSTEM',
            }) do
                if eventValid(ev) then
                    events:Register(ev, onFriendsEvent)
                end
            end
            LPS._friendsEvents = events
        end,
    })
end
