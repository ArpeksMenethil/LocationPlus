# Location Plus — Аддон для World of Warcraft

## Обзор проекта

**Location Plus** — это аддон для WoW, который добавляет информативную панель с локацией, координатами, временем и дополнительными данными. Работает без зависимости от ElvUI.

**Версия:** 1.3.8  
**Автор:** Arpeks  

**Поддерживаемые версии WoW:**

| TOC | Формат | Расширение |
|-----|--------|------------|
| `120001` | 12.0.1 | Retail (Midnight) |
| `11508` | 1.15.8 | Classic Era |
| `20505` | 2.5.5 | TBC Classic (Burning Crusade) |
| `50503` | 5.5.3 | Mists of Pandaria |

## Структура проекта

```
LocationPlus/
├── LocationPlus.toc          # Манифест аддона
├── Game/                     # Ядро аддона
│   ├── !load.xml             # Порядок загрузки файлов
│   ├── init.lua              # Инициализация, глобальные переменные
│   ├── core.lua              # Основная логика, загрузка
│   ├── frames.lua            # Универсальная функция создания фреймов
│   ├── layout.lua            # Позиционирование, размеры
│   ├── ui.lua                # Миникарта, move mode
│   ├── api.lua               # API функции (координаты, время, зоны)
│   ├── utils.lua             # Утилиты
│   └── compartment.lua       # Retail: отсек аддонов
├── Modules/                  # Модули
│   ├── !load.xml
│   ├── options.lua           # Настройки (AceConfig)
│   ├── Frames/               # Фреймы панелей
│   │   ├── location.lua      # Панель локации
│   │   ├── coords.lua        # Панель координат
│   │   ├── time.lua          # Панель времени
│   │   ├── gold.lua          # Панель золота
│   │   └── system.lua        # Панель системы (FPS, память)
│   └── Tooltips/             # Подсказки к панелям
│       ├── location_tt.lua
│       ├── time_tt.lua
│       ├── gold_tt.lua
│       └── system_tt.lua
├── Locales/                  # Локализация
│   ├── enUS.lua              # Английский (AceLocale)
│   └── ruRU.lua              # Русский (AceLocale)
├── Libs/                     # Внешние библиотеки
│   ├── Ace3/                 # Ace3 framework
│   ├── !load.xml             # Retail библиотеки
│   ├── !load_classic.xml     # Classic библиотеки
│   └── ...
└── Media/                    # Ресурсы
    ├── Logo.png
    ├── Logo-Modern.png
    ├── Pet.png
    ├── Fish.png
    └── Level.png
```

## Зависимости

### Обязательные
- **Ace3** — фреймворк для разработки аддонов

### Опциональные
- **LibDeflate** — сжатие для экспорта/импорта профилей
- **LibDBIcon-1.0** — иконка на миникарте
- **LibTourist-3.0** (и классик-версии) — информация о зонах, подземельях

## Архитектура

### Глобальная таблица
```lua
_G.ArpeksLPS.LPS = {
    wow = {...},           -- Информация о клиенте WoW
    addon = {...},        -- Метаданные аддона
    icons = {...},        -- Пути к иконкам
    frame = {...},        -- Созданные фреймы
    db = {...},           -- AceDB профиль
    defaults = {...}      -- Значения по умолчанию
}
```

### Версии WoW
```lua
LPS.Classic  -- WOW_PROJECT_CLASSIC
LPS.TBC      -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC
LPS.Mists    -- WOW_PROJECT_MISTS_CLASSIC
LPS.Retail   -- WOW_PROJECT_MAINLINE
```

### Сохранённые переменные
```lua
LPS_DB = {
    profiles = { Default = {...} },  -- Профили AceDB
    global = { gold = {...} }        -- Глобальные данные
}
```

## Ключевые функции

### Создание фреймов
```lua
LPS:CreateFrame(params)  -- Универсальный конструктор фреймов
```

**Параметры:**
- `name` — имя фрейма
- `parent` — родитель
- `size` — {width, height}
- `anchor` — {point, relativeTo, relativePoint, x, y}
- `updateFunc` — функция обновления
- `updateEvent` — события для обновления
- `onClick` — обработчик клика
- `tooltipFunc` — функция подсказки

