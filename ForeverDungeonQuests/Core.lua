-- Forever Dungeon Quests: core logic
-- Matches quests by TITLE by default, because:
--   1. Wowhead's guide text doesn't expose quest IDs.
--   2. WoW: Forever is in Beta -- IDs may still change.
--   3. C_QuestLog.GetAllCompletedQuestIDs() + GetTitleForQuestID() lets us build a
--      title->completed index at runtime, so we never need to hardcode IDs.
--
-- ID-based matching (see issue #15): a small number of prerequisite chains
-- reuse the exact same title for multiple distinct quests (e.g. Ragefire
-- Chasm's "Hidden Enemies" x5). Title matching can't tell those steps apart
-- -- completing the first occurrence would make every same-titled step
-- report "completed". For those specific cases, a quest entry (in
-- Data.lua) or a prereqs entry can carry an explicit `id = <questID>` (main
-- quest entries) / `{ name = "...", id = <questID> }` (prereqs entries)
-- instead of relying on the title. When `id` is present, status is looked
-- up by ID only (activeIDs/completedIDs below) and the title index is not
-- consulted at all for that entry, so a duplicate title elsewhere can't
-- produce a false "completed".
--
-- Getting the real IDs: Wowhead is unreachable from this dev environment
-- (network egress blocks it, and WebSearch alone can't reliably disambiguate
-- 5 quests sharing one title), so IDs for the chains in issue #15 couldn't
-- be filled in from here. `/fdq idscan <text>` (below) is a stopgap so
-- whoever has live Beta access can find the right ID for a quest that's
-- currently active or already completed on their character and paste it
-- into Data.lua.

FDQ = {}
local FDQ = FDQ

FDQ_DB = FDQ_DB or {}

local function EnsureDB()
  FDQ_DB.completedTitles = FDQ_DB.completedTitles or {}
  FDQ_DB.completedCount = FDQ_DB.completedCount or 0
  FDQ_DB.options = FDQ_DB.options or {}
  -- "off" | "popup" | "chat" | "both" -- see the Options panel (Options.lua)
  -- and FDQ:CheckEntryAlert below.
  FDQ_DB.options.entryAlertMode = FDQ_DB.options.entryAlertMode or "popup"
end
FDQ.EnsureDB = EnsureDB

-- Rebuilds the completed-quest title index. Only rescans if the number of
-- completed quest IDs has changed since last scan, since this can be a
-- fairly large list.
function FDQ:RefreshCompletedIndex(force)
  EnsureDB()
  local ids = C_QuestLog.GetAllCompletedQuestIDs()
  if not ids then return end

  if not force and #ids == FDQ_DB.completedCount then
    return -- nothing new since last scan
  end

  wipe(FDQ_DB.completedTitles)
  for _, questID in ipairs(ids) do
    local title = C_QuestLog.GetTitleForQuestID(questID)
    if title then
      FDQ_DB.completedTitles[title] = true
    end
  end
  FDQ_DB.completedCount = #ids
end

-- Set of quest titles currently in the player's quest log.
function FDQ:GetActiveQuestTitles()
  local active = {}
  local numEntries = C_QuestLog.GetNumQuestLogEntries()
  for i = 1, numEntries do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and info.title then
      active[info.title] = true
    end
  end
  return active
end

-- Set of quest IDs currently in the player's quest log. Cheap to build fresh
-- every call (unlike the title index, there's no per-ID lookup cost here).
function FDQ:GetActiveQuestIDs()
  local active = {}
  local numEntries = C_QuestLog.GetNumQuestLogEntries()
  for i = 1, numEntries do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and info.questID and info.questID ~= 0 then
      active[info.questID] = true
    end
  end
  return active
end

-- Set of completed quest IDs. Also cheap to build fresh -- GetAllCompletedQuestIDs()
-- already returns the raw IDs, it's only the title index (RefreshCompletedIndex)
-- that needs the resolve-and-cache treatment.
function FDQ:GetCompletedQuestIDs()
  local completed = {}
  local ids = C_QuestLog.GetAllCompletedQuestIDs()
  if ids then
    for _, id in ipairs(ids) do
      completed[id] = true
    end
  end
  return completed
end

-- A prereqs entry (Data.lua) is either a plain string (legacy, title-matched)
-- or { name = "...", id = <questID> } for a step that needs ID matching to
-- disambiguate a duplicate title (see the ID-based matching note above).
-- Returns name, id (id may be nil).
function FDQ:NormalizePrereqEntry(entry)
  if type(entry) == "table" then
    return entry.name, entry.id
  end
  return entry, nil
end

function FDQ:GetPlayerFaction()
  local faction = UnitFactionGroup("player")
  return faction or "Neutral"
end

-- status: "completed" | "active" | "dungeon-drop" | "unavailable" | "missing"
-- "dungeon-drop" quests start from an item drop inside the dungeon itself
-- (quest.dungeonDrop in Data.lua) -- the player can't go "pick them up" ahead
-- of time like a normal quest giver, so showing them as "Missing" is
-- misleading. They're picked up naturally while running the dungeon.
-- "unavailable" is for quests restricted to a class the player isn't
-- playing (quest.classOnly in Data.lua, an uppercase English class token
-- like "WARLOCK" matching UnitClass's 3rd return) -- the player could never
-- have picked these up on this character, so "Missing" is just as
-- misleading as it is for dungeon-drop quests; treated the same as
-- "completed" everywhere else (sort order, counts) since there's nothing
-- to go do about it. Checked after active/completed so a class quest the
-- player already has or finished (e.g. on an older character before a
-- class change, if Forever ever allows those) still reports correctly.
-- activeIDs/completedIDs are only consulted when quest.id is set (see the
-- ID-based matching note above) -- callers that never set quest.id can pass
-- nil for both and nothing changes from the old title-only behavior.
function FDQ:GetQuestStatus(quest, activeTitles, activeIDs, completedIDs)
  if quest.id then
    if activeIDs and activeIDs[quest.id] then
      return "active"
    end
    if completedIDs and completedIDs[quest.id] then
      return "completed"
    end
  else
    if activeTitles[quest.name] then
      return "active"
    end
    if FDQ_DB.completedTitles[quest.name] then
      return "completed"
    end
  end
  if quest.classOnly then
    local _, playerClass = UnitClass("player")
    if playerClass ~= quest.classOnly then
      return "unavailable"
    end
  end
  if quest.dungeonDrop then
    return "dungeon-drop"
  end
  return "missing"
end

-- Status of a quest.prereqs entry (Data.lua): matched the same way as any
-- other quest, by title (or by id when the entry sets one -- see the
-- ID-based matching note above), against the same active/completed indexes
-- -- the prereq doesn't need its own entry in Data.lua for this to work. No
-- "dungeon-drop" case here since a prerequisite is always something picked
-- up beforehand, not inside the dungeon that's asking for it.
function FDQ:GetPrereqStatus(prereqEntry, activeTitles, activeIDs, completedIDs)
  local name, id = FDQ:NormalizePrereqEntry(prereqEntry)
  if id then
    if activeIDs and activeIDs[id] then
      return "active"
    end
    if completedIDs and completedIDs[id] then
      return "completed"
    end
    return "missing"
  end
  if activeTitles[name] then
    return "active"
  end
  if FDQ_DB.completedTitles[name] then
    return "completed"
  end
  return "missing"
end

-- Returns { {name=, status=, giver=, location=, coords=}, ... } for
-- quest.prereqs, or nil if the quest has none. giver/location/coords come
-- from FDQ_PrereqInfo (Data.lua), a separate name-keyed lookup rather than
-- fields on the prereqs entry itself -- that way enriching a prereq with
-- "where do I get this" data doesn't require touching every quest's
-- prereqs = { "..." } array syntax, and the same info is shared across every
-- quest that lists the same prereq name (several chains reuse breadcrumbs
-- like "Badlands Reagent Run"). A name missing from FDQ_PrereqInfo just
-- means no location data was found for it yet -- the prereq line still
-- renders, just without the extra detail.
function FDQ:GetPrereqStatuses(quest, activeTitles, activeIDs, completedIDs)
  if not quest.prereqs then return nil end
  local statuses = {}
  for _, prereqEntry in ipairs(quest.prereqs) do
    local name = FDQ:NormalizePrereqEntry(prereqEntry)
    local info = FDQ_PrereqInfo and FDQ_PrereqInfo[name]
    table.insert(statuses, {
      name = name,
      status = FDQ:GetPrereqStatus(prereqEntry, activeTitles, activeIDs, completedIDs),
      giver = info and info.giver,
      location = info and info.location,
      coords = info and info.coords,
    })
  end
  return statuses
end

-- Returns the dungeon table whose aliases best match the given zone/instance name.
function FDQ:FindDungeonByZoneName(zoneName)
  if not zoneName or zoneName == "" then return nil end
  for _, dungeon in ipairs(FDQ_Dungeons) do
    for _, alias in ipairs(dungeon.aliases) do
      if alias == zoneName then
        return dungeon
      end
    end
  end
  return nil
end

-- Fuzzy search by partial dungeon name, for the slash command.
function FDQ:FindDungeonsByPartialName(query)
  query = query:lower()
  local matches = {}
  for _, dungeon in ipairs(FDQ_Dungeons) do
    if dungeon.name:lower():find(query, 1, true) then
      table.insert(matches, dungeon)
    end
  end
  return matches
end

function FDQ:GetCurrentInstanceDungeon()
  local inInstance, instanceType = IsInInstance()
  if inInstance and instanceType == "party" then
    local name = GetInstanceInfo()
    return FDQ:FindDungeonByZoneName(name)
  end
  return nil
end

-- Builds the report: for a given dungeon, the quests relevant to the player's
-- faction (their own faction + Neutral), each with a status.
function FDQ:BuildReport(dungeon)
  FDQ:RefreshCompletedIndex()
  local faction = FDQ:GetPlayerFaction()
  local activeTitles = FDQ:GetActiveQuestTitles()
  local activeIDs = FDQ:GetActiveQuestIDs()
  local completedIDs = FDQ:GetCompletedQuestIDs()

  local rows = {}
  for _, quest in ipairs(dungeon.quests) do
    if quest.faction == "Neutral" or quest.faction == faction then
      table.insert(rows, {
        quest = quest,
        status = FDQ:GetQuestStatus(quest, activeTitles, activeIDs, completedIDs),
        prereqStatuses = FDQ:GetPrereqStatuses(quest, activeTitles, activeIDs, completedIDs),
      })
    end
  end
  return rows
end

-- Whether every quest FDQ:BuildReport would show for this dungeon (for the
-- player's own faction) is already done -- "completed" or "unavailable"
-- (a class restriction the player could never have satisfied on this
-- character, so it's as done as it'll ever get, same reasoning as its
-- status color/grouping elsewhere -- see "Class-restricted quest status" in
-- CLAUDE.md). "active" (still in the quest log) and "dungeon-drop"/
-- "missing" (still something to go do) both count as not-yet-complete --
-- an unclaimed dungeon-drop still means a reason to visit the dungeon
-- beyond just XP, which is exactly the distinction the sidebar badge this
-- powers is meant to draw for the player.
function FDQ:IsDungeonComplete(dungeon)
  local rows = FDQ:BuildReport(dungeon)
  for _, row in ipairs(rows) do
    if row.status ~= "completed" and row.status ~= "unavailable" then
      return false
    end
  end
  return true
end

-- Debug helper for issue #15: a handful of prereq chains reuse the same
-- title for multiple quests, which title-matching can't tell apart (see the
-- ID-based matching note at the top of this file). Wowhead is unreachable
-- from the addon's dev environment, so this addon can't look those IDs up
-- itself -- this scans the player's own active + completed quests for a
-- title match and prints each candidate's real questID, to paste into
-- Data.lua as `id = <questID>` (main quest) or `{ name = "...", id = <questID> }`
-- (a prereqs entry).
function FDQ:PrintIDScan(query)
  query = query:lower()
  local prefix = "|cff33ff99Forever Dungeon Quests|r"
  local found = false

  local numEntries = C_QuestLog.GetNumQuestLogEntries()
  for i = 1, numEntries do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and info.title and info.questID
        and info.title:lower():find(query, 1, true) then
      print(string.format("%s: [active] %s -- id %d", prefix, info.title, info.questID))
      found = true
    end
  end

  local ids = C_QuestLog.GetAllCompletedQuestIDs()
  if ids then
    for _, id in ipairs(ids) do
      local title = C_QuestLog.GetTitleForQuestID(id)
      if title and title:lower():find(query, 1, true) then
        print(string.format("%s: [completed] %s -- id %d", prefix, title, id))
        found = true
      end
    end
  end

  if not found then
    print(prefix .. ": no active or completed quest titles match \"" .. query .. "\".")
  end
end

-- Slash command: /fdq [dungeon name]
-- No argument: opens the single-window UI -- this is meant to be checked
-- *before* you queue/travel, not just while standing inside one. Keeps
-- whatever dungeon was last selected, if any.
-- With argument: fuzzy-matches dungeon name and selects it directly.
SLASH_FDQ1 = "/fdq"
SlashCmdList["FDQ"] = function(msg)
  msg = msg and msg:trim() or ""

  if msg == "scan" then
    FDQ:RefreshCompletedIndex(true)
    print("|cff33ff99Forever Dungeon Quests|r: completed-quest index rebuilt (" .. FDQ_DB.completedCount .. " quests).")
    return
  end

  local idscanQuery = msg:match("^idscan%s+(.+)$")
  if idscanQuery then
    FDQ:PrintIDScan(idscanQuery)
    return
  end

  if msg == "" then
    FDQ:ShowMain()
    return
  end

  local matches = FDQ:FindDungeonsByPartialName(msg)
  if #matches == 0 then
    print("|cff33ff99Forever Dungeon Quests|r: no dungeon matches \"" .. msg .. "\".")
    return
  elseif #matches > 1 then
    print("|cff33ff99Forever Dungeon Quests|r: multiple matches, be more specific:")
    for _, d in ipairs(matches) do
      print("  - " .. d.name)
    end
    return
  end

  FDQ:ShowMain(matches[1])
end

-- Entry alert: on entering a dungeon, if the player is missing any quests
-- for it (their faction only), let them know via a chat line and/or a small
-- toast (FDQ:ShowEntryAlert, in UI.lua) -- not the full window, which stays
-- opt-in via /fdq. Mode is player-configurable via the Options panel
-- (Options.lua) -> FDQ_DB.options.entryAlertMode: "off" | "popup" | "chat" |
-- "both".
--
-- `lastAlertInstanceID` guards against re-alerting every time
-- PLAYER_ENTERING_WORLD fires inside the *same* instance visit (e.g. a
-- graveyard release, or a loading screen between instance floors) -- it's
-- reset once the player leaves the instance, so re-entering the same
-- dungeon later in the session alerts again.
local lastAlertInstanceID

function FDQ:CheckEntryAlert()
  EnsureDB()

  local inInstance, instanceType = IsInInstance()
  if not inInstance or instanceType ~= "party" then
    lastAlertInstanceID = nil
    return
  end

  local mode = FDQ_DB.options.entryAlertMode
  if mode == "off" then return end

  local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
  if instanceID and instanceID == lastAlertInstanceID then
    return -- already alerted for this instance visit
  end
  lastAlertInstanceID = instanceID

  local dungeon = FDQ:FindDungeonByZoneName(name)
  if not dungeon then return end

  local rows = FDQ:BuildReport(dungeon)
  local missingCount = 0
  for _, row in ipairs(rows) do
    if row.status == "missing" then
      missingCount = missingCount + 1
    end
  end
  if missingCount == 0 then return end

  if mode == "chat" or mode == "both" then
    print(string.format(
      "|cff33ff99Forever Dungeon Quests|r: %d missing quest%s in %s. Type |cffffcc00/fdq %s|r to view.",
      missingCount, missingCount == 1 and "" or "s", dungeon.name, dungeon.name
    ))
  end
  if mode == "popup" or mode == "both" then
    FDQ:ShowEntryAlert(dungeon, missingCount)
  end
end

local entryAlertFrame = CreateFrame("Frame")
entryAlertFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
entryAlertFrame:SetScript("OnEvent", function()
  FDQ:CheckEntryAlert()
end)
