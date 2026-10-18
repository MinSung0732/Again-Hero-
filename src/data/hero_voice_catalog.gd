extends RefCounted

# Content identity owns the pack, independently of the chosen battlefield.
const ROOT := "res://assets/audio/sfx/hero_voices/"
const EMPTY := {}
const PACKS := {
	"ranged_rookie": {"folder": "stage1", "prefix": "Stage1"},
	"swift_hunter": {"folder": "stage2", "prefix": "Stage2"},
	"sword_shield_hero": {"folder": "stage3", "prefix": "Stage3"},
	"pistol_hero": {"folder": "stage4", "prefix": "Stage4"},
	"archmage_hero": {"folder": "stage5", "prefix": "Stage5"},
	"madness_hero": {"folder": "stage6", "prefix": "Stage6"},
	"chemical_hero": {"folder": "stage7", "prefix": "Stage7"},
	"summoner_hero": {"folder": "stage8", "prefix": "Stage8", "unlock": true},
	"purifier_hero": {"folder": "stage9", "prefix": "Stage9", "unlock": true},
	"sage_astra": {"folder": "stage10", "prefix": "Stage10", "unlock": true},
}
const EVENTS := {
	&"entry": {"suffix": "battle_start", "priority": 10, "delay": 0.0, "db": -2.0},
	&"unlock": {"suffix": "hero_unlock_skill", "priority": 20, "delay": 0.0, "db": -2.0, "requires": "unlock"},
	&"defeat": {"suffix": "battle_hero_failed", "priority": 100, "delay": 0.08, "db": -2.0},
	&"victory": {"suffix": "battle_hero_victory", "priority": 100, "delay": 0.0, "db": -2.0},
}
const DUCK_DB := {&"BGM": -7.0, &"SFX": -5.0}
const DUCK_ATTACK_SECONDS := 0.08
const DUCK_RELEASE_SECONDS := 0.22

static func path_for(hero_id: String, event: StringName) -> String:
	var pack: Dictionary = PACKS.get(hero_id, EMPTY)
	var cue: Dictionary = EVENTS.get(event, EMPTY)
	if pack.is_empty() or cue.is_empty(): return ""
	if cue.has("requires") and not bool(pack.get(cue["requires"], false)): return ""
	return ROOT + String(pack.folder) + "/" + String(pack.prefix) + "_" + String(cue.suffix) + ".wav"
