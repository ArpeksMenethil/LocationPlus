local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateTimeFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder then return end


	---@type LPSFrameParams
	local params = {
		name = "LPS_Time",
		frameType = "Button",
		parent = LPS.frame.location,
		anchor = {"LEFT", LPS.frame.location, "RIGHT", 5, 0},
		padding = {((db.layout and db.layout.dtPaddingX) or 10), ((db.layout and db.layout.dtPaddingY) or 6)},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			if f.text then
				local newText = LPS:GetFormattedGameTime()
				f.text:SetText(newText)
			end
		end,
		updateTicker = {interval = 1},
		registerClicks = {"LeftButtonUp", "RightButtonUp"},
		onClick = function(self, button)
			if button == "LeftButton" then
				if ToggleTimeManager then
					ToggleTimeManager()
				elseif TimeManagerClockButton_OnClick and TimeManagerClockButton then
					TimeManagerClockButton_OnClick(TimeManagerClockButton)
				end
			elseif button == "RightButton" then
				if ToggleCalendar then
					ToggleCalendar()
				end
			end
		end,
		tooltipFunc = function(self)
			local db = LPS:GetDB()
			if not db.tooltips.visibility.enable then return end
			if db.tooltips.visibility.combat and InCombatLockdown() then return end
			if not db.tooltips.time.enable then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			LPS:BuildTimeTooltip()
			GameTooltip.isTimeTooltip = true
			GameTooltip:Show()
		end,
	}

	return LPS:CreateFrame(params)
end
