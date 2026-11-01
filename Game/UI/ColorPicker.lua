local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
--- Современный пикер цвета — перенос набора функций ColorPickerModern из
--- ElvUI (сам пикер ElvUI дорабатывает нативный ColorPickerFrame через
--- свои внутренние модули, поэтому здесь тот же функционал, но
--- самодостаточным фреймом под тему LocationPlus):
--- * полоса тона (клик + перетаскивание) с маркером — чистая радуга,
---   без белых/чёрных слоёв внутри;
--- * отдельные ползунки: насыщенность (S), яркость (V),
---   прозрачность (A — только при hasAlpha);
--- * поля R/G/B (0-255) и A (0-100) — живой ввод;
--- * Hex-поле (#AARRGGBB / #RRGGBB) — живой ввод: цвет обновляется
---   по мере набора, текст не перезаписывается (нормализуется при потере
---   фокуса / по Enter);
--- * превью в две части: исходный (слева) и текущий (справа) цвет
---   на «шашечках»;
--- * кнопка «цвет класса», «копировать»/«вставить» (буфер + свотч);
--- * «сбросить» (defaultColor, если передан — иначе исходный цвет);
--- * OK / Cancel, ESC = отмена.
local ColorPicker = {}
LPS.UI = LPS.UI or {}
LPS.UI.ColorPicker = ColorPicker
local Widgets = LPS.UI.Widgets
local Theme = LPS.UI.Theme
local L = LPS.L

local function RGBToHSV(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    if max == 0 then return 0, 0, 0 end
    local d = max - min
    local s = d / max
    local h
    if max == min then
        h = 0
    elseif max == r then
        h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
        h = (b - r) / d + 2
    else
        h = (r - g) / d + 4
    end
    return h / 6, s, max
end
local function HSVToRGB(h, s, v)
    h = ((h % 1) + 1) % 1
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end
local function ClassColor()
    local _, classFile = UnitClass("player")
    if classFile then
        local key = classFile:upper()
        if C_ClassColor and C_ClassColor.GetClassColor then
            local c = C_ClassColor.GetClassColor(key)
            if c then return c.r, c.g, c.b end
        end
        local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
        if fallback then return fallback.r, fallback.g, fallback.b end
    end
    return 1, 1, 1
end
local function Clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v or 0))
end

local W, M = 420, 12
local RX = 280
local PREVIEW_W, PREVIEW_H = W - M - RX, 48
local HUE_Y, HUE_H = -30, 26
local LABEL_W = 14
local SLIDER_X, TRACK_W, TRACK_H = M + LABEL_W, 246, 14
local S_Y = HUE_Y - HUE_H - 10
local V_Y = S_Y - TRACK_H - 10
local A_Y = V_Y - TRACK_H - 10
local CLASS_Y = HUE_Y - PREVIEW_H - 12
local COPY_Y = CLASS_Y - 20 - 8
local BOX_Y = 40
local H_NOALPHA = 205
local H_ALPHA = 222

local ART = "Interface\\AddOns\\LocationPlus\\Media\\Art\\"

--- Серые «шашечки» под прозрачными областями (превью, слайдер альфы).
local function MakeCheckerboard(parent, w, h, cell, light, dark)
    for row = 0, math.ceil(h / cell) - 1 do
        for col = 0, math.ceil(w / cell) - 1 do
            local t = parent:CreateTexture(nil, "ARTWORK")
            t:SetPoint("TOPLEFT", parent, "TOPLEFT", col * cell, -row * cell)
            t:SetSize(math.min(cell, w - col * cell), math.min(cell, h - row * cell))
            local c = (row + col) % 2 == 0 and light or dark
            t:SetColorTexture(c[1], c[2], c[3], c[4])
        end
    end
end

