local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
--- Тема оформления нативного окна настроек.
local Theme = {}
LPS.UI = LPS.UI or {}
--- Цвет из hex: "#RRGGBB" (alpha = 1) или "#AARRGGBB" (alpha впереди, как в
--- цветовом пикере WoW); явный параметр alpha перекрывает alpha из хеша.
function LPS:HexToColor(value, alpha)
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
function LPS:UseGameFont()
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
            window = LPS:HexToColor("#171a1f"), header = LPS:HexToColor("#1d2127"), nav = LPS:HexToColor("#14171b"), surface = LPS:HexToColor("#1d2127"),
            field = LPS:HexToColor("#121519"), hover = LPS:HexToColor("#262b32"), border = LPS:HexToColor("#2c323a"), line = LPS:HexToColor("#2c323a"),
            accent = LPS:HexToColor("#4fbf8f"), text = LPS:HexToColor("#e8ebee"), muted = LPS:HexToColor("#9aa3ad"), title = LPS:HexToColor("#e8ebee"), heading = LPS:HexToColor("#e8ebee"),
            button = LPS:HexToColor("#262b32"), buttonBorder = LPS:HexToColor("#2c323a"), buttonHover = LPS:HexToColor("#30363f"), buttonText = LPS:HexToColor("#e8ebee"),
            primary = LPS:HexToColor("#2f8f68"), primaryBorder = LPS:HexToColor("#2f8f68"), primaryHover = LPS:HexToColor("#36a377"), primaryText = LPS:HexToColor("#ffffff"),
            disabled = LPS:HexToColor("#5c646d"),
        },
    },
    vintage = {
        nameKey = "THEME_VINTAGE", fallbackName = "Vintage",
        descKey = "THEME_VINTAGE_DESC", fallbackDesc = "Walnut and brass with engraved headings.",
        fonts = { body = SOURCE, strong = SOURCE_BOLD, heading = CINZEL, title = CINZEL, button = SOURCE_BOLD },
        titleSize = 15, windowRadius = 4, buttonRadius = 4, sizeBoost = 2,
        innerFrame = true,
        colors = {
            window = LPS:HexToColor("#1c1611"), header = LPS:HexToColor("#1c1611"), nav = LPS:HexToColor("#18130f"), surface = LPS:HexToColor("#241c15"),
            field = LPS:HexToColor("#120e0b"), hover = LPS:HexToColor("#2e241b"), border = LPS:HexToColor("#5a4630"), line = LPS:HexToColor("#3a2e22"),
            accent = LPS:HexToColor("#c9a35a"), text = LPS:HexToColor("#efe6d6"), muted = LPS:HexToColor("#bfb19e"), title = LPS:HexToColor("#e9d9b4"), heading = LPS:HexToColor("#f3e6c8"),
            button = LPS:HexToColor("#241c15"), buttonBorder = LPS:HexToColor("#5a4630"), buttonHover = LPS:HexToColor("#2e241b"), buttonText = LPS:HexToColor("#e9d9b4"),
            primary = LPS:HexToColor("#c9a35a"), primaryBorder = LPS:HexToColor("#e2c07a"), primaryHover = LPS:HexToColor("#d6b06a"), primaryText = LPS:HexToColor("#1c1611"),
            disabled = LPS:HexToColor("#6b5d4e"),
        },
    },
    classic = {
        nameKey = "THEME_CLASSIC", fallbackName = "Classic",
        descKey = "THEME_CLASSIC_DESC", fallbackDesc = "The original classic look.",
        titleSize = 16, windowRadius = 0, buttonRadius = 0,
        headerFill = true,
        colors = {
            window = LPS:HexToColor("#fa0f0f0f"), header = LPS:HexToColor("#141414"), nav = LPS:HexToColor("#0b0b0b"), surface = LPS:HexToColor("#121212"),
            field = LPS:HexToColor("#1a1a1a"), hover = LPS:HexToColor("#1f1f1f"), border = LPS:HexToColor("#383838"), line = LPS:HexToColor("#474747"),
            accent = LPS:HexToColor("#c7a838"), text = LPS:HexToColor("#ebe8db"), muted = LPS:HexToColor("#b3b3b3"),
            title = LPS:HexToColor("#ebe8db"), heading = LPS:HexToColor("#ebe8db"),
            button = LPS:HexToColor("#1f1f1f"), buttonBorder = LPS:HexToColor("#383838"), buttonHover = LPS:HexToColor("#2e2e2e"), buttonText = LPS:HexToColor("#b3b3b3"),
            primary = LPS:HexToColor("#1f1f1f"), primaryBorder = LPS:HexToColor("#c7a838"), primaryHover = LPS:HexToColor("#2e2e2e"), primaryText = LPS:HexToColor("#ebe8db"),
            disabled = LPS:HexToColor("#666666"),
        },
    },
    frost = {
        nameKey = "THEME_FROST", fallbackName = "Frost",
        descKey = "THEME_FROST_DESC", fallbackDesc = "Cool navy depths with an icy accent.",
        fonts = { body = BARLOW, strong = BARLOW_SEMI, heading = BARLOW_SEMI, title = BARLOW_COND, button = BARLOW_SEMI },
        titleSize = 18, windowRadius = 10, buttonRadius = 4, sizeBoost = 2,
        uppercaseTitle = true, headerFill = true,
        colors = {
            window = LPS:HexToColor("#121821"), header = LPS:HexToColor("#17202c"), nav = LPS:HexToColor("#0f141c"), surface = LPS:HexToColor("#17202c"),
            field = LPS:HexToColor("#0c1118"), hover = LPS:HexToColor("#213042"), border = LPS:HexToColor("#2e3d52"), line = LPS:HexToColor("#2e3d52"),
            accent = LPS:HexToColor("#6cb8d8"), text = LPS:HexToColor("#e5ecf4"), muted = LPS:HexToColor("#94a6ba"), title = LPS:HexToColor("#e5ecf4"), heading = LPS:HexToColor("#e5ecf4"),
            button = LPS:HexToColor("#213042"), buttonBorder = LPS:HexToColor("#2e3d52"), buttonHover = LPS:HexToColor("#2a3c51"), buttonText = LPS:HexToColor("#e5ecf4"),
            primary = LPS:HexToColor("#2f7ea3"), primaryBorder = LPS:HexToColor("#6cb8d8"), primaryHover = LPS:HexToColor("#3891b8"), primaryText = LPS:HexToColor("#ffffff"),
            disabled = LPS:HexToColor("#5b6c7e"),
        },
    },
}
function LPS:GetThemeName(key)
    local def = Theme.THEMES[key]
    if not def then return key end
    return L[def.nameKey] or def.fallbackName
