local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateLocationFrame()
	if not LPS_DB or not LPS.frame.holder then return end

	---@type LPSFrameParams
	local params = {
		name = "LPS_Location",
		frameType = "Button",
		parent = LPS.frame.holder,
		anchor = {"CENTER", LPS.frame.holder, "CENTER", 0, 0},
		padding = {10,6},
		fontSize = LPS_DB.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			local mapID = C_Map.GetBestMapForUnit("player")
			local zone = LPS:GetMapNameByIDAlt(mapID) or UNKNOWN
			local sub = GetSubZoneText()
			local text = (sub ~= "" and sub or zone) or ""
			local zoneLevel = LPS:GetLevelRange(zone)

			if f.text then
				if zoneLevel then
					f.text:SetText(format("%s (%s)", text, zoneLevel))
				else
					f.text:SetText(text)
				end
				f.text:SetTextColor(LPS:GetZoneStatus(true))
			end
		end,
		updateEvent = {events = {"ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED_INDOORS","PLAYER_ENTERING_WORLD"}},
		registerClicks = {"LeftButtonUp", "RightButtonUp"},
		onClick = function(self, button)
			if button == "LeftButton" then
				if IsShiftKeyDown() then
					local zone = GetZoneText()
					local subZone = GetSubZoneText()
					local x,y = LPS:GetPlayerCoords()
					local msg = string.format("%s: %s (%.2f %.2f)", zone, subZone, x*100, y*100)
					ChatEdit_ActivateChat(ChatEdit_GetLastActiveWindow())
					ChatEdit_InsertLink(msg)
				else
					ToggleWorldMap()
					WorldMapFrame:ClearAllPoints()
					WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
				end
			elseif button == "RightButton" then
				LPS:Print("In the future")
			end
		end,
		tooltipFunc = function(self)
			if not LPS_DB.tooltips.location.enable then return end
			GameTooltip:SetOwner(self,"ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			LPS:BuildLocationTooltip(GameTooltip)
			GameTooltip:Show()
		end,
	}

	return LPS:CreateFrame(params)
end
