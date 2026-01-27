local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

----------------------------------------------------------------
-- Addon Compartment
----------------------------------------------------------------
function LPS_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
	if buttonName == "LeftButton" then
		LPS:ToggleMoveMode()
	elseif buttonName == "RightButton" then
		LPS:ToggleOptions()
	end
end

function LPS_OnAddonCompartmentEnter(addonName, menuButtonFrame)
	local r, g, b = LPS:GetColor("text")

	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:AddLine(LPS:L("Shows your location and coordinates on screen"), r, g, b)
	GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Toggle move mode"), r, g, b, 0.41, 0.8, 0.94)
	GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), r, g, b, 0.41, 0.8, 0.94)

	GameTooltip:Show()
end

function LPS_OnAddonCompartmentLeave(addonName, menuButtonFrame)
	GameTooltip:Hide()
end