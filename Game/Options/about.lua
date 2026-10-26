local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Метка-заголовок секции («header» в дереве настроек): рисуется крупным
--- акцентным шрифтом, как заголовки групп на других страницах.
local function header(nameText, order)
    return { type = "header", name = nameText, order = order }
end

--- Возвращает вкладку "About" дерева настроек (внутренний формат дерева).
--- Полноценная страница «О модификации»: описание аддона, сведения о
--- версии/авторе и ссылки.
function LPS.Options.BuildTree.tabs.about()
    local title = (LPS.addon.title and LPS.addon.title ~= "") and LPS.addon.title or "Location Plus"
    local version = tostring(LPS.addon.version or "")
    local author = LPS.Options.aboutAuthor or "Arpeks"

    -- Описание: Notes из .toc для текущего языка клиента (с fallback на enUS)
    local notes = nil
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if getMeta and LPS.addon.name then
        local locale = LPS.ACTIVE_LOCALE or GetLocale()
        notes = getMeta(LPS.addon.name, "Notes-" .. tostring(locale))
                or getMeta(LPS.addon.name, "Notes")
    end
    notes = (type(notes) == "string" and notes ~= "") and notes
            or L.ADDS_LOCATION_COORDS_NEXTRA_PANELS_AND_AN_INFO_RICH_TOOLTIP_N_NO_ELVUI_REQUIRED

    local args = {
        aboutHeader = header(L.ABOUT_THIS_ADDON, 1),
        aboutLabel = {
            order = 2,
            type = "description",
            name = notes,
        },
        infoHeader = header(L.AUTHOR, 3),
        infoLabel = {
            order = 4,
            type = "description",
            name = string.format("%s: %s\n%s: %s",
                L.AUTHOR, author,
                L.VERSION_LABEL or "Version", version),
        },
        linksLabel = {
            order = 5,
            type = "description",
            name = "CurseForge: |cff4aa3ffhttps://www.curseforge.com/wow/addons/location-plus|r",
        },
    }

    return {
        name = L.ABOUT,
        order = 92,
        args = args,
    }
end
