local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local inventorySlots = {
        INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_WAIST = 6,
        INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
        INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17, INVTYPE_RANGED = 18,
}

-- Только C_Item, без GetInventoryItemDurability() (secret-числа). См. Modules/Frames/durability.lua.
local function isValidNumber(v)
        if type(v) ~= "number" then return false end
        if isSecret then
                local ok, secret = pcall(isSecret, v)
                if ok and secret then return false end
        end
        return true
end

local function slotDurability(index)
        if not (C_Item and C_Item.Create) then return nil end
        local ok, item = pcall(C_Item.Create, C_Item, "player", index)
        if not ok or type(item) ~= "table" then return nil end
        local validOk, valid = pcall(function() return item.IsValid and item:IsValid() end)
        if not (validOk and valid) then return nil end
        local hasOk, has = pcall(function() return item.HasDurability and item:HasDurability() end)
        if not (hasOk and has) then return nil end
        local dOk, cur, max = pcall(function()
                local a, b = item:GetDurability()
                return a, b
        end)
        if not dOk then return nil end
        if cur and max and isValidNumber(cur) and isValidNumber(max) and max > 0 then
                return cur, max
        end
        return nil
end

local INVTYPE_NAMES_KEY = {
        [1] = "INVTYPE_HEAD", [3] = "INVTYPE_SHOULDER", [5] = "INVTYPE_CHEST",
        [6] = "INVTYPE_WAIST", [7] = "INVTYPE_LEGS", [8] = "INVTYPE_FEET",
        [9] = "INVTYPE_WRIST", [10] = "INVTYPE_HAND", [16] = "INVTYPE_WEAPONMAINHAND",
        [17] = "INVTYPE_WEAPONOFFHAND", [18] = "INVTYPE_RANGED",
}

local function slotLabel(index, item)
        local name = _G[INVTYPE_NAMES_KEY[index]] or INVTYPE_NAMES_KEY[index]
        if item and item.GetItemLevelEquipped then
                local ok, ilvl = pcall(item.GetItemLevelEquipped, item)
                if ok and isValidNumber(ilvl) and ilvl > 0 then
                        return string.format("%s (%d)", name or "", ilvl)
                end
        end
        return name
end

local function slotIcon(index)
        local ok, icon = pcall(GetInventoryItemTexture, "player", index)
        if ok and (type(icon) == "string" or isValidNumber(icon)) then return icon end
        return nil
end

local function slotDurabilityFull(index)
        if not (C_Item and C_Item.Create) then return nil end
        local ok, item = pcall(C_Item.Create, C_Item, "player", index)
        if not ok or type(item) ~= "table" then return nil end
        local validOk, valid = pcall(function() return item.IsValid and item:IsValid() end)
        if not (validOk and valid) then return nil end
        local hasOk, has = pcall(function() return item.HasDurability and item:HasDurability() end)
        if not (hasOk and has) then return nil end
        local dOk, cur, max = pcall(function()
                local a, b = item:GetDurability()
                return a, b
        end)
        if not dOk then return nil end
        if cur and max and isValidNumber(cur) and isValidNumber(max) and max > 0 then
                return cur, max, item
        end
        return nil
end

function LPS:BuildDurabilityTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(DURABILITY, 1, 0.82, 0)
                                tt:AddLine(" ")
                                for _, index in pairs(inventorySlots) do
                                        local cur, max, item = slotDurabilityFull(index)
                                        if cur and max and max > 0 then
                                                local perc = math.floor(cur / max * 100 + 0.5)
                                                local label = slotLabel(index, item)
                                                local icon = slotIcon(index)
                                                local r, g, b = DT.colorGradient(perc * 0.01, 1, .1, .1, 1, 1, .1, .1, 1, .1)
                                                tt:AddDoubleLine(icon and string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, label) or label,
                                                        string.format("%d%%", perc), 1, 1, 1, r, g, b)
                                        end
                                end

    tt:AddLine(" ")
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open character panel"), rB, gB, bB, rB, gB, bB)
end
