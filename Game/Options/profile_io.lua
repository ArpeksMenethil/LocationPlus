local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L




local MAX_DEPTH = 8

function LPS:ProfileEncodeValue(v, depth)
    if v == nil then return "null" end
    local t = type(v)
    if t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        if v == math.floor(v) and math.abs(v) < 1e16 then
            return string.format("%d", v)
        end
        return string.format("%.16g", v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" and depth < MAX_DEPTH then
        local n = #v
        local isArray = true
        if n == 0 then
            for _ in pairs(v) do isArray = false break end
        else
            for i = 1, n do
                if v[i] == nil then isArray = false break end
            end
        end
        local parts = {}
        if isArray then
            for i = 1, n do
                parts[#parts + 1] = LPS:ProfileEncodeValue(v[i], depth + 1)
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b)
                if type(a) == type(b) then return tostring(a) < tostring(b) end
                return type(a) < type(b)
            end)
            for _, k in ipairs(keys) do
                parts[#parts + 1] = string.format("%q:%s", k, LPS:ProfileEncodeValue(v[k], depth + 1))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function LPS:ProfileEncode(data)
    return LPS:ProfileEncodeValue(data, 0)
end

--- Мини-рекурсивный JSON-парсер (только типы, которые мы кодируем).
function LPS:ProfileDecodeJSON(str)
    local pos = 1

    local function SkipSpaces()
        pos = pos + #(str:match("^%s*", pos) or "")
    end

    local ParseValue, ParseString, ParseArray, ParseObject

    local function ParseStringFn()
        pos = pos + 1
        local out = {}
        while true do
            local c = str:sub(pos, pos)
            if c == "" then error("JSON: unterminated string") end
            if c == '"' then pos = pos + 1 break end
            if c == "\\" then
                local esc = str:sub(pos + 1, pos + 1)
                local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
                if map[esc] then
                    out[#out + 1] = map[esc]
                    pos = pos + 2
                elseif esc == "u" then
                    local hex = str:sub(pos + 2, pos + 5)
                    local cp = tonumber(hex, 16)
                    if not cp then error("JSON: bad \\u escape") end
                    if cp < 0x80 then
                        out[#out + 1] = string.char(cp)
                    elseif cp < 0x800 then
                        out[#out + 1] = string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
                    else
                        out[#out + 1] = string.char(
                            0xE0 + math.floor(cp / 4096),
                            0x80 + math.floor(cp / 64) % 64,
                            0x80 + cp % 64
                        )
                    end
                    pos = pos + 6
                else
                    out[#out + 1] = esc
                    pos = pos + 2
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end
        return table.concat(out)
    end

    local function ParseArrayFn()
        pos = pos + 1
        local arr = {}
        SkipSpaces()
        if str:sub(pos, pos) == "]" then pos = pos + 1 return arr end
        while true do
            arr[#arr + 1] = ParseValue()
            SkipSpaces()
            local c = str:sub(pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "]" then
                pos = pos + 1
                return arr
            else
                error(string.format("JSON: bad array at %d", pos))
            end
        end
    end

    local function ParseObjectFn()
        pos = pos + 1
        local obj = {}
        SkipSpaces()
        if str:sub(pos, pos) == "}" then pos = pos + 1 return obj end
        while true do
            SkipSpaces()
            local key = ParseString()
            SkipSpaces()
            if str:sub(pos, pos) ~= ":" then error("JSON: expected ':'") end
            pos = pos + 1
            obj[key] = ParseValue()
            SkipSpaces()
            local c = str:sub(pos, pos)
            if c == "," then
                pos = pos + 1
            elseif c == "}" then
                pos = pos + 1
                return obj
            else
                error(string.format("JSON: bad object at %d", pos))
            end
        end
    end

    ParseString = ParseStringFn
    ParseArray = ParseArrayFn
    ParseObject = ParseObjectFn

    function ParseValue()
        SkipSpaces()
        local c = str:sub(pos, pos)
        if c == "{" then return ParseObject() end
        if c == "[" then return ParseArray() end
        if c == '"' then return ParseString() end
        local num = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
        if num then
            pos = pos + #num
            return tonumber(num)
        end
        local tok = str:match("^%a+", pos)
        if tok == "true" then pos = pos + 4 return true end
        if tok == "false" then pos = pos + 5 return false end
        if tok == "null" then pos = pos + 4 return nil end
        error(string.format("JSON: unexpected char at %d", pos))
    end

    local ok, result = pcall(ParseValue)
    if not ok then return nil end
    return result
end

function LPS:ProfileDecode(json)
    return LPS:ProfileDecodeJSON(json)
end

function LPS:GetLibDeflate()
    if LibStub and LibStub.GetLibrary then
        local lib = LibStub:GetLibrary("LibDeflate", true)
        if lib then return lib end
    end
    if type(_G.LibDeflate) == "table" and _G.LibDeflate.CompressDeflate then
        return _G.LibDeflate
    end
    return nil
end

local CODE_PREFIX = "!LPS!"

--- Собирает печатную строку переноса для настроек профиля.
function LPS:EncodeProfileData(profileName, settings)
    local ld = LPS:GetLibDeflate()
    if not ld then return nil, L.PROFILE_IO_NO_LIB or "LibDeflate is not available." end
    local payload = {
        addon = LPS.addon.name,
        format = 1,
        version = LPS.addon.version,
        profile = profileName,
        data = LPS:DeepCopy(settings) or {},
    }
    local ok, json = pcall(LPS.ProfileEncode, LPS, payload)
    if not ok then return nil, json end
    local compressed = ld:CompressDeflate(json)
    if not compressed then return nil, L.PROFILE_IO_COMPRESS_FAIL or "Compress failed." end
    local code = ld:EncodeForPrint(compressed)
    if not code then return nil, L.PROFILE_IO_COMPRESS_FAIL or "Compress failed." end
    return CODE_PREFIX .. code
end

--- Разбирает строку переноса в payload {addon, format, profile, data}.
function LPS:DecodeProfileData(code)
    local ld = LPS:GetLibDeflate()
    if not ld then return nil, L.PROFILE_IO_NO_LIB or "LibDeflate is not available." end
    local clean = tostring(code or ""):match("^%s*(.-)%s*$")
    if clean == "" then return nil, L.PROFILE_IO_EMPTY or "No code entered." end
    if clean:sub(1, #CODE_PREFIX) ~= CODE_PREFIX then
        return nil, string.format(L.PROFILE_IO_PREFIX_FAIL or "Invalid code: expected %s prefix.", CODE_PREFIX)
    end
    clean = clean:sub(#CODE_PREFIX + 1)
    if clean == "" then return nil, L.PROFILE_IO_EMPTY or "No code entered." end
    local raw = ld:DecodeForPrint(clean)
    if not raw then
        return nil, L.PROFILE_IO_DECODE_FAIL or "Invalid code: cannot decode."
    end
    local json = ld:DecompressDeflate(raw)
    if not json then
        return nil, L.PROFILE_IO_DECODE_FAIL or "Invalid code: cannot decode."
    end
    local ok, payload = pcall(LPS.ProfileDecode, LPS, json)
    if not ok or type(payload) ~= "table" then
        return nil, L.PROFILE_IO_FORMAT_FAIL or "Invalid code: unknown profile format."
    end
    if payload.addon ~= LPS.addon.name or type(payload.data) ~= "table" then
        return nil, L.PROFILE_IO_WRONG_ADDON or "Invalid code: not a Location Plus profile."
    end
    return payload
end

function LPS:CreateProfilePopupBase(width, height)
    
    LPS:CloseActivePopup()
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(width, height)
    popup:SetPoint("CENTER")
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    LPS:ThemeBox(popup, "window", "border", (LPS:ThemeGet()).windowRadius)
    local titleFs = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFs.themeRole = "heading"
    titleFs:SetPoint("TOPLEFT", 12, -12)
    LPS:ApplyFontColor(titleFs, "textPrimary")
    local bodyFs = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyFs:SetPoint("TOPLEFT", 12, -36)
    bodyFs:SetPoint("TOPRIGHT", -12, -36)
    bodyFs:SetJustifyH("LEFT")
    bodyFs:SetJustifyV("TOP")
    LPS:ApplyFontColor(bodyFs, "textMuted")
    local okBtn = LPS:CreateFlatButton(popup, 80, 22, L.BTN_OK or "OK")
    okBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    local cancelBtn = LPS:CreateFlatButton(popup, 80, 22, L.BTN_CANCEL or "Cancel")
    cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -8, 0)
    cancelBtn:SetScript("OnClick", function()
        LPS:CloseActivePopup()
    end)
    LPS:BindEscapeToClose(popup, function()
        LPS:CloseActivePopup()
    end)
    LPS:ThemeApplyFonts(popup)
    LPS:SetActivePopup(popup)
    return popup, titleFs, bodyFs, okBtn
end

function LPS:CreateProfileFieldBox(popup, x, y, w, h)
    
    local editBox = CreateFrame("EditBox", nil, popup)
    editBox:SetSize(w, h)
    editBox:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    LPS:ThemeBox(editBox, "field", "border", (LPS:ThemeGet()).windowRadius)
    local fieldText = LPS:GetWidgetColor("text")
    editBox:SetTextColor(fieldText.r, fieldText.g, fieldText.b)
    editBox:SetTextInsets(6, 6, 0, 0)
    return editBox
end

function LPS:ShowExportProfilePopup()
    
    if not (LPS:GetDB()) then return end
    local sourceName = LPS:SVGetCurrentProfile() or "Default"
    local settings = LPS:DeepCopy(LPS:GetDB()) or {}
    local code, err = LPS:EncodeProfileData(sourceName, settings)
    if not code then
        LPS:CreatePopup(
            L.POPUP_EXPORT_PROFILE_TITLE or "Export Profile",
            err or "Failed to encode the profile.",
            nil,
            L.BTN_OK or "OK",
            nil
        )
        return
    end

    local popup, titleFs, bodyFs, okBtn = LPS:CreateProfilePopupBase(560, 320)
    titleFs:SetText(L.POPUP_EXPORT_PROFILE_TITLE or "Export Profile")
    bodyFs:SetText(
        L.POPUP_EXPORT_PROFILE_DESC or "Copy the code below and paste it into Import on another client or game version."
    )

    local CODE_H = 204
    local codeBox = LPS:CreateProfileFieldBox(popup, 12, -64, 536, CODE_H)
    codeBox:SetMultiLine(true)
    codeBox:EnableMouse(true)
    codeBox:SetText(code)
    codeBox:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= code then
            self:SetText(code)
        end
        self:SetHeight(CODE_H)
    end)

    codeBox:SetScript("OnMouseDown", function()
        codeBox:HighlightText()
    end)

    okBtn:SetScript("OnClick", function()
        LPS:CloseActivePopup()
    end)
    codeBox:SetFocus()
    codeBox:HighlightText()
    return popup
end

function LPS:ShowImportProfilePopup()
    
    if not LPS.db then return end

    local popup, titleFs, bodyFs, okBtn = LPS:CreateProfilePopupBase(560, 470)
    titleFs:SetText(L.POPUP_IMPORT_PROFILE_TITLE or "Import Profile")
    bodyFs:SetText(
        L.POPUP_IMPORT_PROFILE_DESC or "Enter a name for the new profile and paste the exported code below:"
    )

    local nameLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameLabel:SetPoint("TOPLEFT", 12, -64)
    nameLabel:SetText(L.PROFILE_NAME_LABEL or "Profile name")
    LPS:ApplyFontColor(nameLabel, "textMuted")
    local nameBox = LPS:CreateProfileFieldBox(popup, 12, -82, 260, 22)

    local codeLabel = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    codeLabel:SetPoint("TOPLEFT", 12, -114)
    codeLabel:SetText(L.LABEL_CODE or "Code")
    LPS:ApplyFontColor(codeLabel, "textMuted")
    local CODE_H = 296
    local codeBox = LPS:CreateProfileFieldBox(popup, 12, -132, 536, CODE_H)
    codeBox:SetMultiLine(true)
    codeBox:EnableMouse(true)
    codeBox:SetScript("OnTextChanged", function(self)
        self:SetHeight(CODE_H)
    end)

    okBtn:SetScript("OnClick", function()
        local payload, err = LPS:DecodeProfileData(codeBox:GetText())
        if not payload then
            LPS:CreatePopup(
                L.POPUP_IMPORT_PROFILE_TITLE or "Import Profile",
                err or "Invalid code.",
                nil,
                L.BTN_OK or "OK",
                nil
            )
            return
        end
        local name = nameBox:GetText():match("^%s*(.-)%s*$") or ""
        if name == "" and type(payload.profile) == "string" then
            name = payload.profile:match("^%s*(.-)%s*$") or ""
        end
        if name == "" then name = L.PROFILE_IMPORTED_BASE or "Imported Profile" end
        local finalName = LPS:BuildUniqueProfileName(name)
        LPS.sv.profiles[finalName] = LPS:DeepCopy(payload.data) or {}
        LPS:SVSetProfile(finalName)
        
        if LPS:PanelIsShown() then LPS:PanelRefreshActivePage() end
        LPS:CreatePopup(
            L.POPUP_IMPORT_PROFILE_TITLE or "Import Profile",
            string.format(L.IMPORT_CREATED or "Profile \"%s\" created.", finalName),
            nil,
            L.BTN_OK or "OK",
            nil
        )
    end)
    nameBox:SetFocus()
    return popup
end
