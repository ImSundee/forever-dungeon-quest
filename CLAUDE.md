# Forever Dungeon Quests

A World of Warcraft: Forever addon. Before entering (or while inside) a dungeon,
it shows which dungeon quests the player already has, which they're missing
(and where to get them), and which they've already completed — filtered to
their faction.

## Game context

- **WoW: Forever** is a new Blizzard product launching **2026-11-04**, currently
  in Beta (as of 2026-09-24). It's a from-scratch take on Classic/Vanilla-era
  content (codename "Camelot", product `wow_classic_beta`).
- Despite the Classic-era content, it runs on the **modern Retail client**:
  `## Interface: 16001`, Retail's `C_*` namespace API (`C_QuestLog`, `C_Traits`,
  `C_Map`, etc.), not the old Classic API. "Port from Retail code, not Classic
  code."
- Community references for the API surface (not vendored into this repo, just
  useful to re-check against): `Thunderz96/forever-addon-kit` (captured API
  baseline + porting notes) and `Atraeau/WoW-Addons` (dev environment + hosted
  API reference at atraeau.github.io/WoW-Addons).
- **EllesmereUI** (`github.com/EllesmereGaming/EllesmereUI`) is a popular
  third-party all-in-one UI replacement addon for Forever (an ElvUI-style
  suite). It ships a public, documented skinning API
  (`SKINNING_API.md`, apiVersion 1) that lets other addons opt into matching
  the user's theme/font — see the "UI theming" section below.

## Data source

Quest data in [`ForeverDungeonQuests/Data.lua`](ForeverDungeonQuests/Data.lua)
was transcribed by hand from Wowhead's guide:
https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location
(by Serenal, patch 1.60.1, last pulled 2026-09-24). That page is JS-rendered —
plain `WebFetch` returns an empty shell; you need a real browser
(`claude-in-chrome` MCP tools: `navigate` + `get_page_text`) to get the
rendered text.

Caveats carried over from the source:
- The guide itself says it's Beta and **may be incomplete/inaccurate**;
  currently-untestable dungeons have data backfilled from Classic WoW/Wowhead DB.
- A few quests in **Ruins of Lordaeron** (`Abominable Creatures`,
  `Remember That I Love You`) have `giver = "TBD"` — Wowhead hadn't filled
  those in yet at time of transcription.
- No quest IDs were available on the page at all (see below for why that's
  actually fine).
- Re-pull this page periodically as the Beta progresses; quest text, NPC
  names, and coords are likely to shift before the 2026-11-04 launch.

## Architecture

```
ForeverDungeonQuests/
  ForeverDungeonQuests.toc   -- Interface 16001, lists Data/Core/UI/Minimap load order
  Data.lua                   -- FDQ_Dungeons: static quest database (see below)
  Core.lua                   -- FDQ: faction/dungeon detection, quest status logic, slash command
  UI.lua                     -- FDQ:ShowMain()/SelectDungeon()/ToggleUI(): the single window
  Minimap.lua                -- draggable minimap button, calls FDQ:ToggleUI()
```

### UI shape: one window, sidebar + table

