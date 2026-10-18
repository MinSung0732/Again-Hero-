extends RefCounted
class_name MonsterCatalog

const FRONTIER := preload("res://src/data/frontier_monster_catalog.gd")
const BALANCE := preload("res://src/data/monster_balance_catalog.gd")
static var balanced_stats_cache: Dictionary = {}
const EMPTY_RUNTIME_SCALING := {}
const EMPTY_GIANT_SCALING := {}
const EMPTY_PROPERTY_MULTIPLIERS := {}
const EMPTY_GIANT_STAT_PROPERTIES := []

enum EliteSpawnPosition { EVENT_RING, FARTHEST_ATTACK_RANGE }
const DEFAULT_ELITE_SPAWN_DISTANCE := 720.0
const DEFAULT_ELITE_SPAWN := {
	"position_policy": EliteSpawnPosition.EVENT_RING,
	"spawn_distance": DEFAULT_ELITE_SPAWN_DISTANCE,
	"alive_registration_method": &"",
}

const ORDER := [
	"iron_beetle",
	"lantern_wisp",
	"blade_mantis",
	"moss_deer",

	"cave_ant",
	"thorn_hedgehog",
	"spore_mushroom",
	"shell_crab",
	"swamp_toad",
	"rag_scarecrow",
	"rust_automaton",

	"crystal_tortoise",
	"ember_salamander",
	"frost_owl",
	"thorn_dryad",
	"dusk_panther",
	"rune_sentinel",
	"venom_scorpion",
	"moon_moth",
	"harpy",
	"imp",
	"mimic",
	"mud_golem",
	"satyr_rogue",
	"satyr_shaman",
	"skeleton_shield",
	"toxic_slime",

	"fanatic",
	"gumiho",
	"slime",
	"spider",
	"orc",
	"bomb_rat",
	"boar",
	"dark_elf_archer",
	"dark_elf_rogue",
	"skeleton",
	"skeleton_archer",
	"kobolt",
	"bat",
	"goblin",
	"goblin_thrower",
	"ghost",
	"banshee",
	"dullahan",
	"kraken",
	"medusa",
	"anubis",
	"mummy",
	"powwow_mummy",
	"scorpion",
	"succubus",
	"wolf",
	"yuki_onna",
	"gargoyle",
	"hobgoblin",
	"ogre",
	"lizardman_fighter",
	"lizardman_spearman",
	"zeus",
	"bulgasal",
	"izanami",
	"manticore",
	"shuten_doji",
	"arthur",
]

const DULLAHAN_BEHAVIOR := preload("res://src/data/dullahan_behavior_catalog.gd")

