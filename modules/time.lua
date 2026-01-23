local LPS = _G.MyAddon and _G.MyAddon.LPS
if not LPS then return end


-- Ждём, чтобы SavedVariables точно загрузились
C_Timer.After(0.1, function()
    if not LPS_DB then return end


    -- Фрейм для времени
    local f = CreateFrame("Button", "LPS_Time", LPS.holder, "BackdropTemplate")
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
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetAllPoints()
    f.text:SetJustifyH("CENTER")
    f.text:SetFontHeight(FONT_SIZE)

    -- Флаг для тултипа времени
    f.isTimeTooltip = true

    -- обновление времени каждую секунду
    local lastDisplay = ""
    C_Timer.NewTicker(1, function()
        local newText = LPS:GetFormattedGameTime()

        if newText ~= lastDisplay then
            lastDisplay = newText
            f.text:SetText(newText)

            -- если тултип открыт — обновляем его
            if GameTooltip:IsVisible() and GameTooltip.isTimeTooltip then
                LPS:BuildTimeTooltip()
            end
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

    f:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ToggleTimeManager() -- открыть часы
        elseif button == "RightButton" then
            ToggleCalendar() -- открыть календарь
        end
    end)

    LPS.timeFrame = f



end)