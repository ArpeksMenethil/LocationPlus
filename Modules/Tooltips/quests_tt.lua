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

--- Только ПРИНЯТЫЕ задания (C_QuestLog.IsOnQuest):
--- раньше в список попадали доступные, но не взятые квесты,
--- которые помечались как не выполненные.
local function acceptedQuests()
	local list = {}
	local numEntries
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		numEntries = C_QuestLog.GetNumQuestLogEntries()
	end
	if not numEntries then
		numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries()
	end
	numEntries = numEntries or 0
	for qi = 1, numEntries do
		if C_QuestLog and C_QuestLog.GetInfo then
			local info = C_QuestLog.GetInfo(qi)
			if info and not info.isHeader and not info.isTask and isOnQuest(info.questID) then
				list[#list + 1] = { title = info.title, questID = info.questID, isComplete = info.isComplete }
			end
		elseif GetQuestLogTitle then
			local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questLevel, questHidden, questID = GetQuestLogTitle(qi)
			if title and not isHeader and not questHidden and isOnQuest(questID) then
				list[#list + 1] = { title = title, questID = questID, isComplete = isComplete }
			end
		end
	end
	return list
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
