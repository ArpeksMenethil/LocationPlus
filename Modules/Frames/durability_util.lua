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
-- Правильный способ получить ОБЫЧНЫЕ числа прочности (как это делают
-- Blizzard PaperDollFrame / Blizzard_AutoCompleteText):
--   1. создать инстанс Item, привязанный к слоту ("inventory:<n>" через
--      SecureCmdItemParse или C_Item:Create("player", <n>));
--   2. вызвать item:GetDurability() ВНУТРИ item:RunFor(<доверенный
--      Blizzard-фрейм слота>, ...). Только такой вызов раскрывает
--      secret-значения в обычные числа без тинта.
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

--- Возвращает инстанс Item для слота (или nil, если API недоступен).
local function slotItem(index)
	local cached = slotItemCache[index]
	if cached and cached.GetDurability then return cached end

	-- Официальный Blizzard-путь: CreateFrame("Item") + SetInventorySlot.
	-- Такой инстанс умеет RunFor и отдаёт прочность через GetDurability().
	local item
	if CreateFrame then
		local ok, created = pcall(CreateFrame, "Item")
		if ok and created and created.SetInventorySlot and created.GetDurability then
			local ok2 = pcall(created.SetInventorySlot, created, "player", index)
			if ok2 then item = created end
		end
	end
	-- Fallback: SecureCmdItemParse ("inventory:<n>") — так же парсит предмет
	-- сам клиент для secure-хуков.
	if not item and SecureCmdItemParse then
		local ok, parsed = pcall(SecureCmdItemParse, "inventory:" .. index)
		if ok and type(parsed) == "table" and parsed.GetDurability then
			item = parsed
		end
	end
	if not item then return nil end

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
	local item = slotItem(index)
	if not item then return nil end

	-- Клиенты с secret-системой: значения читаются ТОЛЬКО через RunFor по
	-- доверенному Blizzard-фрейму слота; если такого фрейма нет (окно
	-- персонажа скрыто) — вернуть nil вместо растекания secret'ов по UI.
	if item.RunFor then
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

	-- Старые клиенты без Item:RunFor / secret API: GetInventoryItemDurability()
	-- возвращает обычные числа и безопасна.
	return GetInventoryItemDurability(index)
end
