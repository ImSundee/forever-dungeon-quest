-- Forever Dungeon Quests: options panel
--
-- Blizzard's Interface Options window, using the modern retail Settings API
-- (Settings.RegisterVerticalLayoutCategory / Settings.CreateDropdown), since
-- WoW: Forever runs on the modern Retail client despite its Classic-era
-- content (see CLAUDE.md "Game context"). Currently the only setting is the
-- dungeon-entry alert mode -- see FDQ:CheckEntryAlert in Core.lua.
--
-- UNVERIFIED: written against the documented Settings API without a live
-- client to confirm the panel actually renders/registers correctly on
-- Forever's Beta build -- see CLAUDE.md.

if not Settings or not Settings.RegisterVerticalLayoutCategory then
  return -- defensive: fall back to no options panel rather than erroring out
end

FDQ.EnsureDB()

local category = Settings.RegisterVerticalLayoutCategory("Forever Dungeon Quests")
Settings.RegisterAddOnCategory(category)

local function GetEntryAlertMode()
  return FDQ_DB.options.entryAlertMode
end

local function SetEntryAlertMode(value)
  FDQ_DB.options.entryAlertMode = value
end

local setting = Settings.RegisterProxySetting(
  category,
  "FDQ_EntryAlertMode",
  Settings.VarType.String,
  "Dungeon entry alert",
  "popup",
  GetEntryAlertMode,
  SetEntryAlertMode
)

local modeOptions = Settings.CreateControlTextContainer()
modeOptions:Add("off", "Off")
modeOptions:Add("popup", "Pop-up alert")
modeOptions:Add("chat", "Chat message")
modeOptions:Add("both", "Both")

Settings.CreateDropdown(
  category,
  setting,
  function() return modeOptions:GetData() end,
  "Alert when you enter a dungeon with quests you're missing (for your faction)."
)
