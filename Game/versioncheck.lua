local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local PREFIX = "LPS_VERSIONCHK"
local OUTDATED_FLAG = "OLD|"

do
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end

    local myRealm = (GetRealmName and GetRealmName()) or ""

    --- Имя игрока в формате чата: "Name-Realm", либо просто "Name" (свой рейм/region-unique).
    local function toSenderName(name, realm)
        if not name or name == "" then return nil end
        if realm and realm ~= "" and realm ~= myRealm then
            return name .. "-" .. realm
        end
        return name
    end

    local function unitSenderName(unit)
        local name, realm
        if UnitFullName then
            name, realm = UnitFullName(unit)
        else
            name = UnitName(unit)
            realm = UnitRealm and UnitRealm(unit)
        end
        return toSenderName(name, realm)
    end

    local function mySenderName()
        return unitSenderName("player")
    end

    --- Включена ли проверка обновления (настройка «Общие → Проверять обновление»);
    --- при выключенной версии всё равно отправляются, реакции — нет.
    local function checkEnabled()
        local db = LPS.GetDB and LPS:GetDB()
        return db and db.general and db.general.checkForUpdates ~= false
    end

    --- Числовое сравнение версий вида "X.Y.Z": 1 (a > b), 0, -1 (a < b).
    local function versionCompare(a, b)
        local function toParts(v)
            local parts = {}
            for p in tostring(v):gmatch("%d+") do
                parts[#parts + 1] = tonumber(p)
            end
            return parts
        end
        local A, B = toParts(a), toParts(b)
        for i = 1, math.max(#A, #B) do
            local x, y = A[i] or 0, B[i] or 0
            if x ~= y then
                return x > y and 1 or -1
            end
        end
        return 0
    end

    local notifiedMe = false
    local toldMeOutdated = false
    local responded = {}
    local repliedTo = {}
    local noResponseDone = false

    --- Дебаг-вывод проверки версий (только при LPS.DEBUG).
    local function dbg(fmt, ...)
        if LPS.DEBUG then
            LPS:Print(format("[debug] " .. fmt, ...), false)
        end
    end

    local function getChannel()
        if IsInRaid() then
            return (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID"
        elseif IsInGroup() then
            return (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY"
        elseif IsInGuild() then
            return "GUILD"
        end
        return nil
    end

    local checkNoResponse
    local function sendVersionCheck()
        local channel = getChannel()
        if channel and C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(PREFIX, LPS.addon.version, channel)
            dbg("versioncheck: sent my version %s to channel %s", LPS.addon.version, channel)
        else
            dbg("versioncheck: no send (not in group/raid/guild)")
        end
        if not noResponseDone then
            C_Timer.After(4, checkNoResponse)
        end
    end

    --- Отладка (только LPS.DEBUG, один раз за сессию): кто из участников
    --- группы/рейда/гильдии не прислал свою версию.
    checkNoResponse = function()
        if noResponseDone then return end
        noResponseDone = true
        if not LPS.DEBUG then return end

        local members = {}
        if IsInGroup() or IsInRaid() then
            local unitPrefix = IsInRaid() and "raid" or "party"
            for i = 1, GetNumGroupMembers() do
                local unit = unitPrefix .. i
                local sender = unitSenderName(unit)
                if sender and sender ~= mySenderName() then
                    members[#members + 1] = sender
                end
            end
        end
        if IsInGuild() and GetGuildMemberByIndex and GetNumGuildMembers then
            for i = 1, GetNumGuildMembers() do
                local name, _, _, _, online = GetGuildMemberByIndex(i)
                if name and name ~= "" and online ~= false then
                    members[#members + 1] = name
                end
            end
        end

        local missing = {}
        for _, member in ipairs(members) do
            local ok = responded[member]
            if not ok then
                for r in pairs(responded) do
                    if string.find(r, member, 1, true) == 1 or string.find(member, r, 1, true) == 1 then
                        ok = true
                        break
                    end
                end
            end
            if not ok then
                missing[#missing + 1] = member
            end
        end


        dbg("no-response check: %d members, %d without response", #members, #missing)
        if #missing > 0 then
            LPS:Print(format(
                L.LPS_NO_RESPONSE_DEBUG or "No response about the Location Plus version from: %s (the addon is not installed, or addon messages are blocked?)",
                table.concat(missing, ", ")), false)
        end
    end

    local function sendReply(sender, payload)
        if repliedTo[sender] then return end
        repliedTo[sender] = true
        local channel = getChannel()
        if channel and C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(PREFIX, payload, channel)
        end
    end

    local lastGroupSize, lastGuildSize = nil, nil
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, prefix, message, _, senderOne, senderTwo)
        if event == "CHAT_MSG_ADDON" then
            if prefix ~= PREFIX then return end
            local sender = string.find(senderOne or "", "-", 1, true) and senderOne or senderTwo
            if not sender or sender == "" or sender == mySenderName() then return end
            message = tostring(message)
            local enabled = checkEnabled()

            if string.sub(message, 1, #OUTDATED_FLAG) == OUTDATED_FLAG then
                dbg("versioncheck: received 'outdated' notice from %s (their version %s)", sender, string.sub(message, #OUTDATED_FLAG + 1))
                if enabled and not toldMeOutdated then
                    toldMeOutdated = true
                    LPS:Print(format(
                        L.LPS_OUTDATED_NOTICE or "Your Location Plus is outdated: you have %s, and %s has version %s. Please update the addon.",
                        LPS.addon.version, sender, string.sub(message, #OUTDATED_FLAG + 1)), false)
                end
                return
            end

            responded[sender] = true
            local cmp = versionCompare(message, LPS.addon.version)
            dbg("versioncheck: received version %s from %s (my %s, cmp %d)", message, sender, LPS.addon.version, cmp)
            if enabled and cmp > 0 and not notifiedMe then
                notifiedMe = true
                LPS:Print(format(
                    L.LPS_NEW_VERSION_AVAILABLE or "A new version %s is available (you have %s). Please update Location Plus (version detected via %s).",
                    message, LPS.addon.version, sender), false)
            end
            if not repliedTo[sender] then
                if cmp < 0 then
                    if enabled then
                        --- Частный ответ устаревшему игроку, чтобы не «обвинить» всех в канале группы.
                        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
                            C_ChatInfo.SendAddonMessage(PREFIX, OUTDATED_FLAG .. LPS.addon.version, "WHISPER", sender)
                        end
                        dbg("versioncheck: sent 'outdated' whisper to %s (my version %s)", sender, LPS.addon.version)
                        repliedTo[sender] = true
                    end
                else
                    sendReply(sender, LPS.addon.version)
                    dbg("versioncheck: sent my version %s back to %s", LPS.addon.version, sender)
                end
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            local num = GetNumGroupMembers()
            if lastGroupSize ~= nil and num > 1 and num > lastGroupSize then
                dbg("versioncheck: group roster grew %d -> %d, sending", lastGroupSize, num)
                C_Timer.After(1, sendVersionCheck)
            end
            lastGroupSize = num
        elseif event == "GUILD_ROSTER_UPDATE" then
            if IsInGuild() and GetNumGuildMembers then
                local num = GetNumGuildMembers()
                if lastGuildSize ~= nil and num > lastGuildSize then
                    dbg("versioncheck: guild roster grew %d -> %d, sending", lastGuildSize, num)
                    C_Timer.After(1, sendVersionCheck)
                end
                lastGuildSize = num
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            dbg("versioncheck: PLAYER_ENTERING_WORLD, sending")
            C_Timer.After(1, sendVersionCheck)
        end
    end)
end