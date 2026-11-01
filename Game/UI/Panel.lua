local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L
--- Каркас нативного окна настроек: заголовок, навигация, страницы (порт ConfigPanel).
local MIN_WIDTH = 560
local MIN_HEIGHT = 420
local DEFAULT_WIDTH = 640
local DEFAULT_HEIGHT = 520
local NAV_WIDTH = 140
local TITLE_HEIGHT = 32
local CONTENT_PAD = 14
local WINDOW_PAGE = "window"
local frame
local pages = {}
local pageOrder = {}
function LPS:RegisterPanelPage(key, def)
    def.key = key
    pages[key] = def
    pageOrder[#pageOrder + 1] = def
    table.sort(pageOrder, function(a, b)
        return (a.order or 99) < (b.order or 99)
    end)
end
--- Применяет изменённую настройку и обновляет активную страницу.
function LPS:PanelOnSettingChanged()
    if LPS.ApplyOptionsRefresh then
        LPS:ApplyOptionsRefresh()
    end
    LPS:PanelRefreshActivePage()
end
function LPS:PanelRefreshTheme()
    if frame and frame.navButtons then
        for _, btn in pairs(frame.navButtons) do
            btn:RefreshTheme()
        end
    end
end
function LPS:PanelCreateScrollPage(container)
    local scroll = LPS:CreateScrollFrame(container)
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    local width = frame and frame.content and frame.content:GetWidth()
    if width and width > 1 then
        scroll.content:SetWidth(width)
    end
    return scroll, scroll.content
end
--- Пересинхронизация геометрии скролл-контента всех созданных страниц.
--- Вызывается при изменении размера окна и при его показе: если страница
--- была построена, когда фрейм имел нулевой/единичный размер, строки
--- остались бы невидимыми (пустые вкладки).
function LPS:PanelSyncPagesGeometry()
    if not frame or not frame.pageFrames then return end
    for _, container in pairs(frame.pageFrames) do
        local page = container.page
        local scroll = page and page.scroll
        if scroll and scroll.content then
            local w = scroll:GetWidth()
            if w and w > 1 then
                scroll.content:SetWidth(w)
            end
            local h = tonumber(page.height)
            if h and h > 0 and scroll.SetContentHeight then
                scroll:SetContentHeight(h)
            end
        end
    end
end
function LPS:PanelSaveFrameSize()
    local db = LPS:GetDB()
    if not db then return end
    db.uiOptions = db.uiOptions or {}
    db.uiOptions.width = frame:GetWidth()
    db.uiOptions.height = frame:GetHeight()
end

--- Значение по умолчанию для dropdown'а акцента: "default" = цвет текущего
--- класса игрока; если сохранён класс, недоступный в этой игре (например,
--- Evoker в Classic) — считаем значение невалидным и показываем "default".
function LPS:GetValidAccentValue()
    local db = LPS:GetDB()
    local ui = db and db.uiOptions
    local v = ui and ui.themeColor
    if not v or v == "default" then return "default" end
    for _, item in ipairs(LPS.LPS:GetThemeAccentItems()) do
        if item.value == v then return v end
    end
    return "default"
end

--- Строки внутренней страницы «Настройка окна»: тема окна, цвета акцента,
--- свой цвет фона окна и масштаб. Раньше это была отдельная вкладка
--- «Внешний вид» (Game/Options/appearance.lua) — теперь только эта страница
--- под кнопкой-шестерёнкой в заголовке.
function LPS:BuildWindowEntries(L)
    local function UIOpts()
        local db = LPS:GetDB()
        db.uiOptions = db.uiOptions or {}
        return db.uiOptions
    end
    local function ApplyTheme()
        LPS:PanelRefreshTheme()
        if LPS.ApplyOptionsRefresh then
            LPS:ApplyOptionsRefresh()
        end
    end
    return {
        { kind = "header", label = L.THEME },
        {
            kind = "dropdown", key = "uiTheme", label = L.THEME_STYLE,
            tooltip = L.THEME_STYLE_DESC,
            items = function()
                local items = {}
                for _, key in ipairs(LPS:GetThemeOrder()) do
                    items[#items + 1] = { value = key, text = LPS:GetThemeName(key) }
                end
                return items
            end,
            get = function() return LPS:ThemeGet() and LPS:GetThemeKey() end,
            set = function() end,
            onChange = function(value)
                LPS:ThemeSet(value)
            end,
        },
                    { kind = "header", label = L.THEME_COLOR },
                    {
                        kind = "dropdown", key = "themeColor", label = L.THEME_COLOR,
                        tooltip = L.THEME_COLOR_DESC,
                        items = function() return LPS:GetThemeAccentItems() end,
                        get = function() return LPS:GetValidAccentValue() end,
                        set = function(v) UIOpts().themeColor = v end,
                        onChange = ApplyTheme,
                    },
                            { kind = "header", label = L.SIZE_AND_SCALE },
                            {
                                kind = "slider", key = "uiScale", label = L.WINDOW_SCALE,
                                tooltip = L.WINDOW_SCALE_DESC,
                                min = 0.5, max = 1.5, step = 0.05, format = "%.2f",
                                commitOnRelease = true,
                                get = function()
                                    local db = LPS:GetDB()
                                    local ui = db and db.uiOptions
                                    return (ui and tonumber(ui.scale)) or 1.0
                                end,
                                set = function() end,
                                onChange = function(value)
                                    LPS:PanelSetWindowScale(value)
                                end,
                            },
                                        {
                                            kind = "button", key = "resetAppearance", label = L.RESET_APPEARANCE,
                                            tooltip = L.RESET_APPEARANCE_DESC,
                                            func = function()
                                                local ui = UIOpts()
                                                ui.theme = nil
                                                ui.themeColor = nil
                                                ui.scale = 1.0
                                                LPS:ThemeSet("modern")
                                                LPS:PanelSetWindowScale(1.0)
                                                ApplyTheme()
                                                LPS:PanelRefreshActivePage()
                                            end,
                                        },
    }
end

--- Регистрация внутренней страницы window (вне pageOrder — в навигации её нет).
pages[WINDOW_PAGE] = {
    key = WINDOW_PAGE,
    create = function(container)
        local _, content = LPS:PanelCreateScrollPage(container)
        local page = LPS:BuildOptionPage(content, LPS:BuildWindowEntries(L), {
            onChange = function()
                LPS:PanelOnSettingChanged()
            end,
        })
        content:SetHeight(page.height)
        return page
    end,
}

--- Кнопка шестерёнки: переключает страницу «Настройка окна» (порт ToggleWindowSettings).
function LPS:PanelToggleWindowSettings()
    if not frame then return end
    if frame._minimized then
        LPS:PanelSetMinimized(false)
    end
    if frame._activePage == WINDOW_PAGE then
        LPS:PanelShowPage(frame._lastAddonPage or (pageOrder[1] and pageOrder[1].key))
    else
        LPS:PanelShowPage(WINDOW_PAGE)
    end
end
function LPS:CreateCircleButton(parent, iconName, isClose)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(20, 20)
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
    btn.mask = btn:CreateMaskTexture()
    btn.mask:SetAllPoints(btn.bg)
    btn.mask:SetTexture("Interface\\Masks\\CircleMaskScalable", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    btn.bg:AddMaskTexture(btn.mask)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetTexture(LPS:GetThemeArt() .. iconName)
    btn.icon:SetSize(10, 10)
    btn.icon:SetPoint("CENTER")
    btn.icon:SetVertexColor(0.8, 0.8, 0.8)
    btn:SetScript("OnEnter", function(self)
        if isClose then
            self.bg:SetColorTexture(0.5, 0.1, 0.1, 1)
        else
            self.bg:SetColorTexture(0.3, 0.3, 0.3, 1)
        end
        self.icon:SetVertexColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        self.icon:SetVertexColor(0.8, 0.8, 0.8)
    end)
    return btn
end
function LPS:CreateMainFrame()
    local themeKey = LPS:ThemeGet() and LPS:GetThemeKey()
    if frame and frame.themeKey == themeKey then
        return frame
    end
    if frame then
        frame:Hide()
    end
    frame = CreateFrame("Frame", "ArpeksLPSConfigFrame", UIParent)
    frame.themeKey = themeKey
    local savedUi = LPS:GetDB() and LPS:GetDB().uiOptions
    local savedWidth = savedUi and tonumber(savedUi.width)
    local savedHeight = savedUi and tonumber(savedUi.height)
    frame:SetSize(math.max(savedWidth or DEFAULT_WIDTH, MIN_WIDTH), math.max(savedHeight or DEFAULT_HEIGHT, MIN_HEIGHT))
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    end
    frame:Hide()
    LPS:ThemeWindow(frame, TITLE_HEIGHT + 1, true)
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.titleBar:SetHeight(TITLE_HEIGHT)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    frame.logo = frame.titleBar:CreateTexture(nil, "OVERLAY")
    frame.logo:SetSize(20, 20)
    frame.logo:SetPoint("LEFT", frame.titleBar, "LEFT", 10, 0)
    frame.logo:SetTexture(LPS.icons.PathLogoModern)
    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", frame.logo, "RIGHT", 8, 0)
    LPS:ThemeSetTitle(frame.title, LPS.addon.title or "Location Plus")
    LPS:ApplyFontColor(frame.title, "title")
    frame.version = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.version:SetPoint("LEFT", frame.title, "RIGHT", 8, -1)
    frame.version:SetText("v" .. tostring(LPS.addon.version or ""))
    LPS:ApplyFontColor(frame.version, "textMuted", 0.7)
    if LPS:GetThemeKey() == "classic" then
        frame.closeBtn = LPS:CreateCircleButton(frame.titleBar, "icon_close", true)
    else
        frame.closeBtn = LPS:ThemeCloseButton(frame.titleBar, 22)
    end
    frame.closeBtn:SetPoint("RIGHT", frame.titleBar, "RIGHT", -8, 0)
    frame.closeBtn:SetScript("OnClick", function()
        LPS:PanelHide()
    end)

    if LPS:GetThemeKey() == "classic" then
        frame.minBtn = LPS:CreateCircleButton(frame.titleBar, "icon_minus")
    else
        frame.minBtn = LPS:ThemeIconButton(frame.titleBar, 22, "icon_minus")
    end
    frame.minBtn:SetPoint("RIGHT", frame.closeBtn, "LEFT", -6, 0)
    frame.minBtn:SetScript("OnClick", function()
        LPS:PanelSetMinimized(not frame._minimized)
    end)
    frame.minBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(frame._minimized and (L.EXPAND or "Expand") or (L.MINIMIZE or "Minimize"), 1, 1, 1)
        GameTooltip:Show()
    end)
    frame.minBtn:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    if LPS:GetThemeKey() == "classic" then
        frame.gearBtn = LPS:CreateCircleButton(frame.titleBar, "icon_gear")
        frame.gearBtn.icon:SetSize(12, 12)
    else
        frame.gearBtn = LPS:ThemeIconButton(frame.titleBar, 22, "icon_gear")
    end
    frame.gearBtn:SetPoint("RIGHT", frame.minBtn, "LEFT", -6, 0)
    frame.gearBtn:SetScript("OnClick", function()
        LPS:PanelToggleWindowSettings()
    end)
    frame.gearBtn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L.TIP_WINDOW_SETTINGS or "Window Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame.gearBtn:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.nav = CreateFrame("Frame", nil, frame)
    frame.nav:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 0, 0)
    frame.nav:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    frame.nav:SetWidth(NAV_WIDTH)
    LPS:ThemeCornerFill(frame.nav, "nav", (LPS:ThemeGet()).windowRadius)
    frame.nav.divider = frame.nav:CreateTexture(nil, "ARTWORK")
    frame.nav.divider:SetPoint("TOPRIGHT", frame.nav, "TOPRIGHT", 0, 0)
    frame.nav.divider:SetPoint("BOTTOMRIGHT", frame.nav, "BOTTOMRIGHT", 0, 0)
    frame.nav.divider:SetWidth(1)
    LPS:ApplyTextureColor(frame.nav.divider, "border", 1)
    frame.navButtons = {}
    local navY = -8
    for _, def in ipairs(pageOrder) do
        local btn = LPS:CreateNavButton(frame.nav, (def.labelKey and LPS.L[def.labelKey]) or def.label)
        btn:SetPoint("TOPLEFT", frame.nav, "TOPLEFT", 0, navY)
        btn:SetPoint("TOPRIGHT", frame.nav, "TOPRIGHT", -1, navY)
        btn:SetScript("OnClick", function()
            LPS:PanelShowPage(def.key)
        end)
        frame.navButtons[def.key] = btn
        navY = navY - 28
    end
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame.nav, "TOPRIGHT", CONTENT_PAD, -CONTENT_PAD)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PAD, CONTENT_PAD)
    frame.content:SetScript("OnSizeChanged", function()
        LPS:PanelSyncPagesGeometry()
    end)
    frame.pageFrames = {}
    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(16, 16)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.resizeHandle:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    frame.resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        LPS:PanelSaveFrameSize()
    end)
    tinsert(UISpecialFrames, "ArpeksLPSConfigFrame")
    frame:SetScript("OnHide", function()

    end)
    LPS:ThemeApplyFonts(frame)
    if LPS.DisableMoveModeIfActive then
        frame:HookScript("OnHide", function()
            LPS:DisableMoveModeIfActive()
        end)
    end
    return frame
