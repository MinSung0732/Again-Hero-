extends Area2D

const EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect8"
const POOL_KEY := "sage_annihilation_point"
const MONSTER_RUNTIME_COMMON := preload("res://src/monsters/monster_runtime_common.gd")

const CREATE_FIRST_FRAME := 1
const CREATE_FRAME_COUNT := 5
const ACTIVE_FIRST_FRAME := 5
const ACTIVE_FRAME_COUNT := 2
const DISAPPEAR_FIRST_FRAME := 7
const DISAPPEAR_FRAME_COUNT := 2
const ATTRACTION_WISP_COUNT := 8

static var _texture_cache: Dictionary = {}

enum State {
	INACTIVE,
	CREATING,
	ACTIVE,
	DISAPPEARING,
	AUDIO_TAIL,
}

var state: int = State.INACTIVE
var caster: Node2D
var active_duration: float = 6.0
var effect_radius: float = 200.0
var damage: int = 1
var pull_interval: float = 0.10
var pull_step: float = 10.0
var damage_interval: float = 0.50
var execution_hp_ratio: float = 0.10
var visual_scale: float = 1.05
var create_fps: float = 10.0
var active_fps: float = 5.0
var disappear_fps: float = 10.0

var create_elapsed: float = 0.0
var active_elapsed: float = 0.0
var disappear_elapsed: float = 0.0
var pull_timer: float = 0.0
var damage_timer: float = 0.0
var _last_frame: int = -1
var _all_monster_scratch: Array = []
var _damage_scratch: Array = []
var _wisps: Array[Sprite2D] = []

@onready var visual: Sprite2D = $Visual
@onready var attraction_layer: Node2D = $AttractionLayer
@onready var creation_audio: AudioStreamPlayer2D = $CreationAudio
@onready var execution_audio: AudioStreamPlayer2D = $ExecutionAudio


func _ready() -> void:
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_attraction_wisps()
	deactivate_for_pool()


func setup(
	caster_node: Node2D,
	new_duration: float,
	new_effect_radius: float,
	new_damage: int,
	new_pull_interval: float,
	new_pull_step: float,
	new_damage_interval: float,
	new_execution_hp_ratio: float,
	new_visual_scale: float,
	new_create_fps: float,
	new_active_fps: float,
	new_disappear_fps: float
) -> void:
	caster = caster_node
	active_duration = maxf(new_duration, 0.1)
	effect_radius = maxf(new_effect_radius, 1.0)
	damage = maxi(new_damage, 1)
	pull_interval = maxf(new_pull_interval, 0.05)
	pull_step = maxf(new_pull_step, 0.0)
	damage_interval = maxf(new_damage_interval, 0.05)
	execution_hp_ratio = clampf(new_execution_hp_ratio, 0.0, 1.0)
	visual_scale = maxf(new_visual_scale, 0.05)
	create_fps = maxf(new_create_fps, 1.0)
	active_fps = maxf(new_active_fps, 1.0)
	disappear_fps = maxf(new_disappear_fps, 1.0)

	create_elapsed = 0.0
	active_elapsed = 0.0
	disappear_elapsed = 0.0
	pull_timer = pull_interval
	damage_timer = damage_interval
	_last_frame = -1

	state = State.CREATING
	visible = true
	set_physics_process(true)
	visual.visible = true
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE * visual_scale
	_set_frame(CREATE_FIRST_FRAME)
	_set_wisps_visible(false)

	if is_instance_valid(creation_audio) and creation_audio.stream != null:
		creation_audio.stop()
		creation_audio.play()
	if is_instance_valid(execution_audio):
		execution_audio.stop()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or state == State.AUDIO_TAIL:
		return
	if _is_combat_simulation_paused():
		return
	if (
		is_instance_valid(caster)
		and not caster.is_queued_for_deletion()
		and caster.get("current_hp") != null
		and int(caster.get("current_hp")) <= 0
		and state != State.DISAPPEARING
	):
		_begin_disappearing()

	match state:
		State.CREATING:
			_update_creating(delta)
		State.ACTIVE:
			_update_active(delta)
		State.DISAPPEARING:
			_update_disappearing(delta)
		_:
			pass


func _is_combat_simulation_paused() -> bool:
	var battle := get_parent()
	if not is_instance_valid(battle):
		return false
	if battle.has_method("is_combat_simulation_paused"):
		return bool(battle.call("is_combat_simulation_paused"))
	return false


