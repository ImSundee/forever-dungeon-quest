-- Forever Dungeon Quests: core logic
-- Matches quests by TITLE rather than quest ID, because:
--   1. Wowhead's guide text doesn't expose quest IDs.
--   2. WoW: Forever is in Beta -- IDs may still change.
--   3. C_QuestLog.GetAllCompletedQuestIDs() + GetTitleForQuestID() lets us build a
--      title->completed index at runtime, so we never need to hardcode IDs.

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

function FDQ:GetPlayerFaction()
  local faction = UnitFactionGroup("player")
  return faction or "Neutral"
end

-- status: "completed" | "active" | "dungeon-drop" | "missing"
-- "dungeon-drop" quests start from an item drop inside the dungeon itself
-- (quest.dungeonDrop in Data.lua) -- the player can't go "pick them up" ahead
-- of time like a normal quest giver, so showing them as "Missing" is
-- misleading. They're picked up naturally while running the dungeon.
function FDQ:GetQuestStatus(quest, activeTitles)
  if activeTitles[quest.name] then
    return "active"
  end
  if FDQ_DB.completedTitles[quest.name] then
    return "completed"
  end
  if quest.dungeonDrop then
    return "dungeon-drop"
  end
  return "missing"
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

  local rows = {}
  for _, quest in ipairs(dungeon.quests) do
    if quest.faction == "Neutral" or quest.faction == faction then
      table.insert(rows, {
        quest = quest,
        status = FDQ:GetQuestStatus(quest, activeTitles),
      })
    end
  end
  return rows
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
