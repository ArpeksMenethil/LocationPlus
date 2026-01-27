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
	local width =
		LPS.frame.location:GetWidth() +
		LPS.frame.time:GetWidth() +
		LPS.frame.coords:GetWidth() +
		padding * 2 + 10
	local height = math.max(
		LPS.frame.location:GetHeight(),
		LPS.frame.time:GetHeight(),
		LPS.frame.coords:GetHeight()
	) + 6
	LPS.frame.holder:SetSize(width, height)
end