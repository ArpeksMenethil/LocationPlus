local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local cachedPlayerClass
local function getClassColor()
	if not cachedPlayerClass then
		local _, class = UnitClass("player")
		cachedPlayerClass = class
	end
	local c = cachedPlayerClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cachedPlayerClass]
	if c then
		return c.r, c.g, c.b
	end
	return 1, 1, 1
end

local unpackFn = table.unpack or unpack

-- Кэш нормализованного layout'а (см. LPS:_NormalizeLayoutDB).
local normalizedLayoutCache

function LPS:_NormalizeLayoutDB(raw)
	if not raw then
		raw = {}
		local db = LPS:GetDB()
		if db then db.layout = raw end
	end
-- ВАЖНО: кэш нормализации не должен «съедать» изменения настроек.
-- AceDB может мутировать профиль in-place (та же таблица), поэтому
-- проверка «изменились ли значения» здесь ненадёжна и раньше приводила
-- к тому, что правки в табаке «Макет» (padding/minWidth/spacing) не
-- применялись. Нормализация дешёвая — выполняем её всегда; настоящая
-- защита от лишних перекладок — ключ ApplyLayout + InvalidateLayoutCache.
local out = normalizedLayoutCache and normalizedLayoutCache.out or {}
	out.dtPaddingX  = tonumber(raw.dtPaddingX)
	out.dtPaddingY  = tonumber(raw.dtPaddingY)
	out.dtMinWidth  = tonumber(raw.dtMinWidth)
	out.locPaddingX = tonumber(raw.locPaddingX)
	out.locPaddingY = tonumber(raw.locPaddingY)
	out.locMinWidth = tonumber(raw.locMinWidth)
	-- spacingAuto == true — авторасстояние (жёстко 5, как в эталонной версии);
	-- spacingAuto == false — ручное значение из spacingManual (дефолт из LPS.defaults).
	local defLayout = LPS.defaults and LPS.defaults.layout or {}
	if raw.spacingAuto == false then
		out.spacing = tonumber(raw.spacingManual) or tonumber(defLayout.spacingManual) or 20
	else
		out.spacing = 5
	end
	if raw.dtshow == nil and LPS.defaults and LPS.defaults.layout then
		raw.dtshow = LPS.defaults.layout.dtshow
	end
	if raw.sideSlots == nil and LPS.defaults and LPS.defaults.layout then
		-- КОПИЯ дефолтов, а не ссылка: при AceDB-наследовании запись в общую
		-- таблицу дефолтов ломала бы все профили и сам источник дефолтов.
		local copy = {}
		for k, v in pairs(LPS.defaults.layout.sideSlots) do
			if type(v) == "table" then
				local t = {}
				for kk, vv in pairs(v) do t[kk] = vv end
				copy[k] = t
			else
				copy[k] = v
			end
		end
		copy.userTouched = {}
		raw.sideSlots = copy
	end
	out.dtshow      = raw.dtshow ~= false
	out.slotCount   = tonumber(raw.slotCount) or 2
	out.frameStrata = raw.frameStrata
	out.frameLevel  = tonumber(raw.frameLevel)
	out.customColor = raw.customColor
	out.userColor   = raw.userColor
	-- режим якоря цепочки ("chain" | "location") — входит в layoutKey ApplyLayout
	out.chainAnchor = raw.chainAnchor
	local function copySlots(slots)
		if type(slots) ~= "table" then return nil end
		local res = {}
		for side, s in pairs(slots) do
			if side == "userTouched" then
				-- служебная таблица (не слот): сохраняем ссылку как есть
				res[side] = s
			elseif type(s) == "table" then
				res[side] = { frame = s.frame, offsetX = s.offsetX, offsetY = s.offsetY }
			else
				res[side] = {}
			end
		end
		return res
	end
	out.sideSlots   = copySlots(raw.sideSlots)
	normalizedLayoutCache = { raw = raw, out = out }
	return out
end

function LPS:InvalidateLayoutCache()
	normalizedLayoutCache = nil
	local holder = LPS.frame and LPS.frame.holder
	if holder then holder._lpsLastLayoutKey = nil end
end

