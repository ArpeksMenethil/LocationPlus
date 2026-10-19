local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Profiles" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.profiles()
	return {
			type = "group",
			name = L.PROFILES,
			order = 90,
			args = {}
}
end
