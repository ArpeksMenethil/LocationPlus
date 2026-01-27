local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------
-- OPTIONS
-------------------------------------------------
LPS.Options = {}

-------------------------------------------------
-- UI HELPERS
-------------------------------------------------
function LPS:CreateCheck(parent, text, tooltip, get, set, x, y)
	local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
	cb:SetPoint("TOPLEFT", x, y)
	cb.Text:SetText(text)

	if tooltip then
		cb.tooltipText = tooltip
	end

	cb:SetChecked(get())

	cb:SetScript("OnClick", function(self)
		set(self:GetChecked())
	end)

	return cb
end

function LPS:CreateSlider(parent, text, minVal, maxVal, step, get, set, x, y)
	local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	s:SetPoint("TOPLEFT", x, y)
	s:SetMinMaxValues(minVal, maxVal)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)

	local valText = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	valText:SetPoint("TOP", s, "BOTTOM", 0, -2)

	local function update(val)
		val = tonumber(string.format(step < 1 and "%.1f" or "%d", val))
		valText:SetText(val)
		set(val)
	end

	s.Text:SetText(text)
	s.Low:SetText(minVal)
	s.High:SetText(maxVal)

	local startVal = get()
	s:SetValue(startVal)
	valText:SetText(startVal)

	s:SetScript("OnValueChanged", function(self, val)
		update(val)
	end)

	return s
end


-------------------------------------------------
-- MAIN PANEL
-------------------------------------------------
local panel = CreateFrame("Frame")
panel.name = "Location Plus"
LPS.Options.panel = panel

-------------------------------------------------
-- SIMPLE TABS (SAFE FOR SETTINGS)
-------------------------------------------------
function LPS.Options:CreateTabs(parent)
	self.tabs = {}
	self.pages = {}

	local tabData = {
		{ key = "general",	text = "General" },
		{ key = "show",		text = "Show" },
		{ key = "tooltips",	text = "Tooltips" },
		{ key = "style",	text = "Style" },
	}

	local prev

	for i, info in ipairs(tabData) do
		local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		b:SetSize(100, 22)
		b:SetText(info.text)
		b.key = info.key

		if not prev then
			b:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -50)
		else
			b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
		end

		b:SetScript("OnClick", function(self)
			LPS.Options:SelectTab(self.key)
		end)

		self.tabs[info.key] = b
		prev = b

		local page = CreateFrame("Frame", nil, parent)
		page:SetPoint("TOPLEFT", 0, -80)
		page:SetPoint("BOTTOMRIGHT", 0, 0)
		page:Hide()

		self.pages[info.key] = page
	end

	self:SelectTab("general")
end

function LPS.Options:SelectTab(key)
	for k, btn in pairs(self.tabs) do
		if k == key then
			btn:Disable()
		else
			btn:Enable()
		end
	end

	for k, page in pairs(self.pages) do
		page:SetShown(k == key)
	end
end

-------------------------------------------------
-- RESET
-------------------------------------------------
function LPS.Options:CreateResetButton(parent)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(160, 22)
	b:SetPoint("BOTTOMLEFT", 16, 16)
	b:SetText("Reset to defaults")

	b:SetScript("OnClick", function()
		LPS_DB = CopyTable(LPS.defaults)
		ReloadUI()
	end)
end

function LPS.Options:CreateToggleMoveButton(parent)
	local move = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	move:SetSize(140, 22)
	move:SetPoint("TOPRIGHT", -100, -32)
	move:SetText("Move frame")

	move:SetScript("OnClick", function()
		LPS:ToggleMoveMode()
	end)

end

-------------------------------------------------
-- GENERAL TAB
-------------------------------------------------
function LPS:CreateGeneralOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Login message",
		nil,
		function() return LPS_DB.general.loginMessage end,
		function(v) LPS_DB.general.loginMessage = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"24H time format",
		nil,
		function() return LPS_DB.general.is24H end,
		function(v) LPS_DB.general.is24H = v end,
		16, y
	)

	y = y - 40

	self:CreateSlider(parent,
		"Coords update (sec)",
		0.1, 2, 0.1,
		function() return LPS_DB.general.coordsTimeUpdate end,
		function(v) LPS_DB.general.coordsTimeUpdate = v end,
		16, y
	)
end

-------------------------------------------------
-- SHOW TAB
-------------------------------------------------
function LPS:CreateShowOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Show zone",
		nil,
		function() return LPS_DB.show.zone end,
		function(v) LPS_DB.show.zone = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Exact coordinates",
		nil,
		function() return LPS_DB.show.exactCoords end,
		function(v) LPS_DB.show.exactCoords = v end,
		16, y
	)
end

-------------------------------------------------
-- TOOLTIPS TAB
-------------------------------------------------
function LPS:CreateTooltipOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Enable tooltips",
		nil,
		function() return LPS_DB.tooltips.visibility.enable end,
		function(v) LPS_DB.tooltips.visibility.enable = v end,
		16, y
	)

	y = y - 30

	self:CreateCheck(parent,
		"Hide in combat",
		nil,
		function() return LPS_DB.tooltips.visibility.combat end,
		function(v) LPS_DB.tooltips.visibility.combat = v end,
		16, y
	)
end

-------------------------------------------------
-- STYLE TAB
-------------------------------------------------
function LPS:CreateStyleOptions(parent)
	local y = -10

	self:CreateCheck(parent,
		"Enable background",
		nil,
		function() return LPS_DB.settings.colors.bgEnable end,
		function(v)
			LPS_DB.settings.colors.bgEnable = v
			if LPS.ApplyBackground then
				LPS:ApplyBackground()
			end
		end,
		16, y
	)

	y = y - 40

	self:CreateSlider(parent,
		"Font size",
		8, 20, 1,
		function() return LPS_DB.settings.fontSize end,
		function(v) LPS_DB.settings.fontSize = v end,
		16, y
	)

	y = y - 50

	self:CreateSlider(parent,
		"Border size",
		1, 6, 1,
		function() return LPS_DB.settings.borderSize end,
		function(v) LPS_DB.settings.borderSize = v end,
		16, y
	)
end

-------------------------------------------------
-- INIT
-------------------------------------------------
panel:SetScript("OnShow", function(self)
	if self.inited then return end
	self.inited = true

	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("|c"..LPS.addonTextColor..LPS.addonName.."|r")

	LPS.Options:CreateTabs(self)

	LPS:CreateGeneralOptions(LPS.Options.pages.general)
	LPS:CreateShowOptions(LPS.Options.pages.show)
	LPS:CreateTooltipOptions(LPS.Options.pages.tooltips)
	LPS:CreateStyleOptions(LPS.Options.pages.style)

	LPS.Options:CreateResetButton(self)
	LPS.Options:CreateToggleMoveButton(self)
end)

LPS.Options.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(LPS.Options.category)
