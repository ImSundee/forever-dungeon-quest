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
  unavailable = "|cff808080",  -- gray, same as completed -- nothing to do about it
  missing = "|cffff4444",      -- red
}

local STATUS_LABEL = {
  completed = "Done",
  active = "In Log",
  ["dungeon-drop"] = "Drop",
  unavailable = "Unavailable",
  missing = "Missing",
}

-- Sidebar level-number color, keyed off the same hard/medium/atLevel/easy
-- brackets already in Data.lua (rather than inventing separate absolute-
-- level cutoffs) -- so the color always matches whichever difficulty band
-- the player's own level currently falls in for that dungeon:
--   gray:   at or above "easy"   -- trivial, over-leveled
--   green:  at or above "atLevel" (but below "easy")
--   orange: at or above "medium" (but below "atLevel")
--   red:    below "medium"       -- "hard" band or lower
local function GetLevelColor(dungeon)
  local levels = dungeon.levels
  if not levels or not levels.atLevel then
    return "|cffaaaaaa"
  end
  local playerLevel = UnitLevel("player") or 1
  if levels.easy and playerLevel >= levels.easy then
    return "|cff808080" -- gray
  elseif playerLevel >= levels.atLevel then
    return "|cff33ff33" -- green
  elseif levels.medium and playerLevel >= levels.medium then
    return "|cffff9900" -- orange
  else
    return "|cffff4444" -- red
  end
end

-- "Missing a quest?" footer link (bottom-right corner of the main window):
-- opens a small copyable-URL popup pointed straight at the missing-quest
-- issue template (GitHub's `?template=` deep-link query param, not just the
-- bare issues list -- the button is specifically for reporting quest data,
-- so it should land the player on that form pre-selected rather than making
-- them pick it themselves; the bug_report.yml template exists for
-- addon-itself bugs but isn't linked from in-game since there's no
-- in-game "something broke" button, just this one). WoW's UI has no way to
-- open a real browser link from inside the client, so this is the standard
-- addon pattern -- a StaticPopup with a pre-selected, read-only-in-practice
-- EditBox the player Ctrl+C's out of -- rather than a dead hyperlink or a
-- raw chat print.
local ISSUES_URL = "https://github.com/ImSundee/forever-dungeon-quest/issues/new?template=missing_quest.yml"