v0.1/v0.2 used two separate popup windows (a dungeon picker, and a report
window you'd navigate back-and-forth from via a "< Dungeons" button). That
was replaced with a single window (`CreateMainFrame()` in `UI.lua`) split
into:

- **Left sidebar** (`f.sidebar`): a level-bracket dropdown filter (defaults
  to the player's own level range) above a scrollable list of dungeon
  buttons for that bracket. Clicking a button calls `FDQ:SelectDungeon(dungeon)`
  — it does **not** close or replace the window, just swaps the right panel's
  content and highlights the clicked button (`button:LockHighlight()`).
- **Right panel** (`f.rightPanel`): the selected dungeon's name/level-range/
  faction/keyNote, a fixed column-header row (Status / Quest / Lvl /
  Pickup), and a scrollable quest table below it.

The quest table is hand-laid-out, not a real Blizzard table widget — WoW's
UI API has no built-in data table, so each row is a pool of FontStrings
(`GetRow()`) repositioned every render pass via `LayoutRow()`, which returns
the pixel height consumed (16px, +14px if the quest has a `notes` line) so
the next row's y-offset accounts for variable row height. Column x-offsets
and widths live in the `COL` table near the top of `UI.lua` — change layout
there, not by hunting through render code.

State that persists across `SelectDungeon` calls (module-locals, not saved
to disk): `selectedBracketMin` (sidebar filter) and `selectedDungeon` (right
panel content) are both sticky for the session so reopening the window via
the minimap button keeps your place. Neither survives `/reload` — if that
turns out to matter, they'd move into `FDQ_DB` like `minimapAngle` already
does.

**Untested**: this whole layout, including whether `ClearAllPoints()` +
re-`SetPoint()` every render is fine performance-wise (it should be, this
isn't a per-frame hot path) and whether the fixed `COL` widths clip any
quest name in `Data.lua` — worth a pass once in-game with EllesmereUI both
present and absent.

### Minimap button

Hand-rolled rather than pulling in LibDataBroker/LibDBIcon, to keep the addon
dependency-free (no library-vendoring step exists in this repo yet). Uses
Blizzard's own built-in quest-giver icon
(`Interface\GossipFrame\AvailableQuestIcon`, the yellow "!") instead of a
custom texture, since it already reads as "quest" and needs no image asset
to ship. Position is angle-based around the minimap circumference, saved to
`FDQ_DB.minimapAngle` (persists via the same SavedVariable as the completed-
quest cache). Click calls `FDQ:ToggleUI()` (`UI.lua`), which opens the main
window (see "UI shape" above) or closes it if already open.

**Unverified**: like the rest of the UI, not yet tested against a live
client — worth confirming the icon/border textures referenced
(`MiniMap-TrackingBorder`, `UI-Minimap-ZoomButton-Highlight`,
`AvailableQuestIcon`) still exist under those exact paths in Forever's client
files, since Retail sometimes renames/relocates minimap-related art between
versions.

### UI theming: EllesmereUI integration

`UI.lua` registers a skin callback via `EllesmereUI.RegisterSkin("ForeverDungeonQuests", fn)`
(gated behind `if EllesmereUI and EllesmereUI.RegisterSkin then ... end`, so
it's a no-op with EUI absent or its skinning disabled for this addon). The
callback receives EUI's `S` skinning table and is stored in the module-local
`skin` variable; `SkinWindowChrome(f)` and the inline `skin.Font(...)` /
`skin.Button(...)` calls scattered through frame/line/button creation are all
guarded by `if skin then`, matching EllesmereUI's documented pattern of
idempotent, always-safe-to-call primitives.

Without EllesmereUI installed, the window falls back to a plain flat panel
(`Interface/Tooltips/UI-Tooltip-*`) rather than the ornate gold-trimmed
`DialogFrame` template used in the very first version of this addon — that
was changed because it looked inconsistent/dated next to a themed UI and
had no addon branding. The window has a persistent `"Forever Dungeon Quests"`
brand label above its title.

**Unverified**: this was written directly against EllesmereUI's
`SKINNING_API.md` (apiVersion 1) without a live client + EllesmereUI
installed to test against. First things to check once that's possible: does
`S.Shell` actually look right on the single window (now wider, with a
sidebar + table instead of a simple list), does `S.Font` correctly re-font
the dynamically-created quest-row FontStrings (created lazily in `GetRow`,
potentially before or after the skin callback fires), and does re-skinning
an already-visible frame (the block at the bottom of `UI.lua`) actually
work or fight with EUI's own re-layout.

### Quest matching is by **title**, not quest ID — on purpose

Wowhead's guide doesn't expose quest IDs, and this is still Beta so IDs could
change anyway. Instead of hardcoding IDs, `Core.lua` builds a title→completed
lookup at runtime:

1. `C_QuestLog.GetAllCompletedQuestIDs()` → every completed quest ID for the
   character.
2. `C_QuestLog.GetTitleForQuestID(id)` → resolve each ID to a title, cached
   into `FDQ_DB.completedTitles[title] = true` (persisted via SavedVariables,
   only rescanned when the completed-ID count changes).
3. Currently-active quests are matched the same way, by scanning
   `C_QuestLog.GetInfo(i).title` for the live quest log — no ID needed there
   either.
4. `FDQ_Dungeons` quest entries are matched against both sets by exact
   `quest.name` string.

**Unverified assumption**: that `GetTitleForQuestID` resolves synchronously
from a local client-side quest name cache (like `GetItemInfo`/`GetSpellInfo`
often do for well-known data) rather than requiring a server round-trip via
`RequestLoadQuestByID`. This has **not been tested against the actual beta
client** — there's no beta access from this dev environment. If titles come
back nil for completed quests, that's the first thing to check; the fallback
would be a `C_QuestLog.RequestLoadQuestByID` + wait-and-retry loop, or
accepting an incomplete completed-quest index.

### Faction filtering

`UnitFactionGroup("player")` → `"Alliance"` / `"Horde"`. Each quest in
`Data.lua` has `faction = "Alliance" | "Horde" | "Neutral"`; the quest table
only shows the player's own faction plus `"Neutral"` entries.

### Dungeon detection

`IsInInstance()` + `GetInstanceInfo()` gives the current instance name, matched
against each dungeon's `aliases` list in `Data.lua` (handles cases like Dire
Maul's three wings sharing one instance name, or Blackrock Spire's
upper/lower halves). `FDQ:GetCurrentInstanceDungeon()` in `Core.lua` already
implements this, but as of the current design it is **not wired to any
event** — see the "planning tool, not popup" decision below.

### UI flow: planning tool, not an in-instance popup

Original v0.1 design auto-popped a report window on `PLAYER_ENTERING_WORLD`
when inside a dungeon. That was changed on purpose: the addon's primary job
is to let players check a dungeon's quest list **before** queueing/
traveling, not just after they're standing inside it. Current flow (as of
the v0.3 single-window rework):

- `/fdq` with no args → `FDQ:ShowMain()` (`UI.lua`) opens the window,
  keeping whatever dungeon was last selected (or nothing, on first open).
- `/fdq <name>` → fuzzy-matches by name and opens the window with that
  dungeon pre-selected via `FDQ:ShowMain(dungeon)`.
- Clicking a dungeon in the sidebar calls `FDQ:SelectDungeon(dungeon)`
  directly — no navigation between separate windows anymore.
- Nothing auto-opens on zone change right now. `GetCurrentInstanceDungeon`/
  `FindDungeonByZoneName` are kept in `Core.lua` specifically because a
  **future** "you have missing quests" warning-on-entry feature (a small
  alert bar, not the full window) will need them — see Roadmap below.

## Roadmap

- [ ] **Entry warning bar** (explicitly deferred): a small unobtrusive
      bar/toast when entering a dungeon with missing quests, distinct from
      the full window. Would reuse `GetCurrentInstanceDungeon()` +
      `BuildReport()`, hooked to `PLAYER_ENTERING_WORLD`.
- [x] Minimap button — shipped in v0.2.0.
- [ ] Options panel (e.g. toggling the minimap button, default level
      bracket) — currently `/fdq` slash command only, no Blizzard
      Interface Options integration.

## Known gaps / next steps

- [ ] **In-game testing has started** (an earlier two-window version of the
      UI was confirmed rendering in-game via a screenshot) but is not
      exhaustive, and the v0.3 single-window/sidebar-plus-table rework
      hasn't been screenshotted at all yet. Still need to confirm:
      `GetTitleForQuestID` behavior for the completed-quest index (see
      assumption above), that `IsInInstance()`/`GetInstanceInfo()` naming
      matches the `aliases` in `Data.lua` exactly, that the EllesmereUI skin
      integration actually renders correctly with EUI installed and enabled
      (see "UI theming" above — untested as of this writing), the flat
      fallback panel look for players without EUI, and that the hand-laid-out
      quest table columns (see "UI shape" above) don't clip or overlap.
- [ ] Fill in the `TBD` quest givers in Ruins of Lordaeron once Wowhead (or
      testing) fills them in.
- [ ] Consider re-scraping the Wowhead page closer to 2026-11-04 launch in
      case quest data changes during Beta.
- [ ] No handling yet for **class-restricted** quests beyond a free-text note
      (e.g. `"Paladin only"`, `"Mage only"`, `"Blacksmiths only"`) — the table
      shows them but doesn't cross-check the player's class. Could add a
      `classOnly` field to `Data.lua` and filter/flag it in `Core.lua`.
- [ ] No handling for **prerequisite chain status** — `notes` is free text
      describing prereqs, but the table doesn't check whether those
      prerequisite quests are done. Would need those chain quests added as
      their own entries to check programmatically.

## Releases

`.github/workflows/release.yml` builds a release on GitHub Actions (repo is
hosted on GitHub, not GitLab, despite an earlier mention of GitLab — corrected
during setup). Trigger: pushing a version tag.

```
git tag v0.2.0
git push origin v0.2.0
```

That zips the `ForeverDungeonQuests/` folder (as-is, so the zip's top-level
folder is `ForeverDungeonQuests/`, matching what WoW's AddOns folder expects)
and attaches it to an auto-generated GitHub Release as
`ForeverDungeonQuests-v0.2.0.zip`. Regular commits/pushes to `main` do **not**
trigger a build — only tags matching `v*`.

Before tagging, update three things (in this order, since the changelog
entry is written last so it reflects what actually landed):
1. `ForeverDungeonQuests/ForeverDungeonQuests.toc`'s `## Version:` line.
2. [`CHANGELOG.md`](CHANGELOG.md) — add a dated `## [x.y.z]` section (Keep a
   Changelog style) above the previous version, linking to the release once
   it exists (`https://github.com/ImSundee/forever-dungeon-quest/releases/tag/vX.Y.Z`).
   This is the long-term historical record the project didn't have before
   v0.2.0 — don't let it drift out of sync with what a tag actually shipped.
3. Then tag and push.

## Session continuity notes

If you're picking this up in a new session: read this file first, then skim
`Core.lua` for the actual matching logic before touching `Data.lua`. The
Wowhead fetch requires the `claude-in-chrome` MCP tool — plain `WebFetch`
will *look* like it worked but return only the page shell (nav/comments UI),
not the actual quest tables, since the content is JS-rendered.
