local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local LibStub = _G.LibStub
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LibDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
local ldbObject

local function ClampAngle(angle)
	angle = angle % 360
	if angle < 0 then
		angle = angle + 360
	end
	return angle
end

local function PositionMinimapButton(btn)
	local db = LPS:GetDB()
	if not db or not db.show or not db.show.minimap then return end
	local angle = ClampAngle(tonumber(db.show.minimap.angle) or 220)
	db.show.minimap.angle = angle

	local radius = (Minimap:GetWidth() / 2) + 8
	local rad = math.rad(angle)
	local x = math.cos(rad) * radius
	local y = math.sin(rad) * radius
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function LPS:EnsureLDBMinimapIcon()
	if not (LDB and LibDBIcon) then return false end
	local db = LPS:GetDB()
	if not db or not db.show then return false end
	db.show.minimap = db.show.minimap or { hide = false, angle = 220 }
	local mm = db.show.minimap
	mm.minimapPos = ClampAngle(tonumber(mm.minimapPos) or tonumber(mm.angle) or 220)
	mm.angle = mm.minimapPos

	if not ldbObject then
		ldbObject = LDB:NewDataObject("LocationPlus", {
			type = "launcher",
			icon = "Interface\\AddOns\\LocationPlus\\Media\\logo.tga",
			OnClick = function(_, button)
				if button == "LeftButton" then
					LPS:ToggleMoveMode()
				elseif button == "RightButton" then
					LPS:OpenOptions()
				end
			end,
			OnTooltipShow = function(tt)
				local d = LPS:GetDB()
				if not d.tooltips.visibility.enable then return end
				if d.tooltips.visibility.combat and InCombatLockdown() then return end
				local r, g, b = LPS:GetColor("text")
				tt:AddLine(LPS:L("Location Plus"), 1, 0.82, 0)
				tt:AddLine(LPS:L("Shows your location and coordinates on screen"), r, g, b)
				tt:AddLine(" ")
				tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Toggle move mode"), 1, 1, 1, 0.41, 0.8, 0.94)
				tt:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), 1, 1, 1, 0.41, 0.8, 0.94)
			end,
		})
	end

	if not LibDBIcon:IsRegistered("LocationPlus") then
		LibDBIcon:Register("LocationPlus", ldbObject, mm)
	else
		LibDBIcon:Refresh("LocationPlus", mm)
	end
	return true
end

function LPS:UpdateMinimapButton()
	local db = LPS:GetDB()
	local btn = LPS.frame and LPS.frame.minimapButton
	if LPS:EnsureLDBMinimapIcon() then
		local mm = db and db.show and db.show.minimap
		if mm then
			mm.angle = ClampAngle(tonumber(mm.minimapPos) or tonumber(mm.angle) or 220)
			mm.minimapPos = mm.angle
			if mm.hide then
				LibDBIcon:Hide("LocationPlus")
			else
				LibDBIcon:Show("LocationPlus")
			end
		end
		if btn then
			btn:Hide()
		end
		return
	end
	if not btn then return end
	if not db or not db.show or not db.show.minimap then
		btn:Hide()
		return
	end
	if db.show.minimap.hide then
		btn:Hide()
		return
	end
	btn:Show()
	PositionMinimapButton(btn)
end

function LPS:CreateMinimapButton()
	if not Minimap then return end
	if LPS:EnsureLDBMinimapIcon() then
		if LPS.frame and LPS.frame.minimapButton then
			LPS.frame.minimapButton:Hide()
		end
		LPS:UpdateMinimapButton()
		return
	end
	if not LPS.frame then LPS.frame = {} end
	if LPS.frame.minimapButton then
		LPS:UpdateMinimapButton()
		return
	end

	local btn = CreateFrame("Button", "LPS_MinimapButton", Minimap)
	btn:SetSize(32, 32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	btn:GetHighlightTexture():SetBlendMode("ADD")

	btn.background = btn:CreateTexture(nil, "BACKGROUND")
	btn.background:SetAllPoints()
	btn.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	btn.border = btn:CreateTexture(nil, "OVERLAY")
	btn.border:SetAllPoints()
	btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	btn.icon = btn:CreateTexture(nil, "ARTWORK")
	btn.icon:SetPoint("CENTER")
	btn.icon:SetSize(20, 20)
	btn.icon:SetTexture("Interface\\AddOns\\LocationPlus\\Media\\logo.tga")
	btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	if btn.icon.SetMask then
		btn.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
	end

	btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	btn:GetPushedTexture():SetAllPoints()

	btn:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			LPS:ToggleMoveMode()
		elseif button == "RightButton" then
			LPS:OpenOptions()
		end
	end)

	btn:SetScript("OnEnter", function(self)
		local db = LPS:GetDB()
		if not db.tooltips.visibility.enable then return end
		if db.tooltips.visibility.combat and InCombatLockdown() then return end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		local r, g, b = LPS:GetColor("text")
		GameTooltip:AddLine(LPS:L("Location Plus"), 1, 0.82, 0)
		GameTooltip:AddLine(LPS:L("Shows your location and coordinates on screen"), r, g, b)
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Toggle move mode"), 1, 1, 1, 0.41, 0.8, 0.94)
		GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), 1, 1, 1, 0.41, 0.8, 0.94)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	btn:SetMovable(true)
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetScript("OnDragStart", function(self)
		self:LockHighlight()
		self.isDragging = true
	end)
	btn:SetScript("OnDragStop", function(self)
		self:UnlockHighlight()
		self.isDragging = false
	end)
	btn:SetScript("OnUpdate", function(self)
		if not self.isDragging then return end
		local db = LPS:GetDB()
		if not db or not db.show or not db.show.minimap then return end
		local mx, my = Minimap:GetCenter()
		local x, y = GetCursorPosition()
		local scale = UIParent:GetScale()
		x = x / scale
		y = y / scale
		local dx = x - mx
		local dy = y - my
		local angle = math.deg(math.atan2(dy, dx))
		angle = ClampAngle(angle)
		db.show.minimap.angle = angle
		PositionMinimapButton(self)
	end)

	LPS.frame.minimapButton = btn
	LPS:UpdateMinimapButton()
end

function LPS:SetMoveMode(enabled)
	local f = LPS.frame.holder
	f:SetMovable(enabled)
	f:EnableMouse(enabled)
	f:SetFrameStrata(enabled and "DIALOG" or "HIGH")
	f:SetFrameLevel(enabled and 999 or 1)

	-- создаем линии один раз
	if not f.vLine then
		f.vLine, f.hLine = LPS:CreateGuideLines()
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
			local p = LPS:GetDB().position
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
