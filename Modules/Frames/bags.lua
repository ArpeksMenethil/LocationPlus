local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Bags
do
	local function freeTotal()
		local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4
		local free, total = 0, 0
		for i = 0, NUM_BAG_SLOTS do
			if GetContainerNumFreeSlots then
				local f = GetContainerNumFreeSlots(i)
				local t = GetContainerNumSlots(i)
				if t and t > 0 then
					free = free + (f or 0)
					total = total + t
				end
			end
		end
		return free, total
	end

	LPS:RegisterDatatext({
		key = "bags",
		name = LPS:L("Bags"),
		events = { "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE" },
		update = function(f)
			local cfg = DT.panelCfg("bags") or {}
			local free, total = freeTotal()
			local used = total - free
			local label = (cfg.label ~= nil and cfg.label ~= "") and (cfg.label .. ": ") or (LPS:L("Bags") .. ": ")
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
		onClick = function(self)
			if ToggleAllBags then ToggleAllBags() end
		end,
tooltip = function(tt)
        			tt:AddDoubleLine(LPS:L("Bags"), LPS:L("Used slots") .. " / " .. LPS:L("Total"), 1, 0.82, 0, 1, 1, 1)
        			tt:AddLine(" ")
        			local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4
        			for i = 0, NUM_BAG_SLOTS do
        				local bagName = (C_Container and C_Container.GetBagName) and C_Container.GetBagName(i) or GetBagName(i)
        				if bagName then
        					local numSlots = GetContainerNumSlots(i) or 0
        					local freeSlots = (GetContainerNumFreeSlots and GetContainerNumFreeSlots(i)) or 0
        					local used = numSlots - freeSlots
        					local pct = numSlots > 0 and (used / numSlots) or 0
        					local r, g, b = DT.colorGradient(pct, .1, 1, .1, 1, 1, .1, 1, .1, .1)
        					tt:AddDoubleLine(bagName, string.format("%d / %d", used, numSlots), 1, 1, 1, r, g, b)
        				end
        			end
		end,
	})
end
