local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local unpackFn = table.unpack or unpack

-- Мост для отложенной (после боя) регистрации событий панелей
local frameEventBridge

-- Move Mode (перетаскивание)
function LPS:CreateGuideLines()
	local grid = { vLines = {}, hLines = {} }
	local w = UIParent:GetWidth()
	local h = UIParent:GetHeight()
	local stepX = w / 10
	local stepY = h / 10

	for i = 1, 9 do
		local vLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		vLine:SetSize(2, h)
		vLine:SetPoint("CENTER", UIParent, "BOTTOMLEFT", stepX * i, h / 2)
		vLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
		vLine:SetBackdropColor(1, 1, 1, 0.35)
		vLine:SetFrameStrata("HIGH")
		vLine:Hide()
		grid.vLines[i] = vLine

		local hLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		hLine:SetSize(w, 2)
		hLine:SetPoint("CENTER", UIParent, "BOTTOMLEFT", w / 2, stepY * i)
		hLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
		hLine:SetBackdropColor(1, 1, 1, 0.35)
		hLine:SetFrameStrata("HIGH")
		hLine:Hide()
		grid.hLines[i] = hLine
	end

	return grid
end

-- types.lua
---@class LPSFrameParams
---@field name string Имя создаваемого фрейма (обязательное)
---@field parent table Родительский фрейм (обязательное)
---@field template? `Tp` | Template Шаблон фрейма. По умолчанию "BackdropTemplate"
---@field anchor table {point, relativeTo, relativePoint, x, y} Точка привязки фрейма
---@field size table? {width, height} Размер фрейма. Если не указан — включается авторазмер по тексту
---@field padding table? {x, y} Отступы для авторазмера текста. Используется только если size не указан
---@field fontSize number? Размер шрифта текста
---@field backdrop table? Настройки Backdrop (bgFile, edgeFile, edgeSize, insets)
---@field bgColor table? {r,g,b,a} Цвет фона фрейма
---@field borderColor table? {r,g,b,a} Цвет границы фрейма
---@field frameType? string Тип фрейма (например "Frame", "Button"). По умолчанию "Frame"
---@field updateFunc fun(f:table)? Функция обновления текста/состояния фрейма. Вызывается тикером или событием
---@field updateTicker table? {interval = number} Тикер для updateFunc (в секундах)
---@field updateEvent table? {events = {"EVENT1","EVENT2"}} События для updateFunc
---@field onClick fun(self:table, button:string)? Функция при клике мышью
---@field registerClicks table? {"LeftButtonUp","RightButtonUp"} Кнопки мыши для обработки клика
---@field tooltipFunc fun(self:table)? Функция тултипа (OnEnter)
---@field textAllPoints boolean? Если true, текст занимает весь фрейм (SetAllPoints). По умолчанию false
---@return table Созданный фрейм с возможным полем `.text` для текста

