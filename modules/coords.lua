local LPS = _G.MyAddon and _G.MyAddon.LPS
if not LPS then return end

-- Ждём, чтобы SavedVariables точно загрузились
C_Timer.After(0.1, function()
	if not LPS_DB then return end

    -- Дефолтные значения, если их нет
    local COLORS = LPS_DB.colors or {}
    local FONT_SIZE = LPS_DB.fontSize or 12

    -- Создаём фрейм координат
    local f = CreateFrame("Button", "LPS_Coords", LPS.holder, "BackdropTemplate")
    f:SetSize(100, 22)
    f:ClearAllPoints()
    f:SetPoint("RIGHT", LPS.locationFrame, "LEFT", -5, 0)

    -- backdrop
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(unpack(COLORS.bg or {0,0,0,0.6}))
    f:SetBackdropBorderColor(unpack(COLORS.border or {0.3,0.3,0.3,1}))

    -- текст
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetAllPoints()
    f.text:SetJustifyH("CENTER")
    f.text:SetFont(GameFontNormalSmall:GetFont(), FONT_SIZE)

    -- обновление координат
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


    
end)