StaticPopupDialogs["FDQ_MISSING_QUEST_LINK"] = {
  text = "Report a missing or incorrect quest on GitHub:",
  button1 = CLOSE,
  hasEditBox = true,
  editBoxWidth = 350,
  OnShow = function(self)
    self.editBox:SetText(ISSUES_URL)
    self.editBox:HighlightText()
    self.editBox:SetFocus()
  end,
  EditBoxOnEnterPressed = function(self)
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
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
do
  local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
  if LSM then
    FONT_PATH = LSM:Fetch("font", "Expressway", true)
  end
  if not FONT_PATH and EllesmereUI then
    FONT_PATH = FONT_CANDIDATES[1]
  end
  if not FONT_PATH then
    FONT_PATH = BUNDLED_FONT
  end
end

-- Set true the first time ApplyDefaultFont finds FONT_PATH doesn't
-- actually work (e.g. EllesmereUI global existed but the file path guess
-- was wrong) -- stops retrying a broken path on every single FontString.
local fontPathFailed = false

-- Swaps a FontString's typeface to FONT_PATH while keeping whatever size/
-- outline flags it already has from its template. No-op if FONT_PATH
-- wasn't found or turned out not to work (see above).
local function ApplyDefaultFont(fontString)
  if not FONT_PATH or fontPathFailed then
    return
  end
  local _, size, flags = fontString:GetFont()
  if not size then return end
  local ok = fontString:SetFont(FONT_PATH, size, flags)
  if not ok then
    fontPathFailed = true
  end
end

-- Column layout for the quest table (x-offset, width) within the right
-- panel's content frame. The waypoint icon isn't part of this left-aligned
-- system -- it's pinned to the row's right edge instead (see
-- WAYPOINT_ICON_SIZE/WAYPOINT_RIGHT_PAD below and its SetPoint("TOPRIGHT",...)
-- in LayoutRow), so it stays flush with the table's right edge regardless of
-- how wide the scroll frame ends up being.
local COL = {
  status   = { x = 0,   w = 50 },
  name     = { x = 54,  w = 150 },
  level    = { x = 208, w = 30 },
  pickup   = { x = 242, w = 360 },
}
local ROW_HEIGHT = 16
local NOTE_HEIGHT = 14
local ROW_GAP = 6

-- The waypoint button's clickable area and the crosshair glyph drawn inside
-- it (see CreateCrosshairButton below) -- kept as whole pixels throughout so
-- the corner ticks/center dot don't end up on a half-pixel and blur.
local WAYPOINT_HIT_SIZE = 20
local WAYPOINT_ICON_SIZE = 12
local WAYPOINT_RIGHT_PAD = 6

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

-- Which quests currently have their prerequisite list expanded, keyed by
-- the quest table itself (stable identity for the session -- these come
-- straight out of FDQ_Dungeons, never copied). Sticky across SelectDungeon
-- re-renders (e.g. toggling a row), reset only by a UI reload.
local expandedQuests = {}

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

-- A small hand-drawn crosshair/reticle icon for the waypoint button: four
-- corner tick-brackets plus a center dot, built entirely from WHITE_TEXTURE
-- rectangles rather than a Blizzard art asset -- avoids guessing at a stock
-- texture path that may not exist under that exact name on Forever's client
-- (see CLAUDE.md's general caution about unverified asset paths), and gives
-- full control over color for the enabled/hover/disabled states below.
local function CreateCrosshairButton(parent)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(WAYPOINT_HIT_SIZE, ROW_HEIGHT)
  -- A plain CreateFrame("Button", ...) with no template doesn't get mouse
  -- interaction for free -- without these two calls OnClick/OnEnter/OnLeave
  -- never fire (see the same note on row.expandBtn below).
  btn:EnableMouse(true)
  btn:RegisterForClicks("LeftButtonUp")
  -- Disable() alone stops OnEnter/OnLeave from firing at all (not just
  -- OnClick) -- EnableMouse(true) after Disable() isn't reliable for this.
  -- SetMotionScriptsWhileDisabled is the actual Blizzard-supported API for
  -- "keep showing tooltips on a disabled button" (same mechanism disabled
  -- action bar buttons use), so set it once here instead.
  btn:SetMotionScriptsWhileDisabled(true)
  -- Guarantee this sits visually above the row's FontStrings even if a
  -- long, truncated giver/location line still edges up against it --
  -- parent's frame level plus a margin keeps the click target and its
  -- ticks/dot from ever being drawn underneath overlapping text.
  btn:SetFrameLevel(parent:GetFrameLevel() + 2)

  local icon = CreateFrame("Frame", nil, btn)
  icon:SetSize(WAYPOINT_ICON_SIZE, WAYPOINT_ICON_SIZE)
  icon:SetPoint("CENTER")
  btn.icon = icon

  local tickLen, thickness = 4, 2
  local function MakeTick(w, h)
    local t = icon:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE_TEXTURE)
    t:SetSize(w, h)
    return t
  end

  icon.ticks = {}
  for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
    local h = MakeTick(tickLen, thickness)
    h:SetPoint(corner, 0, 0)
    local v = MakeTick(thickness, tickLen)
    v:SetPoint(corner, 0, 0)
    table.insert(icon.ticks, h)
    table.insert(icon.ticks, v)
  end

  icon.dot = MakeTick(thickness, thickness)
  icon.dot:SetPoint("CENTER")

  function btn:SetIconColor(r, g, b, a)
    a = a or 1
    for _, tex in ipairs(icon.ticks) do
      tex:SetVertexColor(r, g, b, a)
    end
    icon.dot:SetVertexColor(r, g, b, a)
  end

  return btn
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
  skin.Font(f.footer)
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
  -- Left at the default "MEDIUM" strata, this sat behind unit frames from
  -- some third-party unit frame addons (and cast shadows through them) --
  -- reported in-game (2026-09-25). "DIALOG" is the same strata the clean
  -- dropdown's own popout menu uses (see CreateCleanDropdown above), so the
  -- window now sits above ordinary UI panels/unit frames the way a modal
  -- dialog would. SetToplevel makes clicking anywhere on the frame raise it
  -- above any other same-strata frame (e.g. the entry-alert toast, or a
  -- second reload of this same window).
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)

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

  -- Lets Escape close the window, the same way it closes any other
  -- Blizzard UI panel -- without this, a globally-named frame like this
  -- one is invisible to the game's Escape-key handling entirely, and only
  -- the X button (or /fdq again) can close it.
  tinsert(UISpecialFrames, "FDQ_MainFrame")

  -- Sidebar: level filter + dungeon list.
  f.sidebar = CreateFrame("Frame", nil, f)
  f.sidebar:SetPoint("TOPLEFT", 16, -80)
  -- Bottom margin is 30 rather than the outer window's usual 16 to leave
  -- clearance for the "Missing a quest?" footer link pinned to the
  -- bottom-right corner below (see f.footer).
  f.sidebar:SetPoint("BOTTOMLEFT", 16, 30)
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
  -- Same 30px bottom clearance as the sidebar above, for the footer link.
  f.rightPanel:SetPoint("BOTTOMRIGHT", -16, 30)

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
  -- The waypoint column (a crosshair icon, pinned to each row's right edge --
  -- see WAYPOINT_ICON_SIZE above) is icon-only and left unheadered, same as
  -- before it moved from the table's left edge.
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

  -- "Missing a quest?" report link, bottom-right corner of the window
  -- (matches the -16 right margin f.closeButton/f.rightPanel already use).
  -- See ISSUES_URL/StaticPopupDialogs["FDQ_MISSING_QUEST_LINK"] above for
  -- why this opens a copyable-URL popup instead of a real hyperlink.
  f.footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ApplyDefaultFont(f.footer)
  f.footer:SetPoint("BOTTOMRIGHT", -16, 10)
  f.footer:SetText("Missing a quest? Report it")
  f.footer:SetTextColor(0.6, 0.6, 0.6)

  -- FontStrings can't receive clicks -- same pattern as row.expandBtn for
  -- the prereq [+]/[-] toggle (see "Prerequisite quests" in CLAUDE.md).
  f.footerBtn = CreateFrame("Button", nil, f)
  f.footerBtn:SetAllPoints(f.footer)
  f.footerBtn:SetScript("OnClick", function()
    StaticPopup_Show("FDQ_MISSING_QUEST_LINK")
  end)
  f.footerBtn:SetScript("OnEnter", function()
    f.footer:SetTextColor(1, 1, 1)
    GameTooltip:SetOwner(f.footerBtn, "ANCHOR_TOP")
    GameTooltip:SetText("Click to copy the link to GitHub's issue tracker")
    GameTooltip:Show()
  end)
  f.footerBtn:SetScript("OnLeave", function()
    f.footer:SetTextColor(0.6, 0.6, 0.6)
    GameTooltip:Hide()
  end)

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

    -- "Done" badge for a dungeon with nothing left to do (see
    -- FDQ:IsDungeonComplete, Core.lua) -- pinned to the button's own right
    -- edge rather than appended into the button's text (which already
    -- carries the dungeon name plus a level badge, see RefreshSidebar
    -- below, and both are wide enough on longer dungeon names that jamming
    -- a third piece of text into the same string risked overflow/clipping).
    -- A vivid green distinct from the muted gray "Done" used for individual
    -- completed quest rows (STATUS_COLOR.completed) -- this is meant to
    -- stand out at a glance across the whole sidebar, not blend in.
    button.doneBadge = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ApplyDefaultFont(button.doneBadge)
    if skin then skin.Font(button.doneBadge) end
    button.doneBadge:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    button.doneBadge:SetText("|cff33ff33Done|r")
    button.doneBadge:Hide()
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
      label = label .. "  " .. GetLevelColor(dungeon) .. "(" .. atLevel .. ")|r"
    end
    button:SetText(label)
    button.doneBadge:SetShown(FDQ:IsDungeonComplete(dungeon))
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
    -- see Waypoint.lua): a hand-drawn crosshair icon, pinned to the row's
    -- right edge (see LayoutRow). Not a standard textured Button, so it's
    -- deliberately not passed to skin.Button below -- EllesmereUI's skinning
    -- expects normal/pushed/highlight texture slots this button doesn't have.
    row.waypoint = CreateCrosshairButton(f.tableContent)
    row.waypoint:SetIconColor(1, 1, 1, 0.9)
    row.waypoint:SetScript("OnEnter", function(self)
      if self:IsEnabled() then
        local r, g, b = GetAccentColor()
        self:SetIconColor(r, g, b, 1)
      end
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:SetText(self.fdqTooltip or "Set a waypoint.")
      GameTooltip:Show()
    end)
    row.waypoint:SetScript("OnLeave", function(self)
      if self:IsEnabled() then
        self:SetIconColor(1, 1, 1, 0.9)
      end
      GameTooltip_Hide()
    end)

    row.notes = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyDefaultFont(row.notes)
    row.notes:SetWidth(COL.pickup.x + COL.pickup.w - COL.name.x)
    row.notes:SetJustifyH("LEFT")
    row.notes:SetWordWrap(false)

    -- Invisible overlay button over the quest name, for quests with
    -- quest.prereqs -- click toggles expandedQuests[quest] and re-renders.
    -- A FontString on its own can't receive clicks, so this sits on top of
    -- row.name rather than replacing it.
    row.expandBtn = CreateFrame("Button", nil, f.tableContent)
    row.expandBtn:SetSize(COL.name.w, ROW_HEIGHT)
    -- Plain CreateFrame("Button", ...) doesn't get mouse interaction for
    -- free the way template-based buttons do -- without these two calls
    -- OnClick never fires (see the same note on CreateCrosshairButton
    -- above). This was the actual cause of the expand toggle doing nothing
    -- in-game.
    row.expandBtn:EnableMouse(true)
    row.expandBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.expandBtn:Hide()

    -- Thin divider drawn under each quest's full row (including its notes
    -- and any expanded prereq lines) -- added after in-game feedback that
    -- rows, especially expanded ones with several prereq lines, ran
    -- together with no visual separation between one quest and the next.
    row.divider = f.tableContent:CreateTexture(nil, "ARTWORK")
    row.divider:SetTexture(WHITE_TEXTURE)
    row.divider:SetHeight(1)
    row.divider:SetVertexColor(1, 1, 1, 0.12)

    -- Lazily-grown pools of prereq status lines shown under a row when
    -- expanded -- count varies per quest, unlike the fixed cells above. Two
    -- parallel pools (name+status, giver/location) instead of one combined
    -- FontString, so the giver/location text lines up under the main
    -- table's Pickup column instead of trailing directly after the status
    -- text at whatever length that happens to be -- see GetPrereqLine below.
    row.prereqNameFS = {}
    row.prereqPickupFS = {}
    -- Parallel pool of waypoint crosshair buttons, one per prereq line that
    -- has coords (via FDQ_PrereqInfo -- see GetPrereqWaypoint below).
    row.prereqWaypoints = {}

    f.rows[index] = row
  end
  return row
