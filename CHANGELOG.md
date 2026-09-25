# Changelog

All notable changes to this addon are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
correspond to the GitHub Releases produced by `.github/workflows/release.yml`
when a `v*` tag is pushed (see [CLAUDE.md](CLAUDE.md#releases)).

## [0.5.0] - 2026-09-25

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.5.0)

### Added
- Expandable `[+]`/`[-]` prerequisite chains: a quest with a traceable,
  uniquely-titled prerequisite chain now shows each step's own status
  (Missing / In Log / Done) when expanded, instead of just a free-text
  note. Giver/location/coords and a waypoint crosshair are shown per step
  where known (`FDQ_PrereqInfo`).
- Opt-in ID-based quest matching (`id = <questID>` on a quest or prereq
  entry) for the handful of chains where multiple distinct quests share
  the exact same title, which title-only matching can't tell apart. Real
  quest IDs are now filled in for all of the duplicate-title chains
  tracked in issue #15 (Ragefire Chasm, Deadmines, Scarlet Monastery,
  Uldaman, Blackrock Depths, Upper Blackrock Spire, Scholomance), traced
  against Wowhead's Classic quest database — two chain-length estimates
  were corrected in the process (`Jail Break!` and `Drakefire Amulet`),
  and a previously-uncertain final step turned out to be a real quest
  literally titled `"Ascension..."`.
- `"Unavailable"` quest status for quests restricted to a single class the
  player's character isn't, so they no longer show as a misleading
  `Missing`.
- Sidebar dungeon buttons are now color-coded by difficulty band relative
  to the player's own level (gray/green/orange/red), and show a green
  "Done" in place of the level badge — with the dungeon name grayed out —
  once every quest FDQ tracks for that dungeon is already completed.
- A waypoint crosshair button on each quest row (and each expanded
  prerequisite line) with known coordinates, using TomTom if installed or
  the client's built-in waypoint otherwise. Disabled outside the quest's
  own zone, with a tooltip naming the zone you need to be in.
- "Missing a quest?" report link in the main window, pointing at a
  pre-filled GitHub issue template.
- A thin divider between each quest's block in the table, so an expanded
  entry with several prerequisite lines doesn't run into the next quest.

### Changed
- Replaced the hand-rolled dropdown/scrollbar's remaining rough edges and
  reworked the expanded prerequisite lines into a column-aligned layout
  (name/status under Quest, giver/location under Pickup) matching the main
  table, with text measured against the live table width so it can't
  overlap the waypoint crosshair.
- Waypoint button moved from a left-hand column to a crosshair icon
  pinned to each row's right edge.
- Main window now uses `DIALOG` frame strata so it renders above other UI
  panels and third-party unit frames instead of sometimes sitting behind
  them.
- Quest and prerequisite `notes` text trimmed across `Data.lua` — once a
  quest has a full prerequisite chain, the expandable list already shows
  it, so restating "chain of N quests, starting with X" in prose was pure
  noise. Genuine caveats (item requirements, faction forks, ordering
  exceptions) were kept.
