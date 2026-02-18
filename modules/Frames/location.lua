local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateLocationFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder then return end

	---@type LPSFrameParams
	local params = {
		name = "LPS_Location",
		frameType = "Button",
		parent = LPS.frame.holder,
		anchor = {"CENTER", LPS.frame.holder, "CENTER", 0, 0},
		padding = {((db.layout and db.layout.locPaddingX) or 10), ((db.layout and db.layout.locPaddingY) or 6)},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			local db2 = LPS:GetDB()
			local mapID = C_Map.GetBestMapForUnit("player")
			local zone = LPS:GetMapNameByIDAlt(mapID) or UNKNOWN
			local sub = GetSubZoneText()
			local hasSub = sub and sub ~= "" and sub ~= zone
			local showZone = db2 and db2.show and db2.show.zone

			local baseText
			if showZone and hasSub then
				baseText = string.format("%s: %s", zone, sub)
			else
				baseText = hasSub and sub or zone
			end
			baseText = baseText or ""

			local extra = ""
			local icon = ""
			local other = db2 and db2.show and db2.show.displayOther
			local showIcon = db2 and db2.show and db2.show.showicon

			if other == "RLEVEL" then
				extra = LPS:GetLevelRange(mapID, zone) or ""
				if showIcon and extra ~= "" then
					icon = " " .. LPS.icons.Level
				end
			elseif other == "PFISH" and not LPS.Retail and LPS.GetFishingLvl then
				local minFish, maxFish = LPS:GetFishingLvl()
				if minFish and maxFish then
					extra = string.format("%s-%s", minFish, maxFish)
					if showIcon then
						icon = " " .. LPS.icons.Fish
					end
				end
			elseif other == "PET" and (LPS.Retail or LPS.MISTS) and LPS.GetBattlePetLvl then
				extra = LPS:GetBattlePetLvl(zone) or ""
				if showIcon and extra ~= "" then
					icon = " " .. LPS.icons.Pet
				end
			end

			local text = baseText
			if extra ~= "" then
				text = string.format("%s (%s)%s", baseText, extra, icon)
			end

			if f.text then
				f.text:SetText(text)
				local layout = db2 and db2.layout
				if not layout or layout.customColor == 3 then
					f.text:SetTextColor(LPS:GetZoneStatus(true))
				end
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
				LPS:ToggleOptions()
			end
		end,
		tooltipFunc = function(self)
			local db = LPS:GetDB()
			if not db.tooltips.visibility.enable then return end
			if db.tooltips.visibility.combat and InCombatLockdown() then return end
			if not db.tooltips.location.enable then return end
			GameTooltip:SetOwner(self,"ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			LPS:BuildLocationTooltip(GameTooltip)
			GameTooltip:Show()
		end,
	}

	return LPS:CreateFrame(params)
end
