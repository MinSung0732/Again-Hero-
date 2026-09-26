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
var lifetime_remaining: float = 0.0
var temporary_drop: bool = false
var in_flight: bool = false
var flight_origin: Vector2 = Vector2.ZERO
var flight_target: Vector2 = Vector2.ZERO
var flight_duration: float = 0.0
var flight_elapsed: float = 0.0
var flight_arc_height: float = 0.0


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


func activate(
	world_position: Vector2,
	value: float,
	lifetime_seconds: float = 0.0,
	is_temporary: bool = false
) -> void:
	global_position = world_position
	gas_value = maxf(value, 0.0)
	material_type = randi_range(1, MATERIAL_TEXTURES.size())
	lifetime_remaining = maxf(lifetime_seconds, 0.0)
	temporary_drop = is_temporary
	in_flight = false
	flight_elapsed = 0.0
	active = true
	visible = true
	set_process(lifetime_remaining > 0.0)

	var animation_name := StringName("item_%d" % material_type)
	visual.play(animation_name)
	var frame_count: int = visual.sprite_frames.get_frame_count(animation_name)
	if frame_count > 0:
		visual.frame = randi_range(0, frame_count - 1)


func launch_from_cauldron(
	origin: Vector2,
	target: Vector2,
	duration: float = 0.42,
	arc_height: float = 58.0
) -> void:
	if not active:
		return
	flight_origin = origin
	flight_target = target
	flight_duration = maxf(duration, 0.05)
	flight_elapsed = 0.0
	flight_arc_height = maxf(arc_height, 0.0)
	in_flight = true
	global_position = origin
	set_process(true)


func _process(delta: float) -> void:
	if not active:
		return

	if in_flight:
		flight_elapsed = minf(flight_elapsed + delta, flight_duration)
		var t := clampf(flight_elapsed / flight_duration, 0.0, 1.0)
		var travel_position := flight_origin.lerp(flight_target, t)
		travel_position.y -= sin(t * PI) * flight_arc_height
		global_position = travel_position
		if t >= 1.0:
			in_flight = false
			global_position = flight_target

	if lifetime_remaining <= 0.0:
		if not in_flight:
			set_process(false)
		return
	lifetime_remaining = maxf(lifetime_remaining - delta, 0.0)
	if lifetime_remaining <= 0.0:
		deactivate()
		return

	if lifetime_remaining <= 3.0:
		var blink_speed: float = lerpf(5.0, 13.0, 1.0 - lifetime_remaining / 3.0)
		visible = fmod(lifetime_remaining * blink_speed, 1.0) > 0.32
	else:
		visible = true


func deactivate() -> void:
	active = false
	in_flight = false
	flight_elapsed = 0.0
	visible = false
	set_process(false)
	if is_instance_valid(visual):
		visual.stop()
	if temporary_drop:
		queue_free()
