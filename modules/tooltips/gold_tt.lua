local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

function LPS:BuildGoldTooltip(tt)
	local data = LPS.GetGoldSessionData and LPS:GetGoldSessionData() or nil
	if not data then return end

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

	local function getRealmKey()
		if GetNormalizedRealmName then
			return GetNormalizedRealmName() or GetRealmName() or ""
		end
		return GetRealmName() or ""
	end

	local function getGoldRoot()
		if LPS.GetAccountDB then
			local a = LPS:GetAccountDB()
			if a then
				a.gold = a.gold or {}
				return a.gold
			end
		end
		LPS_DB = LPS_DB or {}
		LPS_DB.global = LPS_DB.global or {}
		LPS_DB.global.gold = LPS_DB.global.gold or {}
		return LPS_DB.global.gold
	end

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

	tt:AddLine(LPS:L("Session")..":", headerR, headerG, headerB)
	tt:AddDoubleLine(LPS:L("Earned")..":", moneyText(data.earned), whiteR, whiteG, whiteB, 1, 1, 1)
	tt:AddDoubleLine(LPS:L("Spent")..":", moneyText(data.spent), whiteR, whiteG, whiteB, 1, 1, 1)
	if profit >= 0 then
		tt:AddDoubleLine(LPS:L("Profit")..":", profitText, 0.1, 1, 0.1, 0.1, 1, 0.1)
	else
		tt:AddDoubleLine(LPS:L("Loss")..":", profitText, 1, 0.1, 0.1, 1, 0.1, 0.1)
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

	if #allChars > 0 then
		table.sort(allChars, function(a, b)
			if a.money == b.money then
				return tostring(a.name) < tostring(b.name)
			end
			return a.money > b.money
		end)
		tt:AddLine(" ")
		tt:AddLine(LPS:L("Characters")..":", headerR, headerG, headerB)
		for _, c in ipairs(allChars) do
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

	tt:AddLine(" ")
	tt:AddLine(LPS:L("On server")..":", headerR, headerG, headerB)
	tt:AddDoubleLine(LPS:L("Alliance")..":", moneyText(allyTotal), 0.41, 0.8, 0.94, whiteR, whiteG, whiteB)
	tt:AddDoubleLine(LPS:L("Horde")..":", moneyText(hordeTotal), 1, 0.1, 0.1, whiteR, whiteG, whiteB)
	tt:AddDoubleLine(LPS:L("Total")..":", moneyText(accountTotal), whiteR, whiteG, whiteB, whiteR, whiteG, whiteB)
	tt:AddLine(" ")

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
	if warbandApiOk or warbandMoney ~= nil then
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
	if tokenPrice and tonumber(tokenPrice) and tonumber(tokenPrice) > 0 then
		tt:AddLine(" ")
		tt:AddDoubleLine(LPS:L("WoW Token")..":", moneyText(tokenPrice), 0.41, 0.8, 0.94, whiteR, whiteG, whiteB)
	end

	local watched = 0
	if C_CurrencyInfo and C_CurrencyInfo.GetNumWatchedTokens then
		watched = C_CurrencyInfo.GetNumWatchedTokens() or 0
	elseif GetNumWatchedTokens then
		watched = GetNumWatchedTokens() or 0
	end
	if watched > 0 then
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

	tt:AddLine(" ")
	tt:AddLine(LPS:L("Reset session data")..": "..LPS:L("Ctrl+RMB"), 0.41, 0.8, 0.94)
	tt:AddLine(LPS:L("Reset character data")..": "..LPS:L("Shift+RMB"), 0.41, 0.8, 0.94)
end
