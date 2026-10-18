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

# Body scale is computed from opaque pixels. The remade rookie uses its fixed
# reference height even when the legacy sheet can still be read.
const HERO_REFERENCE_SHEET_PATH := "res://assets/art/heroes/stage1_mage/stage1_mage_spritesheet.png"
const HERO_REFERENCE_FRAME_SIZE := Vector2i(64, 64)
const HERO_REFERENCE_RENDER_SCALE := 3.0
const STAGE1_TARGET_VISIBLE_HEIGHT := 108.0
const FIXED_HEIGHT_HERO_IDS := {"ranged_rookie": true}

static func resolve_target_height(hero_id: String, reference_height: float) -> float:
	if FIXED_HEIGHT_HERO_IDS.has(hero_id) or reference_height <= 0.0:
		return STAGE1_TARGET_VISIBLE_HEIGHT
	return reference_height

const RELEASE_EFFECT_COMPLETION := {
	"sword_shield": {"properties": {"visible": false, "position": Vector2.ZERO}},
	"pistol_gunner": {
		"animation": &"cylinder_dust",
		"properties": {"visible": false, "position": Vector2.ZERO, "modulate": Color.WHITE},
	},
}

static func get_release_effect_completion(archetype: String) -> Dictionary:
	return RELEASE_EFFECT_COMPLETION.get(archetype, EMPTY_PROFILE)

