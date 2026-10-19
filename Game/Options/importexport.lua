local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Import/Export" дерева настроек (внутренний формат дерева).
--- Экспорт/импорт профиля работает без Ace3: собственная сериализация
--- (OH:SerializeProfile / OH:DeserializeProfile) + сжатие LibDeflate из Libs/.
function LPS.Options.BuildTree.tabs.importexport()
    -- страница ещё не открывалась: временное хранилище текста/имени профиля
    local state = LPS.Options._importExportState or {}
    LPS.Options._importExportState = state

    local function canExport()
        return (LPS.db and LPS.db.profile) ~= nil
    end

    --- Кнопка «скопировать в буфер обмена»: без неё длинную строку экспорта
    --- нельзя выделить мышью (многострочное поле только для чтения глазами),
    --- и страница выглядела нерабочей. Текст берётся из state.exportText.
    local function copyButton(order, getText)
        return {
            order = order,
            type = "execute",
            fullRow = false,
            name = L.COPY_TO_CLIPBOARD or "Copy to Clipboard",
            desc = L.COPY_THE_STRING_TO_YOUR_CLIPBOARD or "Copies the string above to your clipboard.",
            func = function()
                local t = tostring(getText() or "")
                if t == "" then return end
                if LPS.DEBUG then print("LPS: copy, len=" .. #t) end
                local edit = _G.LPSImportExportClipboardEditBox
                if not edit then
                    edit = CreateFrame("EditBox", "LPSImportExportClipboardEditBox", _G.UIParent)
                    edit:SetMultiLine(true)
                    edit:SetAutoFocus(false)
                    edit:SetMaxLetters(0)
                    edit:Hide()
                end
                edit:SetText(t)
                edit:HighlightText(0, #t)
                edit:SetFocus()
                edit:CopyInput()
                if edit.HasCopied and edit:HasCopied() then
                    LPS:Print(L.COPIED_TO_CLIPBOARD or "Copied to clipboard!", false)
                else
                    LPS:Print(L.COPY_TO_CLIPBOARD_FAILED or "Copy failed: select the text with Ctrl-A and press Ctrl-C.", false)
                end
                edit:ClearFocus()
                edit:Hide()
            end,
        }
    end

    return {
        name = L.IMPORT_EXPORT,
        order = 91,
        args = {
            aboutLabel = {
                order = 0.5,
                type = "description",
                name = L.IMPORT_EXPORT_PAGE_DESC or "Generate an export string for the current profile, copy it to the clipboard, and paste a string here to import it into any profile by name.",
            },
            exportGroup = {
                name = L.EXPORT,
                order = 1,
                args = {
                    -- fullRow: кнопка одна — не оставляем справа пустую
                    -- половину строки (Builder иначе ждёт второй чекбокс в пару)
                    generate = {
                        order = 1,
                        type = "execute",
                        fullRow = true,
                        name = L.GENERATE_EXPORT_STRING,
                        desc = L.GENERATE_AN_EXPORT_STRING_FOR_THE_CURRENT_PROFILE,
                        disabled = function()
                            return not canExport()
                        end,
                        func = function()
                            local serialString = OH:SerializeProfile(LPS.db.profile or {})
                            local D = OH.Ace and OH.Ace.Deflate
                            if D and D.CompressDeflate and D.EncodeForPrint then
                                local compressedData = D:CompressDeflate(serialString, { level = 5 })
                                local printableString = compressedData and D:EncodeForPrint(compressedData)
                                if printableString then
                                    state.exportText = OH.PROFILE_EXPORT_PREFIX .. printableString
                                    return
                                end
                            end
                            state.exportText = serialString
                        end,
                    },
                    text = {
                        order = 2,
                        type = "input",
                        name = L.EXPORT_STRING,
                        desc = L.COPY_THIS_STRING_TO_EXPORT_YOUR_CURRENT_PROFILE,
                        multiline = 10,
                        disabled = function()
                            return not canExport()
                        end,
                        get = function() return tostring(state.exportText or "") end,
                        set = function(_, v) state.exportText = v end,
                    },
                    copyExport = copyButton(3, function() return state.exportText end),
                },
            },
            importGroup = {
                name = L.IMPORT,
                order = 2,
                args = {
                    asName = {
                        order = 1,
                        type = "input",
                        name = L.PROFILE_NAME,
                        desc = L.NAME_OF_THE_PROFILE_TO_IMPORT_INTO,
                        disabled = function()
                            return not (canExport() and LPS.db and LPS.db.SetProfile)
                        end,
                        get = function() return tostring(state.importAsName or "") end,
                        set = function(_, v) state.importAsName = v end,
                    },
                    text = {
                        order = 2,
                        type = "input",
                        name = L.IMPORT_STRING,
                        desc = L.PASTE_AN_EXPORT_STRING_HERE_TO_IMPORT_A_PROFILE,
                        multiline = 10,
                        disabled = function()
                            return not canExport()
                        end,
                        get = function() return tostring(state.importText or "") end,
                        set = function(_, v) state.importText = v end,
                    },
                    copyImport = copyButton(2.5, function() return state.importText end),
                    doImport = {
                        order = 3,
                        type = "execute",
                        name = L.IMPORT,
                        desc = L.IMPORT_THE_STRING_INTO_THE_SELECTED_PROFILE_NAME,
                        disabled = function()
                            return not (canExport() and LPS.db and LPS.db.SetProfile)
                        end,
                        func = function()
                            local s = tostring(state.importText or "")
                            if s == "" then return end
                            local importName = tostring(state.importAsName or "")
                            local currentProfile = LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()
                            if importName == "" then
                                importName = tostring(currentProfile or "")
                            end
                            if importName == "" then return end
                            local decodeString = s
                            local D = OH.Ace and OH.Ace.Deflate
                            if D and D.DecodeForPrint and D.DecompressDeflate and s:sub(1, #OH.PROFILE_EXPORT_PREFIX) == OH.PROFILE_EXPORT_PREFIX then
                                local encoded = s:sub(#OH.PROFILE_EXPORT_PREFIX + 1)
                                encoded = encoded:gsub("%s+", "")
                                local compressed = D:DecodeForPrint(encoded)
                                if not compressed then
                                    LPS:Print("Import failed: invalid string.", false)
                                    return
                                end
                                local decompressed = D:DecompressDeflate(compressed)
                                if not decompressed then
                                    LPS:Print("Import failed: invalid string.", false)
                                    return
                                end
                                decodeString = decompressed
                            end
                            local t = OH:DeserializeProfile(decodeString)
                            if type(t) ~= "table" then
                                LPS:Print("Import failed: invalid string.", false)
                                return
                            end
                            if currentProfile and importName ~= currentProfile then
                                -- SetProfile сам создаёт профиль, если его ещё нет
                                LPS.db:SetProfile(importName)
                            end
                            local p2 = LPS.db.profile
                            for k in pairs(p2) do
                                p2[k] = nil
                            end
                            for k, v in pairs(t) do
                                p2[k] = OH:deepCopy(v)
                            end
                            if LPS.InvalidateDBCache then LPS:InvalidateDBCache() end
                            if LPS.RefreshAfterProfileChange then
                                LPS:RefreshAfterProfileChange()
                            end
                            LPS:Print(L.PROFILE_NAME .. ": " .. importName, false)
                        end,
                    },
                },
            },
        },
    }
end
