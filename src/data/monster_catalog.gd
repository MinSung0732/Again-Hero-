extends RefCounted
class_name MonsterCatalog

const ORDER := [
	"slime",
	"spider",
	"orc",
	"bomb_rat",
	"skeleton",
	"skeleton_archer",
	"kobolt",
]

const MONSTERS := {
	"slime": {
		"id": "slime",
		"name": "슬라임",
		"role": "swarm",
		"species": "liquid",
		"grade": "normal",
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
		"shards_required": 20,
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
				"description": "사용 시 자신 주변으로 일반 슬라임을 0.25초 간격으로 총 12마리 무작위 방향에 포물선으로 투척합니다.",
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
		"name": "거미",
		"role": "controller",
		"species": "beast",
		"grade": "normal",
		"base_cost": 7.0,
		"summon_exp": 7.0,
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
		"shards_required": 30,
		"rarity": "rare",
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
				"description": "지름 500 거미집을 5초간 설치합니다. 범위 내 용사는 이동속도 50% 둔화, 몬스터는 이동속도 15% 증가합니다.",
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
		"name": "오크",
		"role": "tank",
		"species": "beast",
		"grade": "normal",
		"base_cost": 18.0,
		"summon_exp": 18.0,
		"base_stats": {
			"max_hp": 140,
			"move_speed": 78.0,
			"attack_damage": 18,
			"attack_range": 82.0,
			"attack_cooldown": 1.45,
		},
		"default_unlocked": true,
		"shards_required": 40,
		"rarity": "legendary",
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
				"description": "몸이 붉게 변하며 용사에게 빠르게 돌진해 기본 공격력의 150% 피해를 주고 1초간 이동속도를 99% 둔화시킵니다.",
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
		"name": "스켈레톤",
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
		"default_unlocked": true,
		"shards_required": 20,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelleton/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(72.0, 23.0),
			"offset_y": 34.0,
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
				"description": "2초간 반투명 은신 상태가 되어 받는 피해가 50% 감소합니다. 공격 시 은신이 해제되고 해당 공격의 2타 모두 50% 추가 피해를 줍니다.",
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
		"name": "스켈레톤 궁병",
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
		"default_unlocked": true,
		"shards_required": 20,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelletonarcher/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(64.0, 20.0),
			"offset_y": 29.0,
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
				"description": "선쿨 2초/재사용 17초. 시전 시 용사 위치 중심 지름 275 범위를 얇은 선으로 표시하고, 0.35초 간격으로 12발의 화살비를 총 3회 내립니다. 각 회차는 공격력의 130% 피해를 1회 주고 1초간 25% 둔화시킵니다.",
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
			"attack_cooldown": 1.55,
			"projectile_speed": 385.0,
			"projectile_range": 750.0,
		},
		"default_unlocked": true,
		"shards_required": 30,
		"rarity": "rare",
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
				"description": "선쿨 2초/재사용 10초. 5초간 옅은 붉은색으로 변하며 공격속도가 60% 증가합니다.",
				"initial_cooldown": 2.0,
				"cooldown": 10.0,
				"duration": 5.0,
				"attack_speed_multiplier": 1.60,
				"tint": Color(1.0, 0.68, 0.68, 1.0),
			},
		],
		"scene": preload("res://src/monsters/Kobolt.tscn"),
	},
	"bomb_rat": {
		"id": "bomb_rat",
		"name": "폭탄쥐",
		"role": "burst",
		"species": "beast",
		"grade": "normal",
		"base_cost": 12.0,
		"summon_exp": 12.0,
		"base_stats": {
			"max_hp": 36,
			"move_speed": 175.0,
			"self_destruct_range": 78.0,
			"self_destruct_fuse": 0.30,
			"explosion_radius": 150.0,
			"explosion_damage": 28,
		},
		"default_unlocked": false,
		"shards_required": 30,
		"rarity": "rare",
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
				"description": "4초간 이동속도가 200% 증가하고 자신의 최대 체력 150%만큼 쉴드를 획득합니다.",
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
	"swarm": "물량",
	"controller": "제어",
	"tank": "탱커",
	"ranged": "원거리",
	"burst": "폭발",
}

const SPECIES_LABELS := {
	"beast": "짐승",
	"liquid": "액체",
	"undead": "언데드",
}

const ATTACK_TYPE_LABELS := {
	"melee": "근접",
	"ranged": "원거리",
}

const GRADE_LABELS := {
	"normal": "일반",
}

static func get_monster(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return data.duplicate(true)

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

static func get_grade(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("grade", "normal"))

static func get_attack_type(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("attack_type", ""))

static func get_base_cost(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return float(data.get("base_cost", 0.0))

static func get_summon_exp(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return maxf(float(data.get("summon_exp", 0.0)), 0.0)

static func get_base_stats(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var stats = data.get("base_stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return {}
	return Dictionary(stats).duplicate(true)

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
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return maxi(int(data.get("shards_required", 1)), 1)
