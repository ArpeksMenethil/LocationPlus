local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Import/Export" дерева настроек (нативный формат UI_Options).
--- Экспорт/импорт профиля работает без Ace3: собственная сериализация
--- (OH:SerializeProfile / OH:DeserializeProfile) + сжатие LibDeflate из Libs/.
function LPS.Options.BuildTree.tabs.importexport()
        local function canExport()
                return (LPS.db and LPS.db.profile) ~= nil
        end
        return {
                type = "group",
                name = LPS:L("IMPORT_EXPORT"),
                order = 91,
                args = {
                        export = {
                                type = "group",
                                name = LPS:L("EXPORT"),
                                order = 1,
                                args = {
                                        header = {
                                                order = 1,
                                                type = "header",
                                                name = LPS:L("EXPORT"),
                                        },
                                        generate = {
                                                order = 2,
                                                type = "execute",
                                                name = LPS:L("GENERATE_EXPORT_STRING"),
                                                desc = LPS:L("GENERATE_AN_EXPORT_STRING_FOR_THE_CURRENT_PROFILE"),
                                                disabled = function()
                                                return not canExport()
                                                end,
                                                func = function()
                                                local serialString = OH:SerializeProfile(LPS.db.profile or {})
                                                local D = OH.Ace.Deflate
                                                if D and D.CompressDeflate and D.EncodeForPrint then
                                                local compressedData = D:CompressDeflate(serialString, { level = 5 })
                                                local printableString = compressedData and D:EncodeForPrint(compressedData)
                                                if printableString then
                                                LPS.Options._profileExportText = OH.PROFILE_EXPORT_PREFIX .. printableString
                                                return
                                                end
                                                end
                                                LPS.Options._profileExportText = serialString
                                                end,
                                        },
                                        text = {
                                                order = 3,
                                                type = "input",
                                                name = LPS:L("EXPORT_STRING"),
                                                desc = LPS:L("COPY_THIS_STRING_TO_EXPORT_YOUR_CURRENT_PROFILE"),
                                                width = "full",
                                                multiline = 12,
                                                disabled = function()
                                                return not canExport()
                                                end,
                                                get = function() return tostring(LPS.Options._profileExportText or "") end,
                                                set = function(_, v) LPS.Options._profileExportText = v end,
                                        },
                                },
                        },
                        import = {
                                type = "group",
                                name = LPS:L("IMPORT"),
                                order = 2,
                                args = {
                                        header = {
                                                order = 1,
                                                type = "header",
                                                name = LPS:L("IMPORT"),
                                        },
                                        asName = {
                                                order = 2,
                                                type = "input",
                                                name = LPS:L("PROFILE_NAME"),
                                                desc = LPS:L("NAME_OF_THE_PROFILE_TO_IMPORT_INTO"),
                                                disabled = function()
                                                return not (canExport() and LPS.db and LPS.db.SetProfile)
                                                end,
                                                get = function() return tostring(LPS.Options._profileImportAsName or "") end,
                                                set = function(_, v) LPS.Options._profileImportAsName = v end,
                                        },
                                        text = {
                                                order = 3,
                                                type = "input",
                                                name = LPS:L("IMPORT_STRING"),
                                                desc = LPS:L("PASTE_AN_EXPORT_STRING_HERE_TO_IMPORT_A_PROFILE"),
                                                width = "full",
                                                multiline = 12,
                                                disabled = function()
                                                return not canExport()
                                                end,
                                                get = function() return tostring(LPS.Options._profileImportText or "") end,
                                                set = function(_, v) LPS.Options._profileImportText = v end,
                                        },
                                        doImport = {
                                                order = 4,
                                                type = "execute",
                                                name = LPS:L("IMPORT"),
                                                desc = LPS:L("IMPORT_THE_STRING_INTO_THE_SELECTED_PROFILE_NAME"),
                                                disabled = function()
                                                return not (canExport() and LPS.db and LPS.db.SetProfile)
                                                end,
                                                func = function()
                                                local s = tostring(LPS.Options._profileImportText or "")
                                                if s == "" then return end
                                                local importName = tostring(LPS.Options._profileImportAsName or "")
                                                local currentProfile = LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()
                                                if importName == "" then
                                                importName = tostring(currentProfile or "")
                                                end
                                                if importName == "" then return end
                                                local decodeString = s
                                                local D = OH.Ace.Deflate
                                                if D and D.DecodeForPrint and D.DecompressDeflate and s:sub(1, #OH.PROFILE_EXPORT_PREFIX) == OH.PROFILE_EXPORT_PREFIX then
                                                local encoded = s:sub(#OH.PROFILE_EXPORT_PREFIX + 1)
                                                encoded = encoded:gsub("%s+", "")
                                                local compressed = D:DecodeForPrint(encoded)
                                                if not compressed then return end
                                                local decompressed = D:DecompressDeflate(compressed)
                                                if not decompressed then return end
                                                decodeString = decompressed
                                                end
                                                local t = OH:DeserializeProfile(decodeString)
                                                if type(t) ~= "table" then
                                                LPS:Print("Import failed: invalid string.", false)
                                                return
                                                end
                                                if currentProfile and importName ~= currentProfile then
                                                LPS.db:SetProfile(importName)
                                                end
                                                local p2 = LPS.db.profile
                                                for k in pairs(p2) do
                                                p2[k] = nil
                                                end
                                                for k, v in pairs(t) do
                                                p2[k] = OH:deepCopy(v)
                                                end
                                                if LPS.RefreshAfterProfileChange then
                                                LPS:RefreshAfterProfileChange()
                                                end
                                                end,
                                        },
                                },
                        },
                }

}
end
