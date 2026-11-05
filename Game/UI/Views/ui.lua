local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

function LPS:ClampAngle(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

function LPS:IsMinimapSquare()
    local db = LPS:GetDB()
    local mm = db and db.show and db.show.minimap
    return mm and mm.shape == "square"
end

function LPS:PositionMinimapButton(btn)
    local db = LPS:GetDB()
    if not db or not db.show or not db.show.minimap then return end
    local angle = LPS:ClampAngle(tonumber(db.show.minimap.angle) or 220)
    db.show.minimap.angle = angle

    local pad = 8
    local rad = math.rad(angle)
    local x, y
    if LPS:IsMinimapSquare() then
        local dx, dy = math.cos(rad), math.sin(rad)
        local hw = (Minimap:GetWidth() / 2) + pad
        local hh = (Minimap:GetHeight() / 2) + pad
        local sx = (dx ~= 0) and (hw / math.abs(dx)) or math.huge
        local sy = (dy ~= 0) and (hh / math.abs(dy)) or math.huge
        local s = math.min(sx, sy)
        x = dx * s
        y = dy * s
    else
        local radius = (Minimap:GetWidth() / 2) + pad
        x = math.cos(rad) * radius
        y = math.sin(rad) * radius
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function LPS:FillMinimapTooltip(tt)
    local d = LPS:GetDB()
    local vis = d and d.tooltips and d.tooltips.visibility
    if not vis or not vis.enable then return end
    if vis.combat and InCombatLockdown() then return end
    local r, g, b = LPS:GetColor("text")
    local rb, gb, bb = LPS:GetColor("tooltipSetting")
    tt:AddDoubleLine(LPS.addon.title, format("v%s", LPS.addon.version), 1, 0.82, 0, 1, 0.82, 0)
    tt:AddLine(" ")
    tt:AddLine(LPS:GetAddonNotes(), r, g, b)
    tt:AddLine(" ")
    tt:AddDoubleLine(L.LMB, L.TOGGLE_PANEL_MOVE_MODE, rb, gb, bb, rb, gb, bb)
    tt:AddDoubleLine(L.DRAG, L.REPOSITION_MINIMAP_BUTTON, rb, gb, bb, rb, gb, bb)
    tt:AddDoubleLine(L.RMB, L.OPEN_SETTINGS, rb, gb, bb, rb, gb, bb)
end

function LPS:UpdateMinimapButton()
    local btn = LPS.frame and LPS.frame.minimapButton
    if not btn then return end
    local db = LPS:GetDB()
    if not db or not db.show or not db.show.minimap or db.show.minimap.hide then
        btn:Hide()
        return
    end
    btn:Show()
    LPS:PositionMinimapButton(btn)
end

function LPS:CreateMinimapButton()
    if not Minimap then return end
    if not LPS.frame then LPS.frame = {} end
    if LPS.frame.minimapButton then
        LPS:UpdateMinimapButton()
        return
    end

    local btn = CreateFrame("Button", "LPS_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:GetHighlightTexture():SetBlendMode("ADD")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(LPS.icons.PathLogo)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            LPS:ToggleMoveMode()
        elseif button == "RightButton" then
            LPS:ToggleOptions()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        LPS:FillMinimapTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isDragging = true
    end)
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isDragging = false
    end)
    btn:SetScript("OnUpdate", function(self)
        if not self.isDragging then return end
        local db = LPS:GetDB()
        if not db or not db.show or not db.show.minimap then return end

        local sx, sy = GetCursorPosition()
        local parent = Minimap:GetParent() or UIParent
        local pScale = parent:GetEffectiveScale()
        if not pScale or pScale == 0 then return end
        local cx, cy = Minimap:GetCenter()
        local dx = sx / pScale - cx
        local dy = sy / pScale - cy
        if dx == 0 and dy == 0 then return end
        local angle = LPS:ClampAngle(math.deg(math.atan2(dy, dx)))
        db.show.minimap.angle = angle
        LPS:PositionMinimapButton(self)
    end)

    LPS.frame.minimapButton = btn
    LPS:UpdateMinimapButton()
end

if Minimap and not Minimap._lpsPosHooked then
    Minimap._lpsPosHooked = true

    local _origSetScale = Minimap.SetScale
    Minimap.SetScale = function(self, scale)
        _origSetScale(self, scale)
        if LPS.UpdateMinimapButton then LPS:UpdateMinimapButton() end
    end

    local _origSetSize = Minimap.SetSize
    Minimap.SetSize = function(self, width, height)
        _origSetSize(self, width, height)
        if LPS.UpdateMinimapButton then LPS:UpdateMinimapButton() end
    end
end

