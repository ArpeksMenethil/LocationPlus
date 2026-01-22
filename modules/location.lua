local LPS_DB = _G.MyAddon and _G.MyAddon.LPS_DB
local LPS = _G.MyAddon and _G.MyAddon.LPS
if not LPS then return end

-------------------------------------------------
-- ФРЕЙМ ЛОКАЦИИ
-------------------------------------------------
local f = CreateFrame("Frame", "LPS_Location", LPS.holder, "BackdropTemplate")
f:SetSize(180, 28)
f:SetPoint("LEFT", LPS.coordsFrame, "RIGHT", 5, 0)
f:EnableMouse(true)

-------------------------------------------------
-- СТИЛЬ ПАНЕЛИ
-------------------------------------------------
local COLORS = _G.MyAddon.COLORS
local FONT_SIZE = _G.MyAddon.FONT_SIZE or 12

f:SetBackdrop({
	bgFile   = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	tile     = false,
	edgeSize = 1,
	insets   = { left = 1, right = 1, top = 1, bottom = 1 },
})

f:SetBackdropColor(unpack(COLORS.bg))
f:SetBackdropBorderColor(unpack(COLORS.border))

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
f.text:SetAllPoints()
f.text:SetJustifyH("CENTER")
f.text:SetFontHeight(FONT_SIZE)

-------------------------------------------------
-- ОБНОВЛЕНИЕ ТЕКСТА
-------------------------------------------------
local function Update()
	local zone = GetZoneText()
	local sub  = GetSubZoneText()
	f.text:SetText(sub ~= "" and sub or zone)
	f.text:SetTextColor(LPS:GetZoneStatus(true))
end

-------------------------------------------------
-- TOOLTIP (СТАНДАРТНЫЙ BLIZZARD)
-------------------------------------------------
f:SetScript("OnEnter", function(self)
	if not LPS_DB.tooltips.location.enable then return end

	-- стандартный тултип
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:ClearLines()
	LPS:BuildLocationTooltip(GameTooltip)
	GameTooltip:Show()

	-- создаем обновление при изменении зоны
	self.updateTooltip = function()
		if GameTooltip:IsOwned(self) then
			GameTooltip:ClearLines()
			LPS:BuildLocationTooltip(GameTooltip)
			GameTooltip:Show()
		end
	end
end)

-- динамически обновляем tooltip при событиях смены зоны
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:SetScript("OnEvent", function(self)
	Update()  -- обновляем текст
	if self.updateTooltip then
		self.updateTooltip() -- обновляем tooltip, если он открыт
	end
end)
Update()

f:SetScript("OnLeave", function(self)
	GameTooltip_Hide()
	self.updateTooltip = nil
end)


-------------------------------------------------
-- EXPORT
-------------------------------------------------
LPS.locationFrame = f
