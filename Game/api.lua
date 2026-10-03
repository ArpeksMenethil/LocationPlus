local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- ОПТИМИЗАЦИЯ (duplicates): единая реализация цвета класса игрока.
-- Ранее getClassColor был скопирован дважды как closure внутри функций
-- (ApplyLayout и GetFormattedGameTime) и пересоздавался на каждый вызов;
-- теперь это file-level upvalue с кэшем класса, видимая из ApplyLayout выше.
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

-- ОПТИМИЗАЦИЯ: одноразовая нормализация полей layout из БД + миграция ключей.
-- apply-layout раньше на КАЖДЫЙ вызов делал ~10 tonumber() и чтения таблиц —
-- теперь результат кэшируется; повторная нормализация выполняется только при
-- изменении исходной таблицы (слайдеры/чекбоксы в опциях) или явном сбросе
-- кэша (ApplyAllSettings / смена профиля).
-- Миграция "proffession" -> "profession" (исправление опечатки в имени ключа)
-- выполняется один раз за сессию прямо в сохранённой таблице, поэтому старые
-- SavedVariables подхватываются без дублирования настроек.
function LPS:_NormalizeLayoutDB(raw)
	if not raw then
		raw = {}
		local db = LPS:GetDB()
		if db then db.layout = raw end
	end
	-- FIX (баг «пункты меню Макет не применяются»): AceDB при мутациях может
	-- пересоздавать обёртку db.layout (ссылка raw меняется, содержимое то же) —
	-- раньше это приводило к лишним проходам; но опаснее другое: вложенные таблицы
	-- sideSlots.left/right мутируются НА МЕСТЕ (options.lua пишет .frame/.offsetX),
	-- ссылка raw при этом НЕ меняется, и кэш возвращал устаревший out. Теперь для
	-- sideSlots сравниваются ссылки вложенных таблиц + значения frame/offsetX/offsetY.
	local cache = normalizedLayoutCache
	if cache and cache.raw == raw then
		local function slotsUnchanged(prev, cur)
			if prev == cur then return true end
			if type(prev) ~= "table" or type(cur) ~= "table" then return false end
			for _, side in ipairs({"left", "right"}) do
				local a, b = prev[side], cur[side]
				if a ~= b then
					if type(a) ~= "table" or type(b) ~= "table" then return false end
					if a.frame ~= b.frame or a.offsetX ~= b.offsetX or a.offsetY ~= b.offsetY then
						return false
					end
				end
			end
			return true
		end
		if slotsUnchanged(cache.sideSlots, raw.sideSlots) then
			cache.sideSlots = raw.sideSlots
			return cache.out
		end
	end

	local out = cache and cache.out or {}
	-- FIX (пункты меню «Панели»/«Панель локации» применялись только после /reload):
	-- раньше здесь были захардкожены дефолты (10/6/60...), не совпадавшие с
	-- LPS.defaults.layout; затем их убрали полностью — но это лишь переложило
	-- проблему: нормализация кэшируется по ССЫЛКЕ на raw, а AceDB мутирует поля
	-- db.layout.* НА МЕСТЕ (ссылка не меняется). Колбэк слайдера писал новое
	-- значение в БД, ScheduleRefresh инвалидировал кэш, но первый же проход
	-- нормализации видел "cache.raw == raw" и возвращал СТАРЫЙ снимок out со
	-- старыми padding/minWidth — панели пересчитывались по устаревшим числам
	-- (отсюда «левый фрейм не меняется, пока не сделаешь /reload»). Теперь все
	-- числовые поля layout участвуют в проверке актуальности кэша: изменение
	-- любого значения ломает совпадение и форсирует перенормализацию.
	if cache and cache.raw == raw then
		local numericFresh = true
		for _, k in ipairs({ "dtPaddingX", "dtPaddingY", "dtMinWidth",
				"locPaddingX", "locPaddingY", "locMinWidth", "spacingManual" }) do
			if (tonumber(raw[k]) or -999999) ~= (out[k] or -999999) then
				numericFresh = false
				break
			end
		end
		if numericFresh and (raw.spacingAuto == false) ~= (out.spacing ~= 5) then
			numericFresh = false
		end
		if numericFresh and (raw.dtshow == false) ~= (out.dtshow == false) then
			numericFresh = false
		end
		if numericFresh then
			return out
		end
	end
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
	-- ЗАЩИТА (fix «фреймы не показываются»): раньше при отсутствии/повреждении
	-- db.layout нормализация молча подставляла дефолты, а ApplyLayout скрывал
	-- все панели (dtshow=nil → скрыт; sideSlots=nil → слоты NONE).
	-- Теперь пустые поля layout заполняются значениями по умолчанию один раз в БД,
	-- а dtshow трактуется как «скрыт только при явном false» — ровно как в эталоне.
	if raw.dtshow == nil and LPS.defaults and LPS.defaults.layout then
		raw.dtshow = LPS.defaults.layout.dtshow
	end
	if raw.sideSlots == nil and LPS.defaults and LPS.defaults.layout then
		raw.sideSlots = LPS.defaults.layout.sideSlots
	end
	out.dtshow      = raw.dtshow ~= false
	out.frameStrata = raw.frameStrata
	out.frameLevel  = tonumber(raw.frameLevel)
	out.customColor = raw.customColor
	out.userColor   = raw.userColor
	-- FIX (меню Макет / слоты): out хранит ГЛУБОКУЮ копию sideSlots — иначе ссылки на
	-- таблицы БД, которые options.lua мутирует на месте, делали кэш нормализации и
	-- кэш ApplyLayout непредсказуемыми (значения менялись без изменения ключа).
	local function copySlots(slots)
		if type(slots) ~= "table" then return nil end
		local res = {}
		for _, side in ipairs({"left", "right"}) do
			local s = slots[side]
			if type(s) == "table" then
				res[side] = { frame = s.frame, offsetX = s.offsetX, offsetY = s.offsetY }
			else
				res[side] = {}
			end
		end
		return res
	end
	out.sideSlots   = copySlots(raw.sideSlots)
	-- ЗАЩИТА ОТ САМОКЛИКИ КЭША: если нормализованный вывод (включая ссылки на
	-- вложенные таблицы userColor/sideSlots, которые AceDB иногда пересоздаёт)
	-- полностью идентичен прежнему закешированному объекту, оставляем прежний
	-- `out` — иначе ApplyLayout каждый проход видел бы новый layoutKey и
	-- бесконечно перезапускался через C_Timer.After.
	if cache and cache.out == out then
		return out
	end
	normalizedLayoutCache = { raw = raw, out = out, sideSlots = raw.sideSlots }
	return out
