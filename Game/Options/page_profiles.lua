local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

---------------------------------------------------------------------------
-- Страница «Профили»: прямой порт PageProfiles.lua из CharacterStats.
-- Регистрируется в обход дерева настроек (см. Game/ui_options.lua):
-- заголовок секции, дропдаун активного профиля и ряд кнопок
-- New / Copy / Delete / Reset с попапами виджетов.
-- Секция профилей специализаций не портируется: у этого аддона профили
-- привязаны только к персонажу (profileKeys в SavedVariables).
---------------------------------------------------------------------------
local ROW_HEIGHT = 22
local ROW_GAP = 6

--- Отображаемое имя профиля (Default переводится локалью).
local function DisplayName(name)
    if name == "Default" then
        return LPS.L.PROFILE_DEFAULT or "Default"
    end
    return name
end

local function SetButtonEnabled(btn, enabled)
    if enabled then
        btn:Enable()
        LPS.UI.Widgets.ApplyFontColor(btn.text, "textMuted")
    else
        btn:Disable()
        btn.text:SetTextColor(0.4, 0.4, 0.4)
    end
end

--- Список имён профилей из собственной БД (core.lua, без Ace3).
local function GetProfileList()
    local db = LPS.db
    if db and db.GetProfilesList then return db:GetProfilesList() end
    return {}
end