const KRAKEN_BEHAVIOR := preload("res://src/data/kraken_behavior_catalog.gd")
const MEDUSA_BEHAVIOR := preload("res://src/data/medusa_behavior_catalog.gd")
const BULGASAL_BEHAVIOR := preload("res://src/data/bulgasal_behavior_catalog.gd")
const MONSTERS := {
	"cave_ant": {"ground_shadow":FRONTIER.DEFINITIONS.cave_ant.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.cave_ant.hero_survival_after, "id":FRONTIER.DEFINITIONS.cave_ant.id, "name":FRONTIER.DEFINITIONS.cave_ant.name, "grade":FRONTIER.DEFINITIONS.cave_ant.grade, "rarity":FRONTIER.DEFINITIONS.cave_ant.rarity, "role":FRONTIER.DEFINITIONS.cave_ant.role, "family":FRONTIER.DEFINITIONS.cave_ant.family, "species":FRONTIER.DEFINITIONS.cave_ant.species, "base_cost":FRONTIER.DEFINITIONS.cave_ant.base_cost, "summon_exp":FRONTIER.DEFINITIONS.cave_ant.summon_exp, "attack_type":FRONTIER.DEFINITIONS.cave_ant.attack_type, "base_stats":FRONTIER.DEFINITIONS.cave_ant.base_stats, "balance":FRONTIER.DEFINITIONS.cave_ant.balance, "description":FRONTIER.DEFINITIONS.cave_ant.description, "special_augment_ids":FRONTIER.DEFINITIONS.cave_ant.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.cave_ant.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.cave_ant.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.cave_ant.elite_visual, "scene":preload("res://src/monsters/FrontierCaveAnt.tscn")},
	"thorn_hedgehog": {"ground_shadow":FRONTIER.DEFINITIONS.thorn_hedgehog.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.thorn_hedgehog.hero_survival_after, "id":FRONTIER.DEFINITIONS.thorn_hedgehog.id, "name":FRONTIER.DEFINITIONS.thorn_hedgehog.name, "grade":FRONTIER.DEFINITIONS.thorn_hedgehog.grade, "rarity":FRONTIER.DEFINITIONS.thorn_hedgehog.rarity, "role":FRONTIER.DEFINITIONS.thorn_hedgehog.role, "family":FRONTIER.DEFINITIONS.thorn_hedgehog.family, "species":FRONTIER.DEFINITIONS.thorn_hedgehog.species, "base_cost":FRONTIER.DEFINITIONS.thorn_hedgehog.base_cost, "summon_exp":FRONTIER.DEFINITIONS.thorn_hedgehog.summon_exp, "attack_type":FRONTIER.DEFINITIONS.thorn_hedgehog.attack_type, "base_stats":FRONTIER.DEFINITIONS.thorn_hedgehog.base_stats, "balance":FRONTIER.DEFINITIONS.thorn_hedgehog.balance, "description":FRONTIER.DEFINITIONS.thorn_hedgehog.description, "special_augment_ids":FRONTIER.DEFINITIONS.thorn_hedgehog.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.thorn_hedgehog.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.thorn_hedgehog.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.thorn_hedgehog.elite_visual, "scene":preload("res://src/monsters/FrontierThornHedgehog.tscn")},
	"spore_mushroom": {"ground_shadow":FRONTIER.DEFINITIONS.spore_mushroom.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.spore_mushroom.hero_survival_after, "id":FRONTIER.DEFINITIONS.spore_mushroom.id, "name":FRONTIER.DEFINITIONS.spore_mushroom.name, "grade":FRONTIER.DEFINITIONS.spore_mushroom.grade, "rarity":FRONTIER.DEFINITIONS.spore_mushroom.rarity, "role":FRONTIER.DEFINITIONS.spore_mushroom.role, "family":FRONTIER.DEFINITIONS.spore_mushroom.family, "species":FRONTIER.DEFINITIONS.spore_mushroom.species, "base_cost":FRONTIER.DEFINITIONS.spore_mushroom.base_cost, "summon_exp":FRONTIER.DEFINITIONS.spore_mushroom.summon_exp, "attack_type":FRONTIER.DEFINITIONS.spore_mushroom.attack_type, "base_stats":FRONTIER.DEFINITIONS.spore_mushroom.base_stats, "balance":FRONTIER.DEFINITIONS.spore_mushroom.balance, "description":FRONTIER.DEFINITIONS.spore_mushroom.description, "special_augment_ids":FRONTIER.DEFINITIONS.spore_mushroom.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.spore_mushroom.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.spore_mushroom.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.spore_mushroom.elite_visual, "scene":preload("res://src/monsters/FrontierSporeMushroom.tscn")},
	"shell_crab": {"ground_shadow":FRONTIER.DEFINITIONS.shell_crab.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.shell_crab.hero_survival_after, "id":FRONTIER.DEFINITIONS.shell_crab.id, "name":FRONTIER.DEFINITIONS.shell_crab.name, "grade":FRONTIER.DEFINITIONS.shell_crab.grade, "rarity":FRONTIER.DEFINITIONS.shell_crab.rarity, "role":FRONTIER.DEFINITIONS.shell_crab.role, "family":FRONTIER.DEFINITIONS.shell_crab.family, "species":FRONTIER.DEFINITIONS.shell_crab.species, "base_cost":FRONTIER.DEFINITIONS.shell_crab.base_cost, "summon_exp":FRONTIER.DEFINITIONS.shell_crab.summon_exp, "attack_type":FRONTIER.DEFINITIONS.shell_crab.attack_type, "base_stats":FRONTIER.DEFINITIONS.shell_crab.base_stats, "balance":FRONTIER.DEFINITIONS.shell_crab.balance, "description":FRONTIER.DEFINITIONS.shell_crab.description, "special_augment_ids":FRONTIER.DEFINITIONS.shell_crab.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.shell_crab.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.shell_crab.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.shell_crab.elite_visual, "scene":preload("res://src/monsters/FrontierShellCrab.tscn")},
	"swamp_toad": {"ground_shadow":FRONTIER.DEFINITIONS.swamp_toad.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.swamp_toad.hero_survival_after, "id":FRONTIER.DEFINITIONS.swamp_toad.id, "name":FRONTIER.DEFINITIONS.swamp_toad.name, "grade":FRONTIER.DEFINITIONS.swamp_toad.grade, "rarity":FRONTIER.DEFINITIONS.swamp_toad.rarity, "role":FRONTIER.DEFINITIONS.swamp_toad.role, "family":FRONTIER.DEFINITIONS.swamp_toad.family, "species":FRONTIER.DEFINITIONS.swamp_toad.species, "base_cost":FRONTIER.DEFINITIONS.swamp_toad.base_cost, "summon_exp":FRONTIER.DEFINITIONS.swamp_toad.summon_exp, "attack_type":FRONTIER.DEFINITIONS.swamp_toad.attack_type, "base_stats":FRONTIER.DEFINITIONS.swamp_toad.base_stats, "balance":FRONTIER.DEFINITIONS.swamp_toad.balance, "description":FRONTIER.DEFINITIONS.swamp_toad.description, "special_augment_ids":FRONTIER.DEFINITIONS.swamp_toad.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.swamp_toad.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.swamp_toad.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.swamp_toad.elite_visual, "scene":preload("res://src/monsters/FrontierSwampToad.tscn")},
	"rag_scarecrow": {"ground_shadow":FRONTIER.DEFINITIONS.rag_scarecrow.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.rag_scarecrow.hero_survival_after, "id":FRONTIER.DEFINITIONS.rag_scarecrow.id, "name":FRONTIER.DEFINITIONS.rag_scarecrow.name, "grade":FRONTIER.DEFINITIONS.rag_scarecrow.grade, "rarity":FRONTIER.DEFINITIONS.rag_scarecrow.rarity, "role":FRONTIER.DEFINITIONS.rag_scarecrow.role, "family":FRONTIER.DEFINITIONS.rag_scarecrow.family, "species":FRONTIER.DEFINITIONS.rag_scarecrow.species, "base_cost":FRONTIER.DEFINITIONS.rag_scarecrow.base_cost, "summon_exp":FRONTIER.DEFINITIONS.rag_scarecrow.summon_exp, "attack_type":FRONTIER.DEFINITIONS.rag_scarecrow.attack_type, "base_stats":FRONTIER.DEFINITIONS.rag_scarecrow.base_stats, "balance":FRONTIER.DEFINITIONS.rag_scarecrow.balance, "description":FRONTIER.DEFINITIONS.rag_scarecrow.description, "special_augment_ids":FRONTIER.DEFINITIONS.rag_scarecrow.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.rag_scarecrow.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.rag_scarecrow.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.rag_scarecrow.elite_visual, "scene":preload("res://src/monsters/FrontierRagScarecrow.tscn")},
	"rust_automaton": {"ground_shadow":FRONTIER.DEFINITIONS.rust_automaton.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.rust_automaton.hero_survival_after, "id":FRONTIER.DEFINITIONS.rust_automaton.id, "name":FRONTIER.DEFINITIONS.rust_automaton.name, "grade":FRONTIER.DEFINITIONS.rust_automaton.grade, "rarity":FRONTIER.DEFINITIONS.rust_automaton.rarity, "role":FRONTIER.DEFINITIONS.rust_automaton.role, "family":FRONTIER.DEFINITIONS.rust_automaton.family, "species":FRONTIER.DEFINITIONS.rust_automaton.species, "base_cost":FRONTIER.DEFINITIONS.rust_automaton.base_cost, "summon_exp":FRONTIER.DEFINITIONS.rust_automaton.summon_exp, "attack_type":FRONTIER.DEFINITIONS.rust_automaton.attack_type, "base_stats":FRONTIER.DEFINITIONS.rust_automaton.base_stats, "balance":FRONTIER.DEFINITIONS.rust_automaton.balance, "description":FRONTIER.DEFINITIONS.rust_automaton.description, "special_augment_ids":FRONTIER.DEFINITIONS.rust_automaton.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.rust_automaton.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.rust_automaton.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.rust_automaton.elite_visual, "scene":preload("res://src/monsters/FrontierRustAutomaton.tscn")},
	"iron_beetle": {"ground_shadow":FRONTIER.DEFINITIONS.iron_beetle.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.iron_beetle.hero_survival_after, "id":FRONTIER.DEFINITIONS.iron_beetle.id, "name":FRONTIER.DEFINITIONS.iron_beetle.name, "grade":FRONTIER.DEFINITIONS.iron_beetle.grade, "rarity":FRONTIER.DEFINITIONS.iron_beetle.rarity, "role":FRONTIER.DEFINITIONS.iron_beetle.role, "family":FRONTIER.DEFINITIONS.iron_beetle.family, "species":FRONTIER.DEFINITIONS.iron_beetle.species, "base_cost":FRONTIER.DEFINITIONS.iron_beetle.base_cost, "summon_exp":FRONTIER.DEFINITIONS.iron_beetle.summon_exp, "attack_type":FRONTIER.DEFINITIONS.iron_beetle.attack_type, "base_stats":FRONTIER.DEFINITIONS.iron_beetle.base_stats, "balance":FRONTIER.DEFINITIONS.iron_beetle.balance, "description":FRONTIER.DEFINITIONS.iron_beetle.description, "special_augment_ids":FRONTIER.DEFINITIONS.iron_beetle.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.iron_beetle.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.iron_beetle.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.iron_beetle.elite_visual, "scene":preload("res://src/monsters/FrontierIronBeetle.tscn")},
	"lantern_wisp": {"ground_shadow":FRONTIER.DEFINITIONS.lantern_wisp.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.lantern_wisp.hero_survival_after, "id":FRONTIER.DEFINITIONS.lantern_wisp.id, "name":FRONTIER.DEFINITIONS.lantern_wisp.name, "grade":FRONTIER.DEFINITIONS.lantern_wisp.grade, "rarity":FRONTIER.DEFINITIONS.lantern_wisp.rarity, "role":FRONTIER.DEFINITIONS.lantern_wisp.role, "family":FRONTIER.DEFINITIONS.lantern_wisp.family, "species":FRONTIER.DEFINITIONS.lantern_wisp.species, "base_cost":FRONTIER.DEFINITIONS.lantern_wisp.base_cost, "summon_exp":FRONTIER.DEFINITIONS.lantern_wisp.summon_exp, "attack_type":FRONTIER.DEFINITIONS.lantern_wisp.attack_type, "base_stats":FRONTIER.DEFINITIONS.lantern_wisp.base_stats, "balance":FRONTIER.DEFINITIONS.lantern_wisp.balance, "description":FRONTIER.DEFINITIONS.lantern_wisp.description, "special_augment_ids":FRONTIER.DEFINITIONS.lantern_wisp.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.lantern_wisp.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.lantern_wisp.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.lantern_wisp.elite_visual, "scene":preload("res://src/monsters/FrontierLanternWisp.tscn")},
	"blade_mantis": {"ground_shadow":FRONTIER.DEFINITIONS.blade_mantis.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.blade_mantis.hero_survival_after, "id":FRONTIER.DEFINITIONS.blade_mantis.id, "name":FRONTIER.DEFINITIONS.blade_mantis.name, "grade":FRONTIER.DEFINITIONS.blade_mantis.grade, "rarity":FRONTIER.DEFINITIONS.blade_mantis.rarity, "role":FRONTIER.DEFINITIONS.blade_mantis.role, "family":FRONTIER.DEFINITIONS.blade_mantis.family, "species":FRONTIER.DEFINITIONS.blade_mantis.species, "base_cost":FRONTIER.DEFINITIONS.blade_mantis.base_cost, "summon_exp":FRONTIER.DEFINITIONS.blade_mantis.summon_exp, "attack_type":FRONTIER.DEFINITIONS.blade_mantis.attack_type, "base_stats":FRONTIER.DEFINITIONS.blade_mantis.base_stats, "balance":FRONTIER.DEFINITIONS.blade_mantis.balance, "description":FRONTIER.DEFINITIONS.blade_mantis.description, "special_augment_ids":FRONTIER.DEFINITIONS.blade_mantis.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.blade_mantis.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.blade_mantis.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.blade_mantis.elite_visual, "scene":preload("res://src/monsters/FrontierBladeMantis.tscn")},
	"moss_deer": {"ground_shadow":FRONTIER.DEFINITIONS.moss_deer.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.moss_deer.hero_survival_after, "id":FRONTIER.DEFINITIONS.moss_deer.id, "name":FRONTIER.DEFINITIONS.moss_deer.name, "grade":FRONTIER.DEFINITIONS.moss_deer.grade, "rarity":FRONTIER.DEFINITIONS.moss_deer.rarity, "role":FRONTIER.DEFINITIONS.moss_deer.role, "family":FRONTIER.DEFINITIONS.moss_deer.family, "species":FRONTIER.DEFINITIONS.moss_deer.species, "base_cost":FRONTIER.DEFINITIONS.moss_deer.base_cost, "summon_exp":FRONTIER.DEFINITIONS.moss_deer.summon_exp, "attack_type":FRONTIER.DEFINITIONS.moss_deer.attack_type, "base_stats":FRONTIER.DEFINITIONS.moss_deer.base_stats, "balance":FRONTIER.DEFINITIONS.moss_deer.balance, "description":FRONTIER.DEFINITIONS.moss_deer.description, "special_augment_ids":FRONTIER.DEFINITIONS.moss_deer.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.moss_deer.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.moss_deer.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.moss_deer.elite_visual, "scene":preload("res://src/monsters/FrontierMossDeer.tscn")},
	"crystal_tortoise": {"ground_shadow":FRONTIER.DEFINITIONS.crystal_tortoise.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.crystal_tortoise.hero_survival_after, "id":FRONTIER.DEFINITIONS.crystal_tortoise.id, "name":FRONTIER.DEFINITIONS.crystal_tortoise.name, "grade":FRONTIER.DEFINITIONS.crystal_tortoise.grade, "rarity":FRONTIER.DEFINITIONS.crystal_tortoise.rarity, "role":FRONTIER.DEFINITIONS.crystal_tortoise.role, "family":FRONTIER.DEFINITIONS.crystal_tortoise.family, "species":FRONTIER.DEFINITIONS.crystal_tortoise.species, "base_cost":FRONTIER.DEFINITIONS.crystal_tortoise.base_cost, "summon_exp":FRONTIER.DEFINITIONS.crystal_tortoise.summon_exp, "attack_type":FRONTIER.DEFINITIONS.crystal_tortoise.attack_type, "base_stats":FRONTIER.DEFINITIONS.crystal_tortoise.base_stats, "balance":FRONTIER.DEFINITIONS.crystal_tortoise.balance, "description":FRONTIER.DEFINITIONS.crystal_tortoise.description, "special_augment_ids":FRONTIER.DEFINITIONS.crystal_tortoise.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.crystal_tortoise.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.crystal_tortoise.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.crystal_tortoise.elite_visual, "scene":preload("res://src/monsters/FrontierCrystalTortoise.tscn")},
	"ember_salamander": {"ground_shadow":FRONTIER.DEFINITIONS.ember_salamander.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.ember_salamander.hero_survival_after, "id":FRONTIER.DEFINITIONS.ember_salamander.id, "name":FRONTIER.DEFINITIONS.ember_salamander.name, "grade":FRONTIER.DEFINITIONS.ember_salamander.grade, "rarity":FRONTIER.DEFINITIONS.ember_salamander.rarity, "role":FRONTIER.DEFINITIONS.ember_salamander.role, "family":FRONTIER.DEFINITIONS.ember_salamander.family, "species":FRONTIER.DEFINITIONS.ember_salamander.species, "base_cost":FRONTIER.DEFINITIONS.ember_salamander.base_cost, "summon_exp":FRONTIER.DEFINITIONS.ember_salamander.summon_exp, "attack_type":FRONTIER.DEFINITIONS.ember_salamander.attack_type, "base_stats":FRONTIER.DEFINITIONS.ember_salamander.base_stats, "balance":FRONTIER.DEFINITIONS.ember_salamander.balance, "description":FRONTIER.DEFINITIONS.ember_salamander.description, "special_augment_ids":FRONTIER.DEFINITIONS.ember_salamander.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.ember_salamander.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.ember_salamander.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.ember_salamander.elite_visual, "scene":preload("res://src/monsters/FrontierEmberSalamander.tscn")},
	"frost_owl": {"ground_shadow":FRONTIER.DEFINITIONS.frost_owl.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.frost_owl.hero_survival_after, "id":FRONTIER.DEFINITIONS.frost_owl.id, "name":FRONTIER.DEFINITIONS.frost_owl.name, "grade":FRONTIER.DEFINITIONS.frost_owl.grade, "rarity":FRONTIER.DEFINITIONS.frost_owl.rarity, "role":FRONTIER.DEFINITIONS.frost_owl.role, "family":FRONTIER.DEFINITIONS.frost_owl.family, "species":FRONTIER.DEFINITIONS.frost_owl.species, "base_cost":FRONTIER.DEFINITIONS.frost_owl.base_cost, "summon_exp":FRONTIER.DEFINITIONS.frost_owl.summon_exp, "attack_type":FRONTIER.DEFINITIONS.frost_owl.attack_type, "base_stats":FRONTIER.DEFINITIONS.frost_owl.base_stats, "balance":FRONTIER.DEFINITIONS.frost_owl.balance, "description":FRONTIER.DEFINITIONS.frost_owl.description, "special_augment_ids":FRONTIER.DEFINITIONS.frost_owl.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.frost_owl.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.frost_owl.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.frost_owl.elite_visual, "scene":preload("res://src/monsters/FrontierFrostOwl.tscn")},
	"thorn_dryad": {"ground_shadow":FRONTIER.DEFINITIONS.thorn_dryad.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.thorn_dryad.hero_survival_after, "id":FRONTIER.DEFINITIONS.thorn_dryad.id, "name":FRONTIER.DEFINITIONS.thorn_dryad.name, "grade":FRONTIER.DEFINITIONS.thorn_dryad.grade, "rarity":FRONTIER.DEFINITIONS.thorn_dryad.rarity, "role":FRONTIER.DEFINITIONS.thorn_dryad.role, "family":FRONTIER.DEFINITIONS.thorn_dryad.family, "species":FRONTIER.DEFINITIONS.thorn_dryad.species, "base_cost":FRONTIER.DEFINITIONS.thorn_dryad.base_cost, "summon_exp":FRONTIER.DEFINITIONS.thorn_dryad.summon_exp, "attack_type":FRONTIER.DEFINITIONS.thorn_dryad.attack_type, "base_stats":FRONTIER.DEFINITIONS.thorn_dryad.base_stats, "balance":FRONTIER.DEFINITIONS.thorn_dryad.balance, "description":FRONTIER.DEFINITIONS.thorn_dryad.description, "special_augment_ids":FRONTIER.DEFINITIONS.thorn_dryad.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.thorn_dryad.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.thorn_dryad.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.thorn_dryad.elite_visual, "scene":preload("res://src/monsters/FrontierThornDryad.tscn")},
	"dusk_panther": {"ground_shadow":FRONTIER.DEFINITIONS.dusk_panther.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.dusk_panther.hero_survival_after, "id":FRONTIER.DEFINITIONS.dusk_panther.id, "name":FRONTIER.DEFINITIONS.dusk_panther.name, "grade":FRONTIER.DEFINITIONS.dusk_panther.grade, "rarity":FRONTIER.DEFINITIONS.dusk_panther.rarity, "role":FRONTIER.DEFINITIONS.dusk_panther.role, "family":FRONTIER.DEFINITIONS.dusk_panther.family, "species":FRONTIER.DEFINITIONS.dusk_panther.species, "base_cost":FRONTIER.DEFINITIONS.dusk_panther.base_cost, "summon_exp":FRONTIER.DEFINITIONS.dusk_panther.summon_exp, "attack_type":FRONTIER.DEFINITIONS.dusk_panther.attack_type, "base_stats":FRONTIER.DEFINITIONS.dusk_panther.base_stats, "balance":FRONTIER.DEFINITIONS.dusk_panther.balance, "description":FRONTIER.DEFINITIONS.dusk_panther.description, "special_augment_ids":FRONTIER.DEFINITIONS.dusk_panther.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.dusk_panther.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.dusk_panther.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.dusk_panther.elite_visual, "scene":preload("res://src/monsters/FrontierDuskPanther.tscn")},
	"rune_sentinel": {"ground_shadow":FRONTIER.DEFINITIONS.rune_sentinel.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.rune_sentinel.hero_survival_after, "id":FRONTIER.DEFINITIONS.rune_sentinel.id, "name":FRONTIER.DEFINITIONS.rune_sentinel.name, "grade":FRONTIER.DEFINITIONS.rune_sentinel.grade, "rarity":FRONTIER.DEFINITIONS.rune_sentinel.rarity, "role":FRONTIER.DEFINITIONS.rune_sentinel.role, "family":FRONTIER.DEFINITIONS.rune_sentinel.family, "species":FRONTIER.DEFINITIONS.rune_sentinel.species, "base_cost":FRONTIER.DEFINITIONS.rune_sentinel.base_cost, "summon_exp":FRONTIER.DEFINITIONS.rune_sentinel.summon_exp, "attack_type":FRONTIER.DEFINITIONS.rune_sentinel.attack_type, "base_stats":FRONTIER.DEFINITIONS.rune_sentinel.base_stats, "balance":FRONTIER.DEFINITIONS.rune_sentinel.balance, "description":FRONTIER.DEFINITIONS.rune_sentinel.description, "special_augment_ids":FRONTIER.DEFINITIONS.rune_sentinel.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.rune_sentinel.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.rune_sentinel.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.rune_sentinel.elite_visual, "scene":preload("res://src/monsters/FrontierRuneSentinel.tscn")},
	"venom_scorpion": {"ground_shadow":FRONTIER.DEFINITIONS.venom_scorpion.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.venom_scorpion.hero_survival_after, "id":FRONTIER.DEFINITIONS.venom_scorpion.id, "name":FRONTIER.DEFINITIONS.venom_scorpion.name, "grade":FRONTIER.DEFINITIONS.venom_scorpion.grade, "rarity":FRONTIER.DEFINITIONS.venom_scorpion.rarity, "role":FRONTIER.DEFINITIONS.venom_scorpion.role, "family":FRONTIER.DEFINITIONS.venom_scorpion.family, "species":FRONTIER.DEFINITIONS.venom_scorpion.species, "base_cost":FRONTIER.DEFINITIONS.venom_scorpion.base_cost, "summon_exp":FRONTIER.DEFINITIONS.venom_scorpion.summon_exp, "attack_type":FRONTIER.DEFINITIONS.venom_scorpion.attack_type, "base_stats":FRONTIER.DEFINITIONS.venom_scorpion.base_stats, "balance":FRONTIER.DEFINITIONS.venom_scorpion.balance, "description":FRONTIER.DEFINITIONS.venom_scorpion.description, "special_augment_ids":FRONTIER.DEFINITIONS.venom_scorpion.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.venom_scorpion.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.venom_scorpion.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.venom_scorpion.elite_visual, "scene":preload("res://src/monsters/FrontierVenomScorpion.tscn")},
	"moon_moth": {"ground_shadow":FRONTIER.DEFINITIONS.moon_moth.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.moon_moth.hero_survival_after, "id":FRONTIER.DEFINITIONS.moon_moth.id, "name":FRONTIER.DEFINITIONS.moon_moth.name, "grade":FRONTIER.DEFINITIONS.moon_moth.grade, "rarity":FRONTIER.DEFINITIONS.moon_moth.rarity, "role":FRONTIER.DEFINITIONS.moon_moth.role, "family":FRONTIER.DEFINITIONS.moon_moth.family, "species":FRONTIER.DEFINITIONS.moon_moth.species, "base_cost":FRONTIER.DEFINITIONS.moon_moth.base_cost, "summon_exp":FRONTIER.DEFINITIONS.moon_moth.summon_exp, "attack_type":FRONTIER.DEFINITIONS.moon_moth.attack_type, "base_stats":FRONTIER.DEFINITIONS.moon_moth.base_stats, "balance":FRONTIER.DEFINITIONS.moon_moth.balance, "description":FRONTIER.DEFINITIONS.moon_moth.description, "special_augment_ids":FRONTIER.DEFINITIONS.moon_moth.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.moon_moth.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.moon_moth.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.moon_moth.elite_visual, "scene":preload("res://src/monsters/FrontierMoonMoth.tscn")},
	"harpy": {"ground_shadow":FRONTIER.DEFINITIONS.harpy.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.harpy.hero_survival_after, "id":FRONTIER.DEFINITIONS.harpy.id, "name":FRONTIER.DEFINITIONS.harpy.name, "grade":FRONTIER.DEFINITIONS.harpy.grade, "rarity":FRONTIER.DEFINITIONS.harpy.rarity, "role":FRONTIER.DEFINITIONS.harpy.role, "family":FRONTIER.DEFINITIONS.harpy.family, "species":FRONTIER.DEFINITIONS.harpy.species, "base_cost":FRONTIER.DEFINITIONS.harpy.base_cost, "summon_exp":FRONTIER.DEFINITIONS.harpy.summon_exp, "attack_type":FRONTIER.DEFINITIONS.harpy.attack_type, "base_stats":FRONTIER.DEFINITIONS.harpy.base_stats, "balance":FRONTIER.DEFINITIONS.harpy.balance, "description":FRONTIER.DEFINITIONS.harpy.description, "special_augment_ids":FRONTIER.DEFINITIONS.harpy.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.harpy.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.harpy.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.harpy.elite_visual, "scene":preload("res://src/monsters/FrontierHarpy.tscn")},
	"imp": {"ground_shadow":FRONTIER.DEFINITIONS.imp.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.imp.hero_survival_after, "id":FRONTIER.DEFINITIONS.imp.id, "name":FRONTIER.DEFINITIONS.imp.name, "grade":FRONTIER.DEFINITIONS.imp.grade, "rarity":FRONTIER.DEFINITIONS.imp.rarity, "role":FRONTIER.DEFINITIONS.imp.role, "family":FRONTIER.DEFINITIONS.imp.family, "species":FRONTIER.DEFINITIONS.imp.species, "base_cost":FRONTIER.DEFINITIONS.imp.base_cost, "summon_exp":FRONTIER.DEFINITIONS.imp.summon_exp, "attack_type":FRONTIER.DEFINITIONS.imp.attack_type, "base_stats":FRONTIER.DEFINITIONS.imp.base_stats, "balance":FRONTIER.DEFINITIONS.imp.balance, "description":FRONTIER.DEFINITIONS.imp.description, "special_augment_ids":FRONTIER.DEFINITIONS.imp.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.imp.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.imp.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.imp.elite_visual, "scene":preload("res://src/monsters/FrontierImp.tscn")},
	"mimic": {"ground_shadow":FRONTIER.DEFINITIONS.mimic.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.mimic.hero_survival_after, "id":FRONTIER.DEFINITIONS.mimic.id, "name":FRONTIER.DEFINITIONS.mimic.name, "grade":FRONTIER.DEFINITIONS.mimic.grade, "rarity":FRONTIER.DEFINITIONS.mimic.rarity, "role":FRONTIER.DEFINITIONS.mimic.role, "family":FRONTIER.DEFINITIONS.mimic.family, "species":FRONTIER.DEFINITIONS.mimic.species, "base_cost":FRONTIER.DEFINITIONS.mimic.base_cost, "summon_exp":FRONTIER.DEFINITIONS.mimic.summon_exp, "attack_type":FRONTIER.DEFINITIONS.mimic.attack_type, "base_stats":FRONTIER.DEFINITIONS.mimic.base_stats, "balance":FRONTIER.DEFINITIONS.mimic.balance, "description":FRONTIER.DEFINITIONS.mimic.description, "special_augment_ids":FRONTIER.DEFINITIONS.mimic.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.mimic.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.mimic.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.mimic.elite_visual, "scene":preload("res://src/monsters/FrontierMimic.tscn")},
	"mud_golem": {"ground_shadow":FRONTIER.DEFINITIONS.mud_golem.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.mud_golem.hero_survival_after, "id":FRONTIER.DEFINITIONS.mud_golem.id, "name":FRONTIER.DEFINITIONS.mud_golem.name, "grade":FRONTIER.DEFINITIONS.mud_golem.grade, "rarity":FRONTIER.DEFINITIONS.mud_golem.rarity, "role":FRONTIER.DEFINITIONS.mud_golem.role, "family":FRONTIER.DEFINITIONS.mud_golem.family, "species":FRONTIER.DEFINITIONS.mud_golem.species, "base_cost":FRONTIER.DEFINITIONS.mud_golem.base_cost, "summon_exp":FRONTIER.DEFINITIONS.mud_golem.summon_exp, "attack_type":FRONTIER.DEFINITIONS.mud_golem.attack_type, "base_stats":FRONTIER.DEFINITIONS.mud_golem.base_stats, "balance":FRONTIER.DEFINITIONS.mud_golem.balance, "description":FRONTIER.DEFINITIONS.mud_golem.description, "special_augment_ids":FRONTIER.DEFINITIONS.mud_golem.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.mud_golem.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.mud_golem.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.mud_golem.elite_visual, "scene":preload("res://src/monsters/FrontierMudGolem.tscn")},
	"satyr_rogue": {"ground_shadow":FRONTIER.DEFINITIONS.satyr_rogue.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.satyr_rogue.hero_survival_after, "id":FRONTIER.DEFINITIONS.satyr_rogue.id, "name":FRONTIER.DEFINITIONS.satyr_rogue.name, "grade":FRONTIER.DEFINITIONS.satyr_rogue.grade, "rarity":FRONTIER.DEFINITIONS.satyr_rogue.rarity, "role":FRONTIER.DEFINITIONS.satyr_rogue.role, "family":FRONTIER.DEFINITIONS.satyr_rogue.family, "species":FRONTIER.DEFINITIONS.satyr_rogue.species, "base_cost":FRONTIER.DEFINITIONS.satyr_rogue.base_cost, "summon_exp":FRONTIER.DEFINITIONS.satyr_rogue.summon_exp, "attack_type":FRONTIER.DEFINITIONS.satyr_rogue.attack_type, "base_stats":FRONTIER.DEFINITIONS.satyr_rogue.base_stats, "balance":FRONTIER.DEFINITIONS.satyr_rogue.balance, "description":FRONTIER.DEFINITIONS.satyr_rogue.description, "special_augment_ids":FRONTIER.DEFINITIONS.satyr_rogue.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.satyr_rogue.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.satyr_rogue.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.satyr_rogue.elite_visual, "scene":preload("res://src/monsters/FrontierSatyrRogue.tscn")},
	"satyr_shaman": {"ground_shadow":FRONTIER.DEFINITIONS.satyr_shaman.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.satyr_shaman.hero_survival_after, "id":FRONTIER.DEFINITIONS.satyr_shaman.id, "name":FRONTIER.DEFINITIONS.satyr_shaman.name, "grade":FRONTIER.DEFINITIONS.satyr_shaman.grade, "rarity":FRONTIER.DEFINITIONS.satyr_shaman.rarity, "role":FRONTIER.DEFINITIONS.satyr_shaman.role, "family":FRONTIER.DEFINITIONS.satyr_shaman.family, "species":FRONTIER.DEFINITIONS.satyr_shaman.species, "base_cost":FRONTIER.DEFINITIONS.satyr_shaman.base_cost, "summon_exp":FRONTIER.DEFINITIONS.satyr_shaman.summon_exp, "attack_type":FRONTIER.DEFINITIONS.satyr_shaman.attack_type, "base_stats":FRONTIER.DEFINITIONS.satyr_shaman.base_stats, "balance":FRONTIER.DEFINITIONS.satyr_shaman.balance, "description":FRONTIER.DEFINITIONS.satyr_shaman.description, "special_augment_ids":FRONTIER.DEFINITIONS.satyr_shaman.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.satyr_shaman.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.satyr_shaman.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.satyr_shaman.elite_visual, "scene":preload("res://src/monsters/FrontierSatyrShaman.tscn")},
	"skeleton_shield": {"ground_shadow":FRONTIER.DEFINITIONS.skeleton_shield.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.skeleton_shield.hero_survival_after, "id":FRONTIER.DEFINITIONS.skeleton_shield.id, "name":FRONTIER.DEFINITIONS.skeleton_shield.name, "grade":FRONTIER.DEFINITIONS.skeleton_shield.grade, "rarity":FRONTIER.DEFINITIONS.skeleton_shield.rarity, "role":FRONTIER.DEFINITIONS.skeleton_shield.role, "family":FRONTIER.DEFINITIONS.skeleton_shield.family, "species":FRONTIER.DEFINITIONS.skeleton_shield.species, "base_cost":FRONTIER.DEFINITIONS.skeleton_shield.base_cost, "summon_exp":FRONTIER.DEFINITIONS.skeleton_shield.summon_exp, "attack_type":FRONTIER.DEFINITIONS.skeleton_shield.attack_type, "base_stats":FRONTIER.DEFINITIONS.skeleton_shield.base_stats, "balance":FRONTIER.DEFINITIONS.skeleton_shield.balance, "description":FRONTIER.DEFINITIONS.skeleton_shield.description, "special_augment_ids":FRONTIER.DEFINITIONS.skeleton_shield.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.skeleton_shield.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.skeleton_shield.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.skeleton_shield.elite_visual, "scene":preload("res://src/monsters/FrontierSkeletonShield.tscn")},
	"toxic_slime": {"ground_shadow":FRONTIER.DEFINITIONS.toxic_slime.ground_shadow, "hero_survival_after":FRONTIER.DEFINITIONS.toxic_slime.hero_survival_after, "id":FRONTIER.DEFINITIONS.toxic_slime.id, "name":FRONTIER.DEFINITIONS.toxic_slime.name, "grade":FRONTIER.DEFINITIONS.toxic_slime.grade, "rarity":FRONTIER.DEFINITIONS.toxic_slime.rarity, "role":FRONTIER.DEFINITIONS.toxic_slime.role, "family":FRONTIER.DEFINITIONS.toxic_slime.family, "species":FRONTIER.DEFINITIONS.toxic_slime.species, "base_cost":FRONTIER.DEFINITIONS.toxic_slime.base_cost, "summon_exp":FRONTIER.DEFINITIONS.toxic_slime.summon_exp, "attack_type":FRONTIER.DEFINITIONS.toxic_slime.attack_type, "base_stats":FRONTIER.DEFINITIONS.toxic_slime.base_stats, "balance":FRONTIER.DEFINITIONS.toxic_slime.balance, "description":FRONTIER.DEFINITIONS.toxic_slime.description, "special_augment_ids":FRONTIER.DEFINITIONS.toxic_slime.special_augment_ids, "elite_skills":FRONTIER.DEFINITIONS.toxic_slime.elite_skills, "card_icon_path":FRONTIER.DEFINITIONS.toxic_slime.card_icon_path, "elite_visual":FRONTIER.DEFINITIONS.toxic_slime.elite_visual, "scene":preload("res://src/monsters/FrontierToxicSlime.tscn")},
	"fanatic":{"id": "fanatic", "name": "광신도", "role": "exploder", "family": "fanatic", "species": "humanoid", "grade": "uncommon", "rarity": "uncommon", "attack_type": "melee", "base_cost": 10.0, "summon_exp": 10.0, "balance": {"health_share": 1.5, "damage_share": 0.5, "cycle_damage_multiplier": 2.0, "burst_share": 0.75, "note": "특수 효과 기여는 별도, 승률 미검증"}, "card_icon_path": "res://assets/art/monsters/fanatic/frames/idle_01.png", "description": "단검·어둠구체2연격(엘리트1타). 사망 위치에서1.5초 깜빡인 후 지름175 폭발. 엘리트는1.5초간 무증강 광신도10명 소환.", "special_augment_ids": ["fanatic_suicide", "fanatic_dagger", "fanatic_vitality"], "elite_skills": [{"runtime": "monster", "id": "elite_fanatic_ritual", "name": "의식집도", "description": "1.5초간 모든 증강이 제외된 일반 광신도10명을 순차 소환.", "initial_cooldown": 2.0, "cooldown": 20.0}],"scene":preload("res://src/monsters/Fanatic.tscn"),"base_stats":preload("res://src/data/fanatic_behavior_catalog.gd").BASE,"elite_visual":preload("res://src/data/fanatic_behavior_catalog.gd").ELITE_VISUAL},
	"gumiho":{"id": "gumiho", "name": "구미호", "role": "exploder", "family": "gumiho", "species": "beast", "grade": "legendary", "rarity": "legendary", "attack_type": "melee", "base_cost": 24.0, "summon_exp": 24.0, "balance": {"health_share": 1.5, "damage_share": 1.0, "cycle_damage_multiplier": 1.0, "note": "특수 효과 기여는 별도, 승률 미검증"}, "card_icon_path": "res://assets/art/monsters/gumiho/frames/idle_01.png", "description": "소환 후5초 최대체력55% 원거리쉴드. 투사체10% 반사. 공유 공격20스택 매혹1.5초·종료후면역5초. 변신20초 모든능력치50% 증가, 여우모드 전용 여우불2초150%·화상3초 최대체력5%.", "special_augment_ids": ["gumiho_universal", "gumiho_fascination", "gumiho_last_shadow"], "elite_skills": [{"runtime": "monster", "id": "elite_gumiho_fear", "name": "원한의 공포", "description": "대상에게 공포2초·도주속도70% 증가. 종료후공포면역5초.", "initial_cooldown": 2.0, "cooldown": 20.0}, {"runtime": "monster", "id": "elite_gumiho_transform", "name": "변신", "description": "20초 여우형태·체력/공격/이속/공속50% 증가.1초 무피격 은신.", "initial_cooldown": 5.0, "cooldown": 60.0}, {"runtime": "monster", "id": "elite_gumiho_foxfire", "name": "여우 불", "description": "여우형태에서만 사용.2초간 공격력150% 피해와3초간 대상 최대체력5% 화상(갱신/중첩불가).", "initial_cooldown": 2.0, "cooldown": 10.0}],"scene":preload("res://src/monsters/Gumiho.tscn"),"base_stats":preload("res://src/data/gumiho_behavior_catalog.gd").BASE,"elite_visual":preload("res://src/data/gumiho_behavior_catalog.gd").ELITE_VISUAL},

	"dark_elf_rogue": {
		"id":"dark_elf_rogue","name":"흑요정 도적","role":"exploder","family":"dark_elf","species":"humanoid","grade":"uncommon","rarity":"uncommon","attack_type":"melee",
		"scene":preload("res://src/monsters/DarkElfRogue.tscn"),"base_cost":9.0,"summon_exp":9.0,"base_stats":preload("res://src/data/dark_elf_rogue_behavior_catalog.gd").BASE,
		"balance":{"health_share":1.5,"damage_share":0.8,"cycle_damage_multiplier":2.0,"note":"각100%2연격, 낮은공격13/중간몸체142.3초은신50%피감/첫타150%·공격후사거리내2배속재배치.300%/후방133%·엘리트225%단일해제타와피해취약70%·대상제외는별도기여. 승률미검증"},
		"card_icon_path":"res://assets/art/monsters/dark_elf_rogue/frames/idle_01.png","description":"근접2연격(각공격력100%, 두번째0.14초 후).3초 무피격 은신(피해50% 감소), 은신 첫타150%후해제·재준비3초. 공격 후 자신의 사거리 내 다른 위치로 빠르게 이동. 강화 은신/엘리트 배율은 첫타에만 적용하며 후방 판정은 각 타격 시점의 용사 시선 기준.",
		"special_augment_ids":["dark_elf_rogue_assassinate","dark_elf_rogue_blades","dark_elf_rogue_backstab"],"elite_visual":preload("res://src/data/dark_elf_rogue_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","id":"elite_dark_elf_rogue_darkness","name":"어둠속으로","initial_cooldown":3.0,"cooldown":20.0,"description":"5초 완전투명·용사표적에서제외, 받는피해70% 증가/이속30% 증가. 일반은신 비적용. 유효 첫타225%후해제(일반은신150/300%와중복없음), 후방133%는적용. 기존 충돌/광역·비표적피해 유지."}],
	},
	"boar": {
		"id":"boar","name":"멧돼지","role":"exploder","family":"boar","species":"beast","grade":"common","rarity":"common","attack_type":"melee",
		"scene":preload("res://src/monsters/Boar.tscn"),"base_cost":8.0,"summon_exp":8.0,"base_stats":preload("res://src/data/boar_behavior_catalog.gd").BASE,
		"balance":{"health_share":1.5,"damage_share":0.9,"cycle_extra_seconds":2.8588235294,"note":"직선900 돌진50→425를1초 가속(총2.559초)+정신집중0.3, 종료후간격1.4. 돌진당대상1회, 회피가능. 즉시/3번째가속·엘리트10초연결은별도기여, 승률미검증"},
		"card_icon_path":"res://assets/art/monsters/boar/frames/idle_01.png","description":"사거리 지름550. 공격 전0.3초 정신집중 후 방향을 고정하여 직선900 돌진. 속도50부터425까지 점차 증가(기본1초 가속). 돌진당 대상1회 근접피해, 벽/몸체 충돌 시 종료. 종료 후 공격간격 적용.",
		"special_augment_ids":["boar_tusk","boar_instant","boar_third_charge"],"elite_visual":preload("res://src/data/boar_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","id":"elite_boar_frenzy","name":"저돌맹진","initial_cooldown":3.0,"cooldown":20.0,"duration":10.0,"description":"10초간 일반 돌진 종료 후 공격간격/정신집중 없이 추가 돌진1회. 추가 돌진 종료 후 정상 공격간격 적용. 지속 중 일반돌진마다 반복."}],
	},
	"dark_elf_archer": {
		"id":"dark_elf_archer","name":"흑요정 궁수","role":"ranged","family":"dark_elf","species":"humanoid","grade":"uncommon","rarity":"uncommon","attack_type":"ranged",
		"scene":preload("res://src/monsters/DarkElfArcher.tscn"),"base_cost":12.0,"summon_exp":12.0,"base_stats":preload("res://src/data/dark_elf_archer_behavior_catalog.gd").BASE,
		"balance":{"health_share":0.55,"damage_share":0.8,"note":"3초 은신50%피감/첫사격150%, 사격후재준비3초·2배속85후퇴. 낮은몸체, 엘리트125%4연사15초·무적무시/피감쉴드유지 별도기여, 승률미검증"},
		"card_icon_path":"res://assets/art/monsters/dark_elf_archer/frames/idle_01.png","description":"사거리 지름750, 투사체속도280, 투사체크기109%. 사격 후 안전한 자리로 빠르게 이동.3초 피격 없이 은신 진입(반투명 표시, 받는피해50% 감소). 은신 사격150% 피해 후 즉시 해제, 다시3초 준비. 피격은 준비시간을 초기화하며 이미 진입한 은신의 피감은 다음 사격까지 유지.",
		"special_augment_ids":["dark_elf_far_sight","dark_elf_economy","dark_elf_shadow_shield"],"elite_visual":preload("res://src/data/dark_elf_archer_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","id":"elite_dark_elf_burst","name":"4연사","initial_cooldown":2.0,"cooldown":15.0,"description":"공격력125%의 화살4발을0.18초 간격으로 연사. 피격무적 무시, 쉴드/피해감소 유지. 은신150%와 중복하지 않음. 기절/침묵 시 남은 연사 취소."}],
	},
	"anubis": {
		"id":"anubis","name":"아누비스","role":"exploder","family":"anubis","species":"divine_humanoid","grade":"legendary","rarity":"legendary","attack_type":"melee",
		"scene":preload("res://src/monsters/Anubis.tscn"),"base_cost":24.0,"summon_exp":24.0,"base_stats":preload("res://src/data/anubis_behavior_catalog.gd").BASE,
		"balance":{"role":"tank","health_share":0.7142857143,"damage_share":0.25,"note":"매우높은 체력472·낮은공격25 유지: 비용24/방어형 예산으로 계산, 게임역할폭발 유지. 미라성장/죽음쉴드/희생영구성장·분노30%는 조합기여, 군집 페널티, 승률미검증"},
		"card_icon_path":"res://assets/art/monsters/anubis/frames/idle_01.png","description":"기본 표시크기137%, 매우높은 기본체력. 미라 이름을 가진 생존 아군마다 체력·공격·이속·공속 +5%, 표시크기 +0.3%(표시3배 상한). 미라 사망마다 근거리쉴드15/원거리쉴드20 중첩. 아누비스10/20/30마리 이상이면 전체 전투스탯10/20/50% 감소(대체형). 미라 주술사·엘리트 포함, 범위 제한 없음.",
		"special_augment_ids":["anubis_ranged","anubis_melee","anubis_universal"],"elite_visual":preload("res://src/data/anubis_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","id":"elite_anubis_thoughts","name":"사념 중첩","passive":true,"initial_cooldown":0.0,"cooldown":0.0,"description":"기본공격마다 고정 추가피해7 누적(첫공격7/다음14...). 생존 미라1마리마다 추가 공속3%. 추가피해는 기본타격과 합산된 근거리피해이며 무적/피감 유지."},{"runtime":"monster","id":"elite_anubis_rage","name":"아누비스의 분노","initial_cooldown":10.0,"cooldown":30.0,"description":"7초간 표시크기15% 증가, 체력·공격·이속·공속30% 상승. 종료 시 임시효과만 해제."},{"runtime":"monster","id":"elite_anubis_sacrifice","name":"희생하거라","initial_cooldown":3.0,"cooldown":3.0,"retry_interval":0.5,"description":"전장 내 자신 제외 아누비스 또는 미라1마리 희생. 아누비스 흡수: 영구전투스탯12%/크기5%, 미라 흡수:9%/3% 가산 누적. 희생은 정상사망으로 처리하여 미라사망쉴드/EXP 유지. 대상 없으면 대기."}],
	},

 "lizardman_spearman": {
  "id":"lizardman_spearman","name":"리자드맨 창병","role":"exploder","family":"lizardman","species":"beast","grade":"uncommon","rarity":"uncommon","attack_type":"melee","noncollision_family":"lizardman",
  "base_cost":12.0,"summon_exp":12.0,"default_unlocked":false,"combat_enabled":true,
  "base_stats":preload("res://src/data/lizardman_spearman_behavior_catalog.gd").BASE,
  "balance":{"health_share":1.19047619,"damage_share":0.77160494,"note":"빠른 근접 반복 폭발형. 사거리130/1회 꼬리후퇴, 직접DPS·몸체 기회비용 반영. 원거리 전환/누적 공속은 실전 승률 미검증"},
  "description":"HP30% 이하1회 꼬리자르기(직선최대400). 근접 사거리130, 리자드맨끼리 충돌 없음. 증강으로 원거리 전환 시 반경185(지름370), 투사체속도280.",
  "special_augment_ids":["lizard_spear_throw","lizard_spear_footwork","lizard_spear_repulse"],
  "elite_skills":[{"runtime":"monster","id":"elite_lizard_spear_charge","name":"돌진","passive":true,"initial_cooldown":1.0,"cooldown":15.0,"description":"폭발 역할에서만 활성. 빠르게 접근 후1회 공격250%."},{"runtime":"monster","id":"elite_lizard_spear_ready","name":"빠른 준비","passive":true,"initial_cooldown":0.0,"cooldown":0.0,"description":"원거리 역할에서만 활성. 공격마다공속2%,최대20스택(40%)."}],
  "card_icon_path":"res://assets/art/monsters/lizardmanspearman/frames/idle_01.png",
  "elite_visual":preload("res://src/data/lizardman_spearman_behavior_catalog.gd").ELITE_VISUAL,
  "scene":preload("res://src/monsters/LizardmanSpearman.tscn"),
 },
 "lizardman_fighter": {
  "id":"lizardman_fighter","name":"리자드맨 전사","role":"exploder","family":"lizardman","species":"beast","grade":"uncommon","rarity":"uncommon","attack_type":"melee","noncollision_family":"lizardman",
  "base_cost":12.0,"summon_exp":12.0,"default_unlocked":false,"combat_enabled":true,
  "base_stats":preload("res://src/data/lizardman_fighter_behavior_catalog.gd").BASE,
  "balance":{"health_share":1.19047619,"damage_share":0.90939153,"note":"반복 근접 폭발형. 빠른 접근/공격,HP30% 1회 후퇴로 공격 시간 손실.1회 생존·낮은 기본HP, 엘리트 영구성장 실전승률 미검증"},
  "description":"리자드맨끼리 충돌·밀어내기 없음. HP30% 이하에서1회 꼬리를 남기고 공격자 반대 방향으로 직선 최대400 후퇴. 꼬리는3초간 남고 마지막1초 깜박임. 치명타격은 생존시키지 않음.",
  "special_augment_ids":["lizard_tail_regrowth","lizard_sharp_blade","lizard_clutch_mobilization"],
  "elite_skills":[{"runtime":"monster","id":"elite_lizard_nutrition","name":"영양섭취","passive":true,"initial_cooldown":0.0,"cooldown":0.0,"description":"맵의 꼬리를 즉시 섭취. 꼬리당 최대HP·공격·이속·공속 기본치의2% 영구 증가(전투 내). 가장 가까운 살아있는 엘리트1마리만 섭취."}],
  "card_icon_path":"res://assets/art/monsters/lizardmanfighter/frames/idle_01.png",
  "elite_visual":preload("res://src/data/lizardman_fighter_behavior_catalog.gd").ELITE_VISUAL,
  "scene":preload("res://src/monsters/LizardmanFighter.tscn"),
 },
 "ogre": {
  "id":"ogre","name":"오우거","role":"tank","family":"ogre","species":"beast","grade":"uncommon","rarity":"uncommon","attack_type":"melee",
  "base_cost":20.0,"summon_exp":20.0,"default_unlocked":false,"combat_enabled":true,
  "base_stats":preload("res://src/data/ogre_behavior_catalog.gd").BASE,
  "balance":{"health_share":0.71428571,"damage_share":0.27472527,"note":"등장100%근거리쉴드·매3번째피격 근거리30%피감, 원거리 취약/느린 추격. 낮은 직접화력으로 생존기여 비용 반영. 실전승률 미검증"},
  "description":"소환 시 최대HP100% 근거리쉴드. 매3번째 피격이 근거리이면 그 피해30% 감소. 느린 이동·공격, 매우 높은 체력의 짐승 탱커.",
  "special_augment_ids":["ogre_great_blood","ogre_war_fury","ogre_mass_production"],
  "elite_skills":[{"runtime":"monster","id":"elite_ogre_thick_fat","name":"두꺼운 지방","passive":true,"initial_cooldown":0.0,"cooldown":0.0,"description":"근거리 피격마다5% 무효화 또는5% 확률로 감소 적용 피해80% 반사(서로 배타적). 쉴드 피해 포함, 반사는 원래 피격도 받음."}],
  "card_icon_path":"res://assets/art/monsters/ogre/frames/idle_01.png",
  "elite_visual":preload("res://src/data/ogre_behavior_catalog.gd").ELITE_VISUAL,
  "scene":preload("res://src/monsters/Ogre.tscn"),
 },

	"hobgoblin": {
		"id":"hobgoblin","name":"홉고블린","role":"tank","family":"goblin","species":"beast","grade":"rare","rarity":"rare","attack_type":"melee",
		"base_cost":18.0,"summon_exp":18.0,"default_unlocked":false,"combat_enabled":true,
		"base_stats":preload("res://src/data/hobgoblin_behavior_catalog.gd").BASE,
		"balance":{"health_share":0.58460884,"damage_share":0.57870370,"note":"좁은 반경175의 고블린 수당 고정 성장/공속,100마리HP4배,군단 지원의 기회비용. 기본 몸체·화력 할인. 실전 승률 미검증"},
		"description":"지름350 내 살아있는 이름에 고블린이 포함된 아군(자신 포함)당 HP·공격·이속+2,공속+2%. 사망/이탈시 해당 증가분 제거.10마리 이상: 유효 공격3% 확률1초 기절.100마리 이상: 최대HP+300%(4배).",
		"special_augment_ids":["hobgoblin_lord","hobgoblin_iron_bond","hobgoblin_shield_march"],
		"elite_skills":[{"runtime":"monster","id":"elite_hobgoblin_command","name":"지휘","passive":true,"initial_cooldown":0.0,"cooldown":0.0,"refresh_interval":5.0,"description":"존재하는 동안 범위 내 고블린들을 주변으로 집결.5초마다 지휘 갱신. 순간이동 아님."}],
		"card_icon_path":"res://assets/art/monsters/Hobgoblin_Commander/frames/idle_01.png",
		"elite_visual":preload("res://src/data/hobgoblin_behavior_catalog.gd").ELITE_VISUAL,
		"scene":preload("res://src/monsters/Hobgoblin.tscn"),
	},

	"gargoyle": {
		"id":"gargoyle","name":"가고일","role":"tank","family":"gargoyle","species":"rock","grade":"rare","rarity":"rare","attack_type":"melee",
		"base_cost":14.0,"summon_exp":14.0,"default_unlocked":false,"combat_enabled":true,
		"base_stats":preload("res://src/data/gargoyle_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Gargoyle/frames/idle_01.png",
		"elite_visual":preload("res://src/data/gargoyle_behavior_catalog.gd").ELITE_VISUAL,
		"balance":{"health_share":0.80174927,"damage_share":0.68204365,"note":"원거리 40~60% 피감·반경200 아군피해30% 인계. 느린 근접/낮은 추격·직접DPS로 기회비용 반영. 실전 승률 미검증"},
		"description":"원거리 공격·기술 피해40% 감소. HP50%→15%에서 추가 감소0%→20%. 반경200 아군 원거리피해30% 대신 받음(가장 가까운1마리, 연쇄/중첩 제외). 느린 근접 탱커.",
		"special_augment_ids":["gargoyle_recompense","gargoyle_sky_bastion","gargoyle_stone_slumber"],
		"elite_skills":[{"runtime":"monster","id":"elite_gargoyle_boulder_guard","name":"거석의 보호","description":"선쿨2초/재사용10초. 지름400 아군에게 원거리 쉴드150 갱신(중첩 없음).","initial_cooldown":2.0,"cooldown":10.0,"radius":200.0,"shield_amount":150,"retry_interval":0.25}],
		"scene":preload("res://src/monsters/Gargoyle.tscn"),
	},

	"arthur": {
		"id":"arthur","name":"아서왕","rarity":"transcendent","grade":"transcendent","role":"tank","species":"humanoid","family":"arthur","attack_type":"melee","combat_style":"melee_tank",
		"collection_card":{"style_label":"근접 탱커형","identity":"아발론의 성왕","feature":"엑스칼리버 · 원탁 · 축복 · 방어"},
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,"special_augment_ids":[],
		"growth_metric":"real_tanks_summoned","summon_growth":preload("res://src/data/arthur_behavior_catalog.gd").GROWTH,
		"base_stats":preload("res://src/data/arthur_behavior_catalog.gd").BASE,"transcendence":preload("res://src/data/arthur_behavior_catalog.gd").RULES,
		"card_icon_path":"res://assets/art/Transcendent_monster/King_Arthur/frames/idle_01.png","ground_shadow":{"size":Vector2(80,22),"offset_y":0.0,"opacity":0.35},
		"scene":preload("res://src/monsters/Arthur.tscn"),
		"description":"실제 탱커 40마리 소환 및 아군 사망 50회 후 전투당 1회. 소환 전 실제 탱커 수 × 공격력 1.5 / 체력 15 성장. 엑스칼리버 직선 돌진, 원탁의 기사 지원, 성왕의 축복 반격 보호막, 아발론의 가호 확률 방어. 일반/특수 증강·엘리트·대형몹 제외.",
	},
	"shuten_doji": {
		"id":"shuten_doji","name":"슈텐-도지","rarity":"transcendent","grade":"transcendent","role":"control","species":"humanoid","family":"shuten_doji","attack_type":"melee","combat_style":"melee_control",
		"collection_card":{"style_label":"근접 제어형","identity":"혈주의 귀왕","feature":"술안개 · 발화 · 사슬 · 귀왕해방"},
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,"special_augment_ids":[],
		"growth_metric":"statuses_applied","summon_growth":preload("res://src/data/shuten_doji_behavior_catalog.gd").STATUS_GROWTH,
		"base_stats":preload("res://src/data/shuten_doji_behavior_catalog.gd").BASE,"transcendence":preload("res://src/data/shuten_doji_behavior_catalog.gd").RULES,
		"card_icon_path":"res://assets/art/Transcendent_monster/Shuten-doji/frames/idle_01.png","ground_shadow":{"size":Vector2(80,22),"offset_y":0.0,"opacity":0.35},
		"scene":preload("res://src/monsters/ShutenDoji.tscn"),
		"description":"제어형 실제40회 소환 및 상태이상3회 후 전투당1회. 인간형 근접 제어. 공격220/체력2500부터 소환 전 상태이상 행동당 공격1/체력5 성장(한 공격·기술1회). 이속310·공격간격2초. 게이지100·지휘력회복100%/초당최대15. 혈주연무30/20초:2초12안개·지름600/각200·5~10초·본인외아군도피해·둔화50%,본인둔화80%/피감70%. 귀염지폭0/0:잔여시간합10초이하발화·지름300/175%·현재HP6%출혈7초·기존출혈기절2초·안개당CD2초환급. 쇄혼귀면20/60초:느린유도·3초99%둔화/침묵/250%·이후10초면역·지연도달CD환급. 귀왕해방:첫치명상3초무적/100%회복·강화공격후15초절반안개·적중CD1초/잃은HP1%회복·20적중기절2.5초. 일반/특수증강·엘리트·대형몹 제외.",
	},

	"manticore": {
		"id":"manticore","name":"만티코어","rarity":"transcendent","grade":"transcendent","role":"exploder","species":"beast","family":"manticore","attack_type":"ranged","combat_style":"ranged_harasser",
		"collection_card":{"style_label":"원거리(근접) 폭발형","identity":"살을 찢는 재앙","feature":"사냥 · 추적 · 불꽃 · 맹독유성"},
		"growth_metric":"damage_dealt","summon_growth":preload("res://src/data/manticore_behavior_catalog.gd").GROWTH,
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,"special_augment_ids":[],
		"base_stats":preload("res://src/data/manticore_behavior_catalog.gd").BASE,"transcendence":preload("res://src/data/manticore_behavior_catalog.gd").RULES,
		"card_icon_path":"res://assets/art/Transcendent_monster/manticore/frames/idle_01.png","ground_shadow":{"size":Vector2(78,20),"offset_y":0.0,"opacity":0.35},
		"scene":preload("res://src/monsters/Manticore.tscn"),
		"description":"누적 피해400 후 전투당1회. 2연격 각42+소환 전 피해×0.075, HP1700+피해×0.5. 이속235·지름650·580속도 사냥/추적·완료 후1.5초. 게이지100·지휘력회복100%/초당최대15. 등장 폭발135%는 본인 제외 아군도 피해. 불꽃50/60초·30초·접촉1초100%, 화상75%/1초·공격력절반. 유성35/35초·2초10발·175%·3초중독200%·2초현재HP6%독구름. 지각분쇄30/30초·5초·680거리/450속도·200%·3초30%둔화. 기본5적중 출혈10초/최대HP3%, 출혈대상3타50%·쉴드4%. 첫 치명상 후퇴2배·잃은HP15%회복. 일반/특수증강·엘리트·대형몹 제외.",
	},

	"izanami": {
		"id":"izanami","name":"이자나미","rarity":"transcendent","grade":"transcendent","role":"control","species":"divine_humanoid","family":"izanami","attack_type":"ranged","combat_style":"ranged_harasser",
		"collection_card":{"style_label":"원거리 제어형","identity":"황천의 여신","feature":"원혼 · 침묵 · 도깨비불 · 토리이"},
		"growth_metric":"statuses_applied","summon_growth":preload("res://src/data/izanami_behavior_catalog.gd").STATUS_GROWTH,
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,"special_augment_ids":[],
		"base_stats":preload("res://src/data/izanami_behavior_catalog.gd").BASE,"transcendence":preload("res://src/data/izanami_behavior_catalog.gd").RULES,
		"card_icon_path":"res://assets/art/Transcendent_monster/Izanami/frames/idle_01.png","ground_shadow":{"size":Vector2(78,20),"offset_y":0.0,"opacity":0.35},
		"scene":preload("res://src/monsters/Izanami.tscn"),
		"description":"제어형 실제50회 소환 및 상태이상3회 적중 후 전투당1회. 공격55+소환 전 상태이상 행동×1, HP1400+행동×5(한 공격·기술1회, 지속갱신·다중장판 중복 제외). 사거리 지름550 즉시타격·공격간격1.5초·이속250·거리 유지. 게이지100/증강 적용 지휘력회복100%, 초당최대15. 황천윤무20/30초:7초 받는피해+15%·둔화12%,12피격 시155%·3초99%둔화/침묵. 명계귀화10/8초:0.75초 예고·지름180·170%,3초 장판200%·갱신 둔화30%. 원혼추살30/20초:2초간8개,5초 배회·120%/1.5초기절. 피해12회 또는 상태4회마다 본인 최대HP4% 쉴드 중첩 및 토리이10초·지름350:아군 주는피해+15%/받는피해-20%,용사 주는피해-15%/받는피해+20%. 1초월:귀화CD절반·즉시.2초월:추살소모절반·인식+80%.3초월:귀화CD추가-2초·범위+30%.4초월:토리이15초·아군피감40%.5초월:통과 시이속+40%5초·피감70%1초. 일반/특수증강·엘리트·대형몹 제외.",
	},

	"bulgasal": {
		"id":"bulgasal","name":"불가살","rarity":"transcendent","grade":"transcendent",
		"role":"tank","species":"beast","family":"bulgasal","attack_type":"melee",
		"combat_style":"melee_tank","collection_card":{"style_label":"근접 탱커형","identity":"강철의 짐승","feature":"돌기둥 · 중첩 쉴드 · 강철도약"},
		"growth_metric":"allies_died","summon_growth":BULGASAL_BEHAVIOR.DEATH_GROWTH,
		"attack_growth":{"metric":"tanks_died","multiplier":BULGASAL_BEHAVIOR.DAMAGE_PER_TANK_DEATH},
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,
		"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,"special_augment_ids":[],
		"description":"탱커 실제20마리 소환 및 아군50마리 사망 후 전투당1회. HP2100+아군 누적 사망 수×15, 공격130+소환 전 탱커 사망 수×1.5(소환 시 고정), 공격 간격1.6초·이속270. 게이지60·증강 적용 지휘력 회복100%, 초당최대15. 바위던지기:15/20초, 지름300내300%·기절2초, 지름600내175%·둔화50%2초. 잠입:15/25초,7초 이속+50%·피해60%감소·도달135%/치유감소25%3초. 강철도약:20/20초,2초 정신집중(기절/침묵 취소),지름250 450%·기절3초/8갈래700거리130%·둔화30%2초(파동1회). 돌기둥 파괴150%여진/섭취HP5%쉴드.10피격마다 후퇴·기둥 교체·HP3%쉴드. 초월1: 바위 무적무시. 초월2: 폭발 후8방향 크기·피해·범위·상태효과50% 조각. 초월3: 기둥최대13개·섭취쉴드7%. 초월4: 돌진 무적·개체충돌/대상인식 제외·무적무시 타격. 초월5: 정신집중 행동제어 면역·찍기지름500. 돌진 경로 기둥도 파괴/여진. 일반/특수증강·엘리트·대형몹 제외.",
		"card_icon_path":"res://assets/art/Transcendent_monster/Bulgasal/frames/idle_01.png",

		"base_stats":preload("res://src/data/bulgasal_behavior_catalog.gd").BASE,
		"transcendence":preload("res://src/data/bulgasal_behavior_catalog.gd").RULES,
		"ground_shadow":{"size":Vector2(88,22),"offset_y":0.0,"opacity":0.35},
		"scene":preload("res://src/monsters/Bulgasal.tscn"),
	},
	"zeus": {
		"id":"zeus","name":"제우스","rarity":"transcendent","grade":"transcendent",
		"role":"ranged","species":"divine_humanoid","family":"zeus","attack_type":"ranged",
		"combat_style":preload("res://src/data/zeus_behavior_catalog.gd").COMBAT_STYLE,
		"collection_card":{"style_label":"원거리 견제형","identity":"천둥의 군주","feature":"즉시 낙뢰 · 마비 · 거리 유지"},
		"summon_growth":{"max_hp":preload("res://src/data/zeus_behavior_catalog.gd").HP_PER_SUMMON,"attack_damage":preload("res://src/data/zeus_behavior_catalog.gd").DAMAGE_PER_SUMMON},
		"default_unlocked":false,"combat_enabled":true,"base_cost":0.0,"summon_exp":0.0,
		"can_be_elite":false,"can_be_giant":false,"normal_augments_enabled":false,
		"description":"지휘력300과 마력200 소모 후 전투당1회 무료 소환. 소환 전 실제 생성 수에 따라 HP1450+수×5 / 공격150+수×1. 심판: 지름475 즉시 번개, 50%확률2초75% 마비(공속 저하). 천둥구체:2초 정신집중 후 지름500 영역에서3초간 무작위12회 낙뢰·중심5회 추적. 각 낙뢰 지름120·200%(2초월235%·무적무시)·둔화/마비30%. 마비 대상 기본공격 적중 시 최대HP1% 중첩 쉴드. 왕관:15초,5초마다HP3%회복·마비효과50%증가(3초월 모든 기술CD최소10초). 천둥가르기:650속도·1500직선·150%(2초월175%·무적무시)·마비20%. 과전압:지름550 아군사망 구슬당 게이지0.01(4초월0.02),5초월 잃은HP0.07%회복. 게이지100·지휘력회복100%(증강 적용)·초당최대15. 일반/특수증강·엘리트·대형몹 제외.",
		"card_icon_path":"res://assets/art/Transcendent_monster/zeus/frames/idle_01.png",

		"base_stats":preload("res://src/data/zeus_behavior_catalog.gd").BASE,
		"transcendence":preload("res://src/data/zeus_behavior_catalog.gd").RULES,
		"special_augment_ids":[],"ground_shadow":{"size":Vector2(76,20),"offset_y":43.0,"opacity":0.35},
		"scene":preload("res://src/monsters/Zeus.tscn"),
	},
	"yuki_onna": {
		"id":"yuki_onna","name":"설녀","role":"control","family":"yuki_onna","species":"humanoid","grade":"rare","rarity":"rare","attack_type":"ranged",
		"base_cost":5.5,"summon_exp":5.5,"default_unlocked":false,
		"description":"사거리 지름400, 투사체속도250. 적중마다5초간10% 곱연산 둔화, 대상별 설녀 공용 최대10중첩. 사망 시 반경250 아군 설녀에5초 한기, 최대5중첩: 중첩마다 공속×1.10/투사체속도×1.05/둔화강도×1.02.",
		"base_stats":preload("res://src/data/yuki_onna_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Yuki-onna/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(72,20),"offset_y":44.0,"opacity":0.35},
		"special_augment_ids":["yuki_eternal_chill","yuki_endless_winter","yuki_threefold_snow"],
		"elite_visual":preload("res://src/data/yuki_onna_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","passive":true,"id":"elite_yuki_snowflake","name":"설화","description":"설녀 공용 둔화가 최대중첩에 도달하면 전부 소모, 공격력200% 즉시 피해와2초99% 둔화.","initial_cooldown":0.0,"cooldown":0.0}],
		"scene":preload("res://src/monsters/YukiOnna.tscn"),
	},
	"wolf": {
		"id":"wolf", "name":"늑대", "role":"swarm", "family":"wolf", "species":"beast", "grade":"advanced", "rarity":"uncommon", "attack_type":"melee",
		"base_cost":5.0, "summon_exp":5.0, "default_unlocked":false,
		"description":"빠른 근접 2연격(공격력을 절반씩 분배). 반경250 내 아군 늑대 사망 시1초 하울링 후10초 공격력+15%. 중첩 없이 갱신, 남은 버프2초 이하에서만 재시전.",
		"base_stats":preload("res://src/data/wolf_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/wolf/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(80,20), "offset_y":43.0, "opacity":0.35},
		"special_augment_ids":["wolf_crushing_fang","wolf_blood_scent","wolf_iron_howl"],
		"elite_visual":preload("res://src/data/wolf_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "id":"elite_wolf_pack_hunt", "name":"무리사냥", "description":"1초간 시전 후 뒤쪽에서 이속+30% 일반 늑대12마리 소환. 증강 적용, 분산 생성.", "initial_cooldown":5.0, "cooldown":20.0, "retry_interval":0.25}],
		"scene":preload("res://src/monsters/Wolf.tscn"),
	},
	"succubus": {
		"id":"succubus", "name":"서큐버스", "role":"controller", "family":"succubus", "species":"humanoid", "grade":"legendary", "rarity":"legendary", "attack_type":"melee",
		"base_cost":13.5, "summon_exp":13.5, "default_unlocked":false,
		"description":"공용 적중 15회에 2초 매혹(공격·기술 봉인, 시전자 접근, 이속 -40%). 종료 후 7초 면역. 매혹 대상 추가 피해15%. 치명 피해 시1회 생존하고3초 잠입(행동 정지·무적·반투명).",
		"base_stats":preload("res://src/data/succubus_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Succubus/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(72,22), "offset_y":43.0, "opacity":0.35},
		"special_augment_ids":["succubus_shadow_recovery","succubus_shadow_ambush","succubus_danger_sense"],
		"elite_visual":preload("res://src/data/succubus_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[
			{"runtime":"monster", "id":"elite_succubus_cut", "kind":"cut", "name":"절개", "description":"용사 뒤로 순간이동 후 공격력150% 타격.", "initial_cooldown":0.0, "cooldown":15.0, "damage_multiplier":1.5, "retry_interval":0.25},
			{"runtime":"monster", "id":"elite_succubus_drain", "kind":"drain", "name":"정기흡수", "description":"이전 흡수 이후 실제 준 피해를 비우고55% 회복.", "initial_cooldown":6.0, "cooldown":20.0, "heal_ratio":0.55, "retry_interval":0.25},
			{"runtime":"monster", "id":"elite_succubus_waltz", "kind":"waltz", "name":"유혹의 왈츠", "description":"받는 피해50% 감소.2.5초간0.5초마다 무작위 각도로 순간이동·타격(총 공격력200%), 실제 준 피해40% 회복.", "initial_cooldown":10.0, "cooldown":60.0, "duration":2.5, "interval":0.5, "damage_multiplier":2.0, "heal_ratio":0.4, "damage_taken_multiplier":0.5, "alpha":0.5, "retry_interval":0.25}
		],
		"scene":preload("res://src/monsters/Succubus.tscn"),
	},
	"scorpion": {
		"id":"scorpion", "name":"전갈", "role":"swarm", "family":"scorpion", "species":"beast", "grade":"normal", "rarity":"common", "attack_type":"melee",
		"base_cost":3.0, "summon_exp":3.0, "default_unlocked":false,
		"description":"빠른 근접 물량 몬스터. 실제 준 피해만큼 10초간 중독 추가 피해. 같은 개체·타격별 중독 중첩/갱신 없음.",
		"base_stats":preload("res://src/data/scorpion_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Scorpion/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(76,20), "offset_y":34.0, "opacity":0.35},
		"special_augment_ids":["scorpion_rapid_venom","scorpion_twin_sting","scorpion_death_swamp"],
		"elite_visual":preload("res://src/data/scorpion_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "id":"elite_scorpion_consume", "name":"약육강식", "description":"반경 250 내 가까운 일반 전갈 1마리 섭취. 최대 체력·공격력·이속·초당 공격횟수 합산. 섭취 사망은 경험치·킬 없음.", "initial_cooldown":3.0, "cooldown":7.0, "radius":250.0, "retry_interval":0.25}],
		"scene":preload("res://src/monsters/Scorpion.tscn"),
	},
	"powwow_mummy": {
		"id":"powwow_mummy", "name":"미라 주술사", "role":"ranged", "family":"powwow_mummy", "species":"undead", "grade":"rare", "rarity":"rare", "attack_type":"ranged",
		"base_cost":4.5, "summon_exp":4.5, "default_unlocked":false,
		"description":"사거리 지름 475, 투사체 속도 275. 20초마다 다른 아군 1개체에 무작위 버프: 용기(10초 공격 +15%, 실드 최대 HP 10%) / 회복(잃은 HP 5%) / 날렵(10초 이속 +50%). 같은 버프 중첩 없이 갱신.",
		"base_stats":preload("res://src/data/powwow_mummy_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/powwowmummy/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(68,22),"offset_y":41.0,"opacity":0.35},
		"special_augment_ids":["powwow_mummy_brave_chant","powwow_mummy_restoring_chant","powwow_mummy_quick_ritual"],
		"elite_visual":preload("res://src/data/powwow_mummy_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","passive":true,"id":"elite_powwow_mummy_multicast","name":"다중시전","description":"버프 주기마다 3종을 서로 다른 아군에게 시전. 실제 기본공격 적중마다 다음 버프 대기 -1초.","initial_cooldown":0.0,"cooldown":0.0,"hit_cooldown_reduction":1.0}],
		"scene":preload("res://src/monsters/PowwowMummy.tscn"),
	},
	"mummy": {
		"id":"mummy", "name":"미라", "role":"tank", "family":"mummy", "species":"undead", "grade":"advanced", "rarity":"uncommon", "attack_type":"melee",
		"base_cost":7.0, "summon_exp":7.0, "default_unlocked":false,
		"description":"소환 시 최대 체력 50%의 실드. 체력·공격·이속·공속 중간인 근거리 탱커.",
		"base_stats":preload("res://src/data/mummy_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/mummy/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(70,22), "offset_y":41.0, "opacity":0.35},
		"special_augment_ids":["mummy_eternal_bandage","mummy_broken_seal","mummy_dry_wound"],
		"elite_visual":preload("res://src/data/mummy_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "passive":true, "id":"elite_mummy_curse", "name":"미라의 저주", "description":"실제 타격 시 2초간 대상 받는 피해 +20% (갱신). 접근 이동속도 상시 +30%.", "initial_cooldown":0.0, "cooldown":0.0, "duration":2.0, "damage_increase":0.20, "move_speed_multiplier":1.30}],
		"scene":preload("res://src/monsters/Mummy.tscn"),
	},
	"medusa": {
		"id":"medusa", "name":"메두사", "role":"controller", "family":"medusa", "species":"humanoid", "grade":"rare", "rarity":"rare", "attack_type":"melee",
		"base_cost":7.0, "summon_exp":7.0, "default_unlocked":false,
		"description":"몬스터와 충돌·밀어내기 없음. 추적 중 초당 이속 +10%, 최대 2배. 실제 적중 시 초기화. 메두사 공용 적중 10스택에 2.5초 석화 (이동만 불가). 석화마다 필요 스택 +1.",
		"base_stats":MEDUSA_BEHAVIOR.BASE,
		"card_icon_path":"res://assets/art/monsters/medusa/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(66,20), "offset_y":39.0, "opacity":0.35},
		"special_augment_ids":["medusa_serpent_momentum","medusa_stone_shatter","medusa_stone_residue"],
		"elite_visual":MEDUSA_BEHAVIOR.ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "passive":true, "id":"elite_medusa_hidden_poison", "name":"숨겨진 독", "description":"반경 250 내 메두사에 중독 타격 부여. 실제 피해를 5초에 걸쳐 추가 적용. 같은 개체 중첩·갱신 없음, 다른 개체는 별도 중독.", "initial_cooldown":0.0, "cooldown":0.0, "radius":250.0, "duration":5.0, "refresh_interval":0.2, "buff_linger":0.35}],
		"scene":preload("res://src/monsters/Medusa.tscn"),
	},
	"kraken": {
		"id":"kraken", "name":"크라켄", "role":"ranged", "family":"kraken", "species":"beast", "grade":"legendary", "rarity":"legendary", "attack_type":"ranged",
		"base_cost":15.0, "summon_exp":15.0, "default_unlocked":false,
		"can_be_elite":false, "can_be_giant":false, "spawn_at_max_range":true,
		"description":"고정형 · 지름 2000 사거리. 용사 주변 지름 200 안에 촉수 3개를 2초간 순차 타격 (각 공격력의 1/3). 실제 적중 3회마다 개체 공격력 +0.1%. 사망 시 자신 중심 8방향 촉수 일격. 엘리트·대형몹 없음.",
		"base_stats":KRAKEN_BEHAVIOR.BASE,
		"card_icon_path":"res://assets/art/monsters/Kraken/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(160,40), "offset_y":65.0, "opacity":0.38},
		"special_augment_ids":["kraken_abyss_escape", "kraken_tentacle_barrage", "kraken_abyss_titan"],
		"scene":preload("res://src/monsters/Kraken.tscn"),
	},
	"dullahan": {
		"id": "dullahan", "name": "망령 기사", "role": "tank", "family": "dullahan", "species": "undead", "grade": "legendary", "rarity": "legendary", "attack_type": "melee",
		"base_cost": 12.0, "summon_exp": 12.0, "default_unlocked": false,
		"description": "사망 시 1회 15% 체력으로 부활. 실제 준 피해의 40% 회복. HP 20% 이하에서 위험감지: 이속 +225%로 이탈 후 3초간 휴식하며 HP 50%까지 회복 (쿨 20초).",
		"base_stats": DULLAHAN_BEHAVIOR.BASE,
		"passive": DULLAHAN_BEHAVIOR.PASSIVE,
		"danger_sense": DULLAHAN_BEHAVIOR.DANGER,
		"card_icon_path": "res://assets/art/monsters/Dullahan/frames/idle_01.png",
		"ground_shadow": {"size": Vector2(148, 44), "offset_y": 74.0, "opacity": 0.38},
		"special_augment_ids": ["dullahan_dead_wall", "dullahan_soul_shackles", "dullahan_immortal_thirst"],
		"elite_visual": {"mode": "frames", "asset_dir": "res://assets/art/elitemonster/Dullahan/frames", "target_height": 280.0, "animations": {
			"idle": {"prefix":"idle", "count":4, "fps":6.0, "loop":true}, "move": {"prefix":"walk", "count":6, "fps":9.0, "loop":true},
			"attack": {"prefix":"atk", "count":4, "fps":10.0, "loop":false}, "hit": {"files":["hit_01.png", "hit-02.png"], "count":2, "fps":12.0, "loop":false},
			"death": {"prefix":"dead", "count":7, "fps":10.0, "loop":false}}},
		"elite_skills": [
			{"runtime":"monster", "id":"elite_dullahan_march", "name":"진격", "description":"반경 250 내 0레벨·무증강 해골 전사/궁병 10마리를 5초간 순차 소환. 죽음 역재생 후 행동 시작.", "initial_cooldown":10.0, "cooldown":40.0, "count":10, "interval":0.5, "radius":250.0, "summon_ids":["skeleton", "skeleton_archer"], "summon_modifiers":{"fixed_base_stats":true}},
			{"runtime":"monster", "id":"elite_dullahan_charge", "name":"망령돌진", "description":"소환 시 1회, 5초간 접근 이동속도 200%.", "initial_cooldown":0.0, "cooldown":0.0, "once":true, "duration":5.0, "speed_multiplier":2.0},
			{"runtime":"monster", "id":"elite_dullahan_slam", "name":"강타", "description":"붉은 예고 후 공격 프레임 종료 시 공격력 2배 피해와 1.5초 기절.", "initial_cooldown":5.0, "cooldown":30.0, "windup":0.35, "damage_multiplier":2.0, "stun_duration":1.5}
		],
		"scene": preload("res://src/monsters/Dullahan.tscn"),
	},
	"banshee": {
		"id": "banshee", "name": "밴시", "role": "controller",
		"family": "banshee", "species": "undead", "grade": "advanced", "rarity": "uncommon",
		"attack_type": "melee", "base_cost": 6.5, "summon_exp": 6.5,
		"default_unlocked": false,
		"description": "빠르게 배회하다 공격 예고 후 3배속 돌진. 적중 시 1초간 10% 둔화와 현재 체력 0.5% 추가 피해.",
		"base_stats": {
			"max_hp": 88, "move_speed": 110.0, "attack_damage": 4,
			"attack_range": 62.0, "attack_cooldown": 1.0, "exp_reward": 26,
			"detection_range": 420.0, "charge_speed_multiplier": 3.0,
			"slow_multiplier": 0.90, "slow_duration": 1.0,
		},
		"card_icon_path": "res://assets/art/monsters/Banshee/frames/idle_01.png",
		"ground_shadow": {"size": Vector2(58, 18), "offset_y": 27.0, "opacity": 0.34},
		"special_augment_ids": ["banshee_bleeding", "banshee_charge_stealth", "banshee_death_possession"],
		"elite_visual": {
			"mode": "frames", "asset_dir": "res://assets/art/elitemonster/Banshee/frames", "target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 12.0, "loop": false},
				"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [{
			"id": "elite_banshee_possession", "name": "빙의",
			"description": "최대 체력 20%를 소모해 2초 공포. 공포 종료 후 3초간 빙의 불가.",
			"initial_cooldown": 5.0, "cooldown": 20.0,
			"duration": 2.0, "self_max_hp_cost": 0.20,
		}],
		"scene": preload("res://src/monsters/Banshee.tscn"),
	},
	"slime": {
		"id": "slime",
		"giant_scaling": {"basic_attack": true},
		"name": "슬라임",
		"role": "swarm",
		"species": "liquid",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 3.0,
		"summon_exp": 3.0,
		"base_stats": {
			"max_hp": 72,
			"move_speed": 122.0,
			"attack_damage": 9,
			"attack_range": 72.0,
			"attack_cooldown": 1.10,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/slime/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 27.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"slime_cell_division",
			"slime_residual_mucus",
			"slime_pack_instinct",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/slime/frames",
			"target_height": 80.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 4, "fps": 10.0, "loop": true},
				"attack": {"prefix": "atk", "count": 3, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 4, "fps": 14.0, "loop": false},
				"death": {"prefix": "death", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_slime_proliferation",
				"name": "분열증식",
				"description": "일반 슬라임 12기 투척 · 0.25초 간격",
				"initial_cooldown": 3.0,
				"cooldown": 20.0,
				"spawn_count": 12,
				"spawn_interval": 0.25,
				"launch_distance_min": 105.0,
				"launch_distance_max": 190.0,
				"arc_duration": 0.55,
				"arc_height": 82.0,
			},
		],
		"scene": preload("res://src/monsters/Slime.tscn"),
	},
	"spider": {
		"id": "spider",
		"runtime_scaling": {"spawn_property_multipliers": {&"slow_duration": &"spider_slow_duration_multiplier"}},
		"giant_scaling": {"basic_attack": true, "ranged_attack": true, "stat_properties": [&"slow_duration"]},
		"name": "거미",
		"role": "controller",
		"species": "beast",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 5.0,
		"summon_exp": 5.0,
		"base_stats": {
			"max_hp": 45,
			"move_speed": 150.0,
			"attack_damage": 5,
			"attack_range": 300.0,
			"attack_cooldown": 1.35,
			"slow_multiplier": 0.72,
			"slow_duration": 1.5,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/spider/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(68.0, 22.0),
			"offset_y": 31.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"spider_triple_web",
			"spider_sticky_web",
			"spider_binding",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/spider/frames",
			"target_height": 88.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 10.0, "loop": true},
				"attack": {"start": 11, "count": 8, "fps": 14.0, "loop": false},
				"death": {"start": 19, "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_spider_web_nest",
				"name": "거미집",
				"description": "지름 500 · 5초 · 용사 이속 -50% · 아군 이속 +15%",
				"initial_cooldown": 3.0,
				"cooldown": 25.0,
				"duration": 5.0,
				"radius": 250.0,
				"hero_slow_multiplier": 0.50,
				"monster_speed_multiplier": 1.15,
				"tick_interval": 0.20,
				"effect_path": "res://assets/art/monsters/spider/frames/effect/frame_07.png",
			},
		],
		"scene": preload("res://src/monsters/Spider.tscn"),
	},
	"orc": {
		"id": "orc",
		"giant_scaling": {"basic_attack": true},
		"runtime_scaling": {"hp_upgrade_property": &"orc_hp_multiplier"},
		"name": "오크",
		"role": "tank",
		"species": "beast",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 10.0,
		"summon_exp": 10.0,
		"base_stats": {
			"max_hp": 140,
			"move_speed": 78.0,
			"attack_damage": 18,
			"attack_range": 82.0,
			"attack_cooldown": 1.45,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/orc/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(82.0, 26.0),
			"offset_y": 38.0,
			"opacity": 0.52,
		},
		"special_augment_ids": [
			"orc_berserk",
			"orc_rage_stacks",
			"orc_last_charge",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/orc/frames",
			"target_height": 104.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 10.0, "loop": true},
				"attack": {"start": 11, "count": 6, "fps": 14.0, "loop": false},
				"hit": {"start": 17, "count": 4, "fps": 14.0, "loop": false},
				"death": {"start": 21, "count": 3, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_orc_frenzy",
				"name": "광분",
				"description": "돌진 피해 150% · 1초간 99% 둔화",
				"initial_cooldown": 0.0,
				"cooldown": 20.0,
				"charge_speed_multiplier": 5.0,
				"max_charge_duration": 2.5,
				"damage_multiplier": 1.50,
				"slow_multiplier": 0.01,
				"slow_duration": 1.0,
			},
		],
		"scene": preload("res://src/monsters/Orc.tscn"),
	},
	"skeleton": {
		"id": "skeleton",
		"giant_scaling": {"basic_attack": true},
		"elite_spawn": {"alive_registration_method": &"set_elite_skeleton_alive"},
		"name": "해골 전사",
		"role": "tank",
		"species": "undead",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 9.0,
		"summon_exp": 9.0,
		"base_stats": {
			"max_hp": 105,
			"move_speed": 112.0,
			"attack_damage": 10,
			"attack_range": 78.0,
			"attack_cooldown": 1.25,
			"hits_per_attack": 2,
			"hit_damage_multiplier": 1.0,
			"second_hit_delay": 0.14,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelleton/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(72.0, 23.0),
			"offset_y": 60.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"skeleton_return_of_dead",
			"skeleton_bone_bond",
			"skeleton_necrotic_guard",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/skelleton/frames",
			"target_height": 170.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 10.0, "loop": true},
				"attack": {"prefix": "attack", "count": 6, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_skeleton_ambush",
				"name": "암습",
				"description": "2초 은신 · 받는 피해 -50% · 다음 2타 피해 +50%",
				"initial_cooldown": 2.0,
				"cooldown": 15.0,
				"duration": 2.0,
				"damage_taken_multiplier": 0.50,
				"attack_damage_multiplier": 1.50,
				"opacity": 0.32,
			},
		],
		"scene": preload("res://src/monsters/Skeleton.tscn"),
	},
	"skeleton_archer": {
		"id": "skeleton_archer",
		"giant_scaling": {"basic_attack": true, "ranged_attack": true},
		"name": "해골 궁병",
		"role": "ranged",
		"species": "undead",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 7.5,
		"summon_exp": 7.5,
		"base_stats": {
			"max_hp": 48,
			"move_speed": 88.0,
			"attack_damage": 8,
			"attack_range": 137.5,
			"attack_range_diameter": 275.0,
			"attack_cooldown": 1.55,
			"projectile_speed": 300.0,
			"projectile_range": 190.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelletonarcher/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(64.0, 20.0),
			"offset_y": 44.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"skeleton_archer_power_shot",
			"skeleton_archer_revive",
			"skeleton_archer_triple_shot",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/skelletonarcher/frames",
			"target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 5, "fps": 9.0, "loop": true},
				"attack": {"prefix": "atk", "count": 7, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_skeleton_archer_arrow_rain",
				"name": "화살비",
				"description": "지름 275 · 화살 12발×3회 · 피해 130% · 1초간 25% 둔화",
				"initial_cooldown": 2.0,
				"cooldown": 17.0,
				"radius": 137.5,
				"telegraph_delay": 0.25,
				"wave_interval": 0.35,
				"wave_count": 3,
				"arrows_per_wave": 12,
				"damage_multiplier": 1.30,
				"slow_multiplier": 0.75,
				"slow_duration": 1.0,
				"line_width": 2.0,
				"line_segments": 32,
				"arrow_fall_distance": 170.0,
				"arrow_fall_duration": 0.22,
				"arrow_target_size": 52.0,
				"arrow_texture_path": "res://assets/art/elitemonster/skelletonarcher/frames/effect1/normal_01.png",
			},
		],
		"scene": preload("res://src/monsters/SkeletonArcher.tscn"),
	},
	"kobolt": {
		"id": "kobolt",
		"giant_scaling": {"basic_attack": true, "ranged_attack": true},
		"elite_spawn": {"position_policy": EliteSpawnPosition.FARTHEST_ATTACK_RANGE},
		"name": "코볼트",
		"role": "ranged",
		"species": "beast",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 10.0,
		"summon_exp": 10.0,
		"base_stats": {
			"max_hp": 95,
			"attack_damage": 28,
			"attack_range": 750.0,
			"attack_range_diameter": 1500.0,
			"attack_cooldown": 1.80,
			"projectile_speed": 385.0,
			"projectile_range": 750.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/kobolt/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(70.0, 22.0),
			"offset_y": 32.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"kobolt_projectile_speed",
			"kobolt_unlimited_range",
			"kobolt_giant_fusion",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/kobolt/frames",
			"target_height": 124.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"attack": {"prefix": "atk", "count": 4, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 3, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_kobolt_fighting_spirit",
				"name": "투쟁심",
				"description": "5초간 공격속도 +60%",
				"initial_cooldown": 2.0,
				"cooldown": 10.0,
				"duration": 5.0,
				"attack_speed_multiplier": 1.60,
				"tint": Color(1.0, 0.68, 0.68, 1.0),
			},
		],
		"scene": preload("res://src/monsters/Kobolt.tscn"),
	},
	"bat": {
		"id": "bat",
		"giant_scaling": {"basic_attack": true},
		"name": "박쥐",
		"role": "swarm",
		"species": "beast",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 3.0,
		"summon_exp": 3.0,
		"base_stats": {
			"max_hp": 72,
			"move_speed": 72.0,
			"attack_damage": 6,
			"attack_range": 62.0,
			"attack_cooldown": 0.62,
			"detection_range": 420.0,
			"charge_speed_multiplier": 3.75,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/bat/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(58.0, 18.0),
			"offset_y": 27.0,
			"opacity": 0.42,
		},
		"special_augment_ids": [
			"bat_lifesteal",
			"bat_permanent_charge",
			"bat_echo_summon",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/bat/frames",
			"target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_bat_poison_fang",
				"name": "독이빨",
				"description": "타격 시 3초 독 · 현재 HP의 5% 피해 · 재타격 갱신",
				"passive": true,
				"initial_cooldown": 0.0,
				"duration": 3.0,
				"total_current_hp_ratio": 0.05,
				"tick_interval": 0.50,
			},
		],
		"scene": preload("res://src/monsters/Bat.tscn"),
	},
	"goblin": {
		"id": "goblin",
		"giant_scaling": {"basic_attack": true},
		"name": "고블린",
		"role": "swarm",
		"species": "beast",
		"family": "goblin",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 5.4,
		"summon_exp": 5.4,
		"base_stats": {
			"max_hp": 84,
			"move_speed": 155.0,
			"attack_damage": 7,
			"attack_range": 68.0,
			"attack_cooldown": 0.72,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/goblin/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 30.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"goblin_spawn_stealth",
			"goblin_survivor_growth",
			"goblin_pack_mastery",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/goblin/frames",
			"target_height": 118.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_goblin_commander",
				"name": "지휘관",
				"description": "지름 600 · 고블린 이속 +15% · 5초마다 HP 10% 쉴드",
				"passive": true,
				"runtime_tick": true,
				"initial_cooldown": 0.0,
				"radius": 300.0,
				"aura_tick_interval": 0.20,
				"shield_refresh_interval": 5.0,
				"shield_max_hp_ratio": 0.10,
				"speed_multiplier": 1.15,
				"line_width": 2.0,
				"line_segments": 48,
			},
		],
		"scene": preload("res://src/monsters/Goblin.tscn"),
	},
	"goblin_thrower": {
		"id": "goblin_thrower",
		"giant_scaling": {"basic_attack": true, "ranged_attack": true},
		"name": "고블린투척병",
		"role": "ranged",
		"species": "beast",
		"family": "goblin",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 5.4,
		"summon_exp": 5.4,
		"base_stats": {
			"max_hp": 56,
			"move_speed": 82.0,
			"attack_damage": 7,
			"attack_range": 275.0,
			"attack_range_diameter": 550.0,
			"attack_cooldown": 1.20,
			"projectile_speed": 380.0,
			"projectile_range": 340.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/goblinthrower/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 30.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"goblin_thrower_heavy_rock",
			"goblin_thrower_retreat_heal",
			"goblin_thrower_rapid_fire",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/goblinthrower/frames",
			"target_height": 124.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 9.0, "loop": true},
				"attack": {"prefix": "atk", "count": 5, "fps": 12.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_goblin_thrower_bombardment",
				"name": "폭탄 투하",
				"description": "지름 220 · 폭탄 10개 · 1초 후 공격력 150% 폭발",
				"initial_cooldown": 3.0,
				"cooldown": 20.0,
				"radius": 110.0,
				"bomb_count": 10,
				"bomb_interval": 0.15,
				"projectile_speed": 650.0,
				"fuse_duration": 1.0,
				"damage_multiplier": 1.50,
				"explosion_radius": 52.0,
			},
		],
		"scene": preload("res://src/monsters/GoblinThrower.tscn"),
	},
	"ghost": {
		"id": "ghost",
		"giant_scaling": {"basic_attack": true, "ranged_attack": true},
		"name": "유령",
		"role": "controller",
		"species": "gas",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 6.1,
		"summon_exp": 6.1,
		"base_stats": {
			"max_hp": 92,
			"move_speed": 54.0,
			"attack_damage": 4,
			"attack_range": 275.0,
			"attack_range_diameter": 550.0,
			"attack_cooldown": 2.40,
			"projectile_speed": 500.0,
			"projectile_range": 360.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/ghost/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(58.0, 18.0),
			"offset_y": 29.0,
			"opacity": 0.34,
		},
		"special_augment_ids": [
			"ghost_phase_shift",
			"ghost_stack_slow",
			"ghost_death_empower",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/ghost/frames",
			"target_height": 138.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 5, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 5, "fps": 8.0, "loop": true},
				"attack": {"prefix": "atk", "count": 5, "fps": 10.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 12.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 9.0, "loop": false},
			},
		},
		"elite_skills": [{
			"id": "elite_ghost_fear",
			"name": "공포",
			"description": "1.5초 공포 · 공격 봉인 · 도주 이속 +50%",
			"initial_cooldown": 3.0,
			"cooldown": 15.0,
			"duration": 1.5,
			"move_speed_multiplier": 1.50,
		}],
		"scene": preload("res://src/monsters/Ghost.tscn"),
	},
	"bomb_rat": {
		"id": "bomb_rat",
		"runtime_scaling": {"fuse_property": &"self_destruct_fuse", "explosion_property": &"explosion_damage"},
		"name": "폭탄쥐",
		"role": "burst",
		"species": "beast",
		"grade": "normal",
		"attack_type": "self_destruct",
		"base_cost": 6.0,
		"summon_exp": 6.0,
		"base_stats": {
			"max_hp": 36,
			"move_speed": 175.0,
			"self_destruct_range": 78.0,
			"self_destruct_fuse": 0.30,
			"explosion_radius": 150.0,
			"explosion_damage": 28,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/bombrat/frames/frame_01.png",
		"ground_shadow": {
			"size": Vector2(60.0, 20.0),
			"offset_y": 27.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"bomb_rat_litter",
			"bomb_rat_powder_overload",
			"bomb_rat_unstable_powder",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/bombrat/frames",
			"target_height": 78.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 11.0, "loop": true},
				"attack": {"start": 11, "count": 6, "fps": 14.0, "loop": false},
				"death": {"start": 17, "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_bomb_rat_vibration",
				"name": "진동감지",
				"description": "4초간 이속 +200% · 최대 HP 150% 쉴드",
				"initial_cooldown": 0.0,
				"cooldown": 20.0,
				"duration": 4.0,
				"move_speed_multiplier": 3.0,
				"shield_max_hp_multiplier": 1.50,
			},
		],
		"scene": preload("res://src/monsters/BombRat.tscn"),
	},
}

