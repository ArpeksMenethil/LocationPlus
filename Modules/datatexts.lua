local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--------------------------------------------------------------------
-- Панели-инфотексты (по мотивам DataTexts из ElvUI)
-- Реестр панелей + общий конструктор фреймов.
--------------------------------------------------------------------

local unpackFn = table.unpack or unpack

-- Ключи слотов layout.sideSlots, которые нельзя переназначать (зарезервированы под старые панели)
local RESERVED_SLOT_KEYS = { time = true, gold = true, system = true }

-- Реестр: key -> конфиг панели
local registry = {}
LPS.datatexts = registry

-- Порядок панелей в списках выбора и в настройках
local orderList = {
	"coords",          -- существующая
	"bags",            -- Bags
	"combatIndicator", -- Combat Indicator
	"combatTime",      -- Combat/Arena Time
	"currencies",      -- Currencies
	"dps",             -- DPS
	"difficulty",      -- Difficulty
	"durability",      -- Durability
	"experience",      -- Experience
	"friends",         -- Friends
	"guild",           -- Guild
	"hps",             -- HPS
	"itemLevel",       -- Item Level
	"mail",            -- Mail
	"microBar",        -- Micro Bar
	"quests",          -- Quests
	"reputation",      -- Reputation
	"timePlayed",      -- Time Played
	"volume",          -- Volume
	"armor",           -- Armor
	"attackPower",     -- Attack Power
	"spellPower",      -- Spell Power
	"healPower",       -- Heal Power
	"crit",            -- Crit Chance
	"haste",           -- Haste
	"mastery",         -- Mastery
	"strength",        -- Strength
	"agility",         -- Agility
	"stamina",         -- Stamina
	"intellect",       -- Intellect
	"spirit",          -- Spirit
}

--------------------------------------------------------------------
-- Вспомогальные функции
--------------------------------------------------------------------

-- Проверка значения на «секретность» (WotLK Classic 3.4+ / Retail secret values)
local function E_NotSecret(v)
	if v == nil then return false end
	if IsRestrictedTable and IsRestrictedTable(v) then return false end
	return true
end

local function shortValue(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.2fk", n / 1e3) end
	return tostring(math.floor(n))
end
LPS.ShortValue = shortValue

local function hexFromRGB(r, g, b)
	return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

local function colorGradient(pct, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	pct = math.max(0, math.min(1, tonumber(pct) or 0))
	local r, g, b
	if pct < 0.5 then
		local f = pct * 2
		r, g, b = r1 + (r2 - r1) * f, g1 + (g2 - g1) * f, b1 + (b2 - b1) * f
	else
		local f = (pct - 0.5) * 2
		r, g, b = r2 + (r3 - r2) * f, g2 + (g3 - g2) * f, b2 + (b3 - b2) * f
	end
	return r, g, b
end

local function classColorHex(classFile)
	local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if c then return hexFromRGB(c.r, c.g, c.b) end
	return "|cFFFFFFFF"
end

local function levelColorHex(level)
	level = tonumber(level) or 0
	if GetQuestDifficultyColor then
		local c = GetQuestDifficultyColor(level)
		return hexFromRGB(c.r, c.g, c.b)
	end
	return "|cFFFFFFFF"
end

local function panelCfg(key)
	local db = LPS:GetDB()
	return db and db.panels and db.panels[key]
end

-- Тултип-хелпер: стандартная проверка видимости подсказок
local function tooltipGuard(key)
	local d = LPS:GetDB()
	if not d then return false end
	if not (d.tooltips and d.tooltips.visibility and d.tooltips.visibility.enable) then return false end
	if d.tooltips.visibility.combat and InCombatLockdown() then return false end
	local cfg = panelCfg(key)
	if cfg and cfg.tooltip == false then return false end
	return true
end
LPS._DTTooltipGuard = tooltipGuard

local function openTooltip(self, buildFunc)
	if GameTooltip.EasyTooltip_SetDefaultAnchor then
		GameTooltip:EasyTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	end
	GameTooltip:ClearLines()
	buildFunc(GameTooltip)
	GameTooltip:Show()
end
LPS._DTOpenTooltip = openTooltip

-- Меню через UIDropDownMenu (без зависимости от ElvUI EasyMenu)
local menuFrame
local function showMenu(anchorFrame, list)
	if not menuFrame then
		menuFrame = CreateFrame("Frame", "LPS_DTMenu", UIParent, "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(menuFrame, function(_, level)
		for _, entry in ipairs(list) do
			if level == 1 then
				local info = UIDropDownMenu_CreateInfo()
				info.text = entry.text
				info.notCheckable = entry.notCheckable ~= false
				info.isTitle = entry.isTitle
				info.disabled = entry.disabled
				if entry.func then
					info.func = function() entry.func() end
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end, "MENU")
	ToggleDropDownMenu(1, nil, menuFrame, anchorFrame, 0, 0)
end
LPS._DTShowMenu = showMenu

--------------------------------------------------------------------
-- Конструктор панели
--------------------------------------------------------------------

--- Регистрирует панель инфотекста.
---@param def table { key, name, events, ticker, update(f), onClick(self,button), tooltip(tt), create(f) }
function LPS:RegisterDatatext(def)
	assert(def and def.key and def.name, "LPS RegisterDatatext: bad definition")
	registry[def.key] = def
end

--- Создаёт фрейм панели по её конфигу (вызывается из ApplyLayout при первом использовании слота)
function LPS:CreateDatatextFrame(key)
	local def = registry[key]
	if not def then return nil end
	local db = LPS:GetDB()
	if not db or not LPS.frame.holder or not LPS.frame.location then return nil end
	-- панель с настройкой enable (временно отключённая) не создаётся
	local pCfg = db.panels and db.panels[key]
	if pCfg and pCfg.enable == false then return nil end

	---@type LPSFrameParams
	local params = {
		name = "LPS_" .. key:gsub("^%l", string.upper),
		frameType = "Button",
		parent = LPS.frame.location,
		anchor = { "LEFT", LPS.frame.location, "RIGHT", 5, 0 },
		padding = { ((db.layout and db.layout.dtPaddingX) or 10), ((db.layout and db.layout.dtPaddingY) or 6) },
		fontSize = db.settings.fontSize or 12,
		bgColor = { LPS:GetColor("bg") },
		borderColor = { LPS:GetColor("border") },
		updateFunc = function(f)
			if def.update then def.update(f) end
		end,
	}

	if def.events then
		params.updateEvent = { events = def.events }
	elseif def.ticker then
		params.updateTicker = { interval = def.ticker }
	end

	if def.onClick then
		params.registerClicks = { "LeftButtonUp", "RightButtonUp" }
		params.onClick = function(self, button) def.onClick(self, button) end
	end

	if def.tooltip then
		params.tooltipFunc = function(self)
			if not tooltipGuard(key) then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:ClearLines()
			def.tooltip(GameTooltip)
			GameTooltip:Show()
		end
	end

	local f = LPS:CreateFrame(params)
	if f and def.create then def.create(f) end
	-- первичное заполнение
	if f and f._lpsUpdateFunc then f._lpsUpdateFunc(f) end
	return f
end

--------------------------------------------------------------------
-- Первичное обновление после входа в мир: пересобираем layout,
-- чтобы занятые слоты создали недостающие панели.
--------------------------------------------------------------------

do
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:SetScript("OnEvent", function(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if LPS.InvalidateLayoutCache then LPS:InvalidateLayoutCache() end
		if LPS.ApplyLayout then LPS:ApplyLayout() end
	end)
end

--------------------------------------------------------------------
-- Определения панелей
--------------------------------------------------------------------

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
			local cfg = panelCfg("bags") or {}
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
					local r, g, b = colorGradient(pct, .1, 1, .1, 1, 1, .1, 1, .1, .1)
					tt:AddDoubleLine(bagName, string.format("%d / %d", used, numSlots), 1, 1, 1, r, g, b)
				end
			end
		end,
	})
end

-------------------------------------------------- Combat Indicator
do
	LPS:RegisterDatatext({
		key = "combatIndicator",
		name = LPS:L("Combat Indicator"),
		events = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" },
		update = function(f)
			local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
			local text
			if inCombat then
				text = "|cFFFF3333" .. LPS:L("In Combat") .. "|r"
			else
				text = "|cFF2BC226" .. LPS:L("Out of Combat") .. "|r"
			end
			if f.text then f.text:SetText(text) end
		end,
	})
end

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
					f.text:SetText(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", first.icon, shortValue(first.count)))
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
		tooltip = function(tt)
			tt:AddLine(CURRENCY or LPS:L("Currencies"), 1, 0.82, 0)
			tt:AddLine(" ")
			local tokens = watchedTokens()
			for _, cur in ipairs(tokens) do
				if type(cur) == "table" then
					tt:AddDoubleLine(string.format("|T%s:16:16:0:0:64:64:4:60:4:60|t %s", cur.icon, cur.name), tostring(cur.count), 1, 1, 1, 1, 1, 1)
				end
			end
			tt:AddLine(" ")
			tt:AddDoubleLine((LPS:L("Gold") or GOLD)..":", LPS:FormatMoneySmart(GetMoney() or 0), nil, nil, nil, 1, 1, 1)
		end,
	})
