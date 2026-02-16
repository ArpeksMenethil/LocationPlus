local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateSystemFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder or not LPS.frame.location then return end

	local function colorByThreshold(v, good, warn, invert)
		v = tonumber(v) or 0
		local r, g, b
		if invert then
			if v <= good then
				r, g, b = 0.1, 1, 0.1
			elseif v <= warn then
				r, g, b = 1, 0.82, 0
			else
				r, g, b = 1, 0.1, 0.1
			end
		else
			if v >= good then
				r, g, b = 0.1, 1, 0.1
			elseif v >= warn then
				r, g, b = 1, 0.82, 0
			else
				r, g, b = 1, 0.1, 0.1
			end
		end
		return string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, v)
	end

	---@type LPSFrameParams
	local params = {
		name = "LPS_System",
		frameType = "Button",
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
				local fpsText = colorByThreshold(fps, 60, 30, false)
				local msText = colorByThreshold(lag, 60, 120, true)
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
