local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildExperienceTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                local level = UnitLevel("player")
                                -- Как в ElvUI: на максимальном уровне подсказка не показывается
                                local maxPlayer = MAX_PLAYER_LEVEL or (GetMaxLevelForPlayer and GetMaxLevelForPlayer(select(4, GetBuildInfo())))
                                if level == nil or level <= 0 or (maxPlayer and level >= maxPlayer) then
                                        return false
                                end
                                tt:AddDoubleLine(LPS:L("Experience"), string.format("%s %d", LPS:L("Level"), level), 1, 0.82, 0, 1, 1, 1)
                                tt:AddLine(" ")
                                local cur, max = UnitXP("player"), UnitXPMax("player")
                                if max and max > 0 then
                                        tt:AddDoubleLine(LPS:L("XP:"), string.format("%s / %s (%.2f%%)", DT.shortValue(cur), DT.shortValue(max), cur / max * 100), 1, 1, 1, 1, 1, 1)
                                        tt:AddDoubleLine(LPS:L("Remaining:"), string.format("%s (%.2f%%)", DT.shortValue(max - cur), (max - cur) / max * 100), 1, 1, 1, 1, 1, 1)
                                end
                                local rested = GetXPExhaustion and GetXPExhaustion()
                                if rested and rested > 0 then
                                        tt:AddDoubleLine(LPS:L("Rested:"), "+" .. DT.shortValue(rested), 1, 1, 1, 0, 1, 0)
                                end

end
