extends Node2D

signal damage_tick(origin: Vector2, radius: float, damage: int)

const POISON_TEXTURES := [
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_02.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_03.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_04.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_05.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_06.png"),
]

@onready var visual: AnimatedSprite2D = $Visual

var active: bool = false
var duration_remaining: float = 0.0
var hit_radius: float = 206.25
var tick_interval: float = 0.27
var tick_timer: float = 0.27
var tick_damage: int = 1

func _ready() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("poison")
	frames.set_animation_speed("poison", 8.0)
	frames.set_animation_loop("poison", true)
	for texture in POISON_TEXTURES:
		frames.add_frame("poison", texture)
	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.79, 0.79)
	deactivate()

func is_available() -> bool:
	return not active

func activate(world_position: Vector2, duration: float, radius: float, interval: float, damage: int) -> void:
	global_position = world_position
	duration_remaining = maxf(duration, 0.1)
	hit_radius = maxf(radius, 1.0)
	tick_interval = maxf(interval, 0.03)
	tick_timer = tick_interval
	tick_damage = maxi(damage, 1)
	active = true
	visible = true
	visual.stop()
	visual.frame = 0
	visual.play("poison")
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not active:
		return
	duration_remaining -= delta
	tick_timer -= delta
	while tick_timer <= 0.0 and duration_remaining > 0.0:
		damage_tick.emit(global_position, hit_radius, tick_damage)
		tick_timer += tick_interval
	if duration_remaining <= 0.0:
		deactivate()

func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	if is_instance_valid(visual):
		visual.stop()
