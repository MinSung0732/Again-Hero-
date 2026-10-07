extends RefCounted
const ROOT := "res://assets/audio/sfx/contextual/"
# Material and action determine a cue; stage numbers do not determine timbre.
const HITS := {
	"ranged_kiter": {"file": "mage_hit.wav", "player": "stage1_hit_audio", "ensure": "_ensure_stage1_audio_runtime"},
	"rogue_combo": {"file": "rogue_hit.wav", "player": "rogue_hit_audio", "ensure": "_ensure_rogue_audio_runtime"},
	"sword_shield": {"file": "fighter_hit.wav", "player": "fighter_hit_audio", "ensure": "_ensure_fighter_audio_runtime"},
	"pistol_gunner": {"file": "gunner_hit.wav", "player": "gunner_hit_audio", "ensure": "_ensure_gunner_audio_runtime"},
	"archmage_elementalist": {"file": "archmage_hit.wav", "player": "archmage_hit_audio", "ensure": "_ensure_archmage_audio_runtime"},
	"berserker_madness": {"file": "berserker_hit.wav", "player": "berserker_hit_audio", "ensure": "_ensure_berserker_audio_runtime"},
}
const HIT_INTERVAL_MS := 140
const HIT_DB := -15.0
const BLOCK_DB := -15.0
const MAGIC_BLOCK_DB := -13.0
const UI_CUES := {
	"formation": {"path": ROOT+"confirm.wav", "db": -11.0, "interval": 0.15},
	"upgrade": {"path": ROOT+"upgrade.wav", "db": -9.0, "interval": 0.25},
	"research": {"path": ROOT+"research.wav", "db": -10.0, "interval": 0.25},
	"demon_level": {"path": ROOT+"demon_level.wav", "db": -10.0, "interval": 0.4},
	"victory": {"path": ROOT+"victory.wav", "db": -10.0},
}
# Rejected/defeat marimba and redundant augment-open jingles are intentionally silent.
const SILENT_UI := ["denied", "defeat"]
