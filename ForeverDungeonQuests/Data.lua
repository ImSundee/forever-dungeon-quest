-- Forever Dungeon Quests: quest database
-- Source: https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location
-- Patch 1.60.1, updated 2026/09/23. Data is Classic-derived and may change during Beta.
--
-- Faction values: "Alliance", "Horde", "Neutral" (available/needed regardless of faction)
-- Quests are matched purely by title at runtime (see Core.lua) -- no hardcoded quest IDs,
-- since Wowhead's guide text doesn't expose them and beta IDs may still shift.

FDQ_Dungeons = {

  {
    name = "Ragefire Chasm",
    aliases = { "Ragefire Chasm" },
    levels = { hard = 9, medium = 12, atLevel = 14, easy = 19 },
    quests = {
      { name = "Slaying the Beast", level = 9, faction = "Horde", giver = "Neeru Fireblade", location = "Orgrimmar, The Drag", coords = "49, 50" },
      { name = "The Power to Destroy...", level = 9, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "56, 92" },
      { name = "Testing an Enemy's Strength", level = 9, faction = "Horde", giver = "Rahauro", location = "Thunder Bluff, Elder Rise", coords = "70, 30" },
      { name = "Searching for the Lost Satchel", level = 9, faction = "Neutral", giver = "Grimtotem Satchel (drop from Maur Grimtotem)", location = "Inside Ragefire Chasm", dungeonDrop = true },
      { name = "Hidden Enemies", level = 9, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "31, 37", notes = "Prerequisite: complete 3 quests starting with Hidden Enemies from Thrall." },
    },
  },

  {
    name = "The Hall of Thanes",
    aliases = { "The Hall of Thanes" },
    levels = { hard = 11, medium = 13, atLevel = 14, easy = 19 },
    quests = {
      { name = "Important Heirlooms", level = 14, faction = "Neutral", giver = "Thom Filch", location = "Ironforge, Old Ironforge", coords = "32.6, 44.6" },
      { name = "The Restless Dead", level = 15, faction = "Neutral", giver = "Afadra Dunwall", location = "Ironforge, Old Ironforge", coords = "64.8, 58.4" },
      { name = "Old Ironforge Incursion", level = 15, faction = "Neutral", giver = "Earthseer Farsen", location = "Dun Morogh, Gol'Golar Quarry", coords = "64.8, 58.4", notes = "Prerequisite to pick up Underground Map from Dark Iron Map." },
      { name = "The Treaty of Understanding", level = 16, faction = "Neutral", giver = "Interactable item", location = "The Hall of Thanes, Reliquary of Kings vault" },
      { name = "An Ancient Grudge", level = 14, faction = "Neutral", giver = "Ghostly Attendant", location = "The Hall of Thanes, Anvilmar's Rest" },
    },
  },

  {
    name = "Wailing Caverns",
    aliases = { "Wailing Caverns" },
    levels = { hard = 15, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "Serpentbloom", level = 14, faction = "Horde", giver = "Apothecary Zamah", location = "Thunder Bluff, Pools of Vision", coords = "34, 21" },
      { name = "Smart Drinks", level = 13, faction = "Neutral", giver = "Mebok Mizzyrix", location = "The Barrens, Ratchet", coords = "62, 37", notes = "Prerequisite: complete Raptor Horns from same NPC first.", prereqs = { "Raptor Horns" } },
      { name = "Trouble at the Docks", level = 14, faction = "Neutral", giver = "Crane Operator Bigglefuzz", location = "The Barrens, Ratchet", coords = "63, 37" },
      { name = "Deviate Hides", level = 13, faction = "Neutral", giver = "Nalpak", location = "The Barrens, above WC entrance", coords = "46, 35" },
      { name = "Deviate Eradication", level = 15, faction = "Neutral", giver = "Ebru", location = "The Barrens, above WC entrance", coords = "46, 35" },
      { name = "The Glowing Shard", level = 10, faction = "Neutral", giver = "Drop from Mutanus the Devourer", location = "Wailing Caverns", dungeonDrop = true },
      { name = "Leaders of the Fang", level = 15, faction = "Horde", giver = "Nara Wildmane", location = "Thunder Bluff, Elder Rise", coords = "45, 23", notes = "Prerequisite: complete 5 quests starting with The Forgotten Pools (The Barrens, Crossroads, Tonga Runetotem)." },
    },
  },

  {
    name = "The Deadmines",
    aliases = { "The Deadmines" },
    levels = { hard = 14, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "Collecting Memories", level = 14, faction = "Alliance", giver = "Wilder Thistlenettle", location = "Stormwind, Dwarven District", coords = "65, 21" },
      { name = "Oh Brother...", level = 15, faction = "Alliance", giver = "Wilder Thistlenettle", location = "Stormwind, Dwarven District", coords = "65, 21" },
      { name = "Underground Assault", level = 15, faction = "Alliance", giver = "Shoni the Shilent", location = "Stormwind, Dwarven District", coords = "55, 13" },
      { name = "The Unsent Letter", level = 16, faction = "Neutral", giver = "Drop from Edwin VanCleef", location = "The Deadmines", notes = "Prerequisite to pick up The Stockade Riots.", dungeonDrop = true },
      { name = "Red Silk Bandanas", level = 14, faction = "Alliance", giver = "Scout Riell", location = "Westfall, Sentinel Hill", coords = "56, 47", notes = "Prerequisite: complete 6 quests starting with The Defias Brotherhood (Gryan Stoutmantle, Sentinel Hill, Westfall)." },
      { name = "The Defias Brotherhood", level = 14, faction = "Alliance", giver = "Gryan Stoutmantle", location = "Westfall, Sentinel Hill", coords = "56, 47", notes = "Same prerequisites as Red Silk Bandanas." },
      { name = "The Test of Righteousness", level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", notes = "Paladin only. Starts the Tome of Valor quest chain; start point varies by race." },
    },
  },

  {
    name = "Ruins of Lordaeron",
    aliases = { "Ruins of Lordaeron" },
    levels = { hard = 15, medium = 17, atLevel = 19, easy = 24 },
    quests = {
      { name = "A Frightened Request", level = 15, faction = "Horde", giver = "Tabitha Heartweaver", location = "Undercity", coords = "34, 21" },
      { name = "The Wrath of Rath'mael", level = 15, faction = "Horde", giver = "Deathguard Kristof", location = "Brill" },
      { name = "The New Plague", level = 16, faction = "Horde", giver = "Theodore Griffs", location = "Undercity", coords = "47.0, 72.6" },
      { name = "Light's Justice", level = 15, faction = "Horde", giver = "Morbin Lightbane", location = "Undercity", coords = "57.8, 89.8" },
      { name = "Unending Torment", level = 15, faction = "Neutral", giver = "Inside dungeon", location = "Ruins of Lordaeron" },
      { name = "Crest of Lordaeron", level = 15, faction = "Neutral", giver = "Inside dungeon", location = "Ruins of Lordaeron" },
      { name = "Abominable Creatures", level = 16, faction = "Neutral", giver = "TBD (beta data incomplete)", location = "TBD" },
      { name = "Bloodied Insignia", level = 16, faction = "Alliance", giver = "General Marcus Jonathan", location = "Stormwind City" },
      { name = "Remember That I Love You", level = 15, faction = "Neutral", giver = "TBD (beta data incomplete)", location = "TBD" },
    },
  },

  {
    name = "Shadowfang Keep",
    aliases = { "Shadowfang Keep" },
    levels = { hard = 18, medium = 21, atLevel = 23, easy = 28 },
    quests = {
      { name = "The Book of Ur", level = 16, faction = "Horde", giver = "Keeper Bel'dugur", location = "Undercity, Apothecarium", coords = "53, 54" },
      { name = "Deathstalkers in Shadowfang", level = 18, faction = "Horde", giver = "High Executor Hadrec", location = "Silverpine Forest, Sepulcher", coords = "43, 41" },
      { name = "Arugal Must Die", level = 18, faction = "Horde", giver = "Dalar Dawnweaver", location = "Silverpine Forest, Sepulcher", coords = "44, 39" },
      { name = "The Orb of Soran'ruk", level = 20, faction = "Neutral", giver = "Doan Karhan", location = "The Barrens, near Camp Taurajo", coords = "49, 57", notes = "Warlock only." },
      { name = "The Test of Righteousness", level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", notes = "Paladin only. Starts the Tome of Valor quest chain; start point varies by race." },
    },
  },

  {
    name = "Blackfathom Deeps",
    aliases = { "Blackfathom Deeps" },
    levels = { hard = 21, medium = 23, atLevel = 25, easy = 30 },
    quests = {
      -- Horde
      { name = "The Essence of Aku'Mai", level = 17, faction = "Horde", giver = "Je'neu Sancrea", location = "Ashenvale, Zoram'gar Outpost", coords = "11, 34" },
      { name = "Blackfathom Villainy", level = 18, faction = "Horde", giver = "Argent Guard Thaelrid", location = "Blackfathom Deeps, alcove SW of Ghamoo-ra" },
      { name = "Amongst the Ruins", level = 21, faction = "Horde", giver = "Je'neu Sancrea", location = "Ashenvale, Zoram'gar Outpost", coords = "11, 34", notes = "Summons Baron Aquanis when Fathom Core is picked up; needed for next quest." },
      { name = "Baron Aquanis", level = 21, faction = "Horde", giver = "Drop: Strange Water Globe from Baron Aquanis", location = "Blackfathom Deeps", dungeonDrop = true },
      { name = "Allegiance to the Old Gods", level = 17, faction = "Horde", giver = "Drop: Damp Note (low drop rate)", location = "Blackfathom Tide Priestess, outside instance", notes = "Drop-only." },
      -- Alliance
      { name = "Knowledge in the Deeps", level = 10, faction = "Alliance", giver = "Gerrig Bonegrip", location = "Ironforge, Forlorn Cave", coords = "50, 5" },
      { name = "Researching the Corruption", level = 18, faction = "Alliance", giver = "Gershala Nightwhisper", location = "Darkshore, Auberdine", coords = "38, 43" },
      { name = "Twilight Falls", level = 20, faction = "Alliance", giver = "Argent Guard Manados", location = "Darnassus, Craftsman's Terrace", coords = "55, 24" },
      { name = "In Search of Thaelrid", level = 18, faction = "Alliance", giver = "Dawnwatcher Shaedlass", location = "Darnassus, Craftsman's Terrace", coords = "55, 24", notes = "Prerequisite to Blackfathom Villainy." },
      { name = "Blackfathom Villainy", level = 18, faction = "Alliance", giver = "Argent Guard Thaelrid", location = "Blackfathom Deeps, alcove SW of Ghamoo-ra", notes = "Requires In Search of Thaelrid." },
      -- Both (Neutral, class-restricted)
      { name = "The Orb of Soran'ruk", level = 20, faction = "Neutral", giver = "Doan Karhan", location = "The Barrens, near Camp Taurajo", coords = "49, 57", notes = "Warlock only." },
      { name = "The Test of Righteousness", level = 20, faction = "Alliance", giver = "Jordan Stilwell", location = "Ironforge, inside Gates", coords = "52, 36", notes = "Paladin only." },
    },
  },

  {
    name = "The Stockades",
    aliases = { "The Stockade", "The Stockades" },
    levels = { hard = 22, medium = 24, atLevel = 26, easy = 30 },
    quests = {
      { name = "Quell The Uprising", level = 22, faction = "Alliance", giver = "Warden Thelwater", location = "Stormwind, outside Stockades", coords = "41, 58" },
      { name = "The Color of Blood", level = 22, faction = "Alliance", giver = "Nikova Raskol (patrols)", location = "The Stockades, Old Town" },
      { name = "Crime and Punishment", level = 22, faction = "Alliance", giver = "Councilman Millstipe", location = "Duskwood, Darkshire", coords = "42, 47" },
      { name = "What Comes Around...", level = 22, faction = "Alliance", giver = "Guard Berton", location = "Redridge Mountains, Lakeshire", coords = "26, 46" },
      { name = "The Fury Runs Deep", level = 25, faction = "Alliance", giver = "Motley Garmason", location = "Wetlands, Dun Modr", coords = "49, 18", notes = "Requires The Dark Iron War.", prereqs = { "The Dark Iron War" } },
      { name = "The Stockade Riots", level = 16, faction = "Alliance", giver = "Warden Thelwater", location = "Stormwind, outside Stockades", coords = "41, 58", notes = "Requires the quest line starting with The Unsent Letter from The Deadmines.", prereqs = { "The Unsent Letter" } },
    },
  },

  {
    name = "Gnomeregan",
    aliases = { "Gnomeregan" },
    levels = { hard = 25, medium = 30, atLevel = 33, easy = 38 },
    keyNote = "At least one player must have the Workshop Key to open the back door (Lockpicking 150 also works).",
    quests = {
      { name = "Rig Wars", level = 25, faction = "Horde", giver = "Nogg", location = "Orgrimmar, Valley of Honor", coords = "76, 25" },
      { name = "Chief Engineer Scooty", level = 20, faction = "Horde", giver = "Sovik", location = "Orgrimmar, Valley of Honor", coords = "76, 25", notes = "Must pick up Rig Wars first.", prereqs = { "Rig Wars" } },
      { name = "Gnomer-gooooone!", level = 20, faction = "Horde", giver = "Scooty", location = "Stranglethorn Vale, Booty Bay", coords = "27, 77" },
      { name = "Save Techbot's Brain!", level = 20, faction = "Alliance", giver = "Tinkmaster Overspark", location = "Ironforge, Tinkertown", coords = "69, 50" },
      { name = "Gyrodrillmatic Excavationators", level = 20, faction = "Alliance", giver = "Shoni the Shilent", location = "Stormwind, Dwarven Quarter", coords = "55, 12" },
      { name = "Essential Artificials", level = 24, faction = "Alliance", giver = "Klockmort Spannerspan", location = "Ironforge, Tinkertown", coords = "47, 64" },
      { name = "Data Rescue", level = 25, faction = "Alliance", giver = "Master Mechanic Castpipe", location = "Ironforge, Tinkertown", coords = "69, 48" },
      { name = "The Grand Betrayal", level = 25, faction = "Alliance", giver = "High Tinker Mekkatorque", location = "Ironforge, Tinkertown", coords = "68, 49" },
      { name = "Gnogaine", level = 20, faction = "Neutral", giver = "Ozzie Togglevolt", location = "Dun Morogh, Kharanos", coords = "45, 49" },
      { name = "The Only Cure is More Green Glow", level = 20, faction = "Neutral", giver = "Ozzie Togglevolt", location = "Dun Morogh, Kharanos", coords = "45, 49", notes = "Complete Gnogaine first.", prereqs = { "Gnogaine" } },
      { name = "The Sparklematic 5200!", level = 25, faction = "Neutral", giver = "Needs Grime-Encrusted Object", location = "Gnomeregan, the Sparklematic 5200" },
      { name = "A Fine Mess", level = 20, faction = "Neutral", giver = "Escort quest", location = "Gnomeregan, room right of Clean Room", notes = "Escort Kernobee." },
      { name = "Grime-Encrusted Ring", level = 28, faction = "Neutral", giver = "Drop: Grime-Encrusted Ring", location = "Gnomeregan", notes = "Starts Return of the Ring.", dungeonDrop = true },
    },
  },

  {
    name = "Razorfen Kraul",
    aliases = { "Razorfen Kraul" },
    levels = { hard = 25, medium = 28, atLevel = 31, easy = 34 },
    quests = {
      { name = "A Vengeful Fate", level = 29, faction = "Horde", giver = "Auld Stonespire", location = "Thunder Bluff, near Main Lift", coords = "37, 29" },
      { name = "Going, Going, Guano!", level = 30, faction = "Horde", giver = "Master Apothecary Faranell", location = "Undercity, The Apothecarium", coords = "48, 69", notes = "Prerequisite for the Scarlet Monastery quest Hearts of Zeal." },
      { name = "An Unholy Alliance", level = 28, faction = "Neutral", giver = "Drop: Small Scroll from Charlga Razorflank", location = "Razorfen Kraul", notes = "Prerequisite for the Razorfen Downs quest of the same name.", dungeonDrop = true },
      { name = "The Crone of the Kraul", level = 29, faction = "Neutral", giver = "Falfindel Waywarder", location = "Feralas, The Lower Wilds", coords = "89, 46", notes = "Complete Lonebrow's Journal first.", prereqs = { "Lonebrow's Journal" } },
      { name = "Mortality Wanes", level = 25, faction = "Neutral", giver = "Heralath Fallowbrook", location = "Razorfen Kraul, behind main boss" },
      { name = "Blueleaf Tubers", level = 20, faction = "Neutral", giver = "Mebok Mizzyrix", location = "The Barrens, Ratchet", coords = "62, 37", notes = "Quest items are next to Mizzyrix." },
      { name = "Willix the Importer", level = 22, faction = "Neutral", giver = "Willix the Importer", location = "Razorfen Kraul, tent near final boss", notes = "Escort quest." },
    },
  },

  {
    name = "Scarlet Monastery",
    aliases = { "Scarlet Monastery" },
    levels = { hard = 26, medium = 32, atLevel = 37, easy = 45 },
    keyNote = "At least one player must have The Scarlet Key to open both the Armory and Cathedral wings (Lockpicking 175 also works).",
    quests = {
      -- All Wings
      { name = "Into The Scarlet Monastery", level = 33, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "56, 92" },
      { name = "In the Name of the Light", level = 34, faction = "Alliance", giver = "Raleigh the Devout", location = "Hillsbrad Foothills, Southshore", coords = "51, 58", notes = "3 prerequisite quests, starting with Brother Anton." },
      -- Graveyard
      { name = "Vorrel's Revenge", level = 25, faction = "Neutral", giver = "Vorrel Sengutz", location = "Scarlet Monastery, Graveyard" },
      { name = "Hearts of Zeal", level = 30, faction = "Horde", giver = "Master Apothecary Faranell", location = "Undercity, The Apothecarium", coords = "48, 69", notes = "Requires Going, Going, Guano! (Razorfen Kraul) first.", prereqs = { "Going, Going, Guano!" } },
      -- Library
      { name = "Compendium of the Fallen", level = 28, faction = "Horde", giver = "Sage Truthseeker", location = "Thunder Bluff, First Rise", coords = "36, 26", notes = "Undead cannot pick up this quest." },
      { name = "Test of Lore", level = 25, faction = "Horde", giver = "Parqual Fintallas", location = "Undercity, The Apothecarium", coords = "57, 65", notes = "Chain of 6 quests, starting with Test of Faith." },
      { name = "Mythology of the Titans", level = 28, faction = "Alliance", giver = "Librarian Mae Paledust", location = "Ironforge, Hall of Explorers", coords = "75, 12" },
      { name = "Rituals of Power", level = 30, faction = "Neutral", giver = "Magus Tirth", location = "Thousand Needles, Shimmering Flats Raceway", coords = "78, 75", notes = "Mage only. Chain of 3 quests starting with Journey to the Marsh." },
    },
  },

  {
    name = "Razorfen Downs",
    aliases = { "Razorfen Downs" },
    levels = { hard = 35, medium = 37, atLevel = 39, easy = 44 },
    quests = {
      { name = "Bring the End", level = 37, faction = "Horde", giver = "Andrew Brownell", location = "Undercity, Magic Quarter", coords = "74, 33" },
      { name = "An Unholy Alliance", level = 28, faction = "Horde", giver = "Varimathras", location = "Undercity, Royal Quarter", coords = "36, 26", notes = "Requires An Unholy Alliance from Razorfen Kraul first.", prereqs = { "An Unholy Alliance" } },
      { name = "Bring the Light", level = 39, faction = "Alliance", giver = "Archbishop Benedictus", location = "Stormwind, Cathedral", coords = "39, 27" },
      { name = "A Host of Evil", level = 28, faction = "Neutral", giver = "Myriam Moonsinger", location = "The Barrens, outside instance portal", coords = "49, 95" },
      { name = "Scourge of the Downs", level = 32, faction = "Neutral", giver = "Belnistrasz", location = "Razorfen Downs, Murder Pens", notes = "Entire party should complete before picking up the next quest." },
      { name = "Extinguishing the Idol", level = 32, faction = "Neutral", giver = "Belnistrasz", location = "Razorfen Downs, Murder Pens", notes = "Escort quest. Entire party must finish Scourge of the Downs first or they won't get credit.", prereqs = { "Scourge of the Downs" } },
    },
  },

  {
    name = "Uldaman",
    aliases = { "Uldaman" },
    levels = { hard = 37, medium = 40, atLevel = 42, easy = 47 },
    quests = {
      { name = "Reclaimed Treasures", level = 33, faction = "Horde", giver = "Patrick Garrett", location = "Undercity, Center", coords = "62, 48" },
      { name = "Uldaman Reagent Run", level = 36, faction = "Horde", giver = "Jarkal Mossmeld", location = "Badlands, Kargath", coords = "3, 46", notes = "Complete Badlands Reagent Run first.", prereqs = { "Badlands Reagent Run" } },
      { name = "Necklace Recovery", level = 37, faction = "Neutral", giver = "Drop: Shattered Necklace from Shadowforge/Shadowvault mobs", location = "Badlands, outside Uldaman instance", notes = "Drop-only." },
      { name = "Reclaimed Treasures", level = 33, faction = "Alliance", giver = "Krom Stoutarm", location = "Ironforge, Hall of Explorers", coords = "74, 9" },
      { name = "The Lost Dwarves", level = 35, faction = "Alliance", giver = "Prospector Stormpike", location = "Ironforge, Hall of Explorers", coords = "75, 12" },
      { name = "The Hidden Chamber", level = 35, faction = "Alliance", giver = "Baelog's Journal", location = "Uldaman, Lost Dwarves area", notes = "Complete The Lost Dwarves first.", prereqs = { "The Lost Dwarves" } },
      { name = "Uldaman Reagent Run", level = 38, faction = "Alliance", giver = "Ghak Healtouch", location = "Loch Modan, Thelsamar", coords = "37, 49", notes = "Complete Badlands Reagent Run first.", prereqs = { "Badlands Reagent Run" } },
      { name = "Agmond's Fate", level = 33, faction = "Alliance", giver = "Prospector Ironband", location = "Loch Modan, Ironband's Excavation Site", coords = "65, 65", notes = "Chain of 3 quests starting with Ironband Wants You!" },
      { name = "The Lost Tablets of Will", level = 30, faction = "Alliance", giver = "Advisor Belgrum", location = "Ironforge, Hall of Explorers", coords = "77, 9", notes = "Chain of 8 quests starting with A Sign of Hope." },
      { name = "The Shattered Necklace", level = 37, faction = "Neutral", giver = "Drop: Shattered Necklace from Shadowforge/Shadowvault mobs", location = "Badlands, outside Uldaman instance", notes = "Drop-only." },
      { name = "Power Stones", level = 30, faction = "Neutral", giver = "Rigglefuzz", location = "Badlands, Central", coords = "42, 52" },
      { name = "Solution to Doom", level = 30, faction = "Neutral", giver = "Theldurin the Lost", location = "Badlands, Southern", coords = "51, 76" },
      { name = "The Platinum Discs", level = 40, faction = "Neutral", giver = "Item pickup", location = "Uldaman, room after Archaedas" },
      { name = "Power in Uldaman", level = 35, faction = "Neutral", giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57", notes = "Mage only. Chain of 3 quests starting with Return to the Marsh." },
    },
  },

  {
    name = "Zul'Farrak",
    aliases = { "Zul'Farrak" },
    levels = { hard = 40, medium = 42, atLevel = 44, easy = 50 },
    keyNote = "At least one player must have the Mallet of Zul'Farrak to summon Gahz'rilla, the end boss.",
    quests = {
      { name = "The Spider God", level = 40, faction = "Horde", giver = "Master Gadrin", location = "Durotar, Sen'jin Village", coords = "56, 74", notes = "Chain of 3 quests starting with Venom Bottles." },
      { name = "Nekrum's Medallion", level = 40, faction = "Alliance", giver = "Thadius Grimshade", location = "Blasted Lands, Nethergarde Keep", coords = "66, 19", notes = "Chain of 3 quests starting with Witherbark Cages." },
      { name = "Divino-matic Rod", level = 40, faction = "Neutral", giver = "Chief Engineer Bilgewhizzle", location = "Tanaris, Gadgetzan", coords = "52, 28" },
      { name = "Scarab Shells", level = 40, faction = "Neutral", giver = "Tran'rek", location = "Tanaris, Gadgetzan", coords = "51, 26" },
      { name = "Troll Temper", level = 40, faction = "Neutral", giver = "Trenton Lighthammer", location = "Tanaris, Gadgetzan", coords = "51, 28" },
      { name = "Tiara of the Deep", level = 40, faction = "Neutral", giver = "Tabetha", location = "Dustwallow Marsh, N. of Stonemaul Ruins", coords = "46, 57" },
      { name = "Gahz'rilla", level = 40, faction = "Neutral", giver = "Wizzle Brassbolts", location = "Thousand Needles, Shimmering Flats", coords = "78, 77", notes = "Needs the Mallet of Zul'Farrak (drop from Qiaga the Keeper, Hinterlands)." },
      { name = "The Prophecy of Mosh'aru", level = 40, faction = "Neutral", giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22", notes = "Complete Screecher Spirits first.", prereqs = { "Screecher Spirits" } },
    },
  },

  {
    name = "Maraudon",
    aliases = { "Maraudon" },
    levels = { hard = 41, medium = 44, atLevel = 46, easy = 50 },
    keyNote = "At least one player must have the Scepter of Celebras to open the portal to Earth Song Falls (skips the orange/purple sides).",
    quests = {
      { name = "Shadowshard Fragments", level = 39, faction = "Horde", giver = "Uthel'nay", location = "Orgrimmar, Valley of Spirits", coords = "39, 86" },
      { name = "Vyletongue Corruption", level = 41, faction = "Horde", giver = "Vark Battlescar", location = "Desolace, Shadowprey Village", coords = "23, 70" },
      { name = "Corruption of Earth and Seed", level = 45, faction = "Horde", giver = "Selendra", location = "Desolace, S. of Shadowprey Village", coords = "26, 77" },
      { name = "Shadowshard Fragments", level = 39, faction = "Alliance", giver = "Archmage Tervosh", location = "Dustwallow Marsh, Theramore", coords = "66, 49" },
      { name = "Vyletongue Corruption", level = 41, faction = "Alliance", giver = "Talendria", location = "Desolace, Nijel's Point", coords = "68, 8" },
      { name = "Corruption of Earth and Seed", level = 45, faction = "Alliance", giver = "Keeper Marandis", location = "Desolace, Nijel's Point", coords = "63, 10" },
      { name = "Twisted Evils", level = 41, faction = "Neutral", giver = "Willow", location = "Desolace, SE of Thunderaxe Fortress", coords = "62, 39" },
      { name = "Legends of Maraudon", level = 41, faction = "Neutral", giver = "Cavindra", location = "Maraudon, Orange side, outside instance" },
      { name = "Seed of Life", level = 39, faction = "Neutral", giver = "Zaetar's Spirit", location = "Maraudon, middle ring, after killing Princess Theradras" },
      { name = "The Pariah's Instructions", level = 39, faction = "Neutral", giver = "Centaur Pariah (patrols)", location = "Desolace, south of Mannoroc Coven", coords = "48.4, 87.0" },
      { name = "The Scepter of Celebras", level = 41, faction = "Neutral", giver = "Celebras the Redeemed", location = "Maraudon, Purple side", notes = "Complete Legends of Maraudon first.", prereqs = { "Legends of Maraudon" } },
    },
  },

  {
    name = "Sunken Temple",
    aliases = { "Temple of Atal'Hakkar", "The Sunken Temple" },
    levels = { hard = 46, medium = 49, atLevel = 51, easy = 54 },
    keyNote = "At least one player must have Yeh'kinya's Scroll to summon the Avatar of Hakkar. Also hosts a per-class Sunken Temple class quest.",
    quests = {
      { name = "The Temple of Atal'Hakkar", level = 38, faction = "Horde", giver = "Fel'zerul", location = "Swamp of Sorrows, Stonard", coords = "47, 54", notes = "Chain of 3 quests starting with Pool of Tears." },
      { name = "Zapper Fuel", level = 47, faction = "Neutral", giver = "Liv Rizzlefix", location = "The Barrens, Ratchet", coords = "62, 38", notes = "Chain of 2 quests starting with Larion and Muigin." },
      { name = "Haze of Evil", level = 47, faction = "Neutral", giver = "Gregan Brewspewer", location = "Feralas, Twin Colossals", coords = "45, 25", notes = "Chain of 2 quests starting with Muigin and Larion." },
      { name = "Into The Temple of Atal'Hakkar", level = 38, faction = "Alliance", giver = "Brohann Caskbelly", location = "Stormwind, Dwarven District", coords = "64, 21", notes = "Chain of 6 quests starting with In Search of The Temple." },
      { name = "Jammal'an the Prophet", level = 38, faction = "Neutral", giver = "Atal'ai Exile", location = "Hinterlands, spider area SW of Altar of Zul", coords = "33, 75" },
      { name = "The Essence of Eranikus", level = 48, faction = "Neutral", giver = "Drop: Essence of Eranikus", location = "Sunken Temple", dungeonDrop = true },
      { name = "Into the Depths", level = 46, faction = "Neutral", giver = "Marvon Rivetseeker", location = "Tanaris, S. of Gadgetzan", coords = "52, 45", notes = "Chain of 2 quests starting with The Sunken Temple." },
      { name = "Secret of the Circle", level = 46, faction = "Neutral", giver = "Marvon Rivetseeker", location = "Tanaris, S. of Gadgetzan", coords = "52, 45", notes = "Chain of 2 quests starting with The Sunken Temple." },
      { name = "The God Hakkar", level = 40, faction = "Neutral", giver = "Yeh'kinya", location = "Tanaris, Steamwheedle Port", coords = "67, 22", notes = "Chain of 3 quests starting with Screecher Spirits." },
    },
  },

  {
    name = "Blackrock Depths",
    aliases = { "Blackrock Depths" },
    levels = { hard = 50, medium = 52, atLevel = 55, easy = 60 },
    keyNote = "At least one player must have the Shadowforge Key to open the Shadowforge Doors (Lockpicking 280 also works).",
    quests = {
      -- Horde
      { name = "KILL ON SIGHT: Dark Iron Dwarves", level = 48, faction = "Horde", giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47" },
      { name = "Lost Thunderbrew Recipe", level = 50, faction = "Horde", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Breadcrumb: Vivian Lagrave in Undercity for easy XP." },
      { name = "KILL ON SIGHT: High Ranking Dark Iron Officials", level = 50, faction = "Horde", giver = "WANTED poster", location = "Badlands, Kargath", coords = "4, 47", notes = "Complete KILL ON SIGHT: Dark Iron Dwarves first.", prereqs = { "KILL ON SIGHT: Dark Iron Dwarves" } },
      { name = "The Rise of the Machines", level = 52, faction = "Horde", giver = "Lotwil Veriatus", location = "Badlands, Eastern", coords = "25, 44", notes = "Chain of 2 quests starting with The Rise of the Machines." },
      { name = "Disharmony of Flame", level = 48, faction = "Horde", giver = "Thunderheart", location = "Badlands, Kargath", coords = "3.6, 48.0" },
      { name = "Disharmony of Fire", level = 48, faction = "Horde", giver = "Thunderheart", location = "Badlands, Kargath", coords = "3.6, 48.0", notes = "Opens after Disharmony of Flame.", prereqs = { "Disharmony of Flame" } },
      { name = "Commander Gor'shak", level = 48, faction = "Horde", giver = "Galamav the Marksman", location = "Badlands, Kargath", coords = "6, 47", notes = "Opens after Disharmony of Flame.", prereqs = { "Disharmony of Flame" } },
      { name = "The Last Element", level = 48, faction = "Horde", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Opens after Disharmony of Flame.", prereqs = { "Disharmony of Flame" } },
      { name = "Operation: Death to Angerforge", level = 52, faction = "Horde", giver = "Warlord Goretooth", location = "Badlands, Kargath", coords = "6, 47", notes = "Chain of 3 starting with KILL ON SIGHT: Dark Iron Dwarves. Includes a long escort (Grark Lorkrub)." },
      { name = "The Royal Rescue", level = 48, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "32, 38", notes = "Chain of 4 starting with Commander Gor'shak." },
      -- Alliance
      { name = "Overmaster Pyron", level = 48, faction = "Alliance", giver = "Jalinda Sprig", location = "Burning Steppes, Morgan's Vigil", coords = "85, 70" },
      { name = "Incendius!", level = 48, faction = "Alliance", giver = "Jalinda Sprig", location = "Burning Steppes, Morgan's Vigil", coords = "85, 70", notes = "Complete Overmaster Pyron first.", prereqs = { "Overmaster Pyron" } },
      { name = "The Good Stuff", level = 50, faction = "Alliance", giver = "Oralius", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68" },
      { name = "Hurley Blackbreath", level = 50, faction = "Alliance", giver = "Ragnar Thunderbrew", location = "Dun Morogh, Kharanos", coords = "46, 52" },
      { name = "Kharan Mighthammer", level = 50, faction = "Alliance", giver = "King Magni Bronzebeard", location = "Ironforge, Throne Room", coords = "39, 56", notes = "Chain of 2 starting with The Smoldering Ruins of Thaurissan." },
      { name = "The Fate of the Kingdom", level = 50, faction = "Alliance", giver = "King Magni Bronzebeard", location = "Ironforge, Throne Room", coords = "39, 56", notes = "Chain of 2 starting with Kharan Mighthammer.", prereqs = { "Kharan Mighthammer" } },
      { name = "Marshal Windsor", level = 48, faction = "Alliance", giver = "Marshal Maxwell", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68", notes = "Chain of 2 starting with Dragonkin Menace." },
      { name = "Jail Break!", level = 50, faction = "Alliance", giver = "Marshal Windsor", location = "Blackrock Depths, Prison Cell", notes = "Chain of 6 starting with Dragonkin Menace, through Marshal Windsor to A Shred of Hope." },
      -- Neutral
      { name = "Ribbly Screwspigot", level = 50, faction = "Neutral", giver = "Yuka Screwspigot", location = "Burning Steppes, Flame Crest", coords = "66, 21", notes = "Breadcrumb: Yuka Screwspigot in Steamwheedle Port for easy XP." },
      { name = "The Heart of the Mountain", level = 50, faction = "Neutral", giver = "Maxwort Uberglint", location = "Burning Steppes, Flame Crest", coords = "65, 23" },
      { name = "Attunement to the Core", level = 55, faction = "Neutral", giver = "Lothos Riftwaker", location = "Blackrock Mountain" },
      { name = "Dark Iron Legacy", level = 48, faction = "Neutral", giver = "Franclorn Forgewright", location = "Blackrock Mountain, structure in the middle", notes = "NPC only visible while you are dead. Complete Dark Iron Legacy first." },
      { name = "The Love Potion", level = 50, faction = "Neutral", giver = "Mistress Nagmara", location = "Blackrock Depths, Grim Guzzler" },
      { name = "A Taste of Flame", level = 52, faction = "Neutral", giver = "Cyrus Therepentous", location = "Burning Steppes, cave in NE", coords = "95, 31", notes = "Chain of 11 starting with Divine Retribution." },
    },
  },

  {
    name = "Dire Maul: East (Warpwood Quarter)",
    aliases = { "Dire Maul" },
    levels = { hard = 52, medium = 54, atLevel = 56, easy = 60 },
    keyNote = "At least one player must have the Crescent Key to open the West and North wings of Dire Maul (Lockpicking 300 also works).",
    quests = {
      { name = "Lethtendris's Web", level = 54, faction = "Horde", giver = "Talo Thornhoof", location = "Feralas, Camp Mojache", coords = "76, 43" },
      { name = "Lethtendris's Web", level = 54, faction = "Alliance", giver = "Latronicus Moonspear", location = "Feralas, Feathermoon Stronghold", coords = "30, 46" },
      { name = "Pusillin and the Elder Azj'Tordin", level = 54, faction = "Neutral", giver = "Azj'Tordin", location = "Feralas, Lariss Pavilion", coords = "76, 37" },
      { name = "Shards of the Felvine", level = 56, faction = "Neutral", giver = "Rabine Saturna", location = "Moonglade, Nighthaven", coords = "51, 45", notes = "Complete A Reliquary of Purity from the same NPC and explore all of Dire Maul first.", prereqs = { "A Reliquary of Purity" } },
      { name = "Arcane Refreshment", level = 60, faction = "Neutral", giver = "Lorekeeper Lydros", location = "Dire Maul, Library", notes = "Mage only." },
    },
  },

  {
    name = "Dire Maul: West (Capital Gardens)",
    aliases = { "Dire Maul" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "The Madness Within", level = 56, faction = "Neutral", giver = "Shen'dralar Ancient", location = "Dire Maul, West, second floor" },
      { name = "Foror's Compendium", level = 60, faction = "Neutral", giver = "Nostro's Compendium of Dragon Slaying", location = "Dire Maul", notes = "Rare drop, or looted from A Dusty Tome. Not BoP; used to craft a BoP tanking sword (item #18348).", dungeonDrop = true },
    },
  },

  {
    name = "Dire Maul: North (Gordok Commons)",
    aliases = { "Dire Maul" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "Elven Legends", level = 54, faction = "Horde", giver = "Sage Korolusk", location = "Feralas, Camp Mojache", coords = "74, 43", notes = "Eligibility for Libram of Protection/Rapidity/Focus." },
      { name = "Elven Legends", level = 54, faction = "Alliance", giver = "Scholar Runethorn", location = "Feralas, Feathermoon Stronghold", coords = "31, 43", notes = "Eligibility for Libram of Protection/Rapidity/Focus." },
      { name = "Free Knot!", level = 56, faction = "Neutral", giver = "Knot Thimblejack", location = "Dire Maul, North", notes = "Cannot be completed during a Tribute Run unless a party member already has the Gordok Shackle Key." },
      { name = "The Gordok Ogre Suit", level = 56, faction = "Neutral", giver = "Knot Thimblejack", location = "Dire Maul, North" },
      { name = "The Gordok Taste Test", level = 56, faction = "Neutral", giver = "Stomper Kreeg", location = "Dire Maul, North", notes = "Can only be picked up after completing a Tribute Run." },
      { name = "Unfinished Gordok Business", level = 56, faction = "Neutral", giver = "Captain Kromcrush", location = "Dire Maul, North", notes = "Requires one Tribute Run, then a second after killing Prince Tortheldrin and looting the Gauntlet of Gordok Might." },
    },
  },

  {
    name = "Lower Blackrock Spire",
    aliases = { "Blackrock Spire", "Lower Blackrock Spire" },
    levels = { hard = 55, medium = 56, atLevel = 60 },
    quests = {
      { name = "The Pack Mistress", level = 55, faction = "Neutral", giver = "Galamav the Marksman", location = "Badlands, Kargath", coords = "6, 47" },
      { name = "Operative Bijou", level = 55, faction = "Neutral", giver = "Lexlort", location = "Badlands, Kargath", coords = "5, 47", notes = "Leads to Bijou's Belongings inside LBRS." },
      { name = "Warlord's Command", level = 55, faction = "Neutral", giver = "Warlord Goretooth", location = "Badlands, Kargath", coords = "5, 47" },
      { name = "Put Her Down", level = 55, faction = "Neutral", giver = "Helendis Riverhorn", location = "Burning Steppes, Morgan's Vigil", coords = "65, 69" },
      { name = "General Drakkisath's Command", level = 55, faction = "Neutral", giver = "Drop from Overlord Wyrmthalak", location = "Blackrock Spire, Lower", dungeonDrop = true },
      { name = "Bijou's Belongings", level = 55, faction = "Neutral", giver = "Bijou", location = "Blackrock Spire, Lower" },
      { name = "En-Ay-Es-Tee-Why", level = 55, faction = "Neutral", giver = "Kibler", location = "Burning Steppes, Flame Crest", coords = "65, 21" },
      { name = "Kibler's Exotic Pets", level = 55, faction = "Neutral", giver = "Kibler", location = "Burning Steppes, Flame Crest", coords = "65, 21" },
      { name = "Mother's Milk", level = 55, faction = "Neutral", giver = "Ragged John", location = "Burning Steppes, Flame Crest", coords = "65, 23" },
      { name = "Seal of Ascension", level = 57, faction = "Neutral", giver = "Drop: Unadorned Seal of Ascension + 3 Gemstones", location = "Blackrock Spire, Lower", dungeonDrop = true },
      { name = "Urok Doomhowl", level = 55, faction = "Neutral", giver = "Warosh (patrols)", location = "Blackrock Spire, Lower, near beginning" },
      { name = "The Final Tablets", level = 40, faction = "Neutral", giver = "Prospector Ironboot", location = "Tanaris, Steamwheedle Port", coords = "66, 24", notes = "Chain of 5 starting with Screecher Spirits." },
    },
  },

  {
    name = "Scholomance",
    aliases = { "Scholomance" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player must have the Skeleton Key to open the front door in Caer Darrow.",
    quests = {
      { name = "Barov Family Fortune", level = 52, faction = "Horde", giver = "Alexi Barov", location = "Tirisfal Glades, The Bulwark", coords = "83, 71", notes = "May be dead due to Alliance kill quest; 30 minute spawn timer." },
      { name = "The Darkreaver Menace", level = 58, faction = "Horde", giver = "Sagorne Creststrider", location = "Orgrimmar, Valley of Wisdom", coords = "38, 35", notes = "Shaman only. Complete Material Assistance first.", prereqs = { "Material Assistance" } },
      { name = "Barov Family Fortune", level = 52, faction = "Alliance", giver = "Weldon Barov", location = "Western Plaguelands, Chillwind Camp", coords = "43, 83", notes = "May be dead due to Horde kill quest; 30 minute spawn timer." },
      { name = "Plagued Hatchlings", level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "Healthy Dragon Scale", level = 55, faction = "Neutral", giver = "Drop from Plagued Hatchlings", location = "Scholomance", notes = "Repeatable for Argent Dawn rep. Complete Plagued Hatchlings first.", dungeonDrop = true, prereqs = { "Plagued Hatchlings" } },
      { name = "Doctor Theolen Krastinov, the Butcher", level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73" },
      { name = "Krastinov's Bag of Horrors", level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73", notes = "Complete Doctor Theolen Krastinov, the Butcher first.", prereqs = { "Doctor Theolen Krastinov, the Butcher" } },
      { name = "Kirtonos the Herald", level = 55, faction = "Neutral", giver = "Eva Sarkhoff", location = "Western Plaguelands, Caer Darrow", coords = "70, 73", notes = "Complete Krastinov's Bag of Horrors first; keep item #13544.", prereqs = { "Krastinov's Bag of Horrors" } },
      { name = "Dawn's Gambit", level = 57, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", notes = "Chain of 9 starting with Broodling Essence." },
      { name = "The Lich, Ras Frostwhisper", level = 57, faction = "Neutral", giver = "Magistrate Marduke", location = "Western Plaguelands, Caer Darrow", coords = "70, 74", notes = "Chain of 8 starting with Doctor Theolen Krastinov, the Butcher. Must have item #13544 equipped to see Marduke." },
    },
  },

  {
    name = "Stratholme: Live Side",
    aliases = { "Stratholme" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player needs The Scarlet Key (Live Side, Scarlet Hold) and the Key to the City (side entrance to Undead side); Lockpicking 275 also works for both.",
    quests = {
      { name = "The Great Ezra Grimm", level = 55, faction = "Neutral", giver = "Smokey LaRue", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "80, 58" },
      { name = "The Archivist", level = 55, faction = "Neutral", giver = "Duke Nicholas Zverenhoff", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "The Restless Souls", level = 55, faction = "Neutral", giver = "Egan", location = "Eastern Plaguelands, Terrordale", coords = "14, 33" },
      { name = "The Medallion of Faith", level = 55, faction = "Neutral", giver = "Aurius", location = "Stratholme, Undead Side, inside chapel at beginning", notes = "Complete The Restless Souls (Undead side) first.", prereqs = { "The Restless Souls" } },
      { name = "The Truth Comes Crashing Down", level = 55, faction = "Neutral", giver = "Drop: Head of Balnazzar from Balnazzar", location = "Stratholme, Live Side", notes = "Complete The Archivist to be eligible.", dungeonDrop = true, prereqs = { "The Archivist" } },
      { name = "Of Love and Family", level = 52, faction = "Neutral", giver = "Artist Renfray", location = "Western Plaguelands, Caer Darrow", coords = "65, 75", notes = "Chain of 7 starting with Blood Tinged Skies, Carrion Grubbage, and Demon Dogs." },
    },
  },

  {
    name = "Stratholme: Undead Side",
    aliases = { "Stratholme" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    quests = {
      { name = "Ramstein", level = 56, faction = "Neutral", giver = "Nathanos Blightcaller", location = "Eastern Plaguelands, Marris Stead", coords = "26, 74", notes = "Chain of 4 starting with The Ranger Lord's Behest and To Kill With Purpose." },
      { name = "Houses of the Holy", level = 55, faction = "Neutral", giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57" },
      { name = "The Flesh Does Not Lie", level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59" },
      { name = "The Active Agent", level = 55, faction = "Neutral", giver = "Betina Bigglezink", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", notes = "Complete The Flesh Does Not Lie first.", prereqs = { "The Flesh Does Not Lie" } },
      { name = "Aurius' Reckoning", level = 55, faction = "Neutral", giver = "Aurius", location = "Stratholme, Undead Side, chapel at beginning", notes = "Complete The Medallion of Faith first.", prereqs = { "The Medallion of Faith" } },
      { name = "Above and Beyond", level = 55, faction = "Neutral", giver = "Duke Nicholas Zverenhoff", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 59", notes = "Chain of 2 starting with The Archivist." },
      { name = "Menethil's Gift", level = 57, faction = "Neutral", giver = "Leonid Barthalomew the Revered", location = "Eastern Plaguelands, Light's Hope Chapel", coords = "81, 57", notes = "Chain of 5 starting with Doctor Theolen Krastinov, the Butcher." },
      { name = "Dead Man's Plea", level = 58, faction = "Neutral", giver = "Anthion Harmon", location = "Eastern Plaguelands, Stratholme Main Entrance", coords = "30, 16", notes = "Chain of 9 starting with A Supernatural Device. Requires the Extra-Dimensional Ghost Revealer to see the quest NPC." },
    },
  },

  {
    name = "Upper Blackrock Spire",
    aliases = { "Upper Blackrock Spire", "UBRS" },
    levels = { hard = 54, medium = 56, atLevel = 60 },
    keyNote = "At least one player must have item #12344 to enter Upper Blackrock Spire.",
    quests = {
      { name = "The Darkstone Tablet", level = 57, faction = "Neutral", giver = "Shadowmage Vivian Lagrave", location = "Badlands, Kargath", coords = "3, 48", notes = "Breadcrumb: Vivian Lagrave and the Darkstone Tablet in Undercity for easy XP." },
      { name = "For The Horde!", level = 55, faction = "Horde", giver = "Thrall", location = "Orgrimmar, Valley of Wisdom", coords = "31, 37", notes = "Chain of 2 starting with Warlord's Command." },
      { name = "Blood of the Black Dragon Champion", level = 55, faction = "Horde", giver = "Rexxar (patrols)", location = "Desolace", notes = "Chain of 13 starting with Warlord's Command." },
      { name = "Doomrigger's Clasp", level = 57, faction = "Alliance", giver = "Mayara Brightwing", location = "Burning Steppes, Morgan's Vigil", coords = "84, 69", notes = "Breadcrumb: Mayara Brightwing in Stormwind Keep for easy XP." },
      { name = "General Drakkisath's Demise", level = 55, faction = "Alliance", giver = "Marshal Maxwell", location = "Burning Steppes, Morgan's Vigil", coords = "84, 68", notes = "Requires General Drakkisath's Command first.", prereqs = { "General Drakkisath's Command" } },
      { name = "Drakefire Amulet", level = 50, faction = "Neutral", giver = "Haleh", location = "Winterspring, Mazthoril", coords = "56, 49", notes = "Chain of 10 starting with Dragonkin Menace. Step on the blue rune at end of cave to spawn NPC." },
      { name = "Blackhand's Command", level = 55, faction = "Neutral", giver = "Drop from Scarshield Quartermaster", location = "Blackrock Mountain, side hallway on the way to BWL", dungeonDrop = true },
      { name = "The Matron Protectorate", level = 57, faction = "Neutral", giver = "Awbee", location = "Blackrock Spire, Upper, ledge in room after killing Blackhand" },
      { name = "Finkle Einhorn, At Your Service!", level = 57, faction = "Neutral", giver = "Pip Quickwit", location = "Blackrock Spire, Upper", notes = "Only spawns after skinning (300) The Beast with Pip Quickwit." },
      { name = "Egg Collection", level = 57, faction = "Neutral", giver = "Tinkee Steamboil", location = "Burning Steppes, Flame Crest", coords = "65, 23", notes = "Chain of 6 starting with Egg Freezing and Broodling Essence from the same NPC." },
      { name = "Eye of the Emberseer", level = 55, faction = "Neutral", giver = "Duke Hydraxis", location = "Azshara", coords = "79, 73", notes = "Chain of 2 starting with Stormers and Rumblers, and Poisoned Water from the same NPC." },
      { name = "The Demon Forge", level = 55, faction = "Neutral", giver = "Lorax", location = "Winterspring, Southeast", coords = "63, 73", notes = "Blacksmiths only. Complete Lorax's Tale first. Rewards Plans: Demon Forged Breastplate.", prereqs = { "Lorax's Tale" } },
    },
  },
}
