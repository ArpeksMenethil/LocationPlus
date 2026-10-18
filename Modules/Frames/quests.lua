local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Quests
do
	local function questCounts()
		local numEntries, numQuests
		if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
			numEntries = C_QuestLog.GetNumQuestLogEntries()
			numQuests = C_QuestLog.GetNumQuestLogEntries and select(2, C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries()) or 0
		end
		if not numEntries then
			numEntries, numQuests = GetNumQuestLogEntries()
		end
		return numEntries or 0, numQuests or 0
	end

	LPS:RegisterDatatext({
		key = "quests",
		name = LPS:L("Quest Log"),
		events = { "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" },
		update = function(f)
			local _, numQuests = questCounts()
			local maxQ = 25
			if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
				maxQ = C_QuestLog.GetMaxNumQuestsCanAccept() or maxQ
			end
			if f.text then
				f.text:SetText(string.format("%s: %d/%d", LPS:L("Quests") or TRACKER_HEADER_QUESTS, numQuests, maxQ))
			end
		end,
		onClick = function()
			if ToggleQuestLog then ToggleQuestLog() end
		end,
tooltip = function(tt)
        			tt:AddLine(TRACKER_HEADER_QUESTS or LPS:L("Quest Log"), 1, 0.82, 0)
        			tt:AddLine(" ")
        			local numEntries = questCounts()
        			local limit = (DT.panelCfg("quests") or {}).maxLimit or 15
        			local shown = 0
        			for qi = 1, numEntries do
        				local title, level, _, isHeader, _, isComplete
        				if C_QuestLog and C_QuestLog.GetInfo then
        					local info = C_QuestLog.GetInfo(qi)
        					if info then
        						title, level, isHeader, isComplete = info.title, info.level, info.isHeader, info.isComplete
        					end
        				else
        					title, level, _, isHeader, _, _, _, _, _, isComplete = GetQuestLogTitle(qi)
        				end
        				if title and not isHeader then
        					shown = shown + 1
        					if shown <= limit then
        						tt:AddDoubleLine(title, isComplete and COMPLETE or INCOMPLETE, 1, 1, 1,
        							isComplete and .2 or 1, isComplete and 1 or .2, .2)
        					end
        				end
        			end
        			if shown == 0 then
        				tt:AddLine(LPS:L("No quests"), 0.65, 0.65, 0.65)
        			end
		end,
	})
end
