extends RefCounted
const ROOT := "res://assets/audio/sfx/monsters/"
const DEATH_DB := -20.0
const ATTACK_DB := -27.0
const DEATH_INTERVAL := 0.07
const ATTACK_INTERVAL := 0.12
const PITCH_JITTER := 0.08
const GROUPS := {
	"humanoid": {"death":ROOT+"humanoid_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"beast": {"death":ROOT+"beast_death_pixabay.mp3", "melee":ROOT+"bite_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"insect": {"death":ROOT+"insect_death_pixabay.mp3", "melee":ROOT+"bite_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"slime": {"death":ROOT+"slime_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"bone": {"death":ROOT+"bone_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"spirit": {"death":ROOT+"spirit_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"magic_attack_pixabay.mp3"},
	"construct": {"death":ROOT+"construct_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
	"explosion": {"death":ROOT+"explosion_death_pixabay.mp3", "melee":ROOT+"melee_attack_pixabay.mp3", "ranged":ROOT+"arrow_attack_pixabay.mp3"},
}
const MEMBERS := {
	"goblin": "humanoid",
	"goblin_thrower": "humanoid",
	"hobgoblin": "humanoid",
	"kobolt": "humanoid",
	"orc": "humanoid",
	"ogre": "humanoid",
	"imp": "humanoid",
	"satyr_rogue": "humanoid",
	"satyr_shaman": "humanoid",
	"fanatic": "humanoid",
	"dark_elf_rogue": "humanoid",
	"dark_elf_archer": "humanoid",
	"lizardman_spearman": "humanoid",
	"lizardman_fighter": "humanoid",
	"gumiho": "humanoid",
	"succubus": "humanoid",
	"medusa": "humanoid",
	"wolf": "beast",
	"boar": "beast",
	"dusk_panther": "beast",
	"moss_deer": "beast",
	"harpy": "beast",
	"frost_owl": "beast",
	"ember_salamander": "beast",
	"thorn_hedgehog": "beast",
	"kraken": "beast",
	"cave_ant": "insect",
	"spider": "insect",
	"blade_mantis": "insect",
	"venom_scorpion": "insect",
	"scorpion": "insect",
	"iron_beetle": "insect",
	"moon_moth": "insect",
	"bat": "insect",
	"shell_crab": "insect",
	"slime": "slime",
	"toxic_slime": "slime",
	"swamp_toad": "slime",
	"spore_mushroom": "slime",
	"thorn_dryad": "slime",
	"mud_golem": "slime",
	"skeleton": "bone",
	"skeleton_archer": "bone",
	"skeleton_shield": "bone",
	"mummy": "bone",
	"powwow_mummy": "bone",
	"anubis": "bone",
	"dullahan": "bone",
	"ghost": "spirit",
	"banshee": "spirit",
	"lantern_wisp": "spirit",
	"yuki_onna": "spirit",
	"rust_automaton": "construct",
	"rune_sentinel": "construct",
	"gargoyle": "construct",
	"crystal_tortoise": "construct",
	"mimic": "construct",
	"rag_scarecrow": "construct",
	"bomb_rat": "explosion",
}
const MAGIC := ["satyr_shaman","fanatic","imp","gumiho","succubus","medusa","frost_owl","ember_salamander","spore_mushroom","thorn_dryad","rune_sentinel","moon_moth"]
const EXCLUDED := ["arthur", "shuten_doji", "manticore", "izanami", "bulgasal", "zeus"]
const MAGIC_PATH := ROOT+"magic_attack_pixabay.mp3"

static func cue_for(monster_id: String, kind: String, attack_type: String) -> String:
	if monster_id.is_empty() or monster_id in EXCLUDED: return ""
	var group := String(MEMBERS.get(monster_id, "humanoid"))
	if kind == "death": return "monster:"+group+":death"
	if kind != "attack" or attack_type == "self_destruct": return ""
	if attack_type == "ranged" and monster_id in MAGIC: return "monster:magic:attack"
	return "monster:"+group+(":ranged" if attack_type == "ranged" else ":melee")

static func audio_cues() -> Dictionary:
	var cues := {}
	for group in GROUPS:
		for kind in ["death", "melee", "ranged"]:
			var id: String = "monster:"+String(group)+":"+String(kind)
			var death: bool = kind == "death"
			cues[id] = {"path":GROUPS[group][kind], "db":DEATH_DB if death else ATTACK_DB, "interval":DEATH_INTERVAL if death else ATTACK_INTERVAL, "pitch_jitter":PITCH_JITTER}
			if death: cues[id+":elite"] = {"path":GROUPS[group][kind], "db":DEATH_DB+3.0, "interval":DEATH_INTERVAL, "pitch":0.85, "pitch_jitter":PITCH_JITTER}
	cues["monster:magic:attack"] = {"path":MAGIC_PATH, "db":ATTACK_DB, "interval":ATTACK_INTERVAL, "pitch_jitter":PITCH_JITTER}
	return cues

static var cue_ids: Array = []
static func cue_from_index(index: int) -> String:
	if cue_ids.is_empty(): cue_ids = audio_cues().keys()
	return String(cue_ids[index-1]) if index > 0 and index <= cue_ids.size() else ""
