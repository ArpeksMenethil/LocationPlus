local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildDifficultyTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local function diffLabel(id)
        if GetDifficultyInfo then
            local name = GetDifficultyInfo(id)
            if name then return name end
        end
        return tostring(id)
    end

        			tt:AddLine(LPS:L("Current Difficulties:"), 1, 0.82, 0)
        			tt:AddLine(" ")
        			if GetDungeonDifficultyID then
        				tt:AddDoubleLine(LPS:L("Dungeon"), diffLabel(GetDungeonDifficultyID()), 1, 1, 1, 1, 1, 1)
        			end
        			if GetRaidDifficultyID then
        				tt:AddDoubleLine(LPS:L("Raid"), diffLabel(GetRaidDifficultyID()), 1, 1, 1, 1, 1, 1)
        			end

    GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(LPS:L("LMB"), LPS:L("Click"), rB, gB, bB, rB, gB, bB)

        if GameTooltipTextLeft1 then
                local rT, gT, bT = GameTooltipTextLeft1:GetTextColor()
                GameTooltipTextLeft1:SetFontObject(GameTooltipText)
                GameTooltipTextLeft1:SetTextColor(rT, gT, bT)
        end
        if GameTooltipTextRight1 then
                local rT, gT, bT = GameTooltipTextRight1:GetTextColor()
                GameTooltipTextRight1:SetFontObject(GameTooltipText)
                GameTooltipTextRight1:SetTextColor(rT, gT, bT)
        end
end
