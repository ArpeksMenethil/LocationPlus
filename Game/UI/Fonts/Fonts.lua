local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local fontLib

--- @return table|nil LibSharedMedia-3.0 (или nil, если библиотека недоступна;
--- неудача не кэшируется — повторный запрос при следующем обращении)
function LPS:GetFontLib()
    if type(fontLib) == "table" then return fontLib end
    if not LibStub or type(LibStub.GetLibrary) ~= "function" then return nil end
    local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibSharedMedia-3.0")
    if ok and type(lib) == "table" then
        fontLib = lib
        return lib
    end
    return nil
end

--- Зарегистрированные шрифты (LibSharedMedia: шрифты клиента + шрифты
--- других аддонов).
--- @return table<string, string> имя шрифта → файл
function LPS:GetRegisteredFonts()
    local fonts = {}
    local lib = LPS:GetFontLib()
    if lib and type(lib.List) == "function" and type(lib.Fetch) == "function" then
        local ok, names = pcall(lib.List, lib, "font")
        if ok and type(names) == "table" then
            for _, name in ipairs(names) do
                if type(name) == "string" then
                    local okF, file = pcall(lib.Fetch, lib, "font", name, true)
                    if okF and type(file) == "string" and file ~= "" then
                        fonts[name] = file
                    end
                end
            end
        end
    end
    return fonts
end

