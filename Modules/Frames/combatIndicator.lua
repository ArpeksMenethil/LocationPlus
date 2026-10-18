local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Combat Indicator
do
	LPS:RegisterDatatext({
		key = "combatIndicator",
		name = LPS:L("Combat Indicator"),
		events = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
		update = function(f)
			local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
			local text
			if inCombat then
				text = "|cFFFF3333" .. LPS:L("In Combat") .. "|r"
			else
				text = "|cFF2BC226" .. LPS:L("Out of Combat") .. "|r"
			end
			if f.text then f.text:SetText(text) end
		end,
	})
end