- Waypoint tooltip wording cleaned up ("Travel to `<zone>` to be able to
  set a waypoint for this quest").

### Fixed
- Escape now closes the main window, like any other Blizzard UI panel
  (it wasn't registered in `UISpecialFrames`).
- The `[+]`/`[-]` prerequisite expand toggle didn't respond to clicks
  in-game — the overlay button was missing `EnableMouse(true)`.
- Hovering a disabled (wrong-zone) waypoint crosshair didn't show its
  explanatory tooltip at all — `Button:Disable()` also suppresses
  `OnEnter`/`OnLeave`, not just `OnClick`. Fixed properly via
  `SetMotionScriptsWhileDisabled(true)` rather than the initial
  `EnableMouse(true)` workaround, and the disabled-state icon recolored
  from a near-invisible pale gray to a clearly-visible dim orange.
- Long quest notes could visually overflow past the table's right edge
  instead of being clipped.

## [0.4.0] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.4.0)

### Added
- Dungeon entry alert: on entering a dungeon, if you're missing quests for
  it (for your faction), you now get a chat message and/or a small
  dismissible pop-up (distinct from the full `/fdq` window), pointing you at
  `/fdq <dungeon>` to see details. Guarded against re-firing on every
  `PLAYER_ENTERING_WORLD` inside the same instance visit.
- Options panel (Blizzard's Interface Options, via the modern Settings API)
  with a single "Dungeon entry alert" dropdown: Off / Pop-up alert / Chat
  message / Both. Defaults to pop-up alert.
- New "Drop" quest status for quests that start from an item drop inside
  the dungeon itself (e.g. *The Glowing Shard* off Mutanus the Devourer in
  Wailing Caverns) rather than from an NPC or object you could go pick up
  beforehand — these no longer show as `Missing`, which was misleading
  since there's nothing to go get ahead of time. Only applied to
  drop-starters where the drop actually happens inside the relevant
  dungeon; a few Wowhead-listed drop quests picked up just outside an
  instance (e.g. the Uldaman necklace quests) are left as ordinary
  missable quests.

### Changed
- Quest table's Pickup column and notes line no longer repeat "Drop-only"
  text for the new drop-status quests now that the status itself says so —
  the Pickup column still shows what the item drops from and where, and
  any other useful note (a prerequisite, a quest chain, an eligibility
  requirement) is kept.

## [0.3.3] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.3.3)

### Fixed
- CurseForge upload was still failing after v0.3.2's fix, now with
  `No Git, SVN, or Hg checkout found in "ForeverDungeonQuests"` —
  `BigWigsMods/packager` requires `.git` to exist literally inside whatever
  `-t` points at, and this repo's `.git` is at the root, not inside
  `ForeverDungeonQuests/`. `publish-curseforge` now `git init`s a throwaway,
  tagged, single-commit repo inside `ForeverDungeonQuests/` before running
  `packager` so `-t` has something valid to find.

## [0.3.2] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.3.2)

### Fixed
- CurseForge upload was failing with `Could not find an addon TOC file` —
  `BigWigsMods/packager` looks for the `.toc` at the checkout root by
  default, but this repo's addon lives in `ForeverDungeonQuests/`. Added
  `-t ForeverDungeonQuests` to the `publish-curseforge` job so it points at
  the right directory.

## [0.3.1] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.3.1)

### Added
- CI now publishes releases to CurseForge automatically on a `v*` tag push,
  via a new `publish-curseforge` job in `release.yml` (using
  `BigWigsMods/packager`), alongside the existing GitHub Release. Gated on
  a `CURSEFORGE_PROJECT_ID` repo variable and `CF_API_TOKEN` secret — skips
  quietly until both are configured, so this doesn't affect the existing
  GitHub Release job.

### Fixed
- The `publish-curseforge` job's `if:` condition referenced the `secrets`
  context directly, which GitHub Actions rejects at workflow-validation
  time. That showed up as two failed, zero-job runs against ordinary
  branch/main pushes (not the tag-only trigger firing — GitHub re-validates
  the workflow file on any push that touches it). Moved the secret-presence
  check into its own job step with a job output instead.

## [0.3.0] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.3.0)

### Added
- Waypoint/arrow button on each quest row with coordinates: sets a TomTom
  waypoint if TomTom is installed, otherwise falls back to the client's own
  built-in waypoint (`C_Map.SetUserWaypoint` + `C_SuperTrack`). Only enabled
  while standing in the quest's own zone, since coords are zone-relative and
  this addon deliberately has no zone-name → map-ID table (see
  [`Waypoint.lua`](ForeverDungeonQuests/Waypoint.lua) and CLAUDE.md). Hovering
  a disabled button explains why (wrong zone, or no waypoint provider
  installed).

### Changed
- Replaced the two-window UI (a dungeon picker + a separate report window,
  with a "< Dungeons" button to go back) with a single window: a sidebar
  on the left listing dungeons (filterable by level bracket) and a proper
  column-aligned quest table (Status / Quest / Lvl / Pickup) on the right
  for whichever dungeon is selected. Clicking a different dungeon just
  swaps the table instead of navigating between windows.
- Widened the window (900px) and rebalanced the quest table's columns —
  narrower Quest column, much wider Pickup column — after in-game testing
  showed pickup text (giver/zone/coords) getting cut off.
- Level-bracket filter now groups dungeons in 20-level ranges (1-20, 21-40,
  41-60) instead of 10-level ranges, since the wider window has room for
  more dungeons per bracket.
- Replaced the sidebar's level-bracket dropdown (previously Blizzard's
  `UIDropDownMenuTemplate` — brown border, round arrow button) and both
  scrollbars' up/down buttons and thumb (previously Blizzard's beveled gold
  scroll-arrow art) with a plain hand-rolled flat style: solid-color boxes
  and a white text-glyph arrow, no Blizzard textures. Unlike the
  EllesmereUI theming, this look is unconditional — it's the addon's own
  default now, not something only users with a theming addon installed get.
- Removed the scrollbar's up/down arrow buttons entirely (hidden, not just
  reskinned) instead of giving them a caret glyph — leaves a clean
  thumb/track with nothing else. Restyled the dropdown's popout menu with a
  small accent-colored swatch per row (instead of a full-row highlight) and
  thin dividers between rows, modeled on a screenshot of Blizzard's own
  Edit Mode settings dropdown.
