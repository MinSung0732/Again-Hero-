extends RefCounted
class_name DamageNumberSpawner

const DAMAGE_NUMBER_SCENE := preload("res://src/ui/DamageNumber.tscn")
const WORLD_OFFSET := Vector2(0.0, -56.0)
const MAX_ACTIVE_POPUPS := 48

static var active_popup_count: int = 0

static func show(target: Node2D, amount: int, text_color: Color = Color.WHITE) -> void:
	if target == null or not is_instance_valid(target):
		return

	var displayed_damage := maxi(amount, 0)
	if displayed_damage <= 0:
		return

	if target.has_meta("damage_number_color_once"):
		text_color = target.get_meta("damage_number_color_once", text_color)
		target.remove_meta("damage_number_color_once")

	if target.has_meta("damage_number_popup"):
		var existing = target.get_meta("damage_number_popup")
		if is_instance_valid(existing) and existing.has_method("can_merge_damage"):
			if bool(existing.call("can_merge_damage")):
				existing.call("add_damage", displayed_damage, text_color)
				return
		else:
			target.remove_meta("damage_number_popup")

	if active_popup_count >= MAX_ACTIVE_POPUPS:
		return

	var parent := target.get_parent()
	if parent == null:
		return

	var popup := DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	parent.add_child(popup)
	active_popup_count += 1
	popup.tree_exited.connect(_on_popup_tree_exited, Object.CONNECT_ONE_SHOT)
	popup.global_position = target.global_position + WORLD_OFFSET
	popup.call("setup", displayed_damage, text_color)
	target.set_meta("damage_number_popup", popup)


static func show_text_at(
	parent: Node2D,
	world_position: Vector2,
	message: String
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if message.is_empty():
		return
	if active_popup_count >= MAX_ACTIVE_POPUPS:
		return

	var popup := DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	parent.add_child(popup)
	active_popup_count += 1
	popup.tree_exited.connect(_on_popup_tree_exited, Object.CONNECT_ONE_SHOT)
	popup.global_position = world_position
	popup.call("setup_text", message)


static func _on_popup_tree_exited() -> void:
	active_popup_count = maxi(active_popup_count - 1, 0)
