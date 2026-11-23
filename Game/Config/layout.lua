local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

local DEFAULT_POSITION = { "TOP", "TOP", 0, -10 }

function LPS:IsValidPos(p)
    return type(p) == "table"
        and type(p.point) == "string"
        and type(p.relPoint) == "string"
        and type(p.x) == "number" and p.x == p.x
        and type(p.y) == "number" and p.y == p.y
end

--- Старый ключ сохранённой позиции relativePoint → новый relPoint (Foundry.Window).
--- Мигрируем ТОЛЬКО таблицы без нового ключа: если relPoint уже есть,
--- legacy-ключ (его мог подмешать ApplyDefaults из defaults) игнорируем,
--- иначе он бы перезаписал реальную сохранённую позицию.
function LPS:MigratePos(p)
    if type(p) == "table" and p.relativePoint ~= nil and p.relPoint == nil then
        p.relPoint = p.relativePoint
        p.relativePoint = nil
    end
end

LPS._holderAttached = false

local ANCHOR_FX = {
    TOPLEFT = 0, TOP = 0.5, TOPRIGHT = 1,
    LEFT = 0, CENTER = 0.5, RIGHT = 1,
    BOTTOMLEFT = 0, BOTTOM = 0.5, BOTTOMRIGHT = 1,
}
local ANCHOR_FY = {
    TOPLEFT = 0, TOP = 0, TOPRIGHT = 0,
    LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5,
    BOTTOMLEFT = 1, BOTTOM = 1, BOTTOMRIGHT = 1,
}

--- Точка привязки holder к UIParent (настройка db.layout.anchorPoint).
--- @return string
function LPS:GetHolderAnchor()
    local db = self:GetDB()
    local p = db and db.layout and db.layout.anchorPoint
    if type(p) == "string" and ANCHOR_FX[p] ~= nil then
        return p
    end
    return "TOP"
end

--- Размер holder для пересчёта позиции: последний, выставленный UpdateFrameSize
--- (создательный 400x25 на момент логина не используется), иначе оценка
--- (location + отступы UpdateFrameSize: 18 = 4*2 + 10, 6).
--- @return number, number
function LPS:GetHolderSizeEstimate(db)
    local w, h = self._lastPosW, self._lastPosH
    local loc = self.frame and self.frame.location
    if not w or w <= 1 then
        w = ((loc and loc.IsShown and loc:IsShown() and loc:GetWidth() > 1 and loc:GetWidth())
            or (db and db.layout and tonumber(db.layout.locMinWidth)) or 200) + 18
    end
    if not h or h <= 1 then
        h = ((loc and loc.IsShown and loc:IsShown() and loc:GetHeight() > 1 and loc:GetHeight()) or 25) + 6
    end
    return w, h
end

--- Сдвиг сохранённой позиции с точки fromPoint на точку toPoint
--- (положение панели на экране не меняется).
--- @return boolean
function LPS:ConvertHolderPos(pos, fromPoint, toPoint, w, h)
    local fx1, fy1 = ANCHOR_FX[fromPoint], ANCHOR_FY[fromPoint]
    local fx2, fy2 = ANCHOR_FX[toPoint], ANCHOR_FY[toPoint]
    if not (fx1 and fx2 and fy1 and fy2) then return false end
    pos.x = pos.x - fx1 * w + fx2 * w
    pos.y = pos.y - fy1 * h + fy2 * h
    pos.point = toPoint
    pos.relPoint = "TOPLEFT"
    return true
end

--- Нормализует сохранённую позицию holder под настроенную точку привязки:
--- legacy TOPLEFT (до 2.2.1) мигрируется один раз (флаг _posMigrated),
--- точка, не совпадающая с настройкой (смена/импорт профиля), пересчитывается.
function LPS:NormalizeHolderPos(db, pos)
    local want = LPS:GetHolderAnchor()
    if type(pos.point) ~= "string" or type(pos.x) ~= "number" or type(pos.y) ~= "number" then
        return
    end
    local legacy = (not pos._posMigrated) and (pos.point == "TOPLEFT")
    if legacy or pos.point ~= want then
        local w, h = LPS:GetHolderSizeEstimate(db)
        LPS:ConvertHolderPos(pos, legacy and "TOPLEFT" or pos.point, want, w, h)
        pos._posMigrated = true
    end