end
function LPS:GetThemeDescription(key)
    local def = Theme.THEMES[key]
    if not def then return "" end
    return L[def.descKey] or def.fallbackDesc
end
--- Есть ли класс в этой версии игры: опросом LOCALIZED_CLASS_NAMES_MALE —
--- клиентской таблицы локализованных имён классов. В ней есть только те классы,
--- что существуют в этой сборке (в Classic — классики, в Retail — все). Не по
--- RAID_CLASS_COLORS (там цвета всех классов) и не по жёстко заданным уровням
--- экспансий.
function LPS:ClassExists(classToken)
    if not classToken then return false end
    if not LOCALIZED_CLASS_NAMES_MALE then return false end
    return LOCALIZED_CLASS_NAMES_MALE[classToken:upper()] ~= nil
end
--- Золотой запасается только если класс-цвета недоступны.
local DEFAULT_ACCENT = LPS:HexToColor("#c7a838")
--- Акцент по умолчанию = цвет текущего класса игрока (если класс определён).
function LPS:GetDefaultAccentColor()
    local _, classFile = UnitClass("player")
    local r, g, b = LPS:GetClassColor(classFile)
    if r then return r, g, b end
    return DEFAULT_ACCENT[1], DEFAULT_ACCENT[2], DEFAULT_ACCENT[3]
end
--- Устаревшие настройки окна, удалённые из UI; чистим их из БД при загрузке.
local OBSOLETE_UI_KEYS = {
    "themeUseClassColor", "accentColor",
    "windowColorMode", "windowColor", "windowColorKeepHeader",
}
function LPS:MuteColor(r, g, b, amount)
    amount = amount or 0.15
    return r + (0.5 - r) * amount, g + (0.5 - g) * amount, b + (0.5 - b) * amount
