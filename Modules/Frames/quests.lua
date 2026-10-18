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

	--- Число ПРИНЯТЫХ квестов. Считаются ТОЛЬКО реально взятые задания:
	--- 1) приоритет — официальный счётчик категорий журнала (numAccepted):
	---    ровно то число, что показывает сам журнал;
	--- 2) если API недоступен — обход записей с фильтром questLogIndex/IsOnQuest.
	--- Раньше в подсчёт попадали видимые в журнале, но НЕ принятые задания
	--- (44 «квеста» при 12 принятых), поэтому число завышалось.
	local function getAcceptedCount()
		if C_QuestLog and C_QuestLog.GetNumQuestLogAcceptableCategories then
			local ok, categories = pcall(C_QuestLog.GetNumQuestLogAcceptableCategories)
			if ok and type(categories) == "table" then
				local total, found = 0, false
				for _, cat in ipairs(categories) do
					if cat and cat.numAccepted then
						total = total + (tonumber(cat.numAccepted) or 0)
						found = true
					end
				end
				if found then return total end
			end
		end
		local count = 0
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
				-- header'ы и task'и пропускаем; questLogIndex > 0 — признак
				-- принятого задания (запись из журнала, а не из списка доступных)
				if info and not info.isHeader and not info.isTask then
					if info.questLogIndex and info.questLogIndex > 0 then
						count = count + 1
					elseif isOnQuest(info.questID) then
						count = count + 1
					end
				end
			elseif GetQuestLogTitle then
				local title, _, _, isHeader = GetQuestLogTitle(qi)
				-- в классических клиентах в самом журнале лежат только принятые
				if title and not isHeader then
					count = count + 1
				end
			end
		end
		return count
	end

	--- Список принятых квестов для подсказки (тот же строгий фильтр IsOnQuest).
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
			local numQuests = getAcceptedCount()
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