end

function LPS:ApplyHolderPosition()
    local holder = self.frame and self.frame.holder
    if not holder then return end
    local db = self:GetDB()
    db.position = db.position or {}
    LPS:MigratePos(db.position)

    local pos = db.position
    LPS:NormalizeHolderPos(db, pos)

    if not LPS._holderAttached then
        local geometry = {}
        for k, v in pairs(db.position) do
            geometry[k] = v
        end
        self.frame._posGeometry = geometry
        LPS._holderAttached = true
        LPS.F.Window:Attach(holder, {
            handle = holder,
            geometry = geometry,
            default = DEFAULT_POSITION,
        })
        if not holder.isMoving then
            holder:EnableMouse(false)
        end
        holder:SetUserPlaced(true)
        return
    end

    local p = db.position
    local g = self.frame._posGeometry
    for k in pairs(g) do g[k] = nil end
    for k, v in pairs(p) do g[k] = v end
    if LPS:IsValidPos(g) then
        if not holder.isMoving then
            holder:ClearAllPoints()
            holder:SetPoint(g.point, UIParent, g.relPoint, g.x, g.y)
            holder:SetUserPlaced(true)
        end
    else
        LPS.F.Window:Reset(holder)
    end
end

--- Игра кэширует позиции user-placed фреймов в собственном SavedVariables
--- (кэш раскладки UIParent) и в районе логина применяет их, перетирая наш
--- SetPoint старой записью «правый край». Находим таблицу кэша, содержащую
--- LPS_Holder, и перезаписываем её запись канонической точкой из DB.
--- Идемпотентно и тихо; вызывается на PEW и на таймерах после загрузки.
function LPS:RepairHolderLayoutCache()
    local holder = self.frame and self.frame.holder
    if not holder then return end
    local p = self:GetDB() and self:GetDB().position
    if type(p) ~= "table" or not self:IsValidPos(p) then return end
    for gName in pairs(_G) do
        local g = _G[gName]
        if type(g) == "table" and type(g.db) == "table" and type(g.db["LPS_Holder"]) == "table" then
            local e = g.db["LPS_Holder"]
            if type(e.point) == "string" and type(e.x) == "number" and type(e.y) == "number" then
                e.point = p.point
                if type(e.relativeTo) == "table" then
                    e.relativeTo = UIParent
                else
                    e.relativeTo = "UIParent"
                end
                e.relPoint = p.relPoint
                e.x = p.x
                e.y = p.y
                e.w = holder:GetWidth()
                e.h = holder:GetHeight()
            end
        end
    end
end

LPS._lastPosW, LPS._lastPosH = nil, nil
function LPS:UpdateFrameSize()
    if not (LPS.frame and LPS.frame.holder) then return end
    local padding = 4
    local function w(f)
        return (f and f:IsShown()) and f:GetWidth() or 0
    end
    local function h(f)
        return (f and f:IsShown()) and f:GetHeight() or 0
    end

    local width = w(LPS.frame.location)
    local height = h(LPS.frame.location)
    for key, f in pairs(LPS.frame) do
        if key ~= "holder" and key ~= "location" and key ~= "minimapButton"
            and type(f) == "table" and f.IsShown and f.GetWidth and f:GetParent() == LPS.frame.holder
            and f:IsShown() then
                width = width + f:GetWidth()
                height = math.max(height, f:GetHeight())
            end
    end
    width = width + padding * 2 + 10
    height = height + 6
    local uiW, uiH = UIParent:GetWidth(), UIParent:GetHeight()
    if uiW > 100 then width = math.min(width, uiW - 10) end
    if uiH > 100 then height = math.min(height, uiH - 10) end
    if width ~= LPS._lastPosW or height ~= LPS._lastPosH then
        LPS._lastPosW, LPS._lastPosH = width, height
        LPS.frame.holder:SetSize(width, height)
    end
end

LPS._sizeUpdatePending = false
function LPS:ScheduleFrameSizeUpdate()
    if LPS._sizeUpdatePending then return end
    LPS._sizeUpdatePending = true
    C_Timer.After(0.05, function()
        LPS._sizeUpdatePending = false
        LPS:UpdateFrameSize()
    end)
end
