local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local function questCounts()
        local numEntries, numQuests
        if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
                numEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
        end
        if not numEntries then
                numEntries, numQuests = GetNumQuestLogEntries()
        end
        numEntries = numEntries or 0
        if type(numQuests) ~= "number" or numQuests == 0 then
                local counted = 0
                for qi = 1, numEntries do
                        local info
                        if C_QuestLog and C_QuestLog.GetInfo then
                                info = C_QuestLog.GetInfo(qi)
                        end
                        if info then
                                if not info.isHeader and not info.hidden then
                                        counted = counted + 1
                                end
                        elseif GetQuestLogTitle then
                                local _, _, _, isHeader, _, _, _, _, questHidden = GetQuestLogTitle(qi)
                                if isHeader ~= nil and not isHeader and not questHidden then
                                        counted = counted + 1
                                end
                        end
                end
                numQuests = counted
        end
        return numEntries, numQuests
end

function LPS:BuildQuestsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(TRACKER_HEADER_QUESTS, 1, 0.82, 0)
                                tt:AddLine(" ")
                                local numEntries = questCounts()
                                local limit = (DT.tooltipCfg("quests") or {}).maxLimit or 15
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
                                elseif shown > limit then
                                        tt:AddLine(string.format("+%d ...", shown - limit), 0.75, 0.9, 1)
                                end

    tt:AddLine(" ")
    tt:AddLine(LPS:L("LMB") .. ": " .. LPS:L("Open quest log"), 0.65, 0.65, 0.65)
end
