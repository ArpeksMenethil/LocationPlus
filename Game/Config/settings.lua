local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Категория аддона в стандартном окне настроек: изображение, описание
--- и кнопка, открывающая окно настроек аддона (плюс подсказка про /lps).
--- На клиентах без Settings.* API категория не создаётся (тихо) —
--- настройки остаются доступны через /lps и ПКМ по кнопке на мини-карте.

function LPS:GetSettingsAddonTitle()
    return (LPS.addon.title and LPS.addon.title ~= "") and LPS.addon.title or "Location Plus"
end

function LPS:BuildSettingsCategoryFrame()
    if LPS.frame.settingsCategory then
        return LPS.frame.settingsCategory
    end

    local panel = CreateFrame("Frame", "LPS_SettingsCategory")
    panel.name = LPS:GetSettingsAddonTitle()

    local logo = panel:CreateTexture("ART")
    logo:SetSize(96, 96)
    logo:SetPoint("TOPLEFT", panel, "TOPLEFT", 48, -48)
    logo:SetTexture(LPS.icons.PathLogoModern)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    if type(title) ~= "table" or type(title.SetText) ~= "function" then
        error(("settings panel: CreateFontString returned %s (object: %s)")
            :format(tostring(title), title and title.GetObjectType and title:GetObjectType() or "?"), 0)
    end
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 24, 0)
    title:SetText(LPS:GetSettingsAddonTitle())

    local version = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    version:SetTextColor(0.6, 0.6, 0.6)
    version:SetText("v" .. tostring(LPS.addon.version))

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", logo, "BOTTOMRIGHT", 24, 0)
    desc:SetWidth(460)
    desc:SetText(LPS:GetAddonNotes())

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    hint:SetWidth(460)
    hint:SetTextColor(0.6, 0.6, 0.6)
    hint:SetText(L.SETTINGS_CMD_HINT)

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -14)
    btn:SetSize(180, 24)
    btn:SetText(L.SETTINGS_OPEN_BUTTON)
    btn:SetScript("OnClick", function()
        LPS:ToggleOptions()
    end)

    LPS.frame.settingsCategory = panel
    return panel
end

--- Регистрация категории аддона в настройках игры (нативный API:
--- RegisterCanvasLayoutCategory + RegisterAddOnCategory; для клиентов с
--- canvas-API — запасная сигнатура).
function LPS:RegisterSettingsCategory()
    if LPS.settingsCategory then
        return LPS.settingsCategory
    end
    if not (_G.Settings
        and type(_G.Settings.RegisterCanvasLayoutCategory) == "function"
        and type(_G.Settings.RegisterAddOnCategory) == "function") then
        return
    end
    local title = LPS:GetSettingsAddonTitle()
    local icon = LPS.icons and LPS.icons.PathLogo
    local panel = LPS:BuildSettingsCategoryFrame()
    panel:Hide()
    local ok, category = pcall(_G.Settings.RegisterCanvasLayoutCategory, panel, title)
    if not ok then
        ok, category = pcall(_G.Settings.RegisterCanvasLayoutCategory, title, function(canvas)
            canvas:SetFrameLevel(1)
            if type(canvas.CreateTitle) == "function" then
                canvas:CreateTitle(title)
            end
            panel:SetParent(canvas)
            panel:ClearAllPoints()
            panel:SetPoint("TOPLEFT", canvas, "TOPLEFT", 8, -26)
            panel:SetPoint("BOTTOMRIGHT", canvas, "BOTTOMRIGHT", -8, 8)
            return panel
        end, 100, icon)
    end
    if not ok then
        print("LocationPlus: settings category failed: " .. tostring(category))
        return
    end
    pcall(_G.Settings.RegisterAddOnCategory, category)
    LPS.settingsCategory = category
    return category
end
