local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local ROW_HEIGHT = 22
local ROW_GAP = 6

--- Отображаемое имя профиля (Default переводится локалью).
function LPS:GetProfileDisplayName(name)
    if name == "Default" then
        return LPS.L.PROFILE_DEFAULT or "Default"
    end
    return name
end

function LPS:SetButtonEnabled(btn, enabled)
    if enabled then
        btn:Enable()
        LPS:ApplyFontColor(btn.text, "textMuted")
    else
        btn:Disable()
        btn.text:SetTextColor(0.4, 0.4, 0.4)
    end
end

--- Список имён профилей из собственной БД (core.lua, без Ace3).
function LPS:GetProfileList()
    if LPS.SVGetProfilesList then
        return LPS:SVGetProfilesList()
    end
    return {}
end

--- Уникальное имя на основе base ("New Profile 2", "New Profile 3", ...).
function LPS:BuildUniqueProfileName(base)
    local taken = {}
    for _, name in ipairs(LPS:GetProfileList()) do
        taken[name:lower()] = true
    end
    local candidate = base
    local i = 2
    while taken[candidate:lower()] do
        candidate = base .. " " .. i
        i = i + 1
    end
    return candidate
end

--- Строка с подписью слева и дропдауном справа (как в исходном аддоне).
function LPS:CreateProfileDropdownRow(parent, labelText, y)
    
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    row:SetHeight(ROW_HEIGHT)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    LPS:ApplyFontColor(label, "textMuted")
    local _, dropdown = LPS:CreateDropdown(row, "", 150, { fixedWidth = true })
    dropdown:ClearAllPoints()
    dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
    dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    dropdown:SetHeight(ROW_HEIGHT)
    return row, label, dropdown
end

