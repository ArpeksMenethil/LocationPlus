local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Import/Export" дерева настроек (формат AceConfig-3.0).
function LPS.Options.BuildTree.tabs.importexport()
return {
			name = LPS:L("Import/Export"),
			order = 91,
			args = {
				export = {
					type = "group",
					name = LPS:L("Export"),
					order = 1,
					args = {
						header = {
							order = 1,
							type = "header",
							name = LPS:L("Export"),
						},
						generate = {
							order = 2,
							type = "execute",
							name = LPS:L("Generate export string"),
							desc = LPS:L("Generate an export string for the current profile."),
							disabled = function()
							return not (OH.Ace.Serializer and LPS.db and LPS.db.profile)
							end,
							func = function()
							local serialString = OH.Ace.Serializer:Serialize(LPS.db.profile or {})
							if OH.Ace.Deflate and OH.Ace.Deflate.CompressDeflate and OH.Ace.Deflate.EncodeForPrint then
							local compressedData = OH.Ace.Deflate:CompressDeflate(serialString, { level = 5 })
							local printableString = compressedData and OH.Ace.Deflate:EncodeForPrint(compressedData)
							if printableString then
							LPS.Options._profileExportText = PROFILE_EXPORT_PREFIX .. printableString
							return
							end
							end
							LPS.Options._profileExportText = serialString
							end,
						},
						text = {
							order = 3,
							type = "input",
							name = LPS:L("Export string"),
							desc = LPS:L("Copy this string to export your current profile."),
							width = "full",
							multiline = 12,
							dialogControl = "LPSMultiLineEditBoxNoButton",
							disabled = function()
							return not (OH.Ace.Serializer and LPS.db and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileExportText or "") end,
							set = function(_, v) LPS.Options._profileExportText = v end,
						},
					},
				},
				import = {
					type = "group",
					name = LPS:L("Import"),
					order = 2,
					args = {
						header = {
							order = 1,
							type = "header",
							name = LPS:L("Import"),
						},
						asName = {
							order = 2,
							type = "input",
							name = LPS:L("Profile name"),
							desc = LPS:L("Name of the profile to import into."),
							dialogControl = "LPSEditBoxNoButton",
							disabled = function()
							return not (OH.Ace.Serializer and LPS.db and LPS.db.SetProfile and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileImportAsName or "") end,
							set = function(_, v) LPS.Options._profileImportAsName = v end,
						},
						text = {
							order = 3,
							type = "input",
							name = LPS:L("Import string"),
							desc = LPS:L("Paste an export string here to import a profile."),
							width = "full",
							multiline = 12,
							dialogControl = "LPSMultiLineEditBoxNoButton",
							disabled = function()
							return not (OH.Ace.Serializer and LPS.db and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileImportText or "") end,
							set = function(_, v) LPS.Options._profileImportText = v end,
						},
						doImport = {
							order = 4,
							type = "execute",
							name = LPS:L("Import"),
							desc = LPS:L("Import the string into the selected profile name."),
							disabled = function()
							return not (OH.Ace.Serializer and LPS.db and LPS.db.profile and LPS.db.SetProfile)
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
							if OH.Ace.Deflate and OH.Ace.Deflate.DecodeForPrint and OH.Ace.Deflate.DecompressDeflate and s:sub(1, #PROFILE_EXPORT_PREFIX) == PROFILE_EXPORT_PREFIX then
							local encoded = s:sub(#PROFILE_EXPORT_PREFIX + 1)
							encoded = encoded:gsub("%s+", "")
							local compressed = OH.Ace.Deflate:DecodeForPrint(encoded)
							if not compressed then return end
							local decompressed = OH.Ace.Deflate:DecompressDeflate(compressed)
							if not decompressed then return end
							decodeString = decompressed
							end
							local ok, t = OH.Ace.Serializer:Deserialize(decodeString)
							if not ok or type(t) ~= "table" then
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
