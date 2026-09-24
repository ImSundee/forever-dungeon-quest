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
--
-- Default font/accent color: text defaults to real Expressway if something
-- on the system already provides it (LibSharedMedia, or EllesmereUI's own
-- bundled copy), otherwise to Overpass, an OFL-licensed lookalike bundled
-- in Fonts/ (see FONT_PATH below for the full chain). The dropdown's
-- selected-row swatch prefers EllesmereUI's own live accent color
-- (GetAccentColor()) over our static ACCENT_COLOR guess when EUI is
-- present. Both are best-effort "match EllesmereUI's own defaults" per
-- user request, not hard dependencies.

local ADDON_NAME = "Forever Dungeon Quests"

local STATUS_COLOR = {
  completed = "|cff808080",    -- gray
  active = "|cff33ff33",       -- green
  ["dungeon-drop"] = "|cffffcc00", -- yellow
  missing = "|cffff4444",      -- red
}

local STATUS_LABEL = {
  completed = "Done",
  active = "In Log",
  ["dungeon-drop"] = "Dungeon Drop",
  missing = "Missing",
}

-- A plain 8x8 all-white texture bundled with the client, used everywhere
-- below as a solid-color fill/border instead of any Blizzard-themed art
-- (dropdown box, its menu, scrollbar thumb).
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"

-- Fallback accent color for the dropdown menu's selected-row indicator
-- square (used when EllesmereUI isn't present to supply a live one --
-- see GetAccentColor below), modeled after the clean flat look of
-- Blizzard's own Edit Mode settings dropdowns.
local ACCENT_COLOR = { 0.85, 0.55, 0.25 }

-- Default font. Preference order:
--   1. LibSharedMedia-3.0, if some other addon has registered "Expressway"
--      with it -- someone else's real Expressway, not ours to redistribute.
--   2. EllesmereUI's own bundled copy of Expressway, by path -- if
--      EllesmereUI is installed, this file already exists on disk; we're
--      just pointing at it, the same way LibSharedMedia itself works under
--      the hood. Still not something we ship ourselves.
--   3. Our own bundled font, Fonts/Overpass-Regular.ttf -- Overpass is
--      licensed under the SIL Open Font License (see Fonts/LICENSE.md),
--      which explicitly permits bundling/redistributing with other
--      software (OFL 1.1, condition 2), unlike Expressway's proprietary
--      EULA. It's a deliberate lookalike: Overpass is an open-source
--      interpretation of the same U.S. "Highway Gothic" (FHWA Series)
--      letterforms that Expressway itself is based on, so it's a close
--      visual match without any licensing risk. This is the guaranteed
--      fallback -- always available, no other addon required.
local FONT_CANDIDATES = {
  "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF",
}
local BUNDLED_FONT = "Interface\\AddOns\\ForeverDungeonQuests\\Fonts\\Overpass-Regular.ttf"

local FONT_PATH
local FONT_SOURCE -- for the debug print below
do
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    FONT_PATH = LSM:Fetch("font", "Expressway", true)
    if FONT_PATH then
      FONT_SOURCE = "LibSharedMedia"
    end
  end
  if not FONT_PATH and EllesmereUI then
    FONT_PATH = FONT_CANDIDATES[1]
    FONT_SOURCE = "EllesmereUI path guess"
  end
  if not FONT_PATH then
    FONT_PATH = BUNDLED_FONT
    FONT_SOURCE = "bundled Overpass (OFL)"
  end
end

-- Set true the first time ApplyDefaultFont finds FONT_PATH doesn't
-- actually work (e.g. EllesmereUI global existed but the file path guess
-- was wrong) -- stops retrying a broken path on every single FontString.
local fontPathFailed = false
local fontDebugPrinted = false

-- One-shot diagnostic so we can tell exactly where this is failing instead
-- of guessing blindly -- remove once the font situation is confirmed
-- working (or not) in-game. See CLAUDE.md.
local function PrintFontDebug(setFontOk)
  if fontDebugPrinted then return end
  fontDebugPrinted = true
  print(string.format(
    "|cff33ff99Forever Dungeon Quests|r font debug: LibStub=%s FONT_PATH=%s (source=%s) SetFont ok=%s",
    tostring(LibStub ~= nil), tostring(FONT_PATH), tostring(FONT_SOURCE), tostring(setFontOk)
  ))
end

