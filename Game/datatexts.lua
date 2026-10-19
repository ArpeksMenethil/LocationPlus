local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--------------------------------------------------------------------
-- Панели-инфотексты (по мотивам DataTexts из ElvUI)
-- Реестр панелей + общий конструктор фреймов.
-- Вспомогательные функции (LPS._DT.*) перенесены в Game/utils.lua.
--------------------------------------------------------------------

local registry = {}
LPS.datatexts = registry

-- Координаты/время/золото/система больше не «зарезервированные» панели с
-- отдельными конструкторами: они регистрируются через RegisterDatatext наравне
-- со всеми остальными, поэтому и создаются общим GetOrCreatePanelFrame.

-- Панели, которые нельзя показывать в списках слотов: microBar — это не
-- инфотекст (перемещает микро-бар Blizzard), отдельного текста не имеет.
local HIDDEN_SLOT_KEYS = { microBar = true }

--- Название панели для списков: ВСЕГДА актуально локализованное (язык
--- клиента). Раньше имя замораживалось в момент загрузки файла
--- (name = L.BAGS), а панели грузятся ПОСЛЕ datatexts.lua и до
--- полного построения локали — из-за этого списки сортировались по
--- АНГЛИЙСКИМ названиям ("Bags", "Mail"...), даже на русском клиенте.
--- Теперь хранится ключ перевода (def.nameKey), а перевод выполняется
--- при каждом обращении к имени.
function LPS:GetDatatextDisplayName(key)
	if key == "location" then return L.LOCATION end
	local def = registry[key]
	if def then
		if def.nameKey then return LPS:L(def.nameKey) end
		if def.name then return tostring(def.name) end
	end
	return key
end

--- Список ключей панелей для слотов: все зарегистрированные панели,
--- отсортированные по названию на языке клиента (русский клиент — по
--- русским названиям, enUS — по английским). Сортировка выполняется
--- ПОСЛЕ локализации: компаратор каждый раз берёт свежий перевод через
--- GetDatatextDisplayName. Кэш сбрасывается при каждой новой регистрации
--- панели.
local sortedKeysCache
local function invalidateSortedKeys()
	sortedKeysCache = nil
end

