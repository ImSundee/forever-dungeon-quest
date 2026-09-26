-- Forever Dungeon Quests: quest database
-- Source: https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location
-- Patch 1.60.1, updated 2026/09/23. Data is Classic-derived and may change during Beta.
--
-- Faction values: "Alliance", "Horde", "Neutral" (available/needed regardless of faction)
--
-- ID-based matching (issue #15, backfilled for issue #27): a quest entry may carry an
-- optional `id = <questID>` field, and a `prereqs` entry may be `{ name = "...", id =
-- <questID> }` instead of a plain string. When `id` is set, Core.lua matches that entry
-- by quest ID only (not title) -- this is immune to the non-English-client title
-- matching bug from issue #27, since C_QuestLog returns numeric IDs regardless of
-- locale. Most top-level quest entries now carry a real `id`, sourced from Wowhead's
-- Forever-specific quest database (wowhead.com/forever/quests/... -- note this is a
-- distinct, Forever-only ID space from Classic's, not a Classic-derived guess; confirmed
-- by cross-checking giver/side against each entry's own transcribed giver/faction).
-- `prereqs` array entries are backfilled with `id` too now (2026-09-26 follow-up pass),
-- using the same Forever quest DB + Core.lua array-id support as the top-level entries.
-- Every plain-string prereqs entry is now converted, including "Just Compensation"
-- (Dead Man's Plea's prereqs), which resolves to 16 same-titled quest IDs on Wowhead --
-- confirmed (2026-09-26) to be interchangeable copies of the same quest, not distinct
-- steps, so it uses the array-id form like the top-level interchangeable-ID quests.
--
-- `id` may also be an ARRAY of questIDs ( id = { 2951, 2952, ... } ) instead of a single
-- number, for quests where the game itself hands out one of several interchangeable
-- quest IDs for the exact same action (e.g. Gnomeregan's "The Sparklematic 5200!" -- a
-- simple "use this object" quest that exists as 6 near-identical DB records, likely so
-- multiple party members can each hold their own copy without ID conflicts; or a quest
-- reworked in a later patch that kept its old ID around too). FDQ:MatchesQuestID
-- (Core.lua) matches on ANY id in the array. Every one of the 16 top-level entries that
-- initially had no confident single ID (traced 2026-09-26) turned out to resolve to one
-- of: a real prerequisite chain (id = final step, prereqs = earlier steps, same as the
-- issue #15 pattern), a faction fork (split into two rows, like the existing
-- Reclaimed Treasures pattern), an interchangeable-ID quest (id = array, see above), or
-- in one case (The Great Ezra Grimm / The Great Fras Siabi) a straight-up name change
-- between Classic and Forever that made the transcribed title never match at all,
-- regardless of client language.
--
-- `/fdq idscan <text>` (Core.lua) remains available in-game as a fallback for any future
-- gaps, or to spot-check any of the above once testable live.

FDQ_Dungeons = {

  {
    name = "Ragefire Chasm",
    aliases = { "Ragefire Chasm" },
    levels = { hard = 9, medium = 12, atLevel = 14, easy = 19 },
    quests = {
      { name = "Slaying the Beast", id = 5761, level = 9, faction = "Horde", giver = "Neeru Fireblade", location = "Orgrimmar, The Drag", coords = "49, 50" },
      { name = "The Power to Destroy...", id = 5725, level = 9, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "56, 92" },
      { name = "Testing an Enemy's Strength", id = 5723, level = 9, faction = "Horde", giver = "Rahauro", location = "Thunder Bluff, Elder Rise", coords = "70, 30" },
      { name = "Searching for the Lost Satchel", id = 5722, level = 9, faction = "Neutral", giver = "Grimtotem Satchel (drop from Maur Grimtotem)", location = "Inside Ragefire Chasm", dungeonDrop = true },
      { name = "Hidden Enemies", id = 5728, level = 9, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "31, 37", prereqs = { { name = "Hidden Enemies", id = 5726 }, { name = "Hidden Enemies", id = 5727 }, { name = "Hidden Enemies", id = 5729 }, { name = "Hidden Enemies", id = 5730 } } },
    },
  },

  {
    name = "The Hall of Thanes",
    aliases = { "The Hall of Thanes" },
    levels = { hard = 11, medium = 13, atLevel = 14, easy = 19 },
    quests = {
      { name = "Important Heirlooms", id = 96403, level = 14, faction = "Neutral", giver = "Thom Filch", location = "Ironforge, Old Ironforge", coords = "32.6, 44.6" },
      { name = "The Restless Dead", id = 96394, level = 15, faction = "Neutral", giver = "Afadra Dunwall", location = "Ironforge, Old Ironforge", coords = "64.8, 58.4" },
      { name = "Old Ironforge Incursion", id = 96393, level = 15, faction = "Neutral", giver = "Earthseer Farsen", location = "Dun Morogh, Gol'Golar Quarry", coords = "64.8, 58.4", notes = "Prerequisite to pick up Underground Map from Dark Iron Map." },
      { name = "The Treaty of Understanding", id = 98423, level = 16, faction = "Neutral", giver = "Interactable item", location = "The Hall of Thanes, Reliquary of Kings vault" },
      { name = "An Ancient Grudge", id = 96395, level = 14, faction = "Neutral", giver = "Ghostly Attendant", location = "The Hall of Thanes, Anvilmar's Rest" },
    },
  },

  {
    name = "Wailing Caverns",
    aliases = { "Wailing Caverns" },
    levels = { hard = 15, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "Serpentbloom", id = 962, level = 14, faction = "Horde", giver = "Apothecary Zamah", location = "Thunder Bluff, Pools of Vision", coords = "34, 21" },
      { name = "Smart Drinks", id = 1491, level = 13, faction = "Neutral", giver = "Mebok Mizzyrix", location = "The Barrens, Ratchet", coords = "62, 37", notes = "Prerequisite: complete Raptor Horns from same NPC first.", prereqs = { { name = "Raptor Horns", id = 865 } } },
      { name = "Trouble at the Docks", id = 959, level = 14, faction = "Neutral", giver = "Crane Operator Bigglefuzz", location = "The Barrens, Ratchet", coords = "63, 37" },
      { name = "Deviate Hides", id = 1486, level = 13, faction = "Neutral", giver = "Nalpak", location = "The Barrens, above WC entrance", coords = "46, 35" },
      { name = "Deviate Eradication", id = 1487, level = 15, faction = "Neutral", giver = "Ebru", location = "The Barrens, above WC entrance", coords = "46, 35" },
      { name = "The Glowing Shard", id = 6981, level = 10, faction = "Neutral", giver = "Drop from Mutanus the Devourer", location = "Wailing Caverns", dungeonDrop = true },
      { name = "Leaders of the Fang", id = 914, level = 15, faction = "Horde", giver = "Nara Wildmane", location = "Thunder Bluff, Elder Rise", coords = "45, 23", notes = "The Barrens Oases is an alternate, skippable entry point into this chain (Tonga hands out either it or The Forgotten Pools, not both) -- omitted below since requiring it shows a permanent false Missing for players who started via The Forgotten Pools instead.", prereqs = { { name = "The Forgotten Pools", id = 870 }, { name = "The Stagnant Oasis", id = 877 }, { name = "Altered Beings", id = 880 }, { name = "Hamuul Runetotem", id = 1489 }, { name = "Nara Wildmane", id = 1490 } } },
    },
  },

  {
    name = "The Deadmines",
    aliases = { "The Deadmines" },
    levels = { hard = 14, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "Collecting Memories", id = 168, level = 14, faction = "Alliance", giver = "Wilder Thistlenettle", location = "Stormwind, Dwarven District", coords = "65, 21" },
      { name = "Oh Brother...", id = 167, level = 15, faction = "Alliance", giver = "Wilder Thistlenettle", location = "Stormwind, Dwarven District", coords = "65, 21" },
      { name = "Underground Assault", id = 2040, level = 15, faction = "Alliance", giver = "Shoni the Shilent", location = "Stormwind, Dwarven District", coords = "55, 13" },
      { name = "The Unsent Letter", id = 373, level = 16, faction = "Neutral", giver = "Drop from Edwin VanCleef", location = "The Deadmines", notes = "Prerequisite to pick up The Stockade Riots.", dungeonDrop = true },
      { name = "Red Silk Bandanas", id = 214, level = 14, faction = "Alliance", giver = "Scout Riell", location = "Westfall, Sentinel Hill", coords = "56, 47", prereqs = { { name = "The Defias Brotherhood", id = 142 }, { name = "The Defias Brotherhood", id = 65 }, { name = "The Defias Brotherhood", id = 132 }, { name = "The Defias Brotherhood", id = 135 }, { name = "The Defias Brotherhood", id = 141 }, { name = "The Defias Brotherhood", id = 155 } } },
      { name = "The Defias Brotherhood", id = 166, level = 14, faction = "Alliance", giver = "Gryan Stoutmantle", location = "Westfall, Sentinel Hill", coords = "56, 47", prereqs = { { name = "The Defias Brotherhood", id = 142 }, { name = "The Defias Brotherhood", id = 65 }, { name = "The Defias Brotherhood", id = 132 }, { name = "The Defias Brotherhood", id = 135 }, { name = "The Defias Brotherhood", id = 141 }, { name = "The Defias Brotherhood", id = 155 } } },
      { name = "The Test of Righteousness", id = 1806, level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", classOnly = "PALADIN", notes = "Paladin only. Starts the Tome of Valor quest chain; start point varies by race." },
    },
  },

  {
    name = "Ruins of Lordaeron",
    aliases = { "Ruins of Lordaeron" },
    levels = { hard = 15, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "A Frightened Request", id = 92401, level = 15, faction = "Horde", giver = "Tabitha Heartweaver", location = "Undercity", coords = "34, 21" },
      { name = "The Wrath of Rath'mael", id = 92422, level = 15, faction = "Horde", giver = "Deathguard Kristof", location = "Brill" },
      { name = "The New Plague", id = 95216, level = 16, faction = "Horde", giver = "Theodore Griffs", location = "Undercity", coords = "47.0, 72.6" },
      { name = "Light's Justice", id = 92421, level = 15, faction = "Horde", giver = "Morbin Lightbane", location = "Undercity", coords = "57.8, 89.8" },
      { name = "Unending Torment", id = 97290, level = 15, faction = "Neutral", giver = "Inside dungeon", location = "Ruins of Lordaeron", notes = "5-step in-dungeon/Undercity chain; step order after the first two is best-effort (Wowhead's chain-order data doesn't fully disambiguate steps 3-4).", prereqs = { { name = "Unending Torment", id = 97288 }, { name = "Unending Torment", id = 97289 }, { name = "Unending Torment", id = 97292 }, { name = "Unending Torment", id = 97291 } } },
      { name = "Crest of Lordaeron", id = 95204, level = 15, faction = "Horde", giver = "Inside dungeon (turn in to Oran Snakewrithe, Undercity)", location = "Ruins of Lordaeron", dungeonDrop = true },
      { name = "Crest of Lordaeron", id = 95189, level = 15, faction = "Alliance", giver = "Inside dungeon (turn in to Lady Dena Kennedy, Stormwind City)", location = "Ruins of Lordaeron", dungeonDrop = true },
      { name = "Abominable Creatures", id = 95250, level = 16, faction = "Alliance", giver = "TBD (beta data incomplete)", location = "TBD" },
      { name = "Bloodied Insignia", id = 95195, level = 16, faction = "Alliance", giver = "General Marcus Jonathan", location = "Stormwind City" },
      { name = "Remember That I Love You", id = 92415, level = 15, faction = "Alliance", giver = "TBD (beta data incomplete)", location = "TBD" },
    },
  },

  {
    name = "Shadowfang Keep",
    aliases = { "Shadowfang Keep" },
    levels = { hard = 18, medium = 21, atLevel = 23, easy = 28 },
    quests = {
      { name = "The Book of Ur", id = 1013, level = 16, faction = "Horde", giver = "Keeper Bel'dugur", location = "Undercity, Apothecarium", coords = "53, 54" },
      { name = "Deathstalkers in Shadowfang", id = 1098, level = 18, faction = "Horde", giver = "High Executor Hadrec", location = "Silverpine Forest, Sepulcher", coords = "43, 41" },
      { name = "Arugal Must Die", id = 1014, level = 18, faction = "Horde", giver = "Dalar Dawnweaver", location = "Silverpine Forest, Sepulcher", coords = "44, 39" },
      { name = "The Orb of Soran'ruk", id = 1740, level = 20, faction = "Neutral", giver = "Doan Karhan", location = "The Barrens, near Camp Taurajo", coords = "49, 57", classOnly = "WARLOCK", notes = "Warlock only." },
      { name = "The Test of Righteousness", id = 1806, level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", classOnly = "PALADIN", notes = "Paladin only. Starts the Tome of Valor quest chain; start point varies by race." },
    },
  },

  {
    name = "Blackfathom Deeps",
    aliases = { "Blackfathom Deeps" },
    levels = { hard = 21, medium = 23, atLevel = 25, easy = 30 },
    quests = {
      -- Horde
      { name = "The Essence of Aku'Mai", id = 6563, level = 17, faction = "Horde", giver = "Je'neu Sancrea", location = "Ashenvale, Zoram'gar Outpost", coords = "11, 34" },
      { name = "Blackfathom Villainy", id = 6561, level = 18, faction = "Horde", giver = "Argent Guard Thaelrid", location = "Blackfathom Deeps, alcove SW of Ghamoo-ra" },
      { name = "Amongst the Ruins", id = 6921, level = 21, faction = "Horde", giver = "Je'neu Sancrea", location = "Ashenvale, Zoram'gar Outpost", coords = "11, 34", notes = "Summons Baron Aquanis when Fathom Core is picked up; needed for next quest." },
      { name = "Baron Aquanis", id = 909, level = 21, faction = "Horde", giver = "Drop: Strange Water Globe from Baron Aquanis", location = "Blackfathom Deeps", dungeonDrop = true },
      { name = "Allegiance to the Old Gods", id = 6565, level = 17, faction = "Horde", giver = "Je'neu Sancrea (after turning in the drop-only Damp Note)", location = "Blackfathom Tide Priestess, outside instance", notes = "Starts from a low-drop-rate Damp Note.", prereqs = { { name = "Allegiance to the Old Gods", id = 6564 } } },
      -- Alliance
      { name = "Knowledge in the Deeps", id = 971, level = 10, faction = "Alliance", giver = "Gerrig Bonegrip", location = "Ironforge, Forlorn Cave", coords = "50, 5" },
      { name = "Researching the Corruption", id = 1275, level = 18, faction = "Alliance", giver = "Gershala Nightwhisper", location = "Darkshore, Auberdine", coords = "38, 43" },
      { name = "Twilight Falls", id = 1199, level = 20, faction = "Alliance", giver = "Argent Guard Manados", location = "Darnassus, Craftsman's Terrace", coords = "55, 24" },
      { name = "In Search of Thaelrid", id = 1198, level = 18, faction = "Alliance", giver = "Dawnwatcher Shaedlass", location = "Darnassus, Craftsman's Terrace", coords = "55, 24", notes = "Prerequisite to Blackfathom Villainy." },
      { name = "Blackfathom Villainy", id = 1200, level = 18, faction = "Alliance", giver = "Argent Guard Thaelrid", location = "Blackfathom Deeps, alcove SW of Ghamoo-ra", notes = "Requires In Search of Thaelrid." },
      -- Both (Neutral, class-restricted)
      { name = "The Orb of Soran'ruk", id = 1740, level = 20, faction = "Neutral", giver = "Doan Karhan", location = "The Barrens, near Camp Taurajo", coords = "49, 57", classOnly = "WARLOCK", notes = "Warlock only." },
      { name = "The Test of Righteousness", id = 1806, level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", classOnly = "PALADIN", notes = "Paladin only." },
    },
  },

  {
    name = "The Stockades",
    aliases = { "The Stockade", "The Stockades" },
    levels = { hard = 22, medium = 24, atLevel = 26, easy = 30 },
    quests = {
      { name = "Quell The Uprising", id = 387, level = 22, faction = "Alliance", giver = "Warden Thelwater", location = "Stormwind, outside Stockades", coords = "41, 58" },
      { name = "The Color of Blood", id = 388, level = 22, faction = "Alliance", giver = "Nikova Raskol (patrols)", location = "The Stockades, Old Town" },
      { name = "Crime and Punishment", id = 377, level = 22, faction = "Alliance", giver = "Councilman Millstipe", location = "Duskwood, Darkshire", coords = "42, 47" },
      { name = "What Comes Around...", id = 386, level = 22, faction = "Alliance", giver = "Guard Berton", location = "Redridge Mountains, Lakeshire", coords = "26, 46" },
      { name = "The Fury Runs Deep", id = 378, level = 25, faction = "Alliance", giver = "Motley Garmason", location = "Wetlands, Dun Modr", coords = "49, 18", notes = "Requires The Dark Iron War.", prereqs = { { name = "The Dark Iron War", id = 303 } } },
      { name = "The Stockade Riots", id = 391, level = 16, faction = "Alliance", giver = "Warden Thelwater", location = "Stormwind, outside Stockades", coords = "41, 58", prereqs = { { name = "The Unsent Letter", id = 373 } } },
    },
  },

  {
    name = "Gnomeregan",
    aliases = { "Gnomeregan" },
    levels = { hard = 25, medium = 30, atLevel = 33, easy = 38 },
    keyNote = "At least one player must have the Workshop Key to open the back door (Lockpicking 150 also works).",
    quests = {
      { name = "Rig Wars", id = 2841, level = 25, faction = "Horde", giver = "Nogg", location = "Orgrimmar, Valley of Honor", coords = "76, 25" },
      { name = "Chief Engineer Scooty", id = 2842, level = 20, faction = "Horde", giver = "Sovik", location = "Orgrimmar, Valley of Honor", coords = "76, 25", notes = "Must pick up Rig Wars first.", prereqs = { { name = "Rig Wars", id = 2841 } } },
      { name = "Gnomer-gooooone!", id = 2843, level = 20, faction = "Horde", giver = "Scooty", location = "Stranglethorn Vale, Booty Bay", coords = "27, 77" },
      { name = "Save Techbot's Brain!", id = 2922, level = 20, faction = "Alliance", giver = "Tinkmaster Overspark", location = "Ironforge, Tinkertown", coords = "69, 50" },
      { name = "Gyrodrillmatic Excavationators", id = 2928, level = 20, faction = "Alliance", giver = "Shoni the Shilent", location = "Stormwind, Dwarven Quarter", coords = "55, 12" },
      { name = "Essential Artificials", id = 2924, level = 24, faction = "Alliance", giver = "Klockmort Spannerspan", location = "Ironforge, Tinkertown", coords = "47, 64" },
      { name = "Data Rescue", id = 2930, level = 25, faction = "Alliance", giver = "Master Mechanic Castpipe", location = "Ironforge, Tinkertown", coords = "69, 48" },
      { name = "The Grand Betrayal", id = 2929, level = 25, faction = "Alliance", giver = "High Tinker Mekkatorque", location = "Ironforge, Tinkertown", coords = "68, 49" },
      { name = "Gnogaine", id = 2926, level = 20, faction = "Neutral", giver = "Ozzie Togglevolt", location = "Dun Morogh, Kharanos", coords = "45, 49" },
      { name = "The Only Cure is More Green Glow", id = 2962, level = 20, faction = "Neutral", giver = "Ozzie Togglevolt", location = "Dun Morogh, Kharanos", coords = "45, 49", notes = "Complete Gnogaine first.", prereqs = { { name = "Gnogaine", id = 2926 } } },
      { name = "The Sparklematic 5200!", id = { 2951, 2952, 4601, 4602, 4605, 4606 }, level = 25, faction = "Neutral", giver = "Needs Grime-Encrusted Object", location = "Gnomeregan, the Sparklematic 5200", notes = "The game hands out one of several interchangeable quest IDs for this action; id is a list, not a single ID (see Core.lua)." },
      { name = "A Fine Mess", id = 2904, level = 20, faction = "Neutral", giver = "Escort quest", location = "Gnomeregan, room right of Clean Room", notes = "Escort Kernobee." },
      { name = "Grime-Encrusted Ring", id = 2945, level = 28, faction = "Neutral", giver = "Drop: Grime-Encrusted Ring", location = "Gnomeregan", notes = "Starts Return of the Ring.", dungeonDrop = true },
    },
  },

  {
    name = "Razorfen Kraul",
    aliases = { "Razorfen Kraul" },
    levels = { hard = 25, medium = 28, atLevel = 31, easy = 34 },
    quests = {
      { name = "A Vengeful Fate", id = 1102, level = 29, faction = "Horde", giver = "Auld Stonespire", location = "Thunder Bluff, near Main Lift", coords = "37, 29" },
      { name = "Going, Going, Guano!", id = 1109, level = 30, faction = "Horde", giver = "Master Apothecary Faranell", location = "Undercity, The Apothecarium", coords = "48, 69", notes = "Prerequisite for the Scarlet Monastery quest Hearts of Zeal." },
      { name = "An Unholy Alliance", id = 6522, level = 28, faction = "Neutral", giver = "Drop: Small Scroll from Charlga Razorflank", location = "Razorfen Kraul", notes = "Prerequisite for the Razorfen Downs quest of the same name.", dungeonDrop = true },
      { name = "The Crone of the Kraul", id = 1101, level = 29, faction = "Neutral", giver = "Falfindel Waywarder", location = "Feralas, The Lower Wilds", coords = "89, 46", notes = "Complete Lonebrow's Journal first.", prereqs = { { name = "Lonebrow's Journal", id = 1100 } } },
      { name = "Mortality Wanes", id = 1142, level = 25, faction = "Neutral", giver = "Heralath Fallowbrook", location = "Razorfen Kraul, behind main boss" },
      { name = "Blueleaf Tubers", id = 1221, level = 20, faction = "Neutral", giver = "Mebok Mizzyrix", location = "The Barrens, Ratchet", coords = "62, 37", notes = "Quest items are next to Mizzyrix." },
      { name = "Willix the Importer", id = 1144, level = 22, faction = "Neutral", giver = "Willix the Importer", location = "Razorfen Kraul, tent near final boss", notes = "Escort quest." },
    },
  },

  {
    name = "Scarlet Monastery",
    aliases = { "Scarlet Monastery" },
    levels = { hard = 26, medium = 32, atLevel = 37, easy = 45 },
    keyNote = "At least one player must have The Scarlet Key to open both the Armory and Cathedral wings (Lockpicking 175 also works).",
    quests = {
      -- All Wings
      { name = "Into The Scarlet Monastery", id = 1048, level = 33, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "56, 92" },
      { name = "In the Name of the Light", id = 1053, level = 34, faction = "Alliance", giver = "Raleigh the Devout", location = "Hillsbrad Foothills, Southshore", coords = "51, 58", prereqs = { { name = "Brother Anton", id = 6141 }, { name = "Down the Scarlet Path", id = 261 }, { name = "Down the Scarlet Path", id = 1052 } } },
      -- Graveyard
      { name = "Vorrel's Revenge", id = 1051, level = 25, faction = "Neutral", giver = "Vorrel Sengutz", location = "Scarlet Monastery, Graveyard" },
      { name = "Hearts of Zeal", id = 1113, level = 30, faction = "Horde", giver = "Master Apothecary Faranell", location = "Undercity, The Apothecarium", coords = "48, 69", notes = "Requires Going, Going, Guano! (Razorfen Kraul) first.", prereqs = { { name = "Going, Going, Guano!", id = 1109 } } },
      -- Library
      { name = "Compendium of the Fallen", id = 1049, level = 28, faction = "Horde", giver = "Sage Truthseeker", location = "Thunder Bluff, First Rise", coords = "36, 26", notes = "Undead cannot pick up this quest." },
      { name = "Test of Lore", id = 1160, level = 25, faction = "Horde", giver = "Parqual Fintallas", location = "Undercity, The Apothecarium", coords = "57, 65", prereqs = { { name = "Test of Faith", id = 1149 }, { name = "Test of Endurance", id = 1150 }, { name = "Test of Strength", id = 1151 }, { name = "Test of Lore", id = 1152 }, { name = "Test of Lore", id = 1154 }, { name = "Test of Lore", id = 6627 }, { name = "Test of Lore", id = 1159 } } },
      { name = "Mythology of the Titans", id = 1050, level = 28, faction = "Alliance", giver = "Librarian Mae Paledust", location = "Ironforge, Hall of Explorers", coords = "75, 12" },
      { name = "Rituals of Power", id = 1951, level = 30, faction = "Neutral", giver = "Magus Tirth", location = "Thousand Needles, Shimmering Flats Raceway", coords = "78, 75", classOnly = "MAGE", notes = "Mage only.", prereqs = { { name = "Journey to the Marsh", id = 1947 }, { name = "Hidden Secrets", id = 1949 }, { name = "Get the Scoop", id = 1950 } } },
    },
  },

  {
    name = "Razorfen Downs",
    aliases = { "Razorfen Downs" },
    levels = { hard = 35, medium = 37, atLevel = 39, easy = 44 },
    quests = {
      { name = "Bring the End", id = 3341, level = 37, faction = "Horde", giver = "Andrew Brownell", location = "Undercity, Magic Quarter", coords = "74, 33" },
      { name = "An Unholy Alliance", id = 6521, level = 28, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "36, 26", notes = "Requires An Unholy Alliance from Razorfen Kraul first.", prereqs = { { name = "An Unholy Alliance", id = 6522 } } },
      { name = "Bring the Light", id = 3636, level = 39, faction = "Alliance", giver = "Archbishop Benedictus", location = "Stormwind, Cathedral", coords = "39, 27" },
      { name = "A Host of Evil", id = 6626, level = 28, faction = "Neutral", giver = "Myriam Moonsinger", location = "The Barrens, outside instance portal", coords = "49, 95" },
      { name = "Scourge of the Downs", id = 3523, level = 32, faction = "Neutral", giver = "Belnistrasz", location = "Razorfen Downs, Murder Pens", notes = "Entire party should complete before picking up the next quest." },
      { name = "Extinguishing the Idol", id = 3525, level = 32, faction = "Neutral", giver = "Belnistrasz", location = "Razorfen Downs, Murder Pens", notes = "Escort quest. Entire party must finish Scourge of the Downs first or they won't get credit.", prereqs = { { name = "Scourge of the Downs", id = 3523 } } },
    },
  },

  {
    name = "Uldaman",
    aliases = { "Uldaman" },
    levels = { hard = 37, medium = 40, atLevel = 42, easy = 47 },
    quests = {
      { name = "Reclaimed Treasures", id = 2342, level = 33, faction = "Horde", giver = "Patrick Garrett", location = "Undercity, Center", coords = "62, 48" },
      { name = "Uldaman Reagent Run", id = 2202, level = 36, faction = "Horde", giver = "Jarkal Mossmeld", location = "Badlands, Kargath", coords = "3, 46", notes = "Complete Badlands Reagent Run first.", prereqs = { { name = "Badlands Reagent Run", id = 2258 } } },
      { name = "Necklace Recovery", id = 2283, level = 37, faction = "Neutral", giver = "Drop: Shattered Necklace from Shadowforge/Shadowvault mobs", location = "Badlands, outside Uldaman instance", notes = "Drop-only." },
      { name = "Reclaimed Treasures", id = 1360, level = 33, faction = "Alliance", giver = "Krom Stoutarm", location = "Ironforge, Hall of Explorers", coords = "74, 9" },
      { name = "The Lost Dwarves", id = 2398, level = 35, faction = "Alliance", giver = "Prospector Stormpike", location = "Ironforge, Hall of Explorers", coords = "75, 12" },
      { name = "The Hidden Chamber", id = 2240, level = 35, faction = "Alliance", giver = "Baelog's Journal", location = "Uldaman, Lost Dwarves area", notes = "Complete The Lost Dwarves first.", prereqs = { { name = "The Lost Dwarves", id = 2398 } } },
      { name = "Uldaman Reagent Run", id = 17, level = 38, faction = "Alliance", giver = "Ghak Healtouch", location = "Loch Modan, Thelsamar", coords = "37, 49", notes = "Complete Badlands Reagent Run first.", prereqs = { { name = "Badlands Reagent Run", id = 2500 } } },
      { name = "Agmond's Fate", id = 704, level = 33, faction = "Alliance", giver = "Prospector Ironband", location = "Loch Modan, Ironband's Excavation Site", coords = "65, 65", prereqs = { { name = "Ironband Wants You!", id = 707 }, { name = "Find Agmond", id = 738 }, { name = "Murdaloc", id = 739 } } },
      { name = "The Lost Tablets of Will", id = 1139, level = 30, faction = "Alliance", giver = "Advisor Belgrum", location = "Ironforge, Hall of Explorers", coords = "77, 9", prereqs = { { name = "A Sign of Hope", id = 720 }, { name = "A Sign of Hope", id = 721 }, { name = "Amulet of Secrets", id = 722 }, { name = "Prospect of Faith", id = 723 }, { name = "Prospect of Faith", id = 724 }, { name = "Passing Word of a Threat", id = 725 }, { name = "Passing Word of a Threat", id = 726 }, { name = "An Ambassador of Evil", id = 762 } } },
      { name = "The Shattered Necklace", id = 2198, level = 37, faction = "Neutral", giver = "Drop: Shattered Necklace from Shadowforge/Shadowvault mobs", location = "Badlands, outside Uldaman instance", notes = "Drop-only." },
      { name = "Power Stones", id = 2418, level = 30, faction = "Neutral", giver = "Rigglefuzz", location = "Badlands, Central", coords = "42, 52" },
      { name = "Solution to Doom", id = 709, level = 30, faction = "Neutral", giver = "Theldurin the Lost", location = "Badlands, Southern", coords = "51, 76" },
      { name = "The Platinum Discs", id = 2278, level = 40, faction = "Neutral", giver = "Item pickup", location = "Uldaman, room after Archaedas" },
      { name = "Power in Uldaman", id = 1956, level = 35, faction = "Neutral", giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57", classOnly = "MAGE", notes = "Mage only.", prereqs = { { name = "Return to the Marsh", id = 1953 }, { name = "The Infernal Orb", id = 1954 }, { name = "The Exorcism", id = 1955 } } },
    },
  },

  {
    name = "Zul'Farrak",
    aliases = { "Zul'Farrak" },
    levels = { hard = 40, medium = 42, atLevel = 44, easy = 50 },
    keyNote = "At least one player must have the Mallet of Zul'Farrak to summon Gahz'rilla, the end boss.",
    quests = {
      { name = "The Spider God", id = 2936, level = 40, faction = "Horde", giver = "Master Gadrin", location = "Durotar, Sen'jin Village", coords = "56, 74", prereqs = { { name = "Venom Bottles", id = 2933 }, { name = "Undamaged Venom Sac", id = 2934 }, { name = "Consult Master Gadrin", id = 2935 } } },
      { name = "Nekrum's Medallion", id = 2991, level = 40, faction = "Alliance", giver = "Thadius Grimshade", location = "Blasted Lands, Nethergarde Keep", coords = "66, 19", prereqs = { { name = "Witherbark Cages", id = 2988 }, { name = "The Altar of Zul", id = 2989 }, { name = "Thadius Grimshade", id = 2990 } } },
      { name = "Divino-matic Rod", id = 2768, level = 40, faction = "Neutral", giver = "Chief Engineer Bilgewhizzle", location = "Tanaris, Gadgetzan", coords = "52, 28" },
      { name = "Scarab Shells", id = 2865, level = 40, faction = "Neutral", giver = "Tran'rek", location = "Tanaris, Gadgetzan", coords = "51, 26" },
      { name = "Troll Temper", id = 3042, level = 40, faction = "Neutral", giver = "Trenton Lighthammer", location = "Tanaris, Gadgetzan", coords = "51, 28" },
      { name = "Tiara of the Deep", id = 2846, level = 40, faction = "Neutral", giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57" },
      { name = "Gahz'rilla", id = 2770, level = 40, faction = "Neutral", giver = "Wizzle Brassbolts", location = "Thousand Needles, Shimmering Flats", coords = "78, 77", notes = "Needs the Mallet of Zul'Farrak (drop from Qiaga the Keeper, Hinterlands)." },
      { name = "The Prophecy of Mosh'aru", id = 3527, level = 40, faction = "Neutral", giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22", notes = "Complete Screecher Spirits first.", prereqs = { { name = "Screecher Spirits", id = 3520 } } },
    },
  },

  {
    name = "Maraudon",
    aliases = { "Maraudon" },
    levels = { hard = 41, medium = 44, atLevel = 46, easy = 50 },
    keyNote = "At least one player must have the Scepter of Celebras to open the portal to Earth Song Falls (skips the orange/purple sides).",
    quests = {
      { name = "Shadowshard Fragments", id = 7068, level = 39, faction = "Horde", giver = "Uthel'nay", location = "Orgrimmar, Valley of Spirits", coords = "39, 86" },
      { name = "Vyletongue Corruption", id = 7029, level = 41, faction = "Horde", giver = "Vark Battlescar", location = "Desolace, Shadowprey Village", coords = "23, 70" },
      { name = "Corruption of Earth and Seed", id = 7064, level = 45, faction = "Horde", giver = "Selendra", location = "Desolace, S. of Shadowprey Village", coords = "26, 77" },
      { name = "Shadowshard Fragments", id = 7070, level = 39, faction = "Alliance", giver = "Archmage Tervosh", location = "Dustwallow Marsh, Theramore", coords = "66, 49" },
      { name = "Vyletongue Corruption", id = 7041, level = 41, faction = "Alliance", giver = "Talendria", location = "Desolace, Nijel's Point", coords = "68, 8" },
      { name = "Corruption of Earth and Seed", id = 7065, level = 45, faction = "Alliance", giver = "Keeper Marandis", location = "Desolace, Nijel's Point", coords = "63, 10" },
      { name = "Twisted Evils", id = 7028, level = 41, faction = "Neutral", giver = "Willow", location = "Desolace, SE of Thunderaxe Fortress", coords = "62, 39" },
      { name = "Legends of Maraudon", id = 7044, level = 41, faction = "Neutral", giver = "Cavindra", location = "Maraudon, Orange side, outside instance" },
      { name = "Seed of Life", id = 7066, level = 39, faction = "Neutral", giver = "Zaetar's Spirit", location = "Maraudon, middle ring, after killing Princess Theradras" },
      { name = "The Pariah's Instructions", id = 7067, level = 39, faction = "Neutral", giver = "Centaur Pariah (patrols)", location = "Desolace, south of Mannoroc Coven", coords = "48.4, 87.0" },
      { name = "The Scepter of Celebras", id = 7046, level = 41, faction = "Neutral", giver = "Celebras the Redeemed", location = "Maraudon, Purple side", notes = "Complete Legends of Maraudon first.", prereqs = { { name = "Legends of Maraudon", id = 7044 } } },
    },
  },

  {
    name = "Sunken Temple",
    aliases = { "Temple of Atal'Hakkar", "The Sunken Temple" },
    levels = { hard = 46, medium = 49, atLevel = 51, easy = 54 },
    keyNote = "At least one player must have Yeh'kinya's Scroll to summon the Avatar of Hakkar. Also hosts a per-class Sunken Temple class quest.",
    quests = {
      { name = "The Temple of Atal'Hakkar", id = 1445, level = 38, faction = "Horde", giver = "Fel'zerul", location = "Swamp of Sorrows, Stonard", coords = "47, 54", prereqs = { { name = "Pool of Tears", id = 1424 }, { name = "The Atal'ai Exile", id = 1429 }, { name = "Return to Fel'Zerul", id = 1444 } } },
      { name = "Zapper Fuel", id = 4146, level = 47, faction = "Neutral", giver = "Liv Rizzlefix", location = "The Barrens, Ratchet", coords = "62, 38", prereqs = { { name = "Larion and Muigin", id = 4145 }, { name = "Marvon's Workshop", id = 4147 } } },
      { name = "Haze of Evil", id = 4143, level = 47, faction = "Neutral", giver = "Gregan Brewspewer", location = "Feralas, Twin Colossals", coords = "45, 25", notes = "Distinct chain from Zapper Fuel despite the similar breadcrumb name.", prereqs = { { name = "Muigin and Larion", id = 4141 }, { name = "A Visit to Gregan", id = 4142 } } },
      { name = "Into The Temple of Atal'Hakkar", id = 1475, level = 38, faction = "Alliance", giver = "Brohann Caskbelly", location = "Stormwind, Dwarven District", coords = "64, 21", prereqs = { { name = "In Search of The Temple", id = 1448 }, { name = "To The Hinterlands", id = 1449 }, { name = "Gryphon Master Talonaxe", id = 1450 }, { name = "Rhapsody Shindigger", id = 1451 }, { name = "Rhapsody's Kalimdor Kocktail", id = 1452 }, { name = "Rhapsody's Tale", id = 1469 } } },
      { name = "Jammal'an the Prophet", id = 1446, level = 38, faction = "Neutral", giver = "Atal'ai Exile", location = "Hinterlands, spider area SW of Altar of Zul", coords = "33, 75" },
      { name = "The Essence of Eranikus", id = 3373, level = 48, faction = "Neutral", giver = "Drop: Essence of Eranikus", location = "Sunken Temple", dungeonDrop = true },
      { name = "Into the Depths", id = 3446, level = 46, faction = "Neutral", giver = "Marvon Rivetseeker", location = "Tanaris, S. of Gadgetzan", coords = "52, 45", notes = "Shares this chain with Secret of the Circle.", prereqs = { { name = "The Sunken Temple", id = { 3380, 3445 } }, { name = "The Stone Circle", id = 3444 } } },
      { name = "Secret of the Circle", id = 3447, level = 46, faction = "Neutral", giver = "Marvon Rivetseeker", location = "Tanaris, S. of Gadgetzan", coords = "52, 45", notes = "Shares this chain with Into the Depths.", prereqs = { { name = "The Sunken Temple", id = { 3380, 3445 } }, { name = "The Stone Circle", id = 3444 } } },
      { name = "The God Hakkar", id = 3528, level = 40, faction = "Neutral", giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22", prereqs = { { name = "Screecher Spirits", id = 3520 }, { name = "The Prophecy of Mosh'aru", id = 3527 }, { name = "The Ancient Egg", id = 4787 } } },
    },
  },

  {
    name = "Blackrock Depths",
    aliases = { "Blackrock Depths" },
    levels = { hard = 50, medium = 52, atLevel = 55, easy = 60 },
    keyNote = "At least one player must have the Shadowforge Key to open the Shadowforge Doors (Lockpicking 280 also works).",
    quests = {
      -- Horde
      { name = "KILL ON SIGHT: Dark Iron Dwarves", id = 4081, level = 48, faction = "Horde", giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47" },
      { name = "Lost Thunderbrew Recipe", id = 4134, level = 50, faction = "Horde", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Breadcrumb: Vivian Lagrave in Undercity for easy XP." },
      { name = "KILL ON SIGHT: High Ranking Dark Iron Officials", id = 4082, level = 50, faction = "Horde", giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47", notes = "Complete KILL ON SIGHT: Dark Iron Dwarves first.", prereqs = { { name = "KILL ON SIGHT: Dark Iron Dwarves", id = 4081 } } },
      { name = "The Rise of the Machines", id = 4063, level = 52, faction = "Horde", giver = "Lotwil Veriatus", location = "Badlands, Eastern", coords = "25, 44", prereqs = { { name = "The Rise of the Machines", id = 4061 }, { name = "The Rise of the Machines", id = 4062 } } },
      { name = "Disharmony of Flame", id = 3906, level = 48, faction = "Horde", giver = "Thunderheart", location = "Badlands, Kargath", coords = "3.6, 48.0" },
      { name = "Disharmony of Fire", id = 3907, level = 48, faction = "Horde", giver = "Thunderheart", location = "Badlands, Kargath", coords = "3.6, 48.0", notes = "Opens after Disharmony of Flame.", prereqs = { { name = "Disharmony of Flame", id = 3906 } } },
      { name = "Commander Gor'shak", id = 3981, level = 48, faction = "Horde", giver = "Galamav the Marksman", location = "Badlands, Kargath", coords = "6, 47", notes = "Opens after Disharmony of Flame.", prereqs = { { name = "Disharmony of Flame", id = 3906 } } },
      { name = "The Last Element", id = { 7201, 3911 }, level = 48, faction = "Horde", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Opens after Disharmony of Flame.", prereqs = { { name = "Disharmony of Flame", id = 3906 } } },
      { name = "Operation: Death to Angerforge", id = 4132, level = 52, faction = "Horde", giver = "Warlord Goretooth", location = "Badlands, Kargath", coords = "6, 47", notes = "Includes a long escort (Grark Lorkrub).", prereqs = { { name = "KILL ON SIGHT: Dark Iron Dwarves", id = 4081 }, { name = "KILL ON SIGHT: High Ranking Dark Iron Officials", id = 4082 }, { name = "Grark Lorkrub", id = 4122 }, { name = "Precarious Predicament", id = 4121 } } },
      { name = "The Royal Rescue", id = 4003, level = 48, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "32, 38", prereqs = { { name = "Commander Gor'shak", id = 3981 }, { name = "What Is Going On?", id = 3982 }, { name = "What Is Going On?", id = 4001 }, { name = "The Eastern Kingdoms", id = 4002 } } },
      -- Alliance
      { name = "Overmaster Pyron", id = 4262, level = 48, faction = "Alliance", giver = "Jalinda Sprig", location = "Burning Steppes, Morgan's Vigil", coords = "85, 70" },
      { name = "Incendius!", id = 4263, level = 48, faction = "Alliance", giver = "Jalinda Sprig", location = "Burning Steppes, Morgan's Vigil", coords = "85, 70", notes = "Complete Overmaster Pyron first.", prereqs = { { name = "Overmaster Pyron", id = 4262 } } },
      { name = "The Good Stuff", id = 4286, level = 50, faction = "Alliance", giver = "Oralius", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68" },
      { name = "Hurley Blackbreath", id = 4126, level = 50, faction = "Alliance", giver = "Ragnar Thunderbrew", location = "Dun Morogh, Kharanos", coords = "46, 52" },
      { name = "Kharan Mighthammer", id = 4341, level = 50, faction = "Alliance", giver = "King Magni Bronzebeard", location = "Ironforge, Throne Room", coords = "39, 56", prereqs = { { name = "The Smoldering Ruins of Thaurissan", id = 3702 }, { name = "The Smoldering Ruins of Thaurissan", id = 3701 } } },
      { name = "The Fate of the Kingdom", id = 4362, level = 50, faction = "Alliance", giver = "King Magni Bronzebeard", location = "Ironforge, Throne Room", coords = "39, 56", prereqs = { { name = "Kharan Mighthammer", id = 4341 } } },
      { name = "Marshal Windsor", id = 4241, level = 48, faction = "Alliance", giver = "Marshal Maxwell", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68", prereqs = { { name = "Dragonkin Menace", id = 4182 }, { name = "The True Masters", id = 4224 }, { name = "The True Masters", id = 4183 }, { name = "The True Masters", id = 4184 }, { name = "The True Masters", id = 4185 }, { name = "The True Masters", id = 4186 }, { name = "The True Masters", id = 4223 } } },
      { name = "Jail Break!", id = 4322, level = 50, faction = "Alliance", giver = "Marshal Windsor", location = "Blackrock Depths, Prison Cell", prereqs = { { name = "Dragonkin Menace", id = 4182 }, { name = "The True Masters", id = 4224 }, { name = "The True Masters", id = 4183 }, { name = "The True Masters", id = 4184 }, { name = "The True Masters", id = 4185 }, { name = "The True Masters", id = 4186 }, { name = "The True Masters", id = 4223 }, { name = "Marshal Windsor", id = 4241 }, { name = "Abandoned Hope", id = 4242 }, { name = "A Crumpled Up Note", id = 4264 }, { name = "A Shred of Hope", id = 4282 } } },
      -- Neutral
      { name = "Ribbly Screwspigot", id = 4136, level = 50, faction = "Neutral", giver = "Yuka Screwspigot", location = "Burning Steppes, Flame Crest", coords = "66, 21", notes = "Breadcrumb: Yuka Screwspigot in Steamwheedle Port for easy XP." },
      { name = "The Heart of the Mountain", id = 4123, level = 50, faction = "Neutral", giver = "Maxwort Uberglint", location = "Burning Steppes, Flame Crest", coords = "65, 23" },
      { name = "Attunement to the Core", id = { 7848, 7487 }, level = 55, faction = "Neutral", giver = "Lothos Riftwaker", location = "Blackrock Mountain" },
      { name = "Dark Iron Legacy", id = 3802, level = 48, faction = "Neutral", giver = "Franclorn Forgewright", location = "Blackrock Mountain, structure in the middle", notes = "NPC only visible while you are dead.", prereqs = { { name = "Dark Iron Legacy", id = 3801 } } },
      { name = "The Love Potion", id = 4201, level = 50, faction = "Neutral", giver = "Mistress Nagmara", location = "Blackrock Depths, Grim Guzzler" },
      { name = "A Taste of Flame", id = 4024, level = 52, faction = "Neutral", giver = "Cyrus Therepentous", location = "Burning Steppes, cave in NE", coords = "95, 31", notes = "Chain of 11 starting with Divine Retribution (only the last 2 local steps are ID-tracked below).", prereqs = { { name = "A Taste of Flame", id = { 4022, 4023 } } } },
    },
  },

  {
    name = "Dire Maul: East (Warpwood Quarter)",
    aliases = { "Dire Maul" },
    levels = { hard = 52, medium = 54, atLevel = 56, easy = 60 },
    keyNote = "At least one player must have the Crescent Key to open the West and North wings of Dire Maul (Lockpicking 300 also works).",
    quests = {
      { name = "Lethtendris's Web", id = 7489, level = 54, faction = "Horde", giver = "Talo Thornhoof", location = "Feralas, Camp Mojache", coords = "76, 43" },
      { name = "Lethtendris's Web", id = 7488, level = 54, faction = "Alliance", giver = "Latronicus Moonspear", location = "Feralas, Feathermoon Stronghold", coords = "30, 46" },
      { name = "Pusillin and the Elder Azj'Tordin", id = 7441, level = 54, faction = "Neutral", giver = "Azj'Tordin", location = "Feralas, Lariss Pavilion", coords = "76, 37" },
      { name = "Shards of the Felvine", id = 5526, level = 56, faction = "Neutral", giver = "Rabine Saturna", location = "Moonglade, Nighthaven", coords = "51, 45", notes = "Complete A Reliquary of Purity from the same NPC and explore all of Dire Maul first.", prereqs = { { name = "A Reliquary of Purity", id = 5527 } } },
      { name = "Arcane Refreshment", id = 7463, level = 60, faction = "Neutral", giver = "Lorekeeper Lydros", location = "Dire Maul, Library", classOnly = "MAGE", notes = "Mage only." },
    },
  },

  {
    name = "Dire Maul: West (Capital Gardens)",
    aliases = { "Dire Maul" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "The Madness Within", id = 7461, level = 56, faction = "Neutral", giver = "Shen'dralar Ancient", location = "Dire Maul, West, second floor" },
      { name = "Foror's Compendium", id = 7507, level = 60, faction = "Neutral", giver = "Nostro's Compendium of Dragon Slaying", location = "Dire Maul", notes = "Rare drop, or looted from A Dusty Tome. Not BoP; used to craft a BoP tanking sword (item #18348).", dungeonDrop = true },
    },
  },

  {
    name = "Dire Maul: North (Gordok Commons)",
    aliases = { "Dire Maul" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "Elven Legends", id = 7481, level = 54, faction = "Horde", giver = "Sage Korolusk", location = "Feralas, Camp Mojache", coords = "74, 43", notes = "Eligibility for Libram of Protection/Rapidity/Focus." },
      { name = "Elven Legends", id = 7482, level = 54, faction = "Alliance", giver = "Scholar Runethorn", location = "Feralas, Feathermoon Stronghold", coords = "31, 43", notes = "Eligibility for Libram of Protection/Rapidity/Focus." },
      { name = "Free Knot!", id = { 5525, 7429 }, level = 56, faction = "Neutral", giver = "Knot Thimblejack", location = "Dire Maul, North", notes = "Cannot be completed during a Tribute Run unless a party member already has the Gordok Shackle Key. One of the two IDs is the repeatable variant." },
      { name = "The Gordok Ogre Suit", id = { 5518, 5519 }, level = 56, faction = "Neutral", giver = "Knot Thimblejack", location = "Dire Maul, North" },
      { name = "The Gordok Taste Test", id = 5528, level = 56, faction = "Neutral", giver = "Stomper Kreeg", location = "Dire Maul, North", notes = "Can only be picked up after completing a Tribute Run." },
      { name = "Unfinished Gordok Business", id = { 7703, 1318 }, level = 56, faction = "Neutral", giver = "Captain Kromcrush", location = "Dire Maul, North", notes = "Requires one Tribute Run, then a second after killing Prince Tortheldrin and looting the Gauntlet of Gordok Might." },
    },
  },

  {
    name = "Lower Blackrock Spire",
    aliases = { "Blackrock Spire", "Lower Blackrock Spire" },
    levels = { hard = 55, medium = 56, atLevel = 60 },
    quests = {
      { name = "The Pack Mistress", id = 4724, level = 55, faction = "Neutral", giver = "Galamav the Marksman", location = "Badlands, Kargath", coords = "6, 47" },
      { name = "Operative Bijou", id = 4981, level = 55, faction = "Horde", giver = "Lexlort", location = "Badlands, Kargath", coords = "5, 47", notes = "Leads to Bijou's Belongings inside LBRS." },
      { name = "Warlord's Command", id = 4903, level = 55, faction = "Neutral", giver = "Warlord Goretooth", location = "Badlands, Kargath", coords = "5, 47" },
      { name = "Put Her Down", id = 4701, level = 55, faction = "Neutral", giver = "Helendis Riverhorn", location = "Burning Steppes, Morgan's Vigil", coords = "65, 69" },
      { name = "General Drakkisath's Command", id = 5089, level = 55, faction = "Neutral", giver = "Drop from Overlord Wyrmthalak", location = "Blackrock Spire, Lower", dungeonDrop = true },
      { name = "Bijou's Belongings", id = 4982, level = 55, faction = "Horde", giver = "Bijou", location = "Blackrock Spire, Lower", prereqs = { { name = "Operative Bijou", id = 4981 } } },
      { name = "Bijou's Belongings", id = 5001, level = 55, faction = "Alliance", giver = "Bijou", location = "Blackrock Spire, Lower" },
      { name = "En-Ay-Es-Tee-Why", id = 4862, level = 55, faction = "Neutral", giver = "Kibler", location = "Burning Steppes, Flame Crest", coords = "65, 21" },
      { name = "Kibler's Exotic Pets", id = 4729, level = 55, faction = "Neutral", giver = "Kibler", location = "Burning Steppes, Flame Crest", coords = "65, 21" },
      { name = "Mother's Milk", id = 4866, level = 55, faction = "Neutral", giver = "Ragged John", location = "Burning Steppes, Flame Crest", coords = "65, 23" },
      { name = "Seal of Ascension", id = 4743, level = 57, faction = "Neutral", giver = "Drop: Unadorned Seal of Ascension + 3 Gemstones", location = "Blackrock Spire, Lower", dungeonDrop = true, prereqs = { { name = "Seal of Ascension", id = 4742 } } },
      { name = "Urok Doomhowl", id = 4867, level = 55, faction = "Neutral", giver = "Warosh (patrols)", location = "Blackrock Spire, Lower, near beginning" },
      { name = "The Final Tablets", id = 4788, level = 40, faction = "Neutral", giver = "Prospector Ironboot", location = "Tanaris, Steamwheedle Port", coords = "66, 24", prereqs = { { name = "Screecher Spirits", id = 3520 }, { name = "The Prophecy of Mosh'aru", id = 3527 }, { name = "The Ancient Egg", id = 4787 }, { name = "The God Hakkar", id = 3528 }, { name = "The Lost Tablets of Mosh'aru", id = 5065 } } },
    },
  },

  {
    name = "Scholomance",
    aliases = { "Scholomance" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player must have the Skeleton Key to open the front door in Caer Darrow.",
    quests = {
      { name = "Barov Family Fortune", id = 5341, level = 52, faction = "Horde", giver = "Alexi Barov", location = "Tirisfal Glades, The Bulwark", coords = "83, 71", notes = "May be dead due to Alliance kill quest; 30 minute spawn timer." },
      { name = "The Darkreaver Menace", id = { 7668, 8258 }, level = 58, faction = "Horde", giver = "Sagorne Creststrider", location = "Orgrimmar, Valley of Wisdom", coords = "38, 35", classOnly = "SHAMAN", notes = "Shaman only.", prereqs = { { name = "Material Assistance", id = 7667 } } },
      { name = "Barov Family Fortune", id = 5343, level = 52, faction = "Alliance", giver = "Weldon Barov", location = "Western Plaguelands, Chillwind Camp", coords = "43, 83", notes = "May be dead due to Horde kill quest; 30 minute spawn timer." },
      { name = "Plagued Hatchlings", id = 5529, level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "Healthy Dragon Scale", id = 5582, level = 55, faction = "Neutral", giver = "Drop from Plagued Hatchlings", location = "Scholomance", notes = "Repeatable for Argent Dawn rep. Complete Plagued Hatchlings first.", dungeonDrop = true, prereqs = { { name = "Plagued Hatchlings", id = 5529 } } },
      { name = "Doctor Theolen Krastinov, the Butcher", id = 5382, level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73" },
      { name = "Krastinov's Bag of Horrors", id = 5515, level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73", notes = "Complete Doctor Theolen Krastinov, the Butcher first.", prereqs = { { name = "Doctor Theolen Krastinov, the Butcher", id = 5382 } } },
      { name = "Kirtonos the Herald", id = 5384, level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73", notes = "Complete Krastinov's Bag of Horrors first; keep item #13544.", prereqs = { { name = "Krastinov's Bag of Horrors", id = 5515 } } },
      { name = "Dawn's Gambit", id = 4771, level = 57, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", prereqs = { { name = "Broodling Essence", id = 4726 }, { name = "Felnok Steelspring", id = 4808 }, { name = "Chillwind Horns", id = 4809 }, { name = "Return to Tinkee", id = 4810 }, { name = "Tinkee Steamboil", id = 4907 }, { name = "Egg Freezing", id = 4734 }, { name = "Egg Collection", id = 4735 }, { name = "Leonid Barthalomew", id = 5522 }, { name = "Betina Bigglezink", id = 5531 } } },
      { name = "The Lich, Ras Frostwhisper", id = 5466, level = 57, faction = "Neutral", giver = "Magistrate Marduke", location = "Western Plaguelands, Caer Darrow", coords = "70, 74", notes = "Must have item #13544 equipped to see Marduke.", prereqs = { { name = "Doctor Theolen Krastinov, the Butcher", id = 5382 }, { name = "Krastinov's Bag of Horrors", id = 5515 }, { name = "Kirtonos the Herald", id = 5384 }, { name = "The Human, Ras Frostwhisper", id = 5461 }, { name = "The Dying, Ras Frostwhisper", id = 5462 }, { name = "Menethil's Gift", id = 5463 }, { name = "Menethil's Gift", id = 5464 }, { name = "Soulbound Keepsake", id = 5465 } } },
    },
  },

  {
    name = "Stratholme: Live Side",
    aliases = { "Stratholme" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player needs The Scarlet Key (Live Side, Scarlet Hold) and the Key to the City (side entrance to Undead side); Lockpicking 275 also works for both.",
    quests = {
      { name = "The Great Fras Siabi", id = 5214, level = 55, faction = "Neutral", giver = "Smokey LaRue", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "80, 58", notes = "Renamed from Classic's \"The Great Ezra Grimm\" in Forever -- same quest, same giver." },
      { name = "The Archivist", id = 5251, level = 55, faction = "Neutral", giver = "Duke Nicholas Zverenhoff", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "The Restless Souls", id = 5282, level = 55, faction = "Neutral", giver = "Egan", location = "Eastern Plaguelands, Terrordale", coords = "14, 33" },
      { name = "The Medallion of Faith", id = 5122, level = 55, faction = "Neutral", giver = "Aurius", location = "Stratholme, Undead Side, inside chapel at beginning", notes = "Complete The Restless Souls (Undead side) first.", prereqs = { { name = "The Restless Souls", id = 5282 } } },
      { name = "The Truth Comes Crashing Down", id = 5262, level = 55, faction = "Neutral", giver = "Drop: Head of Balnazzar from Balnazzar", location = "Stratholme, Live Side", notes = "Complete The Archivist to be eligible.", dungeonDrop = true, prereqs = { { name = "The Archivist", id = 5251 } } },
      { name = "Of Love and Family", id = 5848, level = 52, faction = "Neutral", giver = "Artist Renfray", location = "Western Plaguelands, Caer Darrow", coords = "65, 75", notes = "Blood Tinged Skies, Carrion Grubbage, and Demon Dogs are all required, in any order.", prereqs = { { name = "Blood Tinged Skies", id = 5543 }, { name = "Carrion Grubbage", id = 5544 }, { name = "Demon Dogs", id = 5542 }, { name = "Redemption", id = 5742 }, { name = "Of Forgotten Memories", id = 5781 }, { name = "Of Lost Honor", id = 5845 } } },
    },
  },

  {
    name = "Stratholme: Undead Side",
    aliases = { "Stratholme" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "Ramstein", id = 6163, level = 56, faction = "Neutral", giver = "Nathanos Blightcaller", location = "Eastern Plaguelands, Marris Stead", coords = "26, 74", notes = "A second claimed starter, To Kill With Purpose, could not be confirmed as linking into this chain -- may be an independent breadcrumb.", prereqs = { { name = "The Ranger Lord's Behest", id = 6133 }, { name = "Duskwing, Oh How I Hate Thee...", id = 6135 } } },
      { name = "Houses of the Holy", id = 5243, level = 55, faction = "Neutral", giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57" },
      { name = "The Flesh Does Not Lie", id = 5212, level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "The Active Agent", id = 5213, level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", notes = "Complete The Flesh Does Not Lie first.", prereqs = { { name = "The Flesh Does Not Lie", id = 5212 } } },
      { name = "Aurius' Reckoning", id = 5125, level = 55, faction = "Neutral", giver = "Aurius", location = "Stratholme, Undead Side, chapel at beginning", notes = "Complete The Medallion of Faith first.", prereqs = { { name = "The Medallion of Faith", id = 5122 } } },
      { name = "Above and Beyond", id = 5263, level = 55, faction = "Neutral", giver = "Duke Nicholas Zverenhoff", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", prereqs = { { name = "The Archivist", id = 5251 }, { name = "The Truth Comes Crashing Down", id = 5262 } } },
      { name = "Menethil's Gift", id = 5463, level = 57, faction = "Neutral", giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57", prereqs = { { name = "Doctor Theolen Krastinov, the Butcher", id = 5382 }, { name = "Krastinov's Bag of Horrors", id = 5515 }, { name = "Kirtonos the Herald", id = 5384 }, { name = "The Human, Ras Frostwhisper", id = 5461 }, { name = "The Dying, Ras Frostwhisper", id = 5462 } } },
      { name = "Dead Man's Plea", id = 8945, level = 58, faction = "Neutral", giver = "Anthion Harmon", location = "Eastern Plaguelands, Stratholme Main Entrance", coords = "30, 16", notes = "Requires the Extra-Dimensional Ghost Revealer to see the quest NPC. One step (Return to Deliana for Alliance / Return to Mokvar for Horde) is faction-specific and omitted below -- Just Compensation implies it.", prereqs = { { name = "A Supernatural Device", id = { 8922, 8923 } }, { name = "The Ectoplasmic Distiller", id = 8921 }, { name = "Hunting for Ectoplasm", id = 8924 }, { name = "A Portable Power Source", id = 8925 }, { name = "A Shifty Merchant", id = 8928 }, { name = "Just Compensation", id = { 8926, 8944, 8936, 8935, 8938, 8941, 8927, 8933, 8940, 8937, 8932, 8931, 8939, 8943, 8934, 8942 } }, { name = "In Search of Anthion", id = { 8929, 8930 } } } },
    },
  },

  {
    name = "Upper Blackrock Spire",
    aliases = { "Upper Blackrock Spire", "UBRS" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player must have item #12344 to enter Upper Blackrock Spire.",
    quests = {
      { name = "The Darkstone Tablet", id = 4768, level = 57, faction = "Neutral", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Breadcrumb: Vivian Lagrave and the Darkstone Tablet in Undercity for easy XP." },
      { name = "For The Horde!", id = 4974, level = 55, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "31, 37", prereqs = { { name = "Warlord's Command", id = 4903 }, { name = "Eitrigg's Wisdom", id = 4941 } } },
      { name = "Blood of the Black Dragon Champion", id = 6602, level = 55, faction = "Horde", giver = "Rexxar (patrols)", location = "Desolace", notes = "Shares its first 3 prerequisite steps with For The Horde!.", prereqs = { { name = "Warlord's Command", id = 4903 }, { name = "Eitrigg's Wisdom", id = 4941 }, { name = "What the Wind Carries", id = 6566 }, { name = "The Champion of the Horde", id = 6567 }, { name = "The Testament of Rexxar", id = 6568 }, { name = "Oculus Illusions", id = 6569 }, { name = "Emberstrife", id = 6570 }, { name = "The Test of Skulls, Chronalis", id = 6584 }, { name = "The Test of Skulls, Scryer", id = 6582 }, { name = "The Test of Skulls, Somnus", id = 6583 }, { name = "The Test of Skulls, Axtroz", id = 6585 }, { name = "Ascension...", id = 6601 } } },
      { name = "Doomrigger's Clasp", id = 4764, level = 57, faction = "Alliance", giver = "Mayara Brightwing", location = "Burning Steppes, Morgan's Vigil", coords = "84, 69", notes = "Breadcrumb: Mayara Brightwing in Stormwind Keep for easy XP." },
      { name = "General Drakkisath's Demise", id = 5102, level = 55, faction = "Alliance", giver = "Marshal Maxwell", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68", notes = "Requires General Drakkisath's Command first.", prereqs = { { name = "General Drakkisath's Command", id = 5089 } } },
      { name = "Drakefire Amulet", id = 6502, level = 50, faction = "Neutral", giver = "Haleh", location = "Winterspring, Mazthoril", coords = "56, 49", notes = "Step on the blue rune at end of cave to spawn Haleh.", prereqs = { { name = "Dragonkin Menace", id = 4182 }, { name = "The True Masters", id = 4224 }, { name = "The True Masters", id = 4183 }, { name = "The True Masters", id = 4184 }, { name = "The True Masters", id = 4185 }, { name = "The True Masters", id = 4186 }, { name = "The True Masters", id = 4223 }, { name = "Marshal Windsor", id = 4241 }, { name = "Abandoned Hope", id = 4242 }, { name = "A Crumpled Up Note", id = 4264 }, { name = "A Shred of Hope", id = 4282 }, { name = "Jail Break!", id = 4322 }, { name = "Stormwind Rendezvous", id = 6402 }, { name = "The Great Masquerade", id = 6403 }, { name = "The Dragon's Eye", id = 6501 } } },
      { name = "Blackhand's Command", id = 7761, level = 55, faction = "Neutral", giver = "Drop from Scarshield Quartermaster", location = "Blackrock Mountain, side hallway on the way to BWL", dungeonDrop = true },
      { name = "The Matron Protectorate", id = 5160, level = 57, faction = "Neutral", giver = "Awbee", location = "Blackrock Spire, Upper, ledge in room after killing Blackhand" },
      { name = "Finkle Einhorn, At Your Service!", id = 5047, level = 57, faction = "Neutral", giver = "Pip Quickwit", location = "Blackrock Spire, Upper", notes = "Only spawns after skinning (300) The Beast with Pip Quickwit." },
      { name = "Egg Collection", id = 4735, level = 57, faction = "Neutral", giver = "Tinkee Steamboil", location = "Burning Steppes, Flame Crest", coords = "65, 23", notes = "Egg Freezing (the last prereq step) is not a second starting point.", prereqs = { { name = "Broodling Essence", id = 4726 }, { name = "Felnok Steelspring", id = 4808 }, { name = "Chillwind Horns", id = 4809 }, { name = "Return to Tinkee", id = 4810 }, { name = "Tinkee Steamboil", id = 4907 }, { name = "Egg Freezing", id = 4734 } } },
      { name = "Eye of the Emberseer", id = 6821, level = 55, faction = "Neutral", giver = "Duke Hydraxis", location = "Azshara", coords = "79, 73", notes = "Stormers and Rumblers and Poisoned Water are both required, in any order.", prereqs = { { name = "Stormers and Rumblers", id = 6805 }, { name = "Poisoned Water", id = 6804 } } },
      { name = "The Demon Forge", id = 5127, level = 55, faction = "Neutral", giver = "Lorax", location = "Winterspring, Southeast", coords = "63, 73", notes = "Blacksmiths only. Complete Lorax's Tale first. Rewards Plans: Demon Forged Breastplate.", prereqs = { { name = "Lorax's Tale", id = 5126 } } },
    },
  },
}

-- FDQ_PrereqInfo: giver/location/coords for quest.prereqs entries (see
-- CLAUDE.md "Prerequisite quests"). Keyed by the exact prereq name string
-- (or a {name=} entry's name) -- Core.lua's GetPrereqStatuses looks this up
-- per prereq so the expanded UI row can show "where do I get this" instead
-- of just a status. Kept separate from the prereqs = { "..." } arrays
-- themselves (rather than turning every one into { name=, giver=, ... }
-- tables) so this can be populated/extended without touching that syntax,
-- and so chains that reuse the same breadcrumb quest (e.g. "Badlands
-- Reagent Run") share one entry.
--
-- Populated by researching each name individually (WebSearch, since
-- Wowhead itself is unreachable from this dev environment -- see CLAUDE.md
-- "Data source"), cross-checked against this file's own already-verified
-- giver/location/coords wherever the same quest/NPC also has a full
-- Data.lua entry elsewhere (e.g. "Raptor Horns" matches "Smart Drinks"'s
-- Mebok Mizzyrix). Same Beta/Classic-backfill caveat as the rest of this
-- file applies: best-effort, not confirmed in-game.
--
-- Deliberately NOT exhaustive: some prereq names were left out rather than
-- guessed at for this giver/location DISPLAY data specifically -- conflicting
-- sources, or a faction-forked giver where a single giver/location shown here
-- would be wrong for half the playerbase. A prereq name missing here just
-- renders without the extra detail -- not a bug, just unresearched/unconfirmed.
-- Note this is separate from ID-based MATCHING (the `prereqs = { { name=, id= } }`
-- entries in FDQ_Dungeons above): every name once excluded from *this* table for
-- being faction-forked or ambiguous ("Badlands Reagent Run", "In Search of
-- Anthion", "The Sunken Temple", "Just Compensation") now matches correctly by id
-- regardless -- either a different id per using-context, or Core.lua's array-id
-- support matching any of several interchangeable/faction-variant IDs. They just
-- still lack giver/location DISPLAY data in this specific table.
FDQ_PrereqInfo = {
  ["A Portable Power Source"] = { giver = "Mux Manascrambler", location = "Tanaris, Gadgetzan" },
  ["A Reliquary of Purity"] = { giver = "Rabine Saturna", location = "Moonglade, Nighthaven" },
  ["A Shifty Merchant"] = { giver = "Mux Manascrambler", location = "Tanaris, Gadgetzan" },
  ["A Supernatural Device"] = { giver = "Mux Manascrambler", location = "Tanaris, Gadgetzan" },
  ["Altered Beings"] = { giver = "Tonga Runetotem", location = "The Barrens, Crossroads" },
  ["Betina Bigglezink"] = { giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
  ["Blood Tinged Skies"] = { giver = "Tirion Fordring", location = "Eastern Plaguelands, Light's Hope Chapel" },
  ["Broodling Essence"] = { giver = "Tinkee Steamboil", location = "Burning Steppes, Flame Crest" },
  ["Carrion Grubbage"] = { giver = "Tirion Fordring", location = "Eastern Plaguelands, Light's Hope Chapel" },
  ["Demon Dogs"] = { giver = "Tirion Fordring", location = "Eastern Plaguelands, Light's Hope Chapel" },
  ["Disharmony of Flame"] = { giver = "Thunderheart", location = "Badlands, Kargath", coords = "3.6, 48.0" },
  ["Doctor Theolen Krastinov, the Butcher"] = { giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73" },
  ["Duskwing, Oh How I Hate Thee..."] = { giver = "Nathanos Blightcaller", location = "Eastern Plaguelands, Marris Stead", coords = "26, 74" },
  ["Egg Collection"] = { giver = "Tinkee Steamboil", location = "Burning Steppes, Flame Crest", coords = "65, 23" },
  ["Eitrigg's Wisdom"] = { giver = "Eitrigg", location = "Orgrimmar, Valley of Strength" },
  ["Find Agmond"] = { giver = "Prospector Ironband", location = "Loch Modan, Ironband's Excavation Site", coords = "65, 65" },
  ["Get the Scoop"] = { giver = "Magus Tirth", location = "Thousand Needles, Shimmering Flats", coords = "77, 76" },
  ["Gnogaine"] = { giver = "Ozzie Togglevolt", location = "Dun Morogh, Kharanos", coords = "45, 49" },
  ["Going, Going, Guano!"] = { giver = "Master Apothecary Faranell", location = "Undercity, The Apothecarium", coords = "48, 69" },
  ["Grark Lorkrub"] = { giver = "Lexlort", location = "Badlands, Kargath", coords = "6, 48" },
  ["Gryphon Master Talonaxe"] = { giver = "Gryphon Master Talonaxe", location = "The Hinterlands", coords = "49, 68" },
  ["Hidden Secrets"] = { giver = "Magus Tirth", location = "Thousand Needles, Shimmering Flats" },
  ["Hunting for Ectoplasm"] = { giver = "Mux Manascrambler", location = "Tanaris, Gadgetzan" },
  ["In Search of The Temple"] = { giver = "Brohann Caskbelly", location = "Stormwind, Dwarven District", coords = "64, 21" },
  ["Ironband Wants You!"] = { giver = "Prospector Ironband", location = "Loch Modan, Ironband's Excavation Site", coords = "65, 65" },
  ["KILL ON SIGHT: Dark Iron Dwarves"] = { giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47" },
  ["KILL ON SIGHT: High Ranking Dark Iron Officials"] = { giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47" },
  ["Kharan Mighthammer"] = { giver = "King Magni Bronzebeard", location = "Ironforge, Throne Room", coords = "39, 56" },
  ["Kirtonos the Herald"] = { giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73" },
  ["Krastinov's Bag of Horrors"] = { giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73" },
  ["Larion and Muigin"] = { giver = "Larion", location = "Un'Goro Crater, Marshal's Refuge" },
  ["Legends of Maraudon"] = { giver = "Cavindra", location = "Maraudon, Orange side, outside instance" },
  ["Leonid Barthalomew"] = { giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57" },
  ["Lonebrow's Journal"] = { giver = "Henrig Lonebrow's corpse", location = "Thousand Needles, near the Great Lift", coords = "31, 24" },
  ["Lorax's Tale"] = { giver = "Lorax", location = "Winterspring, Southeast", coords = "63, 73" },
  ["Marvon's Workshop"] = { giver = "Liv Rizzlefix", location = "The Barrens, Ratchet", coords = "62, 38" },
  ["Material Assistance"] = { giver = "Sagorne Creststrider", location = "Orgrimmar, Valley of Wisdom", coords = "38, 35" },
  ["Murdaloc"] = { giver = "Prospector Ironband", location = "Loch Modan, Ironband's Excavation Site", coords = "65, 65" },
  ["Nara Wildmane"] = { giver = "Nara Wildmane", location = "Thunder Bluff, Elder Rise", coords = "45, 23" },
  ["Of Forgotten Memories"] = { giver = "Tirion Fordring", location = "Eastern Plaguelands, Light's Hope Chapel" },
  ["Of Lost Honor"] = { giver = "Tirion Fordring", location = "Eastern Plaguelands, Light's Hope Chapel" },
  ["Overmaster Pyron"] = { giver = "Jalinda Sprig", location = "Burning Steppes, Morgan's Vigil", coords = "85, 70" },
  ["Plagued Hatchlings"] = { giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
  ["Poisoned Water"] = { giver = "Duke Hydraxis", location = "Azshara", coords = "79, 73" },
  ["Pool of Tears"] = { giver = "Fel'zerul", location = "Swamp of Sorrows, Stonard", coords = "47, 54" },
  ["Precarious Predicament"] = { giver = "Lexlort", location = "Badlands, Kargath", coords = "6, 48" },
  ["Raptor Horns"] = { giver = "Mebok Mizzyrix", location = "The Barrens, Ratchet", coords = "62, 37" },
  ["Return to Fel'Zerul"] = { giver = "Atal'ai Exile", location = "The Hinterlands, Shadra'Alor", coords = "33, 75" },
  ["Return to the Marsh"] = { giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57" },
  ["Rig Wars"] = { giver = "Nogg", location = "Orgrimmar, Valley of Honor", coords = "76, 25" },
  ["Scourge of the Downs"] = { giver = "Belnistrasz", location = "Razorfen Downs, Murder Pens" },
  ["Screecher Spirits"] = { giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22" },
  ["Stormers and Rumblers"] = { giver = "Duke Hydraxis", location = "Azshara", coords = "79, 73" },
  ["The Altar of Zul"] = { giver = "Gryphon Master Talonaxe", location = "The Hinterlands", coords = "49, 68" },
  ["The Ancient Egg"] = { giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "66, 23" },
  ["The Archivist"] = { giver = "Duke Nicholas Zverenhoff", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
  ["The Atal'ai Exile"] = { giver = "Atal'ai Exile", location = "The Hinterlands, Shadra'Alor", coords = "33, 75" },
  ["The Dark Iron War"] = { giver = "Motley Garmason", location = "Wetlands, Dun Modr" },
  ["The Dying, Ras Frostwhisper"] = { giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57" },
  ["The Ectoplasmic Distiller"] = { giver = "Mux Manascrambler", location = "Tanaris, Gadgetzan" },
  ["The Exorcism"] = { giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57" },
  ["The Flesh Does Not Lie"] = { giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
  ["The Forgotten Pools"] = { giver = "Tonga Runetotem", location = "The Barrens, Crossroads" },
  ["The God Hakkar"] = { giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22" },
  ["The Human, Ras Frostwhisper"] = { giver = "Magistrate Marduke", location = "Arathi Highlands, Stromgarde" },
  ["The Infernal Orb"] = { giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57" },
  ["The Lost Dwarves"] = { giver = "Prospector Stormpike", location = "Ironforge, Hall of Explorers", coords = "75, 12" },
  ["The Lost Tablets of Mosh'aru"] = { giver = "Prospector Ironboot", location = "Tanaris, Steamwheedle Port", coords = "66, 24" },
  ["The Medallion of Faith"] = { giver = "Aurius", location = "Stratholme, Undead Side, inside chapel at beginning" },
  ["The Prophecy of Mosh'aru"] = { giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22" },
  ["The Ranger Lord's Behest"] = { giver = "Nathanos Blightcaller", location = "Eastern Plaguelands, Marris Stead", coords = "26, 74" },
  ["The Restless Souls"] = { giver = "Egan", location = "Eastern Plaguelands, Terrordale", coords = "14, 33" },
  ["The Stagnant Oasis"] = { giver = "Tonga Runetotem", location = "The Barrens, Crossroads" },
  ["The Stone Circle"] = { giver = "Marvon Rivetseeker", location = "Tanaris, S. of Gadgetzan", coords = "52, 45" },
  ["The Truth Comes Crashing Down"] = { giver = "Drop from Balnazzar", location = "Stratholme, Live Side" },
  ["The Unsent Letter"] = { giver = "Drop from Edwin VanCleef", location = "The Deadmines" },
  ["Tinkee Steamboil"] = { giver = "Felnok Steelspring", location = "Winterspring, Everlook" },
  ["To The Hinterlands"] = { giver = "High Thane Falstad Wildhammer", location = "The Hinterlands, Aerie Peak", coords = "14, 44" },
  ["Undamaged Venom Sac"] = { giver = "Apothecary Lydon", location = "Hillsbrad Foothills, Tarren Mill" },
  ["Venom Bottles"] = { giver = "Apothecary Lydon", location = "Hillsbrad Foothills, Tarren Mill" },
  ["Warlord's Command"] = { giver = "Warlord Goretooth", location = "Badlands, Kargath", coords = "5, 47" },
  ["Witherbark Cages"] = { giver = "Gryphon Master Talonaxe", location = "The Hinterlands", coords = "49, 68" },
  ["Amulet of Secrets"] = { giver = "Hammertoe Grez", location = "Uldaman" },
  ["An Ambassador of Evil"] = { giver = "Historian Karnik", location = "Ironforge" },
  ["Abandoned Hope"] = { giver = "Marshal Windsor", location = "Blackrock Depths" },
  ["A Shred of Hope"] = { giver = "Marshal Windsor", location = "Blackrock Depths" },
  ["Stormwind Rendezvous"] = { giver = "Marshal Maxwell", location = "Burning Steppes, Morgan's Vigil" },
  ["The Great Masquerade"] = { giver = "Reginald Windsor", location = "Stormwind City" },
  ["The Dragon's Eye"] = { giver = "Highlord Bolvar Fordragon", location = "Stormwind City" },
  ["The Smoldering Ruins of Thaurissan"] = { giver = "Royal Historian Archesonus", location = "Ironforge" },
  ["Brother Anton"] = { giver = "Brother Crowley", location = "Stormwind City" },
  ["Test of Faith"] = { giver = "Dorn Plainstalker", location = "Thousand Needles" },
  ["Test of Endurance"] = { giver = "Dorn Plainstalker", location = "Thousand Needles" },
  ["Test of Strength"] = { giver = "Dorn Plainstalker", location = "Thousand Needles" },
}
