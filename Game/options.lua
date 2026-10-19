local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end

-------------------------------------------------
-- OPTIONS — универсальный реестр пунктов меню
-------------------------------------------------
-- Единственный источник описаний ВСЕХ настроек аддона — дерево таблиц в
-- формате AceConfig-3.0 (`options` ниже). Оно используется двумя способами:
--   * если Ace3 доступен — регистрируется в AceConfig/AceConfigDialog
--     (прежнее поведение: окно настроек Blizzard, слаш-команды);
--   * всегда публикуется в LPS.Options.tree — нативное UI (Game/ui_options.lua,
--     дизайн портирован из CharacterStats) строит из него свои страницы без
--     каких-либо библиотек. Пункты нигде не дублируются.
LPS.Options = {}
LPS.Options.aceAppName = aceAppName

local function hasAce()
return LibStub and LibStub:GetLibrary("AceConfig-3.0", true)
and LibStub:GetLibrary("AceConfigDialog-3.0", true)
end

local AceConfig, AceDialog, AceConfigRegistry, AceSerializer, LibDeflate, AceGUI
if hasAce() then
AceConfig = LibStub("AceConfig-3.0")
AceDialog = LibStub("AceConfigDialog-3.0")
AceConfigRegistry = LibStub:GetLibrary("AceConfigRegistry-3.0", true)
AceSerializer = LibStub:GetLibrary("AceSerializer-3.0", true)
LibDeflate = LibStub:GetLibrary("LibDeflate", true)
AceGUI = LibStub:GetLibrary("AceGUI-3.0", true)
end

local PROFILE_EXPORT_PREFIX = "!LPS1!"

--- Имя таблицы опций в AceConfigRegistry (используется и в api.lua).
local aceAppName = "LocationPlus"

--- Единый источник пунктов меню: дерево строится ВСЕГДА (независимо от
--- наличия Ace3). Публикуется в LPS.Options.tree — его использует и нативное
--- UI (Game/ui_options.lua), и AceConfig. Пункты нигде не дублируются.
local options = buildOptionsTree()
LPS.Options.tree = options

do -- =====================================================================
-- Блок регистрации в Ace3: выполняется только если библиотеки найдены.
if not hasAce() then
-- нет Ace3 — наружу ничего не регистрируем; дерево опубликовано выше.
else

	if AceGUI and (AceGUI:GetWidgetVersion("LPSEditBoxNoButton") or 0) < 2 then
		local baseCtor = AceGUI.WidgetRegistry and AceGUI.WidgetRegistry["EditBox"]
		if baseCtor then
			AceGUI:RegisterWidgetType("LPSEditBoxNoButton", function()
				local widget = baseCtor()
				widget.type = "LPSEditBoxNoButton"
				local baseOnAcquire = widget.OnAcquire
				widget.OnAcquire = function(self)
					if baseOnAcquire then baseOnAcquire(self) end
					if self.DisableButton then
						self:DisableButton(true)
					end
				end
				if widget.editbox and widget.GetUserData then
					widget.editbox:HookScript("OnTextChanged", function(frame, userInput)
						if not userInput then return end
						local option = widget:GetUserData("option")
						if option and type(option.set) == "function" then
							option.set(nil, frame:GetText())
						end
					end)
				end
				return widget
			end, 2)
		end
	end

	if AceGUI and (AceGUI:GetWidgetVersion("LPSMultiLineEditBoxNoButton") or 0) < 2 then
		local baseCtor = AceGUI.WidgetRegistry and AceGUI.WidgetRegistry["MultiLineEditBox"]
		if baseCtor then
			AceGUI:RegisterWidgetType("LPSMultiLineEditBoxNoButton", function()
				local widget = baseCtor()
				widget.type = "LPSMultiLineEditBoxNoButton"
				local baseOnAcquire = widget.OnAcquire
				widget.OnAcquire = function(self)
					if baseOnAcquire then baseOnAcquire(self) end
					if self.DisableButton then
						self:DisableButton(true)
					end
				end
				if widget.editBox and widget.GetUserData then
					widget.editBox:HookScript("OnTextChanged", function(frame, userInput)
						if not userInput then return end
						local option = widget:GetUserData("option")
						if option and type(option.set) == "function" then
							option.set(nil, frame:GetText())
						end
					end)
				end
				return widget
			end, 2)
		end
	end

--- Единая точка применения настроек: инвалидация кэша, пересчёт layout,
--- обновление окон AceConfigDialog и нативного UI. Работает и без Ace3.
function LPS.Options:ApplyRefresh()
	if LPS.RefreshAfterProfileChange then
		LPS:RefreshAfterProfileChange()
	end
	if AceConfigRegistry and AceConfigRegistry.NotifyChange then
		AceConfigRegistry:NotifyChange(aceAppName)
	end
	if LPS.UI_Options and LPS.UI_Options.RefreshActivePage then
		LPS.UI_Options:RefreshActivePage()
	end
end

local applySettingsRefresh = function(...) LPS.Options:ApplyRefresh(...) end

