local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local function formatThousands(n)
	n = tonumber(n) or 0
	local s = tostring(math.floor(n))
	local left, num, right = s:match('^([^%d]*)(%d+)(.-)$')
	num = num:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
	return (left or '') .. num .. (right or '')
end

function LPS:FormatMoneySmart(money)
	money = tonumber(money) or 0
	local gold = math.floor(money / 10000)
	local silver = math.floor((money % 10000) / 100)
	local copper = math.floor(money % 100)

	local parts = {}
	if gold > 0 then
		parts[#parts + 1] = formatThousands(gold) .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
	end
	if silver > 0 then
		parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
	end
	if copper > 0 or (gold == 0 and silver == 0) then
		parts[#parts + 1] = copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	end
	return table.concat(parts, " ")
end

function LPS:FormatMoney(money)
	money = tonumber(money) or 0
	local gold = math.floor(money / 10000)
	local silver = math.floor((money % 10000) / 100)
	local copper = math.floor(money % 100)

	local parts = {}
	if gold > 0 then
		parts[#parts + 1] = formatThousands(gold) .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
	end
	if silver > 0 or gold > 0 then
		parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
	end
	parts[#parts + 1] = copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	return table.concat(parts, " ")
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

local goldMenuFrame

local function ensureGoldMenuFrame()
	if goldMenuFrame and goldMenuFrame.Initialize then
		return goldMenuFrame
	end
	goldMenuFrame = CreateFrame("Frame", "LPS_GoldMenu", UIParent, "UIDropDownMenuTemplate")
	return goldMenuFrame
end

local function getGoldRealmTable()
	local gold = getGoldRoot()
	gold.realms = gold.realms or {}

	local realm = getRealmKey()
	if realm == "" then return end
	gold.realms[realm] = gold.realms[realm] or { chars = {} }
	return realm, gold.realms[realm]
end

function LPS:UpdateGoldCharacterData()
	local gold = getGoldRoot()
	gold.realms = gold.realms or {}

	local realm = getRealmKey()
	if realm == "" then return end
	gold.realms[realm] = gold.realms[realm] or { chars = {} }

	local name = UnitName("player")
	if not name then return end

	local faction = UnitFactionGroup("player")
	local _, classFile = UnitClass("player")
	local money = GetMoney() or 0

	gold.realms[realm].chars[name] = {
		money = money,
		faction = faction,
		class = classFile,
		updated = time and time() or nil,
	}
end

function LPS:ResetGoldCharacterData()
	local _, r = getGoldRealmTable()
	if not (r and r.chars) then return end
	local name = UnitName("player")
	if not name then return end
	r.chars[name] = nil
end

function LPS:ResetGoldCharacterDataByName(name)
	if not name or name == "" then return end
	local _, r = getGoldRealmTable()
	if not (r and r.chars) then return end
	r.chars[name] = nil
end

function LPS:ResetGoldAllCharacterData()
	local _, r = getGoldRealmTable()
	if not r then return end
	r.chars = {}
end

function LPS:ShowGoldResetMenu(owner)
	if not owner then return end

	local realm, r = getGoldRealmTable()
	if not (realm and r and r.chars) then return end

	local menu = ensureGoldMenuFrame()

	local names = {}
	for name in pairs(r.chars) do
		names[#names + 1] = name
	end
	table.sort(names)

	UIDropDownMenu_Initialize(menu, function(_, level)
		local info
		if level ~= 1 then return end

		info = UIDropDownMenu_CreateInfo()
		info.isTitle = true
		info.notCheckable = true
		info.text = LPS:L("Reset character data")
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.text = LPS:L("Reset values")
		info.func = function()
			LPS:ResetGoldAllCharacterData()
			if owner._lpsUpdateFunc then owner._lpsUpdateFunc(owner) end
		end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.isTitle = true
		info.notCheckable = true
		info.text = LPS:L("Characters")
		UIDropDownMenu_AddButton(info, level)

		for _, n in ipairs(names) do
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = n
			info.func = function()
				LPS:ResetGoldCharacterDataByName(n)
				if owner._lpsUpdateFunc then owner._lpsUpdateFunc(owner) end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")

	ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
end

local function ensureSession()
	LPS._goldSession = LPS._goldSession or {}
	local s = LPS._goldSession
	if not s.initialized then
		if not s._initTimerStarted and C_Timer and C_Timer.After then
			s._initTimerStarted = true
			s._initCandidate = GetMoney() or 0
			s._initTries = 0
			local function tryInit()
				if not (LPS and LPS._goldSession) then return end
				local ss = LPS._goldSession
				if not ss or ss.initialized then return end
				ss._initTries = (ss._initTries or 0) + 1
				local m = GetMoney() or 0
				if m == (ss._initCandidate or m) or (ss._initTries or 0) >= 10 then
					ss.start = m
					ss.last = m
					ss.earned = 0
					ss.spent = 0
					ss.initialized = true
					if LPS.UpdateGoldCharacterData then
						LPS:UpdateGoldCharacterData()
					end
					return
				end
				ss._initCandidate = m
				C_Timer.After(0.5, tryInit)
			end
			C_Timer.After(0.5, tryInit)
		end
	end
	return s
end

function LPS:ResetGoldSession()
	local s = ensureSession()
	local m = GetMoney() or 0
	s.start = m
	s.last = m
	s.earned = 0
	s.spent = 0
	s.initialized = true
	s._initTimerStarted = true
end

function LPS:GetGoldSessionData()
	local s = ensureSession()
	local current = GetMoney() or 0
	return {
		current = current,
		earned = s.earned or 0,
		spent = s.spent or 0,
		profit = (s.earned or 0) - (s.spent or 0),
		start = s.start or current,
		currentText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(current)) or tostring(current),
		earnedText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(s.earned or 0)) or tostring(s.earned or 0),
		spentText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(s.spent or 0)) or tostring(s.spent or 0),
		profitText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(((s.earned or 0) - (s.spent or 0)))) or tostring(((s.earned or 0) - (s.spent or 0))),
	}
end

function LPS:OnPlayerMoney()
	local s = ensureSession()
	if not s.initialized then return end
	local current = GetMoney() or 0
	if not s.last then return end
	local diff = current - (s.last or current)
	if diff > 0 then
		s.earned = (s.earned or 0) + diff
	elseif diff < 0 then
		s.spent = (s.spent or 0) + (-diff)
	end
	s.last = current
	if LPS.UpdateGoldCharacterData then
		LPS:UpdateGoldCharacterData()
	end
end

function LPS:CreateGoldFrame()
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder or not LPS.frame.location then return end

	---@type LPSFrameParams
	local params = {
		name = "LPS_Gold",
		frameType = "Button",
		parent = LPS.frame.location,
		anchor = {"LEFT", LPS.frame.location, "RIGHT", 5, 0},
		padding = {((db.layout and db.layout.dtPaddingX) or 10), ((db.layout and db.layout.dtPaddingY) or 6)},
		fontSize = db.settings.fontSize or 12,
		bgColor = {LPS:GetColor("bg")},
		borderColor = {LPS:GetColor("border")},
		updateFunc = function(f)
			local oldData = f.text:GetText()
			LPS:OnPlayerMoney()
			local data = LPS:GetGoldSessionData()
			if f.text then
				f.text:SetText(data.currentText)
			end
			if oldData and oldData ~= data.currentText then
				LPS:ApplyLayout()
			end
		end,
		updateEvent = {events = {"PLAYER_ENTERING_WORLD", "PLAYER_MONEY"}},
		registerClicks = {"LeftButtonUp", "RightButtonUp"},
		onClick = function(self, button)
			if button == "RightButton" then
				if IsControlKeyDown() then
					LPS:ResetGoldSession()
					if self._lpsUpdateFunc then
						self._lpsUpdateFunc(self)
					end
					return
				end
				if IsShiftKeyDown() and LPS.ShowGoldResetMenu then
					LPS:ShowGoldResetMenu(self)
					return
				end
			end
		end,
		tooltipFunc = function(self)
			local d = LPS:GetDB()
			if not d.tooltips.visibility.enable then return end
			if d.tooltips.visibility.combat and InCombatLockdown() then return end
			if d.tooltips.gold and d.tooltips.gold.enable == false then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			if LPS.BuildGoldTooltip then
				LPS:BuildGoldTooltip(GameTooltip)
			end
			GameTooltip:Show()
		end,
	}

	return LPS:CreateFrame(params)
end