function LPS:GetSlotKeyList()
	if not sortedKeysCache then
		local keys = {}
		for key in pairs(registry) do
			if not HIDDEN_SLOT_KEYS[key] then
				keys[#keys + 1] = key
			end
		end
		table.sort(keys, function(a, b)
			local na = tostring(LPS:GetDatatextDisplayName(a)):lower()
			local nb = tostring(LPS:GetDatatextDisplayName(b)):lower()
			if na == nb then return a < b end
			return na < nb
		end)
		sortedKeysCache = keys
	end
	return sortedKeysCache
end

--------------------------------------------------------------------
-- Конструктор панели
--------------------------------------------------------------------

-- Мост событий для отложенной инициализации панелей (создание фреймов
-- в момент загрузки аддона безопасно — события регистрируются сразу).
local eventBridge = CreateFrame("Frame")
local datatextCreateQueueRegistered = false

--- Регистрирует панель инфотекста.
---@param def table { key, name, events, ticker, update(f), onClick(self,button), tooltip(tt), create(f) }
function LPS:RegisterDatatext(def)
	assert(def and def.key and (def.name or def.nameKey), "LPS RegisterDatatext: bad definition")
	registry[def.key] = def
	invalidateSortedKeys()
end

--- Создаёт фрейм панели по её конфигу (вызывается из ApplyLayout при первом использовании слота)
function LPS:CreateDatatextFrame(key)
	local def = registry[key]
	if not def then return nil end
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder or not LPS.frame.location then return nil end
	-- панель с настройкой enable (временно отключённая) не создаётся
	local pCfg = db.panels and db.panels[key]
	if pCfg and pCfg.enable == false then return nil end

	---@type LPSFrameParams
	local params = {
		name = "LPS_" .. key:gsub("^%l", string.upper),
		frameType = "Button",
		parent = LPS.frame.holder or LPS.frame.location,
        -- Временный якорь: фактическая позиция назначается в ApplyLayout
        -- (positionChain). Раньше здесь стоял {"LEFT", location, "RIGHT", 5, 0},
        -- из-за чего каждая новая панель при создании ставилась ПОВЕРХ группы 1
        -- ("создаются прямо на месте предыдущей группы") и оставалась там, если
        -- пересчёт layout'а не запускался. Теперь фрейм создаётся у holder'а,
        -- скрыт и становится видимым только после позиционирования в цепочке.
        anchor = { "CENTER", LPS.frame.holder or UIParent, "CENTER", 0, 0 },
		hidden = true, -- создаём скрытым: ApplyLayout позиционирует и показывает
		padding = { ((db.layout and db.layout.dtPaddingX) or 20), ((db.layout and db.layout.dtPaddingY) or 7) },
		fontSize = db.settings.fontSize or 12,
		bgColor = { LPS:GetColor("bg") },
		borderColor = { LPS:GetColor("border") },
		updateFunc = function(f)
			-- Отступы/минимальная ширина ВСЕГДА перечитываются из db.layout перед
			-- расчётом габаритов. Раньше padding фиксировался только при создании
			-- фрейма; теперь через этот реестр идут и coords/time/gold/system —
			-- их фреймы могли создаваться ещё до миграции layout-значений, и без
			-- этого пункта «огромные отступы» закрепились бы навсегда.
			local lay = LPS.GetDB and (LPS:GetDB().layout or {})
			local px = tonumber(lay and lay.dtPaddingX) or 20
			local py = tonumber(lay and lay.dtPaddingY) or 7
			f._lpsPaddingX = px
			f._lpsPaddingY = py
			f._lpsMinWidth = tonumber(lay and lay.dtMinWidth) or f._lpsMinWidth or 60
			if def.update then def.update(f) end
		end,
	}

	if def.events then
		params.updateEvent = { events = def.events }
	elseif def.ticker then
		params.updateTicker = { interval = def.ticker }
	end

	if def.onClick then
		params.registerClicks = def.clicks or { "LeftButtonUp", "RightButtonUp" }
		params.onClick = function(self, button) def.onClick(self, button) end
	end

	-- Подсказка панели: tooltipFunc создаём и когда в модуле задан def.tooltip,
	-- и когда существует отдельный билдер из Modules/Tooltips/<key>_tt.lua
	-- (Build<Key>Tooltip). Раньше условие было только `def.tooltip`, из-за чего
	-- у панелей friends/guild/quests/experience/bags (подсказки вынесены в
	-- *_tt.lua) подсказка вообще не появлялась.
	-- def.customTooltip = true — панель сама задаёт params.tooltipFunc через
	-- колбэк def.buildTooltip(self) (нестандартное поведение: time/gold/system).
	local builderName = "Build" .. key:gsub("^%l", string.upper) .. "Tooltip"
	if def.customTooltip and def.buildTooltip then
		params.tooltipFunc = function(self) def.buildTooltip(self) end
	elseif def.tooltip or LPS[builderName] then
		params.tooltipFunc = function(self)
			if not LPS._DT.tooltipGuard(key) then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			-- Приоритет у отдельного билдера из Modules/Tooltips/<key>_tt.lua.
			-- Билдер может вернуть false, чтобы отменить показ подсказки
			-- (например, experience_tt.lua на максимальном уровне).
			local built = true
			if LPS[builderName] then
				built = LPS[builderName](LPS, GameTooltip)
			elseif def.tooltip then
				def.tooltip(GameTooltip)
			end
			if built == false then
				GameTooltip:Hide()
				return
			end
			GameTooltip:Show()
		end
	end

	-- Безопасное выполнение колбэков create(): во время боевой блокировки
	-- защищённые методы фреймов (RegisterEvent и т.п.) вызывать нельзя —
	-- откладываем вызов до PLAYER_REGEN_ENABLED.
	local function runCreateCallback()
		if not def.create then return true end
		local ok = pcall(def.create)
		return ok
	end

	local f = LPS:CreateFrame(params)
	if f then
		if InCombatLockdown() then
			f._lpsPendingCreate = def.create
			if not datatextCreateQueueRegistered then
				datatextCreateQueueRegistered = true
				eventBridge:RegisterEvent("PLAYER_REGEN_ENABLED")
			end
		else
			runCreateCallback()
		end
		-- первичное заполнение
		if f._lpsUpdateFunc then f._lpsUpdateFunc(f) end
		-- Панель создана скрытой (params.hidden): сразу раскладываем layout,
		-- чтобы positionChain поставил её в цепочку СЛЕДУЮЩЕЙ за предыдущей
		-- группой и показал. Без этого фреймы 2-й/3-й групп оставались бы на
		-- временном якоре поверх первой группы.
		if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
		if LPS.ApplyLayout then LPS:ApplyLayout() end
	end
	return f
end

--------------------------------------------------------------------
-- Первичное обновление после входа в мир: пересобираем layout,
-- чтобы занятые слоты создали недостающие панели.
--------------------------------------------------------------------

do
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
		if LPS.ApplyLayout then LPS:ApplyLayout() end
	end)
end

-- После выхода из боя доделываем отложенные create()-инициализации панелей.
eventBridge:SetScript("OnEvent", function(self, event)
	if event ~= "PLAYER_REGEN_ENABLED" then return end
	local done = true
	for _, f in pairs(LPS.frame or {}) do
		if type(f) == "table" and f._lpsPendingCreate then
			local ok = pcall(f._lpsPendingCreate)
			if ok then
				f._lpsPendingCreate = nil
			else
				done = false
			end
		end
	end
	if done then
		datatextCreateQueueRegistered = false
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end)

--------------------------------------------------------------------
-- Публичный API для options.lua
--------------------------------------------------------------------

function LPS:GetDatatextName(key)
	return LPS:GetDatatextDisplayName(key)
end

--- Публичный доступ к отсортированному по алфавиту списку ключей панелей
--- реализован выше через LPS:GetSlotKeyList().

function LPS:IsDatatextKey(key)
	return key ~= nil and registry[key] ~= nil
end

--- Возвращает фрейм панели по ключу слота (создаёт при необходимости)
-- Защита от рекурсии: CreateDatatextFrame вызывает ApplyLayout, который через
-- positionChain/getFrameByKey может снова позвать GetOrCreatePanelFrame с тем
-- же ключом (фрейм регистрируется в LPS.frame уже ПОСЛЕ создания).
local _lpsCreatingPanels = {}

function LPS:GetOrCreatePanelFrame(key)
	local frames = LPS.frame
	if not frames then return nil end
	if frames[key] then return frames[key] end
	local creating = _lpsCreatingPanels
	if creating[key] then return nil end -- защита от рекурсии ApplyLayout
	creating[key] = true
	local f = LPS:CreateDatatextFrame(key)
	creating[key] = nil
	if f then
		frames[key] = f
		LPS:ScheduleFrameSizeUpdate()
	end
	return f
end
