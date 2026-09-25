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
  Options.lua                -- Blizzard Interface Options panel (Settings API): entry-alert mode
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

**Confirmed in-game (2026-09-25): frame strata**. Left at the default
`"MEDIUM"` strata `CreateFrame` gives every frame, the main window rendered
*behind* some players' third-party unit frames, with the unit frame's own
backdrop showing through as a stray shadow over the addon's window.
`CreateMainFrame()` now explicitly sets `f:SetFrameStrata("DIALOG")` —
matching the strata `CreateCleanDropdown`'s own popout menu already used
(see below) — and `f:SetToplevel(true)` so clicking the window raises it
above any other `DIALOG`-strata frame. `FDQ:ShowMain()` also calls
`mainFrame:Raise()` right after `Show()`, since `SetToplevel` only
auto-raises on click, not on a programmatic `Show()`. The entry-alert toast
(`CreateEntryAlertFrame`) stays at `"HIGH"` (below `"DIALOG"`) since it's a
transient notification, not something that should compete with the main
window for top billing when both happen to be open.

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
  The one-shot `PrintFontDebug` diagnostic (reporting `LibStub` presence,
  the resolved `FONT_PATH`/source, and whether `SetFont` succeeded) has been
  removed now that the LibSharedMedia/Expressway path is confirmed working
  in-game (2026-09-24, see the confirmation above).
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

### Quest matching is by **title** by default, with an opt-in ID fallback (issue #15)

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

