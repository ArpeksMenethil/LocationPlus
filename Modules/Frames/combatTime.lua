local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local DT = LPS._DT

-------------------------------------------------- Combat / Arena Time
do
-- Время боя считаем НЕ накоплением elapsed в OnUpdate, а по часам:
-- timer = GetTime() - startTime. Накопление ломалось, потому что
-- OnUpdate-тикинг и колбэк f._lpsCombatTime навешивались только в
-- create(), а create() при боевом локдауне откладывается
-- (_lpsPendingCreate) — весь первый бой панель молчала.
local startTime

local function formatTime(t)
local m = math.floor(t / 60)
local s = math.floor(t % 60)
--修复：旧 строка открывала |c второй раз без закрытия первого — клиент
--рендерил битую/пустую строку. Теперь один цвет на всё время mm:ss.
return string.format("%s: |cFFFFFFFF%02d:%02d|r", LPS:L("Combat"), m, s)
end

local function emptyText()
return string.format("%s: |cFFFFFFFF00:00|r", LPS:L("Combat"))
end

-- Общий тикер: раз в секунду обновляем текст всех панелей combatTime.
-- Обновляем напрямую через f.text (колбэк _lpsCombatTime не обязателен).
local ticker
local function ensureTicker()
if ticker then return end
ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(self, elapsed)
if not startTime then return end
acc = acc + elapsed
if acc < 1 then return end
acc = 0
local txt = formatTime(GetTime() - startTime)
for _, fr in pairs(LPS.frame or {}) do
if type(fr) == "table" and fr._lpsCombatTime and fr.text and fr:IsShown() then
fr.text:SetText(txt)
end
end
end)
end

LPS:RegisterDatatext({
key = "combatTime",
name = LPS:L("Combat/Arena Time"),
events = {
"ENCOUNTER_START", "ENCOUNTER_END",
"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
"PLAYER_LEAVE_COMBAT",
"PLAYER_ENTERING_WORLD",
},
create = function(f)
ensureTicker()
f._lpsCombatTime = true -- маркер панели для тикера
if f.text then
if startTime then
f.text:SetText(formatTime(GetTime() - startTime))
else
f.text:SetText(emptyText())
end
end
end,
update = function(f, ev)
ensureTicker()
-- create() мог быть отложен боевым локдауном — проставляем
-- маркер здесь, чтобы тикер заработал сразу, а не после боя.
f._lpsCombatTime = true

if ev == "PLAYER_REGEN_DISABLED" or ev == "ENCOUNTER_START" then
if not startTime then startTime = GetTime() end
elseif ev == "PLAYER_REGEN_ENABLED" or ev == "ENCOUNTER_END" or ev == "PLAYER_LEAVE_COMBAT" then
startTime = nil
elseif ev == "PLAYER_ENTERING_WORLD" then
if UnitAffectingCombat("player") then
startTime = GetTime()
else
startTime = nil
end
end

if f.text then
if startTime then
f.text:SetText(formatTime(GetTime() - startTime))
else
f.text:SetText(emptyText())
end
end
end,
})
end
