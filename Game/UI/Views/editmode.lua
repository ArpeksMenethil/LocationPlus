local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local REG_KEY = "LPSLocation"
local DEFAULT_POINT, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y = "TOP", "TOP", 0, -10

--- Библиотека, интегрирующая фреймы в редактор интерфейса игры.
--- @return table?
function LPS:EditModeGetLibrary()
    if LibStub then
        return LibStub("LibLayoutSettings-1.0", true)
    end
    return nil
end

--- Пока открыт редактор интерфейса (его изменения ждут Save).
--- @return boolean
function LPS:EditModeIsEditing()
    local LLS = LPS:EditModeGetLibrary()
    return LLS ~= nil and LLS:IsEditing() or false
end

--- Позиции панели по раскладкам редактора интерфейса (на аккаунт).
--- @return table
function LPS:EditModeGetStorage()
    local a = LPS:GetAccountDB()
    a.editModeLayouts = a.editModeLayouts or {}
    return a.editModeLayouts
end

--- Позиция панели локации, которую показывает фрейм.
--- @return string, string, number, number
function LPS:EditModeGetPosition()
    local g = LPS.frame and LPS.frame._posGeometry
    if g and LPS:IsValidPos(g) then
        return g.point, g.relPoint, g.x, g.y
    end
    return DEFAULT_POINT, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y
end

function LPS:EditModeSetPosition(point, relPoint, x, y)
    local db = LPS:GetDB()
    db.position = db.position or {}
    db.position.point = point
    db.position.relPoint = relPoint
    db.position.x = x
    db.position.y = y
    db.position._posMigrated = true
    db.position._posVer = 3
    LPS:ApplyLocationPosition()
end

--- Вернуть панель к её собственной (не раскладочной) позиции.
function LPS:EditModeRestoreOwnSettings()
    LPS:ApplyLocationPosition()
end

--- Перенести текущую позицию панели в раскладку, которой она принадлежит,
--- чтобы изменение из настроек не было отыграно старой раскладкой.
function LPS:EditModeCaptureLayout()
    local LLS = LPS:EditModeGetLibrary()
    if LLS then
        LLS:Capture(REG_KEY)
    end
end

--- Панель локации как участник редактора интерфейса: перетаскивание по
--- подсветке, стрелки, Reset Position и сохранение позиции в раскладку.
function LPS:EditModeRegisterFrame()
    local LLS = LPS:EditModeGetLibrary()
    if not LLS then return end
    LLS:RegisterFrame(REG_KEY, {
        GetFrame = function()
            return LPS.frame and LPS.frame.location
        end,
        displayName = "Location Plus",
        storage = LPS:EditModeGetStorage(),
        showSelectionLabel = false,
        selectionBehind = "MEDIUM",
        selectionInsets = { left = 2, right = 2, top = 2, bottom = 2 },
        GetPosition = function()
            return LPS:EditModeGetPosition()
        end,
        SetPosition = function(point, relPoint, x, y)
            LPS:EditModeSetPosition(point, relPoint, x, y)
        end,
        EditPosition = function(point, relPoint, x, y)
            LPS:EditModeSetPosition(point, relPoint, x, y)
        end,
        GetDefaultPosition = function()
            return DEFAULT_POINT, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y
        end,
        RestoreOwnSettings = function()
            LPS:EditModeRestoreOwnSettings()
        end,
        OnChanged = function()
            if LPS.ScheduleRefresh then
                LPS:ScheduleRefresh()
            end
        end,
    })
end
