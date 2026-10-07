extends Node2D

const SUMMONER_SFX := preload("res://src/audio/summoner_audio.gd")

signal released(open_gate: Node2D)

const DRONE_SCENE := preload("res://src/hero/SummonerSuicideDrone.tscn")
const DEFAULT_FRAME_DIR := "res://assets/art/heroes/stage8_summoner/frames/effect5"
const DEFAULT_OPENING_AUDIO_PATH := "res://assets/audio/sfx/summoner_clean/portal.wav"
const DEFAULT_DRONE_SPAWN_AUDIO_PATH := "res://assets/audio/sfx/summoner_drone_spawn.mp3"

static var _frames_cache_by_dir: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual
@onready var opening_audio: AudioStreamPlayer = $OpeningAudio
@onready var drone_spawn_audio: AudioStreamPlayer = $DroneSpawnAudio

var active: bool = false
var owner_hero: Node2D = null
var open_duration: float = 40.0
var open_duration_remaining: float = 0.0
var drone_spawn_interval: float = 0.20
var drone_spawn_timer: float = 0.0
var drone_config: Dictionary = {}
var frame_dir: String = DEFAULT_FRAME_DIR
var visual_scale: float = 0.70
var visual_offset_y: float = -133.0
var phase: StringName = &"inactive"
var drone_pool: Array[Node2D] = []
var drone_spawn_index: int = 0
var drone_spawn_half_width: float = 90.0
var drone_spawn_y_min: float = -220.0
var drone_spawn_y_max: float = -70.0


func _ready() -> void:
	_setup_visual(DEFAULT_FRAME_DIR, 2.0)
	_load_audio(DEFAULT_OPENING_AUDIO_PATH, DEFAULT_DRONE_SPAWN_AUDIO_PATH)
	deactivate(false)


func prepare_pool(config: Dictionary) -> void:
	var raw_drone_config = config.get("drone", {})
	drone_config = (
		raw_drone_config.duplicate(true)
		if typeof(raw_drone_config) == TYPE_DICTIONARY
		else {}
	)
	frame_dir = String(config.get("frame_dir", DEFAULT_FRAME_DIR))
	visual_scale = maxf(float(config.get("visual_scale", 0.70)), 0.01)
	visual_offset_y = float(config.get("visual_offset_y", -133.0))
	drone_spawn_half_width = maxf(
		float(config.get("drone_spawn_half_width", 90.0)),
		0.0
	)
	var raw_spawn_y_min := float(
		config.get("drone_spawn_y_min", -220.0)
	)
	var raw_spawn_y_max := float(
		config.get("drone_spawn_y_max", -70.0)
	)
	drone_spawn_y_min = minf(raw_spawn_y_min, raw_spawn_y_max)
	drone_spawn_y_max = maxf(raw_spawn_y_min, raw_spawn_y_max)
	var opening_frame_seconds := maxf(
		float(config.get("opening_frame_seconds", 2.0)),
		0.05
	)
	_setup_visual(frame_dir, opening_frame_seconds)
	_load_audio(
		String(config.get("opening_audio_path", DEFAULT_OPENING_AUDIO_PATH)),
		String(config.get("drone_spawn_audio_path", DEFAULT_DRONE_SPAWN_AUDIO_PATH))
	)
	_ensure_drone_pool(maxi(int(config.get("drone_pool_size", 96)), 1))


func activate(world_position: Vector2, new_owner: Node2D, config: Dictionary) -> void:
	global_position = world_position
	owner_hero = new_owner
	open_duration = maxf(float(config.get("open_duration", 40.0)), 0.1)
	open_duration_remaining = 0.0
	drone_spawn_interval = maxf(float(config.get("drone_spawn_interval", 0.20)), 0.05)
	drone_spawn_timer = drone_spawn_interval
	var raw_drone_config = config.get("drone", {})
	drone_config = (
		raw_drone_config.duplicate(true)
		if typeof(raw_drone_config) == TYPE_DICTIONARY
		else {}
	)
	frame_dir = String(config.get("frame_dir", DEFAULT_FRAME_DIR))
	visual_scale = maxf(float(config.get("visual_scale", 0.70)), 0.01)
	visual_offset_y = float(config.get("visual_offset_y", -133.0))
	drone_spawn_half_width = maxf(
		float(config.get("drone_spawn_half_width", 90.0)),
		0.0
	)
	var raw_spawn_y_min := float(
		config.get("drone_spawn_y_min", -220.0)
	)
	var raw_spawn_y_max := float(
		config.get("drone_spawn_y_max", -70.0)
	)
	drone_spawn_y_min = minf(raw_spawn_y_min, raw_spawn_y_max)
	drone_spawn_y_max = maxf(raw_spawn_y_min, raw_spawn_y_max)
	var opening_frame_seconds := maxf(float(config.get("opening_frame_seconds", 2.0)), 0.05)
	_setup_visual(frame_dir, opening_frame_seconds)
	_load_audio(
		String(config.get("opening_audio_path", DEFAULT_OPENING_AUDIO_PATH)),
		String(config.get("drone_spawn_audio_path", DEFAULT_DRONE_SPAWN_AUDIO_PATH))
	)
	_ensure_drone_pool(maxi(int(config.get("drone_pool_size", 96)), 1))

	drone_spawn_index = 0
	active = true
	visible = true
	phase = &"opening"
	if not is_in_group("hero_summons"):
		add_to_group("hero_summons")
	set_physics_process(true)
	visual.visible = true
	visual.stop()
	visual.play(&"opening")
	SUMMONER_SFX.play_portal(owner_hero, opening_audio)


