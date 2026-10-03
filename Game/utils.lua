local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- Округляет число до указанного количества знаков после запятой
function LPS:Round(num, decimals)
	local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- ОПТИМИЗАЦИЯ (duplicates): colorByThreshold был продублирован в
-- Modules/Frames/system.lua и Modules/Tooltips/system_tt.lua — теперь общая
-- функция LPS здесь (Game/ грузится раньше Modules/).
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