- Default font: prefers real Expressway if something on the system already
  provides it (confirmed working in-game via `LibSharedMedia-3.0`, which
  EllesmereUI itself registers it with), otherwise falls back to
  **Overpass**, an SIL Open Font License font now bundled in
  `ForeverDungeonQuests/Fonts/` — a deliberate visual lookalike (both are
  independent takes on the same U.S. "Highway Gothic" letterforms).
  Expressway itself is not bundled: its proprietary EULA doesn't grant
  redistribution rights for embedding in software. The dropdown's
  selected-row swatch also now prefers EllesmereUI's *live* accent color
  over our own static orange guess, when EllesmereUI is present.

### Added
- `LICENSE` (MIT) and `THIRD_PARTY_LICENSES.md` (covering the bundled
  Overpass font, under its own SIL Open Font License) — the repo didn't
  have a license before this.

### Fixed
- Crash when opening the window: `SetNormalTexture(nil)` (and the Pushed/
  Disabled equivalents) threw `bad argument #1 to 'SetNormalTexture'` on
  the scrollbar's arrow buttons, since those are secure button templates
  that reject `nil` as a texture asset. Fixed by clearing the texture
  region directly (`GetNormalTexture():SetTexture(nil)`) instead of going
  through the Button widget's setter.
- Dropdown/scrollbar arrows rendering as tofu (a blank box) instead of a
  triangle — the unicode glyphs used weren't in Forever's default font.
  Replaced with plain ASCII carets (`^`/`v`).
- Sidebar dungeon buttons not picking up the Expressway/Overpass font —
  `UIPanelButtonTemplate` exposes its label via `GetFontString()`, not
  `CreateFontString()`, so it was never in the set of FontStrings the
  default-font pass touched.

## [0.2.0] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.2.0)

### Added
- Minimap button (draggable around the minimap edge, no LibDBIcon
  dependency) using Blizzard's built-in quest "!" icon. Clicking it toggles
  the dungeon picker via the new `FDQ:ToggleUI()`.
- Level-bracket dropdown filter and 2-column grid layout for the dungeon
  picker, defaulting to the player's own level range.
- Persistent addon branding label ("Forever Dungeon Quests") on both
  windows.
- EllesmereUI skin integration: registers with EllesmereUI's documented
  `SKINNING_API.md` so the UI matches the user's theme/font when
  EllesmereUI is installed and enabled for this addon.

### Changed
- `/fdq` now opens a dungeon picker so quests can be checked before
  queueing or traveling, instead of requiring you to already be standing
  inside the dungeon. The old auto-popup on `PLAYER_ENTERING_WORLD` was
  removed; a lighter-weight "you have missing quests" entry warning is
  deferred to a future release (tracked in CLAUDE.md's Roadmap).
- Fallback window style (for players without EllesmereUI) switched from the
  ornate gold-trimmed `DialogFrame` template to a plain flat panel.

## [0.1.0] - 2026-09-24

[Release](https://github.com/ImSundee/forever-dungeon-quest/releases/tag/v0.1.0)

### Added
- Initial addon scaffold (`ForeverDungeonQuests.toc`, `Interface: 16001`)
  with a quest database covering every dungeon from Ragefire Chasm through
  Upper Blackrock Spire, transcribed from
  [Wowhead's dungeon quest guide](https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location).
- Title-based quest status matching — no hardcoded quest IDs — using
  `C_QuestLog.GetAllCompletedQuestIDs()` + `GetTitleForQuestID()` for
  completed quests, and the live quest log for active ones.
- Faction filtering via `UnitFactionGroup("player")`.
- `/fdq` slash command and report window showing missing/active/completed
  quests for a dungeon, plus `/fdq scan` to force-rebuild the
  completed-quest index.
- GitHub Actions release pipeline: pushing a `v*` tag zips the addon folder
  and publishes it as a GitHub Release asset.
- User-facing README and CLAUDE.md project/session-context documentation.
