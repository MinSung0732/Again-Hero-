extends Node2D

const MATERIAL_TEXTURES := [
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect2/frame_01.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect2/frame_02.png"),
]

@onready var visual: AnimatedSprite2D = $Visual

var active: bool = false
var gas_value: float = 20.0

func _ready() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.0)
	frames.set_animation_loop("idle", true)
	for texture in MATERIAL_TEXTURES:
		frames.add_frame("idle", texture)
	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.48, 0.48)
	deactivate()

func activate(world_position: Vector2, value: float) -> void:
	global_position = world_position
	gas_value = maxf(value, 0.0)
	active = true
	visible = true
	visual.play("idle")

func deactivate() -> void:
	active = false
	visible = false
	if is_instance_valid(visual):
		visual.stop()