end

-- Миграция ключей тултипов location (опечатка proffession -> profession).
function LPS:MigrateTooltipKeys()
	local db = self:GetDB()
	local loc = db and db.tooltips and db.tooltips.location
	if not loc then return end
	if loc.profession == nil and loc.proffession ~= nil then
		loc.profession = loc.proffession
	end
	if loc.professionHideMaxLevel == nil and loc.proffessionHideMaxLevel ~= nil then
		loc.professionHideMaxLevel = loc.proffessionHideMaxLevel
	end
end

function LPS:InvalidateLayoutCache()
	normalizedLayoutCache = nil
	-- FIX: раньше сбрасывался только кэш нормализации, но маркер _lpsLastLayoutKey
	-- внутри ApplyLayout оставался — при смене профиля/сбросе настроек (когда AceDB
	-- пересоздаёт таблицы и ссылки совпадают снова) ApplyLayout мог ложно решить,
	-- что раскладка не менялась, и пропустить переанкеривание.
	local holder = LPS.frame and LPS.frame.holder
	if holder then holder._lpsLastLayoutKey = nil end
end

-- FIX (меню «Макет»: категории «Панели»/«Панель локации» применялись только к
-- правой панели или не применялись до /reload): раньше ЛОГИКА ВИДИМОСТИ панелей
-- существовала в НЕСКОЛЬКИХ копиях (applySideSlotVisibility внутри ApplyLayout,
-- applySideFrameVisibility рядом с ApplyDTVisibility и т.д.), копии со временем
-- разъезжались и противоречили друг другу; плюс нормализация padding/minWidth
-- захардкоженными числами перетирала реальные значения БД. Теперь видимость —
-- единый file-level хелпер ниже; публичные Apply*Visibility лишь делегируют ему.
-- ВАЖНО: видимость определяется ТОЛЬКО dtshow и выбором слота, БЕЗ IsShown():
-- на этапе загрузки UI дочерние панели формально скрыты (родитель ещё не
-- показан), и старая формула "IsShown() and isSelected(...)" молча сбрасывала
-- правильно выбранные панели, а повторный проход блокировался неизменным
-- layoutKey — отсюда «пока не тронешь левый слот, всё стоит справа».
local function applyPanelVisibility(frames, leftSlot, rightSlot, showDT)
	if not frames then return end
	local function normalizeSlotFrameKey(key)
		if not key or key == "" or key == "none" or key == "None" then return "NONE" end
		return key
	end
	local function isSelectedInSlots(frameKey)
		if normalizeSlotFrameKey((leftSlot  and leftSlot.frame))  == frameKey then return true end
		if normalizeSlotFrameKey((rightSlot and rightSlot.frame)) == frameKey then return true end
		return false
	end
	if frames.coords then frames.coords:SetShown(showDT and isSelectedInSlots("coords")) end
	if frames.time   then frames.time:SetShown(showDT   and isSelectedInSlots("time"))   end
	if frames.gold   then frames.gold:SetShown(showDT   and isSelectedInSlots("gold"))   end
	if frames.system then frames.system:SetShown(showDT and isSelectedInSlots("system")) end
