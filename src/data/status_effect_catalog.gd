extends RefCounted
class_name StatusEffectCatalog

const STATUS_EFFECTS := {
	"bleed": {"id": "bleed", "name": "출혈"},
	"slow": {
		"id": "slow",
		"name": "둔화",
	},
	"poison": {
		"id": "poison",
		"name": "독",
	},
	"fear": {
		"id": "fear",
		"name": "공포",
	},
}

static func get_status_name(status_id: String) -> String:
	var data: Dictionary = STATUS_EFFECTS.get(status_id, {})
	return String(data.get("name", status_id))

static func get_name(status_id: String) -> String:
	var data: Dictionary = STATUS_EFFECTS.get(status_id, {})
	return String(data.get("name", status_id))
