local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

----------------------------------------------------------------
-- Addon Compartment
----------------------------------------------------------------
local function OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
	if buttonName == "RightButton" then
		LPS:ToggleOptions()
	end
end

local function OnAddonCompartmentEnter(addonName, menuButtonFrame)
	local r, g, b = LPS:GetColor("text")
	local ry, gy, by = LPS:GetColor("tooltip")
	local rb, gb, bb = LPS:GetColor("tooltipSetting")

	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	GameTooltip:AddDoubleLine(LPS.addon.name, LPS.addon.version, ry, gy, by, r, g, b)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(LPS:L("Adds location, coords,\nextra panels and an info-rich tooltip\n(no ElvUI required)"), r, g, b)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(LPS:L("RMB"), LPS:L("Toggle Configuration"), rb, gb, bb, rb, gb, bb)

	GameTooltip:Show()
end

local function OnAddonCompartmentLeave(addonName, menuButtonFrame)
	GameTooltip:Hide()
end

local function isRegisteredAddonCompartment(data)
	if not (AddonCompartmentFrame and AddonCompartmentFrame.registeredAddons) then return false end
	for i = 1, #AddonCompartmentFrame.registeredAddons do
		local entry = AddonCompartmentFrame.registeredAddons[i]
		if entry == data then
			return true
		end
	end
	return false
end

local function unregisterAddonCompartment(data)
	if not (AddonCompartmentFrame and AddonCompartmentFrame.registeredAddons) then return end
	for i = #AddonCompartmentFrame.registeredAddons, 1, -1 do
		local entry = AddonCompartmentFrame.registeredAddons[i]
		if entry == data or (entry and entry.text == LPS.addon.title) then
			table.remove(AddonCompartmentFrame.registeredAddons, i)
		end
	end
	if AddonCompartmentFrame.UpdateDisplay then
		AddonCompartmentFrame:UpdateDisplay()
	end
end

function LPS:ApplyAddonCompartmentRegistration()
	if not LPS.Retail then return end
	if not AddonCompartmentFrame or not AddonCompartmentFrame.RegisterAddon then return end

	local db = LPS.GetDB and LPS:GetDB()
	local enabled = db and db.show and db.show.addonCompartment

	LPS._addonCompartmentData = LPS._addonCompartmentData or {
		text = LPS.addon.title,
		icon = "Interface\\AddOns\\LocationPlus\\Media\\logo.tga",
		notCheckable = true,
		func = function(button, menuInputData, menu)
			local buttonName = menuInputData and menuInputData.buttonName
			OnAddonCompartmentClick(LPS.addon.name, buttonName, button)
		end,
		funcOnEnter = function(button)
			OnAddonCompartmentEnter(LPS.addon.name, button)
		end,
		funcOnLeave = function(button)
			OnAddonCompartmentLeave(LPS.addon.name, button)
		end,
	}

	local data = LPS._addonCompartmentData
	if enabled then
		if not isRegisteredAddonCompartment(data) then
			AddonCompartmentFrame:RegisterAddon(data)
		end
	else
		unregisterAddonCompartment(data)
	end
end