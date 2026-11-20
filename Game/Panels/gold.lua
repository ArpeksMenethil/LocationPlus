local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

local function formatThousands(n)
    n = tonumber(n) or 0
    local s = tostring(math.floor(n))
    local left, num, right = s:match('^([^%d]*)(%d+)(.-)$')
    num = num:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '')
    return (left or '') .. num .. (right or '')
end

function LPS:FormatMoney(money, keepEmptyUnits)
    money = tonumber(money) or 0
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = math.floor(money % 100)

    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = formatThousands(gold) .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
    end
    if silver > 0 or (keepEmptyUnits and gold > 0) then
        parts[#parts + 1] = silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
    end
    if copper > 0 or (gold == 0 and silver == 0) or keepEmptyUnits then
        parts[#parts + 1] = copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end
    return table.concat(parts, " ")
end

function LPS:FormatMoneySmart(money)
    return LPS:FormatMoney(money, false)
end

local function getRealmKey() return LPS:GetGoldRealmKey() end
local function getGoldRoot() return LPS:GetGoldRoot() end

--- Нормализация ключа сервера для сравнения: без регистра, только буквы и цифры.
local function normRealmKey(key)
    if type(key) ~= "string" then return "" end
    return (key:lower():gsub("[^%w%d]", ""))
end

--- Клиент может не возвращать имя realm локального персонажа
--- (GetRealmName() = "" для своего персонажа). Ищет уже сохранённый realm,
--- содержащий текущего персонажа (сначала по полному имени, затем по короткому).
local function findRealmByChar(gold)
    local name = LPS:GetPlayerFullName()
    if type(name) ~= "string" or name == "" then return end
    local short = UnitName and UnitName("player") or nil
    if type(short) ~= "string" or short == "" or short == name then short = nil end
    local shortHit
    for key, rt in pairs((gold and gold.realms) or {}) do
        if type(rt) == "table" and type(rt.chars) == "table" then
            if rt.chars[name] then
                return key
            end
            if short and rt.chars[short] then
                shortHit = shortHit or key
            end
        end
    end
    return shortHit
end

--- Возвращает (realmKey, realmTable). Если точный ключ отсутствует, ищет уже
--- сохранённый сервер по совпадающей нормализации (обновление клиента могло
--- сменить формат имени сервера) и переносит данные на актуальный ключ.
--- Если клиент не возвращает имя текущего realm (ключ = ""), ищет realm по
--- имени текущего персонажа и переносит данные на ключ "" (локальный realm).
function LPS:GetGoldRealmTable()
    local gold = getGoldRoot()
    gold.realms = gold.realms or {}
    local realm = getRealmKey()
    if realm == "" then
        if not gold.realms[""] then
            local found = findRealmByChar(gold)
            if found then
                gold.realms[""] = gold.realms[found]
                gold.realms[found] = nil
            end
        end
        gold.realms[""] = gold.realms[""] or { chars = {} }
        return "", gold.realms[""]
    end
    local r = gold.realms[realm]
    if r then return realm, r end
    local target = normRealmKey(realm)
    if target ~= "" then
        for key, table_ in pairs(gold.realms) do
            if normRealmKey(key) == target then
                gold.realms[key] = nil
                gold.realms[realm] = table_
                return realm, table_
            end
        end
    end
    gold.realms[realm] = { chars = {} }
    return realm, gold.realms[realm]
end

local function getGoldRealmTable()
    return LPS:GetGoldRealmTable()
end

function LPS:UpdateGoldCharacterData()
    local _, realmTable = LPS:GetGoldRealmTable()
    if not (realmTable and realmTable.chars) then return end

    local name = LPS:GetPlayerFullName()
    if not name then return end

    local faction = UnitFactionGroup("player")
    local _, classFile = UnitClass("player")
    local money = GetMoney() or 0

    realmTable.chars[name] = {
        money = money,
        faction = faction,
        class = classFile,
        updated = time and time() or nil,
    }
end

function LPS:ResetGoldCharacterData()
    local _, r = getGoldRealmTable()
    if not (r and r.chars) then return end
    local name = LPS:GetPlayerFullName()
    if not name then return end

    r.chars[name] = nil
end

function LPS:ResetGoldCharacterDataByName(name)
    if not name or name == "" then return end
    local _, r = getGoldRealmTable()
    if not (r and r.chars) then return end
    r.chars[name] = nil
end

function LPS:ResetGoldAllCharacterData()
    local _, r = getGoldRealmTable()
    if not r then return end
    r.chars = {}
end

function LPS:ShowGoldResetMenu(owner)
    if not owner then return end

    local realm, r = getGoldRealmTable()
    if not (realm and r and r.chars) then return end

    local names = {}
    for name in pairs(r.chars) do
        names[#names + 1] = name
    end
    table.sort(names)

    local list = {
        { isTitle = true, text = L.RESET_CHARACTER_DATA },
        {
            text = L.RESET_VALUES,
            func = function()
                LPS:ResetGoldAllCharacterData()
                if owner._lpsUpdateFunc then owner._lpsUpdateFunc(owner) end
            end,
        },
                    { isTitle = true, text = L.CHARACTERS },
    }
    for _, n in ipairs(names) do
        list[#list + 1] = {
            text = n,
            func = function()
                LPS:ResetGoldCharacterDataByName(n)
                if owner._lpsUpdateFunc then owner._lpsUpdateFunc(owner) end
            end,
        }
    end

    LPS._DT.showMenu(owner, list)
end

local function ensureSession()
    LPS._goldSession = LPS._goldSession or {}
    local s = LPS._goldSession
    if not s.initialized then
        if not s._initTimerStarted and C_Timer and C_Timer.After then
            s._initTimerStarted = true
            s._initCandidate = GetMoney() or 0
            s._initTries = 0
            local function tryInit()
                if not (LPS and LPS._goldSession) then return end
                local ss = LPS._goldSession
                if not ss or ss.initialized then return end
                ss._initTries = (ss._initTries or 0) + 1
                local m = GetMoney() or 0
                if m == (ss._initCandidate or m) or (ss._initTries or 0) >= 10 then
                    ss.start = m
                    ss.last = m
                    ss.earned = 0
                    ss.spent = 0
                    ss.initialized = true
                    if LPS.UpdateGoldCharacterData then
                        LPS:UpdateGoldCharacterData()
                    end
                    return
                end
                ss._initCandidate = m
                C_Timer.After(0.5, tryInit)
            end
            C_Timer.After(0.5, tryInit)
        end
    end
    return s
end

function LPS:ResetGoldSession()
    local s = ensureSession()
    local m = GetMoney() or 0
    s.start = m
    s.last = m
    s.earned = 0
    s.spent = 0
    s.initialized = true
    s._initTimerStarted = true
end

function LPS:GetGoldSessionData()
    local s = ensureSession()
    local current = GetMoney() or 0
    return {
        current = current,
        earned = s.earned or 0,
        spent = s.spent or 0,
        profit = (s.earned or 0) - (s.spent or 0),
        start = s.start or current,
        currentText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(current)) or tostring(current),
        earnedText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(s.earned or 0)) or tostring(s.earned or 0),
        spentText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(s.spent or 0)) or tostring(s.spent or 0),
        profitText = (LPS.FormatMoneySmart and LPS:FormatMoneySmart(((s.earned or 0) - (s.spent or 0)))) or tostring(((s.earned or 0) - (s.spent or 0))),
    }
