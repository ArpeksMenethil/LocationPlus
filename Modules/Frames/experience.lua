local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Experience
do
	LPS:RegisterDatatext({
		key = "experience",
		name = LPS:L("Experience"),
		events = { "PLAYER_XP_UPDATE", "DISABLE_XP_GAIN", "ENABLE_XP_GAIN", "UPDATE_EXHAUSTION", "LEVEL_UP" },
		update = function(f)
			if not UnitXP or not UnitXPMax then return end
			local level = UnitLevel("player")
			local maxPlayer = MAX_PLAYER_LEVEL or (GetMaxLevelForPlayer and GetMaxLevelForPlayer(select(4, GetBuildInfo())))
			if level == nil or level <= 0 or (maxPlayer and level >= maxPlayer) then
				if f.text then f.text:SetText(MAX_LEVEL or LPS:L("Max Level")) end
				return
			end
			local cur, max = UnitXP("player"), UnitXPMax("player")
			if not max or max == 0 then
				if f.text then f.text:SetText(MAX_LEVEL or LPS:L("Max Level")) end
				return
			end
			local cfg = DT.panelCfg("experience") or {}
			local pct = cur / max * 100
			local rested = GetXPExhaustion and GetXPExhaustion()
			local text
			if cfg.display == "CURMAX" then
				text = string.format("%s / %s", DT.shortValue(cur), DT.shortValue(max))
			elseif cfg.display == "CUR" then
				text = DT.shortValue(cur)
			elseif cfg.display == "REM" then
				text = DT.shortValue(max - cur)
			else
				text = string.format("%.2f%%", pct)
			end
			if rested and rested > 0 then
				text = text .. string.format(" |cFF00FF00+%s|r", DT.shortValue(rested))
			end
			if f.text then f.text:SetText(text) end
		end,
tooltip = function(tt)
        			local level = UnitLevel("player")
        			tt:AddDoubleLine(LPS:L("Experience"), string.format("%s %d", LPS:L("Level") or LEVEL, level), 1, 0.82, 0, 1, 1, 1)
        			tt:AddLine(" ")
        			local cur, max = UnitXP("player"), UnitXPMax("player")
        			if max and max > 0 then
        				tt:AddDoubleLine(LPS:L("XP:") or "XP:", string.format("%s / %s (%.2f%%)", DT.shortValue(cur), DT.shortValue(max), cur / max * 100), 1, 1, 1, 1, 1, 1)
        				tt:AddDoubleLine(LPS:L("Remaining:") or "Remaining:", string.format("%s (%.2f%%)", DT.shortValue(max - cur), (max - cur) / max * 100), 1, 1, 1, 1, 1, 1)
        			end
        			local rested = GetXPExhaustion and GetXPExhaustion()
        			if rested and rested > 0 then
        				tt:AddDoubleLine(LPS:L("Rested:") or "Rested:", "+" .. DT.shortValue(rested), 1, 1, 1, 0, 1, 0)
        			end
		end,
	})
end
