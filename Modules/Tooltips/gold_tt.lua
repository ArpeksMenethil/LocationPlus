local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:BuildGoldTooltip(tt)
	local db = LPS.GetDB and LPS:GetDB() or nil
	local cfg = db and db.tooltips and db.tooltips.gold or nil
	if cfg and cfg.enable == false then return end

	local data = LPS.GetGoldSessionData and LPS:GetGoldSessionData() or nil
	if not data then return end
	local rB, gB, bB = LPS:GetColor("tooltipSetting")

	local function formatSignedMoney(amount, formatted)
		amount = tonumber(amount) or 0
		formatted = formatted or ""
		if amount < 0 then
			return "-" .. formatted
		end
		return formatted
	end

	local function moneyText(m)
		if LPS.FormatMoneySmart then
			return LPS:FormatMoneySmart(m)
		end
		if LPS.FormatMoney then
			return LPS:FormatMoney(m)
		end
		return tostring(m or 0)
	end

	-- ОПТИМИЗАЦИЯ (duplicates): локальные копии функций заменены общими методами аддона
	local function getRealmKey() return LPS:GetGoldRealmKey() end
	local function getGoldRoot() return LPS:GetGoldRoot() end

	local function factionIcon(faction)
		if faction == "Alliance" or faction == "Horde" then
			return string.format([[|TInterface\FriendsFrame\PlusManz-%s:14|t]], faction)
		end
		return ""
	end

	local function classColoredName(name, classFile)
		local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
		if c and c.colorStr then
			return "|c" .. c.colorStr .. name .. "|r"
		end
		return name
	end

	local function greenDot()
		return [[ |TInterface\COMMON\Indicator-Green:14|t]]
	end

	local profit = tonumber(data.profit) or 0
	local profitText = formatSignedMoney(profit, moneyText(math.abs(profit)))

	local headerR, headerG, headerB = 1, 0.82, 0
	local whiteR, whiteG, whiteB = 1, 1, 1

	if not cfg or cfg.session ~= false then
		tt:AddLine(LPS:L("Session")..":", headerR, headerG, headerB)
		tt:AddDoubleLine(LPS:L("Earned")..":", moneyText(data.earned), whiteR, whiteG, whiteB, 1, 1, 1)
		tt:AddDoubleLine(LPS:L("Spent")..":", moneyText(data.spent), whiteR, whiteG, whiteB, 1, 1, 1)
		if profit >= 0 then
			tt:AddDoubleLine(LPS:L("Profit")..":", profitText, 0.1, 1, 0.1, 0.1, 1, 0.1)
		else
			tt:AddDoubleLine(LPS:L("Loss")..":", profitText, 1, 0.1, 0.1, 1, 0.1, 0.1)
		end
	end

	local realm = getRealmKey()
	local allChars = {}
	local allyTotal, hordeTotal, realmTotal, accountTotal = 0, 0, 0, 0
	local currentName = UnitName("player")

	local gold = getGoldRoot()
	if gold and gold.realms and realm ~= "" then
		local r = gold.realms[realm]
		if r and r.chars then
			for name, info in pairs(r.chars) do
				local money = tonumber(info and info.money) or 0
				local faction = info and info.faction
				local classFile = info and info.class
				allChars[#allChars + 1] = {
					name = name,
					money = money,
					faction = faction,
					class = classFile,
				}
				realmTotal = realmTotal + money
				if faction == "Alliance" then
					allyTotal = allyTotal + money
				elseif faction == "Horde" then
					hordeTotal = hordeTotal + money
				end
			end
		end
	end

	if gold and gold.realms then
		for _, realmInfo in pairs(gold.realms) do
			if realmInfo and realmInfo.chars then
				for _, info in pairs(realmInfo.chars) do
					accountTotal = accountTotal + (tonumber(info and info.money) or 0)
				end
			end
		end
	end

	if (not cfg or (cfg.characters ~= false and cfg.characters ~= nil)) and #allChars > 0 then
		table.sort(allChars, function(a, b)
			if a.money == b.money then
				return tostring(a.name) < tostring(b.name)
			end
			return a.money > b.money
		end)
		if cfg.session ~= false then
			tt:AddLine(" ")
		end
		tt:AddLine(LPS:L("Characters")..":", headerR, headerG, headerB)
		local maxChars = (cfg and tonumber(cfg.charactersMax)) or 20
		if maxChars < 3 then maxChars = 3 elseif maxChars > 40 then maxChars = 40 end
		local shown = 0
		for _, c in ipairs(allChars) do
			shown = shown + 1
			if shown > maxChars then break end
			local icon = factionIcon(c.faction)
			local left = classColoredName(c.name, c.class)
			if icon ~= "" then
				left = icon .. " " .. left
			end
			if currentName and c.name == currentName then
				left = left .. greenDot()
			end
			tt:AddDoubleLine(left, moneyText(c.money), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
		end
	end

	if not cfg or cfg.serverTotals ~= false then
		tt:AddLine(" ")
		tt:AddLine(LPS:L("On server")..":", headerR, headerG, headerB)
		tt:AddDoubleLine(LPS:L("Alliance")..":", moneyText(allyTotal), rB, gB, bB, whiteR, whiteG, whiteB)
		tt:AddDoubleLine(LPS:L("Horde")..":", moneyText(hordeTotal), 1, 0.1, 0.1, whiteR, whiteG, whiteB)
		tt:AddDoubleLine(LPS:L("Total")..":", moneyText(accountTotal), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
	end

	if LPS.Retail then
		local warbandMoney
		if gold then
			warbandMoney = tonumber(gold.warbandMoney)
		end
		local warbandApiOk = false
		if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account then
			warbandApiOk = true
			local bankType = Enum.BankType.Account
			local ok, v = pcall(C_Bank.FetchDepositedMoney, bankType)
			if ok and v ~= nil then
				warbandMoney = tonumber(v) or warbandMoney
				if gold then
					gold.warbandMoney = warbandMoney
				end
			end
		end
		if (not cfg or cfg.warband ~= false) and (warbandApiOk or warbandMoney ~= nil) then
			tt:AddLine(" ")
			tt:AddDoubleLine(LPS:L("Warband")..":", moneyText(warbandMoney or 0), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
			if warbandApiOk then
				tt:AddDoubleLine(LPS:L("Total")..":", moneyText(accountTotal + (tonumber(warbandMoney) or 0)), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
			end
		end

		local tokenPrice
		if C_WowTokenPublic and C_WowTokenPublic.GetCurrentMarketPrice then
			tokenPrice = C_WowTokenPublic.GetCurrentMarketPrice()
		elseif C_WowTokenPublic and C_WowTokenPublic.GetCurrentPrice then
			tokenPrice = C_WowTokenPublic.GetCurrentPrice()
		elseif GetWowTokenMarketPrice then
			tokenPrice = GetWowTokenMarketPrice()
		end
		
		if (not cfg or cfg.token ~= false) and tokenPrice and tonumber(tokenPrice) and tonumber(tokenPrice) > 0 then
			tt:AddLine(" ")
			tt:AddDoubleLine(LPS:L("WoW Token")..":", moneyText(tokenPrice), rB, gB, bB, whiteR, whiteG, whiteB)
		elseif (not cfg or cfg.token ~= false) and C_WowTokenPublic and C_WowTokenPublic.UpdateMarketPrice then
			-- FIX: был вызов без проверки наличия API (падает на Classic/TBC, где C_WowTokenPublic нет)
			C_WowTokenPublic.UpdateMarketPrice()
		end
	end

	local watched = 0
	if C_CurrencyInfo and C_CurrencyInfo.GetNumWatchedTokens then
		watched = C_CurrencyInfo.GetNumWatchedTokens() or 0
	elseif GetNumWatchedTokens then
		watched = GetNumWatchedTokens() or 0
	end
	if (not cfg or cfg.currency ~= false) and watched > 0 then
		tt:AddLine(" ")
		tt:AddLine(LPS:L("Currency"), headerR, headerG, headerB)
		for i = 1, watched do
			local name, amount, icon
			if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
				local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
				if info then
					name = info.name
					amount = info.quantity
					icon = info.iconFileID
				end
			elseif GetBackpackCurrencyInfo then
				name, amount, icon = GetBackpackCurrencyInfo(i)
			end
			if name and amount then
				local left = (icon and ("|T" .. icon .. ":14:14:0:0|t ") or "") .. name
				tt:AddDoubleLine(left, tostring(amount), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
			end
		end
	end

	if not cfg or cfg.resetHints ~= false then
		tt:AddLine(" ")
		tt:AddDoubleLine(LPS:L("Ctrl+RMB"), LPS:L("Reset session data"), rB, gB, bB, rB, gB, bB)
		tt:AddDoubleLine(LPS:L("Shift+RMB"), LPS:L("Reset character data"), rB, gB, bB, rB, gB, bB)
	end
end
