local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- DPS / HPS (боевой лог)
do
	local subDmg = {
		SWING_DAMAGE = true, RANGE_DAMAGE = true, SPELL_DAMAGE = true,
		SPELL_PERIODIC_DAMAGE = true, DAMAGE_SHIELD = true, DAMAGE_SPLIT = true,
		SPELL_EXTRA_ATTACKS = true,
	}
	local subHeal = {
		SWING_HEALING = true, RANGE_HEALING = true, SPELL_HEALING = true,
		SPELL_PERIODIC_HEALING = true,
	}
	local combatLogFrame
	local lastSegment, timeStamp, combatTime, dmgTotal, healTotal = 0, 0, 0, 0, 0

	local function getCLE()
		return (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo
	end

	local function ensureLog()
		if combatLogFrame then return end
		combatLogFrame = CreateFrame("Frame")
		combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		combatLogFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		combatLogFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		combatLogFrame:RegisterEvent("UNIT_PET")
		local myGUID = nil
		combatLogFrame:SetScript("OnEvent", function(self, event)
			if event == "UNIT_PET" then
				myGUID = myGUID or UnitGUID("player")
			elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVE_COMBAT" then
				local now = time()
				if now - lastSegment > 20 then
					timeStamp, combatTime, dmgTotal, healTotal = 0, 0, 0, 0
				end
				lastSegment = now
			elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
				myGUID = myGUID or UnitGUID("player")
				local srcGUID
				local timestamp, subEvent, _, sourceGUID = getCLE()()
				if sourceGUID ~= myGUID then return end
				if subDmg[subEvent] then
					if timeStamp == 0 then timeStamp = timestamp end
					lastSegment = timestamp
					combatTime = timestamp - timeStamp
					local amount, overkill
					if subEvent == "SWING_DAMAGE" then
						_, _, _, _, _, _, _, _, _, amount, _, _, _, _, overkill = getCLE()()
					else
						amount, _, _, _, _, _, _, overkill = select(12, getCLE()())
					end
					dmgTotal = dmgTotal + math.max(0, (amount or 0) - (overkill or 0))
				elseif subHeal[subEvent] then
					if timeStamp == 0 then timeStamp = timestamp end
					lastSegment = timestamp
					combatTime = timestamp - timeStamp
					local amount, overhealing
					if subEvent == "SWING_HEALING" then
						amount, _, _, _, _, _, _, _, _, overhealing = select(10, getCLE()())
					else
						amount, _, _, _, _, _, overhealing = select(12, getCLE()())
					end
					healTotal = healTotal + math.max(0, (amount or 0) - (overhealing or 0))
				end
				LPS:_RefreshCombatStats()
			end
		end)
	end

	local updaters = {}
	function LPS:_RefreshCombatStats()
		for _, fn in ipairs(updaters) do fn() end
	end

	LPS:RegisterDatatext({
		key = "dps",
		name = STAT_DPS_SHORT or LPS:L("DPS"),
		ticker = 0.5,
		create = function(f)
			ensureLog()
			local fn = function()
				if f.text and f:IsShown() then
					f.text:SetText(string.format("%s: %s", STAT_DPS_SHORT or LPS:L("DPS"), DT.shortValue(combatTime > 0 and (dmgTotal / combatTime) or 0)))
				end
			end
			updaters[#updaters + 1] = fn
			f._lpsUpdater = fn
		end,
		update = function(f)
			if f.text then
				f.text:SetText(string.format("%s: %s", STAT_DPS_SHORT or LPS:L("DPS"), DT.shortValue(combatTime > 0 and (dmgTotal / combatTime) or 0)))
			end
		end,
tooltip = function(tt)
                        tt:AddLine(STAT_DPS_SHORT or LPS:L("DPS"), 1, 0.82, 0)
                        tt:AddLine(" ")
                        tt:AddDoubleLine(LPS:L("Damage:") or "Damage:", DT.shortValue(dmgTotal), 1, 1, 1, 1, 1, 1)
                        tt:AddDoubleLine(LPS:L("Time:") or "Time:", string.format("%.0f s", combatTime), 1, 1, 1, 1, 1, 1)
                        tt:AddLine(" ")
                        tt:AddLine((LPS:L("Click") or "Click") .. ": " .. (LPS:L("Reset counters") or "Reset counters"), 0.65, 0.65, 0.65)
                end,
		onClick = function(self)
			timeStamp, combatTime, dmgTotal = 0, 0, 0
			if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end
		end,
	})

end
