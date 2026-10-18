local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Strength (attribute)
do
	local statDefs = { { key = "strength", label = function() return LPS:L("Strength") end, attr = LE_UNIT_ATTRIBUTE_STRENGTH or 1 } }
for _, sd in ipairs(statDefs) do
		LPS:RegisterDatatext({
			key = sd.key,
			name = sd.label(),
			events = { "UNIT_STATS", "UNIT_AURA", "PLAYER_ENTERING_WORLD" },
			update = function(f)
				local value
				if UnitAttribute then
					value = UnitAttribute("player", sd.attr)
				elseif UnitStat then
					value = UnitStat("player", sd.attr)
				end
				if f.text then
					f.text:SetText(string.format("%s: %d", sd.label(), math.floor(value or 0)))
				end
			end,
		})
	end
end
