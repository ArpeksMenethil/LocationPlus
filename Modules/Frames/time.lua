local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end


local function getDB() return LPS:GetDB() or {} end

local function playedTimeBroker()
    local ok, lib = pcall(function() return LibStub:GetLibrary("LibDataBroker-1.1", true) end)
    if ok and lib then return lib:GetDataObjectByName("Time Played") end
    return nil
end

LPS:RegisterDatatext({
    key = "time",
    nameKey = "Time",
    ticker = 1,
    clicks = { "LeftButtonUp", "RightButtonUp", "MiddleButtonUp" },
        create = function(f)
                if f then f._lpsForceWhite = true end
        end,
    update = function(f)
        if f.text then
            local newText = LPS:GetFormattedGameTime()
            f.text:SetText(newText)
        end
    end,
    onClick = function(self, button)
        local db = getDB()
        if button == "LeftButton" then
            if ToggleTimeManager then
                ToggleTimeManager()
            elseif TimeManagerClockButton_OnClick and TimeManagerClockButton then
                TimeManagerClockButton_OnClick(TimeManagerClockButton)
            end
        elseif button == "RightButton" then
            local brokerPlayedTime = playedTimeBroker()
            if brokerPlayedTime and db.tooltips and db.tooltips.time and db.tooltips.time.playedTime then
                brokerPlayedTime.OnClick(self, button)
                if TimeManagerFrame and TimeManagerFrame:IsVisible() then
                    GameTooltip:Hide()
                end
            end
        elseif button == "MiddleButton" then
            if ToggleCalendar then
                ToggleCalendar()
            end
        end
    end,
    customTooltip = true,
    buildTooltip = function(self)
        local db = getDB()
        local tt = db.tooltips or {}
        local vis = tt.visibility or {}
        if not vis.enable then return end
        if vis.combat and InCombatLockdown() then return end
        if tt.time and tt.time.enable == false then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        LPS:BuildTimeTooltip()
        GameTooltip.isTimeTooltip = true
        GameTooltip:Show()
    end,
})