-- Swaps a FontString's typeface to FONT_PATH while keeping whatever size/
-- outline flags it already has from its template. No-op if FONT_PATH
-- wasn't found or turned out not to work (see above).
local function ApplyDefaultFont(fontString)
  if not FONT_PATH or fontPathFailed then
    PrintFontDebug(nil)
    return
  end
  local _, size, flags = fontString:GetFont()
  if not size then return end
  local ok = fontString:SetFont(FONT_PATH, size, flags)
  PrintFontDebug(ok)
  if not ok then
    fontPathFailed = true
  end
end

-- Column layout for the quest table (x-offset, width) within the right
-- panel's content frame.
local COL = {
  waypoint = { x = 0,   w = 20 },
  status   = { x = 24,  w = 50 },
  name     = { x = 78,  w = 150 },
  level    = { x = 232, w = 30 },
  pickup   = { x = 266, w = 380 },
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

-- Prefers EllesmereUI's own live accent color (so this addon's swatches
-- match whatever the user actually has EllesmereUI set to) over our own
-- static ACCENT_COLOR guess. Per-call rather than cached, since EUI's
-- getters are documented as "don't cache across sessions/long lifetimes."
local function GetAccentColor()
  if skin and skin.GetAccentColor then
    local r, g, b = skin.GetAccentColor()
    if r then
      return r, g, b
    end
  end
  return ACCENT_COLOR[1], ACCENT_COLOR[2], ACCENT_COLOR[3]
end

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

