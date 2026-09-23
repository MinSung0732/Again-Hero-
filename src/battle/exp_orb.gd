extends Node2D

const FRAME_COUNT := 6
const FRAME_SIZE := Vector2(64, 56)
const TARGET_HEIGHT := 42.0
const IDLE_SENSE_MIN_INTERVAL := 0.10
const IDLE_SENSE_MAX_INTERVAL := 0.16

static var _tier_frames_cache: Dictionary = {}

const TIER_DATA := [
	{
		"id": "normal",
		"min_exp": 1,
		"path": "res://assets/art/effects/expstone/01_normal",
	},
	{
		"id": "advanced",
		"min_exp": 16,
		"path": "res://assets/art/effects/expstone/02_advanced",
	},
	{
		"id": "rare",
		"min_exp": 31,
		"path": "res://assets/art/effects/expstone/03_rare",
	},
	{
		"id": "heroic",
		"min_exp": 51,
		"path": "res://assets/art/effects/expstone/04_heroic",
	},
	{
		"id": "legendary",
		"min_exp": 81,
		"path": "res://assets/art/effects/expstone/05_legendary",
	},
	{
		"id": "mythic",
		"min_exp": 121,
		"path": "res://assets/art/effects/expstone/06_mythic",
	},
	{
		"id": "transcendent",
		"min_exp": 201,
		"path": "res://assets/art/effects/expstone/07_transcendent",
	},
]

@export var attraction_speed: float = 620.0
@export var collect_distance: float = 24.0

@onready var visual: AnimatedSprite2D = $Visual

var exp_value: int = 0
var hero: Node2D
var magnetized: bool = false
var pulse_time: float = 0.0
var burst_velocity: Vector2 = Vector2.ZERO
var burst_time: float = 0.0
var idle_sense_timer: float = 0.0

func _ready() -> void:
	add_to_group("exp_orbs")
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	idle_sense_timer = randf_range(
		IDLE_SENSE_MIN_INTERVAL,
		IDLE_SENSE_MAX_INTERVAL
	)
	visual.visible = false
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func setup(value: int, initial_velocity: Vector2 = Vector2.ZERO) -> void:
	if not is_in_group("exp_orbs"):
		add_to_group("exp_orbs")
	visible = true
	set_physics_process(true)
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	pulse_time = 0.0
	exp_value = maxi(value, 0)
	burst_velocity = initial_velocity
	burst_time = 0.30 if initial_velocity.length_squared() > 0.01 else 0.0
	magnetized = false
	idle_sense_timer = randf_range(
		IDLE_SENSE_MIN_INTERVAL,
		IDLE_SENSE_MAX_INTERVAL
	)
	_apply_exp_stone_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	pulse_time += delta
	if burst_time > 0.0:
		global_position += burst_velocity * delta
		burst_velocity = burst_velocity.lerp(
			Vector2.ZERO,
			clampf(delta * 8.0, 0.0, 1.0)
		)
		burst_time = maxf(burst_time - delta, 0.0)

	if not visual.visible:
		queue_redraw()

	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			return

	var pickup_radius := 150.0
	var radius_value = hero.get("exp_pickup_radius")
	if radius_value != null:
		pickup_radius = maxf(float(radius_value), 1.0)

	# Once the initial drop burst is over, dormant orbs only need to check
	# whether the hero entered pickup range at ~6-10 Hz.
	if not magnetized and burst_time <= 0.0:
		idle_sense_timer = maxf(idle_sense_timer - delta, 0.0)
		if idle_sense_timer > 0.0:
			return
		idle_sense_timer = randf_range(
			IDLE_SENSE_MIN_INTERVAL,
			IDLE_SENSE_MAX_INTERVAL
		)

	var offset_to_hero := hero.global_position - global_position
	var distance_sq := offset_to_hero.length_squared()
	var pickup_radius_sq := pickup_radius * pickup_radius

	if not magnetized:
		if distance_sq > pickup_radius_sq:
			return
		magnetized = true

	var collect_distance_sq := collect_distance * collect_distance
	if distance_sq <= collect_distance_sq:
		if hero.has_method("gain_exp"):
			hero.call("gain_exp", exp_value)
		var parent := get_parent()
		if is_instance_valid(parent) and parent.has_method("recycle_exp_orb"):
			parent.call("recycle_exp_orb", self)
		else:
			queue_free()
		return

	var distance := sqrt(distance_sq)
	var speed_scale := (
		1.0
		+ clampf(
			(pickup_radius - distance) / pickup_radius,
			0.0,
			1.0
		) * 0.45
	)
	if distance_sq > 0.001:
		global_position += (
			offset_to_hero / distance
			* attraction_speed
			* speed_scale
			* delta
		)


func deactivate_for_pool() -> void:
	magnetized = false
	burst_velocity = Vector2.ZERO
	burst_time = 0.0
	idle_sense_timer = 0.0
	exp_value = 0
	if is_in_group("exp_orbs"):
		remove_from_group("exp_orbs")
	set_physics_process(false)
	visible = false
	visual.stop()


func _apply_exp_stone_visual() -> void:
	visual.visible = false
	visual.sprite_frames = null

	var tier := _get_tier_data(exp_value)
	if tier.is_empty():
		return

	var tier_id := String(tier.get("id", ""))
	var frames = _tier_frames_cache.get(tier_id)
	if not (frames is SpriteFrames):
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")

		frames.add_animation(&"idle")
		frames.set_animation_speed(&"idle", 10.0)
		frames.set_animation_loop(&"idle", true)

		var base_path := String(tier.get("path", ""))
		for index in range(1, FRAME_COUNT + 1):
			var frame_path := "%s/frame_%02d.png" % [base_path, index]
			var texture := _load_texture(frame_path)
			if texture == null:
				return
			frames.add_frame(&"idle", texture)

		_tier_frames_cache[tier_id] = frames

	visual.sprite_frames = frames
	var uniform_scale := TARGET_HEIGHT / FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.visible = true
	visual.play(&"idle")


func _get_tier_data(value: int) -> Dictionary:
	var selected: Dictionary = {}
	for raw_tier in TIER_DATA:
		var tier: Dictionary = raw_tier
		if value >= int(tier.get("min_exp", 1)):
			selected = tier
		else:
			break
	return selected

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture

	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(path)
		if error == OK:
			return ImageTexture.create_from_image(image)

	return null

func _draw() -> void:
	if visual.visible:
		return

	var pulse := 1.0 + sin(pulse_time * 6.0) * 0.10
	var radius := 10.0 * pulse
	draw_circle(
		Vector2.ZERO,
		radius + 5.0,
		Color(0.20, 0.85, 1.0, 0.18)
	)
	draw_circle(Vector2.ZERO, radius, Color(0.20, 0.85, 1.0))
	draw_circle(
		Vector2.ZERO,
		radius * 0.45,
		Color(0.82, 0.98, 1.0)
	)
