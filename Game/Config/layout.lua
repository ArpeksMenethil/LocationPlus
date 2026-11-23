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

--- Старый ключ сохранённой позиции relativePoint → новый relPoint.
--- Мигрируем ТОЛЬКО таблицы без нового ключа: если relPoint уже есть,
--- legacy-ключ (его мог подмешать ApplyDefaults из defaults) игнорируем,
--- иначе он бы перезаписал реальную сохранённую позицию.
function LPS:MigratePos(p)
    if type(p) == "table" and p.relativePoint ~= nil and p.relPoint == nil then
        p.relPoint = p.relativePoint
        p.relativePoint = nil
    end
end

LPS._locationAttached = false

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

--- Точка привязки панели локации к UIParent (настройка db.layout.anchorPoint).
--- @return string
function LPS:GetMainAnchor()
    local db = self:GetDB()
    local p = db and db.layout and db.layout.anchorPoint
    if type(p) == "string" and ANCHOR_FX[p] ~= nil then
        return p
    end
    return "TOP"
end

--- Долевые координаты точки на фрейме (x, y от верхнего левого угла).
--- @param point string
--- @return number, number
function LPS:GetAnchorFractions(point)
    return ANCHOR_FX[point] or 0.5, ANCHOR_FY[point] or 0
end

--- @param point string
--- @return boolean
function LPS:IsAnchorPoint(point)
    return type(point) == "string" and ANCHOR_FX[point] ~= nil
end

--- Размер панели локации для пересчёта позиции: реальный размер
--- (если панель видима), иначе оценка (locMinWidth, 25).
--- @return number, number
function LPS:GetLocationSizeEstimate(db)
    local loc = self.frame and self.frame.location
    local shown = (loc and loc.IsShown) and loc:IsShown() or false
    local w = (shown and loc:GetWidth() > 1) and loc:GetWidth()
        or (db and db.layout and tonumber(db.layout.locMinWidth)) or 200
    local h = (shown and loc:GetHeight() > 1) and loc:GetHeight() or 25
    return w, h
end

--- Сдвиг сохранённой позиции панели локации с точки fromPoint на точку toPoint
--- (положение панели на экране не меняется).
--- @return boolean
function LPS:ConvertLocationPos(pos, fromPoint, toPoint, w, h)
    local fx1, fy1 = ANCHOR_FX[fromPoint], ANCHOR_FY[fromPoint]
    local fx2, fy2 = ANCHOR_FX[toPoint], ANCHOR_FY[toPoint]
    if not (fx1 and fx2 and fy1 and fy2) then return false end
    pos.x = pos.x + (fx2 - fx1) * w
    pos.y = pos.y - (fy2 - fy1) * h
    pos.point = toPoint
    pos.relPoint = "TOP"
    return true
end

--- Декодирует сохранённую позицию панели локации (любой версии) в координаты
--- экрана: left — от левого края, top — от НИЖНЕГО края экрана (как у
--- GetLeft/GetTop: начало в левом нижнем углу, y вверх).
--- @return number|nil, number|nil (nil, если запись несущественна/за экраном)
function LPS:DecodeLocationPos(db, pos)
    if type(pos) ~= "table" or type(pos.point) ~= "string" or not ANCHOR_FX[pos.point]
        or type(pos.x) ~= "number" or pos.x ~= pos.x
        or type(pos.y) ~= "number" or pos.y ~= pos.y then
        return nil
    end
    local fx, fy = ANCHOR_FX[pos.point], ANCHOR_FY[pos.point]
    local w, h = LPS:GetLocationSizeEstimate(db)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    local left, top
    if pos._posVer == 3 then
        --- Каноническая кодировка: y — от верхнего края (положительный вверх,
        --- как yOfs в SetPoint). x — от центра (relPoint TOP) либо от левого
        --- края (записи 2.2.1-dev с relPoint TOPLEFT).
        if pos.relPoint == "TOP" then
            left = pos.x + screenW / 2 - fx * w
        else
            left = pos.x - fx * w
        end
        top = screenH + pos.y + fy * h
    elseif pos._posVer == 2 then
        left = pos.x - fx * w
        top = pos.y + fy * h
    elseif pos._posMigrated then
        left = pos.x - w / 2
        top = -pos.y
    elseif pos.relPoint == "TOP" then
        left = pos.x + screenW / 2 - fx * w
        top = screenH + pos.y + fy * h
    elseif pos.relPoint == "TOPLEFT" then
        left = pos.x - fx * w
        top = pos.y + fy * h
    else
        left = pos.x - fx * w
        top = screenH + pos.y + fy * h
    end
    if left < -w or left > screenW or top < -h or top > screenH then
        return nil
    end
    return left, top
