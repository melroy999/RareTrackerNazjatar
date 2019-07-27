-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTN.target_zones = {}
RTN.target_zones[1355] = true

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTN.banned_NPC_ids = {}
RTN.banned_NPC_ids[154297] = true
RTN.banned_NPC_ids[150202] = true
RTN.banned_NPC_ids[154304] = true
RTN.banned_NPC_ids[152108] = true
RTN.banned_NPC_ids[151300] = true
RTN.banned_NPC_ids[151310] = true
RTN.banned_NPC_ids[69792] = true
RTN.banned_NPC_ids[62821] = true
RTN.banned_NPC_ids[62822] = true
RTN.banned_NPC_ids[32639] = true
RTN.banned_NPC_ids[32638] = true
RTN.banned_NPC_ids[89715] = true

-- Simulate a set data structure for efficient existence lookups.
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- The ids of the rares the addon monitors.
RTN.rare_ids = {
	152415, -- "Alga the Eyeless"
	152416, -- "Allseer Oma'kil"
	152794, -- "Amethyst Spireshell"
	152566, -- "Anemonar"
	150191, -- "Avarius"
	152361, -- "Banescale the Packfather"
	152712, -- "Blindlight"
	149653, -- "Carnivorous Lasher"
	152464, -- "Caverndark Terror"
	152556, -- "Chasm-Haunter"
	152756, -- "Daggertooth Terror"
	152291, -- "Deepglider"
	152414, -- "Elder Unu"
	152555, -- "Elderspawn Nalaada"
	65090, -- "Fabious"
	152553, -- "Garnetscale"
	152448, -- "Iridescent Glimmershell"
	152567, -- "Kelpwillow"
	152323, -- "King Gakula"
	144644, -- "Mirecrawler"
	152465, -- "Needlespine"
	152397, -- "Oronu"
	152681, -- "Prince Typhonus"
	152682, -- "Prince Vortran"
	150583, -- "Rockweed Shambler"
	151870, -- "Sandcastle"
	152795, -- "Sandclaw Stoneshell"
	152548, -- "Scale Matriarch Gratinax"
	152545, -- "Scale Matriarch Vynara"
	152542, -- "Scale Matriarch Zodia"
	152552, -- "Shassera"
	153658, -- "Shiz'narasz the Consumer"
	152359, -- "Siltstalker the Packmother"
	152290, -- "Soundless"
	153898, -- "Tidelord Aquatus"
	153928, -- "Tidelord Dispersius"
	154148, -- "Tidemistress Leth'sindra"
	152360, -- "Toxigore the Alpha"
	152568, -- "Urduu"
	151719, -- "Voice in the Deeps"
	150468, -- "Vor'koth"
}

RTN.rare_ids_set = Set(RTN.rare_ids)

