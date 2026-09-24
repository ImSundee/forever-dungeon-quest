-- Forever Dungeon Quests: single-window UI
--
-- One window: a left-hand sidebar listing dungeons (filterable by level
-- bracket) and a right-hand quest table for whichever dungeon is selected.
-- Replaces the earlier two-window (picker + report) design.
--
-- Visual integration with EllesmereUI (a third-party UI-replacement addon,
-- github.com/EllesmereGaming/EllesmereUI): if the user has it installed and
-- has skinning enabled for this addon, EllesmereUI.RegisterSkin below hands
-- our frames to its Skins module (`S`) so borders, buttons, scrollbars, and
-- fonts match the user's own theme/font choice instead of stock Blizzard art.
-- Without EllesmereUI installed, frames fall back to a plain flat panel.
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

-- Column layout for the quest table (x-offset, width) within the right
-- panel's content frame.
local COL = {
  status  = { x = 0,   w = 50 },
  name    = { x = 54,  w = 150 },
  level   = { x = 208, w = 30 },
  pickup  = { x = 242, w = 400 },
}
local ROW_HEIGHT = 16
local NOTE_HEIGHT = 14
local ROW_GAP = 6

-- Level-bracket filter for the sidebar dungeon list, so it only shows a
-- handful of dungeons at a time instead of the full list. Wider brackets
-- (20 levels) suit the single-window layout better than the original
-- picker's 10-level brackets did -- there's more room, and fewer dropdown
-- entries to click through.
local BRACKET_SIZE = 20
local selectedBracketMin -- nil until first ShowMain call, then sticky for the session
local selectedDungeon    -- the dungeon currently shown in the right-hand table

local mainFrame
local skin -- set by EllesmereUI.RegisterSkin's callback, nil if EUI isn't present/enabled

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
      FDQ:RefreshSidebar()
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

-- Applies the shared chrome (shell backdrop, close button, brand/title/subtitle
-- fonts) to the window. Safe to call whether or not `skin` is set.
local function SkinWindowChrome(f)
  if not skin then return end
  skin.Shell(f)
  skin.CloseButton(f.closeButton)
  skin.Font(f.brand)
  skin.Font(f.title)
  skin.Font(f.subtitle)
  if f.sidebarScroll and f.sidebarScroll.ScrollBar then
    skin.ScrollBar(f.sidebarScroll.ScrollBar)
  end
  if f.tableScroll and f.tableScroll.ScrollBar then
    skin.ScrollBar(f.tableScroll.ScrollBar)
  end
end

