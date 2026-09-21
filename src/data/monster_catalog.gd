extends RefCounted
class_name MonsterCatalog

const ORDER := ["slime", "spider", "orc", "bomb_rat"]

const MONSTERS := {
	"slime": {
		"id": "slime",
		"name": "슬라임",
		"role": "swarm",
		"base_cost": 3.0,
		"default_unlocked": true,
		"shards_required": 20,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/slime/frames/idle_01.png",
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
		"scene": preload("res://src/monsters/Slime.tscn"),
	},
	"spider": {
		"id": "spider",
		"name": "거미",
		"role": "controller",
		"base_cost": 7.0,
		"default_unlocked": true,
		"shards_required": 30,
		"rarity": "rare",
		"card_icon_path": "res://assets/art/monsters/spider/frames/idle_01.png",
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
		"scene": preload("res://src/monsters/Spider.tscn"),
	},
	"orc": {
		"id": "orc",
		"name": "오크",
		"role": "tank",
		"base_cost": 18.0,
		"default_unlocked": true,
		"shards_required": 40,
		"rarity": "legendary",
		"card_icon_path": "res://assets/art/monsters/orc/frames/idle_01.png",
		"elite_visual": {
			"mode": "sheet",
			"sheet_path": "res://assets/art/elitemonster/orc/eliteorc_spritesheet.png",
			"columns": 6,
			"rows": 5,
			"target_height": 104.0,
			"animations": {
				"idle": {"row": 0, "count": 4, "fps": 6.0, "loop": true},
				"move": {"row": 1, "count": 6, "fps": 10.0, "loop": true},
				"attack": {"row": 2, "count": 6, "fps": 14.0, "loop": false},
				"hit": {"row": 3, "count": 4, "fps": 14.0, "loop": false},
				"death": {"row": 4, "count": 6, "fps": 10.0, "loop": false},
			},
		},
		"scene": preload("res://src/monsters/Orc.tscn"),
	},
	"bomb_rat": {
		"id": "bomb_rat",
		"name": "폭탄쥐",
		"role": "burst",
		"base_cost": 12.0,
		"default_unlocked": false,
		"shards_required": 30,
		"rarity": "rare",
		"card_icon_path": "res://assets/art/monsters/bombrat/bombrat_spritesheet.png",
		"card_icon_region": Rect2(0, 0, 229, 229),
		"elite_visual": {
			"mode": "sheet",
			"sheet_path": "res://assets/art/elitemonster/bombrat/elitebombrat_spritesheet.png",
			"columns": 6,
			"rows": 5,
			"target_height": 78.0,
		},
		"scene": preload("res://src/monsters/BombRat.tscn"),
	},
}

const ROLE_LABELS := {
	"swarm": "물량",
	"controller": "제어",
	"tank": "탱커",
	"burst": "폭발",
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

static func get_scene(monster_id: String) -> PackedScene:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var scene = data.get("scene")
	return scene as PackedScene

static func get_name(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("name", monster_id))

static func get_role(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("role", "unknown"))

static func get_base_cost(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return float(data.get("base_cost", 0.0))

static func get_role_label(role_id: String) -> String:
	return String(ROLE_LABELS.get(role_id, role_id))

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