end

-------------------------------------------------- DPS / HPS (боевой лог)
do
	local subDmg = {
		SWING_DAMAGE = true, RANGE_DAMAGE = true, SPELL_DAMAGE = true,
		SPELL_PERIODIC_DAMAGE = true, DAMAGE_SHIELD = true, DAMAGE_SPLIT = true,
		SPELL_EXTRA_ATTACKS = true,
	}
	local subHeal = {
		SWING_HEALING = true, RANGE_HEALING = true, SPELL_HEALING = true,
		SPELL_PERIODIC_HEALING = true, DAMAGING_HOUSE = nil,
	}
	local combatLogFrame
	local lastSegment, timeStamp, combatTime, dmgTotal, healTotal = 0, 0, 0, 0, 0

	local function getCLE()
		return (C_CombatLog and C_CombatLog.GetCurrentEventInfo) or CombatLogGetCurrentEventInfo
	end

	local function ensureLog()
		if combatLogFrame then return end
		combatLogFrame = CreateFrame("Frame")
		combatLogFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		combatLogFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		combatLogFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		combatLogFrame:RegisterEvent("UNIT_PET")
		local myGUID = nil
		combatLogFrame:SetScript("OnEvent", function(self, event)
			if event == "UNIT_PET" then
				myGUID = myGUID or UnitGUID("player")
			elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVE_COMBAT" then
				local now = time()
				if now - lastSegment > 20 then
					timeStamp, combatTime, dmgTotal, healTotal = 0, 0, 0, 0
				end
				lastSegment = now
			elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
				myGUID = myGUID or UnitGUID("player")
				local srcGUID
				local timestamp, subEvent, _, sourceGUID = getCLE()()
				if sourceGUID ~= myGUID then return end
				if subDmg[subEvent] then
					if timeStamp == 0 then timeStamp = timestamp end
					lastSegment = timestamp
					combatTime = timestamp - timeStamp
					local amount, overkill
					if subEvent == "SWING_DAMAGE" then
						_, _, _, _, _, _, _, _, _, amount, _, _, _, _, overkill = getCLE()()
					else
						amount, _, _, _, _, _, _, overkill = select(12, getCLE()())
					end
					dmgTotal = dmgTotal + math.max(0, (amount or 0) - (overkill or 0))
				elseif subHeal[subEvent] then
					if timeStamp == 0 then timeStamp = timestamp end
					lastSegment = timestamp
					combatTime = timestamp - timeStamp
					local amount, overhealing
					if subEvent == "SWING_HEALING" then
						amount, _, _, _, _, _, _, _, _, overhealing = select(10, getCLE()())
					else
						amount, _, _, _, _, _, overhealing = select(12, getCLE()())
					end
					healTotal = healTotal + math.max(0, (amount or 0) - (overhealing or 0))
				end
				LPS:_RefreshCombatStats()
			end
		end)
	end

	local updaters = {}
	function LPS:_RefreshCombatStats()
		for _, fn in ipairs(updaters) do fn() end
	end

	local function makeStatPanel(key, label, getter, resetter)
		LPS:RegisterDatatext({
			key = key,
			name = label,
			ticker = 0.5,
			create = function(f)
				ensureLog()
				local fn = function()
					if f.text and f:IsShown() then
						f.text:SetText(string.format("%s: %s", label, shortValue(getter())))
					end
				end
				updaters[#updaters + 1] = fn
				f._lpsUpdater = fn
			end,
			update = function(f)
				if f.text then
					f.text:SetText(string.format("%s: %s", label, shortValue(getter())))
				end
			end,
			onClick = function(self)
				resetter()
				if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end
			end,
		})
	end

	makeStatPanel("dps", STAT_DPS_SHORT or LPS:L("DPS"),
		function() return combatTime > 0 and (dmgTotal / combatTime) or 0 end,
		function() timeStamp, combatTime, dmgTotal = 0, 0, 0 end)

	makeStatPanel("hps", LPS:L("HPS"),
		function() return combatTime > 0 and (healTotal / combatTime) or 0 end,
		function() timeStamp, combatTime, healTotal = 0, 0, 0 end)
end

-------------------------------------------------- Difficulty
do
	local function diffLabel(id)
		if GetDifficultyInfo then
			local name = GetDifficultyInfo(id)
			if name then return name end
		end
		return tostring(id)
	end

	LPS:RegisterDatatext({
		key = "difficulty",
		name = LPS:L("Difficulty"),
		events = { "PLAYER_DIFFICULTY_CHANGED", "LOADING_SCREEN_DISABLED", "ZONE_CHANGED_NEW_AREA" },
		update = function(f)
			if not GetInstanceInfo then return end
			local _, instanceType, difficultyID = GetInstanceInfo()
			local text
			if instanceType and instanceType ~= "none" and difficultyID then
				text = string.format("%s: %s", instanceType == "raid" and LPS:L("Raid") or LPS:L("Dungeon"), diffLabel(difficultyID))
			else
				local dd = GetDungeonDifficultyID and GetDungeonDifficultyID()
				local rd = GetRaidDifficultyID and GetRaidDifficultyID()
				text = string.format("%s: %s  |  %s: %s",
					LPS:L("Dungeon"), dd and diffLabel(dd) or "?",
					LPS:L("Raid"), rd and diffLabel(rd) or "?")
			end
			if f.text then f.text:SetText(text) end
		end,
		tooltip = function(tt)
			tt:AddLine(LPS:L("Current Difficulties:") or LPS:L("Difficulty"), 1, 0.82, 0)
			tt:AddLine(" ")
			if GetDungeonDifficultyID then
				tt:AddDoubleLine(LPS:L("Dungeon"), diffLabel(GetDungeonDifficultyID()), 1, 1, 1, 1, 1, 1)
			end
			if GetRaidDifficultyID then
				tt:AddDoubleLine(LPS:L("Raid"), diffLabel(GetRaidDifficultyID()), 1, 1, 1, 1, 1, 1)
			end
		end,
	})
end

-------------------------------------------------- Durability
do
	local inventorySlots = {
		INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_WAIST = 6,
		INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
		INVTYPE_WEAPONMAINHAND = 16, INVTYPE_WEAPONOFFHAND = 17, INVTYPE_RANGED = 18,
	}

	LPS:RegisterDatatext({
		key = "durability",
		name = LPS:L("Durability"),
		events = { "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED" },
		update = function(f)
			local minPct = 100
			local any = false
			for _, index in pairs(inventorySlots) do
				local cur, max = GetInventoryItemDurability(index)
				if cur and max and max > 0 then
					any = true
					local perc = cur / max * 100
					if perc < minPct then minPct = perc end
				end
			end
			if not any then minPct = nil end
			if f.text then
				if minPct then
					local r, g, b = colorGradient(minPct * 0.01, 1, .1, .1, 1, 1, .1, .1, 1, .1)
					f.text:SetText(string.format("%s%d%%|r", hexFromRGB(r, g, b), math.floor(minPct + 0.5)))
				else
					f.text:SetText("-")
				end
			end
		end,
		onClick = function()
			if not InCombatLockdown() and ToggleCharacter then
				ToggleCharacter("PaperDollFrame")
			end
		end,
		tooltip = function(tt)
			tt:AddLine(DURABILITY or LPS:L("Durability"), 1, 0.82, 0)
			tt:AddLine(" ")
			for slotName, index in pairs(inventorySlots) do
				local cur, max = GetInventoryItemDurability(index)
				if cur and max and max > 0 then
					local perc = math.floor(cur / max * 100 + 0.5)
					local link = GetInventoryItemLink("player", index) or _G[slotName] or slotName
					local icon = GetInventoryItemTexture("player", index)
					local r, g, b = colorGradient(perc * 0.01, 1, .1, .1, 1, 1, .1, .1, 1, .1)
					tt:AddDoubleLine(icon and string.format("|T%s:14:14:0:0:64:64:4:60:4:60|t %s", icon, link) or link,
						string.format("%d%%", perc), 1, 1, 1, r, g, b)
				end
			end
		end,
	})
end

-------------------------------------------------- Experience
do
	LPS:RegisterDatatext({
		key = "experience",
		name = LPS:L("Experience"),
		events = { "PLAYER_XP_UPDATE", "DISABLE_XP_GAIN", "ENABLE_XP_GAIN", "UPDATE_EXHAUSTION", "LEVEL_UP" },
		update = function(f)
			if not UnitXP or not UnitXPMax then return end
			local level = UnitLevel("player")
			local maxPlayer = MAX_PLAYER_LEVEL or (GetMaxLevelForPlayer and GetMaxLevelForPlayer(select(4, GetBuildInfo())))
			if level == nil or level <= 0 or (maxPlayer and level >= maxPlayer) then
				if f.text then f.text:SetText(MAX_LEVEL or LPS:L("Max Level")) end
				return
			end
			local cur, max = UnitXP("player"), UnitXPMax("player")
			if not max or max == 0 then
				if f.text then f.text:SetText(MAX_LEVEL or LPS:L("Max Level")) end
				return
			end
			local cfg = panelCfg("experience") or {}
			local pct = cur / max * 100
			local rested = GetXPExhaustion and GetXPExhaustion()
			local text
			if cfg.display == "CURMAX" then
				text = string.format("%s / %s", shortValue(cur), shortValue(max))
			elseif cfg.display == "CUR" then
				text = shortValue(cur)
			elseif cfg.display == "REM" then
				text = shortValue(max - cur)
			else
				text = string.format("%.2f%%", pct)
			end
			if rested and rested > 0 then
				text = text .. string.format(" |cFF00FF00+%s|r", shortValue(rested))
			end
			if f.text then f.text:SetText(text) end
		end,
		tooltip = function(tt)
			local level = UnitLevel("player")
			tt:AddDoubleLine(LPS:L("Experience"), string.format("%s %d", LPS:L("Level") or LEVEL, level), 1, 0.82, 0, 1, 1, 1)
			tt:AddLine(" ")
			local cur, max = UnitXP("player"), UnitXPMax("player")
			if max and max > 0 then
				tt:AddDoubleLine(LPS:L("XP:") or "XP:", string.format("%s / %s (%.2f%%)", shortValue(cur), shortValue(max), cur / max * 100), 1, 1, 1, 1, 1, 1)
				tt:AddDoubleLine(LPS:L("Remaining:") or "Remaining:", string.format("%s (%.2f%%)", shortValue(max - cur), (max - cur) / max * 100), 1, 1, 1, 1, 1, 1)
			end
			local rested = GetXPExhaustion and GetXPExhaustion()
			if rested and rested > 0 then
				tt:AddDoubleLine(LPS:L("Rested:") or "Rested:", "+" .. shortValue(rested), 1, 1, 1, 0, 1, 0)
			end
		end,
	})
end

-------------------------------------------------- Friends
do
	local friendOnlinePattern = ERR_FRIEND_ONLINE_SS and (ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "")) or nil

	LPS:RegisterDatatext({
		key = "friends",
		name = LPS:L("Friends"),
		events = { "FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_INFO_CHANGED", "CHAT_MSG_SYSTEM" },
		update = function(f)
			local online = 0
			if C_FriendList and C_FriendList.GetNumOnlineFriends then
				online = C_FriendList.GetNumOnlineFriends() or 0
			end
			if BNConnected and BNConnected() and BNGetNumFriends then
				online = online + (select(2, BNGetNumFriends()) or 0)
			end
			if f.text then
				f.text:SetText(string.format("%s: %d", FRIENDS or LPS:L("Friends"), online))
			end
		end,
		onClick = function()
			if ToggleFriendsFrame then ToggleFriendsFrame(1) end
		end,
		tooltip = function(tt)
			tt:AddLine(FRIENDS or LPS:L("Friends"), 1, 0.82, 0)
			tt:AddLine(" ")
			local shown = 0
			local limit = (panelCfg("friends") or {}).maxLimit or 15
			if C_FriendList and C_FriendList.GetFriendInfoByIndex and C_FriendList.GetNumFriends then
				for i = 1, C_FriendList.GetNumFriends() or 0 do
					local info = C_FriendList.GetFriendInfoByIndex(i)
					if info and info.connected then
						shown = shown + 1
						if shown <= limit then
							local status = ""
							if info.afk then status = " |cFFFF9900[" .. (LPS:L("AFK") or "AFK") .. "]|r"
							elseif info.dnd then status = " |cFFFF3333[" .. (LPS:L("DND") or "DND") .. "]|r" end
							tt:AddDoubleLine(
								string.format("%s%s|r%s%s", levelColorHex(info.level), "|cff%02x%02x%02x", 0, 0, 0),
								"", 1, 1, 1)
							tt:AddLine("")
							tt:RemoveLine(tt:NumLines())
							tt:AddDoubleLine(string.format("|cff%02x%02x%02x%d|r %s%s", 255, 255, 255, info.level or 0, info.name, status),
								info.className or "", 1, 1, 1, 1, 1, 1)
						end
					end
				end
			end
			if shown == 0 then
				tt:AddLine(LPS:L("No friends online"), 0.65, 0.65, 0.65)
			elseif shown > limit then
				tt:AddLine(string.format("+%d ...", shown - limit), 0.75, 0.9, 1)
			end
		end,
	})
