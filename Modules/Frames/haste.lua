local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Haste
do
        local haste
        LPS:RegisterDatatext({
                key = "haste",
                name = LPS:L("Haste"),
                events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
                update = function(f)
                        LPS._dtState = LPS._dtState or {}
                        LPS._dtState.hasteVal = nil
                        haste = GetHaste and GetHaste() or 0
                        LPS._dtState.hasteVal = haste
                        if f.text then
                                f.text:SetText(string.format("%+d%%", haste))
                        end
                end,
        })
end