const ROLE_LABELS := {
	"control": "제어",
	"swarm": "물량",
	"controller": "제어",
	"tank": "탱커",
	"ranged": "원거리",
	"burst": "폭발",
	"exploder": "폭발",
}

const SPECIES_LABELS := {
	"plant":"식물",
	"construct":"구조체",
	"demon":"악마",
	"rock":"암석",
	"humanoid": "인간형",
	"divine_humanoid": "신인형",
	"beast": "짐승",
	"liquid": "액체",
	"undead": "언데드",
	"gas": "기체",
}

const ATTACK_TYPE_LABELS := {
	"melee": "근접",
	"ranged": "원거리",
	"self_destruct": "자폭",
}

const GRADE_LABELS := {
	"uncommon":"고급",
	"common":"일반",
	"transcendent": "초월",
	"rare": "희귀",
	"legendary": "전설",
	"advanced": "고급",
	"normal": "일반",
}

const RARITY_COMBAT_PROFILES := BALANCE.RARITY_COMBAT_PROFILES

# Permanent growth remains additive and separate from base rarity combat stats.
const MAX_UPGRADE_LEVEL := 30
const SHARD_RESEARCH_POINTS := 1
const RARITY_UPGRADE_PROFILES := {
	"common": {
		"label": "일반",
		"hp_per_level": 0.02,
		"damage_per_level": 0.02,
		"shards_required": 30,
		"configured": true,
	},
	"advanced": {
		"label": "고급",
		"hp_per_level": 0.035,
		"damage_per_level": 0.035,
		"shards_required": 30,
		"configured": true,
	},
	"uncommon": {
		"label": "고급",
		"hp_per_level": 0.035,
		"damage_per_level": 0.035,
		"shards_required": 30,
		"configured": true,
	},
	"rare": {
		"label": "희귀",
		"hp_per_level": 0.05,
		"damage_per_level": 0.05,
		"shards_required": 30,
		"configured": true,
	},
	"legendary": {
		"label": "전설",
		"hp_per_level": 0.07,
		"damage_per_level": 0.07,
		"shards_required": 25,
		"configured": true,
	},
	"transcendent": {
		"label": "초월",
		"hp_per_level": 0.10,
		"damage_per_level": 0.10,
		"shards_required": 1,
		"max_level": 5,
		"shard_research_points": 1000,
		"configured": true,
	},
}