end
LPS._ApplyPanelVisibility = applyPanelVisibility -- общий для ApplyLayout и Apply*Visibility

function LPS:ApplyLayout()
local db = LPS:GetDB()
local frames = LPS.frame
if not db or not frames then return end

-- ОПТИМИЗАЦИЯ: нормализация layout кэшируется в LPS:_NormalizeLayoutDB —
-- локальные переменные читаются напрямую, tonumber() на каждый проход больше нет.
local layout = LPS:_NormalizeLayoutDB(db.layout)
local dtPaddingX = layout.dtPaddingX
local dtPaddingY = layout.dtPaddingY
local dtMinWidth = layout.dtMinWidth
local locPaddingX = layout.locPaddingX
local locPaddingY = layout.locPaddingY
local locMinWidth = layout.locMinWidth
local spacing = layout.spacing

-- Внутренний кэш-маркер: если ключ настроек не изменился с прошлого прохода,
-- ApplyLayout пропускает переанкеривание/перекраску (вызывается очень часто).
-- userColor мутируется колбэком ColorPicker "псевдо-на месте", поэтому его
-- компоненты входят в ключ отдельно от ссылки на таблицу.
local user = layout.userColor
local layoutKey = tostring(layout.dtPaddingX) .. "," .. tostring(layout.dtPaddingY) .. ","
.. tostring(layout.dtMinWidth) .. "," .. tostring(layout.locPaddingX) .. ","
.. tostring(layout.locPaddingY) .. "," .. tostring(layout.locMinWidth) .. ","
.. tostring(spacing) .. "," .. tostring(layout.dtshow) .. ","
.. tostring(layout.frameStrata) .. "," .. tostring(layout.frameLevel) .. ","
.. tostring(layout.customColor) .. ","
.. tostring(user and user.r) .. "," .. tostring(user and user.g) .. "," .. tostring(user and user.b) .. ","
.. tostring((layout.sideSlots and layout.sideSlots.left and layout.sideSlots.left.frame) or "") .. ","
.. tostring((layout.sideSlots and layout.sideSlots.right and layout.sideSlots.right.frame) or "") .. ","
-- FIX (баг «слоты/смещения в меню Макет не применяются»): offsetX/offsetY
-- слотов раньше не входили в ключ кэша — ApplyLayout считал, что ничего не
-- изменилось, и молча пропускал переанкеривание фреймов.
.. tostring((layout.sideSlots and layout.sideSlots.left and layout.sideSlots.left.offsetX) or "") .. ","
.. tostring((layout.sideSlots and layout.sideSlots.left and layout.sideSlots.left.offsetY) or "") .. ","
.. tostring((layout.sideSlots and layout.sideSlots.right and layout.sideSlots.right.offsetX) or "") .. ","
.. tostring((layout.sideSlots and layout.sideSlots.right and layout.sideSlots.right.offsetY) or "") .. ","
.. tostring(db.settings and db.settings.fontSize or 12) -- FIX: смена «Размер шрифта» обязана ломать кэш раскладки