local function MakeGradient(parent, w, h, count, colorFn)
    local strips = {}
    for i = 0, count - 1 do
        local t = parent:CreateTexture(nil, "BACKGROUND")
        t:SetWidth(w / count)
        t:SetHeight(h)
        t:SetPoint("TOPLEFT", parent, "TOPLEFT", (w / count) * i, 0)
        local r, g, b, a = colorFn(i / (count - 1))
        t:SetColorTexture(r, g, b, a)
        strips[#strips + 1] = t
    end
    return strips
end

--- Маркер-полоска (2px белая на 4px тёмной подложке) для треков.
local function MakeKnob(parent, h)
    local bg = parent:CreateTexture(nil, "OVERLAY")
    bg:SetSize(4, h)
    bg:SetPoint("TOP", parent, "TOP", 0, 0)
    bg:SetColorTexture(0, 0, 0, 0.8)
    local fg = parent:CreateTexture(nil, "OVERLAY")
    fg:SetSize(2, h)
    fg:SetPoint("TOP", parent, "TOP", 0, 0)
    fg:SetColorTexture(1, 1, 1, 1)
    return bg, fg
end

--- Открывает пикер цвета (один экземпляр, повторный вызов прячет предыдущий).
--- @param r number 0..1
--- @param g number 0..1
--- @param b number 0..1
--- @param a number 0..1 (учитывается при options.hasAlpha)
--- @param onChange function(r, g, b, a) вызывается по OK
--- @param onCancel function(r, g, b, a) вызывается по Cancel/ESC (цвет на момент открытия)
--- @param options table { hasAlpha = boolean, title = string,
---     defaultColor = { r, g, b, a } — значение для кнопки «Сбросить» }
--- @return Frame фрейм пикера
function ColorPicker.Open(r, g, b, a, onChange, onCancel, options)
    if ColorPicker.frame then
        ColorPicker.frame:Hide()
        ColorPicker.frame = nil
    end
    r, g, b = Clamp(r, 0, 1), Clamp(g, 0, 1), Clamp(b, 0, 1)
    a = Clamp(a, 0, 1)
    options = options or {}
    local hasAlpha = options.hasAlpha == true
    local original = { r = r, g = g, b = b, a = a }
    local state = { r = r, g = g, b = b, a = a }
    local updating = false

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(W, hasAlpha and H_ALPHA or H_NOALPHA)
    frame:SetPoint("CENTER")
    frame:SetFrameLevel(100)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    Theme.Box(frame, "window", "border", (Theme.Get()).windowRadius)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText(options.title or L.CP_TITLE or "Color Picker")

    local hueStrip = CreateFrame("Frame", nil, frame)
    hueStrip:SetSize(TRACK_W, HUE_H)
    hueStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", SLIDER_X, HUE_Y)
    Theme.Box(hueStrip, "field", "border", 2)
    local hueTex = hueStrip:CreateTexture(nil, "BACKGROUND")
    hueTex:SetAllPoints()
    hueTex:SetTexture(ART .. "grad_hue.png")
    local hueMarkerBg, hueMarker = MakeKnob(hueStrip, HUE_H)

    local function MakeSlider(y, labelText, overlayFile)
        local row = CreateFrame("Frame", nil, frame)
        row:SetSize(TRACK_W, TRACK_H)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", SLIDER_X, y)
        Theme.Box(row, "field", "border", 2)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("RIGHT", row, "LEFT", -4, 0)
        label:SetJustifyH("RIGHT")
        label:SetText(labelText)
        local base = row:CreateTexture(nil, "BACKGROUND")
        base:SetAllPoints()
        base:SetColorTexture(1, 0, 0, 1)
        if overlayFile then
            local ov = row:CreateTexture(nil, "ARTWORK")
            ov:SetAllPoints()
            ov:SetTexture(ART .. overlayFile)
        end
        local knobBg, knob = MakeKnob(row, TRACK_H)
        return row, base, knobBg, knob
    end
    local satRow, satBase, satKnobBg, satKnob = MakeSlider(S_Y, "S", "grad_white.png")
    local valRow, valBase, valKnobBg, valKnob = MakeSlider(V_Y, "V", "grad_black_h.png")

    local alphaRow, alphaStrips, alphaKnobBg, alphaKnob
    if hasAlpha then
        alphaRow = CreateFrame("Frame", nil, frame)
        alphaRow:SetSize(TRACK_W, TRACK_H)
        alphaRow:SetPoint("TOPLEFT", frame, "TOPLEFT", SLIDER_X, A_Y)
        Theme.Box(alphaRow, "field", "border", 2)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("RIGHT", alphaRow, "LEFT", -4, 0)
        label:SetJustifyH("RIGHT")
        label:SetText("A")
        MakeCheckerboard(alphaRow, TRACK_W, TRACK_H, 7,
            { 0.8, 0.8, 0.8, 0.35 }, { 0.45, 0.45, 0.45, 0.35 })
        alphaStrips = MakeGradient(alphaRow, TRACK_W, TRACK_H, 64, function(p)
            return 0, 0, 0, p
        end)
        alphaKnobBg, alphaKnob = MakeKnob(alphaRow, TRACK_H)
    end

    local previewFrame = CreateFrame("Frame", nil, frame)
    previewFrame:SetSize(PREVIEW_W, PREVIEW_H)
    previewFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", RX, HUE_Y)
    Theme.Box(previewFrame, "field", "border", 2)
    local partW = math.floor(PREVIEW_W / 2)
    local previewCur
    for i = 0, 1 do
        local part = CreateFrame("Frame", nil, previewFrame)
        part:SetSize(partW, PREVIEW_H)
        part:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", i * partW, 0)
        MakeCheckerboard(part, partW, PREVIEW_H, 8,
            { 0.8, 0.8, 0.8, 0.35 }, { 0.45, 0.45, 0.45, 0.35 })
        local col = part:CreateTexture(nil, "OVERLAY")
        col:SetAllPoints()
        if i == 0 then
            col:SetColorTexture(original.r, original.g, original.b, original.a)
        else
            previewCur = col
        end
    end
    local sep = previewFrame:CreateTexture(nil, "OVERLAY")
    sep:SetSize(1, PREVIEW_H)
    sep:SetPoint("LEFT", previewFrame, "LEFT", partW, 0)
    sep:SetColorTexture(0.15, 0.15, 0.15, 1)

    local classBtn = Widgets.CreateFlatButton(frame, PREVIEW_W, 20, L.CP_CLASS_COLOR or "Class Color")
    classBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", RX, CLASS_Y)
    local swatch = classBtn:CreateTexture(nil, "OVERLAY")
    swatch:SetSize(12, 12)
    swatch:SetPoint("LEFT", classBtn, "LEFT", 6, 0)
    local cr, cg, cb = ClassColor()
    swatch:SetColorTexture(cr, cg, cb, 1)

    local copyBtn = Widgets.CreateFlatButton(frame, 62, 20, L.CP_COPY or "Copy")
    copyBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", RX, COPY_Y)

    local boxR, boxG, boxB, boxA, hexBox
    local hexFocused = false
    local function FormatHex()
        local r = math.floor(state.r * 255 + 0.5)
        local g = math.floor(state.g * 255 + 0.5)
        local b = math.floor(state.b * 255 + 0.5)
        if hasAlpha then
            local av = math.floor(state.a * 255 + 0.5)
            return string.format("#%.2X%.2X%.2X%.2X", av, r, g, b)
        end
        return string.format("#%.2X%.2X%.2X", r, g, b)
    end

    --- Разбирает hex-строку в state: 8 символов — #AARRGGBB
    --- (альфа первые два, конвенция аддона), 3/6 — #RGB/#RRGGBB.
    local function ParseHex(t)
        local full
        if #t == 3 then
            full = t:sub(1, 1) .. t:sub(1, 1) .. t:sub(2, 2) .. t:sub(2, 2)
                .. t:sub(3, 3) .. t:sub(3, 3)
        else
            full = (t .. "00000000"):sub(1, 8)
        end
        if hasAlpha and #full >= 8 then
            state.a = (tonumber(full:sub(1, 2), 16) or 255) / 255
            state.r = (tonumber(full:sub(3, 4), 16) or 0) / 255
            state.g = (tonumber(full:sub(5, 6), 16) or 0) / 255
            state.b = (tonumber(full:sub(7, 8), 16) or 0) / 255
        else
            state.r = (tonumber(full:sub(1, 2), 16) or 0) / 255
            state.g = (tonumber(full:sub(3, 4), 16) or 0) / 255
            state.b = (tonumber(full:sub(5, 6), 16) or 0) / 255
        end
    end

    local function UpdateAll()
        updating = true
        boxR:SetText(string.format("%d", math.floor(state.r * 255 + 0.5)))
        boxG:SetText(string.format("%d", math.floor(state.g * 255 + 0.5)))
        boxB:SetText(string.format("%d", math.floor(state.b * 255 + 0.5)))
        if boxA then boxA:SetText(string.format("%d", math.floor(state.a * 100 + 0.5))) end
        if not hexFocused then
            hexBox:SetText(FormatHex())
        end
        local h, s, v = RGBToHSV(state.r, state.g, state.b)
        local hx = math.floor(h * (TRACK_W - 2))
        hueMarkerBg:SetPoint("LEFT", hueStrip, "LEFT", hx - 1, 0)
        hueMarker:SetPoint("LEFT", hueStrip, "LEFT", hx, 0)
        satBase:SetColorTexture(state.r, state.g, state.b, 1)
        local sx = math.floor(s * (TRACK_W - 2))
        satKnobBg:SetPoint("LEFT", satRow, "LEFT", sx - 1, 0)
        satKnob:SetPoint("LEFT", satRow, "LEFT", sx, 0)
        valBase:SetColorTexture(state.r, state.g, state.b, 1)
        local vx = math.floor(v * (TRACK_W - 2))
        valKnobBg:SetPoint("LEFT", valRow, "LEFT", vx - 1, 0)
        valKnob:SetPoint("LEFT", valRow, "LEFT", vx, 0)
        if hasAlpha then
            for i = 1, #alphaStrips do
                alphaStrips[i]:SetColorTexture(state.r, state.g, state.b, (i - 1) / (#alphaStrips - 1))
            end
            local ax = math.floor(state.a * (TRACK_W - 2))
            alphaKnobBg:SetPoint("LEFT", alphaRow, "LEFT", ax - 1, 0)
            alphaKnob:SetPoint("LEFT", alphaRow, "LEFT", ax, 0)
        end
        previewCur:SetColorTexture(state.r, state.g, state.b, state.a)
        updating = false
    end

    local function MakeNumBox(x, labelText, value, min, max, applyFn)
        local lab = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", M + x, BOX_Y)
        lab:SetSize(10, 20)
        lab:SetJustifyH("LEFT")
        lab:SetText(labelText)
        local box = CreateFrame("EditBox", nil, frame)
        box:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", M + x + 14, BOX_Y)
        box:SetSize(44, 20)
        box:SetMaxLetters(3)
        box:SetNumeric(true)
        box:SetText(value)
        box:SetFontObject("GameFontHighlightSmall")
        Theme.Box(box, "field", "border", (Theme.Get()).buttonRadius or 0)
        box:SetScript("OnTextChanged", function(self)
            if updating or self:GetText() == "" then return end
            applyFn(Clamp(self:GetNumber(), min, max))
        end)
        box:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        return box
    end

    updating = true
    boxR = MakeNumBox(0, "R", string.format("%d", math.floor(r * 255 + 0.5)), 0, 255,
        function(v) state.r = v / 255; UpdateAll() end)
    boxG = MakeNumBox(66, "G", string.format("%d", math.floor(g * 255 + 0.5)), 0, 255,
        function(v) state.g = v / 255; UpdateAll() end)
    boxB = MakeNumBox(132, "B", string.format("%d", math.floor(b * 255 + 0.5)), 0, 255,
        function(v) state.b = v / 255; UpdateAll() end)
    if hasAlpha then
        boxA = MakeNumBox(198, "A", string.format("%d", math.floor(a * 100 + 0.5)), 0, 100,
            function(v) state.a = v / 100; UpdateAll() end)
    end

    hexBox = CreateFrame("EditBox", nil, frame)
    hexBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", M + 264, BOX_Y)
    hexBox:SetSize(132, 20)
    hexBox:SetMaxLetters(9)
    hexBox:SetText(FormatHex())
    hexBox:SetFontObject("GameFontHighlightSmall")
    Theme.Box(hexBox, "field", "border", (Theme.Get()).buttonRadius or 0)
    hexBox:SetScript("OnEditFocusGained", function()
        hexFocused = true
    end)
    hexBox:SetScript("OnEditFocusLost", function()
        hexFocused = false
        if updating then return end
        updating = true
        hexBox:SetText(FormatHex())
        updating = false
    end)
    hexBox:SetScript("OnTextChanged", function(self)
        if updating or not hexFocused then return end
        local t = self:GetText()
        t = t:gsub("%s", "")
        if t:find("^#") then t = t:sub(2) end
        t = t:gsub("[^0-9a-fA-F]", ""):sub(1, 8)
        if #t < 3 then return end
        ParseHex(t)
        UpdateAll()
    end)
    hexBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    updating = false

    classBtn:SetScript("OnClick", function()
        state.r, state.g, state.b = cr, cg, cb
        if hasAlpha then state.a = 1 end
        UpdateAll()
    end)
    -- Копирование: в WoW API есть только CopyToClipboard(text [, removeMarkup])
    -- (SetClipboardText не существует). Чтение буфера обмена недоступно
    -- вообще, поэтому кнопка Paste удалена — вводить hex можно вручную.
    copyBtn:SetScript("OnClick", function()
        if CopyToClipboard then
            CopyToClipboard(FormatHex())
        end
    end)

    local ref = CreateFrame("Frame", nil, UIParent)
    ref:SetSize(1, 1)
    ref:SetPoint("CENTER")

    local absProbe = CreateFrame("Frame", nil, frame)
    absProbe:SetSize(1, 1)
    absProbe:SetPoint("LEFT", frame, "LEFT", 50, 0)
    local absCoords
    local function UseAbsCoords()
        if absCoords == nil then
            absCoords = math.abs(absProbe:GetLeft() - (frame:GetLeft() + 50)) < 1
        end
        return absCoords
    end

    local function TrackAbsLeft(track)
        if UseAbsCoords() then
            return track:GetLeft()
        end
        return frame:GetLeft() + track:GetLeft()
    end

    local function CursorCandidates(x)
        local uiScale = UIParent:GetEffectiveScale() or 1
        if uiScale == 0 then uiScale = 1 end
        local S = ref:GetLeft() + 0.5
        return { S + x / uiScale, x / uiScale, S + x, x }
    end

    local function PickHypothesis(track, x)
        local cands = CursorCandidates(x)
        local T, span = TrackAbsLeft(track), TRACK_W - 2
        for i = 1, #cands do
            if cands[i] >= T and cands[i] <= T + span then
                return i
            end
        end
        return 1
    end

    local function CursorToValue(track, x, idx)
        local cands = CursorCandidates(x)
        local T, span = TrackAbsLeft(track), TRACK_W - 2
        local C
        if idx then
            C = cands[idx]
        else
            C = cands[PickHypothesis(track, x)]
        end
        local v = (C - T) / span
        if v < 0 then v = 0 elseif v > 1 then v = 1 end
        return v
    end

    local dragging
    local dragFrame = CreateFrame("Frame", nil, UIParent)
    dragFrame:SetFrameLevel(1000)
    dragFrame:SetFrameStrata("DIALOG")
    dragFrame:SetAllPoints(UIParent)
    dragFrame:EnableMouse(true)
    dragFrame:Hide()
    local function StopDrag()
        dragging = nil
        dragFrame:Hide()
    end
    local function StartDrag(track, applyFn)
        if updating or dragging then return end
        local x = GetCursorPosition()
        local idx = PickHypothesis(track, x)
        applyFn(CursorToValue(track, x, idx))
        dragging = { track = track, apply = applyFn, idx = idx }
        dragFrame:Show()
    end
    dragFrame:SetScript("OnUpdate", function()
        if not dragging then return end
        local d = dragging
        local ok, b = pcall(IsMouseButtonDown, "LeftButton")
        if ok and b == false then
            StopDrag()
            return
        end
        local x = GetCursorPosition()
        d.apply(CursorToValue(d.track, x, d.idx))
    end)
    dragFrame:SetScript("OnMouseUp", StopDrag)

    local trackList = {}

    local function MakeTrackTracker(track, applyFn)
        local t = CreateFrame("Frame", nil, track)
        t:SetAllPoints()
        t:EnableMouse(true)
        trackList[#trackList + 1] = { track = track, apply = applyFn }
        t:SetScript("OnMouseUp", function()
            if updating then return end
            if dragging then
                local x = GetCursorPosition()
                dragging.apply(CursorToValue(dragging.track, x, dragging.idx))
                StopDrag()
                return
            end
            local x = GetCursorPosition()
            applyFn(CursorToValue(track, x))
        end)
        pcall(function()
            t:SetScript("OnMouseDown", function()
                StartDrag(track, applyFn)
            end)
        end)
        return t
    end
    MakeTrackTracker(hueStrip, function(value)
        local _, s, v = RGBToHSV(state.r, state.g, state.b)
        if s < 0.01 then s = 1 end
        if v < 0.01 then v = 1 end
        state.r, state.g, state.b = HSVToRGB(value, s, v)
        UpdateAll()
    end)
    MakeTrackTracker(satRow, function(value)
        local h, _, v = RGBToHSV(state.r, state.g, state.b)
        if v < 0.01 then v = 1 end
        state.r, state.g, state.b = HSVToRGB(h, value, v)
        UpdateAll()
    end)
    MakeTrackTracker(valRow, function(value)
        local h, s = RGBToHSV(state.r, state.g, state.b)
        state.r, state.g, state.b = HSVToRGB(h, s, value)
        UpdateAll()
    end)
    if hasAlpha then
        MakeTrackTracker(alphaRow, function(value)
            state.a = value
            UpdateAll()
        end)
    end

    frame:SetScript("OnUpdate", function()
        if dragging then return end
        local ok, b = pcall(IsMouseButtonDown, "LeftButton")
        if not (ok and b) then return end
        for i = 1, #trackList do
            local e = trackList[i]
            if e.track:IsMouseOver() then
                StartDrag(e.track, e.apply)
                return
            end
        end
    end)

    local function Close()
        if dragging then StopDrag() end
        frame:Hide()
    end
    local function DoCancel()
        Close()
        if onCancel then
            onCancel(original.r, original.g, original.b, original.a)
        end
    end
    local resetColor = original
    local dc = options.defaultColor
    if type(dc) == "table" and tonumber(dc.r) then
        resetColor = {
            r = Clamp(dc.r, 0, 1),
            g = Clamp(tonumber(dc.g) or dc.r, 0, 1),
            b = Clamp(tonumber(dc.b) or dc.r, 0, 1),
            a = hasAlpha and ((tonumber(dc.a) and Clamp(dc.a, 0, 1)) or 1) or original.a,
        }
    end
    local resetBtn = Widgets.CreateFlatButton(frame, 80, 22, L.CP_RESET or "Reset")
    resetBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", M, 12)
    resetBtn:SetScript("OnClick", function()
        state.r, state.g, state.b, state.a = resetColor.r, resetColor.g, resetColor.b, resetColor.a
        UpdateAll()
    end)
    local okBtn = Widgets.CreateFlatButton(frame, 70, 22, L.CP_OK or "OK")
    okBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -M, 12)
    local cancelBtn = Widgets.CreateFlatButton(frame, 80, 22, L.CP_CANCEL or "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)
    okBtn:SetScript("OnClick", function()
        Close()
        if onChange then
            onChange(state.r, state.g, state.b, state.a)
        end
    end)
    cancelBtn:SetScript("OnClick", DoCancel)
    Widgets.BindEscapeToClose(frame, DoCancel)

    UpdateAll()
    Theme.ApplyFonts(frame)
    frame:Show()
    ColorPicker.frame = frame
    return frame
end
