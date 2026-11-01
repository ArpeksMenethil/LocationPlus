local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

function LPS:BuildBagsTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

    tt:AddDoubleLine(L.BAGS, L.USED_SLOTS .. " / " .. L.TOTAL, 1, 0.82, 0, 1, 1, 1)
    tt:AddLine(" ")
    local NUM_BAG_SLOTS = NUM_BAG_SLOTS or (C_Container and C_Container.NUM_BAG_SLOTS) or 4
    for i = 0, NUM_BAG_SLOTS do
        local bagName = (C_Container and C_Container.GetBagName) and C_Container.GetBagName(i) or (GetBagName and GetBagName(i))
        if bagName then
            local numSlots, freeSlots
            if C_Container and C_Container.GetContainerNumSlots then
                numSlots = C_Container.GetContainerNumSlots(i) or 0
                freeSlots = (C_Container.GetContainerNumFreeSlots and C_Container.GetContainerNumFreeSlots(i)) or 0
            else
                numSlots = (GetContainerNumSlots and GetContainerNumSlots(i)) or 0
                freeSlots = (GetContainerNumFreeSlots and GetContainerNumFreeSlots(i)) or 0
            end
            local used = numSlots - freeSlots
            local pct = numSlots > 0 and (used / numSlots) or 0
            local r, g, b = DT.colorGradient(pct, .1, 1, .1, 1, 1, .1, 1, .1, .1)
            tt:AddDoubleLine(bagName, string.format("%d / %d", used, numSlots), 1, 1, 1, r, g, b)
        end
    end

    tt:AddLine(" ")
    tt:AddDoubleLine(L.LMB, L.TOGGLE_ALL_BAGS, rB, gB, bB, rB, gB, bB)
end