end
function LPS:PanelOnThemeChanged()
    local current = frame
    if not current or not current:IsShown() then
        if current then
            current:Hide()
        end
        frame = nil
        return
    end
    local page = current._activePage
    local lastAddonPage = current._lastAddonPage
    local point, relativeTo, relativePoint, x, y = current:GetPoint(1)
    current:Hide()
    frame = nil
    LPS:PanelShow()
    if frame and point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
    end
    if page and pages[page] and frame._activePage ~= page then
        LPS:PanelShowPage(page)
        frame._lastAddonPage = lastAddonPage or frame._lastAddonPage
    end
end
function LPS:GetPageFrame(key)
    local container = frame.pageFrames[key]
    if container then return container end
    local def = pages[key]
    if not def then return nil end
    container = CreateFrame("Frame", nil, frame.content)
    container:SetAllPoints(frame.content)
    container:Hide()
    container.page = def.create(container) or {}
    LPS:ThemeApplyFonts(container)
    frame.pageFrames[key] = container
    return container
end
function LPS:PanelShowPage(key)
    if not frame or not pages[key] then return end
    for pageKey, container in pairs(frame.pageFrames) do
        if pageKey ~= key then
            container:Hide()
        end
    end
    for pageKey, btn in pairs(frame.navButtons) do
        btn:SetActive(pageKey == key)
    end
    local container = LPS:GetPageFrame(key)
    container:Show()
    LPS:PanelSyncPagesGeometry()
    if container.page.Refresh then
        container.page:Refresh()
    end
    frame._activePage = key
    if key ~= WINDOW_PAGE then
        frame._lastAddonPage = key
    end
