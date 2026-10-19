local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--- Вспомогательные функции и значения для дерева настроек (Game/options.lua).
LPS.OptionsHelper = {}
local OH = LPS.OptionsHelper

local AceConfig, AceDialog, AceConfigRegistry, AceSerializer, LibDeflate, AceGUI
if LibStub and LibStub:GetLibrary("AceConfig-3.0", true) and LibStub:GetLibrary("AceConfigDialog-3.0", true) then
    AceConfig = LibStub("AceConfig-3.0")
    AceDialog = LibStub("AceConfigDialog-3.0")
    AceConfigRegistry = LibStub:GetLibrary("AceConfigRegistry-3.0", true)
    AceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
    LibDeflate = LibStub:GetLibrary("LibDeflate", true)
    AceGUI = LibStub:GetLibrary("AceGUI-3.0", true)
end

OH.Ace = {
    Config = AceConfig,
    Dialog = AceDialog,
    Registry = AceConfigRegistry,
    Serializer = AceSerializer,
    Deflate = LibDeflate,
    GUI = AceGUI,
}
OH.PROFILE_EXPORT_PREFIX = "!LPS1!"

--- Глубокая копия таблицы.
function OH:deepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k2, v2 in pairs(v) do
        out[self:deepCopy(k2)] = self:deepCopy(v2)
    end
    return out
end

--- Текущий профиль БД (или пустая таблица).
function OH:getDb()
    return LPS:GetDB() or {}
end

--- Занят ли слот панели side N значением, отличным от none.
function OH:slotIsFilled(side, n)
    local ss = self:getDb().layout and self:getDb().layout.sideSlots
    local s = ss and ss[side .. n]
    if not s then return false end
    local v = s.frame
    return v ~= nil and v ~= "" and v ~= "NONE" and v ~= "None" and v ~= "none"
end

--- Функция disabled для каскада слотов: слот N активен только при заполненном N-1.
function OH:makeSlotDisabledFunc(side, n)
    return function()
        if n == 2 then
            return not self:slotIsFilled(side, 1)
        elseif n == 3 then
            return not self:slotIsFilled(side, 1) or not self:slotIsFilled(side, 2)
        end
        return false
    end
end

--- При выборе «none» в слоте N очищает нижележащие слоты этой же стороны.
function OH:cascadeClearSlots(ss, side, n)
    if not ss then return end
    for i = n + 1, 3 do
        local other = ss[side .. i]
        if type(other) == "table" then other.frame = "NONE" end
    end
end

--- Дополнительные настройки конкретных панелей для автогенерации Panel Options.
local PANEL_EXTRA = {
    bags = {
        display = {
            order = 3,
            name = LPS:L("Value format"),
            desc = LPS:L("Choose how the value is shown on the panel."),
            values = {
                USED_TOTAL = LPS:L("Used / Total"),
                FREE = LPS:L("Free slots"),
                USED = LPS:L("Used slots"),
            },
        },
    },
    experience = {
        display = {
            order = 3,
            name = LPS:L("Value format"),
            desc = LPS:L("Choose how the value is shown on the panel."),
            values = {
                PERCENT = LPS:L("Percent"),
                CURMAX = LPS:L("Current / Max"),
                CUR = LPS:L("Current"),
                REM = LPS:L("Remaining"),
            },
        },
    },
    friends = { maxLimit = true },
    guild = { maxLimit = true },
}
OH.PANEL_EXTRA = PANEL_EXTRA

