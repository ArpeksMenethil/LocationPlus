local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- Move Mode (перетаскивание)
function LPS:CreateGuideLines()
	local vLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	vLine:SetSize(4, UIParent:GetHeight())
	vLine:SetPoint("CENTER", UIParent, "CENTER")
	vLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	vLine:SetBackdropColor(1,1,1,1) -- по умолчанию белая
	vLine:SetFrameStrata("HIGH")

	local hLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	hLine:SetSize(UIParent:GetWidth(), 4)
	hLine:SetPoint("CENTER", UIParent, "CENTER")
	hLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	hLine:SetBackdropColor(1,1,1,1) -- по умолчанию белая
	hLine:SetFrameStrata("HIGH")

	return vLine, hLine
end

--- Создаёт кнопку/фрейм с общими настройками
---@param params table Параметры фрейма
---@field name string Имя фрейма
---@field parent frame Родительский фрейм
---@field anchor table {point, relativeTo, relativePoint, x, y} Точка привязки
---@field size table {width, height} Размер фрейма
---@field padding table {x, y}? Отступы для авторазмера текста (необязательно)
---@field fontSize number? Размер шрифта (необязательно)
---@field backdrop table? Настройки Backdrop (bgFile, edgeFile, edgeSize, insets)
---@field bgColor table? Цвет фона {r,g,b,a} (необязательно)
---@field borderColor table? Цвет границы {r,g,b,a} (необязательно)
---@field updateFunc fun(f:frame)? Функция обновления текста
---@field updateTicker table? {interval = number} Тикер для updateFunc
---@field updateEvent table? {events = {"EVENT1", "EVENT2"}} События для updateFunc
---@field onClick fun(self:frame, button:string)? Функция клика
---@field registerClicks table? {"LeftButtonUp", "RightButtonUp"} Кнопки мыши для клика
---@field tooltipFunc fun(self:frame)? Функция тултипа (OnEnter)
---@return frame Созданный фрейм
function LPS:CreateFrameButton(params)
	local f = CreateFrame("Button", params.name, params.parent or UIParent, "BackdropTemplate")
	f:ClearAllPoints()
	f:SetPoint(unpack(params.anchor or {"CENTER", f:GetParent(), "CENTER", 0, 0}))

	-- Размер
	if params.size then
		f:SetSize(params.size[1], params.size[2])
	end

	-- Backdrop
	local backdrop = params.backdrop or {
		bgFile   = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile     = false,
		edgeSize = params.borderSize or 2,
		insets   = { left=1, right=1, top=1, bottom=1 },
	}
	f:SetBackdrop(backdrop)
	f:SetBackdropColor(unpack(params.bgColor or {LPS:GetColor("bg")} or {1,1,1,0}))
	f:SetBackdropBorderColor(unpack(params.borderColor or {LPS:GetColor("border")} or {0,0,0,0}))

	-- Текст (если есть шрифт)
	if params.fontSize then
		f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		f.text:SetAllPoints()
		f.text:SetJustifyH("CENTER")
		f.text:SetFont(GameFontNormalSmall:GetFont(), params.fontSize)
	end

	-- Авторазмер по тексту
	if params.padding and params.updateFunc and not params.size then
		local oldUpdate = params.updateFunc
		params.updateFunc = function()
			oldUpdate(f)
			if f.text then
				local w = f.text:GetStringWidth()
				local h = f.text:GetStringHeight()
				f:SetSize(math.max(60, w + params.padding[1]*2), math.max(26, h + params.padding[2]*2))
			end
		end
	end

	-- Скрипты клика
	if params.onClick then
		f:EnableMouse(true)
		if params.registerClicks then
			f:RegisterForClicks(unpack(params.registerClicks))
		else
			f:RegisterForClicks("LeftButtonUp")
		end
		f:SetScript("OnClick", params.onClick)
	end

	-- Тултип
	if params.tooltipFunc then
		f:EnableMouse(true)
		f:SetScript("OnEnter", params.tooltipFunc)
		f:SetScript("OnLeave", function() GameTooltip_Hide() end)
	end

	-- Обновление
	if params.updateFunc then
		if params.updateTicker then
			C_Timer.NewTicker(params.updateTicker.interval, function() params.updateFunc(f) end)
		elseif params.updateEvent then -- Обновление через события
			for _, evt in ipairs(params.updateEvent.events) do
				f:RegisterEvent(evt)
			end
			f:SetScript("OnEvent", function(self, event, ...)
				if params.updateFunc then
					params.updateFunc(f, event, ...)
				end
			end)
			-- сразу вызвать один раз после создания, чтобы текст был виден
			if params.updateFunc then
				C_Timer.After(0, function() params.updateFunc(f, "INITIAL") end)
			end
		else
			params.updateFunc(f)
		end
	end

	return f
end
