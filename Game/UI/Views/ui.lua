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
        if button == "RightButton" then
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
