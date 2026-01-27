local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

local addonVersion = C_AddOns.GetAddOnMetadata(LPS.addonName, "Version") or "?.?.?" -- Версия аддона

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
---@type LPSFrameParams
local params = {
	name = "LPS_Holder",
	parent = UIParent,
	frameType = "Frame",
	size = {400, 25},
	backdrop = { bgFile = "Interface\\Buttons\\WHITE8x8" },
	bgColor = {1, 1, 1, 0},
	borderColor = {1, 1, 1, 0},
	updateEvent = {events = {"ADDON_LOADED"}},
	updateFunc = function(self, event, name)
		if name ~= addonName then return end
		if event == "ADDON_LOADED" then LPS:onLoaded(name) end
	end
}
LPS.frame.holder = LPS:CreateFrame(params)
LPS.frame.holder:SetFrameStrata("HIGH")

----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.frame.holder:RegisterEvent("ADDON_LOADED")
LPS.frame.holder:SetScript("OnEvent", function(self, event, name)
	if name ~= LPS.addonName then return end
	if event == "ADDON_LOADED" then LPS:onLoaded(name) end
end)


function LPS:onLoaded(name)
	if LibStub and LibStub:GetLibrary("AceDB-3.0", true) and LibStub:GetLibrary("AceConfig-3.0", true) and LibStub:GetLibrary("AceConfigDialog-3.0", true) then
		local AceDB = LibStub("AceDB-3.0")
		if type(LPS_DB) == "table" and not LPS_DB.profiles and not LPS_DB.profileKeys then
			LPS_DB = { profiles = { Default = LPS_DB } }
		end
		LPS.db = AceDB:New("LPS_DB", { profile = LPS.defaults }, "Default")
	end

	if LPS.DEBUG then
		LPS:Print("WOW PATCH: "..LPS.wowpatch)
		LPS:Print("WOW BUILD: "..LPS.wowbuild)
		LPS:Print("WOW DATE: "..LPS.wowdate)
		LPS:Print("WOW TOC: "..LPS.wowtoc)
		LPS:Print("WOW PROJECT: "..WOW_PROJECT_ID)
	end

	local db = LPS:GetDB()
	LPS:ApplyDefaults(db or {}, LPS.defaults)
	LPS:ApplyTimeFormat()
	LPS:ApplyHolderPosition()

	LPS:CreateAllFrames()
	LPS:ApplyAllSettings()
	if LPS.CreateMinimapButton then
		LPS:CreateMinimapButton()
	end

	C_Timer.After(1, function()
		LPS:UpdateFrameSize()
	end)

	if db and db.general and db.general.loginMessage then
		LPS:Print(format(LPS:L("loaded. Current version: |c%sv%s|r"), LPS.addonTextColor, addonVersion))
	end
end

function LPS:CreateAllFrames()
	LPS.frame.location = LPS:CreateLocationFrame()
	LPS.frame.coords   = LPS:CreateCoordsFrame()
	LPS.frame.time     = LPS:CreateTimeFrame()
end

SLASH_LPS1 = "/lps"
SlashCmdList["LPS"] = function()
	 LPS:ToggleOptions()
end