local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateCoordsFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder then return end

	---@type LPSFrameParams
	local params = {
		name = "LPS_Coords",
		frameType = "Button",
		parent = LPS.frame.location,
		anchor = {"RIGHT", LPS.frame.location, "LEFT", -5, 0},
		size = {100,22},
		padding = {10,6},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		textAllPoints = true,
		updateFunc = function(f)
			local x, y = LPS:GetPlayerCoords()
			if f.text then
				if x and y then
					f.text:SetText(string.format("|cFFFFFFFF%.2f|r | |cFFFFFFFF%.2f|r", x*100, y*100))
				else
					f.text:SetText("|cFFFFFFFFНЕТ|r")
				end
			end
		end,
		updateTicker = {interval = tonumber(db.general.coordsTimeUpdate) or 0.2},
		onClick = function(self, button)
			if button == "LeftButton" then
				ToggleWorldMap()
				WorldMapFrame:ClearAllPoints()
				WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
			end
		end,
	}

	return LPS:CreateFrame(params)
end
