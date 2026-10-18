local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Item Level
do
	LPS:RegisterDatatext({
		key = "itemLevel",
		nameKey = "Item Level",
		events = { "PLAYER_AVG_ITEM_LEVEL_UPDATE", "PLAYER_ENTERING_WORLD", "UNIT_INVENTORY_CHANGED" },
		update = function(f)
			if not GetAverageItemLevel then
				if f.text then f.text:SetText(NOT_APPLICABLE or "-") end
				return
			end
			local avg, avgEquipped = GetAverageItemLevel()
			if f.text then
				f.text:SetText(string.format("%s: %.1f", ITEM_LEVEL_ABBR, avgEquipped or avg or 0))
			end
		end,
	})
end
