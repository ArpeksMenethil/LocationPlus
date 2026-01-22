local LPS_DB = _G.MyAddon and _G.MyAddon.LPS_DB
local LPS = _G.MyAddon and _G.MyAddon.LPS

if not LPS_DB or not LPS then return end

local f = CreateFrame("Button", "LPS_Coords", LPS.holder, "BackdropTemplate")
f:SetSize(100, 22)
f:ClearAllPoints()
f:SetPoint("RIGHT", LPS.locationFrame, "LEFT", -5, 0)

local COLORS = _G.MyAddon.COLORS
local FONT_SIZE = _G.MyAddon.FONT_SIZE or 12
-- backdrop
f:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
f:SetBackdropColor(unpack(COLORS.bg))
f:SetBackdropBorderColor(unpack(COLORS.border))

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
f.text:SetAllPoints()
f.text:SetJustifyH("CENTER")
f.text:SetFontHeight(FONT_SIZE)

C_Timer.NewTicker(0.2, function()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        f.text:SetText(string.format("|cFFFFFFFF%.1f|r | |cFFFFFFFF%.1f|r", pos.x*100, pos.y*100))
    end
end)

f:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        ToggleWorldMap()
    end
end)

LPS.coordsFrame = f
