extends RefCounted
class_name DamageNumberSpawner

const DAMAGE_NUMBER_SCENE := preload("res://src/ui/DamageNumber.tscn")
const DAMAGE_NUMBER_LOGIC := preload("res://src/ui/damage_number.gd")
const WORLD_OFFSET := Vector2(0.0, -56.0)
const MAX_ACTIVE_POPUPS := 48
const OWNER_META: StringName = &"_damage_number_owner_id"
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
	var critical := bool(target.get_meta("damage_number_critical_once", false))
	if critical: target.remove_meta("damage_number_critical_once")

	var feedback_parent := target.get_parent()
	if feedback_parent != null and feedback_parent.has_signal("online_combat_feedback") and feedback_parent.get("online_match_mode") == true:
		feedback_parent.emit_signal("online_combat_feedback",target,displayed_damage,text_color,false,critical)

	if target.has_meta("damage_number_popup"):
		var existing = target.get_meta("damage_number_popup")
		if (
			is_instance_valid(existing)
			and not existing.is_queued_for_deletion()
			and int(existing.get_meta(OWNER_META, 0)) == target.get_instance_id()
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
	popup.set_meta(OWNER_META, target.get_instance_id())
	target.set_meta("damage_number_popup", popup)


static func show_heal(target: Node2D, amount: int) -> void:
	if target == null or not is_instance_valid(target):
		return

	var displayed_heal := maxi(amount, 0)
	if displayed_heal <= 0:
		return

	var feedback_parent := target.get_parent()
	if feedback_parent != null and feedback_parent.has_signal("online_combat_feedback") and feedback_parent.get("online_match_mode") == true:
		feedback_parent.emit_signal("online_combat_feedback",target,displayed_heal,Color(0.32,1.0,0.42,1.0),true,false)

	if target.has_meta("heal_number_popup"):
		var existing = target.get_meta("heal_number_popup")
		if (
			is_instance_valid(existing)
			and not existing.is_queued_for_deletion()
			and int(existing.get_meta(OWNER_META, 0)) == target.get_instance_id()
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
	popup.set_meta(OWNER_META, target.get_instance_id())
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
	popup.set_meta(OWNER_META, 0)
	popup.call("setup_text", message)


static func show_feedback(parent: Node2D, owner_id: int, world_position: Vector2, amount: int, text_color: Color, healing: bool) -> Node2D:
	if amount <= 0 or parent == null:
		return null
	var pool := _get_compacted_pool(parent)
	for entry in pool:
		var existing := entry as Node2D
		if existing == null or not bool(existing.call("is_pool_active")) or int(existing.get_meta(OWNER_META, -1)) != owner_id:
			continue
		if healing and bool(existing.call("can_merge_heal")):
			existing.call("add_heal",amount,text_color)
			return existing
		if not healing and bool(existing.call("can_merge_damage")):
			existing.call("add_damage",amount,text_color)
			return existing
	var popup := _acquire_popup(parent)
	if popup == null:
		return null
	popup.position = world_position + WORLD_OFFSET + (Vector2(0.0, -10.0) if healing else Vector2.ZERO)
	popup.set_meta(OWNER_META, owner_id)
	if healing: popup.call("setup_heal",amount,text_color)
	else: popup.call("setup",amount,text_color)
	return popup


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

		if popup.is_queued_for_deletion():
			active_count += 1
			continue
		return popup

	if active_count >= MAX_ACTIVE_POPUPS:
		return null

	# The authoritative SubViewport is never drawn. Keep identical pool state,
	# merge windows and random draws, but omit Label/font/layout work there.
	var popup: Node2D = DAMAGE_NUMBER_LOGIC.new() if parent.get("combat_popup_visuals_enabled") == false else DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	if popup == null:
		return null

	parent.add_child(popup)
	pool.append(popup)
	parent.set_meta(POOL_META, pool)
	return popup


static func _get_compacted_pool(parent: Node2D) -> Array:
	var raw_pool = parent.get_meta(POOL_META) if parent.has_meta(POOL_META) else null
	if not raw_pool is Array:
		var new_pool: Array = []
		parent.set_meta(POOL_META, new_pool)
		return new_pool
	# Healthy pools return directly: no copied array and no writes per hit.
	var pool: Array = raw_pool
	var first_invalid := -1
	for index in range(pool.size()):
		if not is_instance_valid(pool[index]):
			first_invalid = index
			break
	if first_invalid < 0:
		return pool
	# Rare stale entries: stable in-place compaction of only the suffix.
	var write_index := first_invalid
	for read_index in range(first_invalid + 1, pool.size()):
		var entry = pool[read_index]
		if is_instance_valid(entry):
			pool[write_index] = entry
			write_index += 1
	pool.resize(write_index)
	return pool