**ID-based opt-in (issue #15)**: title matching breaks down for the handful
of chains (tracked in
[issue #15](https://github.com/ImSundee/forever-dungeon-quest/issues/15))
where multiple distinct quests share the exact same title — completing the
first same-titled step would make the lookup report every later step
"completed" too. Rather than rearchitect the whole addon onto IDs (still
risky per the Beta-ID-churn point above, and most of `Data.lua` has no
duplicate-title problem at all), `Core.lua` now supports **matching a single
entry by ID instead of title**, opt-in per entry:

- A quest entry in `Data.lua` may set `id = <questID>` to match by ID.
- A `prereqs` entry may be `{ name = "...", id = <questID> }` instead of a
  plain string, for the same reason.

When `id` is present, `FDQ:GetQuestStatus`/`FDQ:GetPrereqStatus` check it
against `FDQ:GetActiveQuestIDs()`/`FDQ:GetCompletedQuestIDs()` (both built
fresh per report, unlike the cached title index — `GetAllCompletedQuestIDs()`
already returns raw IDs, so there's no per-ID resolve cost to cache against)
and skip the title index entirely for that entry, so a duplicate title
elsewhere can't produce a false "completed". Entries without `id` are
unaffected — this is purely additive.

**Getting the real IDs**: Wowhead is unreachable from this dev environment
(the network egress proxy blocks `www.wowhead.com` outright, and `WebSearch`
alone can't reliably tell five same-titled quests apart), so the actual
per-step IDs for the chains in issue #15 could not be filled in from here.
`/fdq idscan <text>` (`Core.lua`) is the stopgap: run it in-game while a
candidate quest is active, or after completing it, and it prints the title +
real `questID` for every match in the player's own active/completed quests
— paste that into the `id`/`{name=,id=}` field. The `Data.lua` note for
every duplicate-title chain from issue #15 now points back at this. Doing
this for a chain also confirms the addon's other open assumption — whether
Forever's own Beta quest IDs for these quests match Classic's — since
`idscan` reads them straight from the live client rather than from Wowhead.

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

### Prerequisite quests: expandable status, full chain where it's safe to show

Many `notes` in `Data.lua` describe a prerequisite ("Complete X first",
"Requires Y", "chain of N starting with X"). Where the full chain can be
verified and **every step has a unique title**, `prereqs = { "Step 1", "Step
2", ... }` in `Data.lua` lists the whole ordered chain (not just the note's
starting quest) -- gathered by tracing each chain on Wowhead's Classic
section (`wowhead.com/classic/quest=NNNN`'s Series/Requires/Unlocks fields;
WoW: Forever's quest DB mirrors Classic's, per "Game context" above) via the
`claude-in-chrome` MCP tool, since Wowhead's quest pages are JS-rendered.

**Why not every chain got this treatment: duplicate-titled steps.** A
sizeable fraction of Classic's quest chains reuse the exact same title for
multiple steps -- Ragefire Chasm's "Hidden Enemies" is 5 separate quest IDs
all literally titled "Hidden Enemies"; Deadmines' "The Defias Brotherhood"
is 6; Scarlet Monastery's "Test of Lore" is 4; Uldaman's "The Lost Tablets
of Will" chain has three such pairs; Blackrock Depths' "Marshal Windsor" and
Upper Blackrock Spire's "Drakefire Amulet" both pass through six quests all
titled "The True Masters". Since `FDQ:GetPrereqStatus()` (like every other
status check in this addon -- see "Quest matching is by title" above)
matches by **title string**, not quest ID, a repeated title is
indistinguishable from itself: completing just the *first* occurrence would
make the lookup report that title "done," silently implying later
same-named steps are also complete when they might not be. That's a false
positive, which is worse than the feature not existing. So: any chain
containing a duplicate title anywhere in its steps was deliberately left
**free-text only** (no `prereqs` field), even where the full chain was
successfully traced -- see the punch list in the "Known gaps" issue this
was tracked under (linked from the roadmap below) for the complete list and
each one's `Data.lua` note has been corrected to the verified step count
even where it couldn't get the expandable treatment.

A few quests got a **partial** `prereqs` list as a deliberate compromise
rather than being excluded outright:
- **Dead Man's Plea** (Stratholme) has one faction-forked step ("Return to
  Deliana" for Alliance vs "Return to Mokvar" for Horde) -- omitted from
  `prereqs`, since listing both would show a permanent false "Missing" for
  whichever half doesn't exist for the player's faction. Safe to omit
  because the very next step, "Just Compensation", can't be picked up
  without it, so checking that step already implies it.
- **Ramstein** (Stratholme) only lists the one starting breadcrumb
  ("The Ranger Lord's Behest") that was confirmed to link forward on
  Wowhead; a second claimed starter ("To Kill With Purpose") had no
  verifiable "Unlocks" edge into this chain, so it's left out rather than
  guessed at, with a caveat in the note.
- **Blood of the Black Dragon Champion** (Upper Blackrock Spire) kept no
  `prereqs` at all despite an otherwise-fully-traced 11-step chain, because
  the one step right before the target quest came back from research with
  a truncated/uncertain title -- an exact string match is required for this
  to work at all, so a wrong guess here would silently and permanently show
  "Missing." The note was still corrected with everything that *was*
  confirmed.

The prereq quest **doesn't need its own entry in `Data.lua`** to have its
status checked -- `FDQ:GetPrereqStatus()` (`Core.lua`) matches it by title
against the same `activeTitles`/`FDQ_DB.completedTitles` lookups every
other quest uses (see "Quest matching is by title" above), so external
breadcrumb quests (e.g. `"Badlands Reagent Run"`, `"Raptor Horns"`) resolve
correctly even with no corresponding dungeon-quest row. `FDQ:BuildReport()`
attaches `prereqStatuses` (a list of `{name=, status=, giver=, location=,
coords=}`, `status` one of `"active"/"completed"/"missing"` -- no
`"dungeon-drop"` case, since a prereq is by definition something picked up
*before* entering) to each report row.

In `UI.lua`, a quest with `quest.prereqs` gets a `[+]`/`[-]` prefix on its
name (ASCII, not a unicode disclosure triangle -- see the font-tofu note
under "Custom dropdown and scrollbar" above) and an invisible `row.expandBtn`
overlaid on the name cell (FontStrings can't receive clicks themselves).
Clicking toggles `expandedQuests[quest]` (module-local, keyed by the quest
table's own identity since `Data.lua` entries are stable for the session)
and re-runs `FDQ:SelectDungeon()` to re-layout. When expanded, each prereq
gets its own indented line below the quest's row (and below its `notes`
line, if any), reusing `STATUS_COLOR`/`STATUS_LABEL` for consistent
coloring with the main table. Prereq lines use a lazily-grown per-row pool
(`row.prereqFS`), unlike the fixed-cell columns, since the count varies
per quest; `LayoutRow`'s returned height now accounts for however many
prereq lines are currently shown, so later rows in the table shift down
correctly, same as the existing `notes`-line height bump.

**Prereq giver/location/coords (`FDQ_PrereqInfo`)**: an expanded prereq
line originally showed only a name and status -- no way to actually go get
it. `Data.lua` now has a separate `FDQ_PrereqInfo` table, keyed by prereq
name, holding `{ giver=, location=, coords= }` for ~80 of the ~103 distinct
prereq quests referenced across `Data.lua`'s `prereqs` arrays. It's kept as
its own lookup table rather than fields on the `prereqs` entries themselves
(`prereqs = { "Name", ... }` stays plain strings) for two reasons: it
avoids touching every chain's array syntax to add this, and several chains
reuse the same breadcrumb quest (e.g. `"Badlands Reagent Run"`, though that
particular one is faction-forked and deliberately excluded -- see below),
so one `FDQ_PrereqInfo` entry covers every chain that lists it.
`FDQ:GetPrereqStatuses` (`Core.lua`) looks up each prereq's name in this
table and merges `giver`/`location`/`coords` onto its status entry; a name
missing from `FDQ_PrereqInfo` just renders without the extra detail, same
as before. `UI.lua`'s expanded prereq line grows its own pooled crosshair
waypoint button (`row.prereqWaypoints`, mirroring the main per-row
`row.waypoint`) when `coords` is present -- it builds a small pseudo-quest
table (`{name=, coords=, location=}`) and hands it straight to
`FDQ:SetQuestWaypoint`/`IsPlayerInQuestZone`/`GetQuestZoneName`
(`Waypoint.lua`), which only ever read those three fields off whatever
table they're given, so no changes were needed there.

**Two-column prereq line layout (2026-09-25 rework)**: originally each
expanded prereq was a single FontString --
`"- <name>: <status>  (<giver> - <location>)"` -- with the waypoint
crosshair pinned to the table's right edge same as every other row. In-game
screenshot feedback showed this reading poorly (no alignment with the main
table's own Status/Quest/Pickup columns) and, since that one FontString had
no width cap (`SetWordWrap(false)` doesn't reliably clip overflow -- see
below), long giver/location text could run underneath or past the
crosshair instead of stopping short of it. `LayoutRow` (`UI.lua`) now
renders each prereq line as **two** FontStrings pulled from `GetPrereqLine`
(`row.prereqNameFS`/`row.prereqPickupFS`, replacing the old single
`row.prereqFS` pool): the name+status at the indented name position (as
before), and giver/location aligned under `COL.pickup.x` -- matching the
main table's own Pickup column, for visual consistency rather than trailing
at a variable offset. `TruncateToWidth()` (`UI.lua`) actually enforces the
no-overlap guarantee: rather than guess a character-count cap (font/DPI
dependent and thus unreliable), it sets the text, checks the real rendered
`FontString:GetStringWidth()` against the space available before the
crosshair, and trims a character at a time (appending `"..."`) until it
fits -- applied to both the pickup text (width computed live off
`f.tableContent:GetWidth()`, so it re-derives correctly if the window is
resized) and, more defensively, the prereq name itself (capped to the fixed
gap between the name and pickup columns). `CreateCrosshairButton` also now
explicitly calls `btn:SetFrameLevel(parent:GetFrameLevel() + 2)` so the
crosshair always draws above any FontString it happens to sit near,
belt-and-suspenders on top of the truncation fix.

**Still not reading well after that rework, two more passes (2026-09-25)**:
user screenshot feedback after the two-column change above said it "doesn't
change anything, still looks the same" and that the crosshair "system" was
entirely missing for prereq lines. The column split *was* actually landing
(giver/location was aligned under Pickup in the follow-up screenshot), so
the real complaints were: (1) nothing visually separates one quest's block
(row + notes + expanded prereqs) from the next, so a multi-line expanded
entry reads as a wall of text, and (2) the disabled/wrong-zone crosshair
state was colored `(0.5, 0.5, 0.5, 0.4)` -- pale gray at 40% alpha against
this addon's near-black backdrop, which is essentially invisible rather
than "grayed out but present." Two fixes:
- A pooled 1px divider (`row.divider`, `WHITE_TEXTURE` at 12% white) is now
  drawn under every top-level quest row -- spanning from `COL.name.x` to
  the table's current right edge, positioned at `y + height + ROW_GAP/2`
  (i.e. after that row's own notes/expanded-prereq lines have already added
  to `height`, so the line falls in the gap before the *next* quest starts,
  not between a quest and its own prereq detail).
- The disabled-state icon color on both `row.waypoint` and the prereq
  `waypointBtn` changed from `(0.5, 0.5, 0.5, 0.4)` to `(0.85, 0.45, 0.2,
  0.9)` -- a dim orange at near-full opacity, readable as "here, but you
  can't use it right now" instead of disappearing into the background. The
  enabled-state color (white) and the `OnEnter`/`OnLeave` accent-color hover
  swap are unchanged -- both scripts already gate the hover-color swap on
  `self:IsEnabled()`, so they don't touch the new disabled color.

`FDQ_PrereqInfo` was populated by researching each prereq name individually
via web search (not a live browser pull -- Wowhead itself is unreachable
from this dev environment, see "Data source" above) and cross-checked
against this file's own already-verified entries wherever the same
quest/NPC also has a full `Data.lua` row elsewhere (e.g. `"Raptor Horns"`
reuses `"Smart Drinks"`'s confirmed Mebok Mizzyrix/Ratchet data). About 20
names were deliberately left out of the table rather than guessed at:
faction- or race-forked givers where a single entry would be wrong for half
the playerbase (`"Badlands Reagent Run"`, `"Redemption"`, `"Just
Compensation"`, `"Journey to the Marsh"`, `"In Search of Anthion"`), and
names where research turned up conflicting or no confident source
(`"Thadius Grimshade"`, `"The Sunken Temple"`, `"Chillwind Horns"`,
`"Egg Freezing"`, and others). Wrong location data is worse than none, so
these just don't show the extra detail yet -- fill them in via
`FDQ_PrereqInfo` once confirmed.

**Untested**: like the rest of the UI (see "UI shape" above), not yet
confirmed in-game -- specifically whether the `[+]`/`[-]` click target
(`row.expandBtn`, sized to the full name-column width) feels natural to
click versus just clicking directly on the quest name text, and whether the
new two-column layout and `TruncateToWidth` actually read well and stop
overlap at the table's live width (the screenshot that prompted this rework
was taken before it, so the fix itself hasn't been screenshotted yet). The
`FDQ_PrereqInfo` data itself is unconfirmed against a live client the same
way the rest of `Data.lua` is.

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
into an on-screen arrow, exposed in `UI.lua` as a small crosshair-icon button
pinned to the **right edge** of any quest row that has coords
(`CreateCrosshairButton`/`WAYPOINT_ICON_SIZE`/`WAYPOINT_RIGHT_PAD`). Originally
this was a `">"` text button in a dedicated `COL.waypoint` column on the left
of the table (`COL` no longer has a `waypoint` entry at all) — moved and
reskinned after in-game feedback that it read as noisy/misaligned mixed in
with the other left-aligned columns. The crosshair (four corner tick-brackets
plus a center dot) is drawn entirely from `WHITE_TEXTURE` rectangles rather
than a Blizzard art asset, for the same reason the dropdown/scrollbar are
hand-rolled (see "Custom dropdown and scrollbar" above) — no unverified stock
texture path to gamble on, and full control over color for its
enabled/hover/disabled states (`SetIconColor`). Sizes
(`WAYPOINT_HIT_SIZE`/`WAYPOINT_ICON_SIZE`/tick length/thickness) are kept as
whole pixels throughout so the ticks/dot don't land on a half-pixel and blur.
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
explains why (wrong zone, naming the zone by reading it back off
`FDQ:GetQuestZoneName()`, or no provider installed) via `GameTooltip`.

**Disabled-button tooltip, two attempts (2026-09-24/25)**: `Button:Disable()`
also disallows mouse interaction outright, which silently suppressed
`OnEnter`/`OnLeave` along with `OnClick` -- so the disabled-state tooltip
never showed. First fix (2026-09-25) added `row.waypoint:EnableMouse(true)`
right after `:Disable()` in `LayoutRow` (`UI.lua`), and was believed
confirmed working via user report -- but the user found the tooltip *still*
wasn't appearing after that, so `EnableMouse(true)` alone isn't reliable
here (it's plausible the earlier "confirmed" report only ever exercised the
enabled-state tooltip, not the disabled one). The actual fix is
`Button:SetMotionScriptsWhileDisabled(true)`, set once in
`CreateCrosshairButton` -- this is the Blizzard-documented API specifically
for "keep firing OnEnter/OnLeave on a disabled button" (the same mechanism
disabled action-bar buttons use for their own tooltips), rather than
fighting the widget's disabled-state mouse handling after the fact. The
`EnableMouse(true)` calls were removed from both disabled-branches
(`row.waypoint` and the expanded-prereq-line `waypointBtn` in
`GetPrereqWaypoint` -- a parallel/pooled button that had the same original
bug fixed separately the same day, see "Prerequisite quests" below) now
that `SetMotionScriptsWhileDisabled` covers both from one place. Both
disabled-state tooltip messages were also reworded to always name the zone
(via `FDQ:GetQuestZoneName()`) rather than just saying "wrong zone", per a
follow-up user request -- falls back to a "couldn't be determined" message
only when `quest.location`/`entry.location` itself is missing.

**Still unverified**: `SetMotionScriptsWhileDisabled` hasn't been confirmed
against a live Forever client either -- it's a long-standing Retail Button
API, but nothing in this file has live-client confirmation (see "Game
context"). If the tooltip is *still* not appearing after this, the next
thing to check is whether `OnEnter`/`OnLeave` fire on this button at all
(e.g. via a debug print), since that would point at something else
entirely (frame strata/mouse-blocking by an overlapping frame, an error
elsewhere in `LayoutRow` aborting before the script gets attached, etc.)
rather than another disabled-state quirk.

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

**Untested (crosshair icon + right-side placement, added after the above)**:
like the rest of the UI rework, not confirmed in-game yet — specifically
whether `pickup.w` (`COL.pickup`, `UI.lua`) leaves enough clearance before
the icon for the longest `giver`/`location`/`coords` strings in `Data.lua`
without visually colliding, and whether the hand-drawn tick/dot crosshair
actually reads as a "set waypoint" affordance at this size versus needing a
label/tooltip-only hint the first time a player sees it.

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

- [x] **Entry warning bar** — shipped in v0.4.0. `FDQ:CheckEntryAlert`
      (`Core.lua`), hooked to `PLAYER_ENTERING_WORLD`, reuses
      `FindDungeonByZoneName` + `BuildReport()` to detect missing quests for
      the current instance and fires a chat message and/or a small
      dismissible toast (`FDQ:ShowEntryAlert`, `UI.lua`) — not the full
      window, per the "planning tool, not popup" design note below.
      `lastAlertInstanceID` (module-local in `Core.lua`) stops it re-firing
      on every `PLAYER_ENTERING_WORLD` inside the same instance visit (e.g.
      a release, or a loading screen between floors); it resets once you
      leave the instance.
- [x] Minimap button — shipped in v0.2.0.
- [x] **Options panel** — shipped in v0.4.0 (`Options.lua`), but scoped to
      just the entry-alert mode for now (Off / Pop-up alert / Chat message /
      Both, default pop-up). Built on the modern retail Settings API
      (`Settings.RegisterVerticalLayoutCategory` / `Settings.CreateDropdown`)
      rather than a hand-rolled canvas frame, since Forever runs on the
      modern client (see "Game context"). Toggling the minimap button or the
      default level bracket through this panel is still open — not
      attempted yet, no reason it couldn't reuse the same category.

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
- [ ] **Entry alert / Options panel (v0.4.0, untested)**: neither has been
      confirmed against a live client yet. Specifically need to check:
      whether `Settings.RegisterVerticalLayoutCategory`/`Settings.CreateDropdown`
      actually render a working dropdown on Forever's Beta build
      (`Options.lua` defensively no-ops if `Settings.RegisterVerticalLayoutCategory`
      is missing, but hasn't been confirmed it *is* present); whether the
      toast (`FDQ:ShowEntryAlert`, `UI.lua`) is positioned sensibly alongside
      Blizzard's other on-screen UI (loot toasts, objective tracker) at
      `TOP, 0, -180`; and whether `lastAlertInstanceID`'s guard against
      re-firing on every `PLAYER_ENTERING_WORLD` inside one instance visit
      behaves as expected (e.g. after a graveyard release).
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
- [x] **Class-restricted quest status** — shipped: quests restricted to a
      single class (`"Paladin only"`, `"Warlock only"`, `"Mage only"`,
      `"Shaman only"`) now carry a `classOnly = "WARLOCK"`-style field (an
      uppercase English class token, matching `UnitClass("player")`'s 3rd
      return) in `Data.lua`. `FDQ:GetQuestStatus()` (`Core.lua`) checks it
      after active/completed and returns a fifth status, `"unavailable"`,
      when the player's class doesn't match — the player could never have
      picked the quest up on this character, so showing it as `Missing` was
      misleading the same way `dungeon-drop` quests were (see that section
      above). `UI.lua`'s `STATUS_COLOR`/`STATUS_LABEL` render it gray/
      "Unavailable", same color as `completed`, and the row-sort `order`
      table groups it with `completed` (both rank 4) — it's meant to read
      and behave like a done quest, not a missing one, per the user's
      explicit request. Only true class restrictions got this field —
      `"Blacksmiths only"` (a profession, not a class) was deliberately left
      as free text since it's out of scope for `UnitClass`.
      **Untested**: like the rest of the addon's game-facing logic, not
      confirmed against a live client — specifically that `UnitClass`'s 3rd
      return value is the plain uppercase token (`"WARLOCK"`, `"PALADIN"`,
      `"MAGE"`, `"SHAMAN"`) on Forever's client the way it is on Retail.
- [x] **Prerequisite chain status** — shipped: quests with a traceable,
      unique-titled prerequisite chain have a full ordered `prereqs` field
      (`Data.lua`) and an expandable `[+]`/`[-]` row in the UI showing each
      step's own status (see "Prerequisite quests" above). Untested in-game
      like the rest of the UI rework.
- [x] **ID-based matching opt-in for duplicate-titled chains** — shipped:
      `Core.lua` now lets a single quest or `prereqs` entry match by
      `id = <questID>` instead of title (see "Quest matching is by title"
      above), and `/fdq idscan <text>` helps find real questIDs in-game.
      This unblocks the duplicate-title chains from issue #15 in principle,
      but **the actual per-step IDs still need to be filled in** — Wowhead
      is unreachable from this dev environment (network egress blocks it),
      so none of the ~12 duplicate-title chains below have real `id` values
      yet, just a `Data.lua` note pointing at `/fdq idscan`. Whoever has
      live Beta access needs to run each chain and paste in the IDs; the
      faction-forked/unverified-link chains in issue #15 aren't a duplicate-
      title problem and don't need this at all.
- [ ] **~16 chains still can't be fully tracked**, blocked by duplicate
      quest titles within the chain (mitigated by the ID-based opt-in above,
      but not yet filled in with real IDs), a faction-forked step, or an
      unverified/ambiguous link found during research. Full punch list,
      organized by cause and with suggested next steps, tracked in
      [issue #15](https://github.com/ImSundee/forever-dungeon-quest/issues/15).

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