end

-------------------------------------------------- Guild
do
	LPS:RegisterDatatext({
		key = "guild",
		name = LPS:L("Guild"),
		events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD", "CHAT_MSG_SYSTEM" },
		update = function(f)
			if not IsInGuild or not IsInGuild() then
				if f.text then f.text:SetText(LPS:L("No Guild")) end
				return
			end
			local total, _, online = GetNumGuildMembers()
			if f.text then
				f.text:SetText(string.format("%s: %d/%d", GUILD or LPS:L("Guild"), online or 0, total or 0))
			end
		end,
		onClick = function()
			if not InCombatLockdown() and ToggleGuildFrame then
				ToggleGuildFrame()
			end
		end,
		tooltip = function(tt)
			if not IsInGuild or not IsInGuild() then return end
			local guildName, guildRank = GetGuildInfo("player")
			local total, _, online = GetNumGuildMembers()
			tt:AddDoubleLine(guildName or "", string.format("%d/%d", online or 0, total or 0), 0.4, 0.78, 1, 0.4, 0.78, 1)
			if guildRank then tt:AddLine(guildRank, 0.4, 0.78, 1) end
			local motd = C_GuildInfo and C_GuildInfo.GetMOTD and C_GuildInfo.GetMOTD() or (GetGuildRosterMOTD and GetGuildRosterMOTD())
			if motd and motd ~= "" then
				tt:AddLine(" ")
				tt:AddLine(GUILD_MOTD .. ": " .. motd, 0.75, 0.9, 1)
			end
			tt:AddLine(" ")
			local limit = (panelCfg("guild") or {}).maxLimit or 15
			local shown = 0
			for i = 1, total or 0 do
				local name, rank, rankIndex, level, classLocal, zone, _, _, connected, _, classFile = GetGuildRosterInfo(i)
				if name and connected then
					shown = shown + 1
					if shown <= limit then
						tt:AddDoubleLine(
							string.format("%s%d|r %s", levelColorHex(level), level, name),
							classLocal or "", 1, 1, 1,
							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.r or 1 end)(),
							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.g or 1 end)(),
							(function() local c = classFile and RAID_CLASS_COLORS[classFile]; return c and c.b or 1 end)())
					end
				end
			end
			if shown == 0 then
				tt:AddLine(LPS:L("No members online"), 0.65, 0.65, 0.65)
			end
		end,
	})
