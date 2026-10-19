if GetLocale() ~= "enUS" then return end
local AceLocale = LibStub and LibStub:GetLibrary("AceLocale-3.0", true)
local L
if AceLocale then
	L = AceLocale:NewLocale("LocationPlus", "enUS", true)
else
	return
end
if not L then return end

L["Currency"] = true
L["Enable/Disable the currencies, on Tooltip."] = true

L["Adds location, coords,\nextra panels and an info-rich tooltip\n(no ElvUI required)"] = true

L["Zone"] = true
L["Home"] = true
L["Continent"] = true
L["Status"] = true
L["Recommended Zones"] = true
L["Recommended Dungeons"] = true
L["Battle Pet level"] = true
L["Cooldown raids"] = true
L["Cooldown dungeons"] = true
L["Daily reset"] = true
L["Weekly reset"] = true
L["Server time"] = true
L["day"] = true
L["hour"] = true
L["minute"] = true
L["Toggle time"] = true
L["Toggle calendar"] = true
L["Toggle WorldMap"] = true
L["Toggle Configuration"] = true
L["Send the coordinates to the chat"] = true
L["loaded. Current version:"] = true
L["in"] = true

L["LMB"] = true
L["RMB"] = true
L["MMB"] = true
L["Shift+LMB"] = true

L["The frame position is reset"] = true

-- Professions
L["Alchemy"]        = true
L["Blacksmithing"]  = true
L["Enchanting"]     = true
L["Engineering"]    = true
L["Herbalism"]      = true
L["Leatherworking"] = true
L["Mining"]         = true
L["Skinning"]       = true
L["Tailoring"]      = true
L["Jewelcrafting"]  = true
L["Cooking"]        = true
L["First Aid"]      = true
L["Fishing"]        = true

L["Location Plus"] = true
L["General"] = true
L["Actions"] = true
L["Reset values"] = true
L["Reset all addon settings to default values."] = true
L["Panel settings have been reset to defaults."] = true
L["None"] = true

L["Import/Export"] = true
L["Export"] = true
L["Import"] = true
L["Generate export string"] = true
L["Generate an export string for the current profile."] = true
L["Export string"] = true
L["Copy this string to export your current profile."] = true
L["Profile name"] = true
L["Name of the profile to import into."] = true
L["Import string"] = true
L["Paste an export string here to import a profile."] = true
L["Import the string into the selected profile name."] = true
L["Show/Hide all panels when in combat"] = true
L["Enable/Disable status on Tooltip."] = true
L["Enable/Disable level range on Tooltip."] = true
L["Show Hints"] = true
L["Area Fishing level"] = true
L["Enable/Disable fishing level on the area."] = true
L["Enable/Disable battle pet level on the area."] = true
L["Recommended Zones"] = true
L["Enable/Disable recommended zones on Tooltip."] = true
L["Max entries"] = true
L["Limit how many entries are shown in this list."] = true
L["Zone Dungeons"] = true
L["Enable/Disable dungeons in the zone, on Tooltip."] = true
L["Enable/Disable recommended dungeons on Tooltip."] = true
L["with Entrance Coords"] = true
L["Enable/Disable the coords for area dungeons and recommended dungeon entrances, on Tooltip."] = true
L["Enable/Disable the professions, on Tooltip."] = true
L["Hide capped"] = true
L["Hides a profession when the player reaches its highest level."] = true
L["Filters"] = true
L["Hide Raid"] = true
L["Show/Hide raids on recommended dungeons."] = true
L["Show/Hide PvP zones, Arenas and BGs on recommended dungeons and zones."] = true
L["Location Panel"] = true
L["Layout"] = true
L["Auto"] = true
L["Manual"] = true
L["Spacing"] = true
L["Panels"] = true
L["Minimum width"] = true
L["Sets the minimum width of the location panel."] = true
L["Sets the minimum width of the extra panels."] = true
L["Adjust horizontal text padding inside location panel."] = true
L["Adjust vertical text padding inside location panel."] = true
L["Text padding X"] = true
L["Adjust horizontal text padding inside panels."] = true
L["Text padding Y"] = true
L["Adjust vertical text padding inside panels."] = true
L["Gold"] = true
L["System"] = true
L["Location"] = true
L["Coords"] = true
L["Time"] = true
L["Crest"] = true
L["Other"] = true
L["Show additional info in the Location Panel"] = true
L["Detailed Coords"] = true
L["Adds 2 digits in the coords"] = true
L["Combat Hide"] = true
L["Login message"] = true
L["Show a message in chat on login."] = true
L["24H time format"] = true
L["Use 24-hour time format."] = true
L["Show seconds"] = true
L["Show seconds when using local time."] = true
L["Update Timer"] = true
L["Adjust coords updates (in seconds) to avoid cpu load."] = true
L["Move frame"] = true
L["Toggle move mode for the frame."] = true
L["Reset holder position"] = true
L["Reset the holder frame position."] = true
L["Colors"] = true

L["Show panels"] = true
L["Show/Hide the extra panels (Coords and Time)."] = true
L["Show zone"] = true
L["Show zone name on the panel."] = true
L["Minimap icon"] = true
L["Show/Hide minimap icon."] = true
L["Addon Compartment"] = true
L["Show/Hide addon in the Addon Compartment."] = true
L["Enable tooltip on the gold panel."] = true
L["Enable tooltip on the system panel."] = true
L["Show session information in the tooltip."] = true
L["Show character gold list in the tooltip."] = true
L["Show faction/server totals in the tooltip."] = true
L["Show Warband money in the tooltip (Retail)."] = true
L["Show WoW Token price in the tooltip (Retail)."] = true
L["Show reset keybind hints at the bottom of the tooltip."] = true
L["Show FPS and network information in the tooltip."] = true
L["Show addon memory usage list in the tooltip."] = true
L["Show total addon memory usage line in the tooltip."] = true