end

function LPS:OnPlayerMoney()
    local s = ensureSession()
    if not s.initialized then return end
    local current = GetMoney() or 0
    if not s.last then return end
    local diff = current - (s.last or current)
    if diff > 0 then
        s.earned = (s.earned or 0) + diff
    elseif diff < 0 then
        s.spent = (s.spent or 0) + (-diff)
    end
    s.last = current
    if LPS.UpdateGoldCharacterData then
        LPS:UpdateGoldCharacterData()
    end
end

LPS:RegisterDatatext({
    key = "gold",
    create = function(f)
        if f then f._lpsForceWhite = true end
    end,
    nameKey = "GOLD",
    events = { "PLAYER_ENTERING_WORLD", "PLAYER_MONEY" },
    update = function(f)
        local oldData = f.text and f.text:GetText()
        LPS:OnPlayerMoney()
        local data = LPS:GetGoldSessionData()
        if f.text then
            f.text:SetText(data.currentText)
        end
        if oldData and oldData ~= data.currentText then
            if LPS.ScheduleFrameSizeUpdate then
                LPS:ScheduleFrameSizeUpdate()
            end
        end
    end,
    onClick = function(self, button)
        if button == "RightButton" then
            if IsControlKeyDown() then
                LPS:ResetGoldSession()
                if self._lpsUpdateFunc then
                    self._lpsUpdateFunc(self)
                end
                return
            end
            if IsShiftKeyDown() and LPS.ShowGoldResetMenu then
                LPS:ShowGoldResetMenu(self)
                return
            end
        end
    end,
    customTooltip = true,
    buildTooltip = function(self)
        local d = LPS:GetDB()
        local tt = d and d.tooltips or {}
        local vis = tt.visibility or {}
        if not vis.enable then return end
        if vis.combat and InCombatLockdown() then return end
        if tt.gold and tt.gold.enable == false then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        LPS:ApplyTooltipFont(GameTooltip)
        if LPS.BuildGoldTooltip then
            LPS:BuildGoldTooltip(GameTooltip)
        end
        GameTooltip:Show()
    end,
})
