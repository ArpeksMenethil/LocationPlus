local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Вспомогательные функции и значения для дерева настроек (Game/options.lua).
LPS.OptionsHelper = {}
local OH = LPS.OptionsHelper

---------------------------------------------------------------------------
---------------------------------------------------------------------------
local function escStr(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\")
          :gsub("\n", "\\n")
          :gsub("\r", "\\r")
          :gsub("|", "\\e")
          :gsub(":", "\\c")
          :gsub(",", "\\m")
          :gsub("}", "\\b")
          :gsub("{", "\\o")
    return s
end

local unescMap = {
    ["\\"] = "\\", n = "\n", r = "\r", e = "|",
    c = ":", m = ",", b = "}", o = "{",
}
local function unescStr(s)
    return (s:gsub("\\(.)", function(ch)
        return unescMap[ch] or ch
    end))
end

local encodeValue
local decodeValue
local decodeTable
local encodeTable

encodeValue = function(v)
    local tv = type(v)
    if tv == "string" then return "s|" .. escStr(v)
    elseif tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "s|" end
        if v == math.floor(v) and math.abs(v) < 2^53 then
            return "n|" .. string.format("%d", v)
        end
        return "r|" .. string.format("%.17g", v)
    elseif tv == "boolean" then return "b|" .. (v and "1" or "0")
    elseif tv == "table" then return "t" .. encodeTable(v)
    end
    return "s|"
end

encodeTable = function(t)
    local parts = {}
    for k, v in pairs(t) do
        if (type(k) == "number" or type(k) == "string")
            and v ~= nil and type(v) ~= "function" then
            parts[#parts + 1] = encodeValue(k) .. ":" .. encodeValue(v)
        end
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
end

local DECODE_BUF = {}
local function decodeString(s, pos)
    local i, n = pos, #s
    local buf = DECODE_BUF
    for k = 1, #buf do buf[k] = nil end
    while i <= n do
        local c = s:sub(i, i)
        if c == "\\" then
            buf[#buf + 1] = c .. s:sub(i + 1, i + 1)
            i = i + 2
        elseif c == "," or c == ":" or c == "}" then
            return unescStr(table.concat(buf)), i + 1
        else
            buf[#buf + 1] = c
            i = i + 1
        end
    end
    return unescStr(table.concat(buf)), n + 1
end

decodeTable = function(s, pos)
    if s:sub(pos, pos) ~= "{" then return nil, nil end
    local t = {}
    pos = pos + 1
    if s:sub(pos, pos) == "}" then return t, pos + 1 end
    while pos <= #s do
        local key, np = decodeValue(s, pos)
        if key == nil then return nil, nil end
        if type(key) ~= "number" and type(key) ~= "string" then return nil, nil end
        if s:sub(np, np) == ":" then np = np + 1 end
        local val, np2 = decodeValue(s, np)
        if val == nil then return nil, nil end
        t[key] = val
        local ch = s:sub(np2, np2)
        if ch == "}" then
            return t, np2 + 1
        elseif ch == "" or np2 > #s then
            return nil, nil
        end
        pos = np2
    end
    return nil, nil
end

decodeValue = function(s, pos)
    local code = s:sub(pos, pos)
    if code == "s" then
        if s:sub(pos + 1, pos + 1) ~= "|" then return nil, nil end
        return decodeString(s, pos + 2)
    elseif code == "n" then
        local e = pos + 1
        while e <= #s and s:sub(e, e):match("[%d%-]") do e = e + 1 end
        local num = tonumber(s:sub(pos + 1, e - 1))
        if num == nil then return nil, nil end
        if e <= #s and s:sub(e, e) == "," then e = e + 1 end
        return num, e
    elseif code == "r" then
        local e = pos + 1
        while e <= #s and s:sub(e, e):match("[%d%+%.eE%-]") do e = e + 1 end
        local num = tonumber(s:sub(pos + 1, e - 1))
        if num == nil then return nil, nil end
        if e <= #s and s:sub(e, e) == "," then e = e + 1 end
        return num, e
    elseif code == "b" then
        local bit = s:sub(pos + 2, pos + 2)
        if bit ~= "0" and bit ~= "1" then return nil, nil end
        local e = pos + 3
        if e <= #s and s:sub(e, e) == "," then e = e + 1 end
        return bit == "1", e
    elseif code == "t" then
        local t, e = decodeTable(s, pos + 1)
        return t, e
    end
    return nil, nil
end

--- Сериализует таблицу профиля в многострочную строку.
function OH:SerializeProfile(tbl)
    if type(tbl) ~= "table" then return "" end
    return encodeValue(tbl)
end

--- Обратная операция к SerializeProfile; nil при битой строке.
function OH:DeserializeProfile(str)
    if type(str) ~= "string" then return nil end
    -- Допускаем переносы строк внутри поля ввода: просто убираем их.
    local s = str:gsub("[\r\n]", "")
    if s == "" then return nil end
    local t, epos = decodeValue(s, 1)
    if type(t) ~= "table" then return nil end
    if epos and epos <= #s then return nil end
    return next(t) and t or {}
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
