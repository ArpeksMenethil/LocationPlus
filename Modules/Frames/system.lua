local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end


LPS:RegisterDatatext({
    key = "system",
    nameKey = "System",
    ticker = 1,
    update = function(f)
        local fps = math.floor(GetFramerate() or 0)
        local _, _, lagHome, lagWorld = GetNetStats()
        lagHome = math.floor(lagHome or 0)
        lagWorld = math.floor(lagWorld or 0)
        local lag = lagWorld > 0 and lagWorld or lagHome
        if f.text then
            local fpsText = LPS:ColorByThreshold(fps, 60, 30, false)
            local msText = LPS:ColorByThreshold(lag, 60, 120, true)
            f.text:SetText(string.format("FPS: %s MS: %s", fpsText, msText))
        end
    end,
    customTooltip = true,
    buildTooltip = function(self)
        local d = LPS:GetDB()
        local tt = d and d.tooltips or {}
        local vis = tt.visibility or {}
        if not vis.enable then return end
        if vis.combat and InCombatLockdown() then return end
        if tt.system and tt.system.enable == false then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        if LPS.BuildSystemTooltip then
            LPS:BuildSystemTooltip(GameTooltip)
        end
        GameTooltip:Show()
    end,
})
