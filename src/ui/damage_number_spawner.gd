extends RefCounted
class_name DamageNumberSpawner

const DAMAGE_NUMBER_SCENE := preload("res://src/ui/DamageNumber.tscn")
const WORLD_OFFSET := Vector2(0.0, -56.0)

static func show(target: Node2D, amount: int, text_color: Color = Color.WHITE) -> void:
	if target == null or not is_instance_valid(target):
		return

	var displayed_damage := maxi(amount, 0)
	if displayed_damage <= 0:
		return

	var parent := target.get_parent()
	if parent == null:
		return

	var popup := DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	parent.add_child(popup)
	popup.global_position = target.global_position + WORLD_OFFSET
	popup.call("setup", displayed_damage, text_color)

static func show_text_at(
	parent: Node2D,
	world_position: Vector2,
	message: String
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if message.is_empty():
		return

	var popup := DAMAGE_NUMBER_SCENE.instantiate() as Node2D
	parent.add_child(popup)
	popup.global_position = world_position
	popup.call("setup_text", message)