--- Инлайн-группа настроек одной панели (tooltip/display/maxLimit/label).
function OH:makePanelOptionGroup(key, def, order)
    local args = {}
    local extra = PANEL_EXTRA[key]
    if extra then
        if extra.display then
            args.display = {
                order = extra.display.order - 2,
                type = "select",
                name = extra.display.name,
                desc = extra.display.desc,
                values = extra.display.values,
                get = function(info)
                    local p = self:getDb().panels and self:getDb().panels[info[#info]]
                    return (p and p.display) or next(extra.display.values)
                end,
                set = function(info, v)
                    local k = info[#info]
                    local db = self:getDb()
                    db.panels = db.panels or {}
                    local p = db.panels[k]
                    if type(p) ~= "table" then
                        p = {}
                        db.panels[k] = p
                    end
                    p.display = v
                    LPS.Options:ApplyRefresh()
                end,
            }
        end
        if extra.maxLimit then
            args.maxLimit = {
                order = 2,
                type = "range",
                name = LPS:L("Max entries in tooltip"),
                desc = LPS:L("Limit how many entries are shown in this list."),
                min = 1,
                max = 30,
                step = 1,
                get = function(info)
                    local p = self:getDb().panels and self:getDb().panels[info[#info]]
                    return (p and tonumber(p.maxLimit)) or 15
                end,
                set = function(info, v)
                    local k = info[#info]
                    local db = self:getDb()
                    db.panels = db.panels or {}
                    local p = db.panels[k]
                    if type(p) ~= "table" then
                        p = {}
                        db.panels[k] = p
                    end
                    p.maxLimit = math.floor(v)
                end,
            }
        end
    end
    if key == "bags" then
        args.noLabel = {
            order = 5,
            type = "toggle",
            name = LPS:L("Hide label"),
            width = "half",
            get = function()
                local p = self:getDb().panels and self:getDb().panels.bags
                return p and p.noLabel or false
            end,
            set = function(_, v)
                local db = self:getDb()
                db.panels = db.panels or {}
                local p = db.panels.bags
                if type(p) ~= "table" then p = {}; db.panels.bags = p end
                p.noLabel = v and true or false
                LPS.Options:ApplyRefresh()
            end,
        }
        args.label = {
            order = 6,
            type = "input",
            name = LPS:L("Custom label"),
            width = "half",
            disabled = function()
                local p = self:getDb().panels and self:getDb().panels.bags
                return p and p.noLabel or false
            end,
            get = function()
                local p = self:getDb().panels and self:getDb().panels.bags
                return (p and p.label) or ""
            end,
            set = function(_, v)
                local db = self:getDb()
                db.panels = db.panels or {}
                local p = db.panels.bags
                if type(p) ~= "table" then p = {}; db.panels.bags = p end
                p.label = v or ""
                LPS.Options:ApplyRefresh()
            end,
        }
    end
    return {
        order = order,
        type = "group",
        inline = true,
        name = LPS:GetDatatextDisplayName(key),
        args = args,
    }
end

--- Значения выпадающего списка Display Other Values.
function OH:getDisplayOtherValues()
    local t = {
        ["NONE"] = LPS:L("None"),
        ["RLEVEL"] = LPS.icons.Level .. " " .. LPS:L("Level range"),
    }
    if not LPS.Retail and not LPS.Mists then
        t["PFISH"] = LPS.icons.Fish .. " " .. LPS:L("Fishing")
    end
    if LPS.Retail or LPS.Mists then
        t["PET"] = LPS.icons.Pet .. " " .. LPS:L("Battle pets")
    end
    return t
end

--- Список значений frame strata.
function OH:strataValues()
    return {
        ["BACKGROUND"] = "BACKGROUND",
        ["LOW"] = "LOW",
        ["MEDIUM"] = "MEDIUM",
        ["HIGH"] = "HIGH",
        ["DIALOG"] = "DIALOG",
        ["TOOLTIP"] = "TOOLTIP",
    }
end

--- Список значений флага шрифта.
function OH:fontFlagValues()
    return {
        ["NONE"] = LPS:L("None"),
        ["OUTLINE"] = "OUTLINE",
        ["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
        ["THICKOUTLINE"] = "THICKOUTLINE",
    }
end

--- Регистрация кастомных EditBox/MultiLineEditBox без кнопки ОК в AceGUI.
function OH:RegisterNoButtonWidgets()
    local GUI = self.Ace.GUI
    if not GUI then return end
    if (GUI:GetWidgetVersion("LPSEditBoxNoButton") or 0) < 2 then
        local baseCtor = GUI.WidgetRegistry and GUI.WidgetRegistry["EditBox"]
        if baseCtor then
            GUI:RegisterWidgetType("LPSEditBoxNoButton", function()
                local widget = baseCtor()
                widget.type = "LPSEditBoxNoButton"
                local baseOnAcquire = widget.OnAcquire
                widget.OnAcquire = function(self)
                    if baseOnAcquire then baseOnAcquire(self) end
                    if self.DisableButton then
                        self:DisableButton(true)
                    end
                end
                if widget.editbox and widget.GetUserData then
                    widget.editbox:HookScript("OnTextChanged", function(frame, userInput)
                        if not userInput then return end
                        local option = widget:GetUserData("option")
                        if option and type(option.set) == "function" then
                            option.set(nil, frame:GetText())
                        end
                    end)
                end
                return widget
            end, 2)
        end
    end
    if (GUI:GetWidgetVersion("LPSMultiLineEditBoxNoButton") or 0) < 2 then
        local baseCtor = GUI.WidgetRegistry and GUI.WidgetRegistry["MultiLineEditBox"]
        if baseCtor then
            GUI:RegisterWidgetType("LPSMultiLineEditBoxNoButton", function()
                local widget = baseCtor()
                widget.type = "LPSMultiLineEditBoxNoButton"
                local baseOnAcquire = widget.OnAcquire
                widget.OnAcquire = function(self)
                    if baseOnAcquire then baseOnAcquire(self) end
                    if self.DisableButton then
                        self:DisableButton(true)
                    end
                end
                if widget.editBox and widget.GetUserData then
                    widget.editBox:HookScript("OnTextChanged", function(frame, userInput)
                        if not userInput then return end
                        local option = widget:GetUserData("option")
                        if option and type(option.set) == "function" then
                            option.set(nil, frame:GetText())
                        end
                    end)
                end
                return widget
            end, 2)
        end
    end
end

--- Разрешает имя опции AceConfig (значение или функция).
function OH:resolveAceName(v)
    if type(v) == "function" then
        local ok, r = pcall(v)
        if ok and r ~= nil then
            return tostring(r)
        end
        return ""
    end
    return tostring(v or "")
end

--- Регистрирует группу как отдельную подкатегорию Blizzard-меню.
function OH:registerSubCategory(appName, suffix, group)
    if type(group) ~= "table" then return end
    if not (self.Ace.Config and self.Ace.Dialog) then return end
    local displayName = self:resolveAceName(group.name)
    if displayName == "" then
        displayName = suffix
    end
    self.Ace.Config:RegisterOptionsTable(appName .. suffix, group)
    self.Ace.Dialog:AddToBlizOptions(appName .. suffix, displayName, LPS.addon.title)
end
