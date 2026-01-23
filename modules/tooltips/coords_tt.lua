local LPS =  _G.ArpeksLPS.LPS
local L =  _G.ArpeksLPS.L
LPS_DB = LPS_DB or {}

function LPS:BuildCoordsTooltip()
	-- local r, g, b = LPS:GetColor("tooltip")
	local rB, gB, bB = LPS:GetColor("tooltipSetting")

  GameTooltip:AddDoubleLine(L["LMB"], L["Toggle WorldMap"], rB, gB, bB, rB, gB, bB)

	if GameTooltipTextLeft1 then
		local rT, gT, bT = GameTooltipTextLeft1:GetTextColor()
		GameTooltipTextLeft1:SetFontObject(GameTooltipText)
		GameTooltipTextLeft1:SetTextColor(rT, gT, bT)
	end
	if GameTooltipTextRight1 then
		local rT, gT, bT = GameTooltipTextRight1:GetTextColor()
		GameTooltipTextRight1:SetFontObject(GameTooltipText)
		GameTooltipTextRight1:SetTextColor(rT, gT, bT)
	end
end
