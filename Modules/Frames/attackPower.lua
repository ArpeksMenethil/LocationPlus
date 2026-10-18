local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Attack Power
do
        local isHunter = select(2, UnitClass("player")) == "HUNTER"
        local totalAP, baseAPText
        LPS:RegisterDatatext({
                key = "attackPower",
                name = ATTACK_POWER or "Attack Power",
                events = { "UNIT_ATTACK_POWER", "PLAYER_ENTERING_WORLD" },
                update = function(f)
                        local base, pos, neg
                        if isHunter and UnitRangedAttackPower then
                                base, pos, neg = UnitRangedAttackPower("player")
                        else
                                base, pos, neg = UnitAttackPower("player")
                        end
                        base = base or 0
                        totalAP = DT.NotSecret(base) and (base + (pos or 0) + (neg or 0)) or nil
                        baseAPText = tostring(math.floor(base))
                        LPS._dtState = LPS._dtState or {}
                        LPS._dtState.attackPower = { totalAP = totalAP, baseAPText = baseAPText, isHunter = isHunter }
                        if f.text then
                                local label = isHunter and (RANGED_ATTACK_POWER or "Ranged AP") or (ATTACK_POWER or "Attack Power")
                                if totalAP then
                                        f.text:SetText(string.format("%s: %d", label, math.floor(totalAP)))
                                else
                                        f.text:SetText(string.format("%s: |cFF888888%s|r", label, baseAPText))
                                end
                        end
                end,
        })
end
