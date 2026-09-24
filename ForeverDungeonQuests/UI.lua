-- Forever Dungeon Quests: report + picker windows
--
-- Visual integration with EllesmereUI (a third-party UI-replacement addon,
-- github.com/EllesmereGaming/EllesmereUI): if the user has it installed and
-- has skinning enabled for this addon, EllesmereUI.RegisterSkin below hands
-- our frames to its Skins module (`S`) so borders, buttons, scrollbars, and
-- fonts match the user's own theme/font choice instead of stock Blizzard art.
-- Without EllesmereUI installed, frames fall back to a plain flat panel
-- rather than the ornate gold-trimmed dialog box template.
--
-- NOTE: written against EllesmereUI's documented SKINNING_API.md (apiVersion
-- 1). Not yet verified against a live client with EllesmereUI actually
-- installed -- see CLAUDE.md.

local ADDON_NAME = "Forever Dungeon Quests"

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
local skin -- set by EllesmereUI.RegisterSkin's callback, nil if EUI isn't present/enabled

-- Level-bracket filter for the dungeon picker grid, so it only shows a
-- handful of dungeons at a time instead of the full list.
local BRACKET_SIZE = 10
local selectedBracketMin -- nil until first ShowDungeonList call, then sticky for the session

local function GetDungeonBracket(dungeon)
  local atLevel = (dungeon.levels and dungeon.levels.atLevel) or 1
  return math.floor((atLevel - 1) / BRACKET_SIZE) * BRACKET_SIZE + 1
end

local function GetAvailableBrackets()
  local seen, brackets = {}, {}
  for _, dungeon in ipairs(FDQ_Dungeons) do
    local bracket = GetDungeonBracket(dungeon)
    if not seen[bracket] then
      seen[bracket] = true
      table.insert(brackets, bracket)
    end
  end
  table.sort(brackets)
  return brackets
end

local function GetNearestBracket(target, brackets)
  local best, bestDiff
  for _, bracket in ipairs(brackets) do
    local diff = math.abs(bracket - target)
    if not bestDiff or diff < bestDiff then
      best, bestDiff = bracket, diff
    end
  end
  return best
end

local function GetPlayerBracket()
  local level = UnitLevel("player") or 1
  return math.floor((level - 1) / BRACKET_SIZE) * BRACKET_SIZE + 1
end

local function BracketLabel(bracketMin)
  return bracketMin .. "-" .. (bracketMin + BRACKET_SIZE - 1)
end

local function LevelDropdown_Initialize(dropdown, level)
  for _, bracketMin in ipairs(GetAvailableBrackets()) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = BracketLabel(bracketMin)
    info.value = bracketMin
    info.checked = (bracketMin == selectedBracketMin)
    info.func = function(self)
      selectedBracketMin = self.value
      FDQ:ShowDungeonList()
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

-- Applies the shared chrome (shell backdrop, close button, brand/title/subtitle
-- fonts) to a window frame. Safe to call whether or not `skin` is set.
local function SkinWindowChrome(f)
  if not skin then return end
  skin.Shell(f)
  skin.CloseButton(f.closeButton)
  skin.Font(f.brand)
  skin.Font(f.title)
  skin.Font(f.subtitle)
  if f.backButton then
    skin.Button(f.backButton)
  end
  if f.scroll and f.scroll.ScrollBar then
    skin.ScrollBar(f.scroll.ScrollBar)
  end
end

local function CreateWindowBase(name, width, height)
  local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  f:SetSize(width, height)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  -- Fallback look for players without EllesmereUI: a plain flat panel
  -- instead of the ornate DialogFrame parchment/gold-trim template.
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
  f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  f.brand = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.brand:SetPoint("TOP", 0, -10)
  f.brand:SetText(ADDON_NAME)
  f.brand:SetTextColor(0.6, 0.6, 0.6)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  f.title:SetPoint("TOP", f.brand, "BOTTOM", 0, -6)
  f.title:SetTextColor(1, 1, 1)

  f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -4)

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", -4, -4)

  f:Hide()
  return f
end

local function CreateFrame_FDQ()
  local f = CreateWindowBase("FDQ_ReportFrame", 520, 480)

  f.backButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.backButton:SetSize(90, 22)
  f.backButton:SetPoint("TOPLEFT", 14, -14)
  f.backButton:SetText("< Dungeons")
  f.backButton:SetScript("OnClick", function()
    f:Hide()
    FDQ:ShowDungeonList()
  end)

  f.scroll = CreateFrame("ScrollFrame", "FDQ_ReportScroll", f, "UIPanelScrollFrameTemplate")
  f.scroll:SetPoint("TOPLEFT", 16, -90)
  f.scroll:SetPoint("BOTTOMRIGHT", -34, 16)

  f.content = CreateFrame("Frame", nil, f.scroll)
  f.content:SetSize(1, 1)
  f.scroll:SetScrollChild(f.content)
  f.scroll:SetScript("OnSizeChanged", function(scroll, width)
    f.content:SetWidth(width)
  end)

  f.lines = {}

  SkinWindowChrome(f)
  return f
