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

const SMOKE_POOL_SIZE := 12
const REVEAL_DURATION := 0.32
const SMOKE_REVEAL_THRESHOLD := 0.45

var active: bool = false
var radius: float = 450.0
var duration_remaining: float = 0.0
var tick_interval: float = 0.5
var tick_timer: float = 0.5
var smoke_interval: float = 0.11
var smoke_timer: float = 0.0
var smoke_cursor: int = 0
var reveal_progress: float = 1.0
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
		smoke.scale = Vector2(0.62, 0.62)
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
	reveal_progress = 0.0
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

	if reveal_progress < 1.0:
		reveal_progress = minf(
			reveal_progress + delta / REVEAL_DURATION,
			1.0
		)
		queue_redraw()

	while tick_timer <= 0.0 and duration_remaining > 0.0:
		field_tick.emit(global_position, radius)
		tick_timer += tick_interval

	if (
		reveal_progress >= SMOKE_REVEAL_THRESHOLD
		and smoke_timer <= 0.0
		and duration_remaining > 0.0
	):
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
	var distance := sqrt(randf()) * radius * 0.94
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
	reveal_progress = 1.0
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

	var t := clampf(reveal_progress, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var fill_radius := radius * eased
	var fill_alpha := 0.10 * eased

	if fill_radius > 0.5:
		draw_circle(
			Vector2.ZERO,
			fill_radius,
			Color(0.20, 0.80, 0.34, fill_alpha)
		)

		# The advancing edge gives the field a soft "soaking outward" read
		# without adding another scene/effect allocation.
		if t < 1.0:
			draw_arc(
				Vector2.ZERO,
				fill_radius,
				0.0,
				TAU,
				96,
				Color(0.35, 1.0, 0.50, 0.32 * (1.0 - t)),
				3.0,
				true
			)

	# Keep the final gameplay boundary visible from cast start so the player
	# can read the full area while the translucent fill spreads underneath.
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
