# Changelog

All notable changes to this addon are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions
correspond to the GitHub Releases produced by `.github/workflows/release.yml`
when a `v*` tag is pushed (see [CLAUDE.md](CLAUDE.md#releases)).

## [Unreleased]

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
