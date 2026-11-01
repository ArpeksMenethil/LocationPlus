local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

-------------------------------------------------- Combat Indicator
do
    LPS:RegisterDatatext({
        key = "combatIndicator",
        nameKey = "Combat Indicator",
        events = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
        update = function(f)
            local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
            local text
            if inCombat then
                text = "|cFFFF3333" .. L.IN_COMBAT .. "|r"
            else
                text = "|cFF2BC226" .. L.OUT_OF_COMBAT .. "|r"
            end
            if f.text then f.text:SetText(text) end
        end,
    })
end
