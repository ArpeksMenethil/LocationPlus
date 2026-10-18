local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local inventorySlots = {
        INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_WAIST = 6,
        INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
        INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17, INVTYPE_RANGED = 18,
}

function LPS:BuildDurabilityTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(DURABILITY, 1, 0.82, 0)
                                tt:AddLine(" ")
                                for slotName, index in pairs(inventorySlots) do
                                        local cur, max = GetInventoryItemDurability(index)
                                        if cur and max and max > 0 then
                                                local perc = math.floor(cur / max * 100 + 0.5)
                                                local link = GetInventoryItemLink("player", index) or _G[slotName] or slotName
                                                local icon = GetInventoryItemTexture("player", index)
                                                local r, g, b = DT.colorGradient(perc * 0.01, 1, .1, .1, 1, 1, .1, .1, 1, .1)
                                                tt:AddDoubleLine(icon and string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, link) or link,
                                                        string.format("%d%%", perc), 1, 1, 1, r, g, b)
                                        end
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
