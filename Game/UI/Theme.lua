local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
--- Тема оформления нативного окна настроек.
local Theme = {}
LPS.UI = LPS.UI or {}
local ns = LPS.UI
ns.Theme = Theme
--- Цвет из hex: "#RRGGBB" (alpha = 1) или "#AARRGGBB" (alpha впереди, как в
--- цветовом пикере WoW); явный параметр alpha перекрывает alpha из хеша.
local function Hex(value, alpha)
    local a, r, g, b
    if value:len() == 9 then
        a = alpha or tonumber(value:sub(2, 3), 16) / 255
        r, g, b = value:sub(4, 5), value:sub(6, 7), value:sub(8, 9)
    else
        a = alpha
        r, g, b = value:sub(2, 3), value:sub(4, 5), value:sub(6, 7)
    end
    return {
        tonumber(r, 16) / 255,
        tonumber(g, 16) / 255,
        tonumber(b, 16) / 255,
        a or 1,
    }
end
local MEDIA = "Interface\\AddOns\\" .. (LPS.addon and LPS.addon.name or "LocationPlus") .. "\\Media\\"
local FONTS = MEDIA .. "Fonts\\"
Theme.ART = MEDIA .. "Art\\"
local BARLOW = FONTS .. "Barlow-Regular.ttf"
local BARLOW_SEMI = FONTS .. "Barlow-SemiBold.ttf"
local BARLOW_COND = FONTS .. "BarlowCondensed-Bold.ttf"
local CINZEL = FONTS .. "Cinzel-Bold.ttf"
local SOURCE = FONTS .. "SourceSans3-Regular.ttf"
local SOURCE_BOLD = FONTS .. "SourceSans3-Bold.ttf"
local NON_LATIN = { ruRU = true, koKR = true, zhCN = true, zhTW = true }
local function UseGameFont()
    return NON_LATIN[GetLocale()] == true
