local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
LPS_DB = LPS_DB or {}

-- Применяет сохранённую позицию к holder-фрейму
function LPS:ApplyHolderPosition()
	local db = LPS:GetDB()
	db.position = db.position or { point = "TOP", relativePoint = "TOP", x = 0, y = -10 }
	local p = db.position
	self.frame.holder:ClearAllPoints()
	self.frame.holder:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

-- Пересчитывает размер главного фрейма по вложенным элементам
function LPS:UpdateFrameSize()
	local padding = 4
	local function w(f)
		return (f and f:IsShown()) and f:GetWidth() or 0
	end
	local function h(f)
		return (f and f:IsShown()) and f:GetHeight() or 0
	end

	local width = w(LPS.frame.location) + w(LPS.frame.time) + w(LPS.frame.coords) + w(LPS.frame.gold) + w(LPS.frame.system) + padding * 2 + 10
	local height = math.max(h(LPS.frame.location), h(LPS.frame.time), h(LPS.frame.coords), h(LPS.frame.gold), h(LPS.frame.system)) + 6
	LPS.frame.holder:SetSize(width, height)
end