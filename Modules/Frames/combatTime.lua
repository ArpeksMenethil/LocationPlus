local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Combat / Arena Time
do
	local timer, startTime
	local frame = nil

	local function ensureTicker(f)
		if not frame then
			frame = CreateFrame("Frame")
			frame:SetScript("OnUpdate", function(self, elapsed)
				if timer and startTime then
					timer = timer + elapsed
					local m = math.floor(timer / 60)
					local s = math.floor(timer % 60)
					for _, fr in pairs(LPS.frame or {}) do
						if fr._lpsCombatTime then
							fr._lpsCombatTime(m, s)
						end
					end
				end
			end)
		end
	end

	LPS:RegisterDatatext({
		key = "combatTime",
		name = LPS:L("Combat/Arena Time"),
		events = { "ENCOUNTER_START", "ENCOUNTER_END", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
		create = function(f)
			ensureTicker(f)
			f._lpsCombatTime = function(m, s)
				if f.text and f:IsShown() then
					f.text:SetText(string.format("%s: |cFFFFFFFF%02d|cFFFFFFFF:%02d|r", LPS:L("Combat"), m, s))
				end
			end
		end,
		update = function(f, ev)
			if ev == "PLAYER_REGEN_DISABLED" or ev == "ENCOUNTER_START" then
				timer, startTime = 0, GetTime()
			elseif ev == "PLAYER_REGEN_ENABLED" or ev == "ENCOUNTER_END" then
				timer, startTime = nil, nil
				if f.text then
					f.text:SetText(string.format("%s: |cFFFFFFFF00:00|r", LPS:L("Combat")))
				end
			end
			if timer ~= nil and f.text then
				local m = math.floor(timer / 60)
				local s = math.floor(timer % 60)
				f.text:SetText(string.format("%s: |cFFFFFFFF%02d|cFFFFFFFF:%02d|r", LPS:L("Combat"), m, s))
			end
		end,
	})
end