func _update_creating(delta: float) -> void:
	create_elapsed += delta
	var frame_offset := mini(
		floori(create_elapsed * create_fps),
		CREATE_FRAME_COUNT - 1
	)
	_set_frame(CREATE_FIRST_FRAME + frame_offset)
	queue_redraw()
	if create_elapsed * create_fps >= float(CREATE_FRAME_COUNT):
		_begin_active()


func _begin_active() -> void:
	if state != State.CREATING:
		return
	state = State.ACTIVE
	active_elapsed = 0.0
	pull_timer = 0.0
	damage_timer = damage_interval
	_set_frame(ACTIVE_FIRST_FRAME)
	_set_wisps_visible(true)
	queue_redraw()


func _update_active(delta: float) -> void:
	active_elapsed += delta
	var frame_offset := int(floor(active_elapsed * active_fps)) % ACTIVE_FRAME_COUNT
	_set_frame(ACTIVE_FIRST_FRAME + frame_offset)
	_update_attraction_wisps()

	pull_timer -= delta
	while pull_timer <= 0.0:
		_apply_global_pull()
		pull_timer += pull_interval

	damage_timer -= delta
	while damage_timer <= 0.0:
		_apply_damage_tick()
		damage_timer += damage_interval

	queue_redraw()
	if active_elapsed + 0.0001 >= active_duration:
		_begin_disappearing()


func _begin_disappearing() -> void:
	if state == State.DISAPPEARING or state == State.INACTIVE:
		return
	state = State.DISAPPEARING
	disappear_elapsed = 0.0
	_set_wisps_visible(false)
	_set_frame(DISAPPEAR_FIRST_FRAME)
	queue_redraw()


func _update_disappearing(delta: float) -> void:
	disappear_elapsed += delta
	var frame_offset := floori(disappear_elapsed * disappear_fps)
	if frame_offset >= DISAPPEAR_FRAME_COUNT:
		visual.visible = false
		queue_redraw()
		if (
			(is_instance_valid(creation_audio) and creation_audio.playing)
			or (is_instance_valid(execution_audio) and execution_audio.playing)
		):
			state = State.AUDIO_TAIL
			set_physics_process(false)
			if is_instance_valid(execution_audio) and execution_audio.playing:
				var execute_finished := Callable(self, "_finish")
				if not execution_audio.finished.is_connected(execute_finished):
					execution_audio.finished.connect(
						execute_finished,
						Object.CONNECT_ONE_SHOT
					)
			elif is_instance_valid(creation_audio) and creation_audio.playing:
				var create_finished := Callable(self, "_finish")
				if not creation_audio.finished.is_connected(create_finished):
					creation_audio.finished.connect(
						create_finished,
						Object.CONNECT_ONE_SHOT
					)
		else:
			_finish()
		return
	_set_frame(DISAPPEAR_FIRST_FRAME + frame_offset)


func _apply_global_pull() -> void:
	if pull_step <= 0.0:
		return
	var query_owner := get_parent()
	if not is_instance_valid(query_owner):
		return

	_all_monster_scratch.clear()
	if query_owner.has_method("fill_active_monsters"):
		query_owner.call("fill_active_monsters", _all_monster_scratch)
	else:
		var tree := get_tree()
		if tree != null:
			_all_monster_scratch.append_array(tree.get_nodes_in_group("monsters"))

	for raw_node in _all_monster_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or not MONSTER_RUNTIME_COMMON.can_be_forced_moved(monster)
		):
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var offset := global_position - monster.global_position
		var distance := offset.length()
		if distance <= 6.0:
			continue
		var step := minf(pull_step, distance - 6.0)
		monster.global_position += offset / distance * step


func _apply_damage_tick() -> void:
	var query_owner := get_parent()
	if not is_instance_valid(query_owner):
		return

	_damage_scratch.clear()
	if query_owner.has_method("fill_monsters_near"):
		query_owner.call(
			"fill_monsters_near",
			global_position,
			effect_radius,
			_damage_scratch
		)
	else:
		var tree := get_tree()
		if tree != null:
			_damage_scratch.append_array(tree.get_nodes_in_group("monsters"))

	var radius_sq := effect_radius * effect_radius
	var executed_any := false
	for raw_node in _damage_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or not monster.has_method("take_damage")
			or global_position.distance_squared_to(monster.global_position) > radius_sq
		):
			continue

		var hp_value = monster.get("current_hp")
		if hp_value == null or int(hp_value) <= 0:
			continue
		var max_hp_value = monster.get("max_hp")
		var current_hp := maxi(int(hp_value), 0)
		var max_hp := maxi(int(max_hp_value) if max_hp_value != null else current_hp, 1)
		if float(current_hp) / float(max_hp) <= execution_hp_ratio:
			_execute_monster(monster, current_hp, max_hp)
			executed_any = true
		else:
			monster.call("take_damage", damage)

	_damage_scratch.clear()
	if (
		executed_any
		and is_instance_valid(execution_audio)
		and execution_audio.stream != null
	):
		execution_audio.stop()
		execution_audio.play()


