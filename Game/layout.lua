local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

function LPS:ApplyHolderPosition()
    local db = LPS:GetDB()
    db.position = db.position or { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
    local p = db.position
    self.frame.holder:ClearAllPoints()
    self.frame.holder:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

local lastW, lastH
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
    if width ~= lastW or height ~= lastH then
        lastW, lastH = width, height
        LPS.frame.holder:SetSize(width, height)
    end
end

local sizeUpdatePending = false
function LPS:ScheduleFrameSizeUpdate()
    if sizeUpdatePending then return end
    sizeUpdatePending = true
    C_Timer.After(0.05, function()
        sizeUpdatePending = false
        LPS:UpdateFrameSize()
    end)
end
