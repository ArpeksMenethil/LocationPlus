local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--------------------------------------------------------------------
-- Панели-инфотексты (по мотивам DataTexts из ElvUI)
-- Реестр панелей + общий конструктор фреймов.
--------------------------------------------------------------------

local unpackFn = table.unpack or unpack

-- Ключи слотов layout.sideSlots, которые нельзя переназначать (зарезервированы под старые панели)
local RESERVED_SLOT_KEYS = { time = true, gold = true, system = true }

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
-- Вспомогательные функции (LPS._DT)
--------------------------------------------------------------------

-- Таблица общих хелперов панелей (используется файлами Modules/Frames/*.lua)
LPS._DT = LPS._DT or {}

-- Проверка значения на «секретность» (WotLK Classic 3.4+ / Retail secret values)
LPS._DT.NotSecret = function(v)
	if v == nil then return false end
	if IsRestrictedTable and IsRestrictedTable(v) then return false end
	return true
end

LPS._DT.shortValue = function(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.2fk", n / 1e3) end
	return tostring(math.floor(n))
end


LPS._DT.hexFromRGB = function(r, g, b)
	return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

LPS._DT.colorGradient = function(pct, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	pct = math.max(0, math.min(1, tonumber(pct) or 0))
	local r, g, b
	if pct < 0.5 then
		local f = pct * 2
		r, g, b = r1 + (r2 - r1) * f, g1 + (g2 - g1) * f, b1 + (b2 - b1) * f
	else
		local f = (pct - 0.5) * 2
		r, g, b = r2 + (r3 - r2) * f, g2 + (g3 - g2) * f, b2 + (b3 - b2) * f
	end
	return r, g, b
end

LPS._DT.classColorHex = function(classFile)
	local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if c then return LPS._DT.hexFromRGB(c.r, c.g, c.b) end
	return "|cFFFFFFFF"
end

LPS._DT.levelColorHex = function(level)
	level = tonumber(level) or 0
	if GetQuestDifficultyColor then
		local c = GetQuestDifficultyColor(level)
		return LPS._DT.hexFromRGB(c.r, c.g, c.b)
	end
	return "|cFFFFFFFF"
end

LPS._DT.panelCfg = function(key)
	local db = LPS:GetDB()
	return db and db.panels and db.panels[key]
end

-- Тултип-хелпер: стандартная проверка видимости подсказок
LPS._DT.tooltipGuard = function(key)
	local d = LPS:GetDB()
	if not d then return false end
	if not (d.tooltips and d.tooltips.visibility and d.tooltips.visibility.enable) then return false end
	if d.tooltips.visibility.combat and InCombatLockdown() then return false end
	local cfg = LPS._DT.panelCfg(key)
	if cfg and cfg.tooltip == false then return false end
	return true
end


LPS._DT.openTooltip = function(self, buildFunc)
	if GameTooltip.EasyTooltip_SetDefaultAnchor then
		GameTooltip:EasyTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	end
	GameTooltip:ClearLines()
	buildFunc(GameTooltip)
	GameTooltip:Show()
end


-- Меню через UIDropDownMenu (без зависимости от ElvUI EasyMenu)
local menuFrame
LPS._DT.showMenu = function(anchorFrame, list)
	if not menuFrame then
		menuFrame = CreateFrame("Frame", "LPS_DTMenu", UIParent, "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(menuFrame, function(_, level)
		for _, entry in ipairs(list) do
			if level == 1 then
				local info = UIDropDownMenu_CreateInfo()
				info.text = entry.text
				info.notCheckable = entry.notCheckable ~= false
				info.isTitle = entry.isTitle
				info.disabled = entry.disabled
				if entry.func then
					info.func = function() entry.func() end
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end, "MENU")
	ToggleDropDownMenu(1, nil, menuFrame, anchorFrame, 0, 0)
end


--------------------------------------------------------------------
-- Конструктор панели
--------------------------------------------------------------------

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
		parent = LPS.frame.location,
		anchor = { "LEFT", LPS.frame.location, "RIGHT", 5, 0 },
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

	local f = LPS:CreateFrame(params)
	if f and def.create then def.create(f) end
	-- первичное заполнение
	if f and f._lpsUpdateFunc then f._lpsUpdateFunc(f) end
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

--------------------------------------------------------------------
-- Определения панелей
--------------------------------------------------------------------
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
function LPS:GetOrCreatePanelFrame(key)
	if RESERVED_SLOT_KEYS[key] then return nil end
	local frames = LPS.frame
	if not frames then return nil end
	if frames[key] then return frames[key] end
	local f = LPS:CreateDatatextFrame(key)
	if f then
		frames[key] = f
		LPS:ScheduleFrameSizeUpdate()
	end
	return f
end