func _execute_monster(monster: Node2D, current_hp: int, max_hp: int) -> void:
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		return
	if MONSTER_RUNTIME_COMMON.can_be_forced_moved(monster):
		monster.global_position = monster.global_position.lerp(
			global_position,
			0.72
		)
		if monster is CharacterBody2D:
			(monster as CharacterBody2D).velocity = Vector2.ZERO

	var execution_damage := maxi(
		current_hp + max_hp * 4,
		damage
	)
	monster.call("take_damage", execution_damage)


func _build_attraction_wisps() -> void:
	if not _wisps.is_empty():
		return
	var texture := _load_texture_cached(
		"%s/stage10_effect3_02.png" % EFFECT_DIR
	)
	if texture == null:
		return

	for index in range(ATTRACTION_WISP_COUNT):
		var sprite := Sprite2D.new()
		sprite.name = "AttractionWisp%02d" % index
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * visual_scale * 0.13
		sprite.modulate = Color(0.82, 0.74, 1.0, 0.28)
		sprite.visible = false
		attraction_layer.add_child(sprite)
		_wisps.append(sprite)


func _set_wisps_visible(show_wisps: bool) -> void:
	for sprite in _wisps:
		if is_instance_valid(sprite):
			sprite.visible = show_wisps


func _update_attraction_wisps() -> void:
	if _wisps.is_empty():
		return
	var outer_radius := effect_radius * 1.72
	var inner_radius := effect_radius * 0.30
	for index in range(_wisps.size()):
		var sprite := _wisps[index]
		if not is_instance_valid(sprite):
			continue
		var phase := fmod(
			active_elapsed * 0.72 + float(index) / float(_wisps.size()),
			1.0
		)
		var radius := lerpf(outer_radius, inner_radius, phase)
		var angle := (
			float(index) / float(_wisps.size()) * TAU
			+ active_elapsed * 1.35
			+ phase * 1.8
		)
		sprite.position = Vector2.from_angle(angle) * radius
		sprite.rotation = angle + PI * 0.5
		sprite.scale = Vector2.ONE * visual_scale * lerpf(0.16, 0.07, phase)
		sprite.modulate.a = lerpf(0.16, 0.48, phase)
		sprite.visible = true


func _draw() -> void:
	if state == State.INACTIVE or state == State.AUDIO_TAIL:
		return
	draw_arc(
		Vector2.ZERO,
		effect_radius,
		0.0,
		TAU,
		64,
		Color(0.75, 0.64, 1.0, 0.72),
		1.5,
		true
	)
	if state == State.ACTIVE:
		var pulse := 0.5 + sin(active_elapsed * 4.0) * 0.08
		for ring_index in range(3):
			var ring_radius := effect_radius * (1.12 + float(ring_index) * 0.15)
			draw_arc(
				Vector2.ZERO,
				ring_radius,
				active_elapsed * (0.7 + float(ring_index) * 0.13),
				active_elapsed * (0.7 + float(ring_index) * 0.13) + PI * pulse,
				32,
				Color(0.66, 0.52, 1.0, 0.18),
				1.0,
				true
			)


func _set_frame(frame_index: int) -> void:
	if frame_index == _last_frame:
		return
	_last_frame = frame_index
	var path := "%s/stage10_effect3_%02d.png" % [EFFECT_DIR, frame_index]
	var texture := _load_texture_cached(path)
	if texture != null:
		visual.texture = texture


static func _load_texture_cached(path: String) -> Texture2D:
	var cached = _texture_cache.get(path)
	if cached is Texture2D:
		return cached
	if not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	if resource is Texture2D:
		_texture_cache[path] = resource
		return resource
	return null


func _finish() -> void:
	if state == State.INACTIVE:
		return
	state = State.INACTIVE
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	state = State.INACTIVE
	set_physics_process(false)
	visible = false
	caster = null
	_all_monster_scratch.clear()
	_damage_scratch.clear()
	_set_wisps_visible(false)
	if is_instance_valid(visual):
		visual.visible = false
		visual.position = Vector2.ZERO
	if is_instance_valid(creation_audio):
		creation_audio.stop()
	if is_instance_valid(execution_audio):
		execution_audio.stop()
	queue_redraw()
