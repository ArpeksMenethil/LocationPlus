local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- Ждём, чтобы SavedVariables точно загрузились
C_Timer.After(0, function()
	if not LPS_DB then return end

	-------------------------------------------------
	-- ФРЕЙМ ЛОКАЦИИ
	-------------------------------------------------
	local f = CreateFrame("Button", "LPS_Location", LPS.holder, "BackdropTemplate")
	f:ClearAllPoints()
	f:SetPoint("CENTER", LPS.holder, "CENTER")
	f:EnableMouse(true)

	-------------------------------------------------
	-- СТИЛЬ ПАНЕЛИ
	-------------------------------------------------
	local COLORS = LPS_DB.colors
	local FONT_SIZE = LPS_DB.fontSize or 12

	-- отступы панели
	local PADDING_X = 10
	local PADDING_Y = 6
	local MIN_WIDTH = 60
	local MIN_HEIGHT = 26

	f:SetBackdrop({
		bgFile   = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile     = false,
		edgeSize = 1,
		insets   = { left = 1, right = 1, top = 1, bottom = 1 },
	})

	f:SetBackdropColor(LPS:GetColor("bg"))
	f:SetBackdropBorderColor(LPS:GetColor("border"))

	-------------------------------------------------
	-- ТЕКСТ
	-------------------------------------------------
	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.text:SetPoint("CENTER")
	f.text:SetJustifyH("CENTER")
	f.text:SetFontHeight(FONT_SIZE)

	-------------------------------------------------
	-- ОБНОВЛЕНИЕ ТЕКСТА + РАЗМЕРА
	-------------------------------------------------
	local function Update()
		local zone = GetZoneText()
		local sub  = GetSubZoneText()
		local text = (sub ~= "" and sub or zone) or ""

		f.text:SetText(text)
		f.text:SetTextColor(LPS:GetZoneStatus(true))

		-- авторазмер
		local w = f.text:GetStringWidth()
		local h = f.text:GetStringHeight()

		f:SetSize(
			math.max(MIN_WIDTH,  w + PADDING_X * 2),
			math.max(MIN_HEIGHT, h + PADDING_Y * 2)
		)
	end

	-------------------------------------------------
	-- TOOLTIP (СТАНДАРТНЫЙ BLIZZARD)
	-------------------------------------------------
	f:SetScript("OnEnter", function(self)
		if not LPS_DB.tooltips.location.enable then return end

		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:ClearLines()
		LPS:BuildLocationTooltip(GameTooltip)
		GameTooltip:Show()

		self.updateTooltip = function()
			if GameTooltip:IsOwned(self) then
				GameTooltip:ClearLines()
				LPS:BuildLocationTooltip(GameTooltip)
				GameTooltip:Show()
			end
		end
	end)

	-------------------------------------------------
	-- СОБЫТИЯ СМЕНЫ ЗОНЫ
	-------------------------------------------------
	f:RegisterEvent("ZONE_CHANGED")
	f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	f:RegisterEvent("ZONE_CHANGED_INDOORS")

	f:SetScript("OnEvent", function(self)
		Update()
		if self.updateTooltip then
			self.updateTooltip()
		end
	end)

	f:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
		self.updateTooltip = nil
	end)

	Update()

	-------------------------------------------------
	-- EXPORT
	-------------------------------------------------
	LPS.locationFrame = f



end)