--- Универсальная функция для создания фрейма
---@param params LPSFrameParams
---@return table f Созданный фрейм
function LPS:CreateFrame(params)
	if not params.parent then return end

	local f = CreateFrame(params.frameType or "Frame", params.name, params.parent, params.template or "BackdropTemplate")
	f:ClearAllPoints()
	f:SetPoint(unpackFn(params.anchor or {"CENTER", f:GetParent(), "CENTER", 0, 0}))
	if params.hidden then
		-- Фрейм создаётся скрытым; ApplyLayout позиционирует его в цепочке
		-- и покажет через applyPanelVisibility. Без этого новая панель
		-- мелькала поверх предыдущей группы до первого пересчёта layout'а.
		f:Hide()
	end
	f._lpsUpdateFunc = nil
	f._lpsTicker = nil

	-- Размер (фиксированный)
	if params.size then
		f:SetSize(params.size[1], params.size[2])
	end

	-- Backdrop
	f:SetBackdrop({
		bgFile   = (params.backdrop and params.backdrop.bgFile) or "Interface\\Buttons\\WHITE8x8",
		edgeFile = (params.backdrop and params.backdrop.edgeFile) or "Interface\\Buttons\\WHITE8x8",
		tile     = false,
		edgeSize = (params.backdrop and params.backdrop.edgeSize) or 2,
		insets   = (params.backdrop and params.backdrop.insets) or {left=1,right=1,top=1,bottom=1},
	})
	if params.bgColor then
		f:SetBackdropColor(unpackFn(params.bgColor or {LPS:GetColor("bg")} or {1,1,1,1}))
	end
	if params.borderColor then
		f:SetBackdropBorderColor(unpackFn(params.borderColor or {LPS:GetColor("border")} or {0,0,0,1}))
	end

	-- Текст
	if params.fontSize then
		f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		f.text:SetPoint("CENTER")
		f.text:SetJustifyH("CENTER")
		local fontCache = LPS._fontTuples
		if not fontCache then fontCache = {} LPS._fontTuples = fontCache end
		local tuple = fontCache[params.fontSize]
		if not tuple then
			local path, _, flags = GameFontNormalSmall:GetFont()
			tuple = { path, flags }
			fontCache[params.fontSize] = tuple
		end
		if tuple[1] then
			f.text:SetFont(tuple[1], params.fontSize, tuple[2])
		else
			f.text:SetFont(GameFontNormalSmall:GetFont(), params.fontSize)
			-- local path = GameFontNormalSmall:GetFont(); f.text:SetFont(path, params.fontSize)
		end
	end

	-- Авторазмер по тексту
	if params.padding and params.updateFunc and not params.size then
		f._lpsPaddingX = tonumber(params.padding[1]) or 0
		f._lpsPaddingY = tonumber(params.padding[2]) or 0
		local oldUpdate = params.updateFunc
		-- Пересчёт габаритов под текст. ВАЖНО: измерять строку нужно ДО
		-- применения ограничений (SetPoint к краям фрейма): как только у текста
		-- появляются TOPLEFT/BOTTOMRIGHT-якоря, его ширина ограничивается
		-- текущим размером фрейма и GetStringWidth() возвращает уже «зажатое»
		-- значение — фрейм никогда не расширяется под длинный текст.
		local function resizeToFit()
			if not f.text then return end
			local px = tonumber(f._lpsPaddingX) or 0
			local py = tonumber(f._lpsPaddingY) or 0
			local minW = tonumber(f._lpsMinWidth) or 60
			-- Сбрасываем якоря и любые ограничения ширины, чтобы получить
			-- естественный размер строки без переносов.
			f.text:ClearAllPoints()
			if f.text.GetMaxLineWidth then
				f.text:SetMaxLineWidth(0)
			end
			if f.text.SetNonSpaceMaxWidth then
				f.text:SetNonSpaceMaxWidth(0)
			end
			local w = f.text:GetStringWidth() or 0
			local h = f.text:GetStringHeight() or 0
			-- Отрицательная ширина означает «нет ограничения»: так текст не
			-- обрезается при последующем позиционировании внутри фрейма.
			f.text:SetWidth(-(w + 1))
			f:SetSize(math.max(minW, w + px * 2), math.max(26, h + py * 2))
			f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
			LPS:ScheduleFrameSizeUpdate()
		end
		f._lpsResizeToFit = resizeToFit
		params.updateFunc = function(frame, ev)
			oldUpdate(frame or f, ev)
			resizeToFit()
		end
	end

	-- События
	if params.updateFunc then
		f._lpsUpdateFunc = params.updateFunc
		if params.updateTicker then
			if f._lpsTicker then
				f._lpsTicker:Cancel()
				f._lpsTicker = nil
			end
			f._lpsTicker = C_Timer.NewTicker(params.updateTicker.interval, function()
				if f._lpsUpdateFunc and f:IsShown() and (not f:GetParent() or f:GetParent():IsShown()) then
					f._lpsUpdateFunc(f)
				end
			end)
		elseif params.updateEvent then
			-- Белый список событий: не даём зарегистрировать несуществующее событие
			-- (иначе WoW выдаёт "Attempt to register unknown event").
			local KNOWN_EVENTS = {
				-- общие / мира
				PLAYER_ENTERING_WORLD = true, PLAYER_LOGIN = true, ADDON_LOADED = true,
				ZONE_CHANGED = true, ZONE_CHANGED_NEW_AREA = true, ZONE_CHANGED_INDOORS = true,
				PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true, PLAYER_LEAVE_COMBAT = true,
				COMBAT_LOG_EVENT_UNFILTERED = true,
				UNIT_PET = true, CVAR_UPDATE = true,
				-- опыт / уровень
				PLAYER_XP_UPDATE = true, DISABLE_XP_GAIN = true, ENABLE_XP_GAIN = true,
				-- (LEVEL_UP в WoW API не существует — правильное событие PLAYER_LEVEL_UP)
				UPDATE_EXHAUSTION = true, PLAYER_LEVEL_UP = true,
				-- броня / инвентарь / предметы
				-- (UNIT_ARMOR в WoW API не существует)
				PLAYER_EQUIPMENT_CHANGED = true, EQUIPMENT_SETS_CHANGED = true,
				UNIT_INVENTORY_CHANGED = true, UPDATE_INVENTORY_DURABILITY = true,
				PLAYER_AVG_ITEM_LEVEL_UPDATE = true,
				-- характеристики / способности
				UNIT_STATS = true, UNIT_AURA = true, SPELLS_CHANGED = true,
				UNIT_ATTACK_POWER = true,
				-- деньги / почта / сумки
				PLAYER_MONEY = true, PLAYER_GUILD_UPDATE = true,
				BAG_UPDATE_DELAYED = true, BAG_CONTAINER_UPDATE = true,
				MAIL_INBOX_UPDATE = true, UPDATE_PENDING_MAIL = true, MAIL_CLOSED = true, MAIL_SHOW = true,
				CURRENCY_DISPLAY_UPDATE = true, CHAT_MSG_CURRENCY = true, CHAT_MSG_SYSTEM = true,
				-- квесты
				QUEST_ACCEPTED = true, QUEST_REMOVED = true, QUEST_TURNED_IN = true, QUEST_LOG_UPDATE = true,
				-- репутация / гильдия / друзья
				UPDATE_FACTION = true, COMBAT_TEXT_UPDATE = true,
				GUILD_ROSTER_UPDATE = true, GUILD_MEMBERS_ACCOUNT_STATUSES_UPDATE = true, GUILD_MOTD = true,
				FRIENDLIST_UPDATE = true,
				BN_FRIEND_ACCOUNT_ONLINE = true, BN_FRIEND_ACCOUNT_OFFLINE = true, BN_FRIEND_INFO_CHANGED = true,
				-- бой / подземелья
				ENCOUNTER_START = true, ENCOUNTER_END = true,
				PLAYER_DIFFICULTY_CHANGED = true, LOADING_SCREEN_DISABLED = true,
			}
			local filtered = {}
			for _, evt in ipairs(params.updateEvent.events) do
				if KNOWN_EVENTS[evt] then
					filtered[#filtered + 1] = evt
				else
					geterrorhandler()(("LPS: %s: пропущено неизвестное событие \"%s\""):format(tostring(params.name), tostring(evt)))
				end
			end
			params.updateEvent.events = filtered
			-- Регистрация событий защищённа (taint): во время боя RegisterEvent
			-- вызывать нельзя (ADDON_ACTION_FORBIDDEN) — откладываем до выхода из боя.
			local function registerEvents()
				for _, evt in ipairs(filtered) do
					f:RegisterEvent(evt)
				end
			end
			if InCombatLockdown() then
				f._lpsPendingEventRegister = registerEvents
				if not frameEventBridge then
					frameEventBridge = CreateFrame("Frame")
					frameEventBridge:RegisterEvent("PLAYER_REGEN_ENABLED")
					frameEventBridge:SetScript("OnEvent", function()
						for _, fr in pairs(LPS.frame or {}) do
							if type(fr) == "table" and fr._lpsPendingEventRegister then
								fr._lpsPendingEventRegister()
								fr._lpsPendingEventRegister = nil
							end
						end
					end)
				end
			else
				registerEvents()
			end
			f:SetScript("OnEvent", function(_, ev) params.updateFunc(f, ev) end)
		else
			params.updateFunc(f)
		end
	end

	-- OnClick
	if params.onClick then
		f:EnableMouse(true)
		if params.registerClicks then
			f:RegisterForClicks(unpackFn(params.registerClicks))
		else
			f:RegisterForClicks("LeftButtonUp")
		end
		f:SetScript("OnClick", params.onClick)
	end

	-- Tooltip
	if params.tooltipFunc then
		f:EnableMouse(true)
		f:SetScript("OnEnter", params.tooltipFunc)
		f:SetScript("OnLeave", function() GameTooltip_Hide() end)
	end

	return f
end