### API функции
| Функция | Описание |
|---------|----------|
| `LPS:GetDB()` | Возвращает текущий профиль БД |
| `LPS:GetPlayerCoords()` | Координаты игрока |
| `LPS:GetZoneStatus(color)` | Статус зоны (PvP/мирная) |
| `LPS:GetFormattedTime()` | Игровое время с учётом CVar |
| `LPS:GetContinentID()` | ID континента |
| `LPS:GetMapNameByIDAlt(mapID)` | Название карты |
| `LPS:Round(num, decimals)` | Округление числа |

### Применение настроек
```lua
LPS:ApplyAllSettings()      -- Применить все настройки
LPS:ApplyLayout()           -- Макет и позиционирование
LPS:ApplyStyle()            -- Цвета, границы, шрифты
LPS:ApplyHolderPosition()   -- Позиция главного фрейма
LPS:ApplyVisibility()       -- Видимость (в бою и т.д.)
```

## Настройки (defaults)

### position
Позиция главного фрейма:
```lua
{
    point = "TOP",
    relativePoint = "TOP",
    x = 0,
    y = -10
}
```

### general
```lua
{
    loginMessage = true,           -- Сообщение при входе
    coordsTimeUpdate = 0.5,        -- Интервал обновления координат
    hideBlizzardZoneText = true,   -- Скрыть текст зоны Blizzard
    seconds = false,               -- Показывать секунды
    is24H = true                   -- 24-часовой формат
}
```

### show
```lua
{
    zone = false,                  -- Показывать зону на панели
    both = true,                   -- Обе координаты
    icon = true,                   -- Иконка зоны
    minimap = { hide = false, angle = 220 },
    gold = false,                  -- Панель золота
    system = false,                -- Панель системы
    hideCoordsInInstance = true,   -- Скрыть координаты в инстансах
    displayOther = "RLEVEL"        -- Доп. информация
}
```

### layout
```lua
{
    ht = true,                     -- Использовать шрифт DataTexts
    frameStrata = "LOW",           -- Слой фрейма
    frameLevel = 2,                -- Уровень фрейма
    dtshow = true,                 -- Показывать доп. панели
    sideSlots = {
        left = { frame = "coords" },
        right = { frame = "time" }
    }
}
```

### settings
```lua
{
    colors = {
        text = {1, 1, 1, 1},
        bgEnable = true,
        bg = {0, 0, 0, 0.6},
        border = {0.3, 0.3, 0.3, 1},
        tooltip = {1, 0.824, 0, 1},
        tooltipSetting = {0.41, 0.8, 0.94, 1}
    },
    fontSize = 12,
    borderSize = 2
}
```

## Команды консоли

| Команда | Описание |
|---------|----------|
| `/lps` | Открыть настройки аддона |

## События

| Событие | Обработчик |
|---------|------------|
| `ADDON_LOADED` | `LPS:onLoaded()` |
| `PLAYER_REGEN_DISABLED` | Скрыть в бою |
| `PLAYER_REGEN_ENABLED` | Показать после боя |

## Разработка

### Добавление нового фрейма
```lua
local params = {
    name = "LPS_MyFrame",
    parent = LPS.frame.holder,
    size = {100, 25},
    backdrop = { bgFile = "Interface\\Buttons\\WHITE8x8" },
    bgColor = {0, 0, 0, 0.6},
    borderColor = {0.3, 0.3, 0.3, 1},
    updateEvent = {events = {"PLAYER_LOGIN"}},
    updateFunc = function(self)
        self.text:SetText("Hello")
    end
}
LPS.frame.myframe = LPS:CreateFrame(params)
```

### Добавление настройки
1. Добавить в `LPS.defaults` в `init.lua`
2. Добавить в `options.lua` элемент AceConfig
3. Добавить локализацию в `Locales/*.lua`

### Локализация
```lua
-- Locales/ruRU.lua
local L = AceLocale:GetLocale("LocationPlus", "ruRU")
L["Key"] = "Значение"
```

## Отладка

Режим отладки включается автоматически для BattleTag `Arpeks#21468`:
```lua
LPS.DEBUG = true  -- Выводит отладочные сообщения
```

## Экспорт/Импорт профилей

Аддон поддерживает экспорт и импорт настроек через строку (используется LibDeflate для сжатия).

## Лицензия

Проект размещён на CurseForge: https://www.curseforge.com/wow/addons/location-plus  
ID проекта: 1444011