end
Theme.ORDER = { "modern", "vintage", "classic", "frost" }
Theme.THEMES = {
    modern = {
        nameKey = "THEME_MODERN", fallbackName = "Modern",
        descKey = "THEME_MODERN_DESC", fallbackDesc = "Flat charcoal with a green accent.",
        fonts = { body = BARLOW, strong = BARLOW_SEMI, heading = BARLOW_SEMI, title = BARLOW_COND, button = BARLOW_SEMI },
        titleSize = 18, windowRadius = 10, buttonRadius = 4, sizeBoost = 2,
        uppercaseTitle = true, headerFill = true, stripe = true,
        colors = {
            window = Hex("#171a1f"), header = Hex("#1d2127"), nav = Hex("#14171b"), surface = Hex("#1d2127"),
            field = Hex("#121519"), hover = Hex("#262b32"), border = Hex("#2c323a"), line = Hex("#2c323a"),
            accent = Hex("#4fbf8f"), text = Hex("#e8ebee"), muted = Hex("#9aa3ad"), title = Hex("#e8ebee"), heading = Hex("#e8ebee"),
            button = Hex("#262b32"), buttonBorder = Hex("#2c323a"), buttonHover = Hex("#30363f"), buttonText = Hex("#e8ebee"),
            primary = Hex("#2f8f68"), primaryBorder = Hex("#2f8f68"), primaryHover = Hex("#36a377"), primaryText = Hex("#ffffff"),
            disabled = Hex("#5c646d"),
        },
    },
    vintage = {
        nameKey = "THEME_VINTAGE", fallbackName = "Vintage",
        descKey = "THEME_VINTAGE_DESC", fallbackDesc = "Walnut and brass with engraved headings.",
        fonts = { body = SOURCE, strong = SOURCE_BOLD, heading = CINZEL, title = CINZEL, button = SOURCE_BOLD },
        titleSize = 15, windowRadius = 4, buttonRadius = 4, sizeBoost = 2,
        innerFrame = true,
        colors = {
            window = Hex("#1c1611"), header = Hex("#1c1611"), nav = Hex("#18130f"), surface = Hex("#241c15"),
            field = Hex("#120e0b"), hover = Hex("#2e241b"), border = Hex("#5a4630"), line = Hex("#3a2e22"),
            accent = Hex("#c9a35a"), text = Hex("#efe6d6"), muted = Hex("#bfb19e"), title = Hex("#e9d9b4"), heading = Hex("#f3e6c8"),
            button = Hex("#241c15"), buttonBorder = Hex("#5a4630"), buttonHover = Hex("#2e241b"), buttonText = Hex("#e9d9b4"),
            primary = Hex("#c9a35a"), primaryBorder = Hex("#e2c07a"), primaryHover = Hex("#d6b06a"), primaryText = Hex("#1c1611"),
            disabled = Hex("#6b5d4e"),
        },
    },
    classic = {
        nameKey = "THEME_CLASSIC", fallbackName = "Classic",
        descKey = "THEME_CLASSIC_DESC", fallbackDesc = "The original classic look.",
        titleSize = 16, windowRadius = 0, buttonRadius = 0,
        headerFill = true,
        colors = {
            window = Hex("#fa0f0f0f"), header = Hex("#141414"), nav = Hex("#0b0b0b"), surface = Hex("#121212"),
            field = Hex("#1a1a1a"), hover = Hex("#1f1f1f"), border = Hex("#383838"), line = Hex("#474747"),
            accent = Hex("#c7a838"), text = Hex("#ebe8db"), muted = Hex("#b3b3b3"),
            title = Hex("#ebe8db"), heading = Hex("#ebe8db"),
            button = Hex("#1f1f1f"), buttonBorder = Hex("#383838"), buttonHover = Hex("#2e2e2e"), buttonText = Hex("#b3b3b3"),
            primary = Hex("#1f1f1f"), primaryBorder = Hex("#c7a838"), primaryHover = Hex("#2e2e2e"), primaryText = Hex("#ebe8db"),
            disabled = Hex("#666666"),
        },
    },
    frost = {
        nameKey = "THEME_FROST", fallbackName = "Frost",
        descKey = "THEME_FROST_DESC", fallbackDesc = "Cool navy depths with an icy accent.",
        fonts = { body = BARLOW, strong = BARLOW_SEMI, heading = BARLOW_SEMI, title = BARLOW_COND, button = BARLOW_SEMI },
        titleSize = 18, windowRadius = 10, buttonRadius = 4, sizeBoost = 2,
        uppercaseTitle = true, headerFill = true,
        colors = {
            window = Hex("#121821"), header = Hex("#17202c"), nav = Hex("#0f141c"), surface = Hex("#17202c"),
            field = Hex("#0c1118"), hover = Hex("#213042"), border = Hex("#2e3d52"), line = Hex("#2e3d52"),
            accent = Hex("#6cb8d8"), text = Hex("#e5ecf4"), muted = Hex("#94a6ba"), title = Hex("#e5ecf4"), heading = Hex("#e5ecf4"),
            button = Hex("#213042"), buttonBorder = Hex("#2e3d52"), buttonHover = Hex("#2a3c51"), buttonText = Hex("#e5ecf4"),
            primary = Hex("#2f7ea3"), primaryBorder = Hex("#6cb8d8"), primaryHover = Hex("#3891b8"), primaryText = Hex("#ffffff"),
            disabled = Hex("#5b6c7e"),
        },
    },
}
function Theme.GetName(key)
    local def = Theme.THEMES[key]
    if not def then return key end
    return L[def.nameKey] or def.fallbackName
end
function Theme.GetDescription(key)
    local def = Theme.THEMES[key]
    if not def then return "" end
    return L[def.descKey] or def.fallbackDesc
end
--- Есть ли класс в этой версии игры: опросом LOCALIZED_CLASS_NAMES_MALE —
--- клиентской таблицы локализованных имён классов. В ней есть только те классы,
--- что существуют в этой сборке (в Classic — классики, в Retail — все). Не по
--- RAID_CLASS_COLORS (там цвета всех классов) и не по жёстко заданным уровням
--- экспансий.
local function ClassExists(classToken)
    if not classToken then return false end
    if not LOCALIZED_CLASS_NAMES_MALE then return false end
    return LOCALIZED_CLASS_NAMES_MALE[classToken:upper()] ~= nil