--- Создание страницы; вызывается из Panel.GetPageFrame (container — фрейм-родитель).
function LPS:CreateProfilesPanelPage(container)
    
    
    local L = LPS.L
    local page = {}
    local _, content = LPS:PanelCreateScrollPage(container)

    local y = -4
    local header = LPS:CreateSectionHeader(content, L.HEADER_PROFILES or "Profiles")
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    y = y - 18 - ROW_GAP

    local _, profileLabel, profileDrop = LPS:CreateProfileDropdownRow(content, L.LABEL_ACTIVE_PROFILE or "Active Profile", y)
    y = y - ROW_HEIGHT - ROW_GAP

    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    buttonRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    local BTN_GAP = 6
    local newBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_NEW or "New")
    local copyBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_COPY or "Copy")
    local deleteBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_DELETE or "Delete")
    local resetBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.RESET_PROFILE or "Reset profile")
    local importBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_IMPORT or "Import")
    local exportBtn = LPS:CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_EXPORT or "Export")
    local buttons = { newBtn, copyBtn, deleteBtn, resetBtn, importBtn, exportBtn }
    local btnRows = math.ceil(#buttons / 2)
    buttonRow:SetHeight(ROW_HEIGHT * btnRows + BTN_GAP * (btnRows - 1))
    --- Одинаковая ширина кнопок (по самой длинной подписи): в сетке 2×2
    --- соседние кнопки получают гарантированный зазор и не перекрываются.
    function page:SizeButtons()
        local textMax = 0
        for _, btn in ipairs(buttons) do
            if btn.text then
                local tw = btn.text:GetStringWidth() or 0
                if tw > textMax then textMax = tw end
            end
        end
        local width = math.max(80, textMax + BTN_GAP * 4)
        for _, btn in ipairs(buttons) do
            btn:SetWidth(width)
        end
    end
    --- Раскладка сетки 2×2: две кнопки в строке, строки по центру.
    function page:LayoutButtons()
        self:SizeButtons()
        local pairW = buttons[1]:GetWidth() * 2 + BTN_GAP
        for i, btn in ipairs(buttons) do
            local row = math.floor((i - 1) / 2)
            local col = (i - 1) % 2
            btn:ClearAllPoints()
            local yOff = -ROW_HEIGHT / 2 - row * (ROW_HEIGHT + BTN_GAP)
            if col == 0 then
                btn:SetPoint("LEFT", buttonRow, "TOP", -pairW / 2, yOff)
            else
                btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", BTN_GAP, 0)
            end
        end
    end
    page._buttonRow = buttonRow
    y = y - (ROW_HEIGHT * btnRows + BTN_GAP * (btnRows - 1)) - 8

    content:SetHeight(math.abs(y) + 8)
    page.scroll = content:GetParent()
    page.height = math.abs(y) + 8
    page:LayoutButtons()

    --- Обновление списка профилей и состояния элементов.
    function page:Refresh()
        local items = {}
        for _, name in ipairs(LPS:GetProfileList()) do
            items[#items + 1] = { value = name, text = LPS:GetProfileDisplayName(name) }
        end
        local active = LPS:SVGetCurrentProfile() or "Default"
        profileDrop:SetItems(items)
        profileDrop:SetValue(active, LPS:GetProfileDisplayName(active))
        local canDelete = false
        for _, item in ipairs(items) do
            if item.value ~= "Default" then canDelete = true break end
        end
        LPS:SetButtonEnabled(deleteBtn, canDelete)
        self:LayoutButtons()
    end

    profileDrop:SetOnChange(function(value)
        if value and LPS.db then
            LPS:SVSetProfile(value)
        end
        if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
        LPS:PanelRefreshActivePage()
        page:Refresh()
    end)

    newBtn:SetScript("OnClick", function()
        LPS:CreateInputPopup(
            L.POPUP_NEW_PROFILE_TITLE or "New Profile",
            L.POPUP_NEW_PROFILE_DESC or "Enter a name for the new profile.",
            LPS:BuildUniqueProfileName(L.PROFILE_NEW_BASE or "New Profile"),
            function(name)
                if type(name) ~= "string" or name == "" then return false end
                if LPS.sv.profiles[name] ~= nil then return false end
                LPS.sv.profiles[name] = {}
                LPS:SVSetProfile(name)
                LPS:PanelRefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    copyBtn:SetScript("OnClick", function()
        local source = LPS:SVGetCurrentProfile() or "Default"
        LPS:CreateInputPopup(
            L.POPUP_COPY_PROFILE_TITLE or "Copy Profile",
            L.POPUP_COPY_PROFILE_DESC or "Copy the current profile to a new one.",
            LPS:BuildUniqueProfileName(string.format(L.PROFILE_COPY_BASE or "Copy of %s", LPS:GetProfileDisplayName(source))),
            function(name)
                if type(name) ~= "string" or name == "" or name == source then return false end
                if LPS.sv.profiles[name] ~= nil then return false end
                LPS.sv.profiles[name] = {}
                LPS:SVSetProfile(name)
                LPS:SVCopyProfileFrom(source)
                LPS:PanelRefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    deleteBtn:SetScript("OnClick", function()
        local deletable = {}
        for _, name in ipairs(LPS:GetProfileList()) do
            if name ~= "Default" then
                deletable[#deletable + 1] = { value = name, text = LPS:GetProfileDisplayName(name) }
            end
        end
        if #deletable == 0 then
            LPS:CreatePopup(
                L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
                L.POPUP_DELETE_NONE or "No profiles to delete.",
                nil,
                L.BTN_OK or "OK",
                nil
            )
            return
        end
        LPS:CreateSelectPopup(
            L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
            L.POPUP_DELETE_SELECT or "Select a profile to delete:",
            deletable,
            deletable[1].value,
            function(name)
                if not name or name == "Default" then return false end
                if LPS.sv.profiles[name] == nil then return false end
                LPS:SVDeleteProfile(name)
                LPS:PanelRefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_DELETE or "Delete",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    resetBtn:SetScript("OnClick", function()
        LPS:CreatePopup(
            L.POPUP_RESET_PROFILE_TITLE or "Reset Profile",
            L.POPUP_RESET_PROFILE_DESC or "Reset the current profile to default values?",
            function()
                LPS:SVResetProfile()
                if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
                LPS:PanelRefreshActivePage()
                page:Refresh()
            end,
            L.BTN_RESET or "Reset",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    importBtn:SetScript("OnClick", function()
        LPS.ShowImportProfilePopup()
    end)

    exportBtn:SetScript("OnClick", function()
        LPS.ShowExportProfilePopup()
    end)

    return page
end
