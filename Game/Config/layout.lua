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

function LPS:ApplyHolderPosition()
    local holder = self.frame and self.frame.holder
    if not holder then return end
    local db = self:GetDB()
    db.position = db.position or {}
    LPS:MigratePos(db.position)

    if not LPS._holderAttached then
        local geometry = {}
        for k, v in pairs(db.position) do
            geometry[k] = v
        end
        -- DEBUG: какие координаты применяются при загрузке
        LPS:Print(string.format(
            "[LPS DEBUG] ApplyHolderPosition: attach holder, geometry from DB: point=%s relPoint=%s x=%s y=%s",
            tostring(geometry.point), tostring(geometry.relPoint),
            tostring(geometry.x), tostring(geometry.y)), false)
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
        -- Mark user-placed so the game re-saves our canonical point into
        -- its layout cache (UIParent) on logout, overwriting the stale
        -- right-edge entry that makes the frame "fly away" on /reload.
        holder:SetUserPlaced(true)
        local par = holder:GetParent()
        LPS:Print(string.format(
            "[LPS DEBUG] ApplyHolderPosition: holder after attach: left=%s top=%s right=%s bottom=%s, numPoints=%s, parent=%s (parent left=%s top=%s scale=%s)",
            tostring(holder:GetLeft()), tostring(holder:GetTop()),
            tostring(holder:GetRight()), tostring(holder:GetBottom()),
            tostring(holder:GetNumPoints()),
            par and (par:GetName() or "(unnamed)") or "nil",
            par and tostring(par:GetLeft()) or "nil",
            par and tostring(par:GetTop()) or "nil",
            par and tostring(par:GetScale()) or "nil"), false)
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
            -- Same as on attach: let the game re-save our canonical point
            -- into its layout cache so the stale entry gets overwritten.
            holder:SetUserPlaced(true)
        end
        -- DEBUG: какие координаты применяются при повторном вызове
        LPS:Print(string.format(
            "[LPS DEBUG] ApplyHolderPosition: SetPoint(%s, UIParent, %s, %s, %s) applied: left=%s top=%s right=%s bottom=%s, numPoints=%s",
            tostring(g.point), tostring(g.relPoint), tostring(g.x), tostring(g.y),
            tostring(holder:GetLeft()), tostring(holder:GetTop()),
            tostring(holder:GetRight()), tostring(holder:GetBottom()),
            tostring(holder:GetNumPoints())), false)
    else
        -- DEBUG: позиция в DB невалидна — фрейм сбрасывается на дефолт
        LPS:Print(string.format(
            "[LPS DEBUG] ApplyHolderPosition: invalid pos (point=%s relPoint=%s x=%s y=%s), Window:Reset called",
            tostring(g and g.point), tostring(g and g.relPoint),
            tostring(g and g.x), tostring(g and g.y)), false)
        LPS.F.Window:Reset(holder)
    end
end

--- [LPS DEBUG] Состояние точек holder'а + поиск/лечение кэша раскладки игры (UIParent).
--- Игра кэширует позиции user-placed фреймов в собственном SavedVariables и
--- в районе логина применяет их, перетирая наш SetPoint (старая запись
--- «правый край»). Здесь:
---  1) печатаем РЕАЛЬНЫЙ GetPoint(1) holder'а — видно, подменила ли игра точку;
---  2) ищем в _G таблицу с db["LPS_Holder"] и печатаем её содержимое;
---  3) если запись выглядит как точка — перезаписываем канонической из DB.
function LPS:DebugHolderState(tag)
    local holder = self.frame and self.frame.holder
    if not holder then return end
    local point, relTo, relP, px, py = holder:GetPoint(1)
    local relName = "(nil)"
    if relTo and relTo.GetName then
        relName = relTo:GetName() or "(unnamed)"
    end
    self:Print(string.format(
        "[LPS DEBUG] %s GetPoint(1): point=%s relativeTo=%s relPoint=%s x=%s y=%s | left=%s top=%s",
        tostring(tag), tostring(point), tostring(relName),
        tostring(relP), tostring(px), tostring(py),
        tostring(holder:GetLeft()), tostring(holder:GetTop())), false)

    local p = self:GetDB() and self:GetDB().position
    for gName in pairs(_G) do
        local g = _G[gName]
        if type(g) == "table" and type(g.db) == "table" and type(g.db["LPS_Holder"]) == "table" then
            local e = g.db["LPS_Holder"]
            local relToStr
            if type(e.relativeTo) == "table" then
                if e.relativeTo.GetName then
                    relToStr = e.relativeTo:GetName() or "(frame)"
                else
                    relToStr = "(frame)"
                end
            else
                relToStr = tostring(e.relativeTo)
            end
            self:Print(string.format(
                "[LPS DEBUG] %s game-cache %s: point=%s relativeTo=%s relPoint=%s x=%s y=%s",
                tostring(tag), tostring(gName),
                tostring(e.point), relToStr, tostring(e.relPoint),
                tostring(e.x), tostring(e.y)), false)
            if type(e.point) == "string" and type(e.x) == "number"
                and type(e.y) == "number" and type(p) == "table" and self:IsValidPos(p) then
                e.point = "TOPLEFT"
                if type(e.relativeTo) == "table" then
                    e.relativeTo = UIParent
                else
                    e.relativeTo = "UIParent"
                end
                e.relPoint = "TOPLEFT"
                e.x = p.x
                e.y = p.y
                self:Print(string.format(
                    "[LPS DEBUG] %s game-cache %s REPAIRED with canonical point (TOPLEFT, TOPLEFT, %s, %s)",
                    tostring(tag), tostring(gName), tostring(p.x), tostring(p.y)), false)
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
