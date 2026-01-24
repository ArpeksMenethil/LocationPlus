local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- Ждём, чтобы SavedVariables точно загрузились
C_Timer.After(0.1, function()
	if not LPS_DB then return end

	-- Дефолтные значения, если их нет
	local FONT_SIZE = LPS_DB.settings.fontSize or 12

	-- Создаём фрейм координат
	local f = CreateFrame("Button", "LPS_Coords", LPS.holder, "BackdropTemplate")
	f:SetSize(100, 22)
	f:ClearAllPoints()
	f:SetPoint("RIGHT", LPS.locationFrame, "LEFT", -5, 0)

	-- backdrop
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = LPS_DB.settings.borderSize or 2,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	f:SetBackdropColor(LPS:GetColor("bg"))
	f:SetBackdropBorderColor(LPS:GetColor("border"))

	-- текст
	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.text:SetAllPoints()
	f.text:SetJustifyH("CENTER")
	f.text:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)

	-- обновление координат
	C_Timer.NewTicker(0.2, function()
		local x, y = LPS:GetPlayerCoords()
		if x and y then
			f.text:SetText(string.format("|cFFFFFFFF%.2f|r | |cFFFFFFFF%.2f|r", x*100, y*100))
		else
			f.text:SetText("|cFFFFFFFFНЕТ|r")
		end
	end)

	f:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			ToggleWorldMap()
			WorldMapFrame:ClearAllPoints()
			WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
		end
	end)

	LPS.coordsFrame = f



end)