end

--- Нормализует сохранённую позицию панели локации в каноническую кодировку
--- (relPoint TOP — как в DEFAULT_POSITION: x — от центра экрана, y — от
--- верхнего края, положительный вверх) и под настроенную точку привязки.
--- Восстанавливает записи 2.2.1-dev (_posVer 3 с relPoint TOPLEFT,
--- _posVer 2), 2.2.0 (_posMigrated без _posVer), 2.1 (relPoint TOP) и
--- legacy TOPLEFT; записи вне экрана сбрасывает в дефолт.
function LPS:NormalizeLocationPos(db, pos)
    local want = LPS:GetMainAnchor()
    if type(pos) ~= "table" then
        return
    end
    if type(pos.point) ~= "string" or not ANCHOR_FX[pos.point] then
        pos.point = "TOP"
    end
    local fx, fy = ANCHOR_FX[pos.point], ANCHOR_FY[pos.point]
    local w, h = LPS:GetLocationSizeEstimate(db)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()

    local left, top = LPS:DecodeLocationPos(db, pos)
    if not left then
        pos.point, pos.relPoint, pos.x, pos.y = "TOP", "TOP", 0, -10
        pos._posMigrated = true
        pos._posVer = 3
        return
    end

    local from = pos.point
    pos.point = from
    pos.relPoint = "TOP"
    pos.x = left + fx * w - screenW / 2
    pos.y = top - screenH - fy * h
    if from ~= want then
        LPS:ConvertLocationPos(pos, from, want, w, h)
    end
    pos._posMigrated = true
    pos._posVer = 3
end

--- Применяет сохранённую позицию панели локации (основной фрейм группы):
--- нормализует запись db.position под настроенную точку привязки и
--- перепривязывает панель к UIParent. Позиция из редактора интерфейса тоже
--- приходит через этот путь (EditModeSetPosition).
function LPS:ApplyLocationPosition()
    local loc = self.frame and self.frame.location
    if not loc then return end
    local db = self:GetDB()
    db.position = db.position or {}
    LPS:MigratePos(db.position)
    LPS:NormalizeLocationPos(db, db.position)

    local g = self.frame._posGeometry
    if type(g) ~= "table" then
        g = {}
        self.frame._posGeometry = g
    end
    for k in pairs(g) do g[k] = nil end
    for k, v in pairs(db.position) do g[k] = v end

    if LPS:IsValidPos(g) then
        loc:ClearAllPoints()
        loc:SetPoint(g.point, UIParent, g.relPoint, g.x, g.y)
    else
        local d = DEFAULT_POSITION
        g.point, g.relPoint, g.x, g.y = d[1], d[2], d[3], d[4]
        loc:ClearAllPoints()
        loc:SetPoint(d[1], UIParent, d[2], d[3], d[4])
    end
end

--- Клиент сам помнит перемещённые фреймы (layout-local.txt, на персонажа)
--- и по завершении загрузки мира возвращает их по имени, перетирая наш
--- SetPoint. Панель держим НЕ user-placed (SetUserPlaced(false) после
--- каждого сохранения позиции), чтобы клиент забыл её место при выходе.
--- Пока устаревшая запись не пропала — если клиент перетёр позицию,
--- восстанавливаем её из DB. Сравниваем РЕАЛЬное положение фрейма на
--- экране (GetLeft/GetTop), а не GetPoint: после внешнего перемещения
--- старый якорь может остаться и замаскировать подмену позиции.
function LPS:RepairLocationLayoutCache()
    local loc = self.frame and self.frame.location
    if not loc then return end
    local db = self:GetDB()
    local p = db and db.position
    if not self:IsValidPos(p) then return end
    local left, top = loc:GetLeft(), loc:GetTop()
    if type(left) ~= "number" or type(top) ~= "number" then return end
    local wantLeft, wantTop = LPS:DecodeLocationPos(db, p)
    if not wantLeft then return end
    if math.abs(left - wantLeft) < 6 and math.abs(top - wantTop) < 6 then
        return
    end
    loc:ClearAllPoints()
    loc:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    if loc.SetUserPlaced then
        loc:SetUserPlaced(false)
    end
end