end
function LPS:GetThemeAccentColor()
    local db = LPS:GetDB()
    local ui = db and db.uiOptions
    if not ui then return nil end
    local id = ui.themeColor
    if not id or id == "default" then
        local r, g, b = LPS:GetDefaultAccentColor()
        return LPS:MuteColor(r, g, b, 0.2)
    end
    if LPS:ClassExists(id) then
        local r, g, b = LPS:GetClassColor(id)
        if r then return LPS:MuteColor(r, g, b, 0.2) end
    end
    local r, g, b = LPS:GetDefaultAccentColor()
    return LPS:MuteColor(r, g, b, 0.2)
end
--- Классы, которые убираем из списка тем независимо от цвета: сравниваем токен
--- (ключ) и локализованное имя, без учёта регистра, и удаляем всё, что найдено
--- в этом перечне. Расширяется по мере необходимости.
local ACCENT_EXCLUDED = { adventurer = true, traveler = true }
function LPS:IsExcludedAccent(token, name)
    if type(token) == "string" and ACCENT_EXCLUDED[token:lower()] then return true end
    if type(name) == "string" and ACCENT_EXCLUDED[name:lower()] then return true end
    return false
end
--- Список значений dropdown'а цветовых тем: только классы, доступные в игре,
--- с подготовленным цветом и не входящие в ACCENT_EXCLUDED;
--- значение "default" = текущий класс игрока.
function LPS:GetThemeAccentItems()
    local items = { { value = "default", text = L.THEME_COLOR_DEFAULT } }
    if LOCALIZED_CLASS_NAMES_MALE then
        local classes = {}
        for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
            if LPS:GetClassColor(token) and not LPS:IsExcludedAccent(token, name) then
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
function LPS:ThemeLoad()
    local db = LPS:GetDB()
    local ui = db and db.uiOptions
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
    local r, g, b = LPS:GetThemeAccentColor()
    if r then
        C.accent = { r, g, b, 1 }
        C.primaryBorder = C.accent
    end
    Theme.C = C
end
function LPS:ThemeGet()
    if not Theme.C then LPS:ThemeLoad() end
    return Theme.T, Theme.C
end

function LPS:GetThemeKey()
    return Theme.key
end

function LPS:GetThemeOrder()
    return Theme.ORDER
end

function LPS:GetThemeArt()
    return Theme.ART
