local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

local addonVersion = C_AddOns.GetAddOnMetadata(LPS.addonName, "Version") or "?.?.?" -- Версия аддона

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
LPS.frame = LPS.frame or {}
LPS.frame.holder = CreateFrame("Frame", "LPS_Holder", UIParent, "BackdropTemplate")
LPS.frame.holder:SetFrameStrata("HIGH")
LPS.frame.holder:SetSize(400, 25)
LPS.frame.holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
LPS.frame.holder:SetBackdropColor(1, 1, 1, 0) -- прозрачный

---@type LPSFrameParams
-- local params = {
-- 	name = "LPS_Holder",
-- 	parent = UIParent,
-- 	frameType = "Frame",
-- 	size = {400, 25},
-- 	backdrop = { bgFile = "Interface\\Buttons\\WHITE8x8" },
-- 	bgColor = {1, 1, 1, 0},
-- 	updateEvent = {events = {"ADDON_LOADED"}},
-- 	updateFunc = function(self, event, name)
-- 		if name ~= addonName then return end
-- 		if event == "ADDON_LOADED" then LPS:onLoaded(name) end
-- 	end
-- }
-- LPS.frame.holder = LPS:CreateFrame(params)
-- LPS.frame.holder:SetFrameStrata("HIGH")

----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.frame.holder:RegisterEvent("ADDON_LOADED")
LPS.frame.holder:SetScript("OnEvent", function(self, event, name)
	if name ~= LPS.addonName then return end
	if event == "ADDON_LOADED" then LPS:onLoaded(name) end
end)


function LPS:onLoaded(name)
	if LPS.Retail and LPS_DB.general.is24H then
		SetCVar("timeMgrUseMilitaryTime", 1)
	end

	LPS_DB = LPS:ApplyDefaults(LPS_DB or {}, LPS.defaults)
	LPS:ApplyHolderPosition()

	LPS:CreateAllFrames()

	C_Timer.After(1, function()
		LPS:UpdateFrameSize()
	end)

	LPS:Print(format(LPS:L("loaded. Current version: |c%sv%s|r"), LPS.addonTextColor, addonVersion))
end

function LPS:CreateAllFrames()
	LPS.frame.location = LPS:CreateLocationFrame()
	LPS.frame.coords   = LPS:CreateCoordsFrame()
	LPS.frame.time     = LPS:CreateTimeFrame()
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

SLASH_LPS1 = "/lps"
SlashCmdList["LPS"] = function()
	 LPS:OpenOptions()
end