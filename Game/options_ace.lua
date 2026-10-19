local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper
local aceAppName = LPS.Options.aceAppName

LPS.Options.tree = LPS.Options:GetTree()

local aboutAuthor = LPS.Options.aboutAuthor

--- Ошибка валидации/регистрации дерева опций не должна обрывать загрузку чанка:
-- иначе функции FinalizeAce / EnsureAceProfilesTab / RegisterAceProfiles ниже
-- не определяются, корневая таблица так и не регистрируется (повторные попытки
-- через core.lua тоже молча пропадают), а ToggleLegacyMenu вызывает
-- aceDialog:Open на незарегистрированном приложении:
-- "LocationPlus isn't registed with AceConfigRegistry, unable to open config".
local function safeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		LPS:Print("AceConfig init error: " .. tostring(err))
	end
end

do
if not OH.Ace.Config then
else
OH:RegisterNoButtonWidgets()

local rootRegistered = false
local subCategoriesRegistered = false

local function registerRootAndSubCategories()
local options = LPS.Options.tree
if type(options) ~= "table" then return end
if not rootRegistered then
-- pcall: при ошибке валидации дерева (например, некорректная опция в
-- одной из вкладок) ошибка AceConfigRegistry не должна обрывать чанк —
-- иначе подкатегории и About не зарегистрируются.
local ok, err = pcall(OH.Ace.Config.RegisterOptionsTable, OH.Ace.Config, aceAppName, options)
if ok then
rootRegistered = true
else
LPS:Print("AceConfig: root options table validation failed: " .. tostring(err))
end
end
if not subCategoriesRegistered then
subCategoriesRegistered = true
safeCall(OH.registerSubCategory, OH, aceAppName, "_General", options.args.general)
safeCall(OH.registerSubCategory, OH, aceAppName, "_Show", options.args.show)
safeCall(OH.registerSubCategory, OH, aceAppName, "_Tooltip", options.args.tooltip)
safeCall(OH.registerSubCategory, OH, aceAppName, "_Layout", options.args.layout)
if options.args.importexport then
safeCall(OH.registerSubCategory, OH, aceAppName, "_ImportExport", options.args.importexport)
end
end
end

safeCall(function()
OH.Ace.Config:RegisterOptionsTable(aceAppName .. "_About", {
type = "group",
name = LPS.addon.title .. " v" .. LPS.addon.version,
args = {
logo = {
order = 1,
type = "description",
name = " ",
image = LPS.icons.PathLogoModern,
imageWidth = 128,
imageHeight = 128,
},
spacer = {
order = 2,
type = "description",
name = " ",
},
creditsHeader = {
order = 3,
type = "header",
name = "Credits",
},
creditsList = {
order = 4,
type = "description",
fontSize = "medium",
name = table.concat({
"|cffffd200Author:|r " .. aboutAuthor,
"",
"|cffffd200Special Thanks:|r",
" |cff00ff00The WoW addon community|r",
}, "\n"),
},
},
})
OH.Ace.Dialog:AddToBlizOptions(aceAppName .. "_About", LPS.addon.title)
end)

registerRootAndSubCategories()

--- Повторная регистрация в AceConfig после готовности БД (вызывает core.lua).
function LPS.Options:FinalizeAce()
registerRootAndSubCategories()
end

--- Вкладка профилей из AceDBOptions: добавляет пункт в общее дерево
--- (его видит и нативное UI) и регистрирует отдельную Ace-страницу.
function LPS.Options:EnsureAceProfilesTab()
if self._profilesTabEnsured then return end
if not (LibStub and LibStub.GetLibrary) then return end
if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
local AceDBOptions = LibStub("AceDBOptions-3.0")
-- pcall: GetOptionsTable может ошибиться на нестандартном профиле —
-- не должен обрывать вызывающий код (core.lua / ui_options.lua).
local ok, p = pcall(AceDBOptions.GetOptionsTable, AceDBOptions, LPS.db)
if not ok or type(p) ~= "table" then return end
p.order = 90
p.name = LPS:L("Profiles")
self.tree.args.profiles = p
self._profilesTabEnsured = true
if OH.Ace.Registry and OH.Ace.Registry.NotifyChange then
OH.Ace.Registry:NotifyChange(self.aceAppName)
end
end

function LPS.Options:RegisterAceProfiles()
if self._profilesRegistered then return end
if not (OH.Ace.Config and LibStub and LibStub.GetLibrary) then return end
if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
local AceDBOptions = LibStub("AceDBOptions-3.0")
-- pcall: ошибка валидации таблицы профилей не должна обрывать onLoaded в core.lua
local ok = pcall(OH.Ace.Config.RegisterOptionsTable, OH.Ace.Config, self.aceAppName .. "_Profiles", AceDBOptions:GetOptionsTable(LPS.db))
if not ok then return end
if OH.Ace.Dialog and not self._profilesBlizAdded then
OH.Ace.Dialog:AddToBlizOptions(self.aceAppName .. "_Profiles", LPS:L("Profiles"), LPS.addon.title)
self._profilesBlizAdded = true
end
self._profilesRegistered = true
end
end
end