local function CreateMainFrame()
  local f = CreateFrame("Frame", "FDQ_MainFrame", UIParent, "BackdropTemplate")
  f:SetSize(900, 540)
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

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", f.brand, "BOTTOM", 0, -6)
  f.title:SetText("Dungeon Quests")

  f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -4)
  f.subtitle:SetText("Pick a dungeon on the left to check its quests.")

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", -4, -4)

  -- Sidebar: level filter + dungeon list.
  f.sidebar = CreateFrame("Frame", nil, f)
  f.sidebar:SetPoint("TOPLEFT", 16, -80)
  f.sidebar:SetPoint("BOTTOMLEFT", 16, 16)
  f.sidebar:SetWidth(190)

  f.levelDropdown = CreateFrame("Frame", "FDQ_LevelDropdown", f.sidebar, "UIDropDownMenuTemplate")
  f.levelDropdown:SetPoint("TOPLEFT", -16, 0)
  UIDropDownMenu_SetWidth(f.levelDropdown, 150)
  UIDropDownMenu_Initialize(f.levelDropdown, LevelDropdown_Initialize)

  f.sidebarScroll = CreateFrame("ScrollFrame", "FDQ_SidebarScroll", f.sidebar, "UIPanelScrollFrameTemplate")
  f.sidebarScroll:SetPoint("TOPLEFT", 0, -36)
  f.sidebarScroll:SetPoint("BOTTOMRIGHT", -18, 0)

  f.sidebarContent = CreateFrame("Frame", nil, f.sidebarScroll)
  f.sidebarContent:SetSize(1, 1)
  f.sidebarScroll:SetScrollChild(f.sidebarContent)

  f.sidebarButtons = {}

  -- Vertical divider between sidebar and the quest table.
  f.divider = f:CreateTexture(nil, "ARTWORK")
  f.divider:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 8, 8)
  f.divider:SetPoint("BOTTOMLEFT", f.sidebar, "BOTTOMRIGHT", 8, 0)
  f.divider:SetWidth(1)
  f.divider:SetColorTexture(0.4, 0.4, 0.4, 0.6)

  -- Right panel: dungeon header + quest table.
  f.rightPanel = CreateFrame("Frame", nil, f)
  f.rightPanel:SetPoint("TOPLEFT", f.divider, "TOPRIGHT", 8, 0)
  f.rightPanel:SetPoint("BOTTOMRIGHT", -16, 16)

  f.dungeonName = f.rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.dungeonName:SetPoint("TOPLEFT", 0, 0)

  f.dungeonMeta = f.rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.dungeonMeta:SetPoint("TOPLEFT", f.dungeonName, "BOTTOMLEFT", 0, -4)
  f.dungeonMeta:SetJustifyH("LEFT")
  f.dungeonMeta:SetWidth(640)

  f.dungeonNote = f.rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.dungeonNote:SetPoint("TOPLEFT", f.dungeonMeta, "BOTTOMLEFT", 0, -4)
  f.dungeonNote:SetJustifyH("LEFT")
  f.dungeonNote:SetWidth(640)
  f.dungeonNote:SetWordWrap(true)

  -- Column headers for the quest table.
  f.colHeaders = CreateFrame("Frame", nil, f.rightPanel)
  f.colHeaders:SetPoint("TOPLEFT", f.dungeonNote, "BOTTOMLEFT", 0, -10)
  f.colHeaders:SetSize(640, 14)

  local function MakeHeader(col, text)
    local fs = f.colHeaders:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", col.x, 0)
    fs:SetWidth(col.w)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
  end
  f.headerStatus = MakeHeader(COL.status, "Status")
  f.headerName = MakeHeader(COL.name, "Quest")
  f.headerLevel = MakeHeader(COL.level, "Lvl")
  f.headerPickup = MakeHeader(COL.pickup, "Pickup")

  f.headerRule = f.rightPanel:CreateTexture(nil, "ARTWORK")
  f.headerRule:SetPoint("TOPLEFT", f.colHeaders, "BOTTOMLEFT", 0, -2)
  f.headerRule:SetPoint("TOPRIGHT", f.colHeaders, "BOTTOMRIGHT", 0, -2)
  f.headerRule:SetHeight(1)
  f.headerRule:SetColorTexture(0.4, 0.4, 0.4, 0.6)

  f.tableScroll = CreateFrame("ScrollFrame", "FDQ_TableScroll", f.rightPanel, "UIPanelScrollFrameTemplate")
  f.tableScroll:SetPoint("TOPLEFT", f.headerRule, "BOTTOMLEFT", 0, -6)
  f.tableScroll:SetPoint("BOTTOMRIGHT", 0, 0)

  f.tableContent = CreateFrame("Frame", nil, f.tableScroll)
  f.tableContent:SetSize(1, 1)
  f.tableScroll:SetScrollChild(f.tableContent)
  f.tableScroll:SetScript("OnSizeChanged", function(_, width)
    f.tableContent:SetWidth(width)
  end)

  f.emptyText = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.emptyText:SetPoint("TOPLEFT", 4, -4)
  f.emptyText:SetText("Pick a dungeon on the left.")

  f.rows = {}

  f:Hide()
  SkinWindowChrome(f)
  return f
end

local function GetSidebarButton(f, index)
  local button = f.sidebarButtons[index]
  if not button then
    button = CreateFrame("Button", nil, f.sidebarContent, "UIPanelButtonTemplate")
    button:SetSize(170, 24)
    button:SetPoint("TOPLEFT", 0, -((index - 1) * 28))
    f.sidebarButtons[index] = button
    if skin then
      skin.Button(button)
    end
  end
  return button
end

