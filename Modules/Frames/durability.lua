local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Durability
do
	local inventorySlots = {
		INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_WAIST = 6,
		INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
		INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17, INVTYPE_RANGED = 18,
	}

	LPS:RegisterDatatext({
		key = "durability",
		nameKey = "Durability",
		events = { "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED" },
		update = function(f)
			local minPct = 100
			local any = false
			for _, index in pairs(inventorySlots) do
				local cur, max = GetInventoryItemDurability(index)
				if cur and max and max > 0 then
					any = true
					local perc = cur / max * 100
					if perc < minPct then minPct = perc end
				end
			end
			if not any then minPct = nil end
			if f.text then
				if minPct then
					local r, g, b = DT.colorGradient(minPct * 0.01, 1, .1, .1, 1, 1, .1, .1, 1, .1)
					f.text:SetText(string.format("%s%d%%|r", DT.hexFromRGB(r, g, b), math.floor(minPct + 0.5)))
				else
					f.text:SetText("-")
				end
			end
		end,
		onClick = function()
			if not InCombatLockdown() and ToggleCharacter then
				ToggleCharacter("PaperDollFrame")
			end
		end,
	})
end
