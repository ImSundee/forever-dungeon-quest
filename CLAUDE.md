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
  ForeverDungeonQuests.toc   -- Interface 16001, lists Data/Core/UI load order
  Data.lua                   -- FDQ_Dungeons: static quest database (see below)
  Core.lua                   -- FDQ: faction/dungeon detection, quest status logic, slash command
  UI.lua                     -- FDQ:ShowReport(): the popup report frame
```

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
`Data.lua` has `faction = "Alliance" | "Horde" | "Neutral"`; the report only
shows the player's own faction plus `"Neutral"` entries.

### Dungeon detection

`IsInInstance()` + `GetInstanceInfo()` gives the current instance name, matched
against each dungeon's `aliases` list in `Data.lua` (handles cases like Dire
Maul's three wings sharing one instance name, or Blackrock Spire's
upper/lower halves). `FDQ:GetCurrentInstanceDungeon()` in `Core.lua` already
implements this, but as of the current design it is **not wired to any
event** — see the "planning tool, not popup" decision below.

### UI flow: planning tool, not an in-instance popup

Original v0.1 design auto-popped the report on `PLAYER_ENTERING_WORLD` when
inside a dungeon. That was changed on purpose: the addon's primary job is to
let players check a dungeon's quest list **before** queueing/traveling, not
just after they're standing inside it. Current flow:

- `/fdq` with no args → `FDQ:ShowDungeonList()` (`UI.lua`) opens a picker
  frame listing every dungeon in `FDQ_Dungeons`, sorted by level. Clicking one
  calls `FDQ:OpenDungeonReport(dungeon)`.
- `/fdq <name>` → skips the picker, fuzzy-matches by name, opens the report
  directly.
- The report frame has a "< Dungeons" button (top-left) that re-opens the
  picker.
- Nothing auto-opens on zone change right now. `GetCurrentInstanceDungeon`/
  `FindDungeonByZoneName` are kept in `Core.lua` specifically because a
  **future** "you have missing quests" warning-on-entry feature (a small
  alert bar, not the full report) will need them — see Roadmap below.

## Roadmap

- [ ] **Entry warning bar** (explicitly deferred, not v0.1): a small
      unobtrusive bar/toast when entering a dungeon with missing quests,
      distinct from the full picker/report UI. Would reuse
      `GetCurrentInstanceDungeon()` + `BuildReport()`, hooked to
      `PLAYER_ENTERING_WORLD`.
- [ ] Minimap button / options panel — currently `/fdq` slash command only.

## Known gaps / next steps

- [ ] **No in-game testing yet.** Nothing in `Core.lua`/`UI.lua` has been run
      against a real client — there's no WoW: Forever beta access from this
      dev machine. Priority #1 once beta access exists: confirm
      `GetTitleForQuestID` behavior (see assumption above), confirm
      `IsInInstance()`/`GetInstanceInfo()` naming matches the `aliases` in
      `Data.lua` exactly (instance display names can have subtle punctuation
      differences), and confirm the TOC's `## Interface: 16001` actually loads
      without a "this addon is out of date" warning.
- [ ] Fill in the `TBD` quest givers in Ruins of Lordaeron once Wowhead (or
      testing) fills them in.
- [ ] Consider re-scraping the Wowhead page closer to 2026-11-04 launch in
      case quest data changes during Beta.
- [ ] No handling yet for **class-restricted** quests beyond a free-text note
      (e.g. `"Paladin only"`, `"Mage only"`, `"Blacksmiths only"`) — the report
      shows them but doesn't cross-check the player's class. Could add a
      `classOnly` field to `Data.lua` and filter/flag it in `Core.lua`.
- [ ] No handling for **prerequisite chain status** — `notes` is free text
      describing prereqs, but the report doesn't check whether those
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

## Session continuity notes

If you're picking this up in a new session: read this file first, then skim
`Core.lua` for the actual matching logic before touching `Data.lua`. The
Wowhead fetch requires the `claude-in-chrome` MCP tool — plain `WebFetch`
will *look* like it worked but return only the page shell (nav/comments UI),
not the actual quest tables, since the content is JS-rendered.
