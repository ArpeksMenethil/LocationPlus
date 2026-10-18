local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

function LPS:BuildHpsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local st = LPS._combatStats or {}
    local healTotal, combatTime = st.heal or 0, st.time or 0

                        tt:AddLine(LPS:L("HPS"), 1, 0.82, 0)
                        tt:AddLine(" ")
                        tt:AddDoubleLine(LPS:L("Healing:"), DT.shortValue(healTotal), 1, 1, 1, 1, 1, 1)
                        tt:AddDoubleLine(LPS:L("Time:"), string.format("%.0f s", combatTime), 1, 1, 1, 1, 1, 1)
                        tt:AddLine(" ")
                        tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Reset counters"), rB, gB, bB, rB, gB, bB)
end
