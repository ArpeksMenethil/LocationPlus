local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Currencies
do
	local function watchedTokens()
		local list = {}
		if C_TokenFrame and C_TokenFrame.GetWatchTokenInfo then
			for i = 1, MAX_WATCHED_TOKENS or 3 do
				local id = select(1, C_TokenFrame.GetWatchTokenInfo(i))
				if not id then break end
				list[#list + 1] = id
			end
		elseif GetBackpackCurrencyInfo then
			for i = 1, MAX_WATCHED_TOKENS or 3 do
				local name, count, icon = GetBackpackCurrencyInfo(i)
				if not name then break end
				list[#list + 1] = { name = name, count = count, icon = icon }
			end
		end
		return list
	end

	LPS:RegisterDatatext({
		key = "currencies",
		name = LPS:L("Currencies"),
		events = { "CURRENCY_DISPLAY_UPDATE", "CHAT_MSG_CURRENCY", "PLAYER_MONEY" },
		update = function(f)
			local tokens = watchedTokens()
			local first = tokens[1]
			if type(first) == "table" and first.icon then
				if f.text then
					f.text:SetText(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", first.icon, DT.shortValue(first.count)))
				end
			else
				if f.text then f.text:SetText(LPS:FormatMoneySmart(GetMoney() or 0)) end
			end
		end,
		onClick = function()
			if TokenFrame and ToggleCharacter then
				ToggleCharacter("TokenFrame")
			end
		end,
	})
end
