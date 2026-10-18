local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local function isOnQuest(questID)
        if not questID then return false end
        if C_QuestLog and C_QuestLog.IsOnQuest then
                return C_QuestLog.IsOnQuest(questID)
        end
        return false
end

--- Список принятых заданий для подсказки — те же источники и тот же строгий
--- фильтр IsOnQuest, что и в Modules/Frames/quests.lua, чтобы содержимое
--- подсказки соответствовало счётчику на панели («N/max»).
--- Раньше сюда попадали доступные, но не взятые квесты (до 44 записей),
--- которые помечались как не выполненные.
local function isCompleteFlag(value)
        -- в разных клиентах isComplete бывает числом (номер этапа), строкой или булем
        if type(value) == "number" then return value > 0 end
        return value and true or false
end

local function acceptedQuestsFromSlots()
        if not GetQuestLogTitle then return nil end
        local maxSlots = (C_QuestLog and C_QuestLog.GetMaxNumQuests) and C_QuestLog.GetMaxNumQuests()
                or (GetMaxNumQuests and GetMaxNumQuests())
        if not maxSlots then return nil end
        local list = {}
        for i = 1, maxSlots do
                local title, _, _, isHeader, _, isComplete, _, _, _, questID = GetQuestLogTitle(i)
                if title and not isHeader and (not questID or isOnQuest(questID)) then
                        list[#list + 1] = { title = title, questID = questID, isComplete = isCompleteFlag(isComplete) }
                end
        end
        return list
end

local function acceptedQuestsFromLogEntries()
        local numEntries
        if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
                numEntries = C_QuestLog.GetNumQuestLogEntries()
        end
        if not numEntries then
                numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries()
        end
        if not numEntries then return nil end
        local list = {}
        for qi = 1, numEntries do
                if C_QuestLog and C_QuestLog.GetInfo then
                        local info = C_QuestLog.GetInfo(qi)
                        if info and not info.isHeader and not info.isTask and isOnQuest(info.questID) then
                                list[#list + 1] = { title = info.title, questID = info.questID, isComplete = isCompleteFlag(info.isComplete) }
                        end
                elseif GetQuestLogTitle then
                        local title, _, _, isHeader, _, isComplete, _, _, questHidden, questID = GetQuestLogTitle(qi)
                        if title and not isHeader and not questHidden and isOnQuest(questID) then
                                list[#list + 1] = { title = title, questID = questID, isComplete = isCompleteFlag(isComplete) }
                        end
                end
        end
        return list
end

local function acceptedQuests()
        -- 1) слоты журнала: в классических клиентах там лежат только принятые задания
        local ok, bySlots = pcall(acceptedQuestsFromSlots)
        if ok and bySlots and #bySlots > 0 then return bySlots end

        -- 2) обход записей журнала со строгим фильтром IsOnQuest
        local ok2, byEntries = pcall(acceptedQuestsFromLogEntries)
        if ok2 and byEntries then return byEntries end

        -- 3) крайний случай: пустой список (счётчик на панели при этом считается в quests.lua)
        return {}
end

function LPS:BuildQuestsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

        local quests = acceptedQuests()
        tt:AddLine(TRACKER_HEADER_QUESTS, 1, 0.82, 0)
        tt:AddLine(" ")
        local limit = (DT.tooltipCfg("quests") or {}).maxLimit or 15
        local shown = 0
        for _, q in ipairs(quests) do
                if q.title then
                        shown = shown + 1
                        if shown <= limit then
                                tt:AddDoubleLine(q.title, q.isComplete and COMPLETE or INCOMPLETE, 1, 1, 1,
                                        q.isComplete and .2 or 1, q.isComplete and 1 or .2, .2)
                        end
                end
        end
        if shown == 0 then
                tt:AddLine(LPS:L("No quests"), 0.65, 0.65, 0.65)
        elseif #quests > limit then
                tt:AddLine(string.format("+%d ...", #quests - limit), 0.75, 0.9, 1)
        end

    tt:AddLine(" ")
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open quest log"), rB, gB, bB, rB, gB, bB)
end
