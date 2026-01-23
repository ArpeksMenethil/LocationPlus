local addonName, LPS = ...
local DEBUG = true

_G.MyAddon = _G.MyAddon or {}
_G.MyAddon.LPS = LPS or {}
_G.MyAddon.L = setmetatable({}, {
    __index = function(t, key)
        if DEBUG then
            print("|cff1784d1LocationPlus|r: Missing locale:", key)
        end
        return key
    end
})

-- SavedVariables
LPS_DB = LPS_DB or {}

-- Libs
local Tourist = LibStub("LibTourist-3.0")
local L = _G.MyAddon.L

-- Версия аддона
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?.?.?"

----------------------------------------------------------------
-- Holder (главный фрейм)
----------------------------------------------------------------
LPS.holder = CreateFrame("Frame", "LPS_Holder", UIParent, "BackdropTemplate")
LPS.holder:SetSize(420, 22)
LPS.holder:SetFrameStrata("HIGH")
LPS.holder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
LPS.holder:SetBackdropColor(0, 0, 0, 0) -- прозрачный

----------------------------------------------------------------
-- Применение позиции
----------------------------------------------------------------
function LPS:ApplyHolderPosition()
    LPS_DB.position = LPS_DB.position or { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
    local p = LPS_DB.position
    self.holder:ClearAllPoints()
    self.holder:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

----------------------------------------------------------------
-- ADDON_LOADED
----------------------------------------------------------------
LPS.holder:RegisterEvent("ADDON_LOADED")
LPS.holder:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end

    -- Устанавливаем дефолтные позиции и тултипы, если их нет
    LPS_DB.position = LPS_DB.position or { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
    LPS_DB.tooltips = LPS_DB.tooltips or {
        location = { enable = true, zoneLevel = true, battlePets = true },
        time     = { enable = true, raids = false, dungeons = false },
    }
    -- Цвета для фреймов (location, time, coords)
    LPS_DB.colors = LPS_DB.colors or {
        text   = {1, 1, 1, 1},    -- #ffffff
        bg     = {0, 0, 0, 0.6},  -- фон для элементов, не holder
        border = {0.3, 0.3, 0.3, 1},
    }
    -- Размер шрифта
    LPS_DB.fontSize = LPS_DB.fontSize or 12

    -- Применяем позицию holder
    LPS:ApplyHolderPosition()

    print("|cff1784d1" .. addonName .. "|r loaded. Current version: |cff1784d1" .. addonVersion .. "|r")
end)

----------------------------------------------------------------
-- Move Mode (перетаскивание)
----------------------------------------------------------------
local function CreateGuideLines()
    local vLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    vLine:SetSize(4, UIParent:GetHeight())
    vLine:SetPoint("CENTER", UIParent, "CENTER")
    vLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    vLine:SetBackdropColor(1,1,1,1) -- по умолчанию белая
    vLine:SetFrameStrata("HIGH")

    local hLine = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    hLine:SetSize(UIParent:GetWidth(), 4)
    hLine:SetPoint("CENTER", UIParent, "CENTER")
    hLine:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    hLine:SetBackdropColor(1,1,1,1) -- по умолчанию белая
    hLine:SetFrameStrata("HIGH")

    return vLine, hLine
end

function LPS:SetMoveMode(enabled)
    local f = self.holder
    f:SetMovable(enabled)
    f:EnableMouse(enabled)
    f:SetFrameStrata(enabled and "DIALOG" or "HIGH")
    f:SetFrameLevel(enabled and 999 or 1)

    -- создаем линии один раз
    if not f.vLine then
        f.vLine, f.hLine = CreateGuideLines()
    end

    -- отключаем мышь у всех детей holder
    for _, child in ipairs({f:GetChildren()}) do
        child:EnableMouse(not enabled)
        child:EnableMouseWheel(not enabled)
    end

    if enabled then
        f.vLine:Show()
        f.hLine:Show()
        f:RegisterForDrag("LeftButton")
        f:SetBackdropColor(1,0,0,0.25)

        local snapRange = 10

        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()

            -- вычисляем магнитное смещение
            local left = self:GetLeft()
            local bottom = self:GetBottom()
            local width = self:GetWidth()
            local height = self:GetHeight()
            local centerX = left + width/2
            local centerY = bottom + height/2
            local screenCenterX = UIParent:GetWidth()/2
            local screenCenterY = UIParent:GetHeight()/2

            local offsetX, offsetY = 0, 0
            if math.abs(centerX - screenCenterX) <= snapRange then offsetX = screenCenterX - centerX end
            if math.abs(centerY - screenCenterY) <= snapRange then offsetY = screenCenterY - centerY end

            local point, relativeTo, relativePoint, x, y = self:GetPoint()
            local p = LPS_DB.position
            p.point = point
            p.relativePoint = relativePoint
            p.x = x + offsetX
            p.y = y + offsetY

            self:ClearAllPoints()
            self:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
        end)

        f:SetScript("OnUpdate", function(self)
            local left = self:GetLeft()
            local bottom = self:GetBottom()
            local width = self:GetWidth()
            local height = self:GetHeight()
            local centerX = left + width/2
            local centerY = bottom + height/2
            local screenCenterX = UIParent:GetWidth()/2
            local screenCenterY = UIParent:GetHeight()/2

            if math.abs(centerX - screenCenterX) <= snapRange then
                f.vLine:SetBackdropColor(1,0,0,1)
            else
                f.vLine:SetBackdropColor(1,1,1,1)
            end

            if math.abs(centerY - screenCenterY) <= snapRange then
                f.hLine:SetBackdropColor(1,0,0,1)
            else
                f.hLine:SetBackdropColor(1,1,1,1)
            end
        end)
    else
        -- возвращаем holder в обычное состояние
        f:RegisterForDrag()
        f:SetScript("OnUpdate", nil)
        f:SetBackdropColor(0,0,0,0)
        f.vLine:Hide()
        f.hLine:Hide()
        f:SetFrameStrata("HIGH")
        f:SetFrameLevel(1)
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)

        -- восстанавливаем мышь у внутренних фреймов
        for _, child in ipairs({f:GetChildren()}) do
            child:EnableMouse(true)
            child:EnableMouseWheel(true)
        end
    end
