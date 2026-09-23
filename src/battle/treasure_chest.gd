extends StaticBody2D

signal destroyed(drop_position: Vector2)

const FRAME_SIZE := Vector2(444.0, 444.0)
const TARGET_HEIGHT := 88.0

static var _frames_cache: SpriteFrames

@export var max_hp: int = 100

@onready var visual: AnimatedSprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_hp: int = 100
var destroyed_flag := false


func _ready() -> void:
	add_to_group("treasure_chests")
	current_hp = maxi(max_hp, 1)
	_apply_visual()
	queue_redraw()


func take_damage(amount: int) -> bool:
	if destroyed_flag or amount <= 0:
		return false

	current_hp = maxi(current_hp - amount, 0)
	queue_redraw()

	if current_hp <= 0:
		_start_death_animation()
		return true

	_play_hit_animation()
	return true


func _play_hit_animation() -> void:
	if not is_instance_valid(visual):
		return
	visual.modulate = Color.WHITE
	visual.stop()
	visual.animation = &"hit"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"hit")


func _start_death_animation() -> void:
	if destroyed_flag:
		return
	destroyed_flag = true

	if is_in_group("treasure_chests"):
		remove_from_group("treasure_chests")
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)

	if not is_instance_valid(visual):
		destroyed.emit(global_position)
		queue_free()
		return

	visual.modulate = Color.WHITE
	visual.stop()
	visual.animation = &"death"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"death")


func _on_visual_animation_finished() -> void:
	if not is_instance_valid(visual):
		return

	match String(visual.animation):
		"hit":
			if not destroyed_flag:
				visual.play(&"idle")
		"death":
			destroyed.emit(global_position)
			queue_free()


func _apply_visual() -> void:
	if not is_instance_valid(visual):
		return

	if _frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")

		frames.add_animation(&"idle")
		frames.set_animation_loop(&"idle", true)
		frames.set_animation_speed(&"idle", 8.0)

		frames.add_animation(&"hit")
		frames.set_animation_loop(&"hit", false)
		frames.set_animation_speed(&"hit", 14.0)

		frames.add_animation(&"death")
		frames.set_animation_loop(&"death", false)
		frames.set_animation_speed(&"death", 10.0)

		for index in range(1, 9):
			var path := (
				"res://assets/art/heroes/item/box_frames/"
				+ "expbox_%02d.png" % index
			)
			var texture = load(path)
			if not (texture is Texture2D):
				continue

			if index <= 4:
				frames.add_frame(&"idle", texture)
			elif index <= 6:
				frames.add_frame(&"hit", texture)
			else:
				frames.add_frame(&"death", texture)

		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var uniform_scale := TARGET_HEIGHT / FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.modulate = Color.WHITE

	if not visual.animation_finished.is_connected(
		Callable(self, "_on_visual_animation_finished")
	):
		visual.animation_finished.connect(
			Callable(self, "_on_visual_animation_finished")
		)

	visual.play(&"idle")


func _draw() -> void:
	if destroyed_flag:
		return
	var hp_ratio := clampf(
		float(current_hp) / float(maxi(max_hp, 1)),
		0.0,
		1.0
	)
	draw_rect(
		Rect2(-28, -38, 56, 5),
		Color(0.10, 0.08, 0.06, 0.90),
		true
	)
	draw_rect(
		Rect2(-27, -37, 54.0 * hp_ratio, 3),
		Color(0.94, 0.70, 0.20),
		true
	)
