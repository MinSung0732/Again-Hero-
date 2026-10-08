extends ScrollContainer

signal monster_dropped(id: String)
var accepts_monster: Callable

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("formation_kind", "") == "transcendence" and accepts_monster.is_valid() and accepts_monster.call(String(data.get("formation_id", "")))

func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_position, data):
		monster_dropped.emit(String(data.formation_id))