func _physics_process(delta: float) -> void:
	if not active:
		return

	if phase == &"open":
		open_duration_remaining = maxf(open_duration_remaining - delta, 0.0)
		drone_spawn_timer = maxf(drone_spawn_timer - delta, 0.0)
		while drone_spawn_timer <= 0.0 and open_duration_remaining > 0.0:
			_spawn_drone()
			drone_spawn_timer += drone_spawn_interval
		if open_duration_remaining <= 0.0:
			_begin_closing()


func _spawn_drone() -> void:
	var drone := _acquire_drone()
	if drone == null:
		return

	# Spawn from a random point inside the visible portal body so drones read
	# as emerging from the open gate instead of orbiting around its origin.
	var spawn_offset := Vector2(
		randf_range(-drone_spawn_half_width, drone_spawn_half_width),
		randf_range(drone_spawn_y_min, drone_spawn_y_max)
	)
	var spawn_position := global_position + spawn_offset
	drone_spawn_index += 1

	drone.call("activate", spawn_position, owner_hero, drone_config)
	var world := get_parent()
	if (
		is_instance_valid(world)
		and world.has_method("set_hero_summon_active")
	):
		world.call("set_hero_summon_active", drone, true)

	if drone_spawn_audio.stream != null:
		drone_spawn_audio.play()


func _on_drone_released(drone: Node2D) -> void:
	var world := get_parent()
	if (
		is_instance_valid(world)
		and world.has_method("set_hero_summon_active")
	):
		world.call("set_hero_summon_active", drone, false)


func _acquire_drone() -> Node2D:
	for drone in drone_pool:
		if is_instance_valid(drone) and bool(drone.call("is_available")):
			return drone
	return null


func _begin_closing() -> void:
	if not active or phase == &"closing":
		return
	phase = &"closing"
	visual.stop()
	visual.play(&"closing")


func deactivate(emit_signal: bool = true) -> void:
	var was_active := active
	active = false
	owner_hero = null
	open_duration_remaining = 0.0
	drone_spawn_timer = 0.0
	phase = &"inactive"
	visible = false
	set_physics_process(false)
	if is_in_group("hero_summons"):
		remove_from_group("hero_summons")
	if is_instance_valid(visual):
		visual.stop()
	if emit_signal and was_active:
		released.emit(self)


func is_combat_targetable() -> bool:
	return false


func take_damage(_amount: int, _source: Node = null) -> bool:
	return false


func _on_visual_animation_finished() -> void:
	if not active:
		return
	if visual.animation == &"opening":
		phase = &"open"
		open_duration_remaining = open_duration
		drone_spawn_timer = drone_spawn_interval
		visual.play(&"open_loop")
	elif visual.animation == &"closing":
		deactivate()


func _setup_visual(requested_frame_dir: String, opening_frame_seconds: float) -> void:
	var resolved_dir := requested_frame_dir
	if resolved_dir.is_empty():
		resolved_dir = DEFAULT_FRAME_DIR
	var cache_key := "%s|%.3f" % [resolved_dir, opening_frame_seconds]

	var frames: SpriteFrames = _frames_cache_by_dir.get(cache_key)
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")

		frames.add_animation(&"opening")
		frames.set_animation_loop(&"opening", false)
		frames.set_animation_speed(&"opening", 1.0 / opening_frame_seconds)
		for index in range(1, 7):
			var texture := _load_texture("%s/effect_%02d.png" % [resolved_dir, index])
			if texture != null:
				frames.add_frame(&"opening", texture)

		frames.add_animation(&"open_loop")
		frames.set_animation_loop(&"open_loop", true)
		frames.set_animation_speed(&"open_loop", 5.0)
		for index in range(5, 9):
			var texture := _load_texture("%s/effect_%02d.png" % [resolved_dir, index])
			if texture != null:
				frames.add_frame(&"open_loop", texture)

		frames.add_animation(&"closing")
		frames.set_animation_loop(&"closing", false)
		frames.set_animation_speed(&"closing", 10.0)
		for index in range(6, 0, -1):
			var texture := _load_texture("%s/effect_%02d.png" % [resolved_dir, index])
			if texture != null:
				frames.add_frame(&"closing", texture)

		_frames_cache_by_dir[cache_key] = frames

	visual.sprite_frames = frames
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * visual_scale
	visual.position = Vector2(0.0, visual_offset_y)
	if not visual.animation_finished.is_connected(_on_visual_animation_finished):
		visual.animation_finished.connect(_on_visual_animation_finished)


func _ensure_drone_pool(pool_size: int) -> void:
	var world := get_parent()
	if not is_instance_valid(world):
		return
	while drone_pool.size() < pool_size:
		var drone := DRONE_SCENE.instantiate() as Node2D
		if drone == null:
			break
		world.add_child(drone)
		var release_callable := Callable(self, "_on_drone_released")
		if (
			drone.has_signal("released")
			and not drone.is_connected("released", release_callable)
		):
			drone.connect("released", release_callable)
		drone_pool.append(drone)


func _load_audio(opening_path: String, drone_spawn_path: String) -> void:
	if not opening_path.is_empty() and ResourceLoader.exists(opening_path):
		var stream = load(opening_path)
		if stream is AudioStream:
			opening_audio.stream = stream
	if not drone_spawn_path.is_empty() and ResourceLoader.exists(drone_spawn_path):
		var stream = load(drone_spawn_path)
		if stream is AudioStream:
			drone_spawn_audio.stream = stream


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	return null
