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

	-- Прочность берётся через DurabilityUtil — см. Modules/Frames/durability_util.lua:
	--   * на старых клиентах (без secret-системы) это обычный
	--     GetInventoryItemDurability() — значения доступны ВСЕГДА;
	--   * на клиентах с secret-системой значения читаются Item:RunFor() по
	--     доверенному Blizzard-фрейму слота (окно персонажа). Прямой вызов
	--     GetInventoryItemDurability() здесь недопустим: secret-числа
	--     «просачивались» в текст панели, а затем в Blizzard_TextStatusBar
	--     (окно персонажа), где сравнение secret-значения вызывало ошибку:
	--     "attempt to compare a secret number value (execution tainted by 'LocationPlus')".
	local DU = _G.LPS_DurabilityUtil
	if not DU then return end
	local slotDurability = DU.slotDurability

	LPS:RegisterDatatext({
		key = "durability",
		nameKey = "Durability",
		events = { "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED" },
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
				-- На клиентах с secret-системой прочность доступна только через
				-- доверенные фреймы Blizzard (окно персонажа): после его
				-- открытия перечитаем панель, чтобы значения появились сразу.
				C_Timer.After(0.1, function()
					if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end
				end)
			end
		end,
	})
end
