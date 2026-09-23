extends StaticBody2D

signal destroyed(drop_position: Vector2)

const FRAME_COUNT := 8
const FRAME_SIZE := Vector2(444.0, 444.0)
const TARGET_HEIGHT := 88.0

static var _frames_cache: SpriteFrames

@export var max_hp: int = 100

@onready var visual: AnimatedSprite2D = $Visual

var current_hp: int = 100
var hit_flash_timer := 0.0
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
	hit_flash_timer = 0.12
	if is_instance_valid(visual):
		visual.modulate = Color(1.0, 0.92, 0.62)
	queue_redraw()
	if current_hp <= 0:
		destroyed_flag = true
		destroyed.emit(global_position)
		queue_free()
	return true


func _process(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	var previous_hit_flash := hit_flash_timer
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
		if is_instance_valid(visual):
			visual.modulate = Color.WHITE
		queue_redraw()


func _apply_visual() -> void:
	if not is_instance_valid(visual):
		return
	if _frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"idle")
		frames.set_animation_loop(&"idle", true)
		frames.set_animation_speed(&"idle", 9.0)
		for index in range(1, FRAME_COUNT + 1):
			var path := (
				"res://assets/art/heroes/item/box_frames/"
				+ "expbox_%02d.png" % index
			)
			var texture = load(path)
			if texture is Texture2D:
				frames.add_frame(&"idle", texture)
		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var uniform_scale := TARGET_HEIGHT / FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.modulate = Color.WHITE
	visual.play(&"idle")


func _draw() -> void:
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
