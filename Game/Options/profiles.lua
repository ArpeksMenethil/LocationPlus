local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Вкладка "Profiles" строится напрямую из портированной страницы
--- Game/Options/page_profiles.lua, поэтому в дереве настроек она
--- представлена пустым узлом: ui_options.lua
--- зарегистрирует для неё нативную страницу Panel, а collectRows не выведет
--- никаких сгенерированных строк.
function LPS.Options.BuildTree.tabs.profiles()
    return {
        name = L.PROFILES,
        order = 90,
        args = {},
    }
end