RTN.rare_names_localized = {}
RTN.rare_names_localized["enUS"] = {}
RTN.rare_names_localized["enUS"][152415] = "Alga the Eyeless"
RTN.rare_names_localized["enUS"][152416] = "Allseer Oma'kil"
RTN.rare_names_localized["enUS"][152794] = "Amethyst Spireshell"
RTN.rare_names_localized["enUS"][152566] = "Anemonar"
RTN.rare_names_localized["enUS"][150191] = "Avarius"
RTN.rare_names_localized["enUS"][152361] = "Banescale the Packfather"
RTN.rare_names_localized["enUS"][152712] = "Blindlight"
RTN.rare_names_localized["enUS"][149653] = "Carnivorous Lasher"
RTN.rare_names_localized["enUS"][152464] = "Caverndark Terror"
RTN.rare_names_localized["enUS"][152556] = "Chasm-Haunter"
RTN.rare_names_localized["enUS"][152756] = "Daggertooth Terror"
RTN.rare_names_localized["enUS"][152291] = "Deepglider"
RTN.rare_names_localized["enUS"][152414] = "Elder Unu"
RTN.rare_names_localized["enUS"][152555] = "Elderspawn Nalaada"
RTN.rare_names_localized["enUS"][65090] = "Fabious"
RTN.rare_names_localized["enUS"][152553] = "Garnetscale"
RTN.rare_names_localized["enUS"][152448] = "Iridescent Glimmershell"
RTN.rare_names_localized["enUS"][152567] = "Kelpwillow"
RTN.rare_names_localized["enUS"][152323] = "King Gakula"
RTN.rare_names_localized["enUS"][144644] = "Mirecrawler"
RTN.rare_names_localized["enUS"][152465] = "Needlespine"
RTN.rare_names_localized["enUS"][152397] = "Oronu"
RTN.rare_names_localized["enUS"][152681] = "Prince Typhonus"
RTN.rare_names_localized["enUS"][152682] = "Prince Vortran"
RTN.rare_names_localized["enUS"][150583] = "Rockweed Shambler"
RTN.rare_names_localized["enUS"][151870] = "Sandcastle"
RTN.rare_names_localized["enUS"][152795] = "Sandclaw Stoneshell"
RTN.rare_names_localized["enUS"][152548] = "Scale Matriarch Gratinax"
RTN.rare_names_localized["enUS"][152545] = "Scale Matriarch Vynara"
RTN.rare_names_localized["enUS"][152542] = "Scale Matriarch Zodia"
RTN.rare_names_localized["enUS"][152552] = "Shassera"
RTN.rare_names_localized["enUS"][153658] = "Shiz'narasz the Consumer"
RTN.rare_names_localized["enUS"][152359] = "Siltstalker the Packmother"
RTN.rare_names_localized["enUS"][152290] = "Soundless"
RTN.rare_names_localized["enUS"][153898] = "Tidelord Aquatus"
RTN.rare_names_localized["enUS"][153928] = "Tidelord Dispersius"
RTN.rare_names_localized["enUS"][154148] = "Tidemistress Leth'sindra"
RTN.rare_names_localized["enUS"][152360] = "Toxigore the Alpha"
RTN.rare_names_localized["enUS"][152568] = "Urduu"
RTN.rare_names_localized["enUS"][151719] = "Voice in the Deeps"
RTN.rare_names_localized["enUS"][150468] = "Vor'koth"

-- The names to be displayed in the frames and general chat messages for English (GB) localization.
RTN.rare_names_localized["enGB"] = RTN.rare_names_localized["enUS"]

-- The names to be displayed in the frames and general chat messages for German localization.
RTN.rare_names_localized["deDE"] = {}
RTN.rare_names_localized["deDE"][152415] = "Alga der Augenlose"
RTN.rare_names_localized["deDE"][152416] = "Allseher Oma'kil"
RTN.rare_names_localized["deDE"][152794] = "Amethystspindelschnecke"
RTN.rare_names_localized["deDE"][152566] = "Anemonar"
RTN.rare_names_localized["deDE"][150191] = "Avarius"
RTN.rare_names_localized["deDE"][152361] = "Fluchschuppe der Rudelvater"
RTN.rare_names_localized["deDE"][152712] = "Blindlicht"
RTN.rare_names_localized["deDE"][149653] = "Fleischfressender Peitscher"
RTN.rare_names_localized["deDE"][152464] = "Höhlendunkelschrecken"
RTN.rare_names_localized["deDE"][152556] = "Schluchtschatten"
RTN.rare_names_localized["deDE"][152756] = "Dolchzahnschrecken"
RTN.rare_names_localized["deDE"][152291] = "Tiefengleiter"
RTN.rare_names_localized["deDE"][152414] = "Ältester Unu"
RTN.rare_names_localized["deDE"][152555] = "Brutälteste von Nalaada"
RTN.rare_names_localized["deDE"][65090] = "Fabius"
RTN.rare_names_localized["deDE"][152553] = "Granatschuppe"
RTN.rare_names_localized["deDE"][152448] = "Schillernde Schimmerschale"
RTN.rare_names_localized["deDE"][152567] = "Tangwurz"
RTN.rare_names_localized["deDE"][152323] = "König Gakula"
RTN.rare_names_localized["deDE"][144644] = "Schlammkriecher"
RTN.rare_names_localized["deDE"][152465] = "Nadelstachel"
RTN.rare_names_localized["deDE"][152397] = "Oronu"
RTN.rare_names_localized["deDE"][152681] = "Prinz Typhonus"
RTN.rare_names_localized["deDE"][152682] = "Prinz Vortran"
RTN.rare_names_localized["deDE"][150583] = "Felskrautschlurfer"
RTN.rare_names_localized["deDE"][151870] = "Sandburg"
RTN.rare_names_localized["deDE"][152795] = "Sandscherensteinpanzer"
RTN.rare_names_localized["deDE"][152548] = "Schuppenmatriarchin Gratinax"
RTN.rare_names_localized["deDE"][152545] = "Schuppenmatriarchin Vynara"
RTN.rare_names_localized["deDE"][152542] = "Schuppenmatriarchin Zodia"
RTN.rare_names_localized["deDE"][152552] = "Shassera"
RTN.rare_names_localized["deDE"][153658] = "Shiz'narasz der Verschlinger"
RTN.rare_names_localized["deDE"][152359] = "Schlickpirsch die Rudelmutter"
RTN.rare_names_localized["deDE"][152290] = "Lautlos"
RTN.rare_names_localized["deDE"][153898] = "Gezeitenlord Aquatus"
RTN.rare_names_localized["deDE"][153928] = "Gezeitenlord Dispersius"
RTN.rare_names_localized["deDE"][154148] = "Gezeitenherrin Leth'sindra"
RTN.rare_names_localized["deDE"][152360] = "Toxigore der Alpha"
RTN.rare_names_localized["deDE"][152568] = "Urduu"
RTN.rare_names_localized["deDE"][151719] = "Stimme in den Tiefen"
RTN.rare_names_localized["deDE"][150468] = "Vor'koth"

