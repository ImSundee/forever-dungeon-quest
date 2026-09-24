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
end

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

-- status: "completed" | "active" | "missing"
function FDQ:GetQuestStatus(questName, activeTitles)
  if activeTitles[questName] then
    return "active"
  end
  if FDQ_DB.completedTitles[questName] then
    return "completed"
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
        status = FDQ:GetQuestStatus(quest.name, activeTitles),
      })
    end
  end
  return rows
end

-- Slash command: /fdq [dungeon name]
-- No argument: report for the dungeon you're currently inside.
-- With argument: fuzzy-matches dungeon name.
SLASH_FDQ1 = "/fdq"
SlashCmdList["FDQ"] = function(msg)
  msg = msg and msg:trim() or ""

  if msg == "scan" then
    FDQ:RefreshCompletedIndex(true)
    print("|cff33ff99Forever Dungeon Quests|r: completed-quest index rebuilt (" .. FDQ_DB.completedCount .. " quests).")
    return
  end

  local dungeon
  if msg == "" then
    dungeon = FDQ:GetCurrentInstanceDungeon()
    if not dungeon then
      print("|cff33ff99Forever Dungeon Quests|r: not inside a dungeon. Use /fdq <dungeon name> to look one up.")
      return
    end
  else
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
    dungeon = matches[1]
  end

  local rows = FDQ:BuildReport(dungeon)
  FDQ:ShowReport(dungeon, rows)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_ENTERING_WORLD" then
    local dungeon = FDQ:GetCurrentInstanceDungeon()
    if dungeon then
      local rows = FDQ:BuildReport(dungeon)
      FDQ:ShowReport(dungeon, rows)
    end
  end
end)
