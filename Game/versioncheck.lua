local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local PREFIX = "LPS_VERSIONCHK"
local OUTDATED_FLAG = "OLD|"
local COLOR_VERSION_LOWER = LPS:HexFromRGB(1, 0.2, 0.2)
local COLOR_VERSION_HIGHER = LPS:HexFromRGB(0.2, 1, 0.2)

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

    --- Полное имя без суффикса рейма: для своего персонажа —
    --- LPS:GetPlayerFullName(); в Forever — имя + фамилия из
    --- UnitNameUnmodified (как в подсказке gold_tt), иначе — имя клиента.
    local function fullNameOf(unit)
        if unit == "player" and LPS.GetPlayerFullName then
            local n = LPS:GetPlayerFullName()
            if type(n) == "string" and n ~= "" then return n end
        end
        if LPS.Forever and UnitNameUnmodified then
            local first, surname = UnitNameUnmodified(unit)
            if type(first) == "string" and first ~= "" then
                if surname and surname ~= "" then
                    return first .. " " .. surname
                end
                return first
            end
        end
        if UnitFullName then
            local n = UnitFullName(unit)
            if type(n) == "string" and n ~= "" then return n end
        end
        return UnitName and UnitName(unit) or nil
    end

    --- Суффикс рейма только для чужих серверов: UnitFullName в Forever
    --- возвращает (имя, фамилия) — как рейм использовать нельзя.
    local function unitSenderName(unit)
        local name = fullNameOf(unit)
        if not name then return nil end
        local realm
        if unit ~= "player" and UnitRealm then
            local r = UnitRealm(unit)
            if type(r) == "string" and r ~= "" then
                local mine = myRealm
                if mine == "" then
                    mine = UnitRealm("player") or ""
                end
                if mine == "" or mine ~= r then
                    realm = r
                end
            end
        end
        return toSenderName(name, realm)
    end

    --- Имя для сравнения: без «-» и пробелов (в Forever клиент присылает
    --- «Имя-Фамилия», а в аддоне оно отображается «Имя Фамилия»).
    local function normName(n)
        return (tostring(n or ""):gsub("[%-%s]", ""))
    end

    local function mySenderName()
        return unitSenderName("player")
    end

    --- Unit ID игрока в партии/рейде по имени из чата ("Name" либо "Name-Realm"):
    --- единственный способ узнать класс через Unit API (у отправителя из
    --- гильдии класс неизвестен).
    local function findUnitBySender(sender)
        if not sender or not GetNumGroupMembers then return nil end
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, GetNumGroupMembers() do
            local unit = prefix .. i
            if normName(unitSenderName(unit)) == normName(sender) then
                return unit
            end
        end
        return nil
    end

    --- Hex-цвет по classFile (через LPS:GetClassColor / RAID_CLASS_COLORS;
    --- UnitClass в classic-клиентах не возвращает r/g/b).
    local function classColorHex(classFile)
        if not classFile or classFile == "" then return nil end
        local r, g, b
        if LPS.GetClassColor then
            r, g, b = LPS:GetClassColor(classFile)
        else
            local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
            if c then
                r, g, b = c.r, c.g, c.b
            end
        end
        if r and g and b then
            return LPS:HexFromRGB(r, g, b)
        end
        return nil
    end

    --- Имя отправителя цветом класса его персонажа (без цвета, если класс
    --- определить нельзя). Участники группы/рейда показываются в формате
    --- «Имя Фамилия» без дефиса из клиента.
    local function coloredSender(sender)
        local unit = findUnitBySender(sender)
        if not unit and mySenderName() and normName(sender) == normName(mySenderName()) then
            unit = "player"
        end
        if not unit then return sender end
        local displayName = unitSenderName(unit) or sender
        if UnitClass then
            local _, classFile = UnitClass(unit)
            local hex = classColorHex(classFile)
            if hex then
                return hex .. displayName .. "|r"
            end
        end
        return displayName
    end

    --- Своё имя в своём цвете класса (так вас видят собеседники в группе).
    local function myColoredName()
        local name = mySenderName()
        if not name then return "" end
        if UnitClass then
            local _, classFile = UnitClass("player")
            local hex = classColorHex(classFile)
            if hex then
                return hex .. name .. "|r"
            end
        end
        return name
    end

    --- Включена ли проверка обновления (настройка «Общие → Проверять обновление»);
    --- при выключенной версии всё равно отправляются, реакции — нет.
    local function checkEnabled()
        local db = LPS.GetDB and LPS:GetDB()
        return db and db.general and db.general.checkForUpdates ~= false
    end

    --- Числовое сравнение версий вида "X.Y.Z" по компонентам (сначала X,
    --- затем Y, затем Z): 1 (a > b), 0, -1 (a < b).
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
    local latestVersion = nil
    local responded = {}
    local repliedTo = {}
    local noResponseDone = false
    --- Симуляция /lps checkversion: реальные сообщения не отправляются.
    local simulating = false

    --- "outdated", если локальная версия ниже самой известной проверки;
    --- "disabled", если проверка выключена; иначе "latest".
    function LPS:GetVersionStatus()
        local db = LPS.GetDB and LPS:GetDB()
        if not (db and db.general and db.general.checkForUpdates ~= false) then
            return "disabled"
        end
        if latestVersion and versionCompare(latestVersion, LPS.addon.version) > 0 then
            return "outdated"
        end
        return "latest"
    end

    --- Запоминает более новую версию и обновляет цвет версии в заголовке
    --- окна настроек.
    local function noteNewerVersion(theirVersion)
        if not theirVersion or theirVersion == "" then return end
        if not latestVersion or versionCompare(theirVersion, latestVersion) > 0 then
            latestVersion = theirVersion
            if LPS.PanelApplyVersionColor then
                LPS:PanelApplyVersionColor()
            end
        end
    end

    --- Дебаг-вывод проверки версий (только при LPS.DEBUG).
    local function dbg(fmt, ...)
        if LPS.DEBUG then
            LPS:DebugPrint(format(fmt, ...), false)
        end
    end

    --- Отправка addon-сообщения (во время симуляции /lps checkversion
    --- молча пропускается).
    local function transmit(payload, channel, target)
        if simulating then
            dbg("versioncheck: [simulate] message not sent (payload %s -> %s)", payload, tostring(channel))
            return
        end
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(PREFIX, payload, channel, target)
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
        if channel then
            transmit(LPS.addon.version, channel)
            if not simulating then
                dbg("versioncheck: sent my version %s to channel %s", LPS.addon.version, channel)
            end
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
            local nm = normName(member)
            local ok = false
            for r in pairs(responded) do
                local nr = normName(r)
                if nr == nm or nr:sub(1, #nm) == nm or nm:sub(1, #nr) == nr then
                    ok = true
                    break
                end
            end
            if not ok then
                missing[#missing + 1] = member
            end
        end


        dbg("no-response check: %d members, %d without response", #members, #missing)
        if #missing > 0 then
            LPS:DebugPrint(format(
                L.LPS_NO_RESPONSE_DEBUG or "No response about the Location Plus version from: %s (the addon is not installed, or addon messages are blocked?)",
                table.concat(missing, ", ")), false)
        end
    end

    local function sendReply(sender, payload)
        if repliedTo[sender] then return end
        repliedTo[sender] = true
        local channel = getChannel()
        if channel then
            transmit(payload, channel)
        end
    end

    local lastGroupSize, lastGuildSize = nil, nil
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    local function handleAddonMessage(prefix, message, senderOne, senderTwo)
        if prefix ~= PREFIX then return end
        local sender = string.find(senderOne or "", "-", 1, true) and senderOne or senderTwo
        if not sender or sender == "" or (not simulating and normName(sender) == normName(mySenderName())) then return end
        message = tostring(message)
        local enabled = checkEnabled()

        if string.sub(message, 1, #OUTDATED_FLAG) == OUTDATED_FLAG then
            local theirVersion = string.sub(message, #OUTDATED_FLAG + 1)
            dbg("versioncheck: received 'outdated' notice from %s (their version %s)", sender, theirVersion)
            noteNewerVersion(theirVersion)
            if enabled and not notifiedMe then
                notifiedMe = true
                LPS:Print(format(
                    L.LPS_OUTDATED_NOTICE or "Your Location Plus is outdated: you have %s, and %s has version %s. Please update the addon.",
                    COLOR_VERSION_LOWER .. LPS.addon.version .. "|r",
                    coloredSender(sender),
                    COLOR_VERSION_HIGHER .. theirVersion .. "|r"), false)
            end
            return
        end

        responded[sender] = true
        local cmp = versionCompare(message, LPS.addon.version)
        dbg("versioncheck: received version %s from %s (my %s, cmp %d)", message, sender, LPS.addon.version, cmp)
        if cmp > 0 then
            noteNewerVersion(message)
            if enabled and not notifiedMe then
                notifiedMe = true
                LPS:Print(format(
                    L.LPS_NEW_VERSION_AVAILABLE or "A new version %s is available (you have %s). Please update Location Plus (version detected via %s).",
                    COLOR_VERSION_HIGHER .. message .. "|r",
                    COLOR_VERSION_LOWER .. LPS.addon.version .. "|r",
                    coloredSender(sender)), false)
            end
        end
        if not repliedTo[sender] then
            if cmp < 0 then
                if enabled then
                    --- Частный ответ устаревшему игроку, чтобы не «обвинить» всех в канале группы.
                    transmit(OUTDATED_FLAG .. LPS.addon.version, "WHISPER", sender)
                    if simulating then
                        dbg("versioncheck: [simulate] 'outdated' whisper to %s (not sent)", sender)
                    else
                        dbg("versioncheck: sent 'outdated' whisper to %s (my version %s)", sender, LPS.addon.version)
                    end
                    repliedTo[sender] = true
                end
            else
                sendReply(sender, LPS.addon.version)
                dbg("versioncheck: sent my version %s back to %s", LPS.addon.version, sender)
            end
        end
    end

    frame:SetScript("OnEvent", function(_, event, prefix, message, _, senderOne, senderTwo)
        if event == "CHAT_MSG_ADDON" then
            handleAddonMessage(prefix, message, senderOne, senderTwo)
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

    --- Отправитель для симуляции /lps checkversion: реальный участник
    --- группы/рейда (если в группе — имя показывается с цветом, как в
    --- настоящем сообщении), иначе — своё имя как образец.
    local function simulateSender()
        if IsInGroup and IsInGroup() and GetNumGroupMembers then
            local prefix = IsInRaid and IsInRaid() and "raid" or "party"
            for i = 1, GetNumGroupMembers() do
                local unit = prefix .. i
                local s = unitSenderName(unit)
                if s and normName(s) ~= normName(mySenderName()) then
                    return s
                end
            end
        end
        return mySenderName() or "DevCheck"
    end

    --- Команда разработчика /lps checkversion: имитация входящего
    --- сообщения с версией (от участника группы или от своего имени);
    --- реальные сообщения во время симуляции не отправляются. Дополнительно
    --- выводит, что получил бы игрок с указанной версией.
    function LPS:SimulateVersionCheck(theirVersion)
        local sender = simulateSender()
        simulating = true
        handleAddonMessage(PREFIX, tostring(theirVersion), sender, sender)
        simulating = false
        local cmp = versionCompare(theirVersion, LPS.addon.version)
        if cmp < 0 then
            LPS:Print(format(
                L.LPS_OUTDATED_NOTICE or "Your Location Plus is outdated: you have %s, and %s has version %s. Please update the addon.",
                COLOR_VERSION_LOWER .. theirVersion .. "|r",
                myColoredName(),
                COLOR_VERSION_HIGHER .. LPS.addon.version .. "|r"), false)
        elseif cmp == 0 then
            LPS:Print(format("Version %s is equal to the local version - no reaction.", theirVersion), false)
        end
        return cmp
    end
end