local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Возвращает вкладку "About" дерева настроек (внутренний формат дерева настроек).
--- Информация о модификации и список доступных slash-команд (как в CharacterStats).
function LPS.Options.BuildTree.tabs.about()
    local title = LPS.addon.title or "Location Plus"
    local version = tostring(LPS.addon.version or "")
    local author = LPS.Options.aboutAuthor or "Arpeks"

    local aboutText = string.format(
        "|c%s%s|r v%s\n%s: %s\n\n%s",
        LPS.addon.textColor or "ff1784d1", title, version,
        L.AUTHOR, author,
        L.ADDS_LOCATION_COORDS_NEXTRA_PANELS_AND_AN_INFO_RICH_TOOLTIP_N_NO_ELVUI_REQUIRED:gsub("\\n", "\n")
    )

    -- Список команд берём из обработчика SlashCmdList["LPS"] (Game/core.lua)
    local commands = {
        { cmd = "/lps",            desc = L.OPEN_OPTIONS_WINDOW },
        { cmd = "/lps reset",      desc = L.RESET_ALL_ADDON_SETTINGS_TO_DEFAULT_VALUES },
        { cmd = "/lps resetpanels", desc = L.PANEL_SETTINGS_HAVE_BEEN_RESET_TO_DEFAULTS },
    }
    local commandsText = ""
    for _, c in ipairs(commands) do
        commandsText = commandsText .. "|cffe0c060" .. c.cmd .. "|r - " .. (c.desc or "") .. "\n"
    end

    return {
        name = L.ABOUT,
        order = 92,
        args = {
            infoGroup = {
                order = 1,
                name = L.ABOUT_THIS_ADDON,
                args = {
                    aboutLabel = {
                        order = 1,
                        type = "description",
                        name = aboutText,
                    },
                    linksLabel = {
                        order = 2,
                        type = "description",
                        name = "CurseForge: |cff4aa3ffhttps://www.curseforge.com/wow/addons/location-plus|r",
                    },
                },
            },
            commandsGroup = {
                order = 2,
                name = L.COMMANDS,
                args = {
                    commandsLabel = {
                        order = 1,
                        type = "description",
                        name = commandsText,
                    },
                },
            },
        },
    }
end