end

-- Returns the pair of FontStrings for one expanded prereq line: `name`
-- (status + prereq name, indented under the Quest column) and `pickup`
-- (giver/location, aligned under the Pickup column like the main table --
-- see COL above). Split into two so the giver/location text has a
-- predictable, boundable start position instead of trailing directly after
-- variable-length status text, which is what let it run into the waypoint
-- crosshair pinned to the row's right edge (see TruncateToWidth below for
-- how overlap is actually prevented).
local function GetPrereqLine(f, row, idx)
  local name = row.prereqNameFS[idx]
  if not name then
    name = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyDefaultFont(name)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    if skin then skin.Font(name) end
    row.prereqNameFS[idx] = name
  end

  local pickup = row.prereqPickupFS[idx]
  if not pickup then
    pickup = f.tableContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ApplyDefaultFont(pickup)
    pickup:SetJustifyH("LEFT")
    pickup:SetWordWrap(false)
    if skin then skin.Font(pickup) end
    row.prereqPickupFS[idx] = pickup
  end

  return name, pickup
end

-- Trims `text` (a plain string, no color codes) a character at a time until
-- it renders within `maxWidth` pixels on `fs`, appending "...". Measuring
-- via GetStringWidth (rather than guessing a character-count cap) is what
-- actually guarantees this can't run into the waypoint crosshair regardless
-- of font/size, since WordWrap(false) alone doesn't reliably clip overflow
-- (see the "Untested" note this replaces in CLAUDE.md).
local function TruncateToWidth(fs, text, maxWidth)
  if not text or text == "" then return text end
  fs:SetText(text)
  if fs:GetStringWidth() <= maxWidth then
    return text
  end
  local trimmed = text
  while #trimmed > 1 do
    trimmed = trimmed:sub(1, #trimmed - 1)
    fs:SetText(trimmed .. "...")
    if fs:GetStringWidth() <= maxWidth then
      break
    end
  end
  return trimmed .. "..."
end

-- A waypoint button for one expanded prereq line, same crosshair icon/
-- hover behavior as the main per-row row.waypoint (see GetRow above) but
-- pooled per prereq line instead of per quest row. Not passed to
-- skin.Button for the same reason row.waypoint isn't -- it has no normal/
-- pushed/highlight texture slots for EllesmereUI's skinning to grab.
local function GetPrereqWaypoint(f, row, idx)
  local btn = row.prereqWaypoints[idx]
  if not btn then
    btn = CreateCrosshairButton(f.tableContent)
    btn:SetIconColor(1, 1, 1, 0.9)
    btn:SetScript("OnEnter", function(self)
      if self:IsEnabled() then
        local r, g, b = GetAccentColor()
        self:SetIconColor(r, g, b, 1)
      end
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:SetText(self.fdqTooltip or "Set a waypoint.")
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
      if self:IsEnabled() then
        self:SetIconColor(1, 1, 1, 0.9)
      end
      GameTooltip_Hide()
    end)
    row.prereqWaypoints[idx] = btn
  end
  return btn
end

-- Positions row `index`'s cells at vertical offset `y` (both in the table's
-- content frame), and fills in the quest's data. Returns the height consumed.
local function LayoutRow(f, index, y, quest, status, prereqStatuses)
  local row = GetRow(f, index)

  row.waypoint:ClearAllPoints()
  row.waypoint:SetPoint("TOPRIGHT", f.tableContent, "TOPRIGHT", -WAYPOINT_RIGHT_PAD, -y)
  if quest.coords then
    local provider = FDQ:GetWaypointProvider()
    local inZone = FDQ:IsPlayerInQuestZone(quest)
    row.waypoint:Show()
    if provider and inZone then
      row.waypoint:Enable()
      row.waypoint:SetIconColor(1, 1, 1, 0.9)
      row.waypoint.fdqTooltip = "Set a waypoint to this quest giver" ..
        (provider == "TomTom" and " (TomTom)." or ".")
    else
      row.waypoint:Disable()
      row.waypoint:SetIconColor(0.85, 0.45, 0.2, 0.9)
      if not provider then
        row.waypoint.fdqTooltip = "Install TomTom, or use a client with the built-in waypoint feature, to set a marker here."
      else
        local zone = FDQ:GetQuestZoneName(quest)
        row.waypoint.fdqTooltip = zone and ("Travel to " .. zone .. " to set a waypoint for this quest.")
          or "This quest's zone couldn't be determined, so no waypoint can be set here."
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
  if quest.prereqs then
    row.name:SetText((expandedQuests[quest] and "[-] " or "[+] ") .. quest.name)
    row.expandBtn:ClearAllPoints()
    row.expandBtn:SetPoint("TOPLEFT", COL.name.x, -y)
    row.expandBtn:SetScript("OnClick", function()
      expandedQuests[quest] = not expandedQuests[quest]
      FDQ:SelectDungeon(selectedDungeon)
    end)
    row.expandBtn:Show()
  else
    row.name:SetText(quest.name)
    row.expandBtn:Hide()
  end

  row.level:ClearAllPoints()
  row.level:SetPoint("TOPLEFT", COL.level.x, -y)
  row.level:SetText(tostring(quest.level or "-"))

  row.pickup:ClearAllPoints()
  row.pickup:SetPoint("TOPLEFT", COL.pickup.x, -y)
  -- Even for dungeon-drop quests, the Pickup column is the only place that
  -- says *what drops off which mob* -- the "Drop" status alone doesn't say
  -- where. quest.giver carries that (e.g. "Grimtotem Satchel (drop from
  -- Maur Grimtotem)"), so it's shown the same as any other quest.
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
    -- Same overflow guard as the prereq lines below (TruncateToWidth) --
    -- a fixed SetWidth alone doesn't reliably clip WordWrap(false) text,
    -- so long notes could run past the table's right edge uncut.
    local notesMaxWidth = f.tableContent:GetWidth() - COL.name.x - (WAYPOINT_HIT_SIZE + WAYPOINT_RIGHT_PAD + 4)
    row.notes:SetText(TruncateToWidth(row.notes, quest.notes, notesMaxWidth))
    row.notes:Show()
    height = height + NOTE_HEIGHT
  else
    row.notes:Hide()
  end

  -- Expanded prereq lines: each shows the prereq's own quest status via
  -- STATUS_COLOR/STATUS_LABEL (reusing the same "completed"/"active"/
  -- "missing" keys the main quest table already uses), plus giver/location
  -- from FDQ_PrereqInfo when available (same "giver - location" shape as the
  -- main Pickup column), and its own waypoint button when coords are known.
  if quest.prereqs and expandedQuests[quest] and prereqStatuses then
    -- Available pixel width for the giver/location text, so it can never
    -- visually run into the crosshair pinned at the table's right edge --
    -- computed off the table's actual current width rather than a column
    -- constant, since the window (and so f.tableContent) can be resized.
    local pickupMaxWidth = f.tableContent:GetWidth() - COL.pickup.x
      - (WAYPOINT_HIT_SIZE + WAYPOINT_RIGHT_PAD + 4)
    local nameMaxWidth = COL.pickup.x - (COL.name.x + 14) - 10

    for i, entry in ipairs(prereqStatuses) do
      local nameFS, pickupFS = GetPrereqLine(f, row, i)

      nameFS:ClearAllPoints()
      nameFS:SetPoint("TOPLEFT", COL.name.x + 14, -(y + height))
      local displayName = TruncateToWidth(nameFS, entry.name, nameMaxWidth)
      nameFS:SetText("- " .. displayName .. ": " .. STATUS_COLOR[entry.status] .. STATUS_LABEL[entry.status] .. "|r")
      nameFS:Show()

      pickupFS:ClearAllPoints()
      pickupFS:SetPoint("TOPLEFT", COL.pickup.x, -(y + height))
      if entry.giver or entry.location then
        local plain = entry.giver or "?"
        if entry.location then
          plain = plain .. " - " .. entry.location
        end
        local displayPickup = TruncateToWidth(pickupFS, plain, pickupMaxWidth)
        pickupFS:SetText("|cff888888" .. displayPickup .. "|r")
        pickupFS:Show()
      else
        pickupFS:Hide()
      end

      local waypointBtn = GetPrereqWaypoint(f, row, i)
      waypointBtn:ClearAllPoints()
      waypointBtn:SetPoint("TOPRIGHT", f.tableContent, "TOPRIGHT", -WAYPOINT_RIGHT_PAD, -(y + height))
      if entry.coords then
        -- FDQ:SetQuestWaypoint/IsPlayerInQuestZone/GetQuestZoneName only
        -- read name/coords/location off whatever table they're given, so a
        -- small pseudo-quest works the same as a real Data.lua entry here.
        local pseudoQuest = { name = entry.name, coords = entry.coords, location = entry.location }
        local provider = FDQ:GetWaypointProvider()
        local inZone = FDQ:IsPlayerInQuestZone(pseudoQuest)
        waypointBtn:Show()
        if provider and inZone then
          waypointBtn:Enable()
          waypointBtn:SetIconColor(1, 1, 1, 0.9)
          waypointBtn.fdqTooltip = "Set a waypoint to this prerequisite's quest giver" ..
            (provider == "TomTom" and " (TomTom)." or ".")
        else
          waypointBtn:Disable()
          waypointBtn:SetIconColor(0.85, 0.45, 0.2, 0.9)
          if not provider then
            waypointBtn.fdqTooltip = "Install TomTom, or use a client with the built-in waypoint feature, to set a marker here."
          else
            local zone = FDQ:GetQuestZoneName(pseudoQuest)
            waypointBtn.fdqTooltip = zone and ("Travel to " .. zone .. " to set a waypoint for this prerequisite.")
              or "This prerequisite's zone couldn't be determined, so no waypoint can be set here."
          end
        end
        waypointBtn:SetScript("OnClick", function()
          FDQ:SetQuestWaypoint(pseudoQuest)
        end)
      else
        waypointBtn:Hide()
      end

      height = height + NOTE_HEIGHT
    end
    for i = #prereqStatuses + 1, #row.prereqNameFS do
      row.prereqNameFS[i]:Hide()
      row.prereqPickupFS[i]:Hide()
    end
    for i = #prereqStatuses + 1, #row.prereqWaypoints do
      row.prereqWaypoints[i]:Hide()
    end
  else
    for _, fs in ipairs(row.prereqNameFS) do
      fs:Hide()
    end
    for _, fs in ipairs(row.prereqPickupFS) do
      fs:Hide()
    end
    for _, btn in ipairs(row.prereqWaypoints) do
      btn:Hide()
    end
  end

  row.divider:ClearAllPoints()
  row.divider:SetPoint("TOPLEFT", COL.name.x, -(y + height + (ROW_GAP / 2)))
  row.divider:SetWidth(math.max(1, f.tableContent:GetWidth() - COL.name.x))
  row.divider:Show()

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
  local order = { missing = 1, active = 2, ["dungeon-drop"] = 3, completed = 4, unavailable = 4 }
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
    row.expandBtn:Hide()
    row.divider:Hide()
    for _, fs in ipairs(row.prereqNameFS) do
      fs:Hide()
    end
    for _, fs in ipairs(row.prereqPickupFS) do
      fs:Hide()
    end
    for _, btn in ipairs(row.prereqWaypoints) do
      btn:Hide()
    end
  end

  local y = 0
  for i, entry in ipairs(rows) do
    y = y + LayoutRow(f, i, y, entry.quest, entry.status, entry.prereqStatuses)
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
  -- SetToplevel (see CreateMainFrame) only auto-raises the frame on click --
  -- Show() alone doesn't, so a stale click on something else earlier in the
  -- session could otherwise leave this window under another DIALOG-strata
  -- frame the next time it's opened.
  mainFrame:Raise()