end

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

-------------------------------------------------- Mail
do
	LPS:RegisterDatatext({
		key = "mail",
		name = LPS:L("Mail"),
		events = { "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_CLOSED", "MAIL_SHOW" },
		update = function(f)
			local has = HasNewMail and HasNewMail()
			if f.text then
				f.text:SetText(has and ("|cFFFFFF00" .. (LPS:L("New Mail") or HAVE_MAIL) .. "|r")
					or (LPS:L("No Mail") or "—"))
			end
		end,
		tooltip = function(tt)
			tt:AddLine(MAIL_LABEL or LPS:L("Mail"), 1, 0.82, 0)
			tt:AddLine(" ")
			local senders = { GetLatestThreeSenders and GetLatestThreeSenders() or nil }
			local any = false
			for _, s in ipairs(senders) do
				if s then tt:AddLine(s, 1, 1, 1); any = true end
			end
			if not any then
				tt:AddLine(LPS:L("No mail"), 0.65, 0.65, 0.65)
			end
		end,
	})
end

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
				showMenu(self, list)
			end
		end,
	})
end

-------------------------------------------------- Quests
do
	local function questCounts()
		local numEntries, numQuests
		if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
			numEntries = C_QuestLog.GetNumQuestLogEntries()
			numQuests = C_QuestLog.GetNumQuestLogEntries and select(2, C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries()) or 0
		end
		if not numEntries then
			numEntries, numQuests = GetNumQuestLogEntries()
		end
		return numEntries or 0, numQuests or 0
	end

	LPS:RegisterDatatext({
		key = "quests",
		name = LPS:L("Quest Log"),
		events = { "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" },
		update = function(f)
			local _, numQuests = questCounts()
			local maxQ = 25
			if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
				maxQ = C_QuestLog.GetMaxNumQuestsCanAccept() or maxQ
			end
			if f.text then
				f.text:SetText(string.format("%s: %d/%d", LPS:L("Quests") or TRACKER_HEADER_QUESTS, numQuests, maxQ))
			end
		end,
		onClick = function()
			if ToggleQuestLog then ToggleQuestLog() end
		end,
		tooltip = function(tt)
			tt:AddLine(TRACKER_HEADER_QUESTS or LPS:L("Quest Log"), 1, 0.82, 0)
			tt:AddLine(" ")
			local numEntries = questCounts()
			local limit = (panelCfg("quests") or {}).maxLimit or 15
			local shown = 0
			for qi = 1, numEntries do
				local title, level, _, isHeader, _, isComplete
				if C_QuestLog and C_QuestLog.GetInfo then
					local info = C_QuestLog.GetInfo(qi)
					if info then
						title, level, isHeader, isComplete = info.title, info.level, info.isHeader, info.isComplete
					end
				else
					title, level, _, isHeader, _, _, _, _, _, isComplete = GetQuestLogTitle(qi)
				end
				if title and not isHeader then
					shown = shown + 1
					if shown <= limit then
						tt:AddDoubleLine(title, isComplete and COMPLETE or INCOMPLETE, 1, 1, 1,
							isComplete and .2 or 1, isComplete and 1 or .2, .2)
					end
				end
			end
			if shown == 0 then
				tt:AddLine(LPS:L("No quests"), 0.65, 0.65, 0.65)
			end
		end,
	})
