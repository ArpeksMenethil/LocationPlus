local addonName = ...
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?.?.?" -- Версия аддона

local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
LPS.frame.holder = CreateFrame("Frame", "LPS_Holder", UIParent, "BackdropTemplate")
LPS.frame.holder:SetFrameStrata("HIGH")
LPS.frame.holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
LPS.frame.holder:SetBackdropColor(1, 1, 1, 0) -- прозрачный

----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.frame.holder:RegisterEvent("ADDON_LOADED")
LPS.frame.holder:SetScript("OnEvent", function(self, event, name)
	if name ~= addonName then return end
	if event == "ADDON_LOADED" then LPS:onLoaded(name) end
end)


function LPS:onLoaded(name)
	if LPS.Retail and LPS_DB.general.is24H then
		SetCVar("timeMgrUseMilitaryTime", 1)
	end

	LPS_DB = LPS:ApplyDefaults(LPS_DB or {}, LPS.defaults)
	LPS:ApplyHolderPosition()

	C_Timer.After(0.5, function()
		LPS:UpdateFrameSize()
	end)

	print("|c"..LPS.addonTextColor..addonName.."|r "
		..LPS:L("loaded. Current version")..": |c"
		..LPS.addonTextColor.."v"..addonVersion.."|r"
	)
end


-- Toggle Move Mode
SLASH_LPSMOVE1 = "/lpsmove"
SlashCmdList.LPSMOVE = function()
	LPS:ToggleMoveMode()
end

-- Reset Holder Position
SLASH_LPSRESET1 = "/lpsreset"
SlashCmdList.LPSRESET = function()
	LPS:ResetFramePosition()
end