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

--- Центр панели локации: опорная точка направляющей сетки (средняя линия
--- привязана к этой точке) и округления позиции при перетаскивании.
function LPS:GetSnapPoint()
    local loc = self.frame and self.frame.location
    if loc and loc.IsShown and loc:IsShown() then
        local l, t = loc:GetLeft(), loc:GetTop()
        if type(l) == "number" and type(t) == "number" then
            return l + loc:GetWidth()/2, t + loc:GetHeight()/2
        end
    end
    return nil
end

--- Режим перемещения группы: панель локации — основной перетаскиваемый
--- фрейм, боковые панели, прицепленные к ней, двигаются вместе с ней.
function LPS:SetMoveMode(enabled)
    local f = LPS.frame and LPS.frame.location
    if not f then return end
    if enabled then
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(999)
    else
        local db = LPS:GetDB()
        local layout = db and db.layout
        f:SetFrameStrata((layout and layout.frameStrata) or "HIGH")
        f:SetFrameLevel(tonumber(layout and layout.frameLevel) or 1)
    end

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

        --- Во время перемещения клики и тултип панели выключены,
        --- чтобы не перехватывали drag группы.
        f._lpsOnEnter = f:GetScript("OnEnter")
        f._lpsOnLeave = f:GetScript("OnLeave")
        f:SetScript("OnEnter", nil)
        f:SetScript("OnLeave", nil)
        f:RegisterForClicks()
        f:RegisterForDrag("LeftButton")

        f._lpsDragging = false
        f._lpsDragCX = nil
        f._lpsDragCY = nil

        f:SetScript("OnDragStart", function(self)
            self._lpsDragging = true
            local cx, cy = LPS:GetSnapPoint()
            if cx then
                self._lpsDragCX, self._lpsDragCY = cx, cy
            end
            local l, t = self:GetLeft(), self:GetTop()
            local pp, _, rp, px, py = self:GetPoint()
            local dbp = LPS:GetDB() and LPS:GetDB().position
            print(string.format(
                "[LPS] drag start: фактическая (GetLeft/GetTop, от левого НИЖНЕГО угла): %.0f / %.0f (W %.0f, H %.0f, scale %.2f); " ..
                "якорь GetPoint(): %s %s %.0f %.0f; сохранено (DB): %s %s %.0f %.0f",
                l, t, self:GetWidth(), self:GetHeight(), self:GetEffectiveScale(),
                tostring(pp), tostring(rp), px or 0, py or 0,
                tostring(dbp and dbp.point), tostring(dbp and dbp.relPoint),
                (dbp and dbp.x) or 0, (dbp and dbp.y) or 0))
            self:StartMoving()
        end)

        local function savePosition(self)
            local wasDragging = f._lpsDragging
            if wasDragging then
                self:StopMovingOrSizing()
                f._lpsDragging = false
            end
            if not wasDragging then return end

            --- Реальная позиция после драга. GetPoint здесь не годится:
            --- он может вернуть СТАРЫЙ якорь (позицию до начала драга), и панель
            --- «выскакивает» на прежнее место. GetLeft/GetTop всегда дают
            --- текущее положение фрейма на экране (от левого НИЖНЕГО угла:
            --- left — от левого края, top — от нижнего края, y вверх).
            local left = self:GetLeft()
            local top = self:GetTop()
            if type(left) ~= "number" or type(top) ~= "number" or left ~= left or top ~= top then
                f._lpsDragCX = nil
                f._lpsDragCY = nil
                return
            end

            local screenW = UIParent:GetWidth()
            local screenH = UIParent:GetHeight()
            local w = self:GetWidth()
            local h = self:GetHeight()

            --- Округляем центр панели по сетке (сетка привязана к центру
            --- панели, поэтому округляем сдвиг от начала драга к шагу ячейки).
            if f._lpsDragCX then
                local step = f.grid and f.grid.step or 25
                local cx = left + w / 2
                local cy = top + h / 2
                left = f._lpsDragCX + math.floor((cx - f._lpsDragCX) / step + 0.5) * step - w / 2
                top = f._lpsDragCY + math.floor((cy - f._lpsDragCY) / step + 0.5) * step - h / 2
            end
            f._lpsDragCX = nil
            f._lpsDragCY = nil

            --- Держим панель хотя бы частично на экране (отступ 20 пикселей),
            --- чтобы группа не «исчезала» за краем при перетаскивании.
            local margin = 20
            if left < margin - w then left = margin - w end
            if left > screenW - margin then left = screenW - margin end
            if top < margin then top = margin end
            if top > screenH - margin + h then top = screenH - margin + h end

            local db = LPS:GetDB()
            db.position = db.position or {}
            local p = db.position
            --- Каноническая кодировка (relPoint TOP, как в DEFAULT_POSITION):
            --- x — смещение точки привязки от ЦЕНТРА экрана по горизонтали;
            --- y — смещение от верхнего края (как yOfs в SetPoint: положительный
            --- вверх, т.е. точка ниже верхнего края даёт отрицательное значение).
            local anchor = LPS:GetMainAnchor()
            local fx, fy = LPS:GetAnchorFractions(anchor)
            p.point = anchor
            p.relPoint = "TOP"
            p.x = left + fx * w - screenW / 2
            p.y = top - screenH - fy * h
            p._posMigrated = true
            p._posVer = 3

            self:ClearAllPoints()
            self:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
            if self.SetUserPlaced then
                self:SetUserPlaced(false)
            end

            local g = LPS.frame and LPS.frame._posGeometry
            if g then
                for k in pairs(g) do g[k] = nil end
                g.point, g.relPoint, g.x, g.y = p.point, p.relPoint, p.x, p.y
            end

            if wasDragging then
                local l2, t2 = self:GetLeft(), self:GetTop()
                local pp, _, rp, px, py = self:GetPoint()
                print(string.format(
                    "[LPS] drag end: фактическая (GetLeft/GetTop, от левого НИЖНЕГО угла): %.0f / %.0f; " ..
                    "якорь GetPoint(): %s %s %.0f %.0f; сохранено (DB): %s %s %.0f %.0f",
                    l2, t2,
                    tostring(pp), tostring(rp), px or 0, py or 0,
                    p.point, p.relPoint, p.x, p.y))
            end
        end

        f:SetScript("OnDragStop", savePosition)
        f:SetScript("OnMouseUp", savePosition)

        --- Сетка всегда привязана к центру панели локации: средняя
        --- (красная) линия проходит через центр панели.
        f:SetScript("OnUpdate", function(self)
            local grid = f.grid
            if not grid then return end
            local cx, cy = LPS:GetSnapPoint()
            if not cx then
                cx = self:GetLeft() + self:GetWidth() / 2
                cy = self:GetTop() + self:GetHeight() / 2
            end
            local screenW = UIParent:GetWidth()
            local screenH = UIParent:GetHeight()
            local step = grid.step
            for i, line in ipairs(grid.vLines) do
                line:SetPoint("CENTER", UIParent, "CENTER", cx - screenW / 2 + (i - grid.midV) * step, 0)
                line:Show()
            end
            for i, line in ipairs(grid.hLines) do
                line:SetPoint("CENTER", UIParent, "CENTER", 0, screenH / 2 - cy - (i - grid.midH) * step)
                line:Show()
            end
        end)
    else
        f:RegisterForDrag()
        f._lpsDragging = false
        f._lpsDragCX = nil
        f._lpsDragCY = nil
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
        f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        if f._lpsOnEnter then
            f:SetScript("OnEnter", f._lpsOnEnter)
            f._lpsOnEnter = nil
        end
        if f._lpsOnLeave then
            f:SetScript("OnLeave", f._lpsOnLeave)
            f._lpsOnLeave = nil
        end

        for _, child in ipairs({f:GetChildren()}) do
            child:EnableMouse(true)
            child:EnableMouseWheel(true)
        end
    end
end
