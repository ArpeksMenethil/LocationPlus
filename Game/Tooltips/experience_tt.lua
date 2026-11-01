local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

function LPS:BuildExperienceTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

    local level = UnitLevel("player")
    local maxPlayer = GetMaxPlayerLevel()
    if level == nil or level <= 0 or (maxPlayer and level >= maxPlayer) then
        return false
    end
    tt:AddDoubleLine(L.EXPERIENCE, string.format("%s %d", L.LEVEL, level), 1, 0.82, 0, 1, 1, 1)
    tt:AddLine(" ")
    local cur, max = UnitXP("player"), UnitXPMax("player")
    if max and max > 0 then
        tt:AddDoubleLine(L.XP, string.format("%s / %s (%.2f%%)", DT.shortValue(cur), DT.shortValue(max), cur / max * 100), 1, 1, 1, 1, 1, 1)
        tt:AddDoubleLine(L.REMAINING_2, string.format("%s (%.2f%%)", DT.shortValue(max - cur), (max - cur) / max * 100), 1, 1, 1, 1, 1, 1)
    end
    local rested = GetXPExhaustion and GetXPExhaustion()
    if rested and rested > 0 then
        tt:AddDoubleLine(L.RESTED, "+" .. DT.shortValue(rested), 1, 1, 1, 0, 1, 0)
    end

end
