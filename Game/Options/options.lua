local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--- Реестр фабрик вкладок дерева настроек. Каждая Game/Options/<tab>.lua
--- добавляет сюда свою функцию; LPS:GetOptionsTree() собирает дерево.
LPS.Options = LPS.Options or {}
LPS.Options.BuildTree = LPS.Options.BuildTree or {}
LPS.Options.BuildTree.tabs = LPS.Options.BuildTree.tabs or {}