# Separate events preserve the old no-op when the wrong setup method is called.
const CHANNEL_EFFECT_PROFILES := {
	"berserker_madness": {
		"persistent": {
			"before_build": {"visible": false, "sprite_frames": null, "texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST},
			"animation": &"madness", "fps": 1.0, "loop": true,
			"frame_groups": [
				{"path_pattern": STAGE6_FRAME_DIR + "/effect7/special_%02d.png", "first": 8, "last": 8, "required": true},
			],
			"properties": {
				"animation": &"madness", "position": Vector2(0.0, -126.0),
				"scale": Vector2(0.48, 0.48), "z_index": 9, "modulate": Color.WHITE,
			},
		},
	},
	"alchemist_chemical": {
		"channelled": {
			"animation": &"philosopher_stone", "fps": 8.0, "loop": false,
			"config_property": &"alchemist_philosopher_config", "fps_key": &"channel_fps", "minimum_fps": 1.0,
			"frame_groups": [
				{"path_pattern": STAGE7_FRAME_DIR + "/effect7/brew_%02d.png", "first": 1, "last": 8, "required": false},
				{"path_pattern": STAGE7_FRAME_DIR + "/effect7/cast_%02d.png", "first": 1, "last": 4, "required": false},
			],
			"stop_before_assign": true,
			"properties": {
				"animation": &"philosopher_stone", "visible": false, "texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST,
				# effect7 manifest anchor (192,336) in a 512x384 frame.
				"offset": Vector2(64.0, -144.0), "position": Vector2.ZERO,
				"scale": Vector2(0.50, 0.50), "z_index": 10, "modulate": Color.WHITE,
			},
		},
	},
}

static func get_channel_effect_profile(archetype: String, event: StringName) -> Dictionary:
	var rules: Dictionary = CHANNEL_EFFECT_PROFILES.get(archetype, EMPTY_PROFILE)
	return rules.get(event, EMPTY_PROFILE)

const STAGE2_EFFECT1_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_01"
const STAGE2_EFFECT2_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_02"
const STAGE2_EFFECT3_DIR := "res://assets/art/heroes/stage2_rogue/frames/effect_03"
const STAGE3_BLOCK_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect1"
const STAGE3_SLASH_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect2"
const STAGE3_THRUST_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect3"
const STAGE3_AURA_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect4"
const STAGE3_CHARGE_EFFECT_DIR := "res://assets/art/heroes/stage3_fighter/frames/effect5"

# Setup-only bindings. Batches retain the legacy load/assign boundaries; missing
# frames either abort one effect, stop one animation, or skip a frame.
const COMBAT_EFFECT_PROFILES := {
	"rogue_combo": {
		"rogue": {
			"before_build": {},
			"batches": [
				{
					"builds": [
						{
							"animations": [
								{
									"name": &"stab",
									"path_pattern": STAGE2_EFFECT1_DIR + "/frame_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 20.0,
									"loop": false,
									"missing": &"abort_effect",
									"warning": "Stage 2 rogue effect frame load failed: %s",
									"loop_first": false
								}
							]
						},
						{
							"animations": [
								{
									"name": &"assassinate",
									"path_pattern": STAGE2_EFFECT2_DIR + "/frame_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 22.0,
									"loop": false,
									"missing": &"abort_effect",
									"warning": "Stage 2 rogue effect frame load failed: %s",
									"loop_first": false
								}
							]
						},
						{
							"animations": [
								{
									"name": &"slash",
									"path_pattern": STAGE2_EFFECT3_DIR + "/frame_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 18.0,
									"loop": false,
									"missing": &"abort_effect",
									"warning": "Stage 2 rogue effect frame load failed: %s",
									"loop_first": false
								}
							]
						}
					],
					"bindings": [
						{
							"slot": 0,
							"target": &"rogue_attack_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.65, 0.65) }
						},
						{
							"slot": 1,
							"target": &"channel_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.72, 0.72), "position": Vector2.ZERO }
						},
						{
							"slot": 2,
							"target": &"shield_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.52, 0.52), "position": Vector2.ZERO, "z_index": 3 }
						}
					]
				}
			],
		}
	},
	"sword_shield": {
		"fighter": {
			"before_build": {
				"rogue_attack_effect": { "visible": false },
				"channel_effect": { "visible": false },
				"shield_effect": { "visible": false },
			},
			"batches": [
				{
					"builds": [
						{
							"animations": [
								{
									"name": &"slash",
									"path_pattern": STAGE3_SLASH_EFFECT_DIR + "/hero_effect_slash_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 18.0,
									"loop": false,
									"missing": &"stop_animation",
									"warning": "Stage 3 fighter effect frame load failed: %s",
									"loop_first": false
								},
								{
									"name": &"thrust",
									"path_pattern": STAGE3_THRUST_EFFECT_DIR + "/hero_effect_thrust_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 18.0,
									"loop": false,
									"missing": &"stop_animation",
									"warning": "Stage 3 fighter effect frame load failed: %s",
									"loop_first": false
								}
							]
						}
					],
					"bindings": [
						{
							"slot": 0,
							"target": &"rogue_attack_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.74, 0.74), "position": Vector2.ZERO, "z_index": 2 }
						}
					]
				},
				{
					"builds": [
						{
							"animations": [
								{
									"name": &"guard_release",
									"path_pattern": STAGE3_BLOCK_EFFECT_DIR + "/hero_effect_block_%02d.png",
									"first": 1,
									"last": 6,
									"fps": 15.0,
									"loop": false,
									"missing": &"stop_animation",
									"warning": "Stage 3 fighter effect frame load failed: %s",
									"loop_first": false
								},
								{
									"name": &"charge_impact",
									"path_pattern": STAGE3_CHARGE_EFFECT_DIR + "/ground_effect_%02d.png",
									"first": 1,
									"last": 8,
									"fps": 20.0,
									"loop": false,
									"missing": &"stop_animation",
									"warning": "Stage 3 fighter effect frame load failed: %s",
									"loop_first": false
								}
							]
						}
					],
					"bindings": [
						{
							"slot": 0,
							"target": &"channel_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.76, 0.76), "position": Vector2.ZERO, "z_index": 3 }
						}
					]
				},
				{
					"builds": [
						{
							"animations": [
								{
									"name": &"guard_aura",
									"path_pattern": STAGE3_AURA_EFFECT_DIR + "/aura_%02d.png",
									"first": 1,
									"last": 8,
									"fps": 10.0,
									"loop": true,
									"missing": &"stop_animation",
									"warning": "Stage 3 fighter effect frame load failed: %s",
									"loop_first": false
								}
							]
						}
					],
					"bindings": [
						{
							"slot": 0,
							"target": &"shield_effect",
							"require_nonempty": false,
							"before_assign": {},
							"properties": { "scale": Vector2(0.60, 0.60), "position": Vector2.ZERO, "z_index": 3 }
						}
					]
				}
			],
		}
	},
	"pistol_gunner": {
		"gunner": {
			"before_build": {
				"rogue_attack_effect": {
					"visible": false,
					"sprite_frames": null,
					"texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST
				},
			},
			"batches": [
				{
					"builds": [
						{
							"animations": [
								{
									"name": &"deadeye_flame",
									"path_pattern": STAGE4_FRAME_DIR + "/effect/effect_projectile_%02d.png",
									"first": 5,
									"last": 6,
									"fps": 28.0,
									"loop": true,
									"missing": &"skip",
									"warning": "Stage 4 deadeye flame frame load failed: %s",
									"loop_first": true
								},
								{
									"name": &"deadeye_smoke",
									"path_pattern": STAGE4_FRAME_DIR + "/effect/effect_projectile_%02d.png",
									"first": 7,
									"last": 12,
									"fps": 20.0,
									"loop": false,
									"missing": &"skip",
									"warning": "Stage 4 deadeye smoke frame load failed: %s",
									"loop_first": true
								}
							]
						},
						{
							"animations": [
								{
									"name": &"cylinder_dust",
									"path_pattern": STAGE3_CHARGE_EFFECT_DIR + "/ground_effect_%02d.png",
									"first": 1,
									"last": 8,
									"fps": 20.0,
									"loop": false,
									"missing": &"skip",
									"warning": "Cylinder dust frame load failed: %s",
									"loop_first": true
								}
							]
						}
					],
					"bindings": [
						{
							"slot": 0,
							"target": &"rogue_attack_effect",
							"require_nonempty": true,
							"before_assign": {},
							"properties": { "scale": Vector2(0.30, 0.30), "z_index": 4 }
						},
						{
							"slot": 1,
							"target": &"channel_effect",
							"require_nonempty": true,
							"before_assign": { "visible": false },
							"properties": {
								"texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST,
								"scale": Vector2(0.92, 0.92),
								"position": Vector2.ZERO,
								"z_index": 2,
								"modulate": Color(0.76, 0.68, 0.55, 0.88)
							}
						}
					]
				}
			],
		}
	},
}

static func get_combat_effect_profile(archetype: String, event: StringName) -> Dictionary:
	var rules: Dictionary = COMBAT_EFFECT_PROFILES.get(archetype, EMPTY_PROFILE)
	return rules.get(event, EMPTY_PROFILE)


# Fixed canvas scale for shield; maximum loaded texture extent for channel.
const STAGE1_SHIELD_EFFECT_BASE_PATH := "res://assets/art/heroes/stage1_mage/frames/effect_02"
const STAGE1_SHIELD_EFFECT_FRAME_COUNT := 6
const STAGE1_SHIELD_EFFECT_FRAME_SIZE := Vector2(512, 512)
const STAGE1_SHIELD_EFFECT_TARGET_SIZE := 180.0
const STAGE1_CHANNEL_EFFECT_BASE_PATH := "res://assets/art/heroes/stage1_mage/frames/effect_03"
const STAGE1_CHANNEL_EFFECT_FRAME_COUNT := 6
const STAGE1_CHANNEL_EFFECT_TARGET_SIZE := 300.0

const SCALED_EFFECT_PROFILES := {
	&"rookie_shield": {
		"target": &"shield_effect",
		"hero_ids": {"ranged_rookie": true},
		"reset_before_filter": true,
		"reset_properties": {"visible": false, "sprite_frames": null, "texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST},
		"animation": &"shield", "fps": 10.0, "loop": true,
		"path_pattern": STAGE1_SHIELD_EFFECT_BASE_PATH + "/frame_%02d.png",
		"first": 1, "last": STAGE1_SHIELD_EFFECT_FRAME_COUNT,
		"missing_warning": "Stage 1 shield effect frame load failed: %s",
		"measure_source_extent": false,
		"source_extent": STAGE1_SHIELD_EFFECT_FRAME_SIZE.x,
		"target_extent": STAGE1_SHIELD_EFFECT_TARGET_SIZE,
	},
	&"rookie_channel": {
		"target": &"channel_effect",
		"hero_ids": {"ranged_rookie": true},
		"reset_before_filter": false,
		"reset_properties": {"visible": false, "sprite_frames": null, "texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST},
		"animation": &"channel", "fps": 10.0, "loop": true,
		"path_pattern": STAGE1_CHANNEL_EFFECT_BASE_PATH + "/frame_%02d.png",
		"first": 1, "last": STAGE1_CHANNEL_EFFECT_FRAME_COUNT,
		"missing_warning": "Stage 1 channel effect frame load failed: %s",
		"measure_source_extent": true,
		"source_extent": 0.0,
		"target_extent": STAGE1_CHANNEL_EFFECT_TARGET_SIZE,
		"invalid_extent_warning": "Stage 1 channel effect: invalid source frame size.",
	},
}

static func get_scaled_effect_profile(event: StringName) -> Dictionary:
	return SCALED_EFFECT_PROFILES.get(event, EMPTY_PROFILE)


const ANIMATION_PRIORITIES := {
	&"death": 100, &"hit": 80, &"dash_start": 70, &"dash_finish": 70,
	&"attack": 60, &"run": 20, &"move": 20, &"idle": 10,
}
const DEFAULT_ANIMATION_PRIORITY := 40
const FRAME_CHANGE_METHODS := {"cleric_purifier": [&"_apply_stage9_sprite_anchor"]}

static func animation_priority(animation: StringName) -> int:
	return int(ANIMATION_PRIORITIES.get(animation, DEFAULT_ANIMATION_PRIORITY))

static func get_frame_change_methods(archetype: String) -> Array:
	return FRAME_CHANGE_METHODS.get(archetype, EMPTY_METHODS)

# x offset, resource Y, HP Y, shield Y. Player identity overrides the three Y
# coordinates at draw time; no cached layout can become stale on a mode change.
const DEFAULT_STATUS_LAYOUT := Vector4(0.0, -79.0, -64.0, -49.0)
const STATUS_LAYOUTS := {
	"summoner_gatekeeper": Vector4(0.0, -128.0, -113.0, -98.0),
	"cleric_purifier": Vector4(0.0, -100.0, -85.0, -70.0),
	"grand_sage_astra": Vector4(0.0, -79.0, -64.0, -94.0),
}
const STATUS_BAR_WIDTH := 92.0
const STATUS_CELL_GAP := 2.0
const STATUS_RESOURCE_HEIGHT := 8.0
const STATUS_HP_HEIGHT := 10.0
const STATUS_SHIELD_HEIGHT := 8.0
const STATUS_CONTROL_GAUGE_OFFSET := 24.0
const STATUS_BACKGROUND_COLOR := Color(0.12, 0.12, 0.14)
const STATUS_HP_COLOR := Color(0.95, 0.38, 0.32)
const STATUS_SHIELD_BACKGROUND_COLOR := Color(0.10, 0.12, 0.18)
const STATUS_SHIELD_COLOR := Color(0.20, 0.65, 1.0)
const DEFAULT_STATUS_RESOURCE := {
	"kind": &"ratio", "value_property": &"ultimate_charge",
	"config_property": &"ultimate_config", "max_key": &"charge_max",
	"default_max": 100.0, "minimum_max": 1.0,
	"use_x_offset": false, "color": Color(1.0, 0.77, 0.16),
}
const STATUS_RESOURCES := {
	"pistol_gunner": {
		"kind": &"cells", "capacity_property": &"gunner_magazine_size",
		"count_property": &"gunner_ammo", "reload_property": &"gunner_reloading",
		"timer_property": &"gunner_reload_timer", "config_property": &"gunner_config",
		"duration_key": &"reload_seconds", "default_duration": 2.4, "minimum_duration": 0.1,
		"color": Color(1.0, 0.77, 0.16),
	},
	"summoner_gatekeeper": {
		"kind": &"cells", "capacity_method": &"_get_summoner_slot_capacity",
		"count_method": &"_get_active_summon_count", "color": Color(0.55, 0.40, 0.95),
	},
	"alchemist_chemical": {
		"kind": &"ratio", "value_property": &"alchemist_gas",
		"max_property": &"alchemist_gas_max", "minimum_max": 1.0,
		"use_x_offset": false, "color": Color(0.68, 0.28, 0.92),
	},
	"cleric_purifier": {
		"kind": &"ratio", "value_property": &"ultimate_charge",
		"config_property": &"purifier_gauge_config", "max_key": &"charge_max",
		"default_max": 100.0, "minimum_max": 1.0,
		"use_x_offset": true, "color": Color(1.0, 0.77, 0.16),
	},
	"berserker_madness": {
		"kind": &"ratio", "value_property": &"ultimate_charge",
		"config_property": &"berserker_config", "max_key": &"gauge_max",
		"default_max": 100.0, "minimum_max": 1.0,
		"use_x_offset": false, "color": Color(1.0, 0.30, 0.08),
	},
}

static func get_status_layout(archetype: String) -> Vector4:
	return STATUS_LAYOUTS.get(archetype, DEFAULT_STATUS_LAYOUT)

static func get_status_resource(archetype: String) -> Dictionary:
	return STATUS_RESOURCES.get(archetype, DEFAULT_STATUS_RESOURCE)


const EVENT_AUDIO := {
	"ranged_kiter": {
		&"death": {"method": &"_play_stage1_audio", "arguments": [&"death"]},
		&"level_up": {"method": &"_play_stage1_audio", "arguments": [&"level_up"]},
	},
	"rogue_combo": {&"death": {"method": &"_play_rogue_death_audio", "arguments": EMPTY_METHODS}},
	"sword_shield": {&"death": {"method": &"_play_fighter_death_audio", "arguments": EMPTY_METHODS}},
	"pistol_gunner": {&"death": {"method": &"_play_gunner_death_audio", "arguments": EMPTY_METHODS}},
	"archmage_elementalist": {&"death": {"method": &"_play_archmage_death_audio", "arguments": EMPTY_METHODS}},
	"berserker_madness": {&"death": {"method": &"_play_berserker_death_audio", "arguments": EMPTY_METHODS}},
}

static func get_event_audio(archetype: String, event: StringName) -> Dictionary:
	var events: Dictionary = EVENT_AUDIO.get(archetype, EMPTY_PROFILE)
	return events.get(event, EMPTY_PROFILE)
