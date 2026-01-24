local addonName, LPS = ...
local DEBUG = true

_G.ArpeksLPS = _G.ArpeksLPS or {}
_G.ArpeksLPS.LPS = LPS or {}
_G.ArpeksLPS.L = setmetatable({}, {
	__index = function(t, key)
		if DEBUG then
			print("|c"..LPS.addonTextColor.."LocationPlus|r: Missing locale: ", key)
		end
		return key
	end
})
LPS.wowpatch, LPS.wowbuild, LPS.wowdate, LPS.wowtoc = GetBuildInfo()
do
	LPS.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	LPS.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
end
LPS_DB = LPS_DB or {} -- SavedVariables


local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?.?.?" -- Версия аддона
local L = _G.ArpeksLPS.L

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
LPS.holder = CreateFrame("Frame", "LPS_Holder", UIParent, "BackdropTemplate")
LPS.holder:SetSize(420, 22)
LPS.holder:SetFrameStrata("HIGH")
LPS.holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
LPS.holder:SetBackdropColor(0, 0, 0, 0) -- прозрачный


----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.holder:RegisterEvent("ADDON_LOADED")
LPS.holder:SetScript("OnEvent", function(self, event, name)
	if name ~= addonName then return end

	LPS_DB = LPS:ApplyDefaults(LPS_DB or {}, LPS.defaults)
	-- LPS_DB = LPS.defaults
	LPS:ApplyHolderPosition() -- Применяем позицию holder

	print("|c"..LPS.addonTextColor..addonName.."|r "..L["loaded. Current version"]..": |c"..LPS.addonTextColor.."v"..addonVersion.."|r")
end)

----------------------------------------------------------------
-- Move Mode (перетаскивание)
----------------------------------------------------------------
local function CreateGuideLines()
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

function LPS:SetMoveMode(enabled)
	local f = self.holder
	f:SetMovable(enabled)
	f:EnableMouse(enabled)
	f:SetFrameStrata(enabled and "DIALOG" or "HIGH")
	f:SetFrameLevel(enabled and 999 or 1)

	-- создаем линии один раз
	if not f.vLine then
		f.vLine, f.hLine = CreateGuideLines()
	end

	-- отключаем мышь у всех детей holder
	for _, child in ipairs({f:GetChildren()}) do
		child:EnableMouse(not enabled)
		child:EnableMouseWheel(not enabled)
	end

	if enabled then
		f.vLine:Show()
		f.hLine:Show()
		f:RegisterForDrag("LeftButton")
		f:SetBackdropColor(1,0,0,0.25)

		local snapRange = 10

		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then self:StartMoving() end
		end)
		f:SetScript("OnMouseUp", function(self)
			self:StopMovingOrSizing()

			-- вычисляем магнитное смещение
			local left = self:GetLeft()
			local bottom = self:GetBottom()
			local width = self:GetWidth()
			local height = self:GetHeight()
			local centerX = left + width/2
			local centerY = bottom + height/2
			local screenCenterX = UIParent:GetWidth()/2
			local screenCenterY = UIParent:GetHeight()/2

			local offsetX, offsetY = 0, 0
			if math.abs(centerX - screenCenterX) <= snapRange then offsetX = screenCenterX - centerX end
			if math.abs(centerY - screenCenterY) <= snapRange then offsetY = screenCenterY - centerY end

			local point, relativeTo, relativePoint, x, y = self:GetPoint()
			local p = LPS_DB.position
			p.point = point
			p.relativePoint = relativePoint
			p.x = x + offsetX
			p.y = y + offsetY

			self:ClearAllPoints()
			self:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
		end)

		f:SetScript("OnUpdate", function(self)
			local left = self:GetLeft()
			local bottom = self:GetBottom()
			local width = self:GetWidth()
			local height = self:GetHeight()
			local centerX = left + width/2
			local centerY = bottom + height/2
			local screenCenterX = UIParent:GetWidth()/2
			local screenCenterY = UIParent:GetHeight()/2

			if math.abs(centerX - screenCenterX) <= snapRange then
				f.vLine:SetBackdropColor(1,0,0,1)
			else
				f.vLine:SetBackdropColor(1,1,1,1)
			end

			if math.abs(centerY - screenCenterY) <= snapRange then
				f.hLine:SetBackdropColor(1,0,0,1)
			else
				f.hLine:SetBackdropColor(1,1,1,1)
			end
		end)
	else
		-- возвращаем holder в обычное состояние
		f:RegisterForDrag()
		f:SetScript("OnUpdate", nil)
		f:SetBackdropColor(0,0,0,0)
		f.vLine:Hide()
		f.hLine:Hide()
		f:SetFrameStrata("HIGH")
		f:SetFrameLevel(1)
		f:SetScript("OnMouseDown", nil)
		f:SetScript("OnMouseUp", nil)

		-- восстанавливаем мышь у внутренних фреймов
		for _, child in ipairs({f:GetChildren()}) do
			child:EnableMouse(true)
			child:EnableMouseWheel(true)
		end
	end
end

----------------------------------------------------------------
-- Slash-команды
----------------------------------------------------------------

----------------------------------------------------------------
-- Toggle Move Mode
----------------------------------------------------------------
SLASH_LPSMOVE1 = "/lpsmove"
SlashCmdList.LPSMOVE = function()
	LPS:ToggleMove()
end
----------------------------------------------------------------
-- Reset Holder Position
----------------------------------------------------------------
SLASH_LPSRESET1 = "/lpsreset"
SlashCmdList.LPSRESET = function()
	LPS:ResetPosition()
end