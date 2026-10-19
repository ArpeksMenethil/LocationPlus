local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Вспомогательные функции и значения для дерева настроек (Game/options.lua).
LPS.OptionsHelper = {}
local OH = LPS.OptionsHelper

-- Ace3 больше не используется: ни опции, ни профили, ни сериализация.
-- Единственная внешняя библиотека — LibDeflate из Libs/ (встроена в аддон),
-- она даёт сжатие строк экспорта профилей.
local LibDeflate = LibStub and LibStub:GetLibrary("LibDeflate", true)

OH.Ace = {
    Deflate = LibDeflate,
}
OH.PROFILE_EXPORT_PREFIX = "!LPS1!"

---------------------------------------------------------------------------
-- Собственная сериализация профилей (замена AceSerializer-3.0).
-- Формат: "key=value" построчно; значения кодируются как
--   s|<string>  n|<number>  b|<0|1>  t|<json-подобное вложенное значение>
-- Ключи/значения экранируются (\n -> \\n и т.п.), decode проверяется строго.
---------------------------------------------------------------------------
local function escStr(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("|", "\\p"):gsub("=", "\\e")
    return s
end

local function unescStr(s)
    -- обратная замена к escStr (порядок важен: \1 — временный плейсхолдер для \\)
    local res = s:gsub("\\\\", "\1"):gsub("\\n", "\n"):gsub("\\r", "\r"):gsub("\\p", "|"):gsub("\\e", "=")
    res = res:gsub("\1", "\\")
    return res
end

local encodeValue, decodeValue

local function encodeTable(t)
    local parts = {}
    for k, v in pairs(t) do
        if type(k) == "number" or type(k) == "string" then
            parts[#parts + 1] = (type(k) == "number") and ("n" .. k) or ("s" .. escStr(k))
            parts[#parts] = parts[#parts] .. ":" .. encodeValue(v)
        end
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end

encodeValue = function(v)
    local tv = type(v)
    if tv == "string" then return "s|" .. escStr(v)
    elseif tv == "number" then return "n|" .. string.format("%.14g", v)
    elseif tv == "boolean" then return "b|" .. (v and "1" or "0")
    elseif tv == "table" then return "t" .. encodeTable(v)
    end
    return "s|" -- nil/функции не сериализуются
end

local function decodeTable(s, pos)
    -- s[pos] == "{"; возвращает (tbl, newPos)
    local t = {}
    pos = pos + 1
    if s:sub(pos, pos) == "}" then return t, pos + 1 end
    while pos <= #s do
        local c = s:sub(pos, pos)
        if c == "n" then
            local numEnd = pos + 1
            while numEnd <= #s and s:sub(numEnd, numEnd):match("[%d%.%-]") do numEnd = numEnd + 1 end
            local key = tonumber(s:sub(pos + 1, numEnd - 1))
            pos = numEnd
        elseif c == "s" then
            local e = pos + 1
            while e <= #s do
                local ch = s:sub(e, e)
                if ch == "\\" then e = e + 2
                elseif ch == ":" then break
                else e = e + 1 end
            end
            local rawKey = s:sub(pos + 1, e - 1)
            local decoded = unescStr(rawKey)
            key = tonumber(decoded) or decoded
            pos = e + 1
        else
            return nil, nil
        end
        if not key then return nil, nil end
        local val, np = decodeValue(s, pos)
        if val == nil and not (s:sub(pos, pos + 1) == "s|") then return nil, nil end
        t[key] = val
        pos = np
        local delim = s:sub(pos, pos)
        if delim == "," then pos = pos + 1
        elseif delim == "}" then return t, pos + 1
        else return nil, nil end
    end
    return nil, nil
end

decodeValue = function(s, pos)
    local c = s:sub(pos, pos)
    if c == "s" then
        local e = pos + 2
        while e <= #s do
            local ch = s:sub(e, e)
            if ch == "\\" then e = e + 2
            elseif ch == "," or ch == "}" or e > #s then break
            else e = e + 1 end
        end
        -- строка заканчивается на верхнеуровневом разделителе; для "key=value"
        -- строковых значений конец — это конец строки
        return unescStr(s:sub(pos + 2, e - 1)), e
    elseif c == "n" then
        local e = pos + 1
        while e <= #s and s:sub(e, e):match("[%d%.%-]") do e = e + 1 end
        return tonumber(s:sub(pos + 1, e - 1)), e
    elseif c == "b" then
        return s:sub(pos + 2, pos + 2) == "1", pos + 3
    elseif c == "t" then
        return decodeTable(s, pos + 1)
    end
    return nil, nil
end

--- Сериализует таблицу профиля в многострочную строку.
function OH:SerializeProfile(tbl)
    if type(tbl) ~= "table" then return "" end
    local lines = {}
    local keys = {}
    for k in pairs(tbl) do
        if type(k) == "string" or type(k) == "number" then keys[#keys + 1] = tostring(k) end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = tbl[k] or tbl[tonumber(k)]
        if v ~= nil and type(v) ~= "function" then
            lines[#lines + 1] = k .. "=" .. (select(1, encodeValue(v)))
        end
    end
    return table.concat(lines, "\n")
end

--- Обратная операция к SerializeProfile; nil при битой строке.
function OH:DeserializeProfile(str)
    if type(str) ~= "string" or str == "" then return nil end
    local out = {}
    for line in str:gmatch("[^\n]+") do
        local eq = line:find("=", 1, true)
        if not eq then return nil end
        local key = line:sub(1, eq - 1)
        local val, epos = decodeValue(line, eq + 1)
        if val == nil then return nil end
        local numKey = tonumber(key)
        out[numKey or key] = val
    end
    return next(out) and out or nil
end

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
            name = L.VALUE_FORMAT,
            desc = L.CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL,
            values = {
                USED_TOTAL = L.USED_TOTAL,
                FREE = L.FREE_SLOTS,
                USED = L.USED_SLOTS,
            },
        },
    },
    experience = {
        display = {
            order = 3,
            name = L.VALUE_FORMAT,
            desc = L.CHOOSE_HOW_THE_VALUE_IS_SHOWN_ON_THE_PANEL,
            values = {
                PERCENT = L.PERCENT,
                CURMAX = L.CURRENT_MAX,
                CUR = L.CURRENT,
                REM = L.REMAINING,
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
                name = L.MAX_ENTRIES_IN_TOOLTIP,
                desc = L.LIMIT_HOW_MANY_ENTRIES_ARE_SHOWN_IN_THIS_LIST,
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
            name = L.HIDE_LABEL,
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
            name = L.CUSTOM_LABEL,
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
        ["NONE"] = L.NONE,
        ["RLEVEL"] = LPS.icons.Level .. " " .. L.LEVEL_RANGE,
    }
    if not LPS.Retail and not LPS.Mists then
        t["PFISH"] = LPS.icons.Fish .. " " .. L.FISHING
    end
    if LPS.Retail or LPS.Mists then
        t["PET"] = LPS.icons.Pet .. " " .. L.BATTLE_PETS
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
        ["NONE"] = L.NONE,
        ["OUTLINE"] = "OUTLINE",
        ["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
        ["THICKOUTLINE"] = "THICKOUTLINE",
    }
end
