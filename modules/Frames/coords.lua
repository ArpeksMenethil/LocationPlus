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
			local db2 = LPS:GetDB()
			if db2 and db2.layout and db2.layout.dtshow == false then
				if f:IsShown() then
					f:Hide()
					if LPS.UpdateFrameSize then
						LPS:UpdateFrameSize()
					end
				end
				return
			end
			local hide = false
			if db2 and db2.show and db2.show.hideCoords then
				hide = true
			elseif db2 and db2.show and db2.show.hideCoordsInInstance and IsInInstance() then
				hide = true
			end

			if hide then
				if f:IsShown() then
					f:Hide()
					if LPS.UpdateFrameSize then
						LPS:UpdateFrameSize()
					end
				end
				return
			end

			if not f:IsShown() then
				f:Show()
				if LPS.UpdateFrameSize then
					LPS:UpdateFrameSize()
				end
			end

			local x, y = LPS:GetPlayerCoords()
			if f.text then
				if x and y then
					local dig = (db2 and db2.show and db2.show.dig) and 2 or 0
					local xf = LPS:Round(x * 100, dig)
					local yf = LPS:Round(y * 100, dig)
					if dig == 0 then
						f.text:SetText(string.format("%d | %d", xf, yf))
					else
						f.text:SetText(string.format("%.2f | %.2f", xf, yf))
					end
				else
					f.text:SetText("N/A")
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
