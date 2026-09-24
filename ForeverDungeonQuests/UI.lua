-- Forever Dungeon Quests: report window

local STATUS_COLOR = {
  completed = "|cff808080", -- gray
  active = "|cff33ff33",    -- green
  missing = "|cffff4444",   -- red
}

local STATUS_LABEL = {
  completed = "Done",
  active = "In Log",
  missing = "Missing",
}

local frame
local listFrame

local function CreateFrame_FDQ()
  local f = CreateFrame("Frame", "FDQ_ReportFrame", UIParent, "BackdropTemplate")
  f:SetSize(520, 480)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -16)

  f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -4)

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", -4, -4)

  f.backButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.backButton:SetSize(90, 22)
  f.backButton:SetPoint("TOPLEFT", 14, -14)
  f.backButton:SetText("< Dungeons")
  f.backButton:SetScript("OnClick", function()
    f:Hide()
    FDQ:ShowDungeonList()
  end)

  f.scroll = CreateFrame("ScrollFrame", "FDQ_ReportScroll", f, "UIPanelScrollFrameTemplate")
  f.scroll:SetPoint("TOPLEFT", 16, -70)
  f.scroll:SetPoint("BOTTOMRIGHT", -34, 16)

  f.content = CreateFrame("Frame", nil, f.scroll)
  f.content:SetSize(1, 1)
  f.scroll:SetScrollChild(f.content)

  f.lines = {}

  f:Hide()
  return f
end

local function CreateListFrame_FDQ()
  local f = CreateFrame("Frame", "FDQ_ListFrame", UIParent, "BackdropTemplate")
  f:SetSize(320, 480)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", 0, -16)
  f.title:SetText("Choose a Dungeon")

  f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -4)
  f.subtitle:SetText("Check quests before you queue or travel.")

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", -4, -4)

  f.scroll = CreateFrame("ScrollFrame", "FDQ_ListScroll", f, "UIPanelScrollFrameTemplate")
  f.scroll:SetPoint("TOPLEFT", 16, -60)
  f.scroll:SetPoint("BOTTOMRIGHT", -34, 16)

  f.content = CreateFrame("Frame", nil, f.scroll)
  f.content:SetSize(1, 1)
  f.scroll:SetScrollChild(f.content)

  f.buttons = {}

  f:Hide()
  return f
end

local function GetLine(f, index)
  local line = f.lines[index]
  if not line then
    line = f.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", 4, -((index - 1) * 16) - 4)
    line:SetPoint("RIGHT", f.content, "RIGHT", -4, 0)
    line:SetJustifyH("LEFT")
    line:SetWordWrap(false)
    f.lines[index] = line
  end
  line:Show()
  return line
end

-- The dungeon picker: the normal entry point via `/fdq` with no arguments.
-- Meant to be checked before queueing/traveling, not just while inside.
function FDQ:ShowDungeonList()
  if not listFrame then
    listFrame = CreateListFrame_FDQ()
  end

  if frame then
    frame:Hide()
  end

  local sorted = {}
  for _, dungeon in ipairs(FDQ_Dungeons) do
    table.insert(sorted, dungeon)
  end
  table.sort(sorted, function(a, b)
    local levelA = (a.levels and a.levels.atLevel) or 0
    local levelB = (b.levels and b.levels.atLevel) or 0
    if levelA ~= levelB then
      return levelA < levelB
    end
    return a.name < b.name
  end)

  for _, button in pairs(listFrame.buttons) do
    button:Hide()
  end

  for i, dungeon in ipairs(sorted) do
    local button = listFrame.buttons[i]
    if not button then
      button = CreateFrame("Button", nil, listFrame.content, "UIPanelButtonTemplate")
      button:SetSize(270, 24)
      button:SetPoint("TOPLEFT", 2, -((i - 1) * 28) - 2)
      listFrame.buttons[i] = button
    end

    local atLevel = dungeon.levels and dungeon.levels.atLevel
    local label = dungeon.name
    if atLevel then
      label = label .. "  |cffaaaaaa(lvl " .. atLevel .. ")|r"
    end
    button:SetText(label)
    button:SetScript("OnClick", function()
      listFrame:Hide()
      FDQ:OpenDungeonReport(dungeon)
    end)
    button:Show()
  end

  listFrame.content:SetHeight(math.max(1, #sorted * 28))
  listFrame:Show()
end

function FDQ:ShowReport(dungeon, rows)
  if not frame then
    frame = CreateFrame_FDQ()
  end

  if listFrame then
    listFrame:Hide()
  end

  frame.title:SetText(dungeon.name)

  local faction = FDQ:GetPlayerFaction()
  local levels = dungeon.levels or {}
  local levelText = string.format(
    "Hard: %s  Medium: %s  At Level: %s  Easy: %s",
    levels.hard or "-", levels.medium or "-", levels.atLevel or "-", levels.easy or "-"
  )
  frame.subtitle:SetText(levelText .. "   |   Faction: " .. faction)

  -- sort missing quests first, then active, then completed
  local order = { missing = 1, active = 2, completed = 3 }
  table.sort(rows, function(a, b)
    if order[a.status] ~= order[b.status] then
      return order[a.status] < order[b.status]
    end
    return a.quest.name < b.quest.name
  end)

  for _, line in pairs(frame.lines) do
    line:Hide()
  end

  local lineIndex = 1

  if dungeon.keyNote then
    local line = GetLine(frame, lineIndex)
    line:SetText("|cffffcc00Note:|r " .. dungeon.keyNote)
    lineIndex = lineIndex + 1
    lineIndex = lineIndex + 1 -- blank spacer
  end

  for _, row in ipairs(rows) do
    local quest = row.quest
    local color = STATUS_COLOR[row.status]
    local label = STATUS_LABEL[row.status]

    local line = GetLine(frame, lineIndex)
    local text = string.format("%s[%s]|r  %s |cffaaaaaa(lvl %d)|r", color, label, quest.name, quest.level or 0)
    line:SetText(text)
    lineIndex = lineIndex + 1

    local detail = GetLine(frame, lineIndex)
    local detailText = "     " .. (quest.giver or "?")
    if quest.location then
      detailText = detailText .. " - " .. quest.location
    end
    if quest.coords then
      detailText = detailText .. " /way " .. quest.coords
    end
    detail:SetText("|cff888888" .. detailText .. "|r")
    lineIndex = lineIndex + 1

    if quest.notes then
      local noteLine = GetLine(frame, lineIndex)
      noteLine:SetText("|cff666666     " .. quest.notes .. "|r")
      lineIndex = lineIndex + 1
    end

    lineIndex = lineIndex + 1 -- spacer between quests
  end

  frame.content:SetHeight(math.max(1, (lineIndex - 1) * 16))
  frame:Show()
end
