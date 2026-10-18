local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

-- Подсказка друзей по образцу ElvUI (DataTexts/Friends.lua):
-- заголовок «Список друзей | В сети: X/Y», друзья отсортированы по имени,
-- формат строки: цветной уровень + имя (+* если в группе) + [AFK]/[DND], справа зона.
-- Battle.net-друзья не выводятся: в Classic их API недоступен, и один код
-- должен работать одинаково на classic и retail.

local format, strjoin = string.format, strjoin

-- Тот же алгоритм сортировки, что в ElvUI: sort(friendTable, SortAlphabeticName)
local function SortAlphabeticName(a, b)
    if a.name and b.name then
        return a.name < b.name
    end
end

local totalOnlineString = strjoin('', FRIENDS_LIST_ONLINE, ': %s/%s')
local statusTable = {
    AFK = ' |cffFFFFFF[|r|cffFF9900' .. (LPS:L("AFK")) .. '|r|cffFFFFFF]|r',
    DND = ' |cffFFFFFF[|r|cffFF3333' .. (LPS:L("DND")) .. '|r|cffFFFFFF]|r',
}
-- Уровень и имя — как в ElvUI: levelNameClassString
local levelNameClassString = '|cff%s%d|r |cff%s%s|r%s'

-- Звёздочка рядом с именем, если персонаж в группе/рейде (ElvUI: InGroup)
local function InGroup(name)
    if not name or not GetUnitName then return '' end
    local raid = IsInRaid and IsInRaid()
    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    for i = 1, n do
        local unit = raid and ("raid" .. i) or ("party" .. i)
        if GetUnitName(unit, true) == name then return '|cffaaaaaa*|r' end
    end
    return ''
end

function LPS:BuildFriendsTooltip(GameTooltip)
    local tt = GameTooltip
    local rB, gB, bB = LPS:GetColor("tooltipSetting")

    -- Собираем онлайн-друзей одним проходом (тот же источник, что и счётчик панели)
    local total = (C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends()) or 0
    local list = {}
    if C_FriendList and C_FriendList.GetFriendInfoByIndex then
        for i = 1, total do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.connected then
                list[#list + 1] = {
                    name = info.name,
                    level = info.level or 0,
                    zone = info.area,
                    status = (info.afk and statusTable.AFK) or (info.dnd and statusTable.DND) or '',
                }
            end
        end
    end
    if #list > 1 then
        table.sort(list, SortAlphabeticName)
    end

    tt:AddDoubleLine(LPS:L("Friends List"), format(totalOnlineString, #list, total),
        0.4, 0.78, 1, 0.4, 0.78, 1)
    tt:AddLine(' ')

    local limit = (DT.tooltipCfg("friends") or {}).maxLimit or 15
    local rc, gc, bc = LPS:GetColor("text")
    local nameHex = DT.hexFromRGB(rc, gc, bc)
    local shown = 0
    for _, info in ipairs(list) do
        if shown >= limit then break end
        shown = shown + 1
        local levelHex = DT.levelColorHex(info.level)
        tt:AddDoubleLine(
            format(levelNameClassString, levelHex, info.level, nameHex, info.name .. InGroup(info.name), info.status),
            info.zone or '',
            1, 1, 1, 0.65, 0.65, 0.65)
    end

    if #list == 0 then
        tt:AddLine(LPS:L("No friends online"), 0.65, 0.65, 0.65)
    elseif #list > limit then
        tt:AddLine(format('+%d ...', #list - limit), 0.75, 0.9, 1)
    end

    tt:AddLine(' ')
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open friends list"), rB, gB, bB, rB, gB, bB)
end