end

-- Used by the minimap button: hide the window if it's open, otherwise open it.
function FDQ:ToggleUI()
  if mainFrame and mainFrame:IsShown() then
    mainFrame:Hide()
  else
    FDQ:ShowMain()
  end
end

local ALERT_DURATION = 10 -- seconds before the toast auto-dismisses
local alertFrame

local function CreateEntryAlertFrame()
  local f = CreateFrame("Frame", "FDQ_EntryAlertFrame", UIParent, "BackdropTemplate")
  f:SetSize(320, 60)
  f:SetPoint("TOP", 0, -180)
  f:SetFrameStrata("HIGH")
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
  f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  f.closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  f.closeButton:SetPoint("TOPRIGHT", 2, 2)
  f.closeButton:SetScript("OnClick", function() f:Hide() end)

  f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ApplyDefaultFont(f.text)
  f.text:SetPoint("TOPLEFT", 12, -10)
  f.text:SetPoint("TOPRIGHT", -20, -10)
  f.text:SetJustifyH("LEFT")
  f.text:SetWordWrap(true)

  f.viewButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f.viewButton:SetSize(90, 20)
  f.viewButton:SetPoint("BOTTOMRIGHT", -10, 8)
  f.viewButton:SetText("View quests")
  ApplyDefaultFont(f.viewButton:GetFontString())

  f:Hide()
  if skin then
    skin.Shell(f)
    skin.CloseButton(f.closeButton)
    skin.Font(f.text)
    skin.Button(f.viewButton)
  end
  return f
