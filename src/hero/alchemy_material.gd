extends Node2D

const MATERIAL_TEXTURES: Array[Array] = [
	[
		preload("res://assets/art/heroes/stage7_alchemist/frames/item1/idle_01.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item1/idle_02.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item1/idle_03.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item1/idle_04.png"),
	],
	[
		preload("res://assets/art/heroes/stage7_alchemist/frames/item2/idle_01.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item2/idle_02.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item2/idle_03.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item2/idle_04.png"),
	],
	[
		preload("res://assets/art/heroes/stage7_alchemist/frames/item3/idle_01.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item3/idle_02.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item3/idle_03.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item3/idle_04.png"),
	],
	[
		preload("res://assets/art/heroes/stage7_alchemist/frames/item4/idle_01.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item4/idle_02.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item4/idle_03.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item4/idle_04.png"),
	],
	[
		preload("res://assets/art/heroes/stage7_alchemist/frames/item5/idle_01.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item5/idle_02.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item5/idle_03.png"),
		preload("res://assets/art/heroes/stage7_alchemist/frames/item5/idle_04.png"),
	],
]

@onready var visual: AnimatedSprite2D = $Visual

var active: bool = false
var gas_value: float = 20.0
var material_type: int = 1


func _ready() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for material_index in range(MATERIAL_TEXTURES.size()):
		var animation_name := StringName("item_%d" % (material_index + 1))
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 5.0)
		frames.set_animation_loop(animation_name, true)
		var textures: Array = MATERIAL_TEXTURES[material_index]
		for texture in textures:
			frames.add_frame(animation_name, texture)

	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.20, 0.20)
	deactivate()


func activate(world_position: Vector2, value: float) -> void:
	global_position = world_position
	gas_value = maxf(value, 0.0)
	material_type = randi_range(1, MATERIAL_TEXTURES.size())
	active = true
	visible = true

	var animation_name := StringName("item_%d" % material_type)
	visual.play(animation_name)
	var frame_count: int = visual.sprite_frames.get_frame_count(animation_name)
	if frame_count > 0:
		visual.frame = randi_range(0, frame_count - 1)


func deactivate() -> void:
	active = false
	visible = false
	if is_instance_valid(visual):
		visual.stop()
