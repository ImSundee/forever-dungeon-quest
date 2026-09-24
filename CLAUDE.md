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
  Waypoint.lua               -- FDQ:SetQuestWaypoint(): TomTom/native arrow integration
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

### Custom dropdown and scrollbar (no Blizzard widget art)

After in-game feedback that the sidebar's level-bracket dropdown (built on
`UIDropDownMenuTemplate`) and the scrollbars (built on
`UIPanelScrollFrameTemplate`) looked visually inconsistent with the rest of
the flat/clean window -- ornate brown-bordered dropdown box with a round
arrow button, beveled gold scrollbar arrows -- both were replaced with
hand-rolled equivalents in `UI.lua`, independent of EllesmereUI. This went
through a few iterations based on in-game screenshots; current state:

- `CreateCleanDropdown(parent, width)`: a plain bordered box (built from
  `WHITE_TEXTURE`, a stock 8x8 white texture used as a solid-color fill/
  border throughout) with an ASCII `"v"` caret instead of a texture arrow,
  and a small flat popout menu that is **its own frame**, not Blizzard's
  shared global `DropDownList1` -- avoids any risk of that affecting other
  addons' dropdowns. Exposes `dd:SetOptions(options, selectedValue, onSelect)`.
  Each row in the popout has a small colored swatch (`ACCENT_COLOR`, an
  orange similar to Blizzard's own Edit Mode settings dropdowns) instead of
  a full-row highlight for the selected item, plus a thin 1px divider
  between rows -- explicitly modeled on a screenshot of Blizzard's Edit
  Mode dropdown the user provided as a reference for "clean."
- `CleanScrollBar(scrollBar)`: still uses the real `ScrollBar` object from
  `UIPanelScrollFrameTemplate` (scrolling behavior is unchanged), but
  **hides the up/down arrow buttons entirely** (`Hide()` + `EnableMouse(false)`,
  not just reskinned) and recolors the thumb to a plain translucent white
  rectangle. Feedback was that even a reskinned arrow glyph was noisier than
  needed -- just the thumb/track reads as "clean."

This is unconditional now (not gated behind EllesmereUI at all) -- the
addon's own default look no longer depends on a theming addon being
installed. `EllesmereUI.RegisterSkin`'s `S.ScrollBar` call is still applied
on top in `SkinWindowChrome` if EUI is present (for accent-color theming);
there's no `S.Dropdown` call since the dropdown isn't a
`UIDropDownMenuTemplate` anymore for EUI to recognize.

**Confirmed in-game (2026-09-24), two issues found and fixed along the way**:
1. `UIPanelScrollFrameTemplate`'s `ScrollUpButton`/`ScrollDownButton` do
   exist under those names on Forever's client (`SecureScrollTemplates.xml`).
   Calling `btn:SetNormalTexture(nil)` (and Pushed/Disabled) throws
   `bad argument #1 to 'SetNormalTexture' (Usage: self:SetNormalTexture(asset))`
   -- these are **secure** button templates and their texture setters
   reject `nil` as an asset. (Moot now that the buttons are just hidden
   outright, but worth remembering generally: prefer
   `GetXTexture():SetTexture(nil)` over `SetXTexture(nil)` on secure-template
   buttons if a future change needs to touch their textures again.)
2. Unicode triangle glyphs (`▲`/`▼`) rendered as tofu (a blank box) --
   Forever's default font doesn't have those codepoints. Replaced with
   plain ASCII (`v` for the dropdown arrow; the scrollbar buttons are hidden
   now so this only applies to the dropdown).

**Still unverified**: whether `GetThumbTexture()` behaves as expected on
this client, and whether hiding `ScrollUpButton`/`ScrollDownButton` outright
(rather than resizing them to zero) leaves an odd gap at the top/bottom of
the scrollbar track -- hasn't been screenshotted since this latest pass.

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

#### Default font (Expressway, or Overpass as a licensed fallback) and live accent color

- **Font**: `FONT_PATH` tries, in order:
  1. `LibStub("LibSharedMedia-3.0", true):Fetch("font", "Expressway", true)`
     -- **confirmed working in-game (2026-09-24)**: the debug print (see
     below) showed this actually resolves to
     `Interface\AddOns\EllesmereUI\media\fonts\Expressway.TTF` with
     `SetFont` returning `true`, meaning EllesmereUI itself registers
     "Expressway" with LibSharedMedia -- the earlier assumption that it
     manages fonts purely internally was wrong.
  2. If LibSharedMedia comes up empty and the global `EllesmereUI` table
     exists, fall back to that same path by direct guess (belt-and-suspenders
     for installs where LSM isn't registered but the file is still there).
  3. **`Fonts/Overpass-Regular.ttf`, bundled in this repo** -- the
     guaranteed final fallback, so the font situation isn't a no-op for
     anyone without EllesmereUI. Overpass is licensed under the
     [SIL Open Font License](../ForeverDungeonQuests/Fonts/LICENSE-Overpass.md)
     (see [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md) for the
     full reasoning), pulled unmodified from
     [github.com/googlefonts/overpass](https://github.com/googlefonts/overpass).
     It was picked specifically because it's an open-source interpretation
     of the same U.S. FHWA "Highway Gothic" letterforms Expressway itself
     is based on -- a deliberate visual lookalike, not an arbitrary
     substitute. **Expressway itself was never bundled** in this repo: it's
     under a proprietary Fontspring EULA whose free "desktop license" does
     not grant redistribution rights for embedding in software (that
     requires a separate paid "Application License") -- confirmed by
     reading Font Squirrel's license page and Fontspring's EULA terms
     directly. Also confirmed that EllesmereUI's own `license.txt` doesn't
     change this: it disclaims EllesmereUI's *own* copyright claim over
     third-party resources, but a disclaimer isn't a redistribution grant,
     and only Fontspring/Typodermic can grant one.
  `ApplyDefaultFont(fontString)` applies whichever `FONT_PATH` resolved to
  every FontString we create (keeping its template's size/outline flags).
  `fontPathFailed` is a one-shot latch: if `SetFont` ever returns `false`
  on the first FontString it's tried on, every later call becomes a no-op
  instead of repeating a call already known to fail -- in practice this
  shouldn't trigger now that there's always a real, addon-relative bundled
  path as the final fallback. EllesmereUI's own `skin.Font()` call, when
  present, runs *after* `ApplyDefaultFont` in every call site, so EUI's own
  live font choice still wins when EUI is actively skinning this addon.
  `PrintFontDebug` prints a one-shot chat line reporting `LibStub` presence,
  the resolved `FONT_PATH`/`FONT_SOURCE`, and whether `SetFont` succeeded --
  useful to leave in for now given how much back-and-forth this took to
  nail down; remove once confident it's not needed anymore.
- **Accent color**: the dropdown menu's selected-row swatch calls
  `GetAccentColor()`, which prefers EllesmereUI's live `S.GetAccentColor()`
  over the static `ACCENT_COLOR` fallback table when `skin` is set. Not
  cached (re-read every time the dropdown re-renders), per EllesmereUI's own
  guidance not to cache getter results.

**Still unverified**: whether the bundled-Overpass path actually renders
visibly differently from the default `GameFont*` templates in-game --
confirmed working via the LibSharedMedia branch already (see above), but
the Overpass fallback branch specifically hasn't been screenshotted since
it was added.

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

### "Dungeon Drop" status for in-instance drop-starters

Some quests aren't picked up from an NPC or object beforehand at all — they
start from an item that drops off a mob (or a rare loot) **inside** the
dungeon itself (e.g. `The Glowing Shard` in Wailing Caverns, dropped by
Mutanus the Devourer). There's nothing to "go get" ahead of time for these,
so showing them as `Missing` — the same label used for quests the player
could go pick up right now but hasn't — was misleading.

`Data.lua` entries for these set `dungeonDrop = true` (only when the drop
itself happens inside the relevant dungeon — a handful of Wowhead-listed
drop quests are picked up just *outside* the instance, e.g. `Necklace
Recovery`/`The Shattered Necklace` outside Uldaman, and those are left as
ordinary `missing`-capable quests since the player genuinely can go farm
that drop beforehand). `FDQ:GetQuestStatus()` in `Core.lua` checks this flag
last, after active/completed, and returns a fourth status value,
`"dungeon-drop"`, instead of `"missing"`. `UI.lua`'s `STATUS_COLOR`/
`STATUS_LABEL` render it as yellow "Dungeon Drop", and the row-sort `order`
table places it between active and completed (below missing/active, above
completed) so quests actually worth going out of your way for still sort
first.

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

### Waypoint/arrow integration (TomTom or the client's built-in waypoint)

[`Waypoint.lua`](ForeverDungeonQuests/Waypoint.lua) turns a quest's `coords`
(the "x, y" percentage strings transcribed from Wowhead, e.g. `"49, 50"`)
into an on-screen arrow, exposed in `UI.lua` as a small `">"` button on the
left of any quest row that has coords (see the `COL.waypoint` column).
`FDQ:GetWaypointProvider()` picks between two providers, in order:

1. **TomTom**, if installed (`TomTom.AddWaypoint` exists) — most players
   already have it, and its arrow has distance/crazy-arrow extras this addon
   doesn't try to reimplement.
2. The client's own **built-in waypoint** (`C_Map.SetUserWaypoint` +
   `C_SuperTrack.SetSuperTrackedUserWaypoint`) — added to Retail in
   Battle for Azeroth/Shadowlands, and since Forever runs on the modern
   Retail client (Interface 16001 — see "Game context" above) this should
   exist regardless of what other addons the player has, so there's always
   a fallback with zero third-party dependency. This is *not* the same as
   TomTom's arrow and doesn't have its route/distance extras, but shows a
   basic on-screen arrow + world/minimap pin the same way.

**Why the button is gated on `FDQ:IsPlayerInQuestZone(quest)`**: `coords`
are recorded relative to whatever zone/subzone the quest giver is actually
in, but this addon has no zone-name → `uiMapID` lookup table (deliberately —
Forever's Classic-era zones aren't guaranteed to keep Retail's map IDs, and
building/maintaining that table is more risk than this feature is worth for
a Beta addon). Instead, `FDQ:SetQuestWaypoint()` always resolves the
waypoint against `C_Map.GetBestMapForUnit("player")` — i.e. **the player's
current map** — which is only correct when they're actually standing in the
quest's zone. `FDQ:IsPlayerInQuestZone()` compares `GetZoneText()`/
`GetSubZoneText()` against the zone name parsed out of `quest.location`
(the text before the first comma, e.g. `"Orgrimmar, The Drag"` →
`"Orgrimmar"`) to gate this. When the button is disabled, hovering it
explains why (wrong zone, or no provider installed) via `GameTooltip`.

**Unverified** (no beta access from this dev environment, written directly
against TomTom's documented API and Blizzard's `C_Map`/`C_SuperTrack` API):
- That `TomTom:AddWaypoint(uiMapID, x, y, opts)` still matches its current
  release's signature.
- That `C_SuperTrack.SetSuperTrackedUserWaypoint(true)` actually surfaces
  the on-screen arrow on Forever's client the way it does on live Retail.
- The zone-name parsing/matching in `GetQuestZoneName`/`IsPlayerInQuestZone`
  against real `GetZoneText()`/`GetSubZoneText()` values — `Data.lua`'s
  `location` strings were transcribed from Wowhead prose, not validated
  against actual in-game zone/subzone text, so a mismatch (e.g. capitalization,
  or Wowhead naming a subzone the client reports differently) would silently
  leave the button disabled with a "travel to X" tooltip that's actually
  wrong. Worth checking against a few real zones once testable.

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
- [ ] **Waypoint integration (`Waypoint.lua`) is untested in-game** — see the
      "Waypoint/arrow integration" section above for the specific unverified
      pieces (TomTom's `AddWaypoint` signature, whether
      `C_SuperTrack.SetSuperTrackedUserWaypoint` actually shows an arrow on
      this client, and whether the zone-name matching in
      `IsPlayerInQuestZone` lines up with real `GetZoneText()`/
      `GetSubZoneText()` values for the zones in `Data.lua`).
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

### CurseForge publishing (`publish-curseforge` job)

The same `v*`-tag push also runs a second job in `release.yml`,
`publish-curseforge`, using [BigWigsMods/packager](https://github.com/BigWigsMods/packager)
(the "WoW Packager" GitHub Action) to build and upload straight to
CurseForge. Chosen over hand-rolling a CurseForge API call because it's the
de facto standard tool the WoW addon community uses for this (handles
`.pkgmeta`, localization, and multiple upload targets — WoWInterface/Wago/
GitHub — for when we look at "other ones later" per the roadmap, by just
adding `WOWI_API_TOKEN`/`WAGO_API_TOKEN` and the matching `-w`/`-a` id
flags).

**Setup still needed before this job does anything** (it's gated to skip
silently, not fail, until both are present — see below):
1. Create the CurseForge project for this addon (if it doesn't exist yet)
   and note its project id from the "About Project" box on the project page.
2. Add that id as a repo **variable** (not secret, it's not sensitive):
   Settings → Secrets and variables → Actions → Variables →
   `CURSEFORGE_PROJECT_ID`.
3. Generate a CurseForge API token (console.curseforge.com, or via the
   project's settings) and add it as a repo **secret**:
   Settings → Secrets and variables → Actions → Secrets → `CF_API_TOKEN`.

A separate `check-curseforge-config` job checks both `vars.CURSEFORGE_PROJECT_ID`
and `secrets.CF_API_TOKEN` are non-empty in a shell step and exposes that as
a job output; `publish-curseforge` gates on that output via `needs:`/`if:`.
This two-job indirection isn't optional style — GitHub Actions rejects a
job-level `if:` that references `secrets` directly at **workflow-validation
time** (`Unrecognized named-value: 'secrets'`), and a validation failure
surfaces as a failed run on *any* push that touches the workflow file, not
just tag pushes (that's what happened the first time this job was added —
two failed 0-job runs showed up on ordinary branch/main pushes; the
`tags: "v*"` trigger itself was never bypassed, the file just failed to
validate before the trigger filter was even reached). Keep any future `if:`
on these jobs off the `secrets` context directly for the same reason — route
it through a job output instead. So: tagging a release before the
CurseForge setup above is done just quietly skips the CurseForge job — the
existing GitHub Release job is unaffected either way.

**Confirmed on the first real upload (v0.3.1, 2026-09-24)**: `packager`
looks for the addon's `.toc` at the checkout's top level by default, but
this repo's addon lives one directory down in `ForeverDungeonQuests/` (see
"Architecture" above — the repo root also holds `CLAUDE.md`, `LICENSE`,
etc., since this isn't a single-addon-at-root layout). That failed the
upload with `Could not find an addon TOC file`. First attempt: added `-t
ForeverDungeonQuests` to the `args:` line (`packager`'s "top-level directory
of checkout" flag) — **not sufficient on its own** (see next).

**Confirmed on the second attempt (v0.3.2, 2026-09-24)**: `-t
ForeverDungeonQuests` alone still failed, now with `No Git, SVN, or Hg
checkout found in "ForeverDungeonQuests"`. Read `packager`'s actual
`release.sh` source to confirm why: once `-t` is given explicitly, it skips
the auto-detect-by-walking-up-parent-directories logic entirely and just
checks `[ -d "$topdir/.git" ]` on that literal path — since `.git` lives at
the repo root, not inside `ForeverDungeonQuests/`, that check always fails.
There's no `packager` flag or `.pkgmeta` directive that lets `-t` (or the
TOC search it drives) point at a directory *without* `.git` directly inside
it; `.pkgmeta`'s `move-folders` can relocate files during packaging but
doesn't solve the "where's `.git`" problem on its own, and reworking it
felt riskier than necessary to verify without a live test run.

Fix: before running `packager`, `publish-curseforge` now `git init`s a
throwaway, self-contained repo **inside** `ForeverDungeonQuests/` itself
(one commit of the current tree, tagged with `$GITHUB_REF_NAME`) — the main
checkout's real `.git` at the repo root is left alone. This gives `-t
ForeverDungeonQuests` a directory that actually satisfies packager's check,
and since `packager` derives the uploaded version via `git describe --tags`,
tagging that single commit with the same ref name (e.g. `v0.3.2`) makes it
resolve to the same version whether it walks the real repo history or this
synthetic one — the tradeoff is the CurseForge changelog packager
auto-generates from git log will just show that one synthetic commit
message rather than real history; switching to a `manual-changelog:` in a
`.pkgmeta` pointing at `CHANGELOG.md` would fix that if it matters later.

**Unverified / worth watching on the first real upload**: `packager`
auto-detects supported game versions from the `## Interface:` line(s) in
the `.toc` (see "Game context" above — `16001`, product `wow_classic_beta`).
Since WoW: Forever is a new, still-Beta product, it's not guaranteed
CurseForge's own game-version list (or `packager`'s mapping of interface
numbers to it) already recognizes that interface value — if the upload step
fails on game-version detection, the fix is `-g` on the `args:` line to set
it explicitly (see `packager`'s README) once we know what version string
CurseForge expects for this product.

## Licensing

This repo's own code/data is MIT-licensed ([LICENSE](LICENSE)). Any bundled
third-party asset keeps its own license instead, tracked in
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) — currently just the
Overpass font (see "Default font" above for why it's there instead of
Expressway). If a future change bundles another third-party asset (another
font, a texture, a library), add an entry there rather than assuming MIT
covers it — MIT is what covers *this project's* code, not whatever else
gets dropped into the repo.

## Session continuity notes

If you're picking this up in a new session: read this file first, then skim
`Core.lua` for the actual matching logic before touching `Data.lua`. The
Wowhead fetch requires the `claude-in-chrome` MCP tool — plain `WebFetch`
will *look* like it worked but return only the page shell (nav/comments UI),
not the actual quest tables, since the content is JS-rendered.
