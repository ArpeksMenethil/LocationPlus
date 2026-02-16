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
	local rb, gb, bb = LPS:GetColor("tooltipSetting")

	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:AddLine(LPS:L("Adds location, coords,\nextra panels and an info-rich tooltip\n(no ElvUI required)"), r, g, b)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Move frame"), rb, gb, bb, rb, gb, bb)
	GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), rb, gb, bb, rb, gb, bb)

	GameTooltip:Show()
end

function LPS_OnAddonCompartmentLeave(addonName, menuButtonFrame)
	GameTooltip:Hide()
end

AddonCompartmentFrame:RegisterAddon({
	text = LPS.addonName,
	icon = "Interface\\AddOns\\LocationPlus\\Media\\logo.tga",
	notCheckable = true,
	func = function(button, menuInputData, menu)
		local buttonName = menuInputData.buttonName;
		print("Hello from the addon compartment! You clicked " .. buttonName .. "!")
	end,
	funcOnEnter = function(button)
		MenuUtil.ShowTooltip(button, function(tooltip)
			tooltip:SetText("My cool item!")
		end)
	end,
	funcOnLeave = function(button)
		MenuUtil.HideTooltip(button)
	end,
})