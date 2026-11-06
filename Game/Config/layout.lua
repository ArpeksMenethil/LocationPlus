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
                e.point = "TOPLEFT"
                if type(e.relativeTo) == "table" then
                    e.relativeTo = UIParent
                else
                    e.relativeTo = "UIParent"
                end
                e.relPoint = "TOPLEFT"
                e.x = p.x
                e.y = p.y
                -- Кэш раскладки хранит и РАЗМЕР user-placed фреймов (w/h).
                -- Если туда попала неправильная величина (например, до
                -- первого авторазмера в неизвестной зоне), игра восстанавливает
                -- её на каждом логине ПОСЛЕ нашей поправки в PEW — и holder
                -- остаётся огромным. Перезаписываем актуальным размером.
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
    -- Страховка: holder никогда не может быть больше экрана. Иначе при
    -- рассинхроне размеров детей (например, локация не получена и панель
    -- ещё не пересобрана по тексту) холдер растягивает весь UI.
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