-- (Re)builds the sidebar dungeon list for the current level-bracket filter,
-- without touching whatever's currently shown in the right-hand table.
function FDQ:RefreshSidebar()
  if not mainFrame then return end
  local f = mainFrame

  local brackets = GetAvailableBrackets()
  if not selectedBracketMin then
    selectedBracketMin = GetNearestBracket(GetPlayerBracket(), brackets)
  end

  UIDropDownMenu_Initialize(f.levelDropdown, LevelDropdown_Initialize)
  UIDropDownMenu_SetSelectedValue(f.levelDropdown, selectedBracketMin)
  UIDropDownMenu_SetText(f.levelDropdown, "Level " .. BracketLabel(selectedBracketMin))

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

  for _, button in pairs(f.sidebarButtons) do
    button:Hide()
  end

  for i, dungeon in ipairs(filtered) do
    local button = GetSidebarButton(f, i)
    local atLevel = dungeon.levels and dungeon.levels.atLevel
    local label = dungeon.name
    if atLevel then
      label = label .. "  |cffaaaaaa(" .. atLevel .. ")|r"
    end
    button:SetText(label)
    if selectedDungeon == dungeon then
      button:LockHighlight()
    else
      button:UnlockHighlight()
    end
    button:SetScript("OnClick", function()
      FDQ:SelectDungeon(dungeon)
    end)
    button:Show()
  end

  f.sidebarContent:SetHeight(math.max(1, #filtered * 28))

  if not f.sidebarEmptyText then
    f.sidebarEmptyText = f.sidebarContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.sidebarEmptyText:SetPoint("TOPLEFT", 2, -2)
    f.sidebarEmptyText:SetText("No dungeons in this level range.")
  end
  f.sidebarEmptyText:SetShown(#filtered == 0)
end

local function GetRow(f, index)
  local row = f.rows[index]
  if not row then
    row = {}
    local function MakeCell(col, template)
      local fs = f.tableContent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
      fs:SetWidth(col.w)
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(false)
      if skin then skin.Font(fs) end
      return fs
    end
    row.status = MakeCell(COL.status)
    row.name = MakeCell(COL.name)
    row.level = MakeCell(COL.level)
    row.pickup = MakeCell(COL.pickup)

    row.notes = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.notes:SetWidth(COL.pickup.x + COL.pickup.w - COL.name.x)
    row.notes:SetJustifyH("LEFT")
    row.notes:SetWordWrap(false)

    f.rows[index] = row
  end
  return row
end

-- Positions row `index`'s cells at vertical offset `y` (both in the table's
-- content frame), and fills in the quest's data. Returns the height consumed.
local function LayoutRow(f, index, y, quest, status)
  local row = GetRow(f, index)

  row.status:ClearAllPoints()
  row.status:SetPoint("TOPLEFT", COL.status.x, -y)
  row.status:SetText(STATUS_COLOR[status] .. STATUS_LABEL[status] .. "|r")

  row.name:ClearAllPoints()
  row.name:SetPoint("TOPLEFT", COL.name.x, -y)
  row.name:SetText(quest.name)

  row.level:ClearAllPoints()
  row.level:SetPoint("TOPLEFT", COL.level.x, -y)
  row.level:SetText(tostring(quest.level or "-"))

  row.pickup:ClearAllPoints()
  row.pickup:SetPoint("TOPLEFT", COL.pickup.x, -y)
  local pickupText = quest.giver or "?"
  if quest.location then
    pickupText = pickupText .. " - " .. quest.location
  end
  if quest.coords then
    pickupText = pickupText .. " /way " .. quest.coords
  end
  row.pickup:SetText(pickupText)

  row.status:Show()
  row.name:Show()
  row.level:Show()
  row.pickup:Show()

  local height = ROW_HEIGHT
  if quest.notes then
    row.notes:ClearAllPoints()
    row.notes:SetPoint("TOPLEFT", COL.name.x, -(y + ROW_HEIGHT))
    row.notes:SetText(quest.notes)
    row.notes:Show()
    height = height + NOTE_HEIGHT
  else
    row.notes:Hide()
  end

  return height + ROW_GAP
end

-- Shows the quest table for `dungeon` in the right-hand panel, and updates
-- the sidebar's highlighted selection to match.
function FDQ:SelectDungeon(dungeon)
  if not mainFrame then
    mainFrame = CreateMainFrame()
  end
  local f = mainFrame
  selectedDungeon = dungeon

  FDQ:RefreshSidebar()

  f.dungeonName:SetText(dungeon.name)

  local faction = FDQ:GetPlayerFaction()
  local levels = dungeon.levels or {}
  f.dungeonMeta:SetText(string.format(
    "Hard: %s  Medium: %s  At Level: %s  Easy: %s   |   Faction: %s",
    levels.hard or "-", levels.medium or "-", levels.atLevel or "-", levels.easy or "-", faction
  ))

  f.dungeonNote:SetShown(dungeon.keyNote ~= nil)
  if dungeon.keyNote then
    f.dungeonNote:SetText("|cffffcc00Note:|r " .. dungeon.keyNote)
  end

  local rows = FDQ:BuildReport(dungeon)
  local order = { missing = 1, active = 2, completed = 3 }
  table.sort(rows, function(a, b)
    if order[a.status] ~= order[b.status] then
      return order[a.status] < order[b.status]
    end
    return a.quest.name < b.quest.name
  end)

  for _, row in pairs(f.rows) do
    row.status:Hide()
    row.name:Hide()
    row.level:Hide()
    row.pickup:Hide()
    row.notes:Hide()
  end

  local y = 0
  for i, entry in ipairs(rows) do
    y = y + LayoutRow(f, i, y, entry.quest, entry.status)
  end

  f.emptyText:SetShown(#rows == 0)
  f.tableContent:SetHeight(math.max(1, y))
end

-- The main entry point via `/fdq` or the minimap button. Opens the window;
-- if `dungeon` is given, selects it, otherwise keeps whatever was last
-- selected (or nothing, on first open).
function FDQ:ShowMain(dungeon)
  if not mainFrame then
    mainFrame = CreateMainFrame()
  end

  FDQ:RefreshSidebar()

  if dungeon then
    FDQ:SelectDungeon(dungeon)
  elseif selectedDungeon then
    FDQ:SelectDungeon(selectedDungeon)
  end

  mainFrame:Show()
end

-- Used by the minimap button: hide the window if it's open, otherwise open it.
function FDQ:ToggleUI()
  if mainFrame and mainFrame:IsShown() then
    mainFrame:Hide()
  else
    FDQ:ShowMain()
  end
end

if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin("ForeverDungeonQuests", function(S)
    skin = S
    if mainFrame then
      SkinWindowChrome(mainFrame)
      for _, button in pairs(mainFrame.sidebarButtons) do
        skin.Button(button)
      end
      for _, row in pairs(mainFrame.rows) do
        skin.Font(row.status)
        skin.Font(row.name)
        skin.Font(row.level)
        skin.Font(row.pickup)
      end
    end
  end)
end
