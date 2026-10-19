local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Profiles" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.profiles()
	return {
			type = "group",
			name = LPS:L("PROFILES"),
			order = 90,
			args = {}
}
end
