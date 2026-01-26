local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

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