end

-------------------------------------------------- Reputation
do
	local function watchedFaction()
		if C_Reputation and C_Reputation.GetWatchedFactionData then
			local d = C_Reputation.GetWatchedFactionData()
			if d and d.name then return d end
			return nil
		end
		local name, bottomLine, displayedMax, currentStanding, factionMember,
			currentReputation, maxReputation = GetWatchedFactionInfo and GetWatchedFactionInfo()
		if not name then return nil end
		return {
			name = name,
			currentValue = currentReputation or currentStanding,
			maxValue = maxReputation or displayedMax,
			offsetValue = bottomLine,
		}
	end

	LPS:RegisterDatatext({
		key = "reputation",
		name = LPS:L("Reputation"),
		events = { "UPDATE_FACTION", "COMBAT_TEXT_UPDATE" },
		update = function(f)
			local data = watchedFaction()
			if not data then
				if f.text then f.text:SetText(NOT_APPLICABLE or "-") end
				return
			end
			local cur = (data.currentValue or 0) - (data.offsetValue or 0)
			local max = (data.maxValue or 0) - (data.offsetValue or 0)
			local pct = max > 0 and (cur / max * 100) or 100
			local reaction = data.reaction or data.standing or 5
			local standingLabel = _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN
			if f.text then
				f.text:SetText(string.format("%s: %d%% [%s]", data.name or "", math.floor(pct), standingLabel))
			end
		end,
		onClick = function()
			if ToggleCharacter then ToggleCharacter("ReputationFrame") end
		end,
		tooltip = function(tt)
			local data = watchedFaction()
			if not data then return end
			tt:AddLine(data.name or "", 1, 0.82, 0)
			tt:AddLine(" ")
			local reaction = data.reaction or data.standing or 5
			tt:AddDoubleLine(STANDING .. ":", _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN, 1, 1, 1, 1, 1, 1)
			local cur = (data.currentValue or 0) - (data.offsetValue or 0)
			local max = (data.maxValue or 0) - (data.offsetValue or 0)
			if max > 0 then
				tt:AddDoubleLine(REPUTATION .. ":", string.format("%d / %d (%d%%)", cur, max, cur / max * 100), 1, 1, 1, 1, 1, 1)
			end
		end,
	})
