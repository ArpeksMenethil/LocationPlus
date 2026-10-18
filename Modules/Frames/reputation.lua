local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Reputation
do
	local function watchedFaction()
		if C_Reputation and C_Reputation.GetWatchedFactionData then
			local d = C_Reputation.GetWatchedFactionData()
			if d and d.name then return d end
			return nil
		end
		local name, bottomLine, displayedMax, currentStanding, factionMember,
			currentReputation, maxReputation = GetWatchedFactionInfo and GetWatchedFactionInfo()
		if not name then return nil end
		return {
			name = name,
			currentValue = currentReputation or currentStanding,
			maxValue = maxReputation or displayedMax,
			offsetValue = bottomLine,
		}
	end

	LPS:RegisterDatatext({
		key = "reputation",
		name = LPS:L("Reputation"),
		events = { "UPDATE_FACTION", "COMBAT_TEXT_UPDATE" },
		update = function(f)
			local data = watchedFaction()
			if not data then
				if f.text then f.text:SetText(NOT_APPLICABLE or "-") end
				return
			end
			local cur = (data.currentValue or 0) - (data.offsetValue or 0)
			local max = (data.maxValue or 0) - (data.offsetValue or 0)
			local pct = max > 0 and (cur / max * 100) or 100
			local reaction = data.reaction or data.standing or 5
			local standingLabel = _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN
			if f.text then
				f.text:SetText(string.format("%s: %d%% [%s]", data.name or "", math.floor(pct), standingLabel))
			end
		end,
		onClick = function()
			if ToggleCharacter then ToggleCharacter("ReputationFrame") end
		end,
tooltip = function(tt)
        			local data = watchedFaction()
        			if not data then return end
        			tt:AddLine(data.name or "", 1, 0.82, 0)
        			tt:AddLine(" ")
        			local reaction = data.reaction or data.standing or 5
        			tt:AddDoubleLine(STANDING .. ":", _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN, 1, 1, 1, 1, 1, 1)
        			local cur = (data.currentValue or 0) - (data.offsetValue or 0)
        			local max = (data.maxValue or 0) - (data.offsetValue or 0)
        			if max > 0 then
        				tt:AddDoubleLine(REPUTATION .. ":", string.format("%d / %d (%d%%)", cur, max, cur / max * 100), 1, 1, 1, 1, 1, 1)
        			end
		end,
	})
end
