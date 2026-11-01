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
function LPS:MigratePos(p)
    if type(p) == "table" and p.relativePoint ~= nil then
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
        return
    end

    local p = db.position
    local g = self.frame._posGeometry
    for k in pairs(g) do g[k] = nil end
    for k, v in pairs(p) do g[k] = v end
    if LPS:IsValidPos(g) then
        holder:ClearAllPoints()
        holder:SetPoint(g.point, UIParent, g.relPoint, g.x, g.y)
    else
        LPS.F.Window:Reset(holder)
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