function LPS:SetMoveMode(enabled)
    local f = LPS.frame.holder
    f:SetMovable(enabled)
    f:EnableMouse(enabled)
    f:SetFrameStrata(enabled and "DIALOG" or "HIGH")
    f:SetFrameLevel(enabled and 999 or 1)

    if not f.grid then
        f.grid = LPS:CreateGuideLines()
    end

    for _, child in ipairs({f:GetChildren()}) do
        child:EnableMouse(not enabled)
        child:EnableMouseWheel(not enabled)
    end

    if enabled then
        for _, line in ipairs(f.grid.vLines or {}) do
            line:Show()
        end
        for _, line in ipairs(f.grid.hLines or {}) do
            line:Show()
        end
        f:RegisterForDrag("LeftButton")

        local snapRange = 10
        f._lpsDragging = false

        f:SetScript("OnDragStart", function(self)
            self._lpsDragging = true
            self:StartMoving()
        end)

        local function saveHolderPosition(self)
            -- Принудительно останавливаем перетаскивание (StopMovingOrSizing), иначе при
            -- отпускании кнопки вне области фрейма координаты GetPoint() некорректны
            -- и позиция не сохранялась.
            if f._lpsDragging then
                self:StopMovingOrSizing()
                f._lpsDragging = false
            end
            local point, _, relPoint, x, y = self:GetPoint()
            if not point or type(x) ~= "number" or type(y) ~= "number" then
                return -- незавершённое перетаскивание: не сохраняем некорректные значения
            end

            local left = self:GetLeft()
            local bottom = self:GetBottom()
            local width = self:GetWidth()
            local height = self:GetHeight()
            local centerX = left + width/2
            local centerY = bottom + height/2
            local screenW = UIParent:GetWidth()
            local screenH = UIParent:GetHeight()
            local stepX = screenW / 10
            local stepY = screenH / 10

            local offsetX, offsetY = 0, 0
            if stepX > 0 then
                local i = math.floor((centerX / stepX) + 0.5)
                if i < 0 then i = 0 elseif i > 10 then i = 10 end
                local targetX = stepX * i
                if math.abs(centerX - targetX) <= snapRange then
                    offsetX = targetX - centerX
                end
            end
            if stepY > 0 then
                local j = math.floor((centerY / stepY) + 0.5)
                if j < 0 then j = 0 elseif j > 10 then j = 10 end
                local targetY = stepY * j
                if math.abs(centerY - targetY) <= snapRange then
                    offsetY = targetY - centerY
                end
            end

            local db = LPS:GetDB()
            db.position = db.position or {}
            local p = db.position
            p.point = point
            p.relPoint = relPoint
            p.x = x + offsetX
            p.y = y + offsetY

            self:ClearAllPoints()
            self:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)

            local g = LPS.frame and LPS.frame._posGeometry
            if g then
                for k in pairs(g) do g[k] = nil end
                g.point, g.relPoint, g.x, g.y = point, relPoint, p.x, p.y
            end
        end

        f:SetScript("OnDragStop", saveHolderPosition)
        f:SetScript("OnMouseUp", saveHolderPosition)

        f:SetScript("OnUpdate", function(self)
            local grid = f.grid
            if not grid then return end
            local left = self:GetLeft()
            local bottom = self:GetBottom()
            local width = self:GetWidth()
            local height = self:GetHeight()
            local centerX = left + width/2
            local centerY = bottom + height/2
            local screenW = UIParent:GetWidth()
            local screenH = UIParent:GetHeight()
            local stepX = screenW / 10
            local stepY = screenH / 10

            local nearV, nearH
            if stepX > 0 then
                nearV = math.floor((centerX / stepX) + 0.5)
                if nearV < 1 then nearV = 1 elseif nearV > 9 then nearV = 9 end
            end
            if stepY > 0 then
                nearH = math.floor((centerY / stepY) + 0.5)
                if nearH < 1 then nearH = 1 elseif nearH > 9 then nearH = 9 end
            end

            local activeV
            if stepX > 0 and nearV and math.abs(centerX - (stepX * nearV)) <= snapRange then
                activeV = nearV
            end
            local activeH
            if stepY > 0 and nearH and math.abs(centerY - (stepY * nearH)) <= snapRange then
                activeH = nearH
            end

            if grid._lastActiveV ~= activeV then
                if grid._lastActiveV then
                    local old = grid.vLines and grid.vLines[grid._lastActiveV]
                    if old then old:SetBackdropColor(1, 1, 1, 0.35) end
                end
                if activeV then
                    local line = grid.vLines and grid.vLines[activeV]
                    if line then line:SetBackdropColor(1, 0, 0, 0.8) end
                end
                grid._lastActiveV = activeV
            end
            if grid._lastActiveH ~= activeH then
                if grid._lastActiveH then
                    local old = grid.hLines and grid.hLines[grid._lastActiveH]
                    if old then old:SetBackdropColor(1, 1, 1, 0.35) end
                end
                if activeH then
                    local line = grid.hLines and grid.hLines[activeH]
                    if line then line:SetBackdropColor(1, 0, 0, 0.8) end
                end
                grid._lastActiveH = activeH
            end
        end)
    else
        f:RegisterForDrag()
        f._lpsDragging = false
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnDragStop", nil)
        f:SetScript("OnUpdate", nil)
        for _, line in ipairs(f.grid and f.grid.vLines or {}) do
            line:Hide()
        end
        for _, line in ipairs(f.grid and f.grid.hLines or {}) do
            line:Hide()
        end
        local db = LPS:GetDB()
        local layout = db and db.layout
        f:SetFrameStrata((layout and layout.frameStrata) or "HIGH")
        f:SetFrameLevel(tonumber(layout and layout.frameLevel) or 1)
        f:SetScript("OnMouseUp", nil)
        f:EnableMouse(false)

        for _, child in ipairs({f:GetChildren()}) do
            child:EnableMouse(true)
            child:EnableMouseWheel(true)
        end
    end
end
