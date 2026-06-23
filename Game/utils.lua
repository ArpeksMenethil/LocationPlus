local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-- Округляет число до указанного количества знаков после запятой
function LPS:Round(num, decimals)
	local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end