-- All other localizations are displayed in English.
RTN.rare_names_localized["frFR"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["itIT"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["zhCN"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["zhTW"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["koKR"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["ruRU"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["esES"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["esMX"] = RTN.rare_names_localized["enUS"]
RTN.rare_names_localized["ptBR"] = RTN.rare_names_localized["enUS"]

-- Select the rare name table, using the localization.
RTN.localization = GetLocale()
RTN.rare_names = RTN.rare_names_localized[RTN.localization]

-- The quest ids that indicate that the rare has been killed already.
RTN.completion_quest_ids = {}
RTN.completion_quest_ids[152415] = 56279 -- "Alga the Eyeless"
RTN.completion_quest_ids[152416] = 56280 -- "Allseer Oma'kil"
RTN.completion_quest_ids[152794] = 56268 -- "Amethyst Spireshell"
RTN.completion_quest_ids[152566] = 56281 -- "Anemonar"
RTN.completion_quest_ids[150191] = 55584 -- "Avarius"
RTN.completion_quest_ids[152361] = 56282 -- "Banescale the Packfather"
RTN.completion_quest_ids[152712] = 56269 -- "Blindlight"
RTN.completion_quest_ids[149653] = 55366 -- "Carnivorous Lasher"
RTN.completion_quest_ids[152464] = 56283 -- "Caverndark Terror"
RTN.completion_quest_ids[152556] = 56270 -- "Chasm-Haunter"
RTN.completion_quest_ids[152756] = 56271 -- "Daggertooth Terror"
RTN.completion_quest_ids[152291] = 56272 -- "Deepglider"
RTN.completion_quest_ids[152414] = 56284 -- "Elder Unu"
RTN.completion_quest_ids[152555] = 56285 -- "Elderspawn Nalaada"
RTN.completion_quest_ids[152553] = 56273 -- "Garnetscale"
RTN.completion_quest_ids[152448] = 56286 -- "Iridescent Glimmershell"
RTN.completion_quest_ids[152567] = 56287 -- "Kelpwillow"
RTN.completion_quest_ids[152323] = 55671 -- "King Gakula"
RTN.completion_quest_ids[144644] = 56274 -- "Mirecrawler"
RTN.completion_quest_ids[152465] = 56275 -- "Needlespine"
RTN.completion_quest_ids[152397] = 56288 -- "Oronu"
RTN.completion_quest_ids[152681] = 56289 -- "Prince Typhonus"
RTN.completion_quest_ids[152682] = 56290 -- "Prince Vortran"
RTN.completion_quest_ids[150583] = 56291 -- "Rockweed Shambler"
RTN.completion_quest_ids[151870] = 56276 -- "Sandcastle"
RTN.completion_quest_ids[152795] = 56277 -- "Sandclaw Stoneshell"
RTN.completion_quest_ids[152548] = 56292 -- "Scale Matriarch Gratinax"
RTN.completion_quest_ids[152545] = 56293 -- "Scale Matriarch Vynara"
RTN.completion_quest_ids[152542] = 56294 -- "Scale Matriarch Zodia"
RTN.completion_quest_ids[152552] = 56295 -- "Shassera"
RTN.completion_quest_ids[153658] = 56296 -- "Shiz'narasz the Consumer"
RTN.completion_quest_ids[152359] = 56297 -- "Siltstalker the Packmother"
RTN.completion_quest_ids[152290] = 56298 -- "Soundless"
RTN.completion_quest_ids[153898] = 56122 -- "Tidelord Aquatus"
RTN.completion_quest_ids[153928] = 56123 -- "Tidelord Dispersius"
RTN.completion_quest_ids[154148] = 56106 -- "Tidemistress Leth'sindra"
RTN.completion_quest_ids[152360] = 56278 -- "Toxigore the Alpha"
RTN.completion_quest_ids[152568] = 56299 -- "Urduu"
RTN.completion_quest_ids[151719] = 56300 -- "Voice in the Deeps"
RTN.completion_quest_ids[150468] = 55603 -- "Vor'koth"

RTN.completion_quest_inverse = {}
RTN.completion_quest_inverse[56279] = {152415}
RTN.completion_quest_inverse[56280] = {152416}
RTN.completion_quest_inverse[56268] = {152794}
RTN.completion_quest_inverse[56281] = {152566}
RTN.completion_quest_inverse[55584] = {150191}
RTN.completion_quest_inverse[56282] = {152361}
RTN.completion_quest_inverse[56269] = {152712}
RTN.completion_quest_inverse[55366] = {149653}
RTN.completion_quest_inverse[56283] = {152464}
RTN.completion_quest_inverse[56270] = {152556}
RTN.completion_quest_inverse[56271] = {152756}
RTN.completion_quest_inverse[56272] = {152291}
RTN.completion_quest_inverse[56284] = {152414}
RTN.completion_quest_inverse[56285] = {152555}
RTN.completion_quest_inverse[56273] = {152553}
RTN.completion_quest_inverse[56286] = {152448}
RTN.completion_quest_inverse[56287] = {152567}
RTN.completion_quest_inverse[55671] = {152323}
RTN.completion_quest_inverse[56274] = {144644}
RTN.completion_quest_inverse[56275] = {152465}
RTN.completion_quest_inverse[56288] = {152397}
RTN.completion_quest_inverse[56289] = {152681}
RTN.completion_quest_inverse[56290] = {152682}
RTN.completion_quest_inverse[56291] = {150583}
RTN.completion_quest_inverse[56276] = {151870}
RTN.completion_quest_inverse[56277] = {152795}
RTN.completion_quest_inverse[56292] = {152548}
RTN.completion_quest_inverse[56293] = {152545}
RTN.completion_quest_inverse[56294] = {152542}
RTN.completion_quest_inverse[56295] = {152552}
RTN.completion_quest_inverse[56296] = {153658}
RTN.completion_quest_inverse[56297] = {152359}
RTN.completion_quest_inverse[56298] = {152290}
RTN.completion_quest_inverse[56122] = {153898}
RTN.completion_quest_inverse[56123] = {153928}
RTN.completion_quest_inverse[56106] = {154148}
RTN.completion_quest_inverse[56278] = {152360}
RTN.completion_quest_inverse[56299] = {152568}
RTN.completion_quest_inverse[56300] = {151719}
RTN.completion_quest_inverse[55603] = {150468}

