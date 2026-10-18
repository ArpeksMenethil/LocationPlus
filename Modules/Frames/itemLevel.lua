local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Item Level
do
	LPS:RegisterDatatext({
		key = "itemLevel",
		name = LPS:L("Item Level"),
		events = { "PLAYER_AVG_ITEM_LEVEL_UPDATE", "PLAYER_ENTERING_WORLD", "UNIT_INVENTORY_CHANGED" },
		update = function(f)
			if not GetAverageItemLevel then
				if f.text then f.text:SetText(NOT_APPLICABLE or "-") end
				return
			end
			local avg, avgEquipped = GetAverageItemLevel()
			if f.text then
				f.text:SetText(string.format("%s: %.1f", ITEM_LEVEL_ABBR or LPS:L("ilvl"), avgEquipped or avg or 0))
			end
		end,
tooltip = function(tt)
        			if not GetAverageItemLevel then return end
        			local avg, avgEquipped, avgPvp = GetAverageItemLevel()
        			tt:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL or LPS:L("Average item level"), string.format("%.2f", avg or 0), 1, 1, 1, 1, 1, 1)
        			tt:AddDoubleLine(LPS:L("Equipped") or "Equipped", string.format("%.2f", avgEquipped or 0), 1, 1, 1, 1, 1, 1)
        			if avgPvp then
        				tt:AddDoubleLine(PVP_LEVEL or LPS:L("PvP"), string.format("%.2f", avgPvp), 1, 1, 1, 1, 1, 1)
        			end
        			tt:AddLine(" ")
        			local slots = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
        			for _, k in ipairs(slots) do
        				local link = GetInventoryItemLink("player", k)
        				if link then
        					local ilvl = select(3, GetItemInfo(link))
        					local icon = GetInventoryItemTexture("player", k)
        					if ilvl and ilvl > 0 then
        						tt:AddDoubleLine(icon and string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, link) or link,
        							string.format("%d", ilvl), 1, 1, 1, 1, 1, 1)
        					end
        				end
        			end
		end,
	})
end
