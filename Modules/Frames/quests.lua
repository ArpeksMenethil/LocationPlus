local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Quests
do
		local function isOnQuest(questID)
		if not questID then return false end
		if C_QuestLog and C_QuestLog.IsOnQuest then
			return C_QuestLog.IsOnQuest(questID)
		end
		return false
	end

	--- Число ПРИНЯТЫХ квестов. Раньше считались все не-скрытые
	--- записи журнала, куда попадали и доступные (не принятые) задания.
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
					list[#list + 1] = { title = info.title, level = info.level, questID = info.questID, isComplete = info.isComplete }
				end
			elseif GetQuestLogTitle then
				local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, _, _, questHidden, questID = GetQuestLogTitle(qi)
				if title and not isHeader and not questHidden and isOnQuest(questID) then
					list[#list + 1] = { title = title, level = level, questID = questID, isComplete = isComplete }
				end
			end
		end
		return list
	end

LPS:RegisterDatatext({
		key = "quests",
		name = LPS:L("Quest Log"),
		events = { "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" },
		update = function(f)
			local numQuests = #acceptedQuests()
			local maxQ = 25
			if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
				maxQ = C_QuestLog.GetMaxNumQuestsCanAccept() or maxQ
			end
			if f.text then
				f.text:SetText(string.format("%s: %d/%d", LPS:L("Quests"), numQuests, maxQ))
			end
		end,
		onClick = function()
			if ToggleQuestLog then ToggleQuestLog() end
		end,
	})
end
