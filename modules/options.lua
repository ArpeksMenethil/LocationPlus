local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local Tourist
if LPS.Retail and LibStub:GetLibrary("LibTourist-3.0", true) then
	Tourist = LibStub("LibTourist-3.0")
elseif LibStub:GetLibrary("LibTouristClassic-1.0", true) then
	Tourist = LibStub("LibTouristClassic-1.0")
end