end

-------------------------------------------------- Stats (attributes)
do
	local statDefs = {
		{ key = "strength",  label = function() return STRENGTH or "Strength" end, attr = LE_UNIT_ATTRIBUTE_STRENGTH or 1 },
		{ key = "agility",   label = function() return AGILITY or "Agility" end,   attr = LE_UNIT_ATTRIBUTE_AGILITY or 2 },
		{ key = "stamina",   label = function() return STAMINA or "Stamina" end,   attr = LE_UNIT_ATTRIBUTE_STAMINA or 3 },
		{ key = "intellect", label = function() return INTELLECT or "Intellect" end, attr = LE_UNIT_ATTRIBUTE_INTELLECT or 4 },
		{ key = "spirit",    label = function() return SPIRIT or "Spirit" end,    attr = LE_UNIT_ATTRIBUTE_SPIRIT or 5 },
	}

	for _, sd in ipairs(statDefs) do
		LPS:RegisterDatatext({
			key = sd.key,
			name = sd.label(),
			events = { "UNIT_STATS", "UNIT_AURA", "PLAYER_ENTERING_WORLD" },
			update = function(f)
				local value
				if UnitAttribute then
					value = UnitAttribute("player", sd.attr)
				elseif UnitStat then
					value = UnitStat("player", sd.attr)
				end
				if f.text then
					f.text:SetText(string.format("%s: %d", sd.label(), math.floor(value or 0)))
				end
			end,
		})
	end
end

-------------------------------------------------- Armor
do
local armorStale
LPS:RegisterDatatext({
key = "armor",
name = ARMOR or "Armor",
events = { "UNIT_armor", "PLAYER_ENTERING_WORLD" },
update = function(f)
local _, effective = UnitArmor("player")
if E_NotSecret(effective) then armorStale = effective end
local value = E_NotSecret(effective) and effective or armorStale
if f.text then
f.text:SetText(string.format("%s: %d", ARMOR or "Armor", math.floor(value or 0)))
end
end,
})
end

-------------------------------------------------- Attack Power
do
local isHunter = select(2, UnitClass("player")) == "HUNTER"
local totalAP, baseAPText
LPS:RegisterDatatext({
key = "attackPower",
name = ATTACK_POWER or "Attack Power",
events = { "UNIT_ATTACK_POWER", "PLAYER_ENTERING_WORLD" },
update = function(f)
local base, pos, neg
if isHunter and UnitRangedAttackPower then
base, pos, neg = UnitRangedAttackPower("player")
else
base, pos, neg = UnitAttackPower("player")
end
base = base or 0
totalAP = E_NotSecret(base) and (base + (pos or 0) + (neg or 0)) or nil
baseAPText = tostring(math.floor(base))
if f.text then
local label = isHunter and (RANGED_ATTACK_POWER or "Ranged AP") or (ATTACK_POWER or "Attack Power")
if totalAP then
f.text:SetText(string.format("%s: %d", label, math.floor(totalAP)))
else
f.text:SetText(string.format("%s: |cFF888888%s|r", label, baseAPText))
end
end
end,
tooltip = function(tt)
tt:AddLine(isHunter and (RANGED_ATTACK_POWER or "Ranged Attack Power") or (MELEE_ATTACK_POWER or "Attack Power"), 1, 0.82, 0)
if totalAP then
tt:AddDoubleLine(" ", tostring(math.floor(totalAP)), 1, 1, 1, 1, 1, 1)
else
tt:AddDoubleLine(" ", "|cFF888888" .. tostring(baseAPText or "?") .. "|r", 1, 1, 1, 1, 1, 1)
end
end,
})
end