end
--- Золотой запасается только если класс-цвета недоступны.
local DEFAULT_ACCENT = Hex("#c7a838")
--- Акцент по умолчанию = цвет текущего класса игрока (если класс определён).
local function GetDefaultAccent()
    local _, classFile = UnitClass("player")
    local r, g, b = GetClassColor(classFile)
    if r then return r, g, b end
    return DEFAULT_ACCENT[1], DEFAULT_ACCENT[2], DEFAULT_ACCENT[3]
end
--- Устаревшие настройки окна, удалённые из UI; чистим их из БД при загрузке.
local OBSOLETE_UI_KEYS = {
    "themeUseClassColor", "accentColor",
    "windowColorMode", "windowColor", "windowColorKeepHeader",
}
local function MuteColor(r, g, b, amount)
    amount = amount or 0.15
    return r + (0.5 - r) * amount, g + (0.5 - g) * amount, b + (0.5 - b) * amount
end
local function GetClassColor(classToken)
    if not classToken then return nil end
    local key = classToken:upper()
    if C_ClassColor and C_ClassColor.GetClassColor then
        local c = C_ClassColor.GetClassColor(key)
        if c then return c.r, c.g, c.b end
    end
    local fallback = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
    if fallback then return fallback.r, fallback.g, fallback.b end
    return nil
end
--- Цвет выбранной цветовой темы акцента (db.uiOptions.themeColor).
--- "default" = цвет текущего класса игрока (не золото).
function Theme.GetAccentColor()
    local db = LPS:GetDB()
    local ui = db and db.uiOptions
    if not ui then return nil end
    local id = ui.themeColor
    if not id or id == "default" then
        local r, g, b = GetDefaultAccent()
        return MuteColor(r, g, b, 0.2)
    end
    if ClassExists(id) then
        local r, g, b = GetClassColor(id)
        if r then return MuteColor(r, g, b, 0.2) end
    end
    local r, g, b = GetDefaultAccent()
    return MuteColor(r, g, b, 0.2)
end
--- Классы, которые убираем из списка тем независимо от цвета: сравниваем токен
--- (ключ) и локализованное имя, без учёта регистра, и удаляем всё, что найдено
--- в этом перечне. Расширяется по мере необходимости.
local ACCENT_EXCLUDED = { adventurer = true, traveler = true }
local function IsExcludedAccent(token, name)
    if type(token) == "string" and ACCENT_EXCLUDED[token:lower()] then return true end
    if type(name) == "string" and ACCENT_EXCLUDED[name:lower()] then return true end
    return false
