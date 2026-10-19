local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local OH = LPS.OptionsHelper

--- Возвращает вкладку "Profiles" дерева настроек (формат AceConfig-3.0).
function LPS.Options.BuildTree.tabs.profiles()
	return {
			type = "group",
			name = LPS:L("Profiles"),
			order = 90,
			args = {}
}
end
