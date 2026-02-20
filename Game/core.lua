local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

LPS.addon.version = (
	(C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Version"))
		or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Version"))
		or "?.?.?"
) -- Версия аддона
LPS.addon.title = (
	(C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(LPS.addon.name, "Title"))
		or (GetAddOnMetadata and GetAddOnMetadata(LPS.addon.name, "Title"))
		or "?.?.?"
) -- Версия аддона

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
		if name ~= LPS.addon.name then return end
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
	if name ~= LPS.addon.name then return end
	if event == "ADDON_LOADED" then LPS:onLoaded(name) end
end)


function LPS:onLoaded(name)
	if LibStub and LibStub:GetLibrary("AceDB-3.0", true) and LibStub:GetLibrary("AceConfig-3.0", true) and LibStub:GetLibrary("AceConfigDialog-3.0", true) then
		local AceDB = LibStub("AceDB-3.0")
		if type(LPS_DB) == "table" and not (LPS_DB.profiles or LPS_DB.profileKeys or LPS_DB.global) then
			local old = LPS_DB
			local oldGold = old.gold
			old.gold = nil
			LPS_DB = { profiles = { Default = old }, global = {} }
			if oldGold ~= nil then
				LPS_DB.global.gold = oldGold
			end
		else
			LPS_DB = LPS_DB or {}
			LPS_DB.global = LPS_DB.global or {}
			if LPS_DB.gold and not LPS_DB.global.gold then
				LPS_DB.global.gold = LPS_DB.gold
				LPS_DB.gold = nil
			end
			if LPS_DB.profiles then
				for _, p in pairs(LPS_DB.profiles) do
					if p and p.gold then
						if not LPS_DB.global.gold then
							LPS_DB.global.gold = p.gold
						end
						p.gold = nil
					end
				end
			end
		end
		LPS.db = AceDB:New("LPS_DB", { profile = LPS.defaults, global = { gold = { realms = {} } } }, "Default")
		if LPS.db and LPS.db.RegisterCallback then
			LPS.db.RegisterCallback(LPS, "OnProfileChanged", "OnAceProfileChanged")
			LPS.db.RegisterCallback(LPS, "OnProfileCopied", "OnAceProfileCopied")
			LPS.db.RegisterCallback(LPS, "OnProfileReset", "OnAceProfileReset")
		end
		if LPS.Options then
			if LPS.Options.EnsureAceProfilesTab then
				LPS.Options:EnsureAceProfilesTab()
			end
			if LPS.Options.RegisterAceProfiles then
				LPS.Options:RegisterAceProfiles()
			end
		end
	end

	if LPS.DEBUG then
		LPS:Print("WOW PATCH: "..LPS.wow.patch, false)
		LPS:Print("WOW BUILD: "..LPS.wow.build, false)
		LPS:Print("WOW DATE: "..LPS.wow.date, false)
		LPS:Print("WOW TOC: "..LPS.wow.toc, false)
		LPS:Print("WOW PROJECT: "..LPS.wow.project, false)
	end

	local db = LPS:GetDB()
	LPS:ApplyDefaults(db or {}, LPS.defaults)
	LPS:ApplyTimeFormat()
	LPS:ApplyHolderPosition()

	LPS:CreateAllFrames()
	LPS:ApplyAllSettings()
	if LPS.ApplyAddonCompartmentRegistration then
		LPS:ApplyAddonCompartmentRegistration()
	end
	if LPS.CreateMinimapButton then
		LPS:CreateMinimapButton()
	end

	if LPS.Retail and db.general.is24H then
		SetCVar("timeMgrUseMilitaryTime", 1)
	end

	C_Timer.After(1, function()
		LPS:UpdateFrameSize()
		LPS:ApplyLayout()
	end)

	if db and db.general and db.general.loginMessage then
		LPS:Print(format(LPS:L("loaded. Current version:").." |c%sv%s|r", LPS.addon.textColor, LPS.addon.version), false)
	end
end

function LPS:CreateAllFrames()
	LPS.frame.location = LPS:CreateLocationFrame()
	LPS.frame.coords   = LPS:CreateCoordsFrame()
	LPS.frame.time     = LPS:CreateTimeFrame()
	LPS.frame.gold     = LPS.CreateGoldFrame and LPS:CreateGoldFrame() or nil
	LPS.frame.system   = LPS.CreateSystemFrame and LPS:CreateSystemFrame() or nil
end

SLASH_LPS1 = "/lps"
SlashCmdList["LPS"] = function()
	 LPS:ToggleOptions()
end
