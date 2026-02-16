local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

local function formatMem(kb)
	kb = tonumber(kb) or 0
	if kb >= 1024 then
		return string.format("%.2f mb", kb / 1024)
	end
	return string.format("%.0f kb", kb)
end

local function getNumAddOns()
	if C_AddOns and C_AddOns.GetNumAddOns then
		return C_AddOns.GetNumAddOns() or 0
	end
	if GetNumAddOns then
		return GetNumAddOns() or 0
	end
	return 0
end

local function isAddOnLoaded(i)
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		return C_AddOns.IsAddOnLoaded(i)
	end
	if IsAddOnLoaded then
		return IsAddOnLoaded(i)
	end
	return false
end

local function getAddOnInfo(i)
	if C_AddOns and C_AddOns.GetAddOnInfo then
		local name = C_AddOns.GetAddOnInfo(i)
		return name
	end
	if GetAddOnInfo then
		local name = GetAddOnInfo(i)
		return name
	end
	return nil
end

local function colorByThreshold(v, good, warn, invert)
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

function LPS:BuildSystemTooltip(tt)
	local db = LPS.GetDB and LPS:GetDB() or nil
	local cfg = db and db.tooltips and db.tooltips.system or nil
	if cfg and cfg.enable == false then return end

	local fps = math.floor(GetFramerate() or 0)
	local bandwidth, _, lagHome, lagWorld = GetNetStats()
	lagHome = math.floor(lagHome or 0)
	lagWorld = math.floor(lagWorld or 0)
	local lag = lagWorld > 0 and lagWorld or lagHome

	if not cfg or cfg.network ~= false then
		tt:AddDoubleLine(LPS:L("FPS")..":", colorByThreshold(fps, 60, 30, false), 1, 1, 1, 1, 1, 1)
		tt:AddDoubleLine(LPS:L("MS")..":", colorByThreshold(lag, 60, 120, true), 1, 1, 1, 1, 1, 1)
		tt:AddDoubleLine(LPS:L("Local latency")..":", string.format("%d ms", lagHome), 1, 1, 1, 0.41, 0.8, 0.94)
		tt:AddDoubleLine(LPS:L("Global latency")..":", string.format("%d ms", lagWorld), 1, 1, 1, 0.41, 0.8, 0.94)
		tt:AddDoubleLine(LPS:L("Bandwidth")..":", string.format("%.2f", bandwidth or 0), 1, 1, 1, 0.41, 0.8, 0.94)
	end

	if UpdateAddOnMemoryUsage then
		UpdateAddOnMemoryUsage()
	end
	local addons = {}
	local total = 0
	local count = getNumAddOns()
	for i = 1, count do
		if isAddOnLoaded(i) then
			local mem = GetAddOnMemoryUsage(i) or 0
			total = total + mem
			local name = getAddOnInfo(i)
			if name then
				addons[#addons + 1] = { name = name, mem = mem }
			end
		end
	end
	table.sort(addons, function(a, b) return a.mem > b.mem end)

	if not cfg or cfg.addons ~= false then
		if cfg.network ~= false then tt:AddLine(" ") end
		tt:AddLine(LPS:L("AddOns"), 1, 0.82, 0)
		local max = (cfg and tonumber(cfg.addonsMax)) or 15
		if max < 3 then max = 3 elseif max > 40 then max = 40 end
		for i = 1, math.min(#addons, max) do
			local a = addons[i]
			tt:AddDoubleLine(a.name, formatMem(a.mem), 1, 1, 1, 0.41, 0.8, 0.94)
		end
	end
	if not cfg or cfg.total ~= false then
		tt:AddLine(" ")
		tt:AddDoubleLine(LPS:L("Total"), formatMem(total), 1, 1, 1, 0.41, 0.8, 0.94)
	end
end
