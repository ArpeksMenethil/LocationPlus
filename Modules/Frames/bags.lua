local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Bags
do
	local function freeTotal()
		local NUM_BAG_SLOTS = NUM_BAG_SLOTS or (C_Container and C_Container.NUM_BAG_SLOTS) or 4
		local free, total = 0, 0
		for i = 0, NUM_BAG_SLOTS do
			-- На новых клиентах глобальные GetContainer* перенесены в C_Container
			local f, t
			if C_Container and C_Container.GetContainerNumFreeSlots then
				f = C_Container.GetContainerNumFreeSlots(i)
				t = C_Container.GetContainerNumSlots(i)
			elseif GetContainerNumFreeSlots then
				f = GetContainerNumFreeSlots(i)
				t = GetContainerNumSlots(i)
			end
			if t and t > 0 then
				free = free + (f or 0)
				total = total + t
			end
		end
		return free, total
	end

	LPS:RegisterDatatext({
		key = "bags",
		nameKey = "Bags",
		events = { "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE" },
		update = function(f)
			-- Настройка отображения живёт на вкладке Show: db.show.bags
			local d = LPS:GetDB()
			local cfg = (d and d.show and d.show.bags) or {}
			local free, total = freeTotal()
			local used = total - free
			local label = (cfg.label ~= nil and cfg.label ~= "") and (cfg.label .. ": ") or (LPS:L("BAGS") .. ": ")
			if f.text then
				if cfg.noLabel then label = "" end
				if cfg.display == "FREE" then
					f.text:SetText(label .. tostring(free))
				elseif cfg.display == "USED" then
					f.text:SetText(label .. tostring(used))
				else
					f.text:SetText(label .. used .. "/" .. total)
				end
			end
		end,
		onClick = function(self, button)
			if ToggleAllBags and button == "LeftButton" then ToggleAllBags() end
		end,
	})
end