-- FIX (оба фрейма справа друг на друге после /reload): ранний выход по неизменному
-- ключу допускался только ПОСЛЕ того, как раскладка реально была применена при
-- видимом holder'е. До этого каждый вызов ApplyLayout (ApplyTimeFormat/ApplyStyle/
-- тикеры/кеши) обязан проходить до конца: на этапе загрузки UI дочерние панели
-- формально скрыты, а их дефолтные якоря из Modules/Frames/*.lua привязаны СПРАВА
-- от локации — без полноценного прохода обе выбранные панели оставались бы
-- наложенными друг на друга справа.
-- FIX (меню «Панели»/«Панель локации»: изменения применялись только к правой
-- панели или только после /reload): форсированный проход. Пока раскладка ни разу
-- не была применена при ВИДИМОМ holder (_lpsEverApplied nil), ApplyLayout обязан
-- пройти до конца и вызвать _lpsUpdateFunc ВСЕХ панелей — иначе левый фрейм
-- оставался с размерами по устаревшим padding/minWidth (пересчёт триггерился
-- только сменой шрифта/цвета или тикером контента, который обновляет лишь одну
-- панель). Ранний выход по неизменному ключу возможен теперь только после того,
-- как хотя бы один полный проход выполнен при видимом holder.
local forcePass = not (frames.holder and frames.holder._lpsEverApplied)
if not forcePass and frames.holder._lpsLastLayoutKey == layoutKey then
return
end
local prevKey = frames.holder and frames.holder._lpsLastLayoutKey
if frames.holder then
frames.holder._lpsLastLayoutKey = layoutKey
end

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

if frames.location then
frames.location._lpsPaddingX = locPaddingX
frames.location._lpsPaddingY = locPaddingY
frames.location._lpsMinWidth = locMinWidth
end
for _, f in pairs({frames.coords, frames.time, frames.gold, frames.system}) do
if f then
f._lpsPaddingX = dtPaddingX
f._lpsPaddingY = dtPaddingY
f._lpsMinWidth = dtMinWidth
end
end

local showDT = layout.dtshow ~= false -- layout.dtshow уже нормализован в bool (_NormalizeLayoutDB)

local sideSlots = layout.sideSlots or {}
local leftSlot = sideSlots.left or {}
local rightSlot = sideSlots.right or {}

local function normalizeSlotFrameKey(key)
if not key or key == "" then return "NONE" end
if key == "none" then return "NONE" end
if key == "None" then return "NONE" end
return key
end

local function isSelectedInSlots(frameKey)
local l = normalizeSlotFrameKey(leftSlot.frame)
local r = normalizeSlotFrameKey(rightSlot.frame)
if l == frameKey then return true end
if r == frameKey then return true end
return false
end

local function getFrameByKey(key)
if key == "coords" then return frames.coords end
if key == "time" then return frames.time end
if key == "gold" then return frames.gold end
if key == "system" then return frames.system end
return nil
end

local function positionSlot(slotCfg, side)
if not (frames.location and slotCfg) then return end
local key = normalizeSlotFrameKey(slotCfg.frame)
if key == "NONE" then return end

-- Prevent anchoring the same frame twice.
local otherKey
if side == "LEFT" then
otherKey = normalizeSlotFrameKey(rightSlot.frame)
else
otherKey = normalizeSlotFrameKey(leftSlot.frame)
end
if otherKey == key then
if side == "RIGHT" then
return
end
end

local frame = getFrameByKey(key)
if not frame then return end
-- Переанкеривание НЕ требует видимости фрейма: на этапе загрузки UI все
-- дочерние панели формально скрыты (родитель ещё не показан), и старая
-- проверка "if not frame:IsShown() then return end" оставляла им дефолтный
-- якорь CreateFrame ("LEFT", location, "RIGHT", 5, 0) — обе панели
-- оказывались справа друг на друге до первого изменения слота.

local ox = tonumber(slotCfg.offsetX) or 0
local oy = tonumber(slotCfg.offsetY) or 0
frame:ClearAllPoints()
if side == "LEFT" then
frame:SetPoint("RIGHT", frames.location, "LEFT", -spacing + ox, oy)
else
frame:SetPoint("LEFT", frames.location, "RIGHT", spacing + ox, oy)
end
end

applyPanelVisibility(frames, leftSlot, rightSlot, showDT)
positionSlot(leftSlot, "LEFT")
positionSlot(rightSlot, "RIGHT")

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
-- ОПТИМИЗАЦИЯ: SetFont/SetTextColor пропускаются, если значение не изменилось
-- (ApplyLayout вызывается очень часто — в т.ч. с каждого чекбокса в опциях).
local fontChanged = false
-- FIX (меню «Макет» -> «Размер шрифта» не работал): ApplyStyle вызывал
-- _lpsUpdateFunc ДО ApplyLayout, т.е. текст ещё рисовался старым размером, а
-- после смены фонта панели никто не пересчитывал — размер оставался прежним.
-- Отдельный флаг гарантирует полный пересчёт именно при смене шрифта.
local fontSizeChanged = false
local fontKey = tostring(fontFile) .. "|" .. tostring(size) .. "|" .. tostring(flags)
for _, f in pairs({frames.location, frames.time, frames.coords, frames.gold, frames.system}) do
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
if f == frames.gold or f == frames.time then
r, g, b = 1, 1, 1
elseif mode == 3 then
if f ~= frames.location then
r, g, b = LPS:GetColor("text")
end
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
-- ОПТИМИЗАЦИЯ: полный пересчёт панелей нужен только при реальной смене шрифта/цвета.
-- ОПТИМИЗАЦИЯ: полный пересчёт панелей нужен при реальной смене шрифта/цвета,
-- при изменении любых layout-чисел (padding/minWidth/spacing — см. layoutKey)
-- и на форсированном первом проходе (см. forcePass выше).
local layoutNumsChanged = (prevKey ~= nil) and (prevKey ~= layoutKey)
if fontChanged or fontSizeChanged or layoutNumsChanged or forcePass then
if frames.location and frames.location._lpsUpdateFunc then
frames.location._lpsUpdateFunc(frames.location)
end
if frames.coords and frames.coords._lpsUpdateFunc then
frames.coords._lpsUpdateFunc(frames.coords)
end
if frames.time and frames.time._lpsUpdateFunc then
frames.time._lpsUpdateFunc(frames.time)
end
if frames.gold and frames.gold._lpsUpdateFunc then
frames.gold._lpsUpdateFunc(frames.gold)
end
if frames.system and frames.system._lpsUpdateFunc then
frames.system._lpsUpdateFunc(frames.system)
end
end


if LPS.UpdateFrameSize then
LPS:ScheduleFrameSizeUpdate()
end

-- FIX (главный): помечаем раскладку применённой ТОЛЬКО когда holder реально
-- видим. Пока он скрыт (начальная загрузка, режим боя, скрытие через настройки),
-- следующий вызов ApplyLayout обязан пройти полностью и переанкерить панели —
-- иначе после Show() они оставались бы в дефолтных якорях (оба справа).
if frames.holder and frames.holder:IsShown() then
frames.holder._lpsEverApplied = true
end
end

-- ИСПРАВЛЕНИЕ (bug): формат "%2x" давал битый hex для компонент < 16
-- ("|cff0f..." вместо "|cff000f...") — теперь "%02x".
function LPS:ConvertRGBtoColorString(color)
	if not color then return end

	local colorString = "|cff";
	local r = color.r * 255;
	local g = color.g * 255;
	local b = color.b * 255;
	colorString = colorString..string.format("%02x%02x%02x", r, g, b);
	
	return colorString;
end

-- ОПТИМИЗАЦИЯ: ApplyDTVisibility / ApplyTimeVisibility / ApplyCoordsVisibility
-- ранее были почти идентичными копипастами (три копии логики "dtshow + слоты").
-- Сведены в один параметрический хелпер; публичные имена оставлены как тонкие
-- обёртки, т.к. на них есть внешние вызовы (options.lua и др.).
-- FIX (баг «пункты меню Макет не работают»): раньше здесь существовало ТРИ
-- независимых копии логики видимости (applySideFrameVisibility, ApplyDTVisibility,
-- и своя внутри ApplyLayout). ApplyDTVisibility показывала ВСЕ панели при
-- dtshow==true, игнорируя выбор слотов, и в ApplyAllSettings сразу после
-- ApplyLayout() отменяла его результат — панели вне слотов становились видимыми
-- в дефолтных якорях (обе справа от локации, друг на друге). Теперь ЕДИНСТВЕННЫЙ
-- источник истины — ApplyLayout(); эти публичные функции лишь делегируют ему
-- (инвалидировав кэш, чтобы проход точно выполнился).
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

function LPS:ResetAllSettingsToDefaults()
	if LPS.db and LPS.db.ResetProfile then
		LPS.db:ResetProfile()
	else
		local old = LPS_DB
		local oldGlobal = type(old) == "table" and old.global or nil
		local oldGold = type(old) == "table" and old.gold or nil
		LPS_DB = CopyTable(LPS.defaults)
		LPS_DB.global = LPS_DB.global or {}
		if oldGlobal then
			for k, v in pairs(oldGlobal) do
				if LPS_DB.global[k] == nil then
					LPS_DB.global[k] = v
				end
			end
		end
		if oldGold and not LPS_DB.global.gold then
			LPS_DB.global.gold = oldGold
		end
		LPS_DB.gold = nil
	end
	LPS:ApplyHolderPosition()
	if LPS.ApplyAllSettings then
		LPS:ApplyAllSettings()
	end
	if LPS.UpdateMinimapButton then
		LPS:UpdateMinimapButton()
	end
	if LPS.CreateMinimapButton then
		LPS:CreateMinimapButton()
	end
end

function LPS:RefreshAfterProfileChange()
	self.profileDB = nil
	-- FIX (меню Макет «не работает» после смены профиля): сбрасываем кэши ДО
		-- применения настроек, иначе ApplyLayout отрабатывает по устаревшему ключу.
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

-- ОПТИМИЗАЦИЯ (duplicates): единый загрузчик LibTourist.
-- Ранее идентичный блок из 4 веток был скопирован в api.lua и location_tt.lua.
-- Библиотека выбирается по текущему клиенту; результат доступен как LPS.Tourist.
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

local AceLocale = LibStub and LibStub:GetLibrary("AceLocale-3.0", true)
local Locale
if AceLocale then
	Locale = AceLocale:GetLocale("LocationPlus", true)
end

-- Выводит сообщение в чат с префиксом аддона и поддержкой локализации
--- @param msg string Сообщение
--- @param isTranslate boolean Флаг перевода msg
function LPS:Print(msg, isTranslate)
	if isTranslate ~= false then
		msg = LPS:L(msg)
	end
	print("|c"..LPS.addon.textColor..LPS.addon.name.."|r: " .. tostring(msg))
end

-- Возвращает локализованную строку по ключу или сам ключ, если значение = true
function LPS:L(key)
	if not Locale and AceLocale then
		Locale = AceLocale:GetLocale("LocationPlus", true)
	end
	if Locale then
		local val = rawget(Locale, key)
		if val ~= nil then
			return val
		end
	end

	if LPS.DEBUG then
		LPS:Print("Missing locale: |cFFE24444"..tostring(key).."|r", false)
	end

	return key
end

function LPS:GetProfileDB()
	if self.profileDB then
		return self.profileDB
	end
	if self.db and self.db.profile then
		self.profileDB = self.db.profile
		return self.profileDB
	end
	if type(LPS_DB) == "table" and LPS_DB.profiles and LPS_DB.profiles.Default then
		self.profileDB = LPS_DB.profiles.Default
		return self.profileDB
	end
	self.profileDB = LPS_DB
	return self.profileDB
end

function LPS:GetAccountDB()
	if self.accountDB then
		return self.accountDB
	end
	if self.db and self.db.global then
		self.accountDB = self.db.global
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

-- ОПТИМИЗАЦИЯ (duplicates): единые хелперы для модуля золота.
-- Ранее getRealmKey/getGoldRoot были скопированы один-в-один в
-- Modules/Frames/gold.lua и Modules/Tooltips/gold_tt.lua.
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
	db.layout.sideSlots.left = db.layout.sideSlots.left or {}
	db.layout.sideSlots.right = db.layout.sideSlots.right or {}
	db.layout.sideSlots.left.offsetX = 0
	db.layout.sideSlots.left.offsetY = 0
	db.layout.sideSlots.right.offsetX = 0
	db.layout.sideSlots.right.offsetY = 0
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
	-- ОПТИМИЗАЦИЯ (fix): защита от nil-ошибки, если holder ещё не создан
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

-- ИСПРАВЛЕНИЕ: GetContinentName вызывается из Modules/Tooltips/location_tt.lua,
-- который загружается ПОЗЖЕ этого файла; локальное определение ниже по файлу
-- было бы невидимо для него (Lua upvalue scope). Определяем как метод LPS сразу.
-- ОПТИМИЗАЦИЯ (duplicates): удалена вторая копия функции — раньше она полностью
-- дублировалась в location_tt.lua и перезаписывала эту (мёртвый код).

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
-- ОПТИМИЗАЦИЯ: функция вызывается тикером каждую секунду; ранее на каждый вызов
-- приходились UnitClass() и создание closure-функций getClassColor/getColonToken.
-- getClassColor — единая file-level upvalue в начале этого файла (без дубля).
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
		-- ОПТИМИЗАЦИЯ: один вызов date("*t") вместо трёх (date("%H"), date("%M"), date("%S"))
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

	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = LPS:ApplyDefaults(db[k], v)
		elseif db[k] == nil and k ~= "addonTextColor" then
			db[k] = v
		end
	end

	-- FIX (меню «Макет» не работало): для layout дополнительно проходим по всем
	-- числовым полям через tonumber()==nil — AceDB/старые SavedVariables иногда
	-- хранят строки/0-значения, из-за чего слайдеры показывали одно, а применялось
	-- другое. Также гарантированно создаём sideSlots.left/right с frame/offsetX/offsetY.
	if defaults.layout and db.layout and type(db.layout) == "table" then
		local defL = defaults.layout
		for _, key in ipairs({"dtPaddingX","dtPaddingY","dtMinWidth","locPaddingX","locPaddingY","locMinWidth","frameLevel","spacingManual"}) do
			if tonumber(db.layout[key]) == nil then db.layout[key] = defL[key] end
		end
		if db.layout.dtshow == nil then db.layout.dtshow = defL.dtshow end
		if db.layout.spacingAuto == nil then db.layout.spacingAuto = defL.spacingAuto end
		if db.layout.customColor == nil then db.layout.customColor = defL.customColor end
		if db.layout.frameStrata == nil or db.layout.frameStrata == "" then db.layout.frameStrata = defL.frameStrata end
		if type(db.layout.userColor) ~= "table" then db.layout.userColor = { r = 1, g = 1, b = 1 } end
		if type(db.layout.sideSlots) ~= "table" then db.layout.sideSlots = {} end
		for _, side in ipairs({"left","right"}) do
			local s = db.layout.sideSlots[side]
			if type(s) ~= "table" then
				s = {}
				db.layout.sideSlots[side] = s
			end
			if s.frame == nil or s.frame == "" then
				s.frame = (defL.sideSlots and defL.sideSlots[side] and defL.sideSlots[side].frame) or "none"
			end
			if tonumber(s.offsetX) == nil then s.offsetX = 0 end
			if tonumber(s.offsetY) == nil then s.offsetY = 0 end
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

-- ОПТИМИЗАЦИЯ: единый дебаунс полного каскада перерасчёта (layout + размеры).
-- Каждая set-функция в options.lua раньше дергала ApplyLayout()+UpdateFrameSize()
-- напрямую; при быстрых изменениях настроек это O(N^2) дорогих Layout-вызовов.
-- ScheduleRefresh схлопывает все заявки кадра в один проход на следующем тике.
local refreshPending = false
function LPS:ScheduleRefresh()
	if refreshPending then return end
	refreshPending = true
	C_Timer.After(0.05, function()
		refreshPending = false
		-- FIX (баг «пункты меню Макет не применяются»): set-функции options.lua мутируют
		-- БД напрямую; AceDB может пересобирать обёртки таблиц, и кэш по ссылке
		-- (_NormalizeLayoutDB) способен пропустить реальное изменение. Перед каждым
		-- плановым обновлением раскладки сбрасываем оба кэша — ApplyLayout всегда
		-- видит актуальные значения.
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
	-- ЗАЩИТА: db.general может отсутствовать в повреждённой/старой БД
	local interval = tonumber(db.general and db.general.coordsTimeUpdate) or 0.2
	interval = math.max(interval, 0.05)
	if f._lpsTicker then
		f._lpsTicker:Cancel()
		f._lpsTicker = nil
	end
	-- ОПТИМИЗАЦИЯ: тикер не выполняет работу, пока фрейм/родитель скрыты
	-- (как в CreateFrame), плюс защита от nil-интервала из повреждённой БД.
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
			-- FIX: минимальная толщина рамки теперь 0 — при bs==0 рамка полностью
			-- убирается (edgeFile=nil), а не рисуется шириной в 1 пиксель.
			f:SetBackdrop({
				bgFile   = "Interface\\Buttons\\WHITE8x8",
				edgeFile = (bs > 0 and "Interface\\Buttons\\WHITE8x8") or nil,
				tile     = false,
				edgeSize = bs,
				insets   = {left=1,right=1,top=1,bottom=1},
			})
			-- FIX (меню «Стиль/Панели»): цвета ставим ПОСЛЕ update-функции текста,
			-- чтобы GetColor читал актуальный bgEnable до пересчёта размеров.
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
	-- ОПТИМИЗАЦИЯ: батчинг вместо синхронного UpdateFrameSize сразу после ApplyLayout
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
	-- FIX (оба фрейма справа после /reload): при старте БД мутируется через
	-- ApplyDefaults (заполняет layout.sideSlots дефолтами), а кэш нормализации
	-- и маркер ApplyLayout этого не видят — первый проход применял раскладку
	-- по устаревшему снимку слотов. Инвалидируем кэши перед полным применением.
	if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
	LPS:ApplyTimeFormat()
	LPS:ApplyCoordsUpdateInterval()
	LPS:ApplyLayout()
	LPS:ApplyStyle()
	-- FIX: ApplyDTVisibility/ApplyCoordsVisibility/ApplyTimeVisibility убраны —
	-- видимость панелей теперь целиком ответственность ApplyLayout().
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

function LPS:ToggleOptions()
	local aceDialog = LibStub and LibStub:GetLibrary("AceConfigDialog-3.0", true) and LibStub("AceConfigDialog-3.0")
	if LPS.EnsureOptionsCloseHooks then
		LPS:EnsureOptionsCloseHooks()
	end
	if aceDialog and LPS.Options and LPS.Options.aceAppName then
		local appName = LPS.Options.aceAppName
		if aceDialog.OpenFrames and aceDialog.OpenFrames[appName] then
			if LPS.DisableMoveModeIfActive then
				LPS:DisableMoveModeIfActive()
			end
			aceDialog:Close(appName)
		else
			aceDialog:Open(appName)
			local f = aceDialog.OpenFrames and aceDialog.OpenFrames[appName]
			if f then
				-- FIX (заголовок окна настроек «съехал вниз»): раньше здесь принудительно
				-- переанкеривался titletext на -14 вниз — этот костыль и был причиной
				-- смещения. Убран; стандартная позиция заголовка AceConfigDialog нетронута.
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
		return
	end

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
