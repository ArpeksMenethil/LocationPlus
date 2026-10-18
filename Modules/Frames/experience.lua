local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Experience
do
	LPS:RegisterDatatext({
		key = "experience",
		name = LPS:L("Experience"),
		events = { "PLAYER_XP_UPDATE", "DISABLE_XP_GAIN", "ENABLE_XP_GAIN", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP" },
		update = function(f)
			if not UnitXP or not UnitXPMax then return end
			local level = UnitLevel("player")
			local maxPlayer = MAX_PLAYER_LEVEL or (GetMaxLevelForPlayer and GetMaxLevelForPlayer(select(4, GetBuildInfo())))
			if level == nil or level <= 0 or (maxPlayer and level >= maxPlayer) then
				if f.text then f.text:SetText(MAX_LEVEL) end
				return
			end
			local cur, max = UnitXP("player"), UnitXPMax("player")
			if not max or max == 0 then
				if f.text then f.text:SetText(MAX_LEVEL) end
				return
			end
			-- Настройка отображения живёт на вкладке Show: db.show.experience
			local d = LPS:GetDB()
			local cfg = (d and d.show and d.show.experience) or {}
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
	})
end
