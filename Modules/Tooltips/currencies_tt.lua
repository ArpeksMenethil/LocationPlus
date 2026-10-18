local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local function watchedTokens()
        local list = {}
        if C_TokenFrame and C_TokenFrame.GetWatchTokenInfo then
                for i = 1, MAX_WATCHED_TOKENS or 3 do
                        local id = select(1, C_TokenFrame.GetWatchTokenInfo(i))
                        if not id then break end
                        list[#list + 1] = id
                end
        elseif GetBackpackCurrencyInfo then
                for i = 1, MAX_WATCHED_TOKENS or 3 do
                        local name, count, icon = GetBackpackCurrencyInfo(i)
                        if not name then break end
                        list[#list + 1] = { name = name, count = count, icon = icon }
                end
        end
        return list
end

function LPS:BuildCurrenciesTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(CURRENCY, 1, 0.82, 0)
                                tt:AddLine(" ")
                                local tokens = watchedTokens()
                                for _, cur in ipairs(tokens) do
                                        if type(cur) == "table" then
                                                tt:AddDoubleLine(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", cur.icon, cur.name), tostring(cur.count), 1, 1, 1, 1, 1, 1)
                                        end
                                end
                                tt:AddLine(" ")
                                tt:AddDoubleLine(LPS:L("Gold")..":", LPS:FormatMoneySmart(GetMoney() or 0), nil, nil, nil, 1, 1, 1)

    tt:AddLine(" ")
    tt:AddDoubleLine(LPS:L("LMB"), LPS:L("Open Token frame"), rB, gB, bB, rB, gB, bB)
end