L["Enable"] = true
L["Tooltips"] = true
L["Tooltip"] = true
L["Visibility"] = true
L["Hide in combat"] = true
L["Hide tooltips while in combat."] = true

L["Level range"] = true
L["Battle pets"] = true
L["Professions"] = true
L["Hide PvP"] = true
L["Enable tooltip on the time panel."] = true
L["Show saved raids list."] = true
L["Show saved dungeons list."] = true

L["Style"] = true
L["Enable background"] = true
L["Toggle background on the panel."] = true
L["Font size"] = true
L["Set font size."] = true
L["Border size"] = true
L["Set border thickness."] = true
L["Text color"] = true
L["Custom"] = true
L["Class Colors"] = true
L["Default"] = true
L["Background color"] = true
L["Set background color."] = true
L["Border color"] = true
L["Set border color."] = true
L["Frame strata"] = true
L["Controls how high the LocationPlus panels are drawn."] = true
L["Frame level"] = true
L["Fine-tune draw order within the selected strata."] = true
L["Automatically manage spacing between panels."] = true
L["Set spacing between panels."] = true
L["Profiles"] = true

L["Session"] = true
L["Earned"] = true
L["Spent"] = true
L["Profit"] = true
L["Loss"] = true
L["Characters"] = true
L["On server"] = true
L["Alliance"] = true
L["Horde"] = true
L["Warband"] = true
L["WoW Token"] = true
L["Reset session data"] = true
L["Ctrl+RMB"] = true
L["Reset character data"] = true
L["Shift+RMB"] = true

L["Local latency"] = true
L["Global latency"] = true
L["Bandwidth"] = true
L["AddOns"] = true
L["Total"] = true
L["Currency"] = true
L["Text custom color"] = true
L["Pick a custom color for panel text."] = true

L["Broker Time settings"] = true
L["Played Time"] = true
L["Show played time across all your characters (Required 'Broker: Played Time')"] = true

-- Info panels (DataTexts)
L["AFK"] = true
L["Bags"] = true
L["Combat Indicator"] = true
L["Current Difficulties:"] = true
L["DND"] = true
L["Difficulty"] = true
L["Dungeon"] = true
L["Durability"] = true
L["Experience"] = true
L["Free slots"] = true
L["Friends"] = true
L["Friends List"] = true
L["Game Menu"] = true
L["Guild"] = true
L["In Combat"] = true
L["Item Level"] = true
L["Left Offset X 1"] = true
L["Left Offset X 2"] = true
L["Left Offset X 3"] = true
L["Left Offset Y 1"] = true
L["Left Offset Y 2"] = true
L["Left Offset Y 3"] = true
L["Left Slot 1"] = true
L["Left Slot 2"] = true
L["Left Slot 3"] = true
L["Level"] = true
L["Mail"] = true
L["Max Level"] = true
L["Micro Bar"] = true
L["Mute"] = true
L["New Mail"] = true
L["No Guild"] = true
L["No Mail"] = true
L["No friends online"] = true
L["No mail"] = true
L["No members online"] = true
L["Out of Combat"] = true
L["Percent"] = true
L["Raid"] = true
L["Remaining:"] = true
L["Rested:"] = true
L["Right Offset X 1"] = true
L["Right Offset X 2"] = true
L["Right Offset X 3"] = true
L["Right Offset Y 1"] = true
L["Right Offset Y 2"] = true
L["Right Offset Y 3"] = true
L["Right Slot 1"] = true
L["Right Slot 2"] = true
L["Right Slot 3"] = true
L["Select Volume Stream"] = true
L["Show tooltip"] = true
L["Side Panels"] = true
L["Toggle Volume Stream"] = true
L["Used / Total"] = true
L["Used slots"] = true
L["Volume"] = true
L["Volume Streams"] = true
L["XP:"] = true
L["Mobile"] = true

-- Frame anchor mode (Layout -> Show tab)
L["Frame anchor mode"] = true
L["Side panels always grow along their edge: left panels attach to the LEFT side of the group, right panels attach to the RIGHT side. This option controls what the FIRST panel of each chain anchors to: the location panel edges (default) or the outer edges of the whole holder frame."] = true
L["Location panel edges"] = true
L["Holder outer edges"] = true

-- Panel options (enable/tooltip/display/label)
L["Show a tooltip when hovering over this panel."] = true
L["Display"] = true
L["Hide label"] = true
L["Custom label"] = true
L["Value format"] = true
L["Choose how the value is shown on the panel."] = true
L["Show tooltips when hovering over panels."] = true
L["Choose how panel text is colored. The location panel always keeps its own zone-status color."] = true
L["Show an icon next to the additional info."] = true
L["Select a panel for this slot."] = true
L["Max entries in tooltip"] = true
L["Current"] = true
L["Current / Max"] = true
L["Remaining"] = true

-- Tooltip lines

-- Panel click tooltips (Modules/Tooltips)
L["Open"] = true
L["Toggle all bags"] = true
L["Open character panel"] = true
L["Open friends list"] = true
L["Open guild frame"] = true
