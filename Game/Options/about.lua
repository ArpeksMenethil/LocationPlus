local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Метка-заголовок секции («header» в дереве настроек): рисуется крупным
--- акцентным шрифтом, как заголовки групп на других страницах.
function LPS:OptionHeader(nameText, order)
    return { type = "header", name = nameText, order = order }
end

--- Возвращает вкладку "About" дерева настроек (внутренний формат дерева).
--- Полноценная страница «О модификации»: логотип, описание аддона, сведения
--- о версии/авторе и ссылки.
LPS.Options.BuildTree.tabs.about = function()
    local title = (LPS.addon.title and LPS.addon.title ~= "") and LPS.addon.title or "Location Plus"
    local version = tostring(LPS.addon.version or "")
    local author = LPS.Options.aboutAuthor or "Arpeks"

    local notes = LPS:GetAddonNotes()

    local args = {
        aboutHeader = LPS:OptionHeader(L.ABOUT_THIS_ADDON, 1),
        aboutLogo = {
            order = 2,
            type = "image",
            file = LPS.icons.PathLogoModern,
            width = 64,
            height = 64,
        },
        aboutLabel = {
            order = 3,
            type = "description",
            name = notes,
        },
        infoHeader = LPS:OptionHeader(L.AUTHOR, 4),
        infoLabel = {
            order = 5,
            type = "description",
            name = string.format("%s: %s\n%s: %s",
                L.AUTHOR, author,
                L.VERSION_LABEL or "Version", version),
        },
        curseForgeLink = {
            order = 6,
            type = "link",
            name = L.LINK_CURSEFORGE,
            url = "https://www.curseforge.com/wow/addons/location-plus",
        },
    }

    return {
        name = L.ABOUT,
        order = 92,
        args = args,
    }
end
