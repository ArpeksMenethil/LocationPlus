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
	f:SetPoint(unpack(params.anchor or {"CENTER", f:GetParent(), "CENTER", 0, 0}))
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
		f:SetBackdropColor(unpack(params.bgColor or {LPS:GetColor("bg")} or {1,1,1,1}))
	end
	if params.borderColor then
		f:SetBackdropBorderColor(unpack(params.borderColor or {LPS:GetColor("border")} or {0,0,0,1}))
	end

	-- Текст
	if params.fontSize then
		f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		if params.textAllPoints then
			f.text:SetAllPoints()
		else
			f.text:SetPoint("CENTER")
		end
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
				LPS:UpdateFrameSize()
			end
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
				if f._lpsUpdateFunc then
					f._lpsUpdateFunc(f)
				end
			end)
		elseif params.updateEvent then
			for _, evt in ipairs(params.updateEvent.events) do
				f:RegisterEvent(evt)
			end
			f:SetScript("OnEvent", function() params.updateFunc(f) end)
		else
			params.updateFunc(f)
		end
	end

	-- OnClick
	if params.onClick then
		f:EnableMouse(true)
		if params.registerClicks then
			f:RegisterForClicks(unpack(params.registerClicks))
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