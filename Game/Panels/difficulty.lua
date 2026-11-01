local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
local DT = LPS._DT

-------------------------------------------------- Difficulty
do
    local function diffLabel(id)
        if GetDifficultyInfo then
            local name = GetDifficultyInfo(id)
            if name then return name end
        end
        return tostring(id)
    end

    LPS:RegisterDatatext({
        key = "difficulty",
        nameKey = "Difficulty",
        events = { "PLAYER_DIFFICULTY_CHANGED", "LOADING_SCREEN_DISABLED", "ZONE_CHANGED_NEW_AREA" },
        update = function(f)
            if not GetInstanceInfo then return end
            local _, instanceType, difficultyID = GetInstanceInfo()
            local text
            if instanceType and instanceType ~= "none" and difficultyID then
                text = string.format("%s: %s", instanceType == "raid" and L.RAID or L.DUNGEON, diffLabel(difficultyID))
            else
                local dd = GetDungeonDifficultyID and GetDungeonDifficultyID()
                local rd = GetRaidDifficultyID and GetRaidDifficultyID()
                text = string.format("%s: %s  |  %s: %s",
                    L.DUNGEON, dd and diffLabel(dd) or "?",
                    L.RAID, rd and diffLabel(rd) or "?")
            end
            if f.text then f.text:SetText(text) end
        end,
    })
end
