local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

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

        			tt:AddLine(LPS:L("CURRENT_DIFFICULTIES"), 1, 0.82, 0)
        			tt:AddLine(" ")
        			if GetDungeonDifficultyID then
        				tt:AddDoubleLine(LPS:L("DUNGEON"), diffLabel(GetDungeonDifficultyID()), 1, 1, 1, 1, 1, 1)
        			end
        			if GetRaidDifficultyID then
        				tt:AddDoubleLine(LPS:L("RAID"), diffLabel(GetRaidDifficultyID()), 1, 1, 1, 1, 1, 1)
        			end

end
