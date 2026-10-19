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

	-- Прочность берётся через C_Item (как это делает Blizzard InventoryUnitFrames):
	-- Item:GetDurability() возвращает НЕ secret-значения и не тинтит код аддона.
	-- Раньше использовался глобальный GetInventoryItemDurability() — в актуальных
	-- клиентах WoW он отдаёт secret-числа; они «просачивались» в текст панели, а
	-- затем в Blizzard_TextStatusBar (полоска прочности в окне персонажа), где
	-- сравнение secret-числа вызывало ошибку:
	-- "attempt to compare a secret number value (execution tainted by 'LocationPlus')".
	local function slotDurability(index)
		if C_Item and C_Item.Create then
			local item = C_Item:Create("player", index)
			if item and item.IsValid and item:IsValid()
				and item.HasDurability and item:HasDurability() then
				local cur, max = item:GetDurability()
				if cur and max and max > 0 then return cur, max end
			end
			return nil
		end
		-- Фолбэк для старых клиентов без C_Item.
		return GetInventoryItemDurability(index)
	end

	LPS:RegisterDatatext({
		key = "durability",
		nameKey = "Durability",
		events = { "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED" },
		update = function(f)
			local minPct = 100
			local any = false
			for _, index in pairs(inventorySlots) do
				local cur, max = slotDurability(index)
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
	})
end
