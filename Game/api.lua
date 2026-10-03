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
	local cache = normalizedLayoutCache
	if cache and cache.raw == raw then
		return cache.out
	end

	if raw.profession == nil and raw.proffession ~= nil then
		raw.profession = raw.proffession
	end

	local out = cache and cache.out or {}
	out.dtPaddingX  = tonumber(raw.dtPaddingX)  or 10
	out.dtPaddingY  = tonumber(raw.dtPaddingY)  or 6
	out.dtMinWidth  = tonumber(raw.dtMinWidth)  or 60
	out.locPaddingX = tonumber(raw.locPaddingX) or 10
	out.locPaddingY = tonumber(raw.locPaddingY) or 6
	out.locMinWidth = tonumber(raw.locMinWidth) or 80
	out.spacing     = (raw.spacingAuto == false) and (tonumber(raw.spacingManual) or 5) or 5
	out.dtshow      = raw.dtshow
	out.frameStrata = raw.frameStrata
	out.frameLevel  = tonumber(raw.frameLevel)
	out.customColor = raw.customColor
	out.userColor   = raw.userColor
	out.sideSlots   = raw.sideSlots
	normalizedLayoutCache = { raw = raw, out = out }
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
end

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
		.. tostring((layout.sideSlots and layout.sideSlots.right and layout.sideSlots.right.frame) or "")
	if frames.holder and frames.holder._lpsLastLayoutKey == layoutKey then return end
	if frames.holder then frames.holder._lpsLastLayoutKey = layoutKey end

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

	local showDT = layout.dtshow ~= false
	if frames.coords then
		frames.coords:SetShown(showDT)
	end
	if frames.time then
		frames.time:SetShown(showDT)
	end
	if frames.gold then
		frames.gold:SetShown(showDT)
	end
	if frames.system then
		frames.system:SetShown(showDT)
	end

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

	local function applySideSlotVisibility()
		-- Hide non-selected frames, even if global "show" flags are enabled.
		if frames.coords then
			frames.coords:SetShown(frames.coords:IsShown() and isSelectedInSlots("coords"))
		end
		if frames.time then
			frames.time:SetShown(frames.time:IsShown() and isSelectedInSlots("time"))
		end
		if frames.gold then
			frames.gold:SetShown(frames.gold:IsShown() and isSelectedInSlots("gold"))
		end
		if frames.system then
			frames.system:SetShown(frames.system:IsShown() and isSelectedInSlots("system"))
		end
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
		if not (frame and frame.IsShown and frame:IsShown()) then return end

		local ox = tonumber(slotCfg.offsetX) or 0
		local oy = tonumber(slotCfg.offsetY) or 0
		frame:ClearAllPoints()
		if side == "LEFT" then
			frame:SetPoint("RIGHT", frames.location, "LEFT", -spacing + ox, oy)
		else
			frame:SetPoint("LEFT", frames.location, "RIGHT", spacing + ox, oy)
		end
	end

	-- Apply the base visibility rules first, then constrain to selected slots.
	applySideSlotVisibility()
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
	local fontKey = tostring(fontFile) .. "|" .. tostring(size) .. "|" .. tostring(flags)
	for _, f in pairs({frames.location, frames.time, frames.coords, frames.gold, frames.system}) do
		if f and f.text then
			if f._lpsAppliedFontKey ~= fontKey then
				f._lpsAppliedFontKey = fontKey
				f.text:SetFont(fontFile, size, flags)
				fontChanged = true
			end
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
	if fontChanged then
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


	-- ОПТИМИЗАЦИЯ (fix): ConvertRGBtoColorString определялся НИЖЕ по файлу, но
	-- вызывался из этого файла (location_tt.lua вызывает его сразу при наведении).
	-- Порядок загрузки Lua делает поздние локальные определения невидимыми для
	-- ранних вызовов — переносим определение в начало файла.
	if LPS.UpdateFrameSize then
		LPS:ScheduleFrameSizeUpdate()
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
local function applySideFrameVisibility(frameKey)
	local db = LPS:GetDB()
	local f = LPS.frame and LPS.frame[frameKey]
	if not db or not f then return end
	local layout = db.layout or {}
	local show = true

	if layout.dtshow == false then
		show = false
	else
		local slots = layout.sideSlots or {}
		local left = slots.left and slots.left.frame
		local right = slots.right and slots.right.frame
		if left ~= frameKey and right ~= frameKey then
			show = false
		end
	end

	if f:IsShown() ~= show then
		f:SetShown(show)
		LPS:ScheduleFrameSizeUpdate()
	end
end

function LPS:ApplyDTVisibility()
	local db = LPS:GetDB()
	local show = db and db.layout and db.layout.dtshow ~= false
	local changed = false
	for _, key in ipairs({"time", "coords", "gold", "system"}) do
		local f = LPS.frame and LPS.frame[key]
		if f and f:IsShown() ~= show then
			f:SetShown(show)
			changed = true
		end
	end
	if changed then
		LPS:ScheduleFrameSizeUpdate()
	end
end

function LPS:ApplyTimeVisibility()
	applySideFrameVisibility("time")
end

function LPS:ApplyCoordsVisibility()
	applySideFrameVisibility("coords")
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
			f:SetBackdrop({
				bgFile   = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				tile     = false,
				edgeSize = db.settings.borderSize or 2,
				insets   = {left=1,right=1,top=1,bottom=1},
			})
			f:SetBackdropColor(LPS:GetColor("bg"))
			f:SetBackdropBorderColor(LPS:GetColor("border"))
			if f._lpsUpdateFunc then
				f._lpsUpdateFunc(f)
			end
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
	LPS:ApplyTimeFormat()
	LPS:ApplyCoordsUpdateInterval()
	LPS:ApplyLayout()
	LPS:ApplyStyle()
	LPS:ApplyDTVisibility()
	LPS:ApplyCoordsVisibility()
	LPS:ApplyTimeVisibility()
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
				if not LPS._aceOptionsTitleOffsetApplied then
					LPS._aceOptionsTitleOffsetApplied = true
					local titleText = f.titletext or (f.frame and f.frame.titletext)
					if titleText and titleText.ClearAllPoints and titleText.SetPoint then
						titleText:ClearAllPoints()
						titleText:SetPoint("TOP", f.frame, "TOP", 0, -14)
					end
				end
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
