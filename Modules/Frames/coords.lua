local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateCoordsFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder then return end

	---@type LPSFrameParams
	local params = {
		name = "LPS_Coords",
		frameType = "Button",
		hidden = true,
		parent = LPS.frame.location,
		anchor = {"RIGHT", LPS.frame.location, "LEFT", -5, 0},
		padding = {((db.layout and db.layout.dtPaddingX) or 20), ((db.layout and db.layout.dtPaddingY) or 7)},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			-- Без early-return по f:IsShown(): панель создаётся скрытой, и
			-- проверка видимости блокировала первичное заполнение текста при
			-- выборе панели в настройках (фрейм оставался пустым до тикера).
			local db2 = LPS:GetDB()

			local x, y = LPS:GetPlayerCoords()
			if f.text then
				if x and y then
					local dig = (db2 and db2.show and db2.show.dig) and 2 or 0
					local xf = LPS:Round(x * 100, dig)
					local yf = LPS:Round(y * 100, dig)
					local newText
					if dig == 0 then
						newText = string.format("%d | %d", xf, yf)
					else
						newText = string.format("%.2f | %.2f", xf, yf)
					end
					if f._lpsLastText ~= newText then
						f._lpsLastText = newText
						f.text:SetText(newText)
					end
				elseif f._lpsLastText ~= "N/A" then
					f._lpsLastText = "N/A"
					f.text:SetText("N/A")
				end
			end
		end,
		updateTicker = {interval = math.max(tonumber(db.general and db.general.coordsTimeUpdate) or 0.2, 0.05)},
		onClick = function(self, button)
			if button == "LeftButton" then
				ToggleWorldMap()
				if WorldMapFrame then
					WorldMapFrame:ClearAllPoints()
					WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
				end
			end
		end,
	}

	return LPS:CreateFrame(params)
end
