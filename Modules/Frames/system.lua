local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateSystemFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder or not LPS.frame.location then return end


	---@type LPSFrameParams
	local params = {
		name = "LPS_System",
		frameType = "Button",
		hidden = true,
		parent = LPS.frame.location,
		anchor = {"LEFT", LPS.frame.location, "RIGHT", 5, 0},
		padding = {((db.layout and db.layout.dtPaddingX) or 10), ((db.layout and db.layout.dtPaddingY) or 6)},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			local fps = math.floor(GetFramerate() or 0)
			local _, _, lagHome, lagWorld = GetNetStats()
			lagHome = math.floor(lagHome or 0)
			lagWorld = math.floor(lagWorld or 0)
			local lag = lagWorld > 0 and lagWorld or lagHome
			if f.text then
				local fpsText = LPS:ColorByThreshold(fps, 60, 30, false)
				local msText = LPS:ColorByThreshold(lag, 60, 120, true)
				f.text:SetText(string.format("FPS: %s MS: %s", fpsText, msText))
			end
		end,
		updateTicker = {interval = 1},
		tooltipFunc = function(self)
			local d = LPS:GetDB()
			if not d.tooltips.visibility.enable then return end
			if d.tooltips.visibility.combat and InCombatLockdown() then return end
			if d.tooltips.system and d.tooltips.system.enable == false then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			if LPS.BuildSystemTooltip then
				LPS:BuildSystemTooltip(GameTooltip)
			end
			GameTooltip:Show()
		end,
	}

	return LPS:CreateFrame(params)
end