static func get_monster(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var result := data.duplicate(true)
	if not data.is_empty():
		result["base_stats"] = get_base_stats(monster_id)
	return result

static func get_elite_visual_profile(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var profile = data.get("elite_visual", {})
	if typeof(profile) != TYPE_DICTIONARY:
		return {}
	return Dictionary(profile).duplicate(true)

static func get_elite_skills(monster_id: String) -> Array:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var raw_skills = data.get("elite_skills", [])
	if typeof(raw_skills) != TYPE_ARRAY:
		return []
	return Array(raw_skills).duplicate(true)

static func get_ground_shadow_config(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var config = data.get("ground_shadow", {})
	if typeof(config) != TYPE_DICTIONARY:
		return {}
	return Dictionary(config).duplicate(true)

static func get_scene(monster_id: String) -> PackedScene:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var scene = data.get("scene")
	return scene as PackedScene

static func get_monster_name(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("name", monster_id))

static func get_role(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("role", "unknown"))

static func get_species(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("species", "unknown"))


static func get_family(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("family", ""))


static func node_has_species(
	target_node: Node,
	species_id: String
) -> bool:
	if not is_instance_valid(target_node):
		return false

	var normalized_species := species_id.strip_edges().to_lower()
	if normalized_species.is_empty():
		return false

	var runtime_species := String(
		target_node.get_meta("monster_species", "")
	).strip_edges().to_lower()
	if runtime_species == normalized_species:
		return true

	var monster_type_value = target_node.get("monster_type")
	if monster_type_value != null:
		var monster_id := String(monster_type_value)
		if get_species(monster_id).strip_edges().to_lower() == normalized_species:
			return true

	# Legacy compatibility only. New monsters should be classified by species
	# in this catalog so every species-based effect picks them up automatically.
	if normalized_species == "undead":
		if (
			bool(target_node.get_meta("undead", false))
			or bool(target_node.get_meta("is_undead", false))
			or target_node.is_in_group("undead")
		):
			return true
		if monster_type_value != null:
			var legacy_type := String(monster_type_value).to_lower()
			return (
				"undead" in legacy_type
				or "skeleton" in legacy_type
				or "zombie" in legacy_type
				or "ghoul" in legacy_type
			)
	return false


static func is_undead_node(target_node: Node) -> bool:
	return node_has_species(target_node, "undead")


static func get_grade(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("grade", "normal"))


static func get_rarity(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("rarity", "common"))


static func get_rarity_combat_profile(monster_id: String) -> Dictionary:
	var rarity := get_rarity(monster_id)
	var profile = RARITY_COMBAT_PROFILES.get(
		rarity,
		RARITY_COMBAT_PROFILES["common"]
	)
	return Dictionary(profile).duplicate(true)


static func get_rarity_upgrade_profile(monster_id: String) -> Dictionary:
	var rarity := get_rarity(monster_id)
	var profile = RARITY_UPGRADE_PROFILES.get(rarity, {})
	if typeof(profile) != TYPE_DICTIONARY:
		return {}
	return Dictionary(profile).duplicate(true)


static func get_attack_type(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("attack_type", ""))

static func get_base_cost(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return float(data.get("base_cost", 0.0))

static func get_summon_exp(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return maxf(float(data.get("summon_exp", data.get("base_cost", 0.0))), 0.0)

static func _cached_base_stats(monster_id: String) -> Dictionary:
	if not balanced_stats_cache.has(monster_id):
		balanced_stats_cache[monster_id] = BALANCE.resolve_base_stats(MONSTERS.get(monster_id, {}))
	return balanced_stats_cache[monster_id]

static func get_base_stats(monster_id: String) -> Dictionary:
	# UI callers keep an independent copy. Spawn uses the cached immutable view below.
	return _cached_base_stats(monster_id).duplicate(true)

static func apply_runtime_base_stats(actor: Node, monster_id: String) -> void:
	BALANCE.apply_base_stats(actor, _cached_base_stats(monster_id))


static func get_role_label(role_id: String) -> String:
	return String(ROLE_LABELS.get(role_id, role_id))

static func get_species_label(species_id: String) -> String:
	return String(SPECIES_LABELS.get(species_id, species_id))

static func get_grade_label(grade_id: String) -> String:
	return String(GRADE_LABELS.get(grade_id, grade_id))

static func get_attack_type_label(attack_type_id: String) -> String:
	return String(
		ATTACK_TYPE_LABELS.get(attack_type_id, attack_type_id)
	)

static func get_ids() -> Array[String]:
	var result: Array[String] = []
	for monster_id in ORDER:
		if MONSTERS.has(monster_id):
			result.append(String(monster_id))
	return result

static func is_default_unlocked(monster_id: String) -> bool:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return bool(data.get("default_unlocked", false))

static func get_shards_required(monster_id: String) -> int:
	return maxi(int(get_rarity_upgrade_profile(monster_id).get("shards_required", 30)), 1)

static func get_max_upgrade_level(monster_id: String) -> int:
	return maxi(int(get_rarity_upgrade_profile(monster_id).get("max_level", MAX_UPGRADE_LEVEL)), 0)

static func get_shard_research_points(monster_id: String) -> int:
	return maxi(int(get_rarity_upgrade_profile(monster_id).get("shard_research_points", SHARD_RESEARCH_POINTS)), 0)

# Collection, reveal results and detail previews share the real battle sprite.
# Profile rewards retain their independent portrait/banner catalog.
static func get_ui_icon_path(monster_id: String) -> String:
	var data := get_monster(monster_id)
	if get_rarity(monster_id) == "transcendent":
		return String(data.get("card_icon_path",""))
	return String(data.get("display_icon_path",data.get("card_icon_path","")))

# Immutable content bindings; callers must not modify the shared profile.
static func get_runtime_scaling_profile(monster_id: String) -> Dictionary:
	if not MONSTERS.has(monster_id):
		return EMPTY_RUNTIME_SCALING
	return MONSTERS[monster_id].get("runtime_scaling", EMPTY_RUNTIME_SCALING)

# Shared immutable overrides; missing fields use DEFAULT_ELITE_SPAWN.
static func get_elite_spawn_profile(monster_id: String) -> Dictionary:
	if not MONSTERS.has(monster_id):
		return DEFAULT_ELITE_SPAWN
	return MONSTERS[monster_id].get("elite_spawn", DEFAULT_ELITE_SPAWN)

# Opt-in bindings preserve legacy giant coverage independently of role/rarity.
static func get_giant_scaling_profile(monster_id: String) -> Dictionary:
	if not MONSTERS.has(monster_id):
		return EMPTY_GIANT_SCALING
	return MONSTERS[monster_id].get("giant_scaling", EMPTY_GIANT_SCALING)
