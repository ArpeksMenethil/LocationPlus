local MyAddon = _G.ArpeksLPS
local LPS = MyAddon.LPS

local function getCVar(name)
        if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
        return GetCVar and GetCVar(name)
end
local function getCVarBool(name)
        if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool(name) end
        return GetCVarBool and GetCVarBool(name)
end

local AudioStreams = {
        { Name = MASTER_VOLUME, volume = "Sound_MasterVolume", enabled = "Sound_EnableAllSound" },
        { Name = SOUND_VOLUME or FX_VOLUME, volume = "Sound_SFXVolume", enabled = "Sound_EnableSFX" },
        { Name = AMBIENCE_VOLUME, volume = "Sound_AmbienceVolume", enabled = "Sound_EnableAmbience" },
        { Name = DIALOG_VOLUME, volume = "Sound_DialogVolume", enabled = "Sound_EnableDialog" },
        { Name = MUSIC_VOLUME, volume = "Sound_MusicVolume", enabled = "Sound_EnableMusic" },
}

local function streamString(stream)
        stream = stream or AudioStreams[1]
        local color = getCVarBool(AudioStreams[1].enabled) and getCVarBool(stream.enabled) and "00FF00" or "FF3333"
        local level = tonumber(getCVar(stream.volume) or 0) * 100
        return string.format("%s: |cFF%s%.0f%%|r", stream.Name, color, level)
end

function LPS:BuildVolumeTooltip(GameTooltip)
    local tt = GameTooltip
    local r, g, b = LPS:GetColor("text")
    local rB, gB, bB = LPS:GetColor("tooltipSetting")
    local rY, gY, bY = LPS:GetColor("tooltip")

                                tt:AddLine(LPS:L("Volume Streams"), 1, 0.82, 0)
                                tt:AddLine(" ")
                                for _, s in ipairs(AudioStreams) do
                                        tt:AddDoubleLine(s.Name, streamString(s), 1, 1, 1, 1, 1, 1)
                                end
                                tt:AddLine(" ")
                                tt:AddLine(LPS:L("LMB") .. ": " .. LPS:L("Select Volume Stream"), 0.65, 0.65, 0.65)
                                tt:AddLine(LPS:L("MMB") .. ": " .. LPS:L("Mute"), 0.65, 0.65, 0.65)
                                tt:AddLine(LPS:L("RMB") .. ": " .. LPS:L("Toggle Volume Stream"), 0.65, 0.65, 0.65)
end
