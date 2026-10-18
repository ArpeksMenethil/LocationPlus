local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

function LPS:BuildCritTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")
    local st = (LPS._dtState or {}).crit or {}
    local critMelee, ratingIndex = st.critMelee or 0, st.ratingIndex or (CR_CRIT_MELEE or 1)

                        tt:AddLine(string.format("|cffFFFFFF%s:|r %.2f%%", MELEE_CRIT_CHANCE or "Melee", critMelee))
                        if GetCombatRatingBonus and ratingIndex then
                                local rating = GetCombatRating and GetCombatRating(ratingIndex) or 0
                                tt:AddDoubleLine(CR_CRIT_TOOLTIP or "Crit Rating", format("%.2f%% from %d", GetCombatRatingBonus(ratingIndex) or 0, rating or 0), 1, 1, 1, 1, 1, 1)
                        end

end
