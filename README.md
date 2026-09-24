# Forever Dungeon Quests

A World of Warcraft: Forever addon that shows you which dungeon quests you
already have, which ones you're missing (and where to pick them up), and
which ones you've already completed — filtered to your faction. It's built
for **planning ahead**: check a dungeon's quest list before you queue or
travel there, not just after you're already standing in it.

## Installation

1. Download the latest release zip from the
   [Releases page](https://github.com/ImSundee/forever-dungeon-quest/releases)
   (e.g. `ForeverDungeonQuests-v0.1.0.zip`).
2. Extract it into your WoW: Forever `AddOns` folder, so you end up with:
   ```
   World of Warcraft/_forever_/Interface/AddOns/ForeverDungeonQuests/
   ```
3. Restart the game (or run `/reload` if it's already open).
4. Make sure the addon is checked/enabled on the AddOns screen at the
   character-select login window.

## How to use it

Click the minimap button (the yellow "!" icon on your minimap) any time,
anywhere — you don't need to be inside a dungeon, or even near one. That
opens a single window: a **dungeon list on the left** (filtered to a level
range via the dropdown at the top, defaulting to your character's own
level) and a **quest table on the right** for whichever dungeon you've
clicked. Clicking a different dungeon in the list just swaps the table —
there's no separate "back" screen. Click the minimap button again, or the
window's close button, to dismiss it. Drag the minimap button around the
minimap edge to reposition it.

You can also type `/fdq` to open the same window.

| Command | What it does |
|---|---|
| `/fdq` | Opens the window (keeping whatever dungeon you last had selected, if any). |
| `/fdq <dungeon name>` | Opens the window with a specific dungeon selected directly — e.g. `/fdq deadmines`, `/fdq scarlet` (partial names work). |
| `/fdq scan` | Forces a rescan of your completed quests. Normally happens automatically; use this if the table looks stale. |

If your dungeon-name search matches more than one dungeon, the addon lists
the matches in chat instead so you can be more specific.

> **Not implemented yet:** an automatic pop-up warning when you enter a
> dungeon with missing quests. Right now the addon is purely something you
> check on your own before heading in — see the Roadmap in
> [CLAUDE.md](CLAUDE.md) if you're interested in what's planned.

## Reading the quest table

Each quest is a row with four columns — **Status**, **Quest**, **Lvl**, and
**Pickup** (the giver, zone, and `/way` coordinates, which you can paste
into TomTom or similar) — plus a second line underneath for any
prerequisite/drop/escort notes. Status is one of:

| Tag | Color | Meaning |
|---|---|---|
| **Missing** | Red | You don't have this quest and haven't completed it. |
| **In Log** | Green | You currently have this quest active. |
| **Done** | Gray | You've already completed this quest. |

Missing quests are always listed first, so the important stuff is at the top.

If a dungeon requires a key or special item to access parts of it (e.g. the
Shadowforge Key for Blackrock Depths), that's called out just above the
table as a note.

## Faction

The table only shows quests for **your faction plus faction-neutral
quests** — you won't see Horde-only quests on an Alliance character or vice
versa. Some quests (like class-specific quest chains, e.g. Paladin-only or
Mage-only) are shown to everyone but marked in the notes; the addon doesn't
currently hide those based on your class.

## Known limitations (Beta)

WoW: Forever is still in Beta, and so is this addon:

- Quest data was transcribed from a community guide during Beta and may be
  incomplete or slightly out of date — a few quests were still marked "TBD"
  by the source at time of writing (notably in Ruins of Lordaeron).
- The addon doesn't check whether you've completed a quest's *prerequisites*
  — only whether you have/completed the quest itself. Chain requirements are
  described in the notes text instead.
- Class-restricted quests (Paladin only, Mage only, etc.) aren't filtered out
  for other classes — they're just noted.

If you spot wrong or outdated info, please open an issue on the
[GitHub repo](https://github.com/ImSundee/forever-dungeon-quest/issues).
