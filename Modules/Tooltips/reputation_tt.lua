local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS
local DT = LPS._DT

local function watchedFaction()
        if C_Reputation and C_Reputation.GetWatchedFactionData then
                local d = C_Reputation.GetWatchedFactionData()
                if d and d.name then return d end
                return nil
        end
        local name, bottomLine, displayedMax, currentStanding, factionMember,
                currentReputation, maxReputation = GetWatchedFactionInfo and GetWatchedFactionInfo()
        if not name then return nil end
        return {
                name = name,
                currentValue = currentReputation or currentStanding,
                maxValue = maxReputation or displayedMax,
                offsetValue = bottomLine,
        }
end

function LPS:BuildReputationTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                local data = watchedFaction()
                                if not data then return end
                                tt:AddLine(data.name or "", 1, 0.82, 0)
                                tt:AddLine(" ")
                                local reaction = data.reaction or data.standing or 5
                                tt:AddDoubleLine(STANDING .. ":", _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN, 1, 1, 1, 1, 1, 1)
                                local cur = (data.currentValue or 0) - (data.offsetValue or 0)
                                local max = (data.maxValue or 0) - (data.offsetValue or 0)
                                if max > 0 then
                                        tt:AddDoubleLine(REPUTATION .. ":", string.format("%d / %d (%d%%)", cur, max, cur / max * 100), 1, 1, 1, 1, 1, 1)
                                end

    tt:AddLine(" ")
    tt:AddLine(LPS:L("LMB") .. ": " .. LPS:L("Open reputation panel"), 0.65, 0.65, 0.65)
end
