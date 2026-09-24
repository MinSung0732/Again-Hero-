extends Node2D

signal field_tick(origin: Vector2, radius: float)
signal field_finished

const SMOKE_TEXTURES := [
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_13.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_14.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_15.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_16.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_17.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_18.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_19.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect4/effect_20.png"),
]

const SMOKE_POOL_SIZE := 8

var active: bool = false
var radius: float = 660.0
var duration_remaining: float = 0.0
var tick_interval: float = 0.5
var tick_timer: float = 0.5
var smoke_interval: float = 0.18
var smoke_timer: float = 0.0
var smoke_cursor: int = 0
var smoke_pool: Array[AnimatedSprite2D] = []

func _ready() -> void:
	for _index in range(SMOKE_POOL_SIZE):
		var smoke := AnimatedSprite2D.new()
		var frames := SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("smoke")
		frames.set_animation_speed("smoke", 12.0)
		frames.set_animation_loop("smoke", false)
		for texture in SMOKE_TEXTURES:
			frames.add_frame("smoke", texture)
		smoke.sprite_frames = frames
		smoke.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		smoke.scale = Vector2(0.55, 0.55)
		smoke.visible = false
		smoke.animation_finished.connect(_on_smoke_finished.bind(smoke))
		add_child(smoke)
		smoke_pool.append(smoke)
	deactivate()

func activate(world_position: Vector2, field_radius: float, duration: float, damage_tick_interval: float) -> void:
	global_position = world_position
	radius = maxf(field_radius, 1.0)
	duration_remaining = maxf(duration, 0.1)
	tick_interval = maxf(damage_tick_interval, 0.05)
	tick_timer = 0.0
	smoke_timer = 0.0
	active = true
	visible = true
	set_physics_process(true)
	queue_redraw()

func contains_world_point(world_position: Vector2) -> bool:
	return active and global_position.distance_squared_to(world_position) <= radius * radius

func _physics_process(delta: float) -> void:
	if not active:
		return

	duration_remaining -= delta
	tick_timer -= delta
	smoke_timer -= delta

	while tick_timer <= 0.0 and duration_remaining > 0.0:
		field_tick.emit(global_position, radius)
		tick_timer += tick_interval

	if smoke_timer <= 0.0 and duration_remaining > 0.0:
		_spawn_smoke()
		smoke_timer += smoke_interval

	if duration_remaining <= 0.0:
		deactivate()
		field_finished.emit()

func _spawn_smoke() -> void:
	if smoke_pool.is_empty():
		return
	var smoke := smoke_pool[smoke_cursor]
	smoke_cursor = (smoke_cursor + 1) % smoke_pool.size()
	var angle := randf() * TAU
	var distance := sqrt(randf()) * radius * 0.88
	smoke.position = Vector2.from_angle(angle) * distance
	smoke.rotation = randf_range(-0.18, 0.18)
	smoke.visible = true
	smoke.stop()
	smoke.frame = 0
	smoke.play("smoke")

func _on_smoke_finished(smoke: AnimatedSprite2D) -> void:
	if is_instance_valid(smoke):
		smoke.visible = false

func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	for smoke in smoke_pool:
		if is_instance_valid(smoke):
			smoke.stop()
			smoke.visible = false
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		96,
		Color(0.25, 0.95, 0.42, 0.95),
		5.0,
		true
	)
