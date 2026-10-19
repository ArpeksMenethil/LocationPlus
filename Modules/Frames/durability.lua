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

	-- Только C_Item: GetInventoryItemDurability() отдаёт secret-числа, которые
	-- ломали protected-код Blizzard при открытии окна персонажа.
	local function isValidNumber(v)
		if type(v) ~= "number" then return false end
		if isSecret then
			local ok, secret = pcall(isSecret, v)
			if ok and secret then return false end
		end
		return true
	end

	local function slotDurability(index)
		if not (C_Item and C_Item.Create) then return nil end
		local ok, item = pcall(C_Item.Create, C_Item, "player", index)
		if not ok or type(item) ~= "table" then return nil end
		local validOk, valid = pcall(function() return item.IsValid and item:IsValid() end)
		if not (validOk and valid) then return nil end
		local hasOk, has = pcall(function() return item.HasDurability and item:HasDurability() end)
		if not (hasOk and has) then return nil end
		local dOk, cur, max = pcall(function()
			local a, b = item:GetDurability()
			return a, b
		end)
		if not dOk then return nil end
		if cur and max and isValidNumber(cur) and isValidNumber(max) and max > 0 then
			return cur, max
		end
		return nil
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
		onClick = function(self, button)
			if not InCombatLockdown() and ToggleCharacter and button == "LeftButton" then
				ToggleCharacter("PaperDollFrame")
			end
		end,
	})
end