local function applyPanelVisibility(frames, slotList, showDT)
	if not frames then return end
	local function normalizeSlotFrameKey(key)
		if not key or key == "" or key == "none" or key == "None" then return "NONE" end
		return key
	end
	local function isSelectedInSlots(frameKey)
		for _, slot in ipairs(slotList or {}) do
			if normalizeSlotFrameKey(slot.cfg and slot.cfg.frame) == frameKey then return true end
		end
		return false
	end
	local shownNow = {}
	-- ЕДИНЫЙ цикл по ВСЕМ панелям. Раньше coords/time/gold/system обрабатывались
	-- отдельными строками ДО этого цикла и исключались из него: после перевода
	-- этих четырёх панелей на общий реестр RegisterDatatext их фреймы создаются
	-- общим GetOrCreatePanelFrame (предпроход в ApplyLayout) и появляются в
	-- frames[] уже ПОСЛЕ старых отдельных строк — SetShown для них не вызывался
	-- вовсе, и gold/coords/system/time «вообще не отображались». Теперь здесь
	-- показываются все панели одним кодом (служебные holder/location/minimapButton
	-- пропускаются).
	for key, f in pairs(frames) do
		if key ~= "holder" and key ~= "location" and key ~= "minimapButton"
			and type(f) == "table" and f.SetShown and f.IsShown then
			f:SetShown(showDT and isSelectedInSlots(key))
			if f:IsShown() then shownNow[#shownNow + 1] = f end
		end
	end
	-- Принудительное первичное заполнение ТОЛЬКО что показанных панелей:
	-- без этого скрытая при создании панель (hidden = true), показанная в этом
	-- же проходе, оставалась пустой до первого события/тикера («выбрал Золото
	-- — оно пустое, пока не обновлю»). Скрытые панели не трогаем.
	LPS._pendingPanelPrimes = shownNow
end
LPS._ApplyPanelVisibility = applyPanelVisibility -- общий для ApplyLayout и Apply*Visibility

-- Собирает строковое описание всех слотов (для кэш-ключа ApplyLayout)
function LPS._CollectSlotKeys(sideSlots)
	local res = {}
	if type(sideSlots) ~= "table" then return res end
	local names = {}
	for name in pairs(sideSlots) do
		if name ~= "userTouched" then names[#names + 1] = tostring(name) end
	end
	table.sort(names)
	for _, name in ipairs(names) do
		local s = sideSlots[name]
		if type(s) == "table" then
			res[#res + 1] = name .. "=" .. tostring(s.frame) .. "," .. tostring(s.offsetX) .. "," .. tostring(s.offsetY)
		else
			res[#res + 1] = name .. "=nil"
		end
	end
	return res
end

function LPS:ApplyLayout()
local db = LPS:GetDB()
local frames = LPS.frame
if not db or not frames then return end

local layout = LPS:_NormalizeLayoutDB(db.layout)

-- Внутренний кэш-маркер: если ключ настроек не изменился с прошлого прохода,
-- ApplyLayout пропускает переанкеривание/перекраску (вызывается очень часто).
-- userColor мутируется колбэком ColorPicker "псевдо-на месте", поэтому его
-- компоненты входят в ключ отдельно от ссылки на таблицу.
local user = layout.userColor
local layoutKey = tostring(layout.dtPaddingX) .. "," .. tostring(layout.dtPaddingY) .. ","
.. tostring(layout.dtMinWidth) .. "," .. tostring(layout.locPaddingX) .. ","
.. tostring(layout.locPaddingY) .. "," .. tostring(layout.locMinWidth) .. ","
.. tostring(layout.spacing) .. "," .. tostring(layout.dtshow) .. ","
.. tostring(layout.frameStrata) .. "," .. tostring(layout.frameLevel) .. ","
.. tostring(layout.customColor) .. ","
.. tostring(user and user.r) .. "," .. tostring(user and user.g) .. "," .. tostring(user and user.b) .. ","
.. tostring(layout.slotCount or 2) .. ","
.. table.concat(LPS._CollectSlotKeys(layout.sideSlots), ";") .. ","
.. tostring(db.settings and db.settings.fontSize or 12) .. ","
.. tostring(layout.chainAnchor)

-- forcePass = первый полный проход после загрузки/сброса кэша. Раньше он
-- зависел от holder:IsShown(), который в момент инициализации ещё false, —
-- из-за этого флаг никогда не сбрасывался и часть пересчётов пропускалась.
local forcePass = not (frames.holder and frames.holder._lpsEverApplied)
-- Принудительный полный проход после смены настроек (ScheduleRefresh), даже
-- если layoutKey формально совпал с предыдущим.
if not forcePass and LPS._ConsumePendingRefresh() then forcePass = true end
if not forcePass and frames.holder and frames.holder._lpsLastLayoutKey == layoutKey then
return
end
local prevKey = frames.holder and frames.holder._lpsLastLayoutKey
if frames.holder then
frames.holder._lpsLastLayoutKey = layoutKey
end

-- Локальные имена layout-параметров (без них ниже шли nil-присваивания:
-- f._lpsPaddingX = locPaddingX записывал nil, а padding/minWidth/spacing
-- из таба «Макет» никогда не попадали во фреймы).
-- Значения из db.layout могут быть nil (битый SavedVariables / профиль до
-- миграции) — берём дефолты из LPS.defaults.layout, иначе произошло бы
-- `f._lpsPaddingX = nil` и авторазмер считался бы по жёстким полам, а
-- настройки «Макета» выглядели бы не работающими.
local defaultsLayout = (LPS.defaults and LPS.defaults.layout) or {}
local dtPaddingX  = tonumber(layout.dtPaddingX)  or tonumber(defaultsLayout.dtPaddingX)  or 20
local dtPaddingY  = tonumber(layout.dtPaddingY)  or tonumber(defaultsLayout.dtPaddingY)  or 7
local dtMinWidth  = tonumber(layout.dtMinWidth)  or tonumber(defaultsLayout.dtMinWidth)  or 100
local locPaddingX = tonumber(layout.locPaddingX) or tonumber(defaultsLayout.locPaddingX) or 20
local locPaddingY = tonumber(layout.locPaddingY) or tonumber(defaultsLayout.locPaddingY) or 9
local locMinWidth = tonumber(layout.locMinWidth) or tonumber(defaultsLayout.locMinWidth) or 200
local spacing     = tonumber(layout.spacing) or 5
-- Принудительный пересчёт габаритов на первом проходе (в т.ч. когда holder
-- ещё скрыт): иначе padding/minWidth из таба "Макет" не применяются до
-- первого изменения любой другой настройки.
local firstPass = forcePass

local function getLayoutTextColor(mode, userColor)
if mode == 1 then
return (userColor and userColor.r) or 1, (userColor and userColor.g) or 1, (userColor and userColor.b) or 1
end
if mode == 2 then
-- getClassColor — единая file-level upvalue (без дублей и closure-аллокаций)
return getClassColor()
end
if mode == 3 then
return LPS:GetZoneStatus(true)
end
return nil
end

local function resolveFont()
local file, _, flags = GameFontNormalSmall:GetFont()
return file, flags
end

-- Принудительный пересчёт габаритов: вызывается из ApplyLayout при каждом
-- реальном проходе. Раньше фреймы пересчитывали размер только внутри своих
-- updateFunc (текст -> resizeToFit); если текст панели не менялся, SetSize
-- не вызывался вовсе и изменения отступов X/Y «не работали», пока не
-- приходило следующее событие с новым текстом.
-- ВАЖНО: здесь пересчитывается ТОЛЬКО размер (resizeToFit), без повторного
-- вызова update — полный проход ниже идёт уже после позиционирования и
-- показа панелей. Если бы мы дёргали updateFunc до positionChain, любая
-- запись текста меняла бы ширину фрейма ПОСЛЕ его якорения и панель
-- «прыгала»/перекрывала соседей; кроме того скрытые панели обновлялись
-- зря.
local function forceResize(f)
	if not f then return end
	if f._lpsResizeToFit then f._lpsResizeToFit() end
end

if frames.location then
frames.location._lpsPaddingX = locPaddingX
frames.location._lpsPaddingY = locPaddingY
frames.location._lpsMinWidth = locMinWidth
forceResize(frames.location)
end
for key, f in pairs(frames) do
if key ~= "holder" and key ~= "location" and key ~= "minimapButton" and f then
f._lpsPaddingX = dtPaddingX
f._lpsPaddingY = dtPaddingY
f._lpsMinWidth = dtMinWidth
forceResize(f)
end
end

local showDT = layout.dtshow ~= false -- layout.dtshow уже нормализован в bool (_NormalizeLayoutDB)

local sideSlots = layout.sideSlots or {}

local function normalizeSlotFrameKey(key)
if not key or key == "" then return "NONE" end
if key == "none" then return "NONE" end
if key == "None" then return "NONE" end
return key
end

-- Собираем активные слоты в цепочки left[] / right[] (slotN1 — ближайший к локации)
local leftChain, rightChain = {}, {}
for _, side in ipairs({ "left", "right" }) do
	-- сначала слот 1 (ближе к локации), затем 2, 3 — привязка идёт по цепочке
	for i = 1, math.max(tonumber(layout.slotCount) or 2, 2) do
		local cfg = sideSlots[side .. i]
		if cfg then
			local key = normalizeSlotFrameKey(cfg.frame)
			if key ~= "NONE" then
				local entry = { key = key, cfg = cfg, side = side }
				if side == "left" then leftChain[#leftChain + 1] = entry
				else rightChain[#rightChain + 1] = entry end
			end
		end
	end
end
local slotList = {}
for _, e in ipairs(leftChain) do slotList[#slotList + 1] = e end
for _, e in ipairs(rightChain) do slotList[#slotList + 1] = e end

-- Все панели (в т.ч. coords/time/gold/system, переписанные на общий реестр
-- LPS:RegisterDatatext()) создаются одним конструктором GetOrCreatePanelFrame.
-- Раньше здесь были отдельные ветки `return frames.coords` и т.п.: после
-- перевода этих панелей в реестр их фреймы больше не создаются в
-- CreateAllFrames, а такие ветки возвращали nil — positionChain не ставил
-- панели в цепочку, applyPanelVisibility скрывал несуществующие фреймы, и
-- gold/coords/system/time «вообще не отображались».
local function getFrameByKey(key)
	if LPS.GetOrCreatePanelFrame then return LPS:GetOrCreatePanelFrame(key) end
	return nil
end

-- Гарантированно создаём фреймы всех занятых слотов ДО позиционирования и
-- до applyPanelVisibility (иначе SetShown вызывается для ещё не созданных
-- панелей и они остаются скрытыми до следующего прохода layout'а).
for _, e in ipairs(slotList) do
	local f = getFrameByKey(e.key)
	if f then frames[e.key] = f end
end

-- Цепочки боковых панелей:
-- ЛЕВЫЕ панели привязываются к ЛЕВОЙ стороне группы (первая — к левому краю
-- локации, каждая следующая — к левому краю предыдущей панели).
-- ПРАВЫЕ панели привязываются к ПРАВОЙ стороне группы (первая — к правому
-- краю локации, каждая следующая — к правому краю предыдущей панели).
-- Опция db.layout.chainAnchor = "location" меняет якорь ПЕРВОЙ панели цепочки
-- с края локации на край holder'а (внешний край всей сборки).
local function useHolderAnchor()
	local db = LPS.GetDB and LPS:GetDB()
	local lay = db and db.layout
	return lay ~= nil and lay.chainAnchor == "location" and true or false
end

local function positionChain(chain, side)
	local isLeft = (side == "LEFT")
	-- ownPoint: для левых панелей это их RIGHT-край (он прижимается к левой
	-- стороне группы), для правых — их LEFT-край (прижимается к правой стороне).
	local ownPoint = isLeft and "RIGHT" or "LEFT"
	local edgePoint = isLeft and "LEFT" or "RIGHT"
	local sign = isLeft and -1 or 1
	-- Первая панель цепляется за левый/правый КРАЙ локации; при chainAnchor =
	-- "location" — за соответствующий край holder'а (внешний край сборки).
	local anchorTo, anchorPoint = frames.location, edgePoint
	local seen = {}
	for idx = 1, #chain do
		local entry = chain[idx]
		local key = entry.key
		if not seen[key] then
			seen[key] = true
			local frame = getFrameByKey(key)
			if frame then
				local ox = tonumber(entry.cfg.offsetX) or 0
				local oy = tonumber(entry.cfg.offsetY) or 0
				frame:ClearAllPoints()
				if idx == 1 and useHolderAnchor() then
					local base = (frames.holder and frames.holder.IsShown and frames.holder:IsShown()) and frames.holder or frames.location
					anchorTo, anchorPoint = base, edgePoint
				end
				-- Смещение sign*spacing; у первой панели offset не применяется
				-- (панель стоит вплотную к краю локации), чтобы не было разрывов.
				local dx = ((idx == 1) and 0 or (sign * spacing)) + ox
				frame:SetPoint(ownPoint, anchorTo, anchorPoint, dx, oy)
				-- Следующая панель цепляется за КРАЙ этой же стороны:
				-- левые — за левый край предыдущей, правые — за правый.
				anchorTo, anchorPoint = frame, edgePoint
			end
		end
	end
end

positionChain(leftChain, "LEFT")
positionChain(rightChain, "RIGHT")

-- Показываем/скрываем панели строго по настройкам ("Показывать панели" и
-- занятым слотам). Без этого вызова фреймы, созданные без hidden = true
-- (coords/time/gold/system), оставались видимыми всегда.
applyPanelVisibility(frames, slotList, showDT)

-- Первичное заполнение панелей, показанных в этом же проходе:
-- текст ставится сразу, без ожидания события/тикера.
if LPS._pendingPanelPrimes then
	for _, f in ipairs(LPS._pendingPanelPrimes) do
		if f and f:IsShown() and f._lpsUpdateFunc then
			f._lpsUpdateFunc(f)
			if f._lpsResizeToFit then f._lpsResizeToFit() end
		end
	end
	LPS._pendingPanelPrimes = nil
end

if frames.holder and not frames.holder.isMoving then
if layout.frameStrata then
frames.holder:SetFrameStrata(layout.frameStrata)
end
if layout.frameLevel then
frames.holder:SetFrameLevel(tonumber(layout.frameLevel) or 1)
end
end

local fontFile, defaultFlags = resolveFont()
local size = (db.settings and db.settings.fontSize) or 12
local flags = defaultFlags or "NONE"
local fontChanged = false
local fontSizeChanged = false
local fontKey = tostring(fontFile) .. "|" .. tostring(size) .. "|" .. tostring(flags)
-- Список стилизуемых панелей строится по КЛЮЧАМ frames[]. Раньше сюда
-- добавлялись frames.time/coords/gold/system напрямую: после перевода этих
-- панелей на общий реестр их фреймы могут ещё не существовать (создаются
-- лениво), и nil-элементы ломали цикл стилизации. location исключается —
-- у него собственный режим цвета (getLayoutTextColor/customColor).
local styledFrames = {}
for key, f in pairs(frames) do
if key ~= "holder" and key ~= "minimapButton" and type(f) == "table" and f.text then
styledFrames[#styledFrames + 1] = f
end
end
for _, f in ipairs(styledFrames) do
if f and f.text then
if f._lpsAppliedFontKey ~= fontKey then
f._lpsAppliedFontKey = fontKey
f.text:SetFont(fontFile, size, flags)
fontChanged = true
fontSizeChanged = true
elseif f._lpsAppliedFontSize ~= size then
-- Размер мог измениться без смены файла/флагов шрифта — пересчитываем панель.
fontSizeChanged = true
end
f._lpsAppliedFontSize = size
local mode = layout.customColor
if mode == nil then
mode = 3
end
local r, g, b
if f == LPS.frame.location then
-- Локация исключена из общей раскраски: её цвет всегда управляется
-- своим updateFunc по статусу зоны — см. Modules/Frames/location.lua
elseif f._lpsForceWhite then
-- gold/time всегда белые; флаг ставится модулями панелей
r, g, b = 1, 1, 1
elseif mode == 3 then
r, g, b = LPS:GetColor("text")
else
r, g, b = getLayoutTextColor(mode, layout.userColor)
end
if r then
local nr, ng, nb = f.text:GetTextColor()
if math.abs(nr - r) > 0.001 or math.abs(ng - g) > 0.001 or math.abs(nb - b) > 0.001 then
f.text:SetTextColor(r, g, b)
fontChanged = true
end
end
end
end

-- Re-run updates after font is applied so auto-sizing uses correct font metrics.
local layoutNumsChanged = ((prevKey ~= nil) and (prevKey ~= layoutKey)) or forcePass
if fontChanged or fontSizeChanged or layoutNumsChanged or forcePass then
for key, f in pairs(frames) do
if key ~= "holder" and key ~= "minimapButton" and f and f._lpsUpdateFunc then
f._lpsUpdateFunc(f)
end
end
end

-- Первый проход (или смена layout-чисел при скрытом локации): гарантируем
-- пересчёт размеров локации и панелей даже если updateFuncы выше ничего
-- не поменяли (текст уже был актуален) — иначе настройки "Макета"
-- (padding / minWidth) выглядят "не работающими".
if firstPass or layoutNumsChanged then
local loc = frames.location
if loc and loc._lpsUpdateFunc then
loc._lpsUpdateFunc(loc)
end
-- coords/time/gold/system теперь обычные панели реестра RegisterDatatext и
-- лежат в frames[] под своими ключами — отдельный список из четырёх
-- ipairs({frames.coords, ...}) устарел (он молча ничего не делал, когда
-- фреймы ещё не были созданы). Пересчитываем ВСЕ показанные панели.
for key, f in pairs(frames) do
if key ~= "holder" and key ~= "location" and key ~= "minimapButton"
and type(f) == "table" and f._lpsUpdateFunc and f.IsShown and f:IsShown() then
f._lpsUpdateFunc(f)
end
end
end


if LPS.UpdateFrameSize then
LPS:ScheduleFrameSizeUpdate()
end

if frames.holder then
frames.holder._lpsEverApplied = true
end
end

function LPS:ConvertRGBtoColorString(color)
	if not color then color = { r = 1, g = 1, b = 1 } end

	local colorString = "|cff";
	local r = color.r * 255;
	local g = color.g * 255;
	local b = color.b * 255;
	colorString = colorString..string.format("%02x%02x%02x", r, g, b);
	
	return colorString;
end

function LPS:ApplyDTVisibility()
if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
LPS:ApplyLayout()
end

function LPS:ApplyTimeVisibility()
if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
LPS:ApplyLayout()
end

function LPS:ApplyCoordsVisibility()
if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
LPS:ApplyLayout()
end

function LPS:ApplyVisibility()
	local db = LPS:GetDB()
	local holder = LPS.frame and LPS.frame.holder
	if not db or not holder or not db.show or not db.show.visibility then return end

	local vis = db.show.visibility

	if vis.combat then
		if not holder._lpsCombatVisEvents then
			holder._lpsCombatVisEvents = true
			holder:RegisterEvent("PLAYER_REGEN_DISABLED")
			holder:RegisterEvent("PLAYER_REGEN_ENABLED")
			holder:HookScript("OnEvent", function()
				local d = LPS:GetDB()
				local h = LPS.frame and LPS.frame.holder
				if not d or not h or not d.show or not d.show.visibility then return end
				if d.show.visibility.combat and InCombatLockdown() then
					h:Hide()
				else
					h:Show()
				end
			end)
		end
		if InCombatLockdown() then
			holder:Hide()
		else
			holder:Show()
		end
	else
		if holder._lpsCombatVisEvents then
			holder._lpsCombatVisEvents = nil
			holder:UnregisterEvent("PLAYER_REGEN_DISABLED")
			holder:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		holder:Show()
	end

	if not holder.isMoving then
		holder:EnableMouse(false)
	end
	holder:SetAlpha(1)
end

-- Сброс настроек панелей БЕЗ опоры на LPS.defaults.panels (таблица удалена):
-- очищаем db.panels (все панели снова включены по умолчанию), вычищаем панели
-- из слотов layout.sideSlots (кроме зарезервированных) и закрываем созданные
-- фреймы инфотекстов, чтобы они пересоздались при следующем ApplyLayout.
function LPS:ResetPanelsToDefaults()
        local db = self:GetDB()
        if not db then return end

        db.panels = nil

        -- Сброс панелей = дефолтные слоты (left1="gold", right1="system").
        -- Раньше здесь только «вычищали» незарезервированные панели, помечая
        -- тронутые слоты в userTouched; после этого ApplyDefaults никогда не
        -- возвращал дефолты и сборки оставались с пустыми слотами. Теперь слоты
        -- полностью пересоздаются из копии LPS.defaults.layout.sideSlots, а
        -- userTouched очищается — миграция в ApplyDefaults сама назначит
        -- дефолтные панели в нетронутые слоты.
        if type(db.layout) == "table" then
                local defSS = (LPS.defaults and LPS.defaults.layout and LPS.defaults.layout.sideSlots) or {}
                local fresh = {}
                for name, slot in pairs(defSS) do
                        if name ~= "userTouched" and type(slot) == "table" then
                                fresh[name] = { frame = slot.frame, offsetX = 0, offsetY = 0 }
                        end
                end
                fresh.userTouched = {}
                db.layout.sideSlots = fresh
        end

        -- Закрываем созданные фреймы инфотекстов, чтобы они пересоздались.
        -- ВАЖНО: `reserved` в этом файле не определена — раньше строка
        -- `not reserved[k]` бросала "attempt to index a nil value" и весь
        -- сброс панелей падал (что ощущалось как «настройки не применяются»).
        if LPS.frame then
                for k, f in pairs(LPS.frame) do
                        if type(f) == "table" and k ~= "holder" and k ~= "location" and k ~= "minimapButton"
                                and LPS.datatexts and LPS.datatexts[k] then
                                f:Hide()
                                if f.UnregisterAllEvents then f:UnregisterAllEvents() end
                                if f._lpsTicker then f._lpsTicker:Cancel(); f._lpsTicker = nil end
                                LPS.frame[k] = nil
                        end
                end
        end

        -- Слоты только что перезаписаны дефолтами; ApplyDefaults при следующем
        -- запуске не должен вернуть старые userTouched-метки из наследуемой
        -- таблицы AceDB — перестраховываемся явно.
        if db.layout and type(db.layout.sideSlots) == "table" then
                db.layout.sideSlots.userTouched = {}
        end

        -- Пересоздаём фреймы из актуального db.layout (отступы/minWidth),
        -- затем принудительно перерисовываем layout с инвалидацией кэша.
        if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
        if LPS.ApplyAllSettings then LPS:ApplyAllSettings() end
        if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
        if LPS.ApplyLayout then LPS:ApplyLayout() end
        if LPS.UpdateFrameSize then LPS:UpdateFrameSize() end
end

function LPS:ResetAllSettingsToDefaults()
	-- Сначала пробуем штатный сброс AceDB (он корректно снимает дефолты и
	-- чистит пустые секции). Если он недоступен или падает — вручную
	-- перезаписываем содержимое SavedVariables.
	local resetDone = false
	if LPS.db and LPS.db.ResetProfile then
		local ok = pcall(function() LPS.db:ResetProfile() end)
		resetDone = ok and true or false
		if resetDone and LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
	end
	if not resetDone then
		-- Сброс без ResetProfile: переписываем СОДЕРЖИМОЕ текущего объекта
		-- SavedVariables, а не заменяем саму таблицу. WoW при сохранении пишет
		-- тот объект, на который указывает ГЛОБАЛЬНАЯ переменная LPS_DB; если
		-- подменить её новым объектом, старые ссылки (в т.ч. внутри AceDB и
		-- кешей) останутся на прежней таблице и записанные настройки «исчезнут»
		-- после /reload — ровно симптом «всё возвращается к defaults».
		local newProf = CopyTable(LPS.defaults)
		if type(newProf) ~= "table" then newProf = {} end
		newProf.gold = nil
		local function resetApply()
			_G.LPS_DB = _G.LPS_DB or {}
			if type(_G.LPS_DB) ~= "table" then return end
			-- Миграция плоской структуры в профилевую, если нужно.
			if not _G.LPS_DB.profiles then
				local flat = {}
				for k, v in pairs(_G.LPS_DB) do
					if k ~= "global" and k ~= "profiles" and k ~= "profileKeys" and k ~= "char" and k ~= "realm"
						and k ~= "class" and k ~= "race" and k ~= "faction" and k ~= "factionrealm" and k ~= "gold" then
						flat[k] = v
						_G.LPS_DB[k] = nil
					end
				end
				_G.LPS_DB.profiles = { Default = flat }
			end
			-- Сохраняем глобальные данные (золото/реалмы): они не относятся к
			-- настройкам профиля и не должны сбрасываться.
			_G.LPS_DB.global = _G.LPS_DB.global or {}
			if type(_G.LPS_DB.gold) == "table" and not _G.LPS_DB.global.gold then
				_G.LPS_DB.global.gold = _G.LPS_DB.gold
			end
			_G.LPS_DB.gold = nil
			-- Заменяем содержимое ВСЕХ профилей свежими дефолтами (пользователь
			-- просит полный сброс), но сами таблицы profiles/global/profileKeys
			-- не трогаем — ссылка на SavedVariables остаётся валидной.
			for pname in pairs(_G.LPS_DB.profiles) do
				if pname ~= "Default" then
					_G.LPS_DB.profiles[pname] = nil
				else
					_G.LPS_DB.profiles.Default = newProf
				end
			end
			if _G.LPS_DB.profiles.Default == nil then
				_G.LPS_DB.profiles.Default = newProf
			end
			-- Все привязки персонажей переводим на Default (саму таблицу
			-- profileKeys не удаляем — её может хранить ссылка старого db.keys).
			if type(_G.LPS_DB.profileKeys) == "table" then
				for k in pairs(_G.LPS_DB.profileKeys) do
					_G.LPS_DB.profileKeys[k] = "Default"
				end
			end
		end
		resetApply()
		-- Если AcceDB доступен — пересоздаём БД поверх ТОГО ЖЕ объекта sv
		-- (AceDB:New принимает имя глобала и использует текущий _G.LPS_DB),
		-- чтобы db.sv совпадал с тем, что сериализует WoW.
		if LibStub and LibStub:GetLibrary("AceDB-3.0", true) and LPS.defaults then
			local ok = pcall(function()
				local AceDB = LibStub("AceDB-3.0")
				LPS.db = AceDB:New("LPS_DB", { profile = LPS.defaults, global = { gold = { realms = {} } } }, "Default")
				if LPS.db and LPS.db.RegisterCallback then
					LPS.db.RegisterCallback(LPS, "OnProfileChanged", "OnAceProfileChanged")
					LPS.db.RegisterCallback(LPS, "OnProfileCopied", "OnAceProfileCopied")
					LPS.db.RegisterCallback(LPS, "OnProfileReset", "OnAceProfileReset")
				end
			end)
			if not ok then LPS.db = nil end
		end
		if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
	end
	-- Сброс настроек должен вернуть и вид панелей: закрываем созданные фреймы
	-- инфотекстов (кроме зарезервированных coords/time/gold/system), чтобы они
	-- пересоздались с дефолтовыми значениями при следующем ApplyLayout
	if LPS.frame then
		for _, k in ipairs({ "bags", "combatIndicator",
			"difficulty", "durability", "experience", "friends", "guild", "itemLevel", "mail",
			"microBar", "volume" }) do
			local f = LPS.frame[k]
			if f then
				f:Hide()
				if f.UnregisterAllEvents then f:UnregisterAllEvents() end
				if f._lpsTicker then f._lpsTicker:Cancel(); f._lpsTicker = nil end
				LPS.frame[k] = nil
			end
		end
	end
	if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
	LPS:ApplyHolderPosition()
	LPS:ApplyAllSettings()
	if LPS.UpdateMinimapButton then
		LPS:UpdateMinimapButton()
	end
	if LPS.CreateMinimapButton then
		LPS:CreateMinimapButton()
	end
end

function LPS:RefreshAfterProfileChange()
	if self.InvalidateDBCache then self:InvalidateDBCache() end
	if self.InvalidateLayoutCache then self:InvalidateLayoutCache() end
	local db = self:GetProfileDB()
	if self.ApplyDefaults then
		self:ApplyDefaults(db or {}, self.defaults)
	end
	if self.ApplyHolderPosition then
		self:ApplyHolderPosition()
	end
	if self.ApplyAllSettings then
		self:ApplyAllSettings()
	end
	if self.UpdateMinimapButton then
		self:UpdateMinimapButton()
	end
	if self.CreateMinimapButton then
		self:CreateMinimapButton()
	end
	if self.ApplyLayout then
		self:ApplyLayout()
	end
end

function LPS:OnAceProfileChanged()
	self:RefreshAfterProfileChange()
end

function LPS:OnAceProfileCopied()
	self:RefreshAfterProfileChange()
end

function LPS:OnAceProfileReset()
	self:RefreshAfterProfileChange()
end

local Tourist
if LibStub then
	if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
		Tourist = LibStub("LibTourist-3.0")
	elseif LPS.TBC and LibStub:GetLibrary("LibTouristClassicBCA", true) then
		Tourist = LibStub("LibTouristClassicBCA")
	elseif LPS.Mists and LibStub:GetLibrary("LibTouristClassic-1.0", true) then
		Tourist = LibStub("LibTouristClassic-1.0")
	elseif LPS.Classic and LibStub:GetLibrary("LibTouristClassicEra", true) then
		Tourist = LibStub("LibTouristClassicEra")
	end
end
LPS.Tourist = Tourist

-- Локализация: таблица переводов заполняется файлами Locales/*.lua
-- (по образцу Addons/CharacterStats/*, без AceLocale).
-- enUS.lua создаёт LPS.L, остальные локали дописывают переводы в неё.
LPS.L = LPS.L or {}
local Locale = LPS.L

-- Выводит сообщение в чат с префиксом аддона и поддержкой локализации
--- @param msg string Сообщение
--- @param isTranslate boolean Флаг перевода msg
function LPS:Print(msg, isTranslate)
	if isTranslate ~= false then
		msg = LPS:L(msg)
	end
	print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: " .. tostring(msg))
end

-- Возвращает локализованную строку по ключу или сам ключ, если перевода нет
function LPS:L(key)
	local val = rawget(Locale, key)
	if val ~= nil then
		return val
	end

	if LPS.DEBUG then
		LPS:Print("Missing locale: |cFFE24444"..tostring(key).."|r", false)
	end

	return key
end

-- Принудительно инвалидирует кеши ссылок на БД. Вызывается при любой замене
-- глобала LPS_DB (миграция в onLoaded, сброс настроек), чтобы устаревшие
-- ссылки не приводили к записи настроек «в никуда» (симптом: значения
-- применяются, но после /reload исчезают, потому что WoW сериализует
-- совершенно другой объект SavedVariables).
function LPS:InvalidateDBCache()
	self.profileDB = nil
	self.accountDB = nil
end

function LPS:GetProfileDB()
	-- ВАЖНО: при наличии AceDB НЕ кешируем self.db.profile в self.profileDB.
	-- Если LPS.db пересоздан или глобал LPS_DB заменён, кешеванная ссылка
	-- остаётся на старую таблицу: set() из опций пишет в неё, а на логауте
	-- сериализуется другой объект — настройки «не сохраняются».
	if self.db and self.db.profile then
		return self.db.profile
	end
	if type(LPS_DB) == "table" and LPS_DB.profiles and LPS_DB.profiles.Default then
		self.profileDB = LPS_DB.profiles.Default
		return self.profileDB
	end
	self.profileDB = LPS_DB
	return self.profileDB
end

function LPS:GetAccountDB()
	if self.db and self.db.global then
		return self.db.global
	end
	if self.accountDB then
		return self.accountDB
	end
	LPS_DB = LPS_DB or {}
	LPS_DB.global = LPS_DB.global or {}
	self.accountDB = LPS_DB.global
	return self.accountDB
end

function LPS:GetDB()
	return self:GetProfileDB()
end

function LPS:GetGoldRealmKey()
	if GetNormalizedRealmName then
		return GetNormalizedRealmName() or GetRealmName() or ""
	end
	return GetRealmName() or ""
end

function LPS:GetGoldRoot()
	local a = self:GetAccountDB()
	if a then
		a.gold = a.gold or {}
		return a.gold
	end
	LPS_DB = LPS_DB or {}
	LPS_DB.global = LPS_DB.global or {}
	LPS_DB.global.gold = LPS_DB.global.gold or {}
	return LPS_DB.global.gold
end

-- Сбрасывает позицию основного фрейма к значениям по умолчанию
function LPS:ResetFramePosition()
	local db = LPS:GetDB()
	db.position = { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
	db.layout = db.layout or {}
	db.layout.sideSlots = db.layout.sideSlots or {}
	for _, s in pairs(db.layout.sideSlots) do
		if type(s) == "table" then
			s.offsetX = 0
			s.offsetY = 0
		end
	end
	local holder = LPS.frame and LPS.frame.holder
	if holder and holder.isMoving then
		if LPS.SetMoveMode then
			LPS:SetMoveMode(false)
		end
		holder.isMoving = false
	end
	LPS:ApplyHolderPosition()
	if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
	if LPS.ApplyLayout then
		LPS:ApplyLayout()
	end
	LPS:Print("The frame position is reset")
end

-- Включает или выключает режим перемещения фрейма
function LPS:ToggleMoveMode()
	local holder = LPS.frame and LPS.frame.holder
	if not holder then return end
	local moving = holder.isMoving or false
	LPS:SetMoveMode(not moving)
	holder.isMoving = not moving
end

-- Возвращает ID континента, на котором находится игрок
function LPS:GetContinentID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	local mapInfo = C_Map.GetMapInfo(mapID)
	return mapInfo and mapInfo.parentMapID or nil
end


-- Единственная реализация имени континента: подъём по иерархии карт до
-- Continent/World (корректно и для зон, и для городов-анклавов).
function LPS:GetContinentName()
	local currentMapID = C_Map.GetBestMapForUnit("player")
	if not currentMapID then
		return UNKNOWN
	end

	local mapID = currentMapID
	local continentName
	for _ = 1, 10 do
		local mapInfo = C_Map.GetMapInfo(mapID)
		if not mapInfo then break end
		if mapInfo.mapType == Enum.UIMapType.Continent or mapInfo.mapType == Enum.UIMapType.World then
			continentName = mapInfo.name
			break
		end
		if mapInfo.parentMapID and mapInfo.parentMapID ~= 0 then
			mapID = mapInfo.parentMapID
		else
			if not continentName then continentName = mapInfo.name end
			break
		end
	end

	return continentName or UNKNOWN
end

-- Возвращает статус зоны (PVP/мирная и т.п.), опционально цвет или цветной текст
function LPS:GetZoneStatus(color)
	local status = ""
	local r, g, b = 1, 1, 0
	local pvpType = C_PvP.GetZonePVPInfo()
	local inInstance = IsInInstance()

	if pvpType == "sanctuary" then
		status = SANCTUARY_TERRITORY; r, g, b = 0.41, 0.8, 0.94
	elseif pvpType == "arena" then
		status = ARENA; r, g, b = 1, 0.1, 0.1
	elseif pvpType == "friendly" then
		status = FRIENDLY; r, g, b = 0.1, 1, 0.1
	elseif pvpType == "hostile" then
		status = HOSTILE; r, g, b = 1, 0.1, 0.1
	elseif pvpType == "contested" then
		status = CONTESTED_TERRITORY; r, g, b = 1, 0.7, 0.1
	elseif pvpType == "combat" or inInstance then
		status = COMBAT; r, g, b = 1, 0.1, 0.1
	else
		status = CONTESTED_TERRITORY
	end

	if color then
		return r, g, b
	end
	return format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status)
end

-- Возвращает отформатированное игровое время с учетом CVar (12/24ч, локальное/серверное)
local function rgbToHex(r, g, b)
	r = tonumber(r) or 1
	g = tonumber(g) or 1
	b = tonumber(b) or 1
	local rr = math.floor(r * 255 + 0.5)
	local gg = math.floor(g * 255 + 0.5)
	local bb = math.floor(b * 255 + 0.5)
	return string.format("%02x%02x%02x", rr, gg, bb)
end

function LPS:GetFormattedGameTime()
	local db = LPS:GetDB()
	local layout = db and db.layout or {}
	local is24h = db and db.general and db.general.is24H
	local useLocal = GetCVarBool("timeMgrUseLocalTime")

	local mode = layout.customColor
	if mode == nil then
		mode = 3
	end
	local r, g, b
	if mode == 1 then
		local user = layout.userColor
		r, g, b = (user and user.r) or 1, (user and user.g) or 1, (user and user.b) or 1
	elseif mode == 2 then
		r, g, b = getClassColor()
	else
		r, g, b = 1, 1, 1
	end
	local colon = "|cff" .. rgbToHex(r, g, b) .. ":|r"

	local h, m, s
	if useLocal then
		local t = date("*t")
		h, m, s = t.hour, t.min, t.sec
	else
		h, m = GetGameTime()
	end

	local showSeconds = db.general.seconds and useLocal
	if not is24h then
		local suffix = (h >= 12) and "PM" or "AM"
		h = h % 12
		if h == 0 then h = 12 end
		if showSeconds then
			return string.format("%02d%s%02d%s%02d %s", h, colon, m, colon, s, suffix)
		else
			return string.format("%02d%s%02d %s", h, colon, m, suffix)
		end
	end

	if showSeconds then
		return string.format("%02d%s%02d%s%02d", h, colon, m, colon, s)
	else
		return string.format("%02d%s%02d", h, colon, m)
	end
end

-- Применяет значения по умолчанию к таблице базы данных рекурсивно
function LPS:ApplyDefaults(db, defaults)
	if type(db) ~= "table" then db = {} end
	-- Защита от записи в источник дефолтов: если профиль ещё не содержит
	-- ключа, AceDB-наследование может отдать В ТОЧНОСТИ таблицу из
	-- LPS.defaults. Рекурсия ниже дописывала бы недостающие поля прямо в
	-- defaults — после этого «дефолты» портились на весь аккаунт, а любые
	-- последующие сбросы/смены профилей давали бы мусор («настройки не
	-- сохраняются, всегда применяются default»). Заменяем ссылку копией.
	if rawequal(db, defaults) then
		local copy = {}
		for k, v in pairs(db) do copy[k] = v end
		return copy
	end

	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = LPS:ApplyDefaults(db[k], v)
		elseif db[k] == nil and k ~= "addonTextColor" then
			db[k] = v
		end
	end

	if defaults.layout and db.layout and type(db.layout) == "table" then
		local defL = defaults.layout
		-- Guard: db.layout может быть ТО на таблице дефолтов (AceDB-
		-- наследование). Записи ниже (dtshow/sideSlots/offsetX...) иначе
		-- портили бы сам источник дефолтов — из-за этого gold/system
		-- «исчезали навсегда».
		if rawequal(db.layout, defaults.layout) then
			local copy = {}
			for k, v in pairs(db.layout) do copy[k] = v end
			if type(copy.sideSlots) == "table" then
				local ssCopy = {}
				for k, v in pairs(copy.sideSlots) do
					if type(v) == "table" then
						local t = {}
						for kk, vv in pairs(v) do t[kk] = vv end
						ssCopy[k] = t
					else
						ssCopy[k] = v
					end
				end
				copy.sideSlots = ssCopy
			end
			db.layout = copy
		end
		if defL.sideSlots ~= nil and rawequal(db.layout.sideSlots, defL.sideSlots) then
			local ssCopy = {}
			for k, v in pairs(defL.sideSlots) do
				if type(v) == "table" then
					local t = {}
					for kk, vv in pairs(v) do t[kk] = vv end
					ssCopy[k] = t
				else
					ssCopy[k] = v
				end
			end
			ssCopy.userTouched = {}
			db.layout.sideSlots = ssCopy
		end
		for _, key in ipairs({"dtPaddingX","dtPaddingY","dtMinWidth","locPaddingX","locPaddingY","locMinWidth","frameLevel","spacingManual"}) do
			if tonumber(db.layout[key]) == nil then db.layout[key] = defL[key] end
		end
		if db.layout.dtshow == nil then db.layout.dtshow = defL.dtshow end
		if db.layout.spacingAuto == nil then db.layout.spacingAuto = defL.spacingAuto end
		if db.layout.customColor == nil then db.layout.customColor = defL.customColor end
		if db.layout.frameStrata == nil or db.layout.frameStrata == "" then db.layout.frameStrata = defL.frameStrata end
		if type(db.layout.userColor) ~= "table" then db.layout.userColor = { r = 1, g = 1, b = 1 } end
		if type(db.layout.sideSlots) ~= "table" then db.layout.sideSlots = {} end
		local ss = db.layout.sideSlots
		-- Защита от общей таблицы: если профиль по наследованию AceDB
		-- указывает ТО на LPS.defaults.layout.sideSlots, делаем копию —
		-- иначе миграция/дефолты записывались бы прямо в таблицу дефолтов
		-- и «сжигали» left1/right1 для всех будущих профилей.
		if defL.sideSlots ~= nil and rawequal(ss, defL.sideSlots) then
			local copy = {}
			for k, v in pairs(ss) do
				if type(v) == "table" then
					local t = {}
					for kk, vv in pairs(v) do t[kk] = vv end
					copy[k] = t
				else
					copy[k] = v
				end
			end
			copy.userTouched = {}
			db.layout.sideSlots = copy
			ss = db.layout.sideSlots
		end
		-- Слоты, которые пользователь назначал/чистил вручную (не перетираем
		-- дефолтами при миграции). Проставляется в set-функциях опций.
		if type(ss.userTouched) ~= "table" then ss.userTouched = {} end

		-- Миграция со старой схемы {left, right} на нумерованные слоты {left1..left3, right1..right3}
		for _, side in ipairs({"left","right"}) do
			local oldSlot = ss[side]
			if type(oldSlot) == "table" then
				if ss[side .. "1"] == nil then
					ss[side .. "1"] = { frame = oldSlot.frame, offsetX = oldSlot.offsetX, offsetY = oldSlot.offsetY }
					ss.userTouched[side .. "1"] = true
				end
				ss[side] = nil
			elseif oldSlot ~= nil then
				ss[side] = nil
			end
		end
		-- Удалённый фрейм «Задания» (quests): панель больше не регистрируется,
		-- поэтому чистим слоты с ней при каждой загрузке профиля — иначе
		-- ApplyLayout молча пропустит несуществующую панель.
		for _, slot in pairs(ss) do
			if type(slot) == "table" and slot.frame == "quests" then
				slot.frame = "NONE"
			end
		end
		if tonumber(db.layout.slotCount) == nil then db.layout.slotCount = defL.slotCount or 3 end
		for i = 1, 3 do
			for _, side in ipairs({"left","right"}) do
				local name = side .. i
				local s = ss[name]
				if type(s) ~= "table" then
					s = {}
					ss[name] = s
				end
				local defS = defL.sideSlots and defL.sideSlots[name]
				-- ВАЖНО: условие включает и "NONE": при AceDB-наследовании пустой профиль
				-- может отдать в db.layout.sideSlots саму таблицу дефолтов (та же ссылка),
				-- и предыдущие прогоды ApplyDefaults записывали в неё "NONE" — из-за этого
				-- gold/system терялись навсегда («панели вообще не отображаются»).
				if not ss.userTouched[name] and defS and (s.frame == nil or s.frame == "" or s.frame == "NONE") then
					-- слот ещё никогда не настраивался пользователем -> назначаем
					-- панель по умолчанию, чтобы первая группа фреймов была видима
					-- сразу после установки (или после сброса настроек).
					s.frame = defS.frame
				elseif s.frame == nil or s.frame == "" then
					s.frame = "NONE"
				end
				if tonumber(s.offsetX) == nil then s.offsetX = 0 end
				if tonumber(s.offsetY) == nil then s.offsetY = 0 end
			end
		end
	end

	return db
end

-- Возвращает цвет из настроек аддона по ключу
-- (unpackFn — единый upvalue в начале файла: table.unpack or unpack)
function LPS:GetColor(key)
	local db = LPS:GetDB()
	local colors = db.settings and db.settings.colors
	local c = colors and colors[key]
	if key == "bg" and colors and colors.bgEnable == false then
		local r, g, b = unpackFn(c or {0, 0, 0, 0})
		return r, g, b, 0
	end
	return unpackFn(c or {1, 1, 1, 1})
end

local refreshPending = false
-- Флаг «грязных» установок: ApplyLayout может завершиться раньше, чем что-либо
-- пересчитает (выход по совпадению layoutKey), а гонкая ScheduleRefresh
-- (0.05 с) способна слить несколько инвалидаций в один пропуск.
-- pendingRefresh гарантирует, что после ЛЮБОЙ смены настроек будет выполнен
-- хотя бы один полный проход ApplyLayout — иначе правки выглядели бы
-- неприменёнными («настройки не сохраняются»). ОБЪЯВЛЕН ДО
-- LPS._ConsumePendingRefresh, чтобы тот видел его как upvalue, а не nil-global.
local pendingRefresh = false
-- Вызывается из ApplyLayout: возвращает true, если со времён последнего
-- полного прохода была запрошена смена настроек.
function LPS._ConsumePendingRefresh()
if pendingRefresh then
pendingRefresh = false
return true
end
return false
end
function LPS:ScheduleRefresh()
	pendingRefresh = true
	if refreshPending then return end
	refreshPending = true
	C_Timer.After(0.05, function()
		refreshPending = false
		if not pendingRefresh then return end
		pendingRefresh = false
		if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
		if LPS.ApplyLayout then
			LPS:ApplyLayout()
		end
		LPS:UpdateFrameSize()
	end)
end

function LPS:ApplyCoordsUpdateInterval()
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame.coords
	if not f or not f._lpsUpdateFunc then return end
	local interval = tonumber(db.general and db.general.coordsTimeUpdate) or 0.2
	interval = math.max(interval, 0.05)
	if f._lpsTicker then
		f._lpsTicker:Cancel()
		f._lpsTicker = nil
	end
	f._lpsTicker = C_Timer.NewTicker(interval, function()
		if f._lpsUpdateFunc and f:IsShown() and (not f:GetParent() or f:GetParent():IsShown()) then
			f._lpsUpdateFunc(f)
		end
	end)
end

function LPS:ApplyStyle()
	local db = LPS:GetDB()
	local frames = LPS.frame
	if not frames then return end
	for _, f in pairs({frames.location, frames.coords, frames.time, frames.gold, frames.system}) do
		if f then
			local bs = tonumber(db.settings.borderSize)
			if not bs then bs = 2 end
			bs = math.max(0, math.min(bs, 6))
			f:SetBackdrop({
				bgFile   = "Interface\\Buttons\\WHITE8x8",
				edgeFile = (bs > 0 and "Interface\\Buttons\\WHITE8x8") or nil,
				tile     = false,
				edgeSize = bs,
				insets   = {left=1,right=1,top=1,bottom=1},
			})
			if f._lpsUpdateFunc then
				f._lpsUpdateFunc(f)
			end
			f:SetBackdropColor(LPS:GetColor("bg"))
			f:SetBackdropBorderColor(LPS:GetColor("border"))
		end
	end
	if LPS.ApplyLayout then
		LPS:ApplyLayout()
	end
	if LPS.ScheduleFrameSizeUpdate then
		LPS:ScheduleFrameSizeUpdate()
	end
end

function LPS:ApplyTimeFormat()
	local db = LPS:GetDB()

	local f = LPS.frame and LPS.frame.time
	if f and f._lpsUpdateFunc then
		f._lpsUpdateFunc(f)
	end
	if LPS.ApplyLayout then
		LPS:ApplyLayout()
	end
	if LPS.ScheduleFrameSizeUpdate then
		LPS:ScheduleFrameSizeUpdate()
	end
end

function LPS:ApplyAllSettings()
	if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
	LPS:ApplyTimeFormat()
	LPS:ApplyCoordsUpdateInterval()
	LPS:ApplyLayout()
	LPS:ApplyStyle()
	LPS:ApplyVisibility()
end

-- Возвращает координаты игрока на текущей карте
function LPS:GetPlayerCoords()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if pos then
		return pos.x, pos.y
	else
		return
	end
end

-- Обертка для Tourist:GetMapNameByIDAlt(mapID)
function LPS:GetMapNameByIDAlt(mapID)
	if not Tourist then return end
	return Tourist:GetMapNameByIDAlt(mapID) or UNKNOWN
end

function LPS:DisableMoveModeIfActive()
	local holder = LPS.frame and LPS.frame.holder
	if holder and holder.isMoving then
		if LPS.SetMoveMode then
			LPS:SetMoveMode(false)
		end
		holder.isMoving = false
	end
end

function LPS:EnsureOptionsCloseHooks()
	if not LPS._optionsCloseHooks then
		LPS._optionsCloseHooks = {}
	end

	local function hookOnHide(frame, key)
		if not (frame and frame.HookScript) then return end
		if LPS._optionsCloseHooks[key] then return end
		LPS._optionsCloseHooks[key] = true
		frame:HookScript("OnHide", function()
			if LPS.DisableMoveModeIfActive then
				LPS:DisableMoveModeIfActive()
			end
		end)
	end

	hookOnHide(_G.SettingsPanel, "SettingsPanel")
	hookOnHide(_G.InterfaceOptionsFrame, "InterfaceOptionsFrame")
end

--- Переключить нативное окно настроек (дизайн CharacterStats, без Ace3).
function LPS:ToggleNativeOptions()
	if LPS.UI_Options and LPS.UI_Options.Toggle then
		-- Если открыто окно Ace — закрыть его, чтобы не было двух меню сразу
		local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true)
		if aceDialog and LPS.Options and LPS.Options.aceAppName
			and aceDialog.OpenFrames and aceDialog.OpenFrames[LPS.Options.aceAppName] then
			aceDialog:Close(LPS.Options.aceAppName)
		end
		LPS.UI_Options:Toggle()
		return true
	end
	return false
end

--- Открыть/закрыть прежнее меню на AceConfigDialog (если Ace3 доступен).
-- @return true, если окно Ace было открыто/закрыто; false — Ace недоступен.
function LPS:ToggleLegacyMenu()
	local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true) and LibStub("AceConfigDialog-3.0")
	if not (aceDialog and LPS.Options and LPS.Options.aceAppName) then return false end
	if LPS.EnsureOptionsCloseHooks then
		LPS:EnsureOptionsCloseHooks()
	end
	do
		local appName = LPS.Options.aceAppName
		-- Корневая таблица должна быть зарегистрирована в AceConfigRegistry
		-- (регистрация выполняется в options_ace.lua / FinalizeAce). Если её
		-- нет — не звать aceDialog:Open (иначе AceConfigDialog бросает
		-- "<app> isn't registed with AceConfigRegistry, unable to open config"),
		-- а отдаём управление нативному окну настроек.
		local registry = LibStub:GetLibrary("AceConfigRegistry-3.0", true)
		if not (registry and registry.GetOptionsTable and registry:GetOptionsTable(appName)) then
			if LPS.Options.FinalizeAce then
				pcall(LPS.Options.FinalizeAce, LPS.Options)
			end
			if not (registry and registry.GetOptionsTable and registry:GetOptionsTable(appName)) then
				return false
			end
		end
		if aceDialog.OpenFrames and aceDialog.OpenFrames[appName] then
			if LPS.DisableMoveModeIfActive then
				LPS:DisableMoveModeIfActive()
			end
			aceDialog:Close(appName)
		else
			aceDialog:Open(appName)
			local f = aceDialog.OpenFrames and aceDialog.OpenFrames[appName]
			if f then
				if f.EnableResize then
					f:EnableResize(false)
				end
				local frame = f.frame
				if frame and frame.SetResizable then
					frame:SetResizable(false)
				end
				if frame and frame.HookScript then
					LPS._optionsCloseHooks = LPS._optionsCloseHooks or {}
					if not LPS._optionsCloseHooks.AceConfigDialogFrame then
						LPS._optionsCloseHooks.AceConfigDialogFrame = true
						frame:HookScript("OnHide", function()
							if LPS.DisableMoveModeIfActive then
								LPS:DisableMoveModeIfActive()
							end
						end)
					end
				end
			end
		end
		return true
	end
end

--- Главное переключение меню: есть Ace3 — legacy-окно AceConfigDialog,
--- иначе нативное окно (Game/UI/*). Fallback — стандартные панели Blizzard.
function LPS:ToggleOptions()
	if self:ToggleLegacyMenu() then return end
	if self:ToggleNativeOptions() then return end

	if _G.SettingsPanel and _G.SettingsPanel.IsShown and _G.SettingsPanel:IsShown() then
		if LPS.DisableMoveModeIfActive then
			LPS:DisableMoveModeIfActive()
		end
		_G.SettingsPanel:Hide()
		return
	end
	if _G.InterfaceOptionsFrame and _G.InterfaceOptionsFrame.IsShown and _G.InterfaceOptionsFrame:IsShown() then
		if LPS.DisableMoveModeIfActive then
			LPS:DisableMoveModeIfActive()
		end
		_G.InterfaceOptionsFrame:Hide()
		return
	end

	if LPS.Options and LPS.Options.category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(LPS.Options.category:GetID())
	end
end