deepCopy = function(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k2, v2 in pairs(v) do
		out[deepCopy(k2)] = deepCopy(v2)
	end
	return out
end

--- Запись значения по «точечному» пути в БД ("general.is24H").

--- Локальные помощники дерева опций.

	local function getDb()
		return LPS:GetDB() or {}
	end

	-- Каскад слотов: нет панели в слоте N — слоты N+1..3 неактивны.
	local function slotIsFilled(side, n)
		local ss = getDb().layout and getDb().layout.sideSlots
		local s = ss and ss[side .. n]
		if not s then return false end
		local v = s.frame
		return v ~= nil and v ~= "" and v ~= "NONE" and v ~= "None" and v ~= "none"
	end

function LPS.Options:SetByPath(path, value)
	local db = LPS:GetDB()
	if not db or type(path) ~= "string" then return end
	local cur, segs = db, {}
	for seg in path:gmatch("[^%.]+") do segs[#segs + 1] = seg end
	for i = 1, #segs - 1 do
		cur[segs[i]] = cur[segs[i]] or {}
		cur = cur[segs[i]]
	end
	cur[segs[#segs]] = value
	applySettingsRefresh()
end

end -- do (блок вспомогательных функций)

local aboutAuthor = nil
if GetAddOnMetadata and LPS.addon and LPS.addon.name then
	aboutAuthor = GetAddOnMetadata(LPS.addon.name, "Author")
end
if not aboutAuthor or aboutAuthor == "" then
	aboutAuthor = "Arpeks"
end

--- Дерево настроек (формат AceConfig-3.0). Строится всегда.
local function buildOptionsTree()

local function makeSlotDisabledFunc(side, n)
	return function()
		if n == 2 then
			return not slotIsFilled(side, 1)
		elseif n == 3 then
			return not slotIsFilled(side, 1) or not slotIsFilled(side, 2)
		end
		return false
	end
end

-- При выборе «none» в слоте N очищаем нижележащие слоты этой же стороны.
local function cascadeClearSlots(ss, side, n)
	if not ss then return end
	for i = n + 1, 3 do
		local other = ss[side .. i]
		if type(other) == "table" then other.frame = "NONE" end
	end
end

-- Дополнительные настройки конкретных панелей для автогенерации Panel Options
local PANEL_EXTRA = {
	bags = {
		display = {
			order = 3,
			name = LPS:L("Value format"),
			desc = LPS:L("Choose how the value is shown on the panel."),
			values = {
				USED_TOTAL = LPS:L("Used / Total"),
				FREE = LPS:L("Free slots"),
				USED = LPS:L("Used slots"),
			},
		},
	},
	experience = {
		display = {
			order = 3,
			name = LPS:L("Value format"),
			desc = LPS:L("Choose how the value is shown on the panel."),
			values = {
				PERCENT = LPS:L("Percent"),
				CURMAX = LPS:L("Current / Max"),
				CUR = LPS:L("Current"),
				REM = LPS:L("Remaining"),
			},
		},
	},
	friends = { maxLimit = true },
	guild = { maxLimit = true },
}

-- Фабрика группы настроек одной панели (tooltip + display/maxLimit/label)
-- Включение/выключение панелей не является настройкой: панель активна,
-- когда выбрана в слот (Side Panels), и скрыта, когда слот пуст.
local function makePanelOptionGroup(key, def, order)
	local args = {}
	local extra = PANEL_EXTRA[key]
	if extra then
		if extra.display then
			args.display = {
				order = extra.display.order - 2,
				type = "select",
				name = extra.display.name,
				desc = extra.display.desc,
				values = extra.display.values,
				get = function(info)
					local p = getDb().panels and getDb().panels[info[#info]]
					return (p and p.display) or next(extra.display.values)
				end,
				set = function(info, v)
					local k = info[#info]
					local db = getDb()
					db.panels = db.panels or {}
					local p = db.panels[k]
					if type(p) ~= "table" then
						p = {}
						db.panels[k] = p
					end
					p.display = v
					applySettingsRefresh()
				end,
			}
		end
		if extra.maxLimit then
			args.maxLimit = {
				order = 2,
				type = "range",
				name = LPS:L("Max entries in tooltip"),
				desc = LPS:L("Limit how many entries are shown in this list."),
				min = 1,
				max = 30,
				step = 1,
				get = function(info)
					local p = getDb().panels and getDb().panels[info[#info]]
					return (p and tonumber(p.maxLimit)) or 15
				end,
				set = function(info, v)
					local k = info[#info]
					local db = getDb()
					db.panels = db.panels or {}
					local p = db.panels[k]
					if type(p) ~= "table" then
						p = {}
						db.panels[k] = p
					end
					p.maxLimit = math.floor(v)
				end,
			}
		end
	end
	if key == "bags" then
		args.noLabel = {
			order = 5,
			type = "toggle",
			name = LPS:L("Hide label"),
			width = "half",
			get = function()
				local p = getDb().panels and getDb().panels.bags
				return p and p.noLabel or false
			end,
			set = function(_, v)
				local db = getDb()
				db.panels = db.panels or {}
				local p = db.panels.bags
				if type(p) ~= "table" then p = {}; db.panels.bags = p end
				p.noLabel = v and true or false
				applySettingsRefresh()
			end,
		}
		args.label = {
			order = 6,
			type = "input",
			name = LPS:L("Custom label"),
			width = "half",
			disabled = function()
				local p = getDb().panels and getDb().panels.bags
				return p and p.noLabel or false
			end,
			get = function()
				local p = getDb().panels and getDb().panels.bags
				return (p and p.label) or ""
			end,
			set = function(_, v)
				local db = getDb()
				db.panels = db.panels or {}
				local p = db.panels.bags
				if type(p) ~= "table" then p = {}; db.panels.bags = p end
				p.label = v or ""
				applySettingsRefresh()
			end,
		}
	end
	return {
		order = order,
		type = "group",
		inline = true,
		name = LPS:GetDatatextDisplayName(key),
		args = args,
	}
end


local function getDisplayOtherValues()
	local t = {
		["NONE"] = LPS:L("None"),
		["RLEVEL"] = LPS.icons.Level.." "..LPS:L("Level range"),
	}
	if not LPS.Retail and not LPS.Mists then
		t["PFISH"] = LPS.icons.Fish.." "..LPS:L("Fishing")
	end
	if LPS.Retail or LPS.Mists then
		t["PET"] = LPS.icons.Pet.." "..LPS:L("Battle pets")
	end
	return t
end

local strataValues = {
	["BACKGROUND"] = "BACKGROUND",
	["LOW"] = "LOW",
	["MEDIUM"] = "MEDIUM",
	["HIGH"] = "HIGH",
	["DIALOG"] = "DIALOG",
	["TOOLTIP"] = "TOOLTIP",
}

local fontFlagValues = {
	["NONE"] = LPS:L("None"),
	["OUTLINE"] = "OUTLINE",
	["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
	["THICKOUTLINE"] = "THICKOUTLINE",
}

local options = {
	type = "group",
	name = LPS.addon.title.." v"..LPS.addon.version,
	childGroups = "tab",
	args = {
		general = {
			type = "group",
			name = LPS:L("General"),
			order = 1,
			args = {
				generalGroup = {
					order = 4,
					type = "group",
					name = LPS:L("General"),
					inline = true,
					args = {
						left = {
							order = 1,
							type = "group",
							name = " ",
							inline = true,
							
							args = {
								loginMessage = {
									order = 1,
									name = LPS:L("Login message"),
									desc = LPS:L("Show a message in chat on login."),
									type = "toggle",
									
									get = function() return getDb().general.loginMessage end,
									set = function(_, v) getDb().general.loginMessage = v end,
								},
								spacer1_is24H = {
									order = 2.1,
									type = "description",
									name = "",
								},
								is24H = {
									type = "toggle",
									name = LPS:L("24H time format"),
									desc = LPS:L("Use 24-hour time format."),
									order = 3,
									
									get = function() return getDb().general.is24H end,
									set = function(_, v)
									getDb().general.is24H = v
									if LPS.ApplyTimeFormat then
									LPS:ApplyTimeFormat()
									end
									end,
								},
								seconds = {
									type = "toggle",
									name = LPS:L("Show seconds"),
									desc = LPS:L("Show seconds when using local time."),
									order = 4,
									
									get = function() return getDb().general.seconds end,
									set = function(_, v)
									getDb().general.seconds = v
									if LPS.ApplyTimeFormat then
									LPS:ApplyTimeFormat()
									end
									end,
								},
							},
						},
						right = {
							order = 2,
							type = "group",
							name = " ",
							inline = true,
							
							args = {
								minimapIcon = {
									type = "toggle",
									name = LPS:L("Minimap icon"),
									desc = LPS:L("Show/Hide minimap icon."),
									order = 1,
									
									get = function()
									local mm = getDb().show and getDb().show.minimap
									return not (mm and mm.hide)
									end,
									set = function(_, v)
									getDb().show.minimap = getDb().show.minimap or { hide = false, angle = 220 }
									getDb().show.minimap.hide = not v
									if v and LPS.CreateMinimapButton then
									LPS:CreateMinimapButton()
									end
									if LPS.UpdateMinimapButton then
									LPS:UpdateMinimapButton()
									end
									end,
								},
								addonCompartment = {
									type = "toggle",
									name = LPS:L("Addon Compartment"),
									desc = LPS:L("Show/Hide addon in the Addon Compartment."),
									order = 2,
									
									hidden = function() return not (LPS.Retail or LPS.Forever) end,
									disabled = function() return not (LPS.Retail or LPS.Forever) end,
									get = function() return getDb().show.addonCompartment end,
									set = function(_, v)
									getDb().show.addonCompartment = v
									if LPS.ApplyAddonCompartmentRegistration then
									LPS:ApplyAddonCompartmentRegistration()
									end
									end,
								},
								spacer1_combatHide = {
									order = 2.1,
									type = "description",
									name = "",
								},
								combatHide = {
									order = 4,
									name = LPS:L("Combat Hide"),
									desc = LPS:L("Show/Hide all panels when in combat"),
									type = "toggle",
									
									get = function() return getDb().show.visibility.combat end,
									set = function(_, v)
									getDb().show.visibility.combat = v
									if LPS.ApplyVisibility then
									LPS:ApplyVisibility()
									end
									end,
								},
							},
						},
					},
				},
				actionsGroup = {
					order = 99,
					type = "group",
					name = LPS:L("Actions"),
					inline = true,
					args = {
						moveFrame = {
							type = "execute",
							name = LPS:L("Move frame"),
							desc = LPS:L("Toggle move mode for the frame."),
							order = 1,
							func = function() LPS:ToggleMoveMode() end,
						},
						resetPosition = {
							type = "execute",
							name = LPS:L("Reset holder position"),
							desc = LPS:L("Reset the holder frame position."),
							order = 2,
							func = function() LPS:ResetFramePosition() end,
						},
						resetValues = {
							type = "execute",
							name = LPS:L("Reset values"),
							desc = LPS:L("Reset all addon settings to default values."),
							order = 3,
							func = function()
							if LPS.ResetAllSettingsToDefaults then
							LPS:ResetAllSettingsToDefaults()
							end
							end,
						},
					},
				},
			}
		},
		show = {
			type = "group",
			name = LPS:L("Display"),
			order = 2,
			args = {
				locationGroup = {
					order = 1,
					type = "group",
					name = LPS:L("Location"),
					inline = true,
					
					args = {
						zone = {
							order = 1,
							type = "toggle",
							name = LPS:L("Show zone"),
							desc = LPS:L("Show zone name on the panel."),
							
							get = function() return getDb().show.zone end,
							set = function(_, v)
							getDb().show.zone = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
						spacer1_showicon = {
							order = 1.1,
							type = "description",
							name = "",
						},
						showicon = {
							order = 2,
							name = LPS:L("Crest"),
							desc = LPS:L("Show an icon next to the additional info."),
							type = "toggle",
							
							disabled = function() return getDb().show.displayOther == "NONE" end,
							get = function() return getDb().show.showicon end,
							set = function(_, v)
							getDb().show.showicon = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
						displayOther = {
							order = 3,
							name = LPS:L("Other"),
							desc = LPS:L("Show additional info in the Location Panel"),
							type = "select",
							
							values = getDisplayOtherValues,
							get = function() return getDb().show.displayOther end,
							set = function(_, v)
							local values = getDisplayOtherValues()
							if values[v] == nil then
							v = "RLEVEL"
							end
							getDb().show.displayOther = v
							local f = LPS.frame and LPS.frame.location
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
					},
				},
				coordsGroup = {
					order = 2,
					type = "group",
					name = LPS:L("Coords"),
					inline = true,
					
					args = {
						dig = {
							order = 1,
							name = LPS:L("Detailed Coords"),
							desc = LPS:L("Adds 2 digits in the coords"),
							type = "toggle",
							
							get = function() return getDb().show.dig end,
							set = function(_, v)
							getDb().show.dig = v
							local f = LPS.frame and LPS.frame.coords
							if f and f._lpsUpdateFunc then
							f._lpsUpdateFunc(f)
							end
							end,
						},
						coordsTimeUpdate = {
							order = 2,
							name = LPS:L("Update Timer"),
							desc = LPS:L("Adjust coords updates (in seconds) to avoid cpu load."),
							type = "range",
							
							min = 0.05,
							max = 1,
							step = 0.05,
							get = function() return getDb().general.coordsTimeUpdate end,
							set = function(_, v)
								getDb().general.coordsTimeUpdate = v
								if LPS.ApplyCoordsUpdateInterval then
									LPS:ApplyCoordsUpdateInterval()
								end
							end,
						},
					},
				},
				experienceGroup = {
					order = 3,
					type = "group",
					name = LPS:L("Experience"),
					inline = true,
					
					args = {
						experience = {
							order = 1,
							type = "select",
							name = LPS:L("Value format"),
							desc = LPS:L("Choose how the value is shown on the panel."),
							values = {
								PERCENT = LPS:L("Percent"),
								CURMAX = LPS:L("Current / Max"),
								CUR = LPS:L("Current"),
								REM = LPS:L("Remaining"),
							},
							get = function() return getDb().show.experience.display or "PERCENT" end,
							set = function(_, v)
								getDb().show.experience.display = v
								applySettingsRefresh()
							end,
						},
					},
				},
				bagsGroup = {
					order = 4,
					type = "group",
					name = LPS:L("Bags"),
					inline = true,
					
					args = {
						bags = {
							order = 1,
							type = "select",
							name = LPS:L("Value format"),
							desc = LPS:L("Choose how the value is shown on the panel."),
							values = {
								USED_TOTAL = LPS:L("Used / Total"),
								FREE = LPS:L("Free slots"),
								USED = LPS:L("Used slots"),
							},
							get = function() return getDb().show.bags.display or "USED_TOTAL" end,
							set = function(_, v)
								getDb().show.bags.display = v
								applySettingsRefresh()
							end,
						},
						spacer1_bags = {
							order = 1.2,
							type = "description",
							name = "",
						},
						spacer2_bags = {
							order = 1.3,
							type = "description",
							name = "",
						},
						bagsLabel = {
							order = 2,
							type = "input",
							name = LPS:L("Custom label"),
							disabled = function() return getDb().show.bags.noLabel end,
							get = function() return getDb().show.bags.label or "" end,
							set = function(_, v)
								getDb().show.bags.label = v or ""
								applySettingsRefresh()
							end,
						},
						bagsNoLabel = {
							order = 3,
							type = "toggle",
							name = LPS:L("Hide label"),
							get = function() return getDb().show.bags.noLabel or false end,
							set = function(_, v)
								getDb().show.bags.noLabel = v and true or false
								applySettingsRefresh()
							end,
						},
					},
				},
			},
		},
		tooltip = {
			type = "group",
			name = LPS:L("Tooltip"),
			order = 3,
			args = {
				tt_grp = {
					order = 1,
					type = "group",
					name = LPS:L("Visibility"),
					inline = true,
					args = {
						tt = {
							order = 1,
							name = LPS:L("Show tooltip"),
							desc = LPS:L("Show tooltips when hovering over panels."),
							type = "toggle",
							get = function() return getDb().tooltips.visibility.enable end,
							set = function(_, v) getDb().tooltips.visibility.enable = v applySettingsRefresh() end,
						},
						hide_in_combat = {
							order = 2,
							name = LPS:L("Hide in combat"),
							desc = LPS:L("Hide tooltips while in combat."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.visibility.combat end,
							set = function(_, v) getDb().tooltips.visibility.combat = v applySettingsRefresh() end,
						},
					},
				},
				tt_options = {
					order = 2,
					type = "group",
					name = LPS:L("Location"),
					inline = true,
					args = {
						ttst = {
							order = 1,
							name = LPS:L("Status"),
							desc = LPS:L("Enable/Disable status on Tooltip."),
							type = "toggle",
							
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.location.status end,
							set = function(_, v) getDb().tooltips.location.status = v applySettingsRefresh() end,
						},
						petlevel = {
							order = 1.1,
							name = LPS.icons.Pet.." "..LPS:L("Battle Pet level"),
							desc = LPS:L("Enable/Disable battle pet level on the area."),
							type = "toggle",
							
							disabled = function() return not getDb().tooltips.visibility.enable or not (LPS.Retail or LPS.Mists) end,
							hidden = function() return not (LPS.Retail or LPS.Mists) end,
							get = function() return getDb().tooltips.location.battlePets end,
							set = function(_, v) getDb().tooltips.location.battlePets = v applySettingsRefresh() end,
						},
						ttlvl = {
							order = 2,
							name = LPS.icons.Level.." "..LPS:L("Level range"),
							desc = LPS:L("Enable/Disable level range on Tooltip."),
							type = "toggle",
							
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.location.level end,
							set = function(_, v) getDb().tooltips.location.level = v applySettingsRefresh() end,
						},
						fish = {
							order = 2.1,
							name = LPS.icons.Fish.." "..LPS:L("Area Fishing level"),
							desc = LPS:L("Enable/Disable fishing level on the area."),
							type = "toggle",
							
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Retail or LPS.Mists end,
							hidden = function() return LPS.Retail or LPS.Mists end,
							get = function() return getDb().tooltips.location.fish end,
							set = function(_, v) getDb().tooltips.location.fish = v applySettingsRefresh() end,
						},
						spacer2_prof = {
							order = 2.2,
							type = "description",
							name = "",
						},
						prof = {
							order = 3,
							name = LPS:L("Professions"),
							desc = LPS:L("Enable/Disable the professions, on Tooltip."),
							type = "toggle",
							
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.location.profession end,
							set = function(_, v) getDb().tooltips.location.profession = v applySettingsRefresh() end,
						},
						profcap = {
							order = 3.1,
							name = LPS:L("Hide capped"),
							desc = LPS:L("Hides a profession when the player reaches its highest level."),
							type = "toggle",
							
							disabled = function()
							return not getDb().tooltips.visibility.enable or not getDb().tooltips.location.profession
							end,
							get = function() return getDb().tooltips.location.professionHideMaxLevel end,
							set = function(_, v) getDb().tooltips.location.professionHideMaxLevel = v applySettingsRefresh() end,
						},
						filters = {
							order = 50,
							type = "group",
							name = LPS:L("Filters"),
							inline = true,
							hidden = function() return LPS.Forever end,
							args = {
								tthideraid = {
									order = 1,
									name = LPS:L("Hide Raid"),
									desc = LPS:L("Show/Hide raids on recommended dungeons."),
									type = "toggle",
									disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
									get = function() return getDb().tooltips.location.hides.raids end,
									set = function(_, v) getDb().tooltips.location.hides.raids = v applySettingsRefresh() end,
								},
								tthidepvp = {
									order = 2,
									name = LPS:L("Hide PvP"),
									desc = LPS:L("Show/Hide PvP zones, Arenas and BGs on recommended dungeons and zones."),
									type = "toggle",
									disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
									get = function() return getDb().tooltips.location.hides.pvp end,
									set = function(_, v) getDb().tooltips.location.hides.pvp = v applySettingsRefresh() end,
								},
							},
						},
						spacer1_ttreczones = {
							order = 4,
							type = "description",
							name = "",
						},
						ttreczones = {
							order = 6,
							name = LPS:L("Recommended Zones"),
							desc = LPS:L("Enable/Disable recommended zones on Tooltip."),
							type = "toggle",
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
							get = function() return getDb().tooltips.location.recomZone end,
							set = function(_, v) getDb().tooltips.location.recomZone = v applySettingsRefresh() end,
						},
						ttreczonesmax = {
							order = 6.1,
							name = LPS:L("Max entries"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							type = "range",
							
							min = 3,
							max = 20,
							step = 1,
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not getDb().tooltips.location.recomZone end,
							get = function() return tonumber(getDb().tooltips.location.recomZoneMax) or 5 end,
							set = function(_, v) getDb().tooltips.location.recomZoneMax = v applySettingsRefresh() end,
						},
						spacer1_ttinst = {
							order = 6.2,
							type = "description",
							name = "",
						},
						ttinst = {
							order = 7,
							name = LPS:L("Zone Dungeons"),
							desc = LPS:L("Enable/Disable dungeons in the zone, on Tooltip."),
							type = "toggle",
							
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
							get = function() return getDb().tooltips.location.zoneDungeon end,
							set = function(_, v) getDb().tooltips.location.zoneDungeon = v applySettingsRefresh() end,
						},
						ttinstmax = {
							order = 7.1,
							name = LPS:L("Max entries"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							type = "range",
							
							min = 3,
							max = 20,
							step = 1,
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not getDb().tooltips.location.zoneDungeon end,
							get = function() return tonumber(getDb().tooltips.location.zoneDungeonMax) or 5 end,
							set = function(_, v) getDb().tooltips.location.zoneDungeonMax = v applySettingsRefresh() end,
						},
						spacer1_ttrecinst = {
							order = 7.2,
							type = "description",
							name = "",
						},
						ttrecinst = {
							order = 8,
							name = LPS:L("Recommended Dungeons"),
							desc = LPS:L("Enable/Disable recommended dungeons on Tooltip."),
							type = "toggle",
							
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever end,
							get = function() return getDb().tooltips.location.recomDungeon end,
							set = function(_, v) getDb().tooltips.location.recomDungeon = v applySettingsRefresh() end,
						},
						ttcoords = {
							order = 9,
							name = LPS:L("with Entrance Coords"),
							desc = LPS:L("Enable/Disable the coords for area dungeons and recommended dungeon entrances, on Tooltip."),
							type = "toggle",
							
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or LPS.Forever or not (getDb().tooltips.location.recomDungeon or getDb().tooltips.location.zoneDungeon) end,
							get = function() return getDb().tooltips.location.recomDungeonCoords end,
							set = function(_, v) getDb().tooltips.location.recomDungeonCoords = v applySettingsRefresh() end,
						},
						ttrecinstmax = {
							order = 8.1,
							name = LPS:L("Max entries"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							type = "range",
							
							min = 3,
							max = 20,
							step = 1,
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.location.recomDungeon end,
							get = function() return tonumber(getDb().tooltips.location.recomDungeonMax) or 5 end,
							set = function(_, v) getDb().tooltips.location.recomDungeonMax = v applySettingsRefresh() end,
						},
					},
				},
				gold = {
					order = 30,
					type = "group",
					name = LPS:L("Gold"),
					inline = true,
					args = {
						enable = {
							order = 1,
							name = LPS:L("Enable"),
							desc = LPS:L("Enable tooltip on the gold panel."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.gold.enable end,
							set = function(_, v) getDb().tooltips.gold.enable = v applySettingsRefresh() end,
						},
						session = {
							order = 2,
							name = LPS:L("Session"),
							desc = LPS:L("Show session information in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
							get = function() return getDb().tooltips.gold.session end,
							set = function(_, v) getDb().tooltips.gold.session = v applySettingsRefresh() end,
						},
						spacer1_characters = {
							order = 2.1,
							type = "description",
							name = "",
						},
						characters = {
							order = 3,
							name = LPS:L("Characters"),
							desc = LPS:L("Show character gold list in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
							get = function() return getDb().tooltips.gold.characters end,
							set = function(_, v) getDb().tooltips.gold.characters = v applySettingsRefresh() end,
						},
						charactersMax = {
							order = 3.1,
							name = LPS:L("Max entries"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							type = "range",
							min = 3,
							max = 40,
							step = 1,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or not getDb().tooltips.gold.characters end,
							get = function() return tonumber(getDb().tooltips.gold.charactersMax) or 20 end,
							set = function(_, v) getDb().tooltips.gold.charactersMax = v applySettingsRefresh() end,
						},
						spacer1_serverTotals = {
							order = 3.2,
							type = "description",
							name = "",
						},
						serverTotals = {
							order = 4,
							name = LPS:L("On server"),
							desc = LPS:L("Show faction/server totals in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
							get = function() return getDb().tooltips.gold.serverTotals end,
							set = function(_, v) getDb().tooltips.gold.serverTotals = v applySettingsRefresh() end,
						},
						warband = {
							order = 5,
							name = LPS:L("Warband"),
							desc = LPS:L("Show Warband money in the tooltip (Retail)."),
							type = "toggle",
							hidden = function() return not LPS.Retail end,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or LPS.Forever end,
							get = function() return getDb().tooltips.gold.warband end,
							set = function(_, v) getDb().tooltips.gold.warband = v applySettingsRefresh() end,
						},
						token = {
							order = 6,
							name = LPS:L("WoW Token"),
							desc = LPS:L("Show WoW Token price in the tooltip (Retail)."),
							type = "toggle",
							hidden = function() return not LPS.Retail end,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or LPS.Forever end,
							get = function() return getDb().tooltips.gold.token end,
							set = function(_, v) getDb().tooltips.gold.token = v applySettingsRefresh() end,
						},
						currency = {
							order = 7,
							name = LPS:L("Currency"),
							desc = LPS:L("Enable/Disable the currencies, on Tooltip."),
							type = "toggle",
							
							hidden = function() return not LPS.Retail end,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable or not LPS.Retail end,
							get = function() return getDb().tooltips.gold.currency end,
							set = function(_, v) getDb().tooltips.gold.currency = v applySettingsRefresh() end,
						},
						resetHints = {
							order = 8,
							name = LPS:L("Show Hints"),
							desc = LPS:L("Show reset keybind hints at the bottom of the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.gold.enable end,
							get = function() return getDb().tooltips.gold.resetHints end,
							set = function(_, v) getDb().tooltips.gold.resetHints = v applySettingsRefresh() end,
						},
					},
				},
				system = {
					order = 40,
					type = "group",
					name = LPS:L("System"),
					inline = true,
					args = {
						enable = {
							order = 1,
							name = LPS:L("Enable"),
							desc = LPS:L("Enable tooltip on the system panel."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.system.enable end,
							set = function(_, v) getDb().tooltips.system.enable = v applySettingsRefresh() end,
						},
						network = {
							order = 2,
							name = LPS:L("Bandwidth"),
							desc = LPS:L("Show FPS and network information in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
							get = function() return getDb().tooltips.system.network end,
							set = function(_, v) getDb().tooltips.system.network = v applySettingsRefresh() end,
						},
						spacer1_addons = {
							order = 2.2,
							type = "description",
							name = "",
						},
						addons = {
							order = 3,
							name = LPS:L("AddOns"),
							desc = LPS:L("Show addon memory usage list in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
							get = function() return getDb().tooltips.system.addons end,
							set = function(_, v) getDb().tooltips.system.addons = v applySettingsRefresh() end,
						},
						addonsMax = {
							order = 3.1,
							name = LPS:L("Max entries"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							type = "range",
							min = 3,
							max = 40,
							step = 1,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable or not getDb().tooltips.system.addons end,
							get = function() return tonumber(getDb().tooltips.system.addonsMax) or 15 end,
							set = function(_, v) getDb().tooltips.system.addonsMax = v applySettingsRefresh() end,
						},
						spacer1_total = {
							order = 3.2,
							type = "description",
							name = "",
						},
						total = {
							order = 4,
							name = LPS:L("Total"),
							desc = LPS:L("Show total addon memory usage line in the tooltip."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.system.enable end,
							get = function() return getDb().tooltips.system.total end,
							set = function(_, v) getDb().tooltips.system.total = v applySettingsRefresh() end,
						},
					},
				},
				time = {
					order = 20,
					type = "group",
					name = LPS:L("Time"),
					inline = true,
					args = {
						enable = {
							order = 1,
							name = LPS:L("Enable"),
							desc = LPS:L("Enable tooltip on the time panel."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.time.enable end,
							set = function(_, v) getDb().tooltips.time.enable = v applySettingsRefresh() end,
						},
						raids = {
							order = 2,
							name = LPS:L("Cooldown raids"),
							desc = LPS:L("Show saved raids list."),
							type = "toggle",
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable or LPS.Forever end,
							get = function() return getDb().tooltips.time.raids end,
							set = function(_, v) getDb().tooltips.time.raids = v applySettingsRefresh() end,
						},
						dungeons = {
							order = 3,
							name = LPS:L("Cooldown dungeons"),
							desc = LPS:L("Show saved dungeons list."),
							type = "toggle",
							hidden = function() return LPS.Forever end,
							disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable or LPS.Forever end,
							get = function() return getDb().tooltips.time.dungeons end,
							set = function(_, v) getDb().tooltips.time.dungeons = v applySettingsRefresh() end,
						},
						playedTime = {
							order = 4,
							name = LPS:L("Played Time"),
							desc = LPS:L("Show played time across all your characters (Required 'Broker: Played Time')"),
							type = "toggle",
							disabled = function() return not getDb().tooltips.time.enable or not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.time.playedTime end,
							set = function(_, v) getDb().tooltips.time.playedTime = v applySettingsRefresh() end,
						}
					},
				},
				friends = {
					order = 51,
					type = "group",
					name = LPS:L("Friends"),
					inline = true,
					args = {
						enable = {
							order = 1,
							name = LPS:L("Enable"),
							desc = LPS:L("Show a tooltip when hovering over this panel."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.friends.enable end,
							set = function(_, v) getDb().tooltips.friends.enable = v applySettingsRefresh() end,
						},
						maxLimit = {
							order = 2,
							type = "range",
							name = LPS:L("Max entries in tooltip"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							min = 1,
							max = 30,
							step = 1,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.friends.enable end,
							get = function() return tonumber(getDb().tooltips.friends.maxLimit) or 15 end,
							set = function(_, v) getDb().tooltips.friends.maxLimit = math.floor(v) applySettingsRefresh() end,
						},
					},
				},
				guild = {
					order = 52,
					type = "group",
					name = LPS:L("Guild"),
					inline = true,
					args = {
						enable = {
							order = 1,
							name = LPS:L("Enable"),
							desc = LPS:L("Show a tooltip when hovering over this panel."),
							type = "toggle",
							disabled = function() return not getDb().tooltips.visibility.enable end,
							get = function() return getDb().tooltips.guild.enable end,
							set = function(_, v) getDb().tooltips.guild.enable = v applySettingsRefresh() end,
						},
						maxLimit = {
							order = 2,
							type = "range",
							name = LPS:L("Max entries in tooltip"),
							desc = LPS:L("Limit how many entries are shown in this list."),
							min = 1,
							max = 30,
							step = 1,
							disabled = function() return not getDb().tooltips.visibility.enable or not getDb().tooltips.guild.enable end,
							get = function() return tonumber(getDb().tooltips.guild.maxLimit) or 15 end,
							set = function(_, v) getDb().tooltips.guild.maxLimit = math.floor(v) applySettingsRefresh() end,
						},
					},
				},
			},
		},
		layout = {
			type = "group",
			name = LPS:L("Layout"),
			order = 4,
			args = {
				chainAnchor = {
					order = 3,
					type = "select",
					name = LPS:L("Frame anchor mode"),
					desc = LPS:L("Side panels always grow along their edge: left panels attach to the LEFT side of the group, right panels attach to the RIGHT side. This option controls what the FIRST panel of each chain anchors to: the location panel edges (default) or the outer edges of the whole holder frame."),
					values = {
						chain = LPS:L("Location panel edges"),
						location = LPS:L("Holder outer edges"),
					},
					get = function() return getDb().layout.chainAnchor or "chain" end,
					set = function(_, v)
					getDb().layout.chainAnchor = v
					applySettingsRefresh()
					end,
				},
				locpanel = {
					order = 4,
					type = "group",
					name = LPS:L("Location Panel"),
					inline = true,
					args = {
						locMinWidth = {
							order = 0,
							type = "range",
							name = LPS:L("Minimum width"),
							desc = LPS:L("Sets the minimum width of the location panel."),
							min = 200,
							max = 300,
							step = 1,
							get = function() return getDb().layout.locMinWidth end,
							set = function(_, v)
							getDb().layout.locMinWidth = v
							applySettingsRefresh()
							end,
						},
						locPaddingX = {
							order = 1,
							type = "range",
							name = LPS:L("Text padding X"),
							desc = LPS:L("Adjust horizontal text padding inside location panel."),
							min = 0,
							max = 60,
							step = 1,
							get = function() return getDb().layout.locPaddingX end,
							set = function(_, v)
							getDb().layout.locPaddingX = v
							applySettingsRefresh()
							end,
						},
						locPaddingY = {
							order = 2,
							type = "range",
							name = LPS:L("Text padding Y"),
							desc = LPS:L("Adjust vertical text padding inside location panel."),
							min = 0,
							max = 30,
							step = 1,
							get = function() return getDb().layout.locPaddingY end,
							set = function(_, v)
							getDb().layout.locPaddingY = v
							applySettingsRefresh()
							end,
						},
					},
				},
				panels = {
					order = 5,
					type = "group",
					name = LPS:L("Panels"),
					inline = true,
					args = {
						dtshow = {
							order = 0.3,
							name = LPS:L("Show panels"),
							desc = LPS:L("Show/Hide the extra panels (Coords and Time)."),
							type = "toggle",
							
							get = function() return getDb().layout.dtshow end,
							set = function(_, v)
							getDb().layout.dtshow = v
							if LPS.ApplyDTVisibility then
							LPS:ApplyDTVisibility()
							end
							applySettingsRefresh()
							end,
						},
						
						spacer1_dtMinWidth = {
							order = 0.6,
							type = "description",
							name = "",
						},
						spacer2_dtMinWidth = {
							order = 0.7,
							type = "description",
							name = "",
						},
						dtMinWidth = {
							order = 1,
							type = "range",
							name = LPS:L("Minimum width"),
							desc = LPS:L("Sets the minimum width of the extra panels."),
							min = 100,
							max = 200,
							step = 1,
							disabled = function() return getDb().layout.dtshow == false end,
							get = function() return getDb().layout.dtMinWidth end,
							set = function(_, v)
							getDb().layout.dtMinWidth = v
							applySettingsRefresh()
							end,
						},
						dtPaddingX = {
							order = 2,
							type = "range",
							name = LPS:L("Text padding X"),
							desc = LPS:L("Adjust horizontal text padding inside panels."),
							min = 0,
							max = 60,
							step = 1,
							disabled = function() return getDb().layout.dtshow == false end,
							get = function() return getDb().layout.dtPaddingX end,
							set = function(_, v)
							getDb().layout.dtPaddingX = v
							applySettingsRefresh()
							end,
						},
						dtPaddingY = {
							order = 3,
							type = "range",
							name = LPS:L("Text padding Y"),
							desc = LPS:L("Adjust vertical text padding inside panels."),
							min = 0,
							max = 30,
							step = 1,
							disabled = function() return getDb().layout.dtshow == false end,
							get = function() return getDb().layout.dtPaddingY end,
							set = function(_, v)
							getDb().layout.dtPaddingY = v
							applySettingsRefresh()
							end,
						},
					},
				},
				panelsGroup = {
					order = 6,
					type = "group",
					name = LPS:L("Side Panels"),
					inline = true,
					args = {
						leftSlot1 = {
							order = 1.1,
							name = LPS:L("Left Slot 1"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left1"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.left1 = ss.left1 or { offsetX = 0, offsetY = 0 }
							local cur = ss.left1
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							if v == "none" then cascadeClearSlots(ss, "left", 1) end
							-- Помечаем слот «тронутым», иначе следующий ApplyDefaults вернёт в
							-- нетронутый слот панель по умолчанию и выбор пользователя сотрётся.
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["left1"] = true
							applySettingsRefresh()
							end,
						},
						leftOffsetX1 = {
							order = 1.11,
							name = LPS:L("Left Offset X 1"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left1"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left1"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						leftOffsetY1 = {
							order = 1.12,
							name = LPS:L("Left Offset Y 1"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left1"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left1"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
						rightSlot1 = {
							order = 1.2,
							name = LPS:L("Right Slot 1"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right1"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.right1 = ss.right1 or { offsetX = 0, offsetY = 0 }
							local cur = ss.right1
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							if v == "none" then cascadeClearSlots(ss, "right", 1) end
							-- Помечаем слот «тронутым», иначе следующий ApplyDefaults вернёт в
							-- нетронутый слот панель по умолчанию и выбор пользователя сотрётся.
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["right1"] = true
							applySettingsRefresh()
							end,
						},
						rightOffsetX1 = {
							order = 1.21,
							name = LPS:L("Right Offset X 1"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right1"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right1"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						rightOffsetY1 = {
							order = 1.22,
							name = LPS:L("Right Offset Y 1"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right1"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right1"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
						leftSlot2 = {
							disabled = makeSlotDisabledFunc("left", 2),
							order = 2.1,
							name = LPS:L("Left Slot 2"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left2"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.left2 = ss.left2 or { offsetX = 0, offsetY = 0 }
							local cur = ss.left2
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							if v == "none" then cascadeClearSlots(ss, "left", 2) end
							-- Помечаем слот «тронутым», иначе следующий ApplyDefaults вернёт в
							-- нетронутый слот панель по умолчанию и выбор пользователя сотрётся.
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["left2"] = true
							applySettingsRefresh()
							end,
						},
						leftOffsetX2 = {
							disabled = makeSlotDisabledFunc("left", 2),
							order = 2.11,
							name = LPS:L("Left Offset X 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left2"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left2"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						leftOffsetY2 = {
							disabled = makeSlotDisabledFunc("left", 2),
							order = 2.12,
							name = LPS:L("Left Offset Y 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left2"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left2"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
						rightSlot2 = {
							disabled = makeSlotDisabledFunc("right", 2),
							order = 2.2,
							name = LPS:L("Right Slot 2"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right2"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.right2 = ss.right2 or { offsetX = 0, offsetY = 0 }
							local cur = ss.right2
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							if v == "none" then cascadeClearSlots(ss, "right", 2) end
							-- Помечаем слот «тронутым», иначе следующий ApplyDefaults вернёт в
							-- нетронутый слот панель по умолчанию и выбор пользователя сотрётся.
							ss.userTouched = ss.userTouched or {}
							ss.userTouched["right2"] = true
							applySettingsRefresh()
							end,
						},
						rightOffsetX2 = {
							disabled = makeSlotDisabledFunc("right", 2),
							order = 2.21,
							name = LPS:L("Right Offset X 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right2"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right2"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						rightOffsetY2 = {
							disabled = makeSlotDisabledFunc("right", 2),
							order = 2.22,
							name = LPS:L("Right Offset Y 2"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right2"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right2"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
						leftSlot3 = {
							disabled = makeSlotDisabledFunc("left", 3),
							order = 3.1,
							name = LPS:L("Left Slot 3"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left3"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.left3 = ss.left3 or { offsetX = 0, offsetY = 0 }
							local cur = ss.left3
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							-- Помечаем слот «тронутым» (см. комментарий выше): иначе ApplyDefaults
							-- вернёт в него панель по умолчанию и сотрёт выбор пользователя.
							local _ss = getDb().layout.sideSlots
							_ss.userTouched = _ss.userTouched or {}
							_ss.userTouched["left3"] = true
							applySettingsRefresh()
							end,
						},
						leftOffsetX3 = {
							disabled = makeSlotDisabledFunc("left", 3),
							order = 3.11,
							name = LPS:L("Left Offset X 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left3"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left3"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						leftOffsetY3 = {
							disabled = makeSlotDisabledFunc("left", 3),
							order = 3.12,
							name = LPS:L("Left Offset Y 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left3"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["left3"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
						rightSlot3 = {
							disabled = makeSlotDisabledFunc("right", 3),
							order = 3.2,
							name = LPS:L("Right Slot 3"),
							desc = LPS:L("Select a panel for this slot."),
							type = "select",
							values = function()
							local vals = { none = LPS:L("None") }
							-- coords/time/gold/system включены в GetSlotKeyList()
							-- и идут в общем алфавитном порядке
							if LPS.GetSlotKeyList then
							for _, k in ipairs(LPS:GetSlotKeyList()) do
							-- Название ВСЕГДА локализованное (язык клиента): берём из реестра через GetDatatextName.
							vals[k] = LPS:GetDatatextName(k)
							end
							end
							return vals
							end,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right3"]
							local v = (s and s.frame) or "NONE"
							if v == "NONE" or v == "None" or v == "" or v == nil then
							return "none"
							end
							return v
							end,
							set = function(_, v)
							local db = getDb()
							db.layout.sideSlots = db.layout.sideSlots or {}
							local ss = db.layout.sideSlots
							ss.right3 = ss.right3 or { offsetX = 0, offsetY = 0 }
							local cur = ss.right3
							v = v or "none"
							if v ~= "none" then
							for _, other in pairs(ss) do
							if type(other) == "table" and other ~= cur and other.frame == v then
							other.frame = "NONE"
							end
							end
							end
							cur.frame = (v == "none") and "NONE" or v
							-- Помечаем слот «тронутым» (см. комментарий выше): иначе ApplyDefaults
							-- вернёт в него панель по умолчанию и сотрёт выбор пользователя.
							local _ss = getDb().layout.sideSlots
							_ss.userTouched = _ss.userTouched or {}
							_ss.userTouched["right3"] = true
							applySettingsRefresh()
							end,
						},
						rightOffsetX3 = {
							disabled = makeSlotDisabledFunc("right", 3),
							order = 3.21,
							name = LPS:L("Right Offset X 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right3"]
							return tonumber(s and s.offsetX) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right3"]
							if s then s.offsetX = v end
							applySettingsRefresh()
							end,
						},
						rightOffsetY3 = {
							disabled = makeSlotDisabledFunc("right", 3),
							order = 3.22,
							name = LPS:L("Right Offset Y 3"),
							type = "range",
							min = -200,
							max = 200,
							step = 1,
							get = function()
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right3"]
							return tonumber(s and s.offsetY) or 0
							end,
							set = function(_, v)
							local ss = getDb().layout.sideSlots
							local s = ss and ss["right3"]
							if s then s.offsetY = v end
							applySettingsRefresh()
							end,
						},
					},
				},
				spacingGroup = {
					order = 7,
					type = "group",
					name = LPS:L("Spacing"),
					inline = true,
					args = {
						spacingAuto = {
							order = 1,
							type = "toggle",
							name = LPS:L("Auto"),
							desc = LPS:L("Automatically manage spacing between panels."),
							get = function() return getDb().layout.spacingAuto end,
							set = function(_, v)
							getDb().layout.spacingAuto = v
							applySettingsRefresh()
							end,
						},
						spacingManual = {
							order = 2,
							type = "range",
							name = LPS:L("Manual"),
							desc = LPS:L("Set spacing between panels."),
							min = 0,
							max = 50,
							step = 1,
							disabled = function() return getDb().layout.spacingAuto end,
							get = function() return getDb().layout.spacingManual end,
							set = function(_, v)
							getDb().layout.spacingManual = v
							applySettingsRefresh()
							end,
						},
					},
				},
				style = {
					type = "group",
					name = LPS:L("Style"),
					order = 8,
					inline = true,
					args = {
						frameStrata = {
							type = "select",
							name = LPS:L("Frame strata"),
							desc = LPS:L("Controls how high the LocationPlus panels are drawn."),
							order = 0,
							values = strataValues,
							get = function() return getDb().layout.frameStrata end,
							set = function(_, v)
							getDb().layout.frameStrata = v
							applySettingsRefresh()
							end,
						},
						frameLevel = {
							type = "range",
							name = LPS:L("Frame level"),
							desc = LPS:L("Fine-tune draw order within the selected strata."),
							order = 0.1,
							min = 0,
							max = 1000,
							step = 1,
							get = function() return tonumber(getDb().layout.frameLevel) or 1 end,
							set = function(_, v)
							getDb().layout.frameLevel = v
							applySettingsRefresh()
							end,
						},
						spacer1_fontSize = {
							type = "description",
							name = " ",
							order = 0.5,
						},
						fontSize = {
							type = "range",
							name = LPS:L("Font size"),
							desc = LPS:L("Set font size."),
							order = 1.1,
							min = 8,
							max = 20,
							step = 1,
							get = function() return getDb().settings.fontSize end,
							set = function(_, v)
							getDb().settings.fontSize = v
							if LPS.ApplyStyle then
							LPS:ApplyStyle()
							end
							end,
						},
						borderSize = {
							type = "range",
							name = LPS:L("Border size"),
							desc = LPS:L("Set border thickness."),
							order = 1.2,
							min = 0,
							max = 6,
							step = 1,
							get = function() return getDb().settings.borderSize end,
							set = function(_, v)
							getDb().settings.borderSize = v
							if LPS.ApplyStyle then
							LPS:ApplyStyle()
							end
							end,
						},
						spacer1_bgEnable = {
							type = "description",
							name = " ",
							order = 1.5,
						},
						bgEnable = {
							type = "toggle",
							name = LPS:L("Enable background"),
							desc = LPS:L("Toggle background on the panel."),
							order = 2.1,
							get = function() return getDb().settings.colors.bgEnable end,
							set = function(_, v)
							getDb().settings.colors.bgEnable = v
							if LPS.ApplyStyle then
							LPS:ApplyStyle()
							end
							end,
						},
						bgColor = {
							type = "color",
							name = LPS:L("Background color"),
							desc = LPS:L("Set background color."),
							order = 2.2,
							hasAlpha = true,
							get = function()
							local c = getDb().settings.colors.bg
							return c[1], c[2], c[3], c[4]
							end,
							set = function(_, r, g, b, a)
							local c = getDb().settings.colors.bg
							c[1], c[2], c[3], c[4] = r, g, b, a
							if LPS.ApplyStyle then
							LPS:ApplyStyle()
							end
							end,
						},
						borderColor = {
							type = "color",
							name = LPS:L("Border color"),
							desc = LPS:L("Set border color."),
							order = 3.3,
							hasAlpha = true,
							get = function()
							local c = getDb().settings.colors.border
							return c[1], c[2], c[3], c[4]
							end,
							set = function(_, r, g, b, a)
							local c = getDb().settings.colors.border
							c[1], c[2], c[3], c[4] = r, g, b, a
							if LPS.ApplyStyle then
							LPS:ApplyStyle()
							end
							end,
						},
					},
				},
				colors = {
					order = 9,
					type = "group",
					name = LPS:L("Colors"),
					inline = true,
					args = {
						customColor = {
							order = 1,
							name = LPS:L("Text color"),
							desc = LPS:L("Choose how panel text is colored. The location panel always keeps its own zone-status color."),
							type = "select",
							values = {
								[1] = LPS:L("Custom"),
								[2] = LPS:L("Class Colors"),
								[3] = LPS:L("Default"),
							},
							get = function() return getDb().layout.customColor end,
							set = function(_, v)
							getDb().layout.customColor = v
							applySettingsRefresh()
							end,
						},
						userColor = {
							order = 2,
							name = LPS:L("Text custom color"),
							desc = LPS:L("Pick a custom color for panel text."),
							type = "color",
							disabled = function() return getDb().layout.customColor ~= 1 end,
							get = function()
							local c = getDb().layout.userColor
							return (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
							end,
							set = function(_, r, g, b)
							local c = getDb().layout.userColor
							if not c then
							c = { r = 1, g = 1, b = 1 }
							getDb().layout.userColor = c
							end
							c.r, c.g, c.b = r, g, b
							applySettingsRefresh()
							end,
						},
					},
				},
			},
		},
		profiles = {
			type = "group",
			name = LPS:L("Profiles"),
			order = 90,
			args = {},
		},
		-- NOTE: the AceConfigRegistry validator only allows a fixed set of
		-- keys on each option entry (type/name/desc/order/args/childGroups...).
		-- Any extra key (e.g. an accidental "path") makes every dialog open
		-- fail with "ValidateOptionsTable(): <app>.<key>: unknown parameter".
		importexport = {
			type = "group",
			name = LPS:L("Import/Export"),
			order = 91,
			args = {
				export = {
					type = "group",
					name = LPS:L("Export"),
					order = 1,
					args = {
						header = {
							order = 1,
							type = "header",
							name = LPS:L("Export"),
						},
						generate = {
							order = 2,
							type = "execute",
							name = LPS:L("Generate export string"),
							desc = LPS:L("Generate an export string for the current profile."),
							disabled = function()
							return not (AceSerializer and LPS.db and LPS.db.profile)
							end,
							func = function()
							local serialString = AceSerializer:Serialize(LPS.db.profile or {})
							if LibDeflate and LibDeflate.CompressDeflate and LibDeflate.EncodeForPrint then
							local compressedData = LibDeflate:CompressDeflate(serialString, { level = 5 })
							local printableString = compressedData and LibDeflate:EncodeForPrint(compressedData)
							if printableString then
							LPS.Options._profileExportText = PROFILE_EXPORT_PREFIX .. printableString
							return
							end
							end
							LPS.Options._profileExportText = serialString
							end,
						},
						text = {
							order = 3,
							type = "input",
							name = LPS:L("Export string"),
							desc = LPS:L("Copy this string to export your current profile."),
							width = "full",
							multiline = 12,
							dialogControl = "LPSMultiLineEditBoxNoButton",
							disabled = function()
							return not (AceSerializer and LPS.db and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileExportText or "") end,
							set = function(_, v) LPS.Options._profileExportText = v end,
						},
					},
				},
				import = {
					type = "group",
					name = LPS:L("Import"),
					order = 2,
					args = {
						header = {
							order = 1,
							type = "header",
							name = LPS:L("Import"),
						},
						asName = {
							order = 2,
							type = "input",
							name = LPS:L("Profile name"),
							desc = LPS:L("Name of the profile to import into."),
							dialogControl = "LPSEditBoxNoButton",
							disabled = function()
							return not (AceSerializer and LPS.db and LPS.db.SetProfile and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileImportAsName or "") end,
							set = function(_, v) LPS.Options._profileImportAsName = v end,
						},
						text = {
							order = 3,
							type = "input",
							name = LPS:L("Import string"),
							desc = LPS:L("Paste an export string here to import a profile."),
							width = "full",
							multiline = 12,
							dialogControl = "LPSMultiLineEditBoxNoButton",
							disabled = function()
							return not (AceSerializer and LPS.db and LPS.db.profile)
							end,
							get = function() return tostring(LPS.Options._profileImportText or "") end,
							set = function(_, v) LPS.Options._profileImportText = v end,
						},
						doImport = {
							order = 4,
							type = "execute",
							name = LPS:L("Import"),
							desc = LPS:L("Import the string into the selected profile name."),
							disabled = function()
							return not (AceSerializer and LPS.db and LPS.db.profile and LPS.db.SetProfile)
							end,
							func = function()
							local s = tostring(LPS.Options._profileImportText or "")
							if s == "" then return end
							local importName = tostring(LPS.Options._profileImportAsName or "")
							local currentProfile = LPS.db and LPS.db.GetCurrentProfile and LPS.db:GetCurrentProfile()
							if importName == "" then
							importName = tostring(currentProfile or "")
							end
							if importName == "" then return end
							local decodeString = s
							if LibDeflate and LibDeflate.DecodeForPrint and LibDeflate.DecompressDeflate and s:sub(1, #PROFILE_EXPORT_PREFIX) == PROFILE_EXPORT_PREFIX then
							local encoded = s:sub(#PROFILE_EXPORT_PREFIX + 1)
							encoded = encoded:gsub("%s+", "")
							local compressed = LibDeflate:DecodeForPrint(encoded)
							if not compressed then return end
							local decompressed = LibDeflate:DecompressDeflate(compressed)
							if not decompressed then return end
							decodeString = decompressed
							end
							local ok, t = AceSerializer:Deserialize(decodeString)
							if not ok or type(t) ~= "table" then
							return
							end
							if currentProfile and importName ~= currentProfile then
							LPS.db:SetProfile(importName)
							end
							local p2 = LPS.db.profile
							for k in pairs(p2) do
							p2[k] = nil
							end
							for k, v in pairs(t) do
							p2[k] = deepCopy(v)
							end
							if LPS.RefreshAfterProfileChange then
							LPS:RefreshAfterProfileChange()
							end
							end,
						},
					},
				},
			},
		},
	},
}
	return options
end -- buildOptionsTree()

-- NOTE: the root table is registered by registerRootAndSubCategories() below,
-- which runs at load time and again (idempotently) from LPS.Options:FinalizeAce()
-- once the AceDB profile exists (see Game/core.lua onLoaded). This avoids the
-- "RegisterOptionsTable(appName, options): 'options' - expected table or function
-- reference" error when a get/set function inlined in the table throws during
-- the registry's validation pass (e.g. because the database was not ready yet).

local function resolveAceName(v)
	if type(v) == "function" then
		local ok, r = pcall(v)
		if ok and r ~= nil then
			return tostring(r)
		end
		return ""
	end
	return tostring(v or "")
end

local function registerSubCategory(suffix, group)
	if type(group) ~= "table" then return end
	local displayName = resolveAceName(group.name)
	if displayName == "" then
		displayName = suffix
	end
	local appName = aceAppName .. suffix
	AceConfig:RegisterOptionsTable(appName, group)
	AceDialog:AddToBlizOptions(appName, displayName, LPS.addon.title)
end


local rootRegistered = false
local subCategoriesRegistered = false

local function registerRootAndSubCategories()
	if type(options) ~= "table" then return end
	if not rootRegistered then
		rootRegistered = true
		local ok, err = pcall(AceConfig.RegisterOptionsTable, AceConfig, aceAppName, options)
	end
	if not subCategoriesRegistered then
		subCategoriesRegistered = true
		registerSubCategory("_General", options.args.general)
		registerSubCategory("_Show", options.args.show)
		registerSubCategory("_Tooltip", options.args.tooltip)
		registerSubCategory("_Layout", options.args.layout)
		if options.args.importexport then
			registerSubCategory("_ImportExport", options.args.importexport)
		end
	end
end

AceConfig:RegisterOptionsTable(aceAppName .. "_About", {
type = "group",
name = LPS.addon.title.." v"..LPS.addon.version,
args = {
	logo = {
		order = 1,
		type = "description",
		name = " ",
		image = LPS.icons.PathLogoModern,
		imageWidth = 128,
		imageHeight = 128,
	},
	spacer = {
		order = 2,
		type = "description",
		name = " ",
	},
	creditsHeader = {
		order = 3,
		type = "header",
		name = "Credits",
	},
	creditsList = {
		order = 4,
		type = "description",
		fontSize = "medium",
		name = table.concat({
			"|cffffd200Author:|r "..aboutAuthor,
			"",
			"|cffffd200Special Thanks:|r",
			" |cff00ff00The WoW addon community|r",
		}, "\n"),
	},
},
})
AceDialog:AddToBlizOptions(aceAppName .. "_About", LPS.addon.title)

	registerRootAndSubCategories()
end -- do (блок Ace3)

--- Повторная регистрация в AceConfig после готовности БД (вызывает core.lua).
function LPS.Options:FinalizeAce()
	if not hasAce() then return end
	registerRootAndSubCategories()
end

--- Вкладка профилей из AceDBOptions: добавляет пункт в общее дерево
--- (его видит и нативное UI) и регистрирует отдельную Ace-страницу.
function LPS.Options:EnsureAceProfilesTab()
	if self._profilesTabEnsured then return end
	if not (LibStub and LibStub.GetLibrary) then return end
	if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
	local AceDBOptions = LibStub("AceDBOptions-3.0")
	local p = AceDBOptions:GetOptionsTable(LPS.db)
	if type(p) ~= "table" then return end
	p.order = 90
	p.name = LPS:L("Profiles")
	self.tree.args.profiles = p
	self._profilesTabEnsured = true
	if AceConfigRegistry and AceConfigRegistry.NotifyChange then
		AceConfigRegistry:NotifyChange(self.aceAppName)
	end
end

function LPS.Options:RegisterAceProfiles()
	if self._profilesRegistered then return end
	if not (AceConfig and LibStub and LibStub.GetLibrary) then return end
	if not (LibStub:GetLibrary("AceDBOptions-3.0", true) and LPS.db) then return end
	local AceDBOptions = LibStub("AceDBOptions-3.0")
	AceConfig:RegisterOptionsTable(self.aceAppName .. "_Profiles", AceDBOptions:GetOptionsTable(LPS.db))
	if AceDialog and not self._profilesBlizAdded then
		AceDialog:AddToBlizOptions(self.aceAppName .. "_Profiles", LPS:L("Profiles"), LPS.addon.title)
		self._profilesBlizAdded = true
	end
	self._profilesRegistered = true
end
