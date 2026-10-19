local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper
local aceAppName = LPS.Options.aceAppName

LPS.Options.tree = LPS.Options:GetTree()

local aboutAuthor = LPS.Options.aboutAuthor

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
rootRegistered = true
pcall(OH.Ace.Config.RegisterOptionsTable, OH.Ace.Config, aceAppName, options)
end
if not subCategoriesRegistered then
subCategoriesRegistered = true
OH:registerSubCategory(aceAppName, "_General", options.args.general)
OH:registerSubCategory(aceAppName, "_Show", options.args.show)
OH:registerSubCategory(aceAppName, "_Tooltip", options.args.tooltip)
OH:registerSubCategory(aceAppName, "_Layout", options.args.layout)
if options.args.importexport then
OH:registerSubCategory(aceAppName, "_ImportExport", options.args.importexport)
end
end
end

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
local p = AceDBOptions:GetOptionsTable(LPS.db)
if type(p) ~= "table" then return end
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
OH.Ace.Config:RegisterOptionsTable(self.aceAppName .. "_Profiles", AceDBOptions:GetOptionsTable(LPS.db))
if OH.Ace.Dialog and not self._profilesBlizAdded then
OH.Ace.Dialog:AddToBlizOptions(self.aceAppName .. "_Profiles", LPS:L("Profiles"), LPS.addon.title)
self._profilesBlizAdded = true
end
self._profilesRegistered = true
end
end
end