end
local listeners = {}
function LPS:ThemeOnChange(fn)
    listeners[#listeners + 1] = fn
end
function LPS:ThemeSet(key)
    if not Theme.THEMES[key] then return end
    local db = LPS:GetDB()
    if not db then return end
    db.uiOptions = db.uiOptions or {}
    db.uiOptions.theme = key
    LPS:ThemeLoad()
    for _, fn in ipairs(listeners) do
        local ok, err = pcall(fn, key)
        if not ok then
            geterrorhandler()(err)
        end
    end
end
function LPS:ThemeCycle()
    local current = Theme.key or "modern"
    for i, key in ipairs(Theme.ORDER) do
        if key == current then
            LPS:ThemeSet(Theme.ORDER[i % #Theme.ORDER + 1])
            return
        end
    end
    LPS:ThemeSet(Theme.ORDER[1])
end
local pendingFonts = {}
local retrying = false
function LPS:RedrawFontString(fs)
    local text = fs:GetText()
    if text then
        fs:SetText("")
        fs:SetText(text)
    end
end
function LPS:RetryThemeFonts()
    retrying = false
    for fs, req in pairs(pendingFonts) do
        req.tries = req.tries + 1
        if fs:SetFont(req.file, req.size, req.flags) or req.tries > 10 then
            pendingFonts[fs] = nil
        end
        LPS:RedrawFontString(fs)
    end
    if next(pendingFonts) then
        retrying = true
        C_Timer.After(0.3, function() LPS:RetryThemeFonts() end)
    end
end
function LPS:ThemeSetFont(fs, file, size, flags)
    flags = flags or ""
    if not file or LPS:UseGameFont() then
        fs:SetFont(STANDARD_TEXT_FONT, size, flags)
        return
    end
    if fs:SetFont(file, size, flags) then
        pendingFonts[fs] = nil
        LPS:RedrawFontString(fs)
        return
    end
    fs:SetFont(STANDARD_TEXT_FONT, size, flags)
    LPS:RedrawFontString(fs)
    pendingFonts[fs] = { file = file, size = size, flags = flags, tries = 0 }
    if not retrying then
        retrying = true
        C_Timer.After(0.3, function() LPS:RetryThemeFonts() end)
    end
end
function LPS:ThemeFontFor(role)
    local T = LPS:ThemeGet()
    return T.fonts and (T.fonts[role] or T.fonts.body) or nil
end
function LPS:ApplyThemeFont(fs, T)
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
    LPS:ThemeSetFont(fs, T.fonts[role] or T.fonts.body, math.floor(size + 0.5), flags)
    if role == "title" and fs.rawTitle then
        fs:SetText(T.uppercaseTitle and fs.rawTitle:upper() or fs.rawTitle)
    end
end
function LPS:ThemeApplyFonts(root)
    local T = LPS:ThemeGet()
    if not T.fonts or not root then return end
    for _, region in ipairs({ root:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "FontString" and not region.themeSkip then
            LPS:ApplyThemeFont(region, T)
        end
    end
    for _, child in ipairs({ root:GetChildren() }) do
        LPS:ThemeApplyFonts(child)
    end
end
function LPS:ThemeSetTitle(fs, text)
    fs.themeRole = "title"
    fs.rawTitle = text
    local T = LPS:ThemeGet()
    fs:SetText(T.uppercaseTitle and text:upper() or text)
end
function LPS:ThemeShape(tex, radius)
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
function LPS:ThemeTint(tex, c, alpha)
    if not tex or not c then return end
    tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
end
function LPS:ThemeBox(frame, fillKey, borderKey, radius, sublevel)
    local _, C = LPS:ThemeGet()
    local base = sublevel or 0
    local edge = frame:CreateTexture(nil, "BACKGROUND", nil, base - 2)
    edge:SetAllPoints()
    local fill = frame:CreateTexture(nil, "BACKGROUND", nil, base - 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    LPS:ThemeShape(edge, radius)
    LPS:ThemeShape(fill, radius)
    LPS:ThemeTint(edge, C[borderKey or "border"])
    LPS:ThemeTint(fill, C[fillKey or "window"])
    frame.edge, frame.fill = edge, fill
    return fill, edge
end
function LPS:ThemeCornerFill(frame, colorKey, radius, layer, sublevel)
    local _, C = LPS:ThemeGet()
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
    LPS:ThemeShape(round, radius)
    LPS:ThemeTint(round, c)
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
function LPS:ThemeWindow(frame, headerHeight, noRing)
    local T, C = LPS:ThemeGet()
    LPS:ThemeBox(frame, "window", "border", T.windowRadius)
    if T.headerFill then
        local header = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(headerHeight - 1)
        LPS:ThemeShape(header, T.windowRadius)
        LPS:ThemeTint(header, C.header)
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
        LPS:ThemeShape(ring, T.windowRadius)
        LPS:ThemeTint(ring, C.line)
        local ringFill = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
        ringFill:SetPoint("TOPLEFT", ring, 1, -1)
        ringFill:SetPoint("BOTTOMRIGHT", ring, -1, 1)
        LPS:ThemeShape(ringFill, T.windowRadius)
        LPS:ThemeTint(ringFill, C.window)
    end
    frame.headerLine = line
end
function LPS:ThemeCloseButton(parent, size)
    return LPS:ThemeIconButton(parent, size, "icon_close")
end
function LPS:ThemeIconButton(parent, size, iconName)
    local _, C = LPS:ThemeGet()
    local T = Theme.T
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    local fill = LPS:ThemeBox(button, "button", "buttonBorder", T.buttonRadius)
    local icon = button:CreateTexture(nil, "ARTWORK")
    button.icon = icon
    icon:SetTexture(Theme.ART .. iconName)
    icon:SetSize(math.floor(size * 0.5 + 0.5), math.floor(size * 0.5 + 0.5))
    icon:SetPoint("CENTER")
    LPS:ThemeTint(icon, C.muted)
    button:SetScript("OnEnter", function()
        LPS:ThemeTint(fill, Theme.C.buttonHover)
        LPS:ThemeTint(icon, Theme.C.text)
    end)
    button:SetScript("OnLeave", function()
        LPS:ThemeTint(fill, Theme.C.button)
        LPS:ThemeTint(icon, Theme.C.muted)
    end)
    return button
end
