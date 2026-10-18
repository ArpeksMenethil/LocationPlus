local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--------------------------------------------------------------------
-- Вспомогательные функции панелей-инфотекстов (LPS._DT)
-- Перенесены из Modules/datatexts.lua. Загружаются раньше Panels/*.lua.
--------------------------------------------------------------------

LPS._DT = LPS._DT or {}

-- Проверка значения на «секретность» (WotLK Classic 3.4+ / Retail secret values)
LPS._DT.NotSecret = function(v)
	if v == nil then return false end
	if IsRestrictedTable and IsRestrictedTable(v) then return false end
	return true
end

LPS._DT.shortValue = function(n)
	n = tonumber(n) or 0
	if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.2fk", n / 1e3) end
	return tostring(math.floor(n))
end

LPS._DT.hexFromRGB = function(r, g, b)
	return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

LPS._DT.colorGradient = function(pct, r1, g1, b1, r2, g2, b2, r3, g3, b3)
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

LPS._DT.classColorHex = function(classFile)
	local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if c then return LPS._DT.hexFromRGB(c.r, c.g, c.b) end
	return "|cFFFFFFFF"
end

LPS._DT.levelColorHex = function(level)
	level = tonumber(level) or 0
	if GetQuestDifficultyColor then
		local c = GetQuestDifficultyColor(level)
		return LPS._DT.hexFromRGB(c.r, c.g, c.b)
	end
	return "|cFFFFFFFF"
end

LPS._DT.panelCfg = function(key)
	local db = LPS:GetDB()
	return db and db.panels and db.panels[key]
end

-- Тултип-хелпер: стандартная проверка видимости подсказок
LPS._DT.tooltipGuard = function(key)
	local d = LPS:GetDB()
	if not d then return false end
	if not (d.tooltips and d.tooltips.visibility and d.tooltips.visibility.enable) then return false end
	if d.tooltips.visibility.combat and InCombatLockdown() then return false end
	local cfg = LPS._DT.panelCfg(key)
	if cfg and cfg.tooltip == false then return false end
	return true
end

LPS._DT.openTooltip = function(self, buildFunc)
	if GameTooltip.EasyTooltip_SetDefaultAnchor then
		GameTooltip:EasyTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	end
	GameTooltip:ClearLines()
	buildFunc(GameTooltip)
	GameTooltip:Show()
end

-- Меню через UIDropDownMenu (без зависимости от ElvUI EasyMenu)
local menuFrame
LPS._DT.showMenu = function(anchorFrame, list)
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

--------------------------------------------------------------------

-- Округляет число до указанного количества знаков после запятой
function LPS:Round(num, decimals)
	local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

function LPS:ColorByThreshold(v, good, warn, invert)
	v = tonumber(v) or 0
	local r, g, b
	if invert then
		if v <= good then
			r, g, b = 0.1, 1, 0.1
		elseif v <= warn then
			r, g, b = 1, 0.82, 0
		else
			r, g, b = 1, 0.1, 0.1
		end
	else
		if v >= good then
			r, g, b = 0.1, 1, 0.1
		elseif v >= warn then
			r, g, b = 1, 0.82, 0
		else
			r, g, b = 1, 0.1, 0.1
		end
	end
	return string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, v)
end
