local LPS = _G.MyAddon and _G.MyAddon.LPS
if not LPS then return end

local formatStr = "|cFFFFFFFF%H|r:|cFFFFFFFF%M|r"


-- Ждём, чтобы SavedVariables точно загрузились
C_Timer.After(0.1, function()
    if not LPS_DB then return end


    -- Фрейм для времени
    local f = CreateFrame("Frame", "LPS_Time", LPS.holder, "BackdropTemplate")
    f:SetSize(100, 22)
    f:ClearAllPoints()
    f:SetPoint("LEFT", LPS.locationFrame, "RIGHT", 5, 0)

    local COLORS = LPS_DB.colors or {}
    local FONT_SIZE = LPS_DB.fontSize or 12

    -- стиль панели
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile     = false,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(unpack(COLORS.bg))
    f:SetBackdropBorderColor(unpack(COLORS.border))

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetAllPoints()
    f.text:SetJustifyH("CENTER")
    f.text:SetFontHeight(FONT_SIZE)

    -- Флаг для тултипа времени
    f.isTimeTooltip = true

    -- обновление времени каждую секунду
    C_Timer.NewTicker(1, function()
        -- всегда обновляем текст панели
        f.text:SetText(date(formatStr))

        -- обновляем тултип только если он виден и это тултип времени
        if GameTooltip:IsVisible() and GameTooltip.isTimeTooltip then
            LPS:BuildTimeTooltip()
        end
    end)

    -- === TOOLTIP ===
    f:SetScript("OnEnter", function(self)
        if not LPS_DB.tooltips.time.enable then return end

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        LPS:BuildTimeTooltip()
        GameTooltip.isTimeTooltip = true  -- отмечаем, что это тултип времени
        GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function(self)
        GameTooltip_Hide()
        GameTooltip.isTimeTooltip = false -- сбрасываем флаг
    end)

    LPS.timeFrame = f



end)