-------------------------------------------------- Spell Power / Heal Power
do
local MAX_SCHOOLS = MAX_SPELL_SCHOOLS or 7
local lastSchool = 2
LPS:RegisterDatatext({
key = "spellPower",
name = SPELL_POWER or "Spell Power",
events = { "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UNIT_STATS" },
update = function(f)
local minSP, schoolIdx
for i = 2, MAX_SCHOOLS do
local value = GetSpellBonusDamage and GetSpellBonusDamage(i)
if value and E_NotSecret(value) then
if not minSP or value < minSP then
minSP, schoolIdx = value, i
end
end
end
if minSP then
lastSchool = schoolIdx
else
minSP = 0
end
if f.text then
f.text:SetText(string.format("%s: %d", SPELL_POWER or "Spell Power", math.floor(minSP)))
end
end,
tooltip = function(tt)
tt:AddLine(SPELL_POWER or "Spell Power", 1, 0.82, 0)
for i = 2, MAX_SCHOOLS do
local value = GetSpellBonusDamage and GetSpellBonusDamage(i)
if value and E_NotSecret(value) then
tt:AddDoubleLine(_G["SCHOOL_" .. i .. "_NAME"] or ("School " .. i), tostring(math.floor(value)), 1, 1, 1, 1, 1, 1)
end
end
end,
})

LPS:RegisterDatatext({
key = "healPower",
name = HEALING or "Healing",
events = { "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UNIT_STATS" },
update = function(f)
local heal = GetSpellHealingBonus and GetSpellHealingBonus(4)
if heal and E_NotSecret(heal) then
if f.text then f.text:SetText(string.format("%s: %d", HEALING or "Healing", math.floor(heal))) end
else
if f.text then f.text:SetText(string.format("%s: |cFF888888?|r", HEALING or "Healing")) end
end
end,
})
end

-------------------------------------------------- Crit Chance
do
local critMelee, spellIndex, ratingIndex = 0, 0, CR_CRIT_MELEE or 1
LPS:RegisterDatatext({
key = "crit",
name = LPS:L("Crit Chance") or CR_CRIT_CHANCE or "Crit",
events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
update = function(f)
critMelee = GetCritChance() or 0
local text = critMelee
if GetRangedCritChance then
local critRanged = GetRangedCritChance() or 0
if critRanged > critMelee then text = critRanged end
end
if GetSpellCritChance then
local minimum = GetSpellCritChance(2)
if E_NotSecret(minimum) then
for i = 3, (MAX_SPELL_SCHOOLS or 7) do
local chance = GetSpellCritChance(i)
if E_NotSecret(chance) and chance < minimum then
minimum = chance
end
end
text = minimum
end
end
if f.text then
f.text:SetText(string.format("%.2f%%", text))
end
end,
tooltip = function(tt)
tt:AddLine(string.format("|cffFFFFFF%s:|r %.2f%%", MELEE_CRIT_CHANCE or "Melee", critMelee))
if GetCombatRatingBonus and ratingIndex then
local rating = GetCombatRating and GetCombatRating(ratingIndex) or 0
tt:AddDoubleLine(CR_CRIT_TOOLTIP or "Crit Rating", format("%.2f%% from %d", GetCombatRatingBonus(ratingIndex) or 0, rating or 0), 1, 1, 1, 1, 1, 1)
end
end,
})
end

-------------------------------------------------- Haste
do
local haste
LPS:RegisterDatatext({
key = "haste",
name = LPS:L("Haste") or STAT_HASTE or "Haste",
events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
update = function(f)
haste = GetHaste and GetHaste() or 0
if f.text then
f.text:SetText(string.format("%+d%%", haste))
end
end,
tooltip = function(tt)
tt:AddLine((STAT_HASTE or "Haste") .. ": " .. string.format("%+d%%", haste or 0), 1, 0.82, 0)
if GetCombatRating and GetCombatRatingBonus and CR_HASTE_MELEE then
local rating = GetCombatRating(CR_HASTE_MELEE) or 0
tt:AddDoubleLine(LPS:L("Rating") or "Rating", tostring(rating), 1, 1, 1, 1, 1, 1)
tt:AddDoubleLine(LPS:L("Bonus") or "Bonus", string.format("%.2f%%", GetCombatRatingBonus(CR_HASTE_MELEE) or 0), 1, 1, 1, 1, 1, 1)
end
end,
})
end

-------------------------------------------------- Mastery
do
local mastery
LPS:RegisterDatatext({
key = "mastery",
name = LPS:L("Mastery") or STAT_MASTERY or "Mastery",
events = { "PLAYER_ENTERING_WORLD", "UNIT_STATS", "SPELLS_CHANGED" },
update = function(f)
mastery = GetMasteryEffect and select(1, GetMasteryEffect()) or 0
if f.text then
f.text:SetText(string.format("%.2f%%", mastery))
end
end,
tooltip = function(tt)
tt:AddLine((STAT_MASTERY or "Mastery") .. ": " .. string.format("%.2f%%", mastery or 0), 1, 0.82, 0)
if GetCombatRating and GetCombatRatingBonus and CR_MASTERY then
local rating = GetCombatRating(CR_MASTERY) or 0
tt:AddDoubleLine(LPS:L("Rating") or "Rating", tostring(rating), 1, 1, 1, 1, 1, 1)
tt:AddDoubleLine(LPS:L("Bonus") or "Bonus", string.format("%.2f%%", GetCombatRatingBonus(CR_MASTERY) or 0), 1, 1, 1, 1, 1, 1)
end
end,
})
end

