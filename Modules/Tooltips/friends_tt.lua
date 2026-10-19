local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

--------------------------------------------------------------------
-- Подсказка друзей по образцу ElvUI (DataTexts/Friends.lua OnEnter).
-- ВАЖНО: в списке показываем ВСЕХ друзей в сети, а не только тех,
-- кто сейчас в World of Warcraft:
--   * wow-друзья (friends list) — C_FriendList.GetFriendInfoByIndex().connected;
--   * Battle.net-друзья — онлайн аккаунта ИЛИ любого игрового аккаунта
--     (друг может быть онлайн в BNet-приложении, мобильном клиенте или
--     другой игре Blizzard: HS, OW, D3/D4, SC2, WC3 и т.д.).
-- Счётчик «В сети: X/Y» считается из BNGetNumFriends/BNSetFilters так же,
-- как счётчик на панели (Modules/Frames/friends.lua), чтобы цифры совпадали.
-- ПКМ-меню нет по требованию пользователя — ЛКМ открывает стандартный фрейм.
--------------------------------------------------------------------

do
    local format, gsub, strmatch, tinsert, tremove =
        string.format, string.gsub, string.match, table.insert, table.remove
    local wipe = table.clear or wipe -- WoW-глобалка (в т.ч. Classic Era); в чистом Lua 5.1 её нет
    local sort, next, ipairs, pairs = table.sort, next, ipairs, pairs

    local BNConnected = BNConnected
    local BNGetNumFriends = BNGetNumFriends
    local IsShiftKeyDown = IsShiftKeyDown

    local GetFriendAccountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
    local GetFriendGameAccountInfo = C_BattleNet and C_BattleNet.GetFriendGameAccountInfo
    local GetFriendNumGameAccounts = C_BattleNet and C_BattleNet.GetFriendNumGameAccounts
    local BNet_GetValidatedCharacterName = BNet_GetValidatedCharacterName
    local CF_GetNumFriends = C_FriendList and C_FriendList.GetNumFriends
    local CF_GetNumOnlineFriends = C_FriendList and C_FriendList.GetNumOnlineFriends
    local CF_GetFriendInfoByIndex = C_FriendList and C_FriendList.GetFriendInfoByIndex

    local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

    local totalOnlineString = FRIENDS_LIST_ONLINE .. ': %s/%s'
    local characterFriend = CHARACTER_FRIEND
    local battleNetString = BATTLENET_OPTIONS_LABEL
    local wowString = BNET_CLIENT_WOW
    local EXPANSION0 = EXPANSION_NAME0

    local statusTable = {
        AFK = ' |cffFFFFFF[|r|cffFF9900' .. (L.AFK) .. '|r|cffFFFFFF]|r',
        DND = ' |cffFFFFFF[|r|cffFF3333' .. (L.DND) .. '|r|cffFFFFFF]|r',
    }
    local levelNameString = '|cff%02x%02x%02x%d|r |cff%02x%02x%02x%s|r'
    local levelNameClassString = '|cff%02x%02x%02x%d|r %s%s%s'
    local tthead = { r = 0.4, g = 0.78, b = 1 }
    local activezone, inactivezone = { r = 0.3, g = 1.0, b = 0.3 }, { r = 0.65, g = 0.65, b = 0.65 }

    local friendTable, BNTable, tableList, clientSorted = {}, {}, {}, {}
    local dataValid = false
    local isBNOnline = false

    local myRealm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or ''

    -- Инвалидация кэша: события приходят через общий Datatexts-мост панели
    -- (params.updateEvent -> f:SetScript("OnEvent", ...)), поэтому подписку
    -- вешаем хуком на саму панель при каждом построении подсказки. Панель
    -- может пересоздаваться (сброс настроек / смена макета) — проверяем, что
    -- хук навешан именно на текущий фрейм.
    local hookedPanel
    local function AttachInvalidator()
        local panel = LPS.frame and LPS.frame.friends
        if not panel or type(panel.HookScript) ~= 'function' then return end
        isBNOnline = (BNConnected and BNConnected()) or false
        if hookedPanel == panel then return end
        hookedPanel = panel
        panel:HookScript('OnEvent', function()
            dataValid = false
            isBNOnline = (BNConnected and BNConnected()) or false
        end)
    end

    -- Локальное имя класса -> ключ RAID_CLASS_COLORS (для цвета имени)
    local unlocalizedCache = {}
    local function UnlocalizedClassName(name)
        if not name then return nil end
        local cached = unlocalizedCache[name]
        if cached ~= nil then return cached or nil end
        local result
        if RAID_CLASS_COLORS then
            for k, v in pairs(RAID_CLASS_COLORS) do
                if v.classDescription == name or v.className == name then
                    result = k
                    break
                end
            end
        end
        unlocalizedCache[name] = result or false
        return result
    end

    local function ClassColorHex(classFile)
        local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if c then return DT.hexFromRGB(c.r, c.g, c.b) end
        return nil
    end

    -- Звёздочка, если персонаж в нашей группе/рейде (ElvUI InGroup)
    local function InGroup(name, realmName)
        if not name then return '' end
        if realmName and realmName ~= '' and realmName ~= myRealm then
            name = name .. '-' .. realmName
        end
        local ok = (UnitInRaid and UnitInRaid(name)) or (UnitInParty and UnitInParty(name))
        return ok and '|cffaaaaaa*|r' or ''
    end

    local function SortAlphabeticName(a, b)
        if a.name and b.name then
            return a.name < b.name
        end
    end

    -- client -> project -> faction -> name (как в ElvUI)
    local function Sort(a, b)
        if a.client and b.client then
            if (a.client == b.client) then
                if (a.client == wowString) and a.wowProjectID and b.wowProjectID then
                    if (a.wowProjectID == b.wowProjectID) and a.faction and b.faction then
                        if (a.faction == b.faction) and a.characterName and b.characterName then
                            return a.characterName < b.characterName
                        end
                        return a.faction < b.faction
                    end
                    return a.wowProjectID < b.wowProjectID
                elseif (a.battleTag and b.battleTag) then
                    return a.battleTag < b.battleTag
                end
            end
            return a.client < b.client
        end
    end

    local clientList = {
        WoW =  { index = 1,  tag = 'WoW',  name = 'World of Warcraft' },
        WTCG = { index = 2,  tag = 'HS',   name = 'Hearthstone' },
        Hero = { index = 3,  tag = 'HotS', name = 'Heroes of the Storm' },
        Pro =  { index = 4,  tag = 'OW',   name = 'Overwatch' },
        OSI =  { index = 5,  tag = 'D2',   name = 'Diablo 2: Resurrected' },
        D3 =   { index = 6,  tag = 'D3',   name = 'Diablo 3' },
        Fen =  { index = 7,  tag = 'D4',   name = 'Diablo 4' },
        ANBS = { index = 8,  tag = 'DI',   name = 'Diablo Immortal' },
        S1 =   { index = 9,  tag = 'SC',   name = 'Starcraft' },
        S2 =   { index = 10, tag = 'SC2',  name = 'Starcraft 2' },
        W3 =   { index = 11, tag = 'WC3',  name = 'Warcraft 3: Reforged' },
        RTRO = { index = 12, tag = 'AC',   name = 'Arcade Collection' },
        WLBY = { index = 13, tag = 'CB4',  name = 'Crash Bandicoot 4' },
        VIPR = { index = 14, tag = 'BO4',  name = 'COD: Black Ops 4' },
        ODIN = { index = 15, tag = 'WZ',   name = 'COD: Warzone' },
        AUKS = { index = 16, tag = 'WZ2',  name = 'COD: Warzone 2' },
        LAZR = { index = 17, tag = 'MW2',  name = 'COD: Modern Warfare 2' },
        ZEUS = { index = 18, tag = 'CW',   name = 'COD: Cold War' },
        FORE = { index = 19, tag = 'VG',   name = 'COD: Vanguard' },
        GRY =  { index = 20, tag = 'AR',   name = 'Warcraft Arclight Rumble' },
        App =  { index = 21, tag = 'App',  name = 'App' },
        BSAp = { index = 22, tag = L.MOBILE, name = L.MOBILE },
    }

    local function ClientSort(a, b)
        if a and b then
            local A, B = clientList[a], clientList[b]
            if A and B then
                return A.index < B.index
            end
            return a < b
        end
    end

    ------------------------- Таблица wow-друзей -------------------------
    local function BuildFriendTable(total)
        wipe(friendTable)
        if not CF_GetFriendInfoByIndex then return end
        for i = 1, total do
            local info = CF_GetFriendInfoByIndex(i)
            if info and info.connected then
                local className = UnlocalizedClassName(info.className) or ''
                local status = (info.afk and statusTable.AFK) or (info.dnd and statusTable.DND) or ''
                friendTable[i] = {
                    name = info.name,
                    level = info.level,
                    class = className,
                    zone = info.area,
                    online = info.connected,
                    status = status,
                    notes = info.notes,
                    guid = info.guid,
                }
            end
        end
        if next(friendTable) then
            sort(friendTable, SortAlphabeticName)
        end
    end

    ------------------------- Таблица Battle.net-друзей -------------------------
    local function AddToBNTable(bnIndex, bnetIDAccount, accountName, battleTag, characterName, bnetIDGameAccount, client, isOnline, isBnetAFK, isBnetDND, noteText, wowProjectID, realmName, faction, race, className, zoneName, level, guid, gameText)
        className = UnlocalizedClassName(className) or ''
        characterName = (BNet_GetValidatedCharacterName and BNet_GetValidatedCharacterName(characterName, battleTag, client)) or ''

        local obj = {
            accountID = bnetIDAccount,
            accountName = accountName,
            battleTag = battleTag,
            characterName = characterName,
            gameID = bnetIDGameAccount,
            client = client,
            isOnline = isOnline,
            isBnetAFK = isBnetAFK,
            isBnetDND = isBnetDND,
            noteText = noteText,
            wowProjectID = wowProjectID,
            realmName = realmName,
            faction = faction,
            race = race,
            className = className,
            zoneName = zoneName,
            level = level,
            guid = guid,
            gameText = gameText,
        }

        if wowProjectID and wowProjectID ~= WOW_PROJECT_MAINLINE then
            obj.classicText, obj.realmName = strmatch(gameText, '(.-)%s%-%s?(.-)$')

            if obj.classicText and obj.classicText ~= '' and obj.classicText ~= EXPANSION0 then
                obj.classicText = gsub(obj.classicText, '%s?' .. EXPANSION0 .. '%s?', '')
            end
        end

        BNTable[bnIndex] = obj

        local list = tableList[client]
        if list then
            tinsert(list, obj)
        else
            list = { obj }
            tableList[client] = list
        end
    end

    local function PopulateBNTable(bnIndex, bnetIDAccount, accountName, battleTag, characterName, bnetIDGameAccount, client, isOnline, isBnetAFK, isBnetDND, noteText, wowProjectID, realmName, faction, race, class, zoneName, level, guid, gameText, hasFocus)
        for i = 1, bnIndex do
            local isAdded, bnInfo = 0, BNTable[i]
            if bnInfo and (bnInfo.accountID == bnetIDAccount) then
                if bnInfo.client == 'BSAp' then
                    if client == 'BSAp' then
                        isAdded = 1
                    elseif client == 'App' then
                        isAdded = (hasFocus and 2) or 1
                    else -- Mobile -> Game
                        isAdded = 2 --swap data
                    end
                elseif bnInfo.client == 'App' then
                    if client == 'App' then
                        isAdded = 1
                    elseif client == 'BSAp' then
                        isAdded = (hasFocus and 2) or 1
                    else -- App -> Game
                        isAdded = 2 --swap data
                    end
                elseif bnInfo.client then -- Game
                    if client == 'BSAp' or client == 'App' then -- ignore Mobile and App
                        isAdded = 1
                    end
                end
            end
            if isAdded == 2 then -- swap data
                if bnInfo.client and tableList[bnInfo.client] then
                    for n, y in ipairs(tableList[bnInfo.client]) do
                        if y == bnInfo then
                            tremove(tableList[bnInfo.client], n)
                            break
                        end
                    end
                end
                AddToBNTable(i, bnetIDAccount, accountName, battleTag, characterName, bnetIDGameAccount, client, isOnline, isBnetAFK, isBnetDND, noteText, wowProjectID, realmName, faction, race, class, zoneName, level, guid, gameText)
            end
            if isAdded ~= 0 then
                return bnIndex
            end
        end

        bnIndex = bnIndex + 1
        AddToBNTable(bnIndex, bnetIDAccount, accountName, battleTag, characterName, bnetIDGameAccount, client, isOnline, isBnetAFK, isBnetDND, noteText, wowProjectID, realmName, faction, race, class, zoneName, level, guid, gameText)

        return bnIndex
    end

    -- total = число из второго возврата BNGetNumFriends (после BNSetFilters),
    -- т.е. количество ОТФИЛЬТРОВАННЫХ записей (как в ElvUI UpdateTooltip).
    local function BuildBNTable(total)
        for _, v in pairs(tableList) do wipe(v) end
        wipe(BNTable)
        wipe(clientSorted)

        local bnIndex = 0

        for i = 1, total do
            local accountInfo = GetFriendAccountInfo and GetFriendAccountInfo(i)
            local gameInfo = accountInfo and accountInfo.gameAccountInfo
            if gameInfo and gameInfo.isOnline then
                local numGameAccounts = GetFriendNumGameAccounts and GetFriendNumGameAccounts(i)
                if numGameAccounts and numGameAccounts > 0 then
                    for y = 1, numGameAccounts do
                        local gameOther = GetFriendGameAccountInfo(i, y)
                        bnIndex = PopulateBNTable(bnIndex, accountInfo.bnetAccountID, accountInfo.accountName, accountInfo.battleTag, gameOther.characterName, gameOther.gameAccountID, gameOther.clientProgram, gameOther.isOnline, accountInfo.isAFK or gameOther.isGameAFK, accountInfo.isDND or gameOther.isGameBusy, accountInfo.note, gameOther.wowProjectID, gameOther.realmName, gameOther.factionName, gameOther.raceName, gameOther.className, gameOther.areaName, gameOther.characterLevel, gameOther.playerGuid, gameOther.richPresence, gameOther.hasFocus)
                    end
                else
                    bnIndex = PopulateBNTable(bnIndex, accountInfo.bnetAccountID, accountInfo.accountName, accountInfo.battleTag, gameInfo.characterName, gameInfo.gameAccountID, gameInfo.clientProgram, gameInfo.isOnline, accountInfo.isAFK, accountInfo.isDND, accountInfo.note, gameInfo.wowProjectID)
                end
            end
        end

        if next(BNTable) then
            sort(BNTable, Sort)
        end
        for c, v in pairs(tableList) do
            if next(v) then
                sort(v, Sort)
            end
            tinsert(clientSorted, c)
        end
        if next(clientSorted) then
            sort(clientSorted, ClientSort)
        end
    end

    ------------------------- Построение подсказки -------------------------
    local lastTooltipXLineHeader
    local function TooltipAddXLine(tt, doubleLine, header, ...)
        if lastTooltipXLineHeader ~= header then
            tt:AddLine(' ')

            if doubleLine then
                tt:AddDoubleLine(header, '')
            else
                tt:AddLine(header)
            end

            lastTooltipXLineHeader = header
        end

        if doubleLine then
            tt:AddDoubleLine(...)
        else
            tt:AddLine(...)
        end
    end

    function LPS:BuildFriendsTooltip(GameTooltip)
        AttachInvalidator()

        local tt = GameTooltip
        tt:ClearLines()
        lastTooltipXLineHeader = nil

        local onlineFriends = (CF_GetNumOnlineFriends and CF_GetNumOnlineFriends()) or 0
        local numberOfFriends = (CF_GetNumFriends and CF_GetNumFriends()) or 0
        local totalBNet, numBNetOnline = 0, 0
        if BNGetNumFriends then
            totalBNet, numBNetOnline = BNGetNumFriends()
            totalBNet = totalBNet or 0
            numBNetOnline = numBNetOnline or 0
        end
        local totalonline = onlineFriends + numBNetOnline

        if not dataValid then
            -- данные собираем только когда реально показываем подсказку
            if numberOfFriends > 0 then BuildFriendTable(numberOfFriends) end
            if totalBNet > 0 and isBNOnline then BuildBNTable(totalBNet) end
            dataValid = true
        end

        local totalfriends = numberOfFriends + totalBNet
        local zonec, classc, levelc, realmc
        local shiftDown = IsShiftKeyDown()

        tt:AddDoubleLine(L.FRIENDS_LIST, format(totalOnlineString, totalonline, totalfriends), tthead.r, tthead.g, tthead.b, tthead.r, tthead.g, tthead.b)

        -- wow-друзья в игре
        if (onlineFriends > 0) then
            for _, info in ipairs(friendTable) do
                if info.online then
                    if LPS.MapInfo and LPS.MapInfo.zoneText and (LPS.MapInfo.zoneText == info.zone) then zonec = activezone else zonec = inactivezone end
                    classc = ClassColorHex(info.class)
                    levelc = GetQuestDifficultyColor(info.level)
                    if not classc then classc = DT.hexFromRGB(levelc.r, levelc.g, levelc.b) end

                    TooltipAddXLine(tt, true, characterFriend,
                        format(levelNameClassString, levelc.r * 255, levelc.g * 255, levelc.b * 255, info.level, classc, info.name .. InGroup(info.name) .. info.status),
                        info.zone, classc, zonec.r, zonec.g, zonec.b)
                end
            end
        end

        -- Battle.net-друзья: онлайн в WoW, других играх или BNet-приложении
        if numBNetOnline > 0 then
            local status
            for _, client in ipairs(clientSorted) do
                local Table = tableList[client]
                for _, info in ipairs(Table) do
                    if info.isOnline then
                        if info.isBnetAFK == true then
                            status = statusTable.AFK
                        elseif info.isBnetDND == true then
                            status = statusTable.DND
                        else
                            status = ''
                        end

                        local clientInfo = clientList[client]
                        local header = format('%s (%s)', battleNetString, info.classicText or (clientInfo and clientInfo.tag) or client)
                        if info.client and info.client == wowString then
                            classc = ClassColorHex(info.className)
                            if info.level and info.level ~= '' then
                                levelc = GetQuestDifficultyColor(info.level)
                            else
                                classc, levelc = RAID_CLASS_COLORS.PRIEST, RAID_CLASS_COLORS.PRIEST
                            end
                            -- иногда список друзей показывает level 0 unknown friends
                            if not classc then classc = RAID_CLASS_COLORS.PRIEST end

                            TooltipAddXLine(tt, true, header,
                                format(levelNameString .. '%s%s', levelc.r * 255, levelc.g * 255, levelc.b * 255, info.level, classc, info.characterName .. InGroup(info.characterName, info.realmName) .. status),
                                info.accountName, 238, 238, 238, 238, 238, 238)
                            if shiftDown then
                                if LPS.MapInfo and LPS.MapInfo.zoneText and (LPS.MapInfo.zoneText == info.zoneName) then zonec = activezone else zonec = inactivezone end
                                if myRealm == info.realmName then realmc = activezone else realmc = inactivezone end
                                if info.zoneName or info.realmName then
                                    TooltipAddXLine(tt, true, header, info.zoneName or ' ', info.realmName or ' ', zonec.r, zonec.g, zonec.b, realmc.r, realmc.g, realmc.b)
                                end
                            end
                        else
                            TooltipAddXLine(tt, true, header, info.characterName .. status, info.accountName, .9, .9, .9, .9, .9, .9)
                            if shiftDown and (info.gameText and info.gameText ~= '') and (info.client and info.client ~= 'App' and info.client ~= 'BSAp') then
                                TooltipAddXLine(tt, false, header, info.gameText, inactivezone.r, inactivezone.g, inactivezone.b)
                            end
                        end
                    end
                end
            end
        end

        if totalonline == 0 then
            tt:AddLine(' ')
            tt:AddLine(L.NO_FRIENDS_ONLINE, 0.65, 0.65, 0.65)
        end

        tt:AddLine(' ')
        local rB, gB, bB = LPS:GetColor("tooltipSetting")
        tt:AddDoubleLine(L.LMB, L.OPEN_FRIENDS_LIST, rB, gB, bB, rB, gB, bB)
    end
end