end

-- Small toast shown on dungeon entry when the player is missing quests for
-- it, per FDQ_DB.options.entryAlertMode -- distinct from the full window,
-- which stays opt-in via /fdq (see CLAUDE.md's "planning tool, not popup"
-- design note). Auto-dismisses after ALERT_DURATION seconds, or sooner if
-- clicked/closed.
function FDQ:ShowEntryAlert(dungeon, missingCount)
  if not alertFrame then
    alertFrame = CreateEntryAlertFrame()
  end
  local f = alertFrame

  f.text:SetText(string.format(
    "|cff33ff99Forever Dungeon Quests|r\n%d missing quest%s in %s.",
    missingCount, missingCount == 1 and "" or "s", dungeon.name
  ))

  f.viewButton:SetScript("OnClick", function()
    f:Hide()
    FDQ:ShowMain(dungeon)
  end)

  f:Show()

  if f.hideTimer then
    f.hideTimer:Cancel()
  end
  f.hideTimer = C_Timer.NewTimer(ALERT_DURATION, function()
    f:Hide()
  end)
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
        for _, fs in ipairs(row.prereqNameFS) do
          skin.Font(fs)
        end
        for _, fs in ipairs(row.prereqPickupFS) do
          skin.Font(fs)
        end
      end
    end
  end)
end