--- @return table<string> отсортированные по алфавиту имена зарегистрированных шрифтов
local function GetSortedFontNames()
    local fonts = LPS:GetRegisteredFonts()
    local names = {}
    for name in pairs(fonts) do names[#names + 1] = name end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

--- Пункты выпадающего списка шрифтов: sentinel-пункты и зарегистрированные
--- через LibSharedMedia.
--- @param mode string|nil "global" — глобальный шрифт; "slot" — шрифт слота;
---   "tooltip" — шрифт тултипа; nil — как "global"
--- @return table<string, string> value → текст пункта
function LPS:GetFontChoiceMap(mode)
    local L = LPS.L
    local map = {}
    if mode == "slot" then
        map["default"] = L.FONT_USE_GLOBAL
        map["wowdefault"] = L.FONT_USE_DEFAULT
    elseif mode == "tooltip" then
        map["default"] = L.FONT_USE_DEFAULT
        map["global"] = L.FONT_USE_GLOBAL
    else
        map["default"] = L.FONT_USE_DEFAULT
    end
    for _, name in ipairs(GetSortedFontNames()) do
        map[name] = name
    end
    return map
end

--- Порядок пунктов списка шрифтов.
--- @param mode string|nil "global" / "slot" / "tooltip"
--- @return table<string>
function LPS:GetFontChoiceOrder(mode)
    local order
    if mode == "slot" then
        order = { "default", "wowdefault" }
    elseif mode == "tooltip" then
        order = { "default", "global" }
    else
        order = { "default" }
    end
    for _, name in ipairs(GetSortedFontNames()) do
        order[#order + 1] = name
    end
    return order
end

--- Файл/имя шрифта по выбранному значению; nil — стандартный шрифт игры.
--- @param font string|nil значение из списка (default/global/wowdefault/custom/имя шрифта)
--- @param customName string|nil имя системного шрифта
--- @return string|nil
function LPS:ResolveFontFile(font, customName)
    if not font or font == "default" or font == "wowdefault" then return nil end
    if font == "global" then
        local db = LPS:GetDB()
        local s = (db and db.settings) or {}
        if not s.font or s.font == "default" or s.font == "wowdefault" then return nil end
        return LPS:ResolveFontFile(s.font, s.fontName)
    end
    if font == "custom" then
        if type(customName) == "string" then
            return customName:match("%S+")
        end
        return nil
    end
    local file = LPS:GetRegisteredFonts()[font]
    if file then return file end
    return font
end

--- Шрифт слота (location / left1..3 / right1..3): настройка слота
--- (значение "default" — «использовать глобальный шрифт»), иначе глобальная;
--- nil — стандартный шрифт.
--- @param slot string ключ слота ("location", "left1".., "right1"..)
--- @return string|nil
function LPS:ResolveSlotFontFile(slot)
    local db = LPS:GetDB()
    if not db then return nil end
    local s = db.settings or {}
    local sf = db.layout and db.layout.slotFont and db.layout.slotFont[slot]
    local font = s.font
    if sf and sf ~= "default" then
        font = sf
    end
    return LPS:ResolveFontFile(font, s.fontName)
end

--- Применяет файл шрифта (или сброс к исходному) ко всем строкам-FontString
--- тултипа. FontString создаются один раз в шаблоне GameTooltip и постоянны,
--- поэтому порядок относительно ClearLines/AddLine не важен.
function LPS:_SetTooltipFontStrings(tt, file)
    if not tt then return end
    local function apply(fs)
        if type(fs) ~= "table" and type(fs) ~= "userdata" then return end
        if type(fs.SetFont) ~= "function" or type(fs.GetFont) ~= "function" then return end
        if not fs._lpsOrigFont then
            local ok, f, s = pcall(function() return fs:GetFont() end)
            if ok then fs._lpsOrigFont, fs._lpsOrigSize = f, s end
        end
        local size = fs._lpsOrigSize or 12
        if file then
            pcall(function() fs:SetFont(file, size) end)
        elseif fs._lpsOrigFont then
            pcall(function() fs:SetFont(fs._lpsOrigFont, size) end)
        end
    end
    apply(tt)
    if type(tt.GetChildren) == "function" then
        pcall(function()
            for child in tt:GetChildren() do
                if child and type(child.IsFontString) == "function" and child:IsFontString() then
                    apply(child)
                end
            end
        end)
    end
    --- Каждый ряд GameTooltip имеет свою пару FontString
    --- (GameTooltipTextLeftN / GameTooltipTextRightN), поэтому покрываем все
    --- возможные номера рядов, а не только первый.
    for i = 1, 30 do
        apply(_G["GameTooltipTextLeft" .. i])
        apply(_G["GameTooltipTextRight" .. i])
    end
end

--- Применяет выбранный шрифт подсказок к «нашим» тултипам (вызывать до
--- GameTooltip:Show()). Отмечает тултип как наш, чтобы хук Show мог вернуть
--- стандартный шрифт для чужих (LDB и пр.) подсказок.
function LPS:ApplyTooltipFont(tt)
    if not tt or type(tt.GetChildren) ~= "function" then return end
    local db = LPS:GetDB()
    if not db or type(db.tooltips) ~= "table" then return end
    local file = LPS:ResolveFontFile(db.tooltips.font, db.tooltips.fontName)
    LPS._lpsOursTooltip = true
    tt._lpsCustomFont = file
    LPS:_SetTooltipFontStrings(tt, file)
end

--- Возвращает шрифт подсказок к исходному (вызывается хуком для чужих тултипов).
function LPS:ResetTooltipFont(tt)
    if not tt then return end
    LPS:_SetTooltipFontStrings(tt, nil)
    tt._lpsCustomFont = nil
end

if GameTooltip and type(hooksecurefunc) == "function" then
    hooksecurefunc(GameTooltip, "Show", function(self)
        if LPS._lpsOursTooltip then
            LPS._lpsOursTooltip = nil
        elseif self._lpsCustomFont then
            LPS:ResetTooltipFont(self)
        end
    end)
end

--- Подпись настроек шрифтов (глобальный + шрифты слотов) для ключа
--- ApplyLayout (пересборка макета при смене шрифта).
function LPS:PanelFontKey(db)
    local parts = {}
    local s = (type(db) == "table" and db.settings) or {}
    parts[#parts + 1] = tostring(s.font or "default")
    parts[#parts + 1] = tostring(s.fontName or "")
    local sf = (type(db) == "table" and type(db.layout) == "table") and db.layout.slotFont or nil
    if type(sf) == "table" then
        local slots = { "location", "left1", "left2", "left3", "right1", "right2", "right3" }
        for _, sl in ipairs(slots) do
            parts[#parts + 1] = sl .. ":" .. tostring(sf[sl] or "default")
        end
    end
    return table.concat(parts, ";")
end