-- A flat, hand-rolled dropdown: no Blizzard UIDropDownMenuTemplate art (the
-- brown-bordered box with the round arrow button). Just a plain bordered
-- box, a white text-glyph arrow, and a small flat popout list -- avoids
-- touching Blizzard's shared global DropDownList frames entirely.
local function CreateCleanDropdown(parent, width)
  local dd = CreateFrame("Button", nil, parent, "BackdropTemplate")
  dd:SetSize(width, 24)
  dd:SetBackdrop({
    bgFile = WHITE_TEXTURE,
    edgeFile = WHITE_TEXTURE,
    edgeSize = 1,
  })
  dd:SetBackdropColor(0.08, 0.08, 0.08, 1)
  dd:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  dd.text = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ApplyDefaultFont(dd.text)
  dd.text:SetPoint("LEFT", 8, 0)
  dd.text:SetPoint("RIGHT", -20, 0)
  dd.text:SetJustifyH("LEFT")
  dd.text:SetWordWrap(false)

  dd.arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyDefaultFont(dd.arrow)
  dd.arrow:SetPoint("RIGHT", -6, 0)
  dd.arrow:SetTextColor(1, 1, 1)
  dd.arrow:SetText("v") -- ASCII caret, not a unicode triangle -- see CLAUDE.md for why

  dd.menu = CreateFrame("Frame", nil, dd, "BackdropTemplate")
  dd.menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  dd.menu:SetWidth(width)
  dd.menu:SetBackdrop({
    bgFile = WHITE_TEXTURE,
    edgeFile = WHITE_TEXTURE,
    edgeSize = 1,
  })
  dd.menu:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
  dd.menu:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  dd.menu:SetFrameStrata("DIALOG")
  dd.menu:Hide()
  dd.menuButtons = {}

  dd:SetScript("OnClick", function()
    dd.menu:SetShown(not dd.menu:IsShown())
  end)

  -- `options` is a list of {text=, value=}; `onSelect(value)` fires when one
  -- is clicked (the menu also closes itself first).
  function dd:SetOptions(options, selectedValue, onSelect)
    for _, btn in ipairs(dd.menuButtons) do
      btn:Hide()
    end

    for i, opt in ipairs(options) do
      local btn = dd.menuButtons[i]
      if not btn then
        btn = CreateFrame("Button", nil, dd.menu)
        btn:SetHeight(20)
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(WHITE_TEXTURE)
        highlight:SetVertexColor(1, 1, 1, 0.06)

        -- Small colored swatch instead of a full-row highlight for the
        -- selected item, similar to Blizzard's own Edit Mode dropdowns.
        btn.swatch = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.swatch:SetSize(12, 12)
        btn.swatch:SetPoint("LEFT", 6, 0)
        btn.swatch:SetBackdrop({ bgFile = WHITE_TEXTURE, edgeFile = WHITE_TEXTURE, edgeSize = 1 })
        btn.swatch:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyDefaultFont(btn.label)
        btn.label:SetPoint("LEFT", btn.swatch, "RIGHT", 6, 0)

        -- Thin divider under each row instead of relying on hover
        -- highlighting alone to separate options.
        btn.divider = dd.menu:CreateTexture(nil, "ARTWORK")
        btn.divider:SetColorTexture(1, 1, 1, 0.08)
        btn.divider:SetHeight(1)

        dd.menuButtons[i] = btn
      end
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", 2, -((i - 1) * 20) - 2)
      btn:SetPoint("RIGHT", dd.menu, "RIGHT", -2, 0)
      btn.label:SetText(opt.text)

      if opt.value == selectedValue then
        local r, g, b = GetAccentColor()
        btn.swatch:SetBackdropColor(r, g, b, 1)
      else
        btn.swatch:SetBackdropColor(0, 0, 0, 0.4)
      end

      btn.divider:ClearAllPoints()
      btn.divider:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 4, 0)
      btn.divider:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 0)
      btn.divider:Show()

      btn:SetScript("OnClick", function()
        dd.menu:Hide()
        onSelect(opt.value)
      end)
      btn:Show()
    end

    -- No divider under the last row -- it already sits on the menu's edge.
    if dd.menuButtons[#options] then
      dd.menuButtons[#options].divider:Hide()
    end

    dd.menu:SetHeight(#options * 20 + 4)

    for _, opt in ipairs(options) do
      if opt.value == selectedValue then
        dd.text:SetText(opt.text)
        break
      end
    end
  end

  return dd
end

-- Reskins a ScrollFrame's ScrollBar (from UIPanelScrollFrameTemplate) to
-- just a clean thumb/track -- no up/down arrow buttons at all, per feedback
-- that even a reskinned arrow was noisier than needed. Defensive about
-- which pieces actually exist, since this is a legacy Slider-based
-- ScrollBar and its structure isn't guaranteed identical across clients.
local function CleanScrollBar(scrollBar)
  if not scrollBar then return end

  local name = scrollBar.GetName and scrollBar:GetName()
  local up = scrollBar.ScrollUpButton or (name and _G[name .. "ScrollUpButton"])
  local down = scrollBar.ScrollDownButton or (name and _G[name .. "ScrollDownButton"])

  -- Explicit checks rather than iterating {up, down}: if `up` is nil,
  -- ipairs() over a table built from {up, down} stops at index 1 and never
  -- reaches `down`, since Lua's # operator/ipairs are unreliable with holes.
  if up then
    up:Hide()
    up:EnableMouse(false)
  end
  if down then
    down:Hide()
    down:EnableMouse(false)
  end

  local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
  if thumb then
    thumb:SetColorTexture(1, 1, 1, 0.3)
    thumb:SetWidth(4)
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
  ApplyDefaultFont(f.brand)
  f.brand:SetPoint("TOP", 0, -10)
  f.brand:SetText(ADDON_NAME)
  f.brand:SetTextColor(0.6, 0.6, 0.6)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ApplyDefaultFont(f.title)
  f.title:SetPoint("TOP", f.brand, "BOTTOM", 0, -6)
  f.title:SetText("Dungeon Quests")

  f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyDefaultFont(f.subtitle)
  f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -4)
  f.subtitle:SetText("Pick a dungeon on the left to check its quests.")

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", -4, -4)

  -- Sidebar: level filter + dungeon list.
  f.sidebar = CreateFrame("Frame", nil, f)
  f.sidebar:SetPoint("TOPLEFT", 16, -80)
  f.sidebar:SetPoint("BOTTOMLEFT", 16, 16)
  f.sidebar:SetWidth(190)

  f.levelDropdown = CreateCleanDropdown(f.sidebar, 170)
  f.levelDropdown:SetPoint("TOPLEFT", 0, 0)

  f.sidebarScroll = CreateFrame("ScrollFrame", "FDQ_SidebarScroll", f.sidebar, "UIPanelScrollFrameTemplate")
  f.sidebarScroll:SetPoint("TOPLEFT", 0, -36)
  f.sidebarScroll:SetPoint("BOTTOMRIGHT", -18, 0)
  CleanScrollBar(f.sidebarScroll.ScrollBar)

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
  ApplyDefaultFont(f.dungeonName)
  f.dungeonName:SetPoint("TOPLEFT", 0, 0)

  f.dungeonMeta = f.rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ApplyDefaultFont(f.dungeonMeta)
  f.dungeonMeta:SetPoint("TOPLEFT", f.dungeonName, "BOTTOMLEFT", 0, -4)
  f.dungeonMeta:SetJustifyH("LEFT")
  f.dungeonMeta:SetWidth(640)

  f.dungeonNote = f.rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ApplyDefaultFont(f.dungeonNote)
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
    ApplyDefaultFont(fs)
    fs:SetPoint("TOPLEFT", col.x, 0)
    fs:SetWidth(col.w)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
  end
  f.headerStatus = MakeHeader(COL.status, "Status")
  -- The waypoint column is icon-only (a ">" button per row) -- 20px isn't
  -- wide enough for a readable label, so it's left unheadered.
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
  CleanScrollBar(f.tableScroll.ScrollBar)

  f.tableContent = CreateFrame("Frame", nil, f.tableScroll)
  f.tableContent:SetSize(1, 1)
  f.tableScroll:SetScrollChild(f.tableContent)
  f.tableScroll:SetScript("OnSizeChanged", function(_, width)
    f.tableContent:SetWidth(width)
  end)

  f.emptyText = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ApplyDefaultFont(f.emptyText)
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
    ApplyDefaultFont(button:GetFontString())
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

  local dropdownOptions = {}
  for _, bracketMin in ipairs(brackets) do
    table.insert(dropdownOptions, { text = "Level " .. BracketLabel(bracketMin), value = bracketMin })
  end
  f.levelDropdown:SetOptions(dropdownOptions, selectedBracketMin, function(value)
    selectedBracketMin = value
    FDQ:RefreshSidebar()
  end)

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
    ApplyDefaultFont(f.sidebarEmptyText)
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
      ApplyDefaultFont(fs)
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

    -- Waypoint/arrow button (TomTom or the client's built-in waypoint --
    -- see Waypoint.lua). "> " rather than a unicode arrow glyph: Forever's
    -- default font renders unicode triangles as tofu, see CLAUDE.md.
    row.waypoint = CreateFrame("Button", nil, f.tableContent, "UIPanelButtonTemplate")
    row.waypoint:SetSize(COL.waypoint.w, ROW_HEIGHT)
    row.waypoint:SetText(">")
    local wfs = row.waypoint:GetFontString()
    if wfs then
      wfs:SetPoint("CENTER", 0, 0)
      ApplyDefaultFont(wfs)
    end
    row.waypoint:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.fdqTooltip or "Set a waypoint.")
      GameTooltip:Show()
    end)
    row.waypoint:SetScript("OnLeave", GameTooltip_Hide)
    if skin then skin.Button(row.waypoint) end

    row.notes = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyDefaultFont(row.notes)
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

  row.waypoint:ClearAllPoints()
  row.waypoint:SetPoint("TOPLEFT", COL.waypoint.x, -y)
  if quest.coords then
    local provider = FDQ:GetWaypointProvider()
    local inZone = FDQ:IsPlayerInQuestZone(quest)
    row.waypoint:Show()
    if provider and inZone then
      row.waypoint:Enable()
      row.waypoint.fdqTooltip = "Set a waypoint to this quest giver" ..
        (provider == "TomTom" and " (TomTom)." or ".")
    else
      row.waypoint:Disable()
      if not provider then
        row.waypoint.fdqTooltip = "Install TomTom, or use a client with the built-in waypoint feature, to set a marker here."
      else
        local zone = FDQ:GetQuestZoneName(quest)
        row.waypoint.fdqTooltip = zone and ("Travel to " .. zone .. " to set a waypoint here.")
          or "Not available from your current zone."
      end
    end
    row.waypoint:SetScript("OnClick", function()
      FDQ:SetQuestWaypoint(quest)
    end)
  else
    row.waypoint:Hide()
  end

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
  local order = { missing = 1, active = 2, ["dungeon-drop"] = 3, completed = 4 }
  table.sort(rows, function(a, b)
    if order[a.status] ~= order[b.status] then
      return order[a.status] < order[b.status]
    end
    return a.quest.name < b.quest.name
  end)

  for _, row in pairs(f.rows) do
    row.waypoint:Hide()
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
        skin.Button(row.waypoint)
      end
    end
  end)
end
