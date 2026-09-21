extends RefCounted
class_name MonsterCatalog

const ORDER := ["slime", "spider", "orc"]

const MONSTERS := {
	"slime": {
		"id": "slime",
		"name": "슬라임",
		"role": "swarm",
		"base_cost": 3.0,
		"default_unlocked": true,
		"shards_required": 20,
		"shop_shard_amount": 10,
		"shop_shard_cost": 15,
		"card_icon_path": "res://assets/art/monsters/slime/frames/idle_01.png",
		"scene": preload("res://src/monsters/Slime.tscn"),
	},
	"spider": {
		"id": "spider",
		"name": "거미",
		"role": "controller",
		"base_cost": 7.0,
		"default_unlocked": true,
		"shards_required": 30,
		"shop_shard_amount": 10,
		"shop_shard_cost": 20,
		"card_icon_path": "res://assets/art/monsters/spider/frames/idle_01.png",
		"scene": preload("res://src/monsters/Spider.tscn"),
	},
	"orc": {
		"id": "orc",
		"name": "오크",
		"role": "tank",
		"base_cost": 18.0,
		"default_unlocked": true,
		"shards_required": 40,
		"shop_shard_amount": 10,
		"shop_shard_cost": 25,
		"card_icon_path": "res://assets/art/monsters/orc/frames/idle_01.png",
		"scene": preload("res://src/monsters/Orc.tscn"),
	},
}

const ROLE_LABELS := {
	"swarm": "물량",
	"controller": "제어",
	"tank": "탱커",
}

static func get_monster(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return data.duplicate(true)

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
