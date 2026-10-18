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

	--- Число ПРИНЯТЫХ квестов — ровно то, что показывает сам журнал заданий.
	--- Никаких эвристик по полному списку записей (именно они давали 44/35
	--- вместо реальных принятых): используются только точные источники:
	--- 1) GetCVar("questLogQuantity") — внутренний счётчик принятых заданий,
	---    тот же, что печатает стандартный журнал в заголовке;
	--- 2) GetNumQuestLogQuestions() — классический API числа взятых квестов;
	--- 3) обход слотов журнала GetQuestLogTitle(i), i = 1..GetMaxNumQuests()
	---    (в классических клиентах в этих слотах лежат только принятые);
	--- 4) GetQuestLogSize() — запасной вариант.
	--- Берётся максимум из достоверных источников, чтобы временный нуль
	--- (журнал ещё не прогрузился) не занижал счётчик.
	local function acceptedCountFromSlots()
		local maxSlots = (C_QuestLog and C_QuestLog.GetMaxNumQuests) and C_QuestLog.GetMaxNumQuests()
			or (GetMaxNumQuests and GetMaxNumQuests())
		if not maxSlots or not GetQuestLogTitle then return nil end
		local count = 0
		for i = 1, maxSlots do
			if GetQuestLogTitle(i) then count = count + 1 end
		end
		return count
	end

	local function getAcceptedCount()
		local candidates = {}

		-- 1) точный счётчик самого журнала
		if GetCVar then
			local ok, v = pcall(GetCVar, "questLogQuantity")
			if ok then v = tonumber(v) end
			if v and v >= 0 then candidates[#candidates + 1] = v end
		end

		-- 2) официальный API числа взятых заданий (классические клиенты)
		if GetNumQuestLogQuestions then
			local ok, v = pcall(GetNumQuestLogQuestions)
			if ok then v = tonumber(v) end
			if v and v >= 0 then candidates[#candidates + 1] = v end
		end

		-- 3) прямой обход слотов журнала
		local ok, slots = pcall(acceptedCountFromSlots)
		if ok and slots and slots >= 0 then candidates[#candidates + 1] = slots end

		-- 4) GetQuestLogSize (есть не на всех клиентах)
		if GetQuestLogSize then
			local ok, v = pcall(GetQuestLogSize)
			if ok then v = tonumber(v) end
			if v and v >= 0 then candidates[#candidates + 1] = v end
		end

		local best
		for _, n in ipairs(candidates) do
			if not best or n > best then best = n end
		end
		if best then return best end

		-- крайний случай: строгий фильтр IsOnQuest по записям журнала
		local count = 0
		local numEntries = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries())
			or (GetNumQuestLogEntries and GetNumQuestLogEntries())
			or 0
		for qi = 1, numEntries do
			if C_QuestLog and C_QuestLog.GetInfo then
				local info = C_QuestLog.GetInfo(qi)
				if info and not info.isHeader and not info.isTask and isOnQuest(info.questID) then
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
