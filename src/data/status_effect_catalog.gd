extends RefCounted
class_name StatusEffectCatalog

const STATUS_EFFECTS := {
	"slow": {
		"id": "slow",
		"name": "둔화",
	},
}

static func get_status(status_id: String) -> Dictionary:
	var data: Dictionary = STATUS_EFFECTS.get(status_id, {})
	return data.duplicate(true)

static func get_name(status_id: String) -> String:
	var data: Dictionary = STATUS_EFFECTS.get(status_id, {})
	return String(data.get("name", status_id))
