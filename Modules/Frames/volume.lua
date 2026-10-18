local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Volume
do
	local AudioStreams = {
		{ Name = MASTER_VOLUME, volume = "Sound_MasterVolume", enabled = "Sound_EnableAllSound" },
		{ Name = SOUND_VOLUME or FX_VOLUME, volume = "Sound_SFXVolume", enabled = "Sound_EnableSFX" },
		{ Name = AMBIENCE_VOLUME, volume = "Sound_AmbienceVolume", enabled = "Sound_EnableAmbience" },
		{ Name = DIALOG_VOLUME, volume = "Sound_DialogVolume", enabled = "Sound_EnableDialog" },
		{ Name = MUSIC_VOLUME, volume = "Sound_MusicVolume", enabled = "Sound_EnableMusic" },
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
		nameKey = "Volume",
		events = { "CVAR_UPDATE" },
		-- СКМ (переключение общего звука) не работал: по умолчанию
		-- панель регистрирует только ЛКМ/ПКМ (datatexts.lua), поэтому
		-- MiddleButton не доходил до onClick.
		clicks = { "LeftButtonUp", "RightButtonUp", "MiddleButtonUp" },
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
				DT.showMenu(self, list)
			elseif button == "MiddleButton" then
				setCVar(AudioStreams[1].enabled, getCVarBool(AudioStreams[1].enabled) and 0 or 1)
			else
				local list = { { text = LPS:L("Toggle Volume Stream"), isTitle = true } }
				for i, s in ipairs(AudioStreams) do
					list[#list + 1] = { text = s.Name, func = function() setCVar(s.enabled, getCVarBool(s.enabled) and 0 or 1); if self._lpsUpdateFunc then self._lpsUpdateFunc(self) end end }
				end
				DT.showMenu(self, list)
			end
		end,
	})
end
