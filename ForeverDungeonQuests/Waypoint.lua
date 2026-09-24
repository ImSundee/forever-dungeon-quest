-- Forever Dungeon Quests: arrow/waypoint integration
--
-- Turns a quest's `coords` field (from Data.lua) into an on-screen arrow
-- pointing at the quest giver. Two providers, tried in order:
--   1. TomTom, if installed -- most players already have it, and its arrow
--      comes with distance/crazy-arrow extras this addon doesn't try to
--      reimplement.
--   2. The client's own built-in waypoint API (C_Map.SetUserWaypoint +
--      C_SuperTrack.SetSuperTrackedUserWaypoint). This was added to Retail
--      in Battle for Azeroth/Shadowlands and, since Forever runs on the
--      modern Retail client (Interface 16001, see CLAUDE.md), it should be
--      present regardless of what other addons the player has -- so there's
--      always a working fallback with zero third-party dependency.
--
-- **Unverified**: everything in this file is written against the documented
-- TomTom API and the documented C_Map/C_SuperTrack API, but hasn't been run
-- against a live Forever client (no beta access from this dev environment).
-- First things to confirm in-game: that TomTom:AddWaypoint's (uiMapID, x, y)
-- signature still matches its current release, and that
-- C_SuperTrack.SetSuperTrackedUserWaypoint actually shows the arrow on this
-- client build the way it does on live Retail.

FDQ = FDQ or {}
local FDQ = FDQ

-- Data.lua coords are transcribed straight from Wowhead as "x, y" percentage
-- strings (e.g. "49, 50" or "64.8, 58.4"). Both TomTom and the native
-- waypoint API want 0-1 floats instead, so this is the one place that
-- conversion happens.
local function ParseCoords(coordString)
  if not coordString then return nil end
  local x, y = coordString:match("^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$")
  x, y = tonumber(x), tonumber(y)
  if not x or not y then return nil end
  return x / 100, y / 100
end
FDQ.ParseCoords = ParseCoords

-- Best-effort zone name a quest's `location` string refers to, so the UI
-- can tell whether the player is actually where the quest's coords make
-- sense. `location` is free text like "Orgrimmar, The Drag" or just
-- "Undercity" -- take whatever's before the first comma, since that's
-- consistently the zone/city name across Data.lua.
function FDQ:GetQuestZoneName(quest)
  if not quest.location then return nil end
  local zone = quest.location:match("^([^,]+)")
  return zone and zone:trim()
end

-- Whether the player is currently standing in the zone a quest's coords
-- were recorded in. This addon has no zone-name -> uiMapID lookup table
-- (see SetQuestWaypoint below for why), so a waypoint is only ever set on
-- the player's *current* map -- this is the check the UI uses to decide
-- whether that's actually meaningful right now.
function FDQ:IsPlayerInQuestZone(quest)
  local questZone = FDQ:GetQuestZoneName(quest)
  if not questZone then return false end
  questZone = questZone:lower()

  local here = GetZoneText()
  if here and here:lower() == questZone then return true end

  local sub = GetSubZoneText()
  if sub and sub ~= "" and sub:lower() == questZone then return true end

  return false
end

-- Which arrow provider (if any) is available right now.
function FDQ:GetWaypointProvider()
  if TomTom and TomTom.AddWaypoint then
    return "TomTom"
  end
  if C_Map and C_Map.SetUserWaypoint and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    return "native"
  end
  return nil
end

-- Points an arrow at `quest`'s coords, on the player's CURRENT map.
--
-- Deliberately does NOT try to resolve the quest's own zone to a uiMapID --
-- that would need a full zone-name -> uiMapID table (Forever's Classic-era
-- zones aren't guaranteed to keep Retail's IDs, and re-deriving that table
-- is more risk than this feature is worth). Instead this trusts whatever
-- map the player is standing on, which is exactly right when
-- FDQ:IsPlayerInQuestZone(quest) is true -- the UI only enables the button
-- in that case, so this function assumes the caller already checked.
function FDQ:SetQuestWaypoint(quest)
  local x, y = ParseCoords(quest.coords)
  if not x then
    print("|cff33ff99Forever Dungeon Quests|r: \"" .. quest.name .. "\" has no usable coordinates.")
    return false
  end

  local uiMapID = C_Map.GetBestMapForUnit("player")
  if not uiMapID then
    print("|cff33ff99Forever Dungeon Quests|r: couldn't determine your current map.")
    return false
  end

  local provider = FDQ:GetWaypointProvider()
  if provider == "TomTom" then
    TomTom:AddWaypoint(uiMapID, x, y, {
      title = quest.name,
      persistent = false,
      minimap = true,
      world = true,
    })
    print("|cff33ff99Forever Dungeon Quests|r: TomTom waypoint set for \"" .. quest.name .. "\".")
    return true
  elseif provider == "native" then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(uiMapID, x, y))
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    print("|cff33ff99Forever Dungeon Quests|r: waypoint set for \"" .. quest.name .. "\".")
    return true
  end

  print("|cff33ff99Forever Dungeon Quests|r: no waypoint addon found, and this client build has no built-in waypoint API.")
  return false
end
