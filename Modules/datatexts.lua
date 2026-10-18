local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--------------------------------------------------------------------
-- Панели-инфотексты (по мотивам DataTexts из ElvUI)
-- Реестр панелей + общий конструктор фреймов.
-- Вспомогательные функции (LPS._DT.*) перенесены в Game/utils.lua.
--------------------------------------------------------------------

-- Ключи слотов layout.sideSlots, которые нельзя переназначать (зарезервированы под старые панели)
local RESERVED_SLOT_KEYS = { coords = true, time = true, gold = true, system = true }

-- Реестр: key -> конфиг панели
local registry = {}
LPS.datatexts = registry

-- Порядок панелей в списках выбора и в настройках
local orderList = {
	"coords",          -- существующая
	"bags",            -- Bags
	"combatIndicator", -- Combat Indicator
	"combatTime",      -- Combat/Arena Time
	"currencies",      -- Currencies
	"dps",             -- DPS
	"difficulty",      -- Difficulty
	"durability",      -- Durability
	"experience",      -- Experience
	"friends",         -- Friends
	"guild",           -- Guild
	"hps",             -- HPS
	"itemLevel",       -- Item Level
	"mail",            -- Mail
	"microBar",        -- Micro Bar
	"quests",          -- Quests
	"reputation",      -- Reputation
	"volume",          -- Volume
	"armor",           -- Armor
	"attackPower",     -- Attack Power
	"spellPower",      -- Spell Power
	"healPower",       -- Heal Power
	"crit",            -- Crit Chance
	"haste",           -- Haste
	"mastery",         -- Mastery
	"strength",        -- Strength
	"agility",         -- Agility
	"stamina",         -- Stamina
	"intellect",       -- Intellect
	"spirit",          -- Spirit
}

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
	assert(def and def.key and def.name, "LPS RegisterDatatext: bad definition")
	registry[def.key] = def
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
		padding = { ((db.layout and db.layout.dtPaddingX) or 10), ((db.layout and db.layout.dtPaddingY) or 6) },
		fontSize = db.settings.fontSize or 12,
		bgColor = { LPS:GetColor("bg") },
		borderColor = { LPS:GetColor("border") },
		updateFunc = function(f)
			if def.update then def.update(f) end
		end,
	}

	if def.events then
		params.updateEvent = { events = def.events }
	elseif def.ticker then
		params.updateTicker = { interval = def.ticker }
	end

	if def.onClick then
		params.registerClicks = { "LeftButtonUp", "RightButtonUp" }
		params.onClick = function(self, button) def.onClick(self, button) end
	end

	if def.tooltip then
		params.tooltipFunc = function(self)
			if not LPS._DT.tooltipGuard(key) then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			-- Приоритет у отдельного билдера из Modules/Tooltips/<key>_tt.lua
			local builderName = "Build" .. key:gsub("^%l", string.upper) .. "Tooltip"
			if LPS[builderName] then
				LPS[builderName](LPS, GameTooltip)
			else
				def.tooltip(GameTooltip)
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
	local def = registry[key]
	return def and def.name or key
end

--- Список ключей панелей для слотов (существующие + новые)
LPS._DatatextOrderList = orderList

--- Список ключей панелей для слотов: порядок из orderList + все зарегистрированные вне его
function LPS:GetSlotKeyList()
	local keys = {}
	local seen = {}
	for _, k in ipairs(orderList) do
		if registry[k] and not seen[k] then
			seen[k] = true
			keys[#keys + 1] = k
		end
	end
	for k in pairs(registry) do
		if not seen[k] then keys[#keys + 1] = k end
	end
	return keys
end

function LPS:IsDatatextKey(key)
	return key ~= nil and registry[key] ~= nil and not RESERVED_SLOT_KEYS[key]
end

--- Возвращает фрейм панели по ключу слота (создаёт при необходимости)
-- Защита от рекурсии: CreateDatatextFrame вызывает ApplyLayout, который через
-- positionChain/getFrameByKey может снова позвать GetOrCreatePanelFrame с тем
-- же ключом (фрейм регистрируется в LPS.frame уже ПОСЛЕ создания).
local _lpsCreatingPanels = {}

function LPS:GetOrCreatePanelFrame(key)
	if RESERVED_SLOT_KEYS[key] then return nil end
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
