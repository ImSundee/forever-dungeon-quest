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
