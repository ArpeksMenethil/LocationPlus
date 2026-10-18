local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Micro Bar
do
	LPS:RegisterDatatext({
		key = "microBar",
		name = LPS:L("Micro Bar"),
		update = function(f)
			if f.text then f.text:SetText(LPS:L("Game Menu") or MENU) end
		end,
		onClick = function(self, button)
			if button == "LeftButton" then
				if _G.GameMenuFrame and ToggleFrame then
					ToggleFrame(_G.GameMenuFrame)
				end
			else
				local list = {}
				local buttons = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
					"QuestLogMicroButton", "SocialsMicroButton", "LFGMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
				for _, bn in ipairs(buttons) do
					local b = _G[bn]
					if b then
						list[#list + 1] = {
							text = (b.tooltip and b.tooltip.title) or bn:gsub("MicroButton", ""),
							func = function() b:Click() end,
						}
					end
				end
				DT.showMenu(self, list)
			end
		end,
	})
end
