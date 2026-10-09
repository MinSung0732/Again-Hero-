extends RefCounted
class_name StatusEffectCatalog

const STATUS_EFFECTS := {
	"burn":{"id":"burn","name":"화상"},
	"stun": {"id": "stun", "name": "기절"},
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

static func outgoing_multiplier(actor: Node) -> float:
	return 0.5 if is_instance_valid(actor) and bool(actor.get_meta("burn_active",false)) else 1.0

static func movement_multiplier(actor: Node) -> float:
	return float(actor.get_meta("received_slow_multiplier",1.0)) if is_instance_valid(actor) else 1.0
