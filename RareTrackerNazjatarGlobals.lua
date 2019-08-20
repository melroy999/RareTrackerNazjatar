-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTN.target_zones = {
    [1355] = true,
}

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTN.banned_NPC_ids = {
    [154297] = true,
    [150202] = true,
    [154304] = true,
    [152108] = true,
    [151300] = true,
    [151310] = true,
    [69792] = true,
    [62821] = true,
    [62822] = true,
    [32639] = true,
    [32638] = true,
    [89715] = true,
}

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

-- Get the rare names in the correct localization.
RTN.localization = GetLocale()
RTN.rare_names = {}

if RTN.localization == "deDE" then
    -- The names to be displayed in the frames and general chat messages for German localization.
    RTN.rare_names = {
        [152415] = "Alga der Augenlose",
        [152416] = "Allseher Oma'kil",
        [152794] = "Amethystspindelschnecke",
        [152566] = "Anemonar",
        [150191] = "Avarius",
        [152361] = "Fluchschuppe der Rudelvater",
        [152712] = "Blindlicht",
        [149653] = "Fleischfressender Peitscher",
        [152464] = "Höhlendunkelschrecken",
        [152556] = "Schluchtschatten",
        [152756] = "Dolchzahnschrecken",
        [152291] = "Tiefengleiter",
        [152414] = "Ältester Unu",
        [152555] = "Brutälteste von Nalaada",
        [65090] = "Fabius",
        [152553] = "Granatschuppe",
        [152448] = "Schillernde Schimmerschale",
        [152567] = "Tangwurz",
        [152323] = "König Gakula",
        [144644] = "Schlammkriecher",
        [152465] = "Nadelstachel",
        [152397] = "Oronu",
        [152681] = "Prinz Typhonus",
        [152682] = "Prinz Vortran",
        [150583] = "Felskrautschlurfer",
        [151870] = "Sandburg",
        [152795] = "Sandscherensteinpanzer",
        [152548] = "Schuppenmatriarchin Gratinax",
        [152545] = "Schuppenmatriarchin Vynara",
        [152542] = "Schuppenmatriarchin Zodia",
        [152552] = "Shassera",
        [153658] = "Shiz'narasz der Verschlinger",
        [152359] = "Schlickpirsch die Rudelmutter",
        [152290] = "Lautlos",
        [153898] = "Gezeitenlord Aquatus",
        [153928] = "Gezeitenlord Dispersius",
        [154148] = "Gezeitenherrin Leth'sindra",
        [152360] = "Toxigore der Alpha",
        [152568] = "Urduu",
        [151719] = "Stimme in den Tiefen",
        [150468] = "Vor'koth",
    }
elseif RTN.localization == "zhCN" then
    -- The names to be displayed in the frames and general chat messages for Simplified Chinese localization.
    RTN.rare_names = {
        [152415] = "无目的阿尔加",
        [152416] = "全视者奥玛基尔",
        [152794] = "紫晶尖壳蜗牛",
        [152566] = "阿尼莫纳",
        [150191] = "阿法留斯",
        [152361] = "巢父灾鳞",
        [152712] = "盲光",
        [149653] = "食肉鞭笞者",
        [152464] = "窟晦恐蟹",
        [152556] = "裂谷萦绕者",
        [152756] = "刀齿恐鱼",
        [152291] = "深渊滑行者",
        [152414] = "长者乌努",
        [152555] = "古裔纳拉达",
        [65090] = "法比乌斯",
        [152553] = "榴鳞",
        [152448] = "虹光烁壳蟹",
        [152567] = "柳藻",
        [152323] = "加库拉大王",
        [144644] = "深泽爬行者",
        [152465] = "针脊",
        [152397] = "奥洛努",
        [152681] = "泰丰努斯亲王",
        [152682] = "沃特兰亲王",
        [150583] = "岩草蹒跚者",
        [151870] = "沙堡",
        [152795] = "沙爪岩壳蟹",
        [152548] = "鳞母格拉提纳克丝",
        [152545] = "鳞母薇娜拉",
        [152542] = "鳞母佐迪亚",
        [152552] = "夏瑟拉",
        [153658] = "吞噬者席兹纳拉斯",
        [152359] = "巢母逐沙者",
        [152290] = "无声者",
        [153898] = "海潮领主阿库图斯",
        [153928] = "海潮领主迪斯派修斯",
        [154148] = "潮汐主母莱丝辛德拉",
        [152360] = "“头领”毒血",
        [152568] = "乌尔杜",
        [151719] = "深渊之声",
        [150468] = "沃科斯",
    }