end
--- Список значений dropdown'а цветовых тем: только классы, доступные в игре,
--- с подготовленным цветом и не входящие в ACCENT_EXCLUDED;
--- значение "default" = текущий класс игрока.
function Theme.GetAccentItems()
    local items = { { value = "default", text = L.THEME_COLOR_DEFAULT } }
    if LOCALIZED_CLASS_NAMES_MALE then
        -- Классы берём напрямую из LOCALIZED_CLASS_NAMES_MALE:
        -- ключ = токен (используется как ключ для цвета), значение = локализованное имя.
        -- Оставляем только те, для которых есть цвет и которые не в списке исключений.
        local classes = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
            if GetClassColor(token) and not IsExcludedAccent(token, name) then
                classes[#classes + 1] = { value = token, text = name }
            end
        end
        table.sort(classes, function(a, b)
            return (a.text or "") < (b.text or "")
        end)
        for _, it in ipairs(classes) do
            items[#items + 1] = it
        end
    end
    return items
end
--- Устаревшие ключи тем: старые значения из БД прозрачно переносим в новые
--- (время жизни аддона: "workbench" -> "modern", "ledger" -> "vintage").
local LEGACY_THEME_KEYS = { workbench = "modern", ledger = "vintage" }
function Theme.Load()
    local db = LPS:GetDB()
    local ui = db and db.uiOptions
    -- Чистим устаревшие настройки, удалённые из UI (галка «цвет класса»,
    -- свой цвет акцента, группа «Цвет окна»).
    if ui then
        for _, k in ipairs(OBSOLETE_UI_KEYS) do ui[k] = nil end
    end
    local key = ui and ui.theme
    if key and LEGACY_THEME_KEYS[key] then key = LEGACY_THEME_KEYS[key] end
    if not Theme.THEMES[key] then key = "modern" end
    Theme.key = key
    Theme.T = Theme.THEMES[key]
    local C = {}
    for k, v in pairs(Theme.T.colors) do C[k] = v end
    -- акцент: цветовая тема (класс)
    local r, g, b = Theme.GetAccentColor()
    if r then
        C.accent = { r, g, b, 1 }
        C.primaryBorder = C.accent
    end
    Theme.C = C
end
function Theme.Get()
    if not Theme.C then Theme.Load() end
    return Theme.T, Theme.C
end
local listeners = {}
function Theme.OnChange(fn)
    listeners[#listeners + 1] = fn
end
function Theme.Set(key)
    if not Theme.THEMES[key] then return end
    local db = LPS:GetDB()
    if not db then return end
    db.uiOptions = db.uiOptions or {}
    db.uiOptions.theme = key
    Theme.Load()
    for _, fn in ipairs(listeners) do
        local ok, err = pcall(fn, key)
        if not ok then
            geterrorhandler()(err)
        end
    end
end
function Theme.Cycle()
    local current = Theme.key or "modern"
    for i, key in ipairs(Theme.ORDER) do
        if key == current then
            Theme.Set(Theme.ORDER[i % #Theme.ORDER + 1])
            return
        end
    end
    Theme.Set(Theme.ORDER[1])
end
local pendingFonts = {}
local retrying = false
local function Redraw(fs)
    local text = fs:GetText()
    if text then
        fs:SetText("")
        fs:SetText(text)
    end
end
local function RetryFonts()
    retrying = false
    for fs, req in pairs(pendingFonts) do
        req.tries = req.tries + 1
        if fs:SetFont(req.file, req.size, req.flags) or req.tries > 10 then
            pendingFonts[fs] = nil
        end
        Redraw(fs)
    end
    if next(pendingFonts) then
        retrying = true
        C_Timer.After(0.3, RetryFonts)
    end
end
function Theme.SetFont(fs, file, size, flags)
    flags = flags or ""
    if not file or UseGameFont() then
        fs:SetFont(STANDARD_TEXT_FONT, size, flags)
        return
    end
    if fs:SetFont(file, size, flags) then
        pendingFonts[fs] = nil
        Redraw(fs)
        return
    end
    fs:SetFont(STANDARD_TEXT_FONT, size, flags)
    Redraw(fs)
    pendingFonts[fs] = { file = file, size = size, flags = flags, tries = 0 }
    if not retrying then
        retrying = true
        C_Timer.After(0.3, RetryFonts)
    end
end
function Theme.FontFor(role)
    local T = Theme.Get()
    return T.fonts and (T.fonts[role] or T.fonts.body) or nil
end
local function ApplyFontTo(fs, T)
    if not T.fonts then return end
    local _, size, flags = fs:GetFont()
    size = size or 12
    local role = fs.themeRole or "body"
    if role == "title" then
        size = T.titleSize or size
    elseif not fs.themeSized then
        fs.themeSized = true
        size = size + (T.sizeBoost or 0)
        fs.themeSize = size
    else
        size = fs.themeSize or size
    end
    Theme.SetFont(fs, T.fonts[role] or T.fonts.body, math.floor(size + 0.5), flags)
    if role == "title" and fs.rawTitle then
        fs:SetText(T.uppercaseTitle and fs.rawTitle:upper() or fs.rawTitle)
    end
end
function Theme.ApplyFonts(root)
    local T = Theme.Get()
    if not T.fonts or not root then return end
    for _, region in ipairs({ root:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "FontString" and not region.themeSkip then
            ApplyFontTo(region, T)
        end
    end
    for _, child in ipairs({ root:GetChildren() }) do
        Theme.ApplyFonts(child)
    end
end
function Theme.SetTitle(fs, text)
    fs.themeRole = "title"
    fs.rawTitle = text
    local T = Theme.Get()
    fs:SetText(T.uppercaseTitle and text:upper() or text)
end
function Theme.Shape(tex, radius)
    if radius and radius > 0 and tex.SetTextureSliceMargins then
        tex:SetTexture(Theme.ART .. "round" .. radius)
        tex:SetTextureSliceMargins(radius, radius, radius, radius)
        if Enum and Enum.UITextureSliceMode and tex.SetTextureSliceMode then
            tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    else
        if tex.SetTextureSliceMargins then
            tex:SetTextureSliceMargins(0, 0, 0, 0)
        end
        tex:SetColorTexture(1, 1, 1, 1)
    end
end
function Theme.Tint(tex, c, alpha)
    if not tex or not c then return end
    tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
end
function Theme.Box(frame, fillKey, borderKey, radius, sublevel)
    local _, C = Theme.Get()
    local base = sublevel or 0
    local edge = frame:CreateTexture(nil, "BACKGROUND", nil, base - 2)
    edge:SetAllPoints()
    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, base - 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    Theme.Shape(edge, radius)
    Theme.Shape(fill, radius)
    Theme.Tint(edge, C[borderKey or "border"])
    Theme.Tint(fill, C[fillKey or "window"])
    frame.edge, frame.fill = edge, fill
    return fill, edge
end
function Theme.CornerFill(frame, colorKey, radius, layer, sublevel)
    local _, C = Theme.Get()
    local c = C[colorKey]
    local textures = {}
    local function Square()
        local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
        t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        textures[#textures + 1] = t
        return t
    end
    if not radius or radius <= 0 then
        Square():SetAllPoints()
        return textures
    end
    local round = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel or 0)
    round:SetAllPoints()
    Theme.Shape(round, radius)
    Theme.Tint(round, c)
    textures[#textures + 1] = round
    local upper = Square()
    upper:SetPoint("TOPLEFT")
    upper:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, radius)
    local lower = Square()
    lower:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", radius, 0)
    lower:SetPoint("BOTTOMRIGHT")
    lower:SetHeight(radius)
    return textures
end
function Theme.Window(frame, headerHeight, noRing)
    local T, C = Theme.Get()
    Theme.Box(frame, "window", "border", T.windowRadius)
    if T.headerFill then
        local header = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(headerHeight - 1)
        Theme.Shape(header, T.windowRadius)
        Theme.Tint(header, C.header)
        local square = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        square:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
        square:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
        square:SetHeight(math.min(headerHeight - 1, T.windowRadius or 0))
        square:SetColorTexture(C.header[1], C.header[2], C.header[3], 1)
    end
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetPoint("TOPLEFT", 1, -headerHeight)
    line:SetPoint("TOPRIGHT", -1, -headerHeight)
    line:SetHeight(1)
    line:SetColorTexture(C.line[1], C.line[2], C.line[3], 1)
    if T.stripe then
        local stripe = frame:CreateTexture(nil, "BORDER", nil, 1)
        stripe:SetPoint("TOPLEFT", 1, -headerHeight)
        stripe:SetSize(48, 2)
        stripe:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    if T.innerFrame and not noRing then
        local ring = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
        ring:SetPoint("TOPLEFT", 4, -4)
        ring:SetPoint("BOTTOMRIGHT", -4, 4)
        Theme.Shape(ring, T.windowRadius)
        Theme.Tint(ring, C.line)
        local ringFill = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
        ringFill:SetPoint("TOPLEFT", ring, 1, -1)
        ringFill:SetPoint("BOTTOMRIGHT", ring, -1, 1)
        Theme.Shape(ringFill, T.windowRadius)
        Theme.Tint(ringFill, C.window)
    end
    frame.headerLine = line
end
function Theme.CloseButton(parent, size)
    return Theme.IconButton(parent, size, "icon_close")
end
function Theme.IconButton(parent, size, iconName)
    local _, C = Theme.Get()
    local T = Theme.T
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    local fill = Theme.Box(button, "button", "buttonBorder", T.buttonRadius)
    local icon = button:CreateTexture(nil, "ARTWORK")
    button.icon = icon
    icon:SetTexture(Theme.ART .. iconName)
    icon:SetSize(math.floor(size * 0.5 + 0.5), math.floor(size * 0.5 + 0.5))
    icon:SetPoint("CENTER")
    Theme.Tint(icon, C.muted)
    button:SetScript("OnEnter", function()
        Theme.Tint(fill, Theme.C.buttonHover)
        Theme.Tint(icon, Theme.C.text)
    end)
    button:SetScript("OnLeave", function()
        Theme.Tint(fill, Theme.C.button)
        Theme.Tint(icon, Theme.C.muted)
    end)
    return button
end
