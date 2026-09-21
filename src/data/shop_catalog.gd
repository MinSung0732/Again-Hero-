extends RefCounted
class_name ShopCatalog

const TEST_GOLD := 99999
const SINGLE_DRAW_COST := 100
const MULTI_DRAW_COST := 1000
const MULTI_DRAW_COUNT := 11

const RARITY_ORDER := ["common", "rare", "legendary"]

const RARITIES := {
	"common": {
		"label": "일반",
		"weight": 70.0,
		"shard_min": 10,
		"shard_max": 30,
	},
	"rare": {
		"label": "희귀",
		"weight": 25.0,
		"shard_min": 3,
		"shard_max": 8,
	},
	"legendary": {
		"label": "최고등급",
		"weight": 5.0,
		"shard_min": 1,
		"shard_max": 1,
	},
}

static func get_rarity(rarity_id: String) -> Dictionary:
	var data = RARITIES.get(rarity_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

static func get_rarity_label(rarity_id: String) -> String:
	var data := get_rarity(rarity_id)
	return String(data.get("label", rarity_id))