--- Уникальное имя на основе base ("New Profile 2", "New Profile 3", ...).
local function BuildUniqueName(base)
    local taken = {}
    for _, name in ipairs(GetProfileList()) do
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
local function CreateDropdownRow(parent, labelText, y)
    local Widgets = LPS.UI.Widgets
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    row:SetHeight(ROW_HEIGHT)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetPoint("RIGHT", row, "CENTER", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    Widgets.ApplyFontColor(label, "textMuted")
    local _, dropdown = Widgets.CreateDropdown(row, "", 150, { fixedWidth = true })
    dropdown:ClearAllPoints()
    dropdown:SetPoint("LEFT", row, "CENTER", 8, 0)
    dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    dropdown:SetHeight(ROW_HEIGHT)
    return row, label, dropdown
end

--- Создание страницы; вызывается из Panel.GetPageFrame (container — фрейм-родитель).
function LPS.CreateProfilesPanelPage(container)
    local Widgets = LPS.UI.Widgets
    local Panel = LPS.UI.Panel
    local L = LPS.L
    local page = {}
    local _, content = Panel.CreateScrollPage(container)

    local y = -4
    local header = Widgets.CreateSectionHeader(content, L.HEADER_PROFILES or "Profiles")
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    y = y - 18 - ROW_GAP

    local _, profileLabel, profileDrop = CreateDropdownRow(content, L.LABEL_ACTIVE_PROFILE or "Active Profile", y)
    y = y - ROW_HEIGHT - ROW_GAP

    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
    buttonRow:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    buttonRow:SetHeight(ROW_HEIGHT)
    local newBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_NEW or "New")
    local copyBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_COPY or "Copy")
    local deleteBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.BTN_DELETE or "Delete")
    local resetBtn = Widgets.CreateFlatButton(buttonRow, 80, ROW_HEIGHT, L.RESET_PROFILE or "Reset profile")
    local buttons = { newBtn, copyBtn, deleteBtn, resetBtn }
    Widgets.NormalizeButtonWidths(buttons, 10)
    for i, btn in ipairs(buttons) do
        if i == 1 then
            btn:SetPoint("LEFT", buttonRow, "CENTER", 8, 0)
        else
            btn:SetPoint("LEFT", buttons[i - 1], "RIGHT", 6, 0)
        end
    end
    y = y - ROW_HEIGHT - 8

    content:SetHeight(math.abs(y) + 8)
    page.scroll = content:GetParent()
    page.height = math.abs(y) + 8

    --- Обновление списка профилей и состояния элементов.
    function page:Refresh()
        local items = {}
        for _, name in ipairs(GetProfileList()) do
            items[#items + 1] = { value = name, text = DisplayName(name) }
        end
        local active = (LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()) or "Default"
        profileDrop:SetItems(items)
        profileDrop:SetValue(active, DisplayName(active))
        -- Default и текущий профиль нельзя удалить
        local canDelete = false
        for _, item in ipairs(items) do
            if item.value ~= "Default" then canDelete = true break end
        end
        SetButtonEnabled(deleteBtn, canDelete)
    end

    profileDrop:SetOnChange(function(value)
        if value and LPS.db and LPS.db.SetProfile then
            LPS.db:SetProfile(value)
        end
        if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
        Panel.RefreshActivePage()
        page:Refresh()
    end)

    newBtn:SetScript("OnClick", function()
        Widgets.CreateInputPopup(
            L.POPUP_NEW_PROFILE_TITLE or "New Profile",
            L.POPUP_NEW_PROFILE_DESC or "Enter a name for the new profile.",
            BuildUniqueName(L.PROFILE_NEW_BASE or "New Profile"),
            function(name)
                if type(name) ~= "string" or name == "" then return false end
                if not LPS.db or not LPS.db.SetProfile then return false end
                -- создание через SetProfile: несуществующий профиль создаётся пустым
                LPS.sv.profiles[name] = {}
                LPS.db:SetProfile(name)
                Panel.RefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    copyBtn:SetScript("OnClick", function()
        local source = (LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()) or "Default"
        Widgets.CreateInputPopup(
            L.POPUP_COPY_PROFILE_TITLE or "Copy Profile",
            L.POPUP_COPY_PROFILE_DESC or "Copy the current profile to a new one.",
            BuildUniqueName(string.format(L.PROFILE_COPY_BASE or "Copy of %s", DisplayName(source))),
            function(name)
                if type(name) ~= "string" or name == "" or name == source then return false end
                if not (LPS.db and LPS.db.CopyProfileFrom) then return false end
                -- копируем src в новый профиль: временно переключаемся, затем обратно
                LPS.sv.profiles[name] = {}
                LPS.db:SetProfile(name)
                LPS.db:CopyProfileFrom(source)
                LPS.db:SetProfile(source)
                Panel.RefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_OK or "OK",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    deleteBtn:SetScript("OnClick", function()
        local deletable = {}
        for _, name in ipairs(GetProfileList()) do
            if name ~= "Default" then
                deletable[#deletable + 1] = { value = name, text = DisplayName(name) }
            end
        end
        if #deletable == 0 then
            Widgets.CreatePopup(
                L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
                L.POPUP_DELETE_NONE or "No profiles to delete.",
                nil,
                L.BTN_OK or "OK",
                nil
            )
            return
        end
        Widgets.CreateSelectPopup(
            L.POPUP_DELETE_PROFILE_TITLE or "Delete Profile",
            L.POPUP_DELETE_SELECT or "Select a profile to delete:",
            deletable,
            deletable[1].value,
            function(name)
                if not name or name == "Default" then return false end
                if not (LPS.db and LPS.db.DeleteProfile) then return false end
                LPS.db:DeleteProfile(name)
                Panel.RefreshActivePage()
                page:Refresh()
                return true
            end,
            L.BTN_DELETE or "Delete",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    resetBtn:SetScript("OnClick", function()
        Widgets.CreatePopup(
            L.POPUP_RESET_PROFILE_TITLE or "Reset Profile",
            L.POPUP_RESET_PROFILE_DESC or "Reset the current profile to default values?",
            function()
                if LPS.db and LPS.db.ResetProfile then
                    LPS.db:ResetProfile()
                end
                if LPS.RefreshAfterProfileChange then LPS:RefreshAfterProfileChange() end
                Panel.RefreshActivePage()
                page:Refresh()
            end,
            L.BTN_RESET or "Reset",
            L.BTN_CANCEL or "Cancel"
        )
    end)

    return page
end
