extends Button

signal formation_item_dropped(slot_index: int, formation_kind: String, item_id: String)

@export var slot_index := 0


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = data
	return (
		String(payload.get("formation_kind", "")) in ["monster", "skill"]
		and not String(payload.get("formation_id", "")).is_empty()
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = data
	formation_item_dropped.emit(
		slot_index,
		String(payload.get("formation_kind", "")),
		String(payload.get("formation_id", ""))
	)
