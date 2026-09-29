extends RefCounted
class_name DamageNumberSpawner

const DAMAGE_NUMBER_SCENE := preload("res://src/ui/DamageNumber.tscn")
const WORLD_OFFSET := Vector2(0.0, -56.0)
const MAX_ACTIVE_POPUPS := 48
const POOL_META: StringName = &"_damage_number_pool"


static func show(
	target: Node2D,
	amount: int,
	text_color: Color = Color.WHITE
) -> void:
	if target == null or not is_instance_valid(target):
		return

	var displayed_damage := maxi(amount, 0)
	if displayed_damage <= 0:
		return

	if target.has_meta("damage_number_color_once"):
		text_color = target.get_meta(
			"damage_number_color_once",
			text_color
		)
		target.remove_meta("damage_number_color_once")

	if target.has_meta("damage_number_popup"):
		var existing = target.get_meta("damage_number_popup")
		if (
			is_instance_valid(existing)
			and existing.has_method("can_merge_damage")
			and bool(existing.call("can_merge_damage"))
		):
			existing.call(
				"add_damage",
				displayed_damage,
				text_color
			)
			return

	var parent := target.get_parent() as Node2D
	if parent == null:
		return

	var popup := _acquire_popup(parent)
	if popup == null:
		return

	popup.global_position = target.global_position + WORLD_OFFSET
	popup.call("setup", displayed_damage, text_color)
	target.set_meta("damage_number_popup", popup)


static func show_heal(target: Node2D, amount: int) -> void:
	if target == null or not is_instance_valid(target):
		return

	var displayed_heal := maxi(amount, 0)
	if displayed_heal <= 0:
		return

	if target.has_meta("heal_number_popup"):
		var existing = target.get_meta("heal_number_popup")
		if (
			is_instance_valid(existing)
			and existing.has_method("can_merge_heal")
			and bool(existing.call("can_merge_heal"))
		):
			existing.call(
				"add_heal",
				displayed_heal,
				Color(0.32, 1.0, 0.42, 1.0)
			)
			return

	var parent := target.get_parent() as Node2D
	if parent == null:
		return

	var popup := _acquire_popup(parent)
	if popup == null:
		return

	popup.global_position = (
		target.global_position
		+ WORLD_OFFSET
		+ Vector2(0.0, -10.0)
	)
	popup.call(
		"setup_heal",
		displayed_heal,
		Color(0.32, 1.0, 0.42, 1.0)
	)
	target.set_meta("heal_number_popup", popup)


static func show_text_at(
	parent: Node2D,
	world_position: Vector2,
	message: String
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if message.is_empty():
		return

	var popup := _acquire_popup(parent)
	if popup == null:
		return

	popup.global_position = world_position
	popup.call("setup_text", message)


static func _acquire_popup(parent: Node2D) -> Node2D:
	var pool := _get_compacted_pool(parent)
	var active_count := 0

	for entry in pool:
		var popup := entry as Node2D
		if popup == null or not is_instance_valid(popup):
			continue

		var is_active := (
			popup.has_method("is_pool_active")
			and bool(popup.call("is_pool_active"))
		)
		if is_active:
			active_count += 1
			continue

		return popup

	if active_count >= MAX_ACTIVE_POPUPS:
		return null

	var popup := DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	if popup == null:
		return null

	parent.add_child(popup)
	pool.append(popup)
	parent.set_meta(POOL_META, pool)
	return popup


static func _get_compacted_pool(parent: Node2D) -> Array:
	var raw_pool = parent.get_meta(POOL_META, [])
	var pool: Array = []
	if raw_pool is Array:
		for entry in raw_pool:
			if is_instance_valid(entry):
				pool.append(entry)

	parent.set_meta(POOL_META, pool)
	return pool
