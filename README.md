# Forever Dungeon Quests

A World of Warcraft: Forever addon that shows you which dungeon quests you
already have, which ones you're missing (and where to pick them up), and
which ones you've already completed — filtered to your faction — right when
you step into a dungeon.

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

**It opens itself.** Walk into a supported dungeon and the report window
pops up automatically, showing the quests relevant to your faction.

You can also open it manually with a slash command:

| Command | What it does |
|---|---|
| `/fdq` | Shows the report for the dungeon you're currently standing in. |
| `/fdq <dungeon name>` | Looks up any dungeon by name, even if you're not inside it — e.g. `/fdq deadmines`, `/fdq scarlet` (partial names work). |
| `/fdq scan` | Forces a rescan of your completed quests. Normally happens automatically; use this if the report looks stale. |

If your dungeon-name search matches more than one dungeon, the addon will
list the matches so you can be more specific.

## Reading the report

Each quest line is tagged with a status:

| Tag | Color | Meaning |
|---|---|---|
| **[Missing]** | Red | You don't have this quest and haven't completed it. The line underneath shows the NPC, zone, and coordinates (as a `/way` you can paste into TomTom or similar) where to pick it up, plus any prerequisites or drop requirements. |
| **[In Log]** | Green | You currently have this quest active. |
| **[Done]** | Gray | You've already completed this quest. |

Missing quests are always listed first, so the important stuff is at the top.

If a dungeon requires a key or special item to access parts of it (e.g. the
Shadowforge Key for Blackrock Depths), that's called out at the top of the
report as a note.

## Faction

The report only shows quests for **your faction plus faction-neutral
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