end

local function CreateListFrame_FDQ()
  local f = CreateWindowBase("FDQ_ListFrame", 480, 460)

  f.title:SetText("Choose a Dungeon")
  f.subtitle:SetText("Check quests before you queue or travel.")

  f.levelDropdown = CreateFrame("Frame", "FDQ_LevelDropdown", f, "UIDropDownMenuTemplate")
  f.levelDropdown:SetPoint("TOP", f.subtitle, "BOTTOM", -16, -2)
  UIDropDownMenu_SetWidth(f.levelDropdown, 110)
  UIDropDownMenu_Initialize(f.levelDropdown, LevelDropdown_Initialize)

  f.scroll = CreateFrame("ScrollFrame", "FDQ_ListScroll", f, "UIPanelScrollFrameTemplate")
  f.scroll:SetPoint("TOPLEFT", 16, -140)
  f.scroll:SetPoint("BOTTOMRIGHT", -34, 16)

  f.content = CreateFrame("Frame", nil, f.scroll)
  f.content:SetSize(1, 1)
  f.scroll:SetScrollChild(f.content)

  f.buttons = {}

  SkinWindowChrome(f)
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
  if skin then
    skin.Font(line)
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

  local brackets = GetAvailableBrackets()
  if not selectedBracketMin then
    selectedBracketMin = GetNearestBracket(GetPlayerBracket(), brackets)
  end

  UIDropDownMenu_Initialize(listFrame.levelDropdown, LevelDropdown_Initialize)
  UIDropDownMenu_SetSelectedValue(listFrame.levelDropdown, selectedBracketMin)
  UIDropDownMenu_SetText(listFrame.levelDropdown, "Level " .. BracketLabel(selectedBracketMin))

  local filtered = {}
  for _, dungeon in ipairs(FDQ_Dungeons) do
    if GetDungeonBracket(dungeon) == selectedBracketMin then
      table.insert(filtered, dungeon)
    end
  end
  table.sort(filtered, function(a, b)
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

  local COLS = 2
  local COL_WIDTH = 205
  local COL_GAP = 20
  local ROW_HEIGHT = 24
  local ROW_GAP = 10

  for i, dungeon in ipairs(filtered) do
    local button = listFrame.buttons[i]
    if not button then
      button = CreateFrame("Button", nil, listFrame.content, "UIPanelButtonTemplate")
      button:SetSize(COL_WIDTH, ROW_HEIGHT)
      listFrame.buttons[i] = button
      if skin then
        skin.Button(button)
      end
    end

    local col = (i - 1) % COLS
    local row = math.floor((i - 1) / COLS)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", col * (COL_WIDTH + COL_GAP), -(row * (ROW_HEIGHT + ROW_GAP)))

    local atLevel = dungeon.levels and dungeon.levels.atLevel
    local label = dungeon.name
    if atLevel then
      label = label .. "  |cffaaaaaa(" .. atLevel .. ")|r"
    end
    button:SetText(label)
    button:SetScript("OnClick", function()
      listFrame:Hide()
      FDQ:OpenDungeonReport(dungeon)
    end)
    button:Show()
  end

  if not listFrame.emptyText then
    listFrame.emptyText = listFrame.content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    listFrame.emptyText:SetPoint("TOPLEFT", 2, -2)
    listFrame.emptyText:SetText("No dungeons in this level range.")
  end
  listFrame.emptyText:SetShown(#filtered == 0)

  local rowCount = math.ceil(#filtered / COLS)
  listFrame.content:SetHeight(math.max(1, rowCount * (ROW_HEIGHT + ROW_GAP)))
  listFrame:Show()
end

-- Used by the minimap button: hide whichever window is open, or open the
-- dungeon picker if neither is.
function FDQ:ToggleUI()
  if (frame and frame:IsShown()) or (listFrame and listFrame:IsShown()) then
    if frame then frame:Hide() end
    if listFrame then listFrame:Hide() end
  else
    FDQ:ShowDungeonList()
  end
end

function FDQ:ShowReport(dungeon, rows)
  if not frame then
    frame = CreateFrame_FDQ()
  end

  if listFrame then
    listFrame:Hide()
  end

  frame.content:SetWidth(frame.scroll:GetWidth())

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

if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin("ForeverDungeonQuests", function(S)
    skin = S
    -- Re-skin whatever's already been created (e.g. if the player opened
    -- the UI once before EUI finished registering skins at PLAYER_LOGIN).
    if frame then
      SkinWindowChrome(frame)
      for _, line in pairs(frame.lines) do
        skin.Font(line)
      end
    end
    if listFrame then
      SkinWindowChrome(listFrame)
      for _, button in pairs(listFrame.buttons) do
        skin.Button(button)
      end
    end
  end)
end
