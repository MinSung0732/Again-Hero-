extends RefCounted
## Immutable presentation bindings; unique skills/normalization/anchors stay with Hero.
const STAGE1_FRAME_DIR := "res://assets/art/heroes/stage1_mage/frames"
const STAGE2_FRAME_DIR := "res://assets/art/heroes/stage2_rogue/frames"
const STAGE3_FRAME_DIR := "res://assets/art/heroes/stage3_fighter/frames"
const STAGE4_FRAME_DIR := "res://assets/art/heroes/stage4_gunner/frames"
const STAGE5_FRAME_DIR := "res://assets/art/heroes/stage5_archmage/frames"
const STAGE6_FRAME_DIR := "res://assets/art/heroes/stage6_berserker/frames"
const STAGE7_FRAME_DIR := "res://assets/art/heroes/stage7_alchemist/frames"
const STAGE8_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames"
const STAGE9_FRAME_DIR := "res://assets/art/heroes/stage9_prist/frames"
const STAGE10_FRAME_DIR := "res://assets/art/heroes/stage10_sage/frames"
const EMPTY_PROFILE := {}
const EMPTY_METHODS := []
const EARLY_ARCHETYPES := {
	"grand_sage_astra": true, "cleric_purifier": true, "summoner_gatekeeper": true,
	"alchemist_chemical": true, "berserker_madness": true, "archmage_elementalist": true,
}
const HERO_ID_PROFILES := {"ranged_rookie": "ranged_rookie"}
const LATE_ARCHETYPES := {"pistol_gunner": true, "sword_shield": true, "rogue_combo": true}
const VISUAL_PROFILES := {
	"grand_sage_astra": {
		"frame_dir": STAGE10_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 5.5, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 8.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "count": 6, "fps": 10.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 12.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 8.0, "loop": false, "required": false},
		],
	},
	"cleric_purifier": {
		"frame_dir": STAGE9_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 9.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "attack", "count": 4, "fps": 8.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 12.0, "loop": false, "required": false},
			{"name": "death", "prefix": "death", "count": 4, "fps": 8.0, "loop": false, "required": false},
		],
		"sprite_properties": {"z_index": -2, "show_behind_parent": true},
		"before_scale_methods": ["_build_stage9_frame_anchor_cache"],
		"after_scale_methods": ["_apply_stage9_sprite_anchor"],
	},
	"summoner_gatekeeper": {
		"frame_dir": STAGE8_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 9.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "count": 6, "fps": 12.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 12.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 8.0, "loop": false, "required": false},
		],
		"after_scale_methods": ["_apply_stage8_sprite_anchor"],
	},
	"alchemist_chemical": {
		"frame_dir": STAGE7_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 9.0, "loop": true, "required": false},
			{"name": "run", "prefix": "run", "count": 6, "fps": 11.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "indices": [1, 2, 5], "fps": 7.0, "loop": false, "required": true, "failure_message": "Stage 7 attack frame load failed: %s/atk_%02d.png"},
			{"name": "hit", "prefix": "hit", "count": 2, "fps": 12.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 8.0, "loop": false, "required": false},
		],
		"after_scale_methods": ["_apply_stage7_sprite_anchor"],
		"after_play_methods": ["_apply_alchemist_philosopher_effect_visuals"],
	},
	"berserker_madness": {
		"frame_dir": STAGE6_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 9.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "indices": [1, 5, 2, 6], "fps": 10.0, "loop": false, "required": true, "failure_message": "Stage 6 attack frame load failed: %s/atk_%02d.png"},
			{"name": "dash_start", "prefix": "atk", "indices": [1], "fps": 1.0, "loop": true, "required": true, "defer_configuration": true, "failure_message": "Stage 6 dash frame load failed: %s/atk_%02d.png"},
			{"name": "dash_finish", "prefix": "atk", "indices": [2], "fps": 1.0, "loop": true, "required": true, "defer_configuration": true, "failure_message": "Stage 6 dash frame load failed: %s/atk_%02d.png"},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 13.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 8.0, "loop": false, "required": false},
		],
	},
	"archmage_elementalist": {
		"frame_dir": STAGE5_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 7, "fps": 10.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "count": 7, "fps": 17.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 14.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 10.0, "loop": false, "required": false},
		],
	},
	"ranged_rookie": {
		"frame_dir": STAGE1_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 5.5, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 7, "fps": 10.0, "loop": true, "required": true},
			{"name": "attack", "prefix": "atk", "count": 7, "fps": 18.0, "loop": false, "required": true},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 14.0, "loop": false, "required": true},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 10.0, "loop": false, "required": true},
		],
	},
	"pistol_gunner": {
		"frame_dir": STAGE4_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 9, "fps": 8.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 9, "fps": 12.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "atk", "count": 9, "fps": 20.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 15.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 6, "fps": 10.0, "loop": false, "required": false},
		],
	},
	"sword_shield": {
		"frame_dir": STAGE3_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "hero_idle", "count": 6, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "hero_move", "count": 6, "fps": 9.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "hero_attack", "count": 6, "fps": 13.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hero_hit", "count": 6, "fps": 12.0, "loop": false, "required": false},
		],
	},
	"rogue_combo": {
		"frame_dir": STAGE2_FRAME_DIR,
		"animations": [
			{"name": "idle", "prefix": "idle", "count": 4, "fps": 6.0, "loop": true, "required": true},
			{"name": "move", "prefix": "walk", "count": 6, "fps": 11.0, "loop": true, "required": false},
			{"name": "attack", "prefix": "attack", "count": 6, "fps": 18.0, "loop": false, "required": false},
			{"name": "hit", "prefix": "hit", "count": 3, "fps": 14.0, "loop": false, "required": false},
			{"name": "death", "prefix": "dead", "count": 4, "fps": 10.0, "loop": false, "required": false},
		],
	},
}

static func get_visual_profile(hero_id: String, archetype: String) -> Dictionary:
	# Preserve legacy precedence even when a caller supplies conflicting identities.
	if EARLY_ARCHETYPES.has(archetype):
		return VISUAL_PROFILES[archetype]
	if HERO_ID_PROFILES.has(hero_id):
		return VISUAL_PROFILES[HERO_ID_PROFILES[hero_id]]
	if LATE_ARCHETYPES.has(archetype):
		return VISUAL_PROFILES[archetype]
	return EMPTY_PROFILE

const DEFAULT_ABILITY_LINES := [
	{"text": "원거리 투사체 속도  %.0f", "snapshot_key": "hero_projectile_speed", "multiplier": 1.0, "default": 0.0},
	{"text": "거리 유지형 전투 AI"},
]
const ABILITY_LINES := {
	"rogue_combo": [
		{"text": "3단 찌르기 · 약진/넉백 연계"},
		{"text": "난도질 쉴드  최대 HP %.0f%%", "snapshot_key": "hero_slash_shield_ratio", "multiplier": 100.0, "default": 0.0},
		{"text": "피흡  실제 피해의 %.0f%%", "snapshot_key": "hero_lifesteal_ratio", "multiplier": 100.0, "default": 0.0},
		{"text": "급습-암살 처형선  일반 몬스터 HP %.0f%%", "snapshot_key": "hero_execute_ratio", "multiplier": 100.0, "default": 0.0},
	],
}

static func format_ability_lines(archetype: String, snapshot: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for rule in ABILITY_LINES.get(archetype, DEFAULT_ABILITY_LINES):
		var text: String = rule["text"]
		if rule.has("snapshot_key"):
			text = text % (float(snapshot.get(rule["snapshot_key"], rule["default"])) * float(rule["multiplier"]))
		lines.append(text)
	return lines