end

----------------------------------------------------------------
-- Slash-команды
----------------------------------------------------------------

----------------------------------------------------------------
-- Toggle Move Mode (1 команда)
----------------------------------------------------------------
SLASH_LPSMOVE1 = "/lpsmove"
SlashCmdList.LPSMOVE = function()
    LPS:ToggleMove()
end
----------------------------------------------------------------
-- Reset Holder Position
----------------------------------------------------------------
SLASH_LPSRESET1 = "/lpsreset"
SlashCmdList.LPSRESET = function()
    LPS:ResetPosition()
end



----------------------------------------------------------------
-- Utils
----------------------------------------------------------------
function LPS:print(msg)
    print("|cff1784d1LocationPlus|r: " .. L[msg])
end

function LPS:ResetPosition()
    -- дефолтные координаты
    local defaultPos = { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }

    -- сохраняем в DB
    LPS_DB.position.point = defaultPos.point
    LPS_DB.position.relativePoint = defaultPos.relativePoint
    LPS_DB.position.x = defaultPos.x
    LPS_DB.position.y = defaultPos.y

    -- применяем позицию
    LPS:ApplyHolderPosition()

    LPS:print("The frame position is reset")
end

function LPS:ToggleMove()
    -- проверяем, включен ли режим
    local moving = LPS.holder.isMoving or false
    if moving then
        -- выключаем
        LPS:SetMoveMode(false)
        LPS.holder.isMoving = false
    else
        -- включаем
        LPS:SetMoveMode(true)
        LPS.holder.isMoving = true
    end
end

function LPS:GetContinentID()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    local mapInfo = C_Map.GetMapInfo(mapID)
    return mapInfo and mapInfo.parentMapID or nil
end

function LPS:GetZoneStatus(color)
    local status = ""
    local r, g, b = 1, 1, 0
    local pvpType = C_PvP.GetZonePVPInfo()
    local inInstance = IsInInstance()

    if pvpType == "sanctuary" then
        status = SANCTUARY_TERRITORY; r, g, b = 0.41, 0.8, 0.94
    elseif pvpType == "arena" then
        status = ARENA; r, g, b = 1, 0.1, 0.1
    elseif pvpType == "friendly" then
        status = FRIENDLY; r, g, b = 0.1, 1, 0.1
    elseif pvpType == "hostile" then
        status = HOSTILE; r, g, b = 1, 0.1, 0.1
    elseif pvpType == "contested" then
        status = CONTESTED_TERRITORY; r, g, b = 1, 0.7, 0.1
    elseif pvpType == "combat" or inInstance then
        status = COMBAT; r, g, b = 1, 0.1, 0.1
    else
        status = CONTESTED_TERRITORY
    end

    if color then
        return r, g, b
    end
    return format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status)
end

function LPS:GetFormattedGameTime()
    local is24h = GetCVarBool("timeMgrUseMilitaryTime")
    local useLocal = GetCVarBool("timeMgrUseLocalTime")

    local h, m
    if useLocal then
        h = tonumber(date("%H"))
        m = tonumber(date("%M"))
    else
        h, m = GetGameTime()
    end

    if not is24h then
        local suffix = (h >= 12) and "PM" or "AM"
        h = h % 12
        if h == 0 then h = 12 end
        return string.format("|cFFFFFFFF%d|r:|cFFFFFFFF%02d|r %s", h, m, suffix)
    end

    return string.format("|cFFFFFFFF%02d|r:|cFFFFFFFF%02d|r", h, m)
end