else
    RTN.rare_names = {
        [152415] = "Alga the Eyeless",
        [152416] = "Allseer Oma'kil",
        [152794] = "Amethyst Spireshell",
        [152566] = "Anemonar",
        [150191] = "Avarius",
        [152361] = "Banescale the Packfather",
        [152712] = "Blindlight",
        [149653] = "Carnivorous Lasher",
        [152464] = "Caverndark Terror",
        [152556] = "Chasm-Haunter",
        [152756] = "Daggertooth Terror",
        [152291] = "Deepglider",
        [152414] = "Elder Unu",
        [152555] = "Elderspawn Nalaada",
        [65090] = "Fabious",
        [152553] = "Garnetscale",
        [152448] = "Iridescent Glimmershell",
        [152567] = "Kelpwillow",
        [152323] = "King Gakula",
        [144644] = "Mirecrawler",
        [152465] = "Needlespine",
        [152397] = "Oronu",
        [152681] = "Prince Typhonus",
        [152682] = "Prince Vortran",
        [150583] = "Rockweed Shambler",
        [151870] = "Sandcastle",
        [152795] = "Sandclaw Stoneshell",
        [152548] = "Scale Matriarch Gratinax",
        [152545] = "Scale Matriarch Vynara",
        [152542] = "Scale Matriarch Zodia",
        [152552] = "Shassera",
        [153658] = "Shiz'narasz the Consumer",
        [152359] = "Siltstalker the Packmother",
        [152290] = "Soundless",
        [153898] = "Tidelord Aquatus",
        [153928] = "Tidelord Dispersius",
        [154148] = "Tidemistress Leth'sindra",
        [152360] = "Toxigore the Alpha",
        [152568] = "Urduu",
        [151719] = "Voice in the Deeps",
        [150468] = "Vor'koth",
    }
end

-- The quest ids that indicate that the rare has been killed already.
RTN.completion_quest_ids = {
    [152415] = 56279, -- "Alga the Eyeless"
    [152416] = 56280, -- "Allseer Oma'kil"
    [152794] = 56268, -- "Amethyst Spireshell"
    [152566] = 56281, -- "Anemonar"
    [150191] = 55584, -- "Avarius"
    [152361] = 56282, -- "Banescale the Packfather"
    [152712] = 56269, -- "Blindlight"
    [149653] = 55366, -- "Carnivorous Lasher"
    [152464] = 56283, -- "Caverndark Terror"
    [152556] = 56270, -- "Chasm-Haunter"
    [152756] = 56271, -- "Daggertooth Terror"
    [152291] = 56272, -- "Deepglider"
    [152414] = 56284, -- "Elder Unu"
    [152555] = 56285, -- "Elderspawn Nalaada"
    [152553] = 56273, -- "Garnetscale"
    [152448] = 56286, -- "Iridescent Glimmershell"
    [152567] = 56287, -- "Kelpwillow"
    [152323] = 55671, -- "King Gakula"
    [144644] = 56274, -- "Mirecrawler"
    [152465] = 56275, -- "Needlespine"
    [152397] = 56288, -- "Oronu"
    [152681] = 56289, -- "Prince Typhonus"
    [152682] = 56290, -- "Prince Vortran"
    [150583] = 56291, -- "Rockweed Shambler"
    [151870] = 56276, -- "Sandcastle"
    [152795] = 56277, -- "Sandclaw Stoneshell"
    [152548] = 56292, -- "Scale Matriarch Gratinax"
    [152545] = 56293, -- "Scale Matriarch Vynara"
    [152542] = 56294, -- "Scale Matriarch Zodia"
    [152552] = 56295, -- "Shassera"
    [153658] = 56296, -- "Shiz'narasz the Consumer"
    [152359] = 56297, -- "Siltstalker the Packmother"
    [152290] = 56298, -- "Soundless"
    [153898] = 56122, -- "Tidelord Aquatus"
    [153928] = 56123, -- "Tidelord Dispersius"
    [154148] = 56106, -- "Tidemistress Leth'sindra"
    [152360] = 56278, -- "Toxigore the Alpha"
    [152568] = 56299, -- "Urduu"
    [151719] = 56300, -- "Voice in the Deeps"
    [150468] = 55603, -- "Vor'koth"
}

RTN.completion_quest_inverse = {
    [56279] = {152415},
    [56280] = {152416},
    [56268] = {152794},
    [56281] = {152566},
    [55584] = {150191},
    [56282] = {152361},
    [56269] = {152712},
    [55366] = {149653},
    [56283] = {152464},
    [56270] = {152556},
    [56271] = {152756},
    [56272] = {152291},
    [56284] = {152414},
    [56285] = {152555},
    [56273] = {152553},
    [56286] = {152448},
    [56287] = {152567},
    [55671] = {152323},
    [56274] = {144644},
    [56275] = {152465},
    [56288] = {152397},
    [56289] = {152681},
    [56290] = {152682},
    [56291] = {150583},
    [56276] = {151870},
    [56277] = {152795},
    [56292] = {152548},
    [56293] = {152545},
    [56294] = {152542},
    [56295] = {152552},
    [56296] = {153658},
    [56297] = {152359},
    [56298] = {152290},
    [56122] = {153898},
    [56123] = {153928},
    [56106] = {154148},
    [56278] = {152360},
    [56299] = {152568},
    [56300] = {151719},
    [55603] = {150468},
}