-------------------------------------------------- Time Played
do
	local playedTime
	local requested = false
	local function getPlayed()
		if playedTime or requested or not GetTimePlayed then return playedTime end
		requested = true
		GetTimePlayed(function(totalSeconds)
			playedTime = totalSeconds or 0
			LPS:_RefreshPlayed()
		end)
		return playedTime
	end

	local playedUpdaters = {}
	function LPS:_RefreshPlayed()
		for _, fn in ipairs(playedUpdaters) do fn() end
	end

	LPS:RegisterDatatext({
		key = "timePlayed",
		name = LPS:L("Time Played"),
		ticker = 1,
		create = function(f)
			playedUpdaters[#playedUpdaters + 1] = function()
				if f.text and f:IsShown() then
					local t = playedTime
					if t then
						f.text:SetText(string.format("%s: %dh %dm", LPS:L("Time Played"), math.floor(t / 3600), math.floor((t % 3600) / 60)))
					end
				end
			end
		end,
		update = function(f)
			getPlayed()
			if f.text then
				local t = playedTime
				if t then
					f.text:SetText(string.format("%s: %dh %dm", LPS:L("Time Played"), math.floor(t / 3600), math.floor((t % 3600) / 60)))
				else
					f.text:SetText(LPS:L("Time Played"))
				end
			end
		end,
	})
end

-------------------------------------------------- Volume
do
	local AudioStreams = {
		{ Name = MASTER_VOLUME or LPS:L("Master"), volume = "Sound_MasterVolume", enabled = "Sound_EnableAllSound" },
		{ Name = SOUND_VOLUME or FX_VOLUME or LPS:L("Effects"), volume = "Sound_SFXVolume", enabled = "Sound_EnableSFX" },
		{ Name = AMBIENCE_VOLUME or LPS:L("Ambience"), volume = "Sound_AmbienceVolume", enabled = "Sound_EnableAmbience" },
		{ Name = DIALOG_VOLUME or LPS:L("Dialog"), volume = "Sound_DialogVolume", enabled = "Sound_EnableDialog" },
		{ Name = MUSIC_VOLUME or LPS:L("Music"), volume = "Sound_MusicVolume", enabled = "Sound_EnableMusic" },
	}
	local activeIndex = 1

	local function getCVar(name)
		if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
		return GetCVar and GetCVar(name)
	end
	local function setCVar(name, v)
		if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar(name, v) elseif SetCVar then SetCVar(name, v) end
	end
	local function getCVarBool(name)
		if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool(name) end
		return GetCVarBool and GetCVarBool(name)
	end

	local function streamString(stream)
		stream = stream or AudioStreams[1]
		local color = getCVarBool(AudioStreams[1].enabled) and getCVarBool(stream.enabled) and "00FF00" or "FF3333"
		local level = tonumber(getCVar(stream.volume) or 0) * 100
		return string.format("%s: |cFF%s%.0f%%|r", stream.Name, color, level)
	end

	LPS:RegisterDatatext({
		key = "volume",
		name = LPS:L("Volume"),
		events = { "CVAR_UPDATE" },
		update = function(f)
			if f.text then f.text:SetText(streamString(AudioStreams[activeIndex])) end
		end,
		create = function(f)
			f:EnableMouseWheel(true)
			f:SetScript("OnMouseWheel", function(self, delta)
				local stream = AudioStreams[activeIndex]
				local vol = tonumber(getCVar(stream.volume) or 0.5)
				vol = math.max(0, math.min(1, vol + delta / 100))
				setCVar(stream.volume, vol)
				if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end
			end)
		end,
		onClick = function(self, button)
			if button == "LeftButton" then
				local list = { { text = LPS:L("Select Volume Stream"), isTitle = true } }
				for i, s in ipairs(AudioStreams) do
					list[#list + 1] = { text = s.Name, func = function() activeIndex = i; if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end end }
				end
				showMenu(self, list)
			elseif button == "MiddleButton" then
				setCVar(AudioStreams[1].enabled, getCVarBool(AudioStreams[1].enabled) and 0 or 1)
			else
				local list = { { text = LPS:L("Toggle Volume Stream"), isTitle = true } }
				for i, s in ipairs(AudioStreams) do
					list[#list + 1] = { text = s.Name, func = function() setCVar(s.enabled, getCVarBool(s.enabled) and 0 or 1); if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end end }
				end
				showMenu(self, list)
			end
		end,
		tooltip = function(tt)
			tt:AddLine(LPS:L("Volume Streams"), 1, 0.82, 0)
			tt:AddLine(" ")
			for _, s in ipairs(AudioStreams) do
				tt:AddDoubleLine(s.Name, streamString(s), 1, 1, 1, 1, 1, 1)
			end
			tt:AddLine(" ")
			tt:AddLine((LPS:L("LMB") or "/lmb") .. ": " .. LPS:L("Select Volume Stream"), 0.65, 0.65, 0.65)
			tt:AddLine((LPS:L("MMB") or "/mmb") .. ": " .. LPS:L("Mute"), 0.65, 0.65, 0.65)
			tt:AddLine((LPS:L("RMB") or "/rmb") .. ": " .. LPS:L("Toggle Volume Stream"), 0.65, 0.65, 0.65)
		end,
	})
end

--------------------------------------------------------------------
-- Публичный API для options.lua
--------------------------------------------------------------------

function LPS:GetDatatextName(key)
	local def = registry[key]
	return def and def.name or key
end

--- Список ключей панелей для слотов (существующие + новые)
function LPS:GetSlotKeyList()
	local keys = {}
	for _, k in ipairs(orderList) do
		if registry[k] then keys[#keys + 1] = k end
	end
	return keys
end

function LPS:IsDatatextKey(key)
	return key ~= nil and registry[key] ~= nil and not RESERVED_SLOT_KEYS[key]
end

--- Возвращает фрейм панели по ключу слота (создаёт при необходимости)
function LPS:GetOrCreatePanelFrame(key)
	if RESERVED_SLOT_KEYS[key] then return nil end
	local frames = LPS.frame
	if not frames then return nil end
	if frames[key] then return frames[key] end
	local f = LPS:CreateDatatextFrame(key)
	if f then
		frames[key] = f
		LPS:ScheduleFrameSizeUpdate()
	end
	return f
end
