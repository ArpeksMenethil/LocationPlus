--------------------------------------------------------------------
-- DurabilityUtil — безопасное (не-taint) чтение прочности экипировки
--------------------------------------------------------------------
-- В актуальных клиентах WoW глобальная GetInventoryItemDurability()
-- возвращает secret-числа. Если такое число попадает в текст панели
-- LocationPlus, исполнение аддона тинтится, и дальнейшее сравнение
-- secret-значения внутри Blizzard_TextStatusBar (окно персонажа)
-- вызывает ошибку:
--   "attempt to compare a secret number value (execution tainted by 'LocationPlus')"
--
-- Правильный способ получить ОБЫЧНЫЕ числа прочности — тот же, что
-- используют Blizzard PaperDollFrame / LibActionButton-1.0:
--   1. создать инстанс Item ("player"-слот) из НЕ-тинтнутого
--      secure-снаппшота (snippet header'а исполняется «чистым» кодом);
--   2. item:GetDurability() ВНУТРИ item:RunFor(<доверенный фрейм слота>, ...)
--      раскрывает secret-значения в обычные числа без тинта.
--
-- API:
--   LPS_DurabilityUtil.slotDurability(index) -> cur, max | nil
--     cur/max — обычные числа; nil, если прочитать значения безопасно
--     невозможно (нет доверенного фрейма слота, предмет без прочности).
--   LPS_DurabilityUtil.clearCache()
--     Сбрасывает кэш инстансов Item (вызывать при смене экипировки).
--------------------------------------------------------------------

local DurabilityUtil = {}
_G.LPS_DurabilityUtil = DurabilityUtil

local slotItemCache = {}

function DurabilityUtil.clearCache()
	wipe(slotItemCache)
end

--- Создаёт инстанс Item для слота через secure-снаппшот header'а
--- (C_Item:Create("player", <n>) исполняется НЕ из нашего кода, поэтому
--- secret-система не помечает аддон как скомпрометированный).
--- Возвращает item | false (API недоступен) | nil (снаппшот ещё не готов).
local function makeSlotItem(index)
	local f = _G["LPS_DuraHead"]
	if not f or not f.CreateSnapshot then return nil end
	local ok, item = pcall(f.CreateSnapshot, f, [[
		local itemIndex = ...
		if not itemIndex then return nil end
		if C_Item and C_Item.Create then
			return C_Item:Create("player", itemIndex)
		end
		if CreateFrame then
			local it = CreateFrame("Item")
			if it.SetInventorySlot then
				it:SetInventorySlot("player", itemIndex)
				return it
			end
		end
		return nil
	]], index)
	if ok and item ~= nil then return item end
	return false
end

--- Возвращает инстанс Item для слота (или nil, если API недоступен).
local function slotItem(index)
	local cached = slotItemCache[index]
	if cached ~= nil then
		if cached == false then return nil end
		if cached.GetDurability then return cached end
		slotItemCache[index] = nil -- устаревший/битый кэш — пересоздадим
	end

	local item = makeSlotItem(index)
	if not item then return nil end
	if not item.GetDurability then
		slotItemCache[index] = false
		return nil
	end

	slotItemCache[index] = item
	return item
end

--- Доверенный Blizzard-фрейм слота экипировки для RunFor (или nil).
--- ВАЖНО: фрейм должен быть видим — иначе он не считается trust'нутым.
local function trustedSlotFrame(index)
	-- Стандартное окно персонажа: PaperDollFrame["InventorySlot<n>"].
	if PaperDollFrame then
		local f = PaperDollFrame["InventorySlot" .. index]
		if f and f.IsVisible and f:IsVisible() then return f end
	end
	-- Пул слотов Blizzard (используется, когда экипировочные слоты
	-- рендерятся в другом контейнере, например в сумках).
	if C_EquipSetFinder and C_EquipSetFinder.FindEquipSlot
		and EquipSlotPool and EquipSlotPool.GetSlotButton then
		local ok, res = pcall(C_EquipSetFinder.FindEquipSlot, "player", index)
		local slotID = ok and type(res) == "table" and res.slotID
		if slotID then
			local ok2, frame = pcall(EquipSlotPool.GetSlotButton, EquipSlotPool, slotID)
			if ok2 and frame and frame.IsVisible and frame:IsVisible() then
				return frame
			end
		end
	end
	return nil
end

--- Текущая и максимальная прочность предмета в слоте (обычные числа) или nil.
function DurabilityUtil.slotDurability(index)
	-- Старые клиенты (Era/Classic/TBC/WotLK): здесь нет ни secret-системы,
	-- ни Item:RunFor — GetInventoryItemDurability() отдаёт обычные числа и
	-- полностью безопасна. Именно этот путь даёт панели показывать значения
	-- ВСЕГДА (в том числе когда окно персонажа закрыто).
	if not RunFor then
		return GetInventoryItemDurability(index)
	end

	-- Клиенты с secret-системой: читаем только через Item + RunFor по
	-- доверенному Blizzard-фрейму слота. Если такого фрейма нет (окно
	-- персонажа скрыто) или предмет не создан — вернуть nil вместо
	-- растекания secret'ов по UI.
	local item = slotItem(index)
	if not item or not item.RunFor then return nil end

	local frame = trustedSlotFrame(index)
	if not frame then return nil end

	-- HasDurability тоже может быть секретным — проверяем его только как
	-- булев маркер внутри RunFor (без арифметики).
	local okH, has = pcall(item.RunFor, item, frame, item.HasDurability)
	if not okH or not has then return nil end

	-- RunFor(доверенный фрейм, колбэк, self, ...) -> cur, max (обычные числа)
	local ok, c, m = pcall(item.RunFor, item, frame, item.GetDurability)
	if ok and c and m and m > 0 then
		return c, m
	end
	return nil
end

--------------------------------------------------------------------
-- Secure head: единственный легальный способ создать non-tainted
-- инстанс Item из addon-кода (Blizzard-паттерн: snippet header'а
-- исполняется «чистым» secure-кодом даже после тинта аддона).
--------------------------------------------------------------------
do
	if RunFor and not _G["LPS_DuraHead"] then
		local ok, head = pcall(CreateFrame, "Frame")
		if ok and head and head.CreateSnapshot then
			head.name = "LPS_DuraHead"
			_G["LPS_DuraHead"] = head
		end
	end
end

--------------------------------------------------------------------
-- Инвалидация кэша предметов: при смене экипировки старые инстансы
-- Item больше не актуальны.
--------------------------------------------------------------------
if RunFor then
	do
		local f = _G["LPS_DuraEv"]
		if not f then
			local ok, created = pcall(CreateFrame, "Frame")
			if ok and created then
				f = created
				_G["LPS_DuraEv"] = f
			end
		end
		if f and f.RegisterEvent then
			local events = {
				"UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
				"EQUIPMENT_SETS_CHANGED", "ITEM_CHANGED",
				"PLAYER_ENTERING_WORLD",
			}
			f:SetScript("OnEvent", function(self, event, unit)
				if event == "UNIT_INVENTORY_CHANGED" then
					if unit and unit ~= "player" then return end
				end
				DurabilityUtil.clearCache()
			end)
			for _, e in ipairs(events) do
				pcall(f.RegisterEvent, f, e)
			end
		end
	end
end
