local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local L = _G.ArpeksLPS.L

----------------------------------------------------------------
-- Addon Compartment
----------------------------------------------------------------
function LPS_OnAddonCompartmentClick(addonName, buttonName, menuButtonFrame)
    if buttonName == "LeftButton" then
        LPS:ToggleMove()
    elseif buttonName == "RightButton" then
        print("ПКМ нажата — можно открыть настройки")
        LPS:ResetPosition()
    end
end

function LPS_OnAddonCompartmentEnter(addonName, buttonName, menuButtonFrame)
    local r, g, b = unpack(LPS_DB.colors)

    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:AddLine(L["Shows your location and coordinates on screen"], r, g, b)
    GameTooltip:AddDoubleLine(L["LMB"], L["Toggle move mode"], r, g, b, 0.41, 0.8, 0.94)
    GameTooltip:AddDoubleLine(L["RMB"], L["Reset position"], r, g, b, 0.41, 0.8, 0.94)

    GameTooltip:Show()
end

function LPS_OnAddonCompartmentLeave(addonName, buttonName, menuButtonFrame)
    GameTooltip:Hide()
end