end
function LPS:PanelRefreshActivePage()
    if not frame or not frame:IsShown() or not frame._activePage then return end
    local container = frame.pageFrames[frame._activePage]
    if container and container.page.Refresh then
        container.page:Refresh()
    end
end
function LPS:PanelGetFrame()
    return frame
end
function LPS:PinTopLeft()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return nil end
    local scale = frame:GetScale()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    return left * scale, top * scale
end
local SCALE_ANIM_TIME = 0.18
--- Плавно меняет масштаб окна и сохраняет значение в БД.
function LPS:PanelSetWindowScale(scale)
    if not frame or not scale then return end
    local db = LPS:GetDB()
    if db then
        db.uiOptions = db.uiOptions or {}
        db.uiOptions.scale = scale
    end
    local from = frame:GetScale()
    if math.abs(scale - from) < 0.001 then return end
    local screenLeft, screenTop = LPS:PinTopLeft()
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / SCALE_ANIM_TIME, 1)
        local eased = 1 - (1 - t) * (1 - t)
        local s = from + (scale - from) * eased
        self:SetScale(s)
        if screenLeft then
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", screenLeft / s, screenTop / s)
        end
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end
function LPS:PanelSetMinimized(on)
    if not frame then return end
    on = on and true or false
    if (frame._minimized or false) == on then return end
    LPS:PinTopLeft()
    frame._minimized = on
    frame.nav:SetShown(not on)
    frame.content:SetShown(not on)
    frame.resizeHandle:SetShown(not on)
    if on then
        frame._expandedHeight = frame:GetHeight()
        if frame.SetResizeBounds then
            frame:SetResizeBounds(MIN_WIDTH, TITLE_HEIGHT + 2)
        end
        frame:SetHeight(TITLE_HEIGHT + 2)
    else
        frame:SetHeight(math.max(frame._expandedHeight or DEFAULT_HEIGHT, MIN_HEIGHT))
        if frame.SetResizeBounds then
            frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
        end
    end
    frame.minBtn.icon:SetTexture(LPS:GetThemeArt() .. (on and "icon_chevron_down" or "icon_minus"))
end
function LPS:PanelOpen()
    LPS:PanelShow()
end
function LPS:PanelShow()
    if InCombatLockdown() then
        LPS:Print(L.CANNOT_OPEN_OPTIONS_DURING_COMBAT)
        return
    end
    LPS:CreateMainFrame()
    frame:SetScript("OnUpdate", nil)
    local db = LPS:GetDB()
    frame:SetScale((db and db.uiOptions and db.uiOptions.scale) or 1.0)
    LPS:PanelSetMinimized(false)
    frame:Show()
    LPS:PanelRefreshTheme()
    LPS:PanelShowPage(frame._activePage or (pageOrder[1] and pageOrder[1].key))
    LPS:PanelSyncPagesGeometry()
    LPS:PanelRefreshActivePage()
end
function LPS:PanelHide()
    if frame then
        frame:Hide()
    end
end
function LPS:PanelToggle()
    if frame and frame:IsShown() then
        LPS:PanelHide()
    else
        LPS:PanelShow()
    end
end
function LPS:PanelIsShown()
    return frame and frame:IsShown()
end
LPS:ThemeOnChange(LPS.PanelOnThemeChanged)
