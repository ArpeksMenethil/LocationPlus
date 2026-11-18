local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:CreateLocationFrame()
    local db = LPS:GetDB()
    if not db or not LPS.frame.holder then return end

    local bgR, bgG, bgB, bgA = LPS:GetColor("bg")
    local bdR, bdG, bdB, bdA = LPS:GetColor("border")
    ---@type LPSFrameParams
    local params = {
        name = "LPS_Location",
        frameType = "Button",
        parent = LPS.frame.holder,
        --- Статичная точка: location не смещается при добавлении/удалении боковых панелей
        --- (см. UpdateFrameSize: 9 = (4*2 + 10)/2, 3 = 6/2).
        anchor = {"TOPLEFT", LPS.frame.holder, "TOPLEFT", 9, 3},
        padding = {((db.layout and db.layout.locPaddingX) or 20), ((db.layout and db.layout.locPaddingY) or 9)},
        fontSize = db.settings.fontSize or 12,
        bgColor = {bgR, bgG, bgB, bgA},
        borderColor = {bdR, bdG, bdB, bdA},
        updateFunc = function(f)
            local db2 = LPS:GetDB()
            local mapID = C_Map.GetBestMapForUnit("player")

            local sub = GetSubZoneText()
            local zone = LPS:GetMapNameByIDAlt(mapID)

            local hasSub = sub and sub ~= "" and sub ~= zone
            local showZone = db2 and db2.show and db2.show.zone

            local baseText
            if showZone and hasSub and zone then
                baseText = string.format("%s: %s", zone, sub)
            else
                baseText = hasSub and sub or zone
            end
            baseText = baseText or UNKNOWN

            local playerMinLevel, playerMaxLevel, playerLevelColor, extra
            local icon = ""
            local other = db2 and db2.show and db2.show.displayOther
            local showIcon = db2 and db2.show and db2.show.showicon

            if other == "RLEVEL" then
                playerMinLevel, playerMaxLevel, playerLevelColor = LPS:GetLevelRange(mapID)
                extra = ""

                if playerMinLevel and playerMaxLevel and playerMinLevel ~= playerMaxLevel then
                    extra = playerLevelColor..playerMinLevel.."-"..playerMaxLevel..FONT_COLOR_CODE_CLOSE
                elseif playerMinLevel and playerMinLevel ~= "" then
                    extra = playerLevelColor..playerMinLevel..FONT_COLOR_CODE_CLOSE
                end

                if showIcon and extra ~= "" then
                    icon = " " .. LPS.icons.Level
                end

                if playerMaxLevel == 0 or playerMinLevel == 0 then
                    extra = ""
                    icon = ""
                end
            elseif other == "PFISH" and not LPS.Retail then
                local fishing, maxFish = LPS:GetFishingLvl()
                if fishing and maxFish then
                    extra = format("|cff%02x%02x%02x%d-%d|r", 255, 255, 255, fishing, maxFish)
                elseif fishing and not maxFish then
                    extra = format("|cff%02x%02x%02x%d|r", 255, 255, 255, fishing)
                end
                if showIcon then
                    icon = " " .. LPS.icons.Fish
                end
            elseif other == "PET" and (LPS.Retail or LPS.Mists) then
                extra = LPS:GetBattlePetLvl(zone) or ""
                if showIcon and extra ~= "" then
                    icon = " " .. LPS.icons.Pet
                end
            end

            local text = baseText
            if extra and extra ~= "" then
                text = string.format("%s (%s) %s", baseText, extra, icon)
            end

            if f.text then
                f.text:SetText(text)
                f.text:SetTextColor(LPS:GetZoneStatus(true))
            end
        end,
        updateEvent = {events = {"ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED_INDOORS","PLAYER_ENTERING_WORLD"}},
        registerClicks = {"LeftButtonUp", "RightButtonUp"},
        onClick = function(self, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    local zone = GetZoneText()
                    local subZone = GetSubZoneText()
                    local x,y = LPS:GetPlayerCoords()
                    local msg = string.format("%s: %s (%.2f %.2f)", zone, subZone, x*100, y*100)
                    ChatEdit_ActivateChat(ChatEdit_GetLastActiveWindow())
                    ChatEdit_InsertLink(msg)
                else
                    ToggleWorldMap()
                    WorldMapFrame:ClearAllPoints()
                    WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER")
                end
            elseif button == "RightButton" then
                LPS:ToggleOptions()
            end
        end,
        tooltipFunc = function(self)
            local db = LPS:GetDB()
            if not db.tooltips.visibility.enable then return end
            if db.tooltips.visibility.combat and InCombatLockdown() then return end
            if not db.tooltips.location.enable then return end
            GameTooltip:SetOwner(self,"ANCHOR_BOTTOM")
            GameTooltip:ClearLines()
            LPS:ApplyTooltipFont(GameTooltip)
            LPS:BuildLocationTooltip(GameTooltip)
            GameTooltip:Show()
        end,
    }

    return LPS:CreateFrame(params)
end
