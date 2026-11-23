local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

--- Контроллеры событий (нативная замена Foundry.Events): каждый контроллер —
--- один фрейм, распределяющий зарегистрированные события между обработчиками.
--- События, зарегистрированные до логина, встают в очередь и регистрируются
--- после PLAYER_LOGIN (до логина клиент их не доставляет).
LPS.Events = LPS.Events or {}

local pending = {}
local pendingOnce = {}

local function flush(list)
    for i = #list, 1, -1 do
        local entry = list[i]
        list[i] = nil
        if entry.frame and entry.frame._handlers[entry.event]
            and not entry.frame._registered[entry.event] then
            entry.frame:RegisterEvent(entry.event)
            entry.frame._registered[entry.event] = true
        end
    end
end

if not (IsLoggedIn and IsLoggedIn()) then
    local flushFrame = CreateFrame("Frame", nil, UIParent)
    flushFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        flush(pending)
        flush(pendingOnce)
    end)
    flushFrame:RegisterEvent("PLAYER_LOGIN")
end

local EventController = {}
EventController.__index = EventController

local function dereg(frame, event)
    if frame._registered[event] then
        frame:UnregisterEvent(event)
        frame._registered[event] = nil
    end
end

local function reg(frame, event)
    frame:RegisterEvent(event)
    frame._registered[event] = true
end

--- Регистрирует обработчик события (подменяет прежний обработчик того же события).
--- @param event string
--- @param handler fun(event: string, ...)
function EventController:Register(event, handler)
    local frame = self.frame
    dereg(frame, event)
    frame._handlers[event] = handler
    if IsLoggedIn and IsLoggedIn() then
        reg(frame, event)
    else
        pending[#pending + 1] = { frame = frame, event = event }
    end
end

--- Регистрирует одноразовый обработчик события.
--- @param event string
--- @param handler fun(event: string, ...)
function EventController:RegisterOnce(event, handler)
    local frame = self.frame
    dereg(frame, event)
    frame._handlers[event] = function(ev, ...)
        frame._handlers[event] = nil
        dereg(frame, ev)
        handler(ev, ...)
    end
    if IsLoggedIn and IsLoggedIn() then
        reg(frame, event)
    else
        pendingOnce[#pendingOnce + 1] = { frame = frame, event = event }
    end
end

--- Снимает обработчик события.
--- @param event string
function EventController:Unregister(event)
    local frame = self.frame
    dereg(frame, event)
    frame._handlers[event] = nil
end

--- Создаёт новый контроллер событий.
--- @param name string Имя контроллера (для диагностики)
--- @return table
function LPS.Events:New(name)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame._handlers = {}
    frame._registered = {}
    frame:SetScript("OnEvent", function(_, event, ...)
        local handler = frame._handlers[event]
        if handler then
            handler(event, ...)
        end
    end)
    frame:Hide()
    return setmetatable({ name = name, frame = frame }, EventController)
end