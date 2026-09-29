extends Node2D

signal launched
signal impacted
signal finished

const MONSTER_RUNTIME_COMMON := preload(
	"res://src/monsters/monster_runtime_common.gd"
)

enum State {
	CASTING,
	FLYING,
	IMPACT_HOLD,
	EXPLODING,
	CAMERA_RESTORE,
	DONE,
}

static var _texture_cache: Dictionary = {}

@onready var charge_aura: Sprite2D = $ChargeAura
@onready var trail_layer: Node2D = $TrailLayer
@onready var visual: Sprite2D = $Visual

var caster: Node2D
var config: Dictionary = {}
var direction: Vector2 = Vector2.RIGHT
var state: int = State.CASTING

var effect_dir: String = ""
var cast_seconds: float = 1.0
var projectile_speed: float = 900.0
var max_distance: float = 1500.0
var capture_radius: float = 150.0
var explosion_radius: float = 250.0
var damage_ratio: float = 1.50
var slow_multiplier: float = 0.50
var slow_duration: float = 2.0
var impact_hold_seconds: float = 0.06
var explosion_fps: float = 12.0
var projectile_visual_scale: float = 0.62
var explosion_visual_scale: float = 1.30

var charge_effect_dir: String = ""
var charge_visual_scale: float = 0.85
var charge_alpha_start: float = 0.28
var charge_alpha_end: float = 0.88
var charge_frame_first: int = 17
var charge_frame_last: int = 22
var _last_charge_frame: int = -1

var trail_interval: float = 0.035
var trail_lifetime: float = 0.20
var trail_alpha: float = 0.42
var trail_scale_multiplier: float = 0.94
var trail_pool_size: int = 10
var trail_timer: float = 0.0
var _trail_pool: Array[Sprite2D] = []
var _trail_ages: Array[float] = []
var _trail_active: Array[bool] = []
var _trail_base_scales: Array[Vector2] = []
var _trail_pool_index: int = 0

var camera_zoom_multiplier: float = 0.52
var camera_zoom_out_seconds: float = 0.22
var camera_zoom_in_seconds: float = 0.32
var camera_focus_ratio: float = 0.50
var _camera: Camera2D
var _camera_original_zoom: Vector2 = Vector2.ONE
var _camera_original_position: Vector2 = Vector2.ZERO
var _camera_zoom_from: Vector2 = Vector2.ONE
var _camera_position_from: Vector2 = Vector2.ZERO
var _camera_zoom_elapsed: float = 0.0
var _camera_restore_elapsed: float = 0.0
var _camera_effect_active: bool = false

var cast_elapsed: float = 0.0
var travelled: float = 0.0
var impact_elapsed: float = 0.0
var explosion_elapsed: float = 0.0
var _last_cast_frame: int = -1
var _last_flight_frame: int = -1
var _last_explosion_frame: int = -1

var _query_scratch: Array = []
var _captured: Array[Node2D] = []
var _captured_ids: Dictionary = {}


func setup(
	caster_node: Node2D,
	fire_direction: Vector2,
	skill_config: Dictionary
) -> void:
	caster = caster_node
	config = skill_config.duplicate(true)
	direction = (
		fire_direction.normalized()
		if fire_direction.length_squared() > 0.001
		else Vector2.RIGHT
	)
	effect_dir = String(
		config.get(
			"effect_dir",
			"res://assets/art/heroes/stage9_prist/frames/effect6"
		)
	)
	charge_effect_dir = String(
		config.get(
			"charge_effect_dir",
			"res://assets/art/heroes/stage9_prist/frames/effect3"
		)
	)
	charge_visual_scale = maxf(
		float(config.get("charge_visual_scale", 0.85)),
		0.05
	)
	charge_alpha_start = clampf(
		float(config.get("charge_alpha_start", 0.28)),
		0.0,
		1.0
	)
	charge_alpha_end = clampf(
		float(config.get("charge_alpha_end", 0.88)),
		0.0,
		1.0
	)
	charge_frame_first = int(config.get("charge_frame_first", 17))
	charge_frame_last = maxi(
		int(config.get("charge_frame_last", 22)),
		charge_frame_first
	)
	trail_interval = maxf(
		float(config.get("trail_interval", 0.035)),
		0.01
	)
	trail_lifetime = maxf(
		float(config.get("trail_lifetime", 0.20)),
		0.05
	)
	trail_alpha = clampf(
		float(config.get("trail_alpha", 0.42)),
		0.0,
		0.95
	)
	trail_scale_multiplier = maxf(
		float(config.get("trail_scale_multiplier", 0.94)),
		0.05
	)
	trail_pool_size = clampi(
		int(config.get("trail_pool_size", 10)),
		4,
		24
	)
	camera_zoom_multiplier = clampf(
		float(config.get("camera_zoom_multiplier", 0.52)),
		0.20,
		1.0
	)
	camera_zoom_out_seconds = maxf(
		float(config.get("camera_zoom_out_seconds", 0.22)),
		0.0
	)
	camera_zoom_in_seconds = maxf(
		float(config.get("camera_zoom_in_seconds", 0.32)),
		0.0
	)
	camera_focus_ratio = clampf(
		float(config.get("camera_focus_ratio", 0.50)),
		0.0,
		1.0
	)
	cast_seconds = maxf(float(config.get("cast_seconds", 1.0)), 0.05)
	projectile_speed = maxf(
		float(config.get("projectile_speed", 900.0)),
		1.0
	)
	max_distance = maxf(float(config.get("flight_distance", 1500.0)), 1.0)

	var capture_diameter := maxf(
		float(config.get("capture_diameter", 300.0)),
		2.0
	)
	var explosion_diameter := maxf(
		float(config.get("explosion_diameter", 500.0)),
		2.0
	)
	capture_radius = capture_diameter * 0.5
	explosion_radius = explosion_diameter * 0.5
	damage_ratio = maxf(float(config.get("damage_ratio", 1.50)), 0.0)
	slow_multiplier = clampf(
		float(config.get("slow_multiplier", 0.50)),
		0.05,
		1.0
	)
	slow_duration = maxf(float(config.get("slow_duration", 2.0)), 0.0)
	impact_hold_seconds = maxf(
		float(config.get("impact_hold_seconds", 0.06)),
		0.0
	)
	explosion_fps = maxf(float(config.get("explosion_fps", 12.0)), 1.0)

	var projectile_reference_diameter := maxf(
		float(config.get("projectile_reference_diameter", 490.0)),
		1.0
	)
	var explosion_reference_diameter := maxf(
		float(config.get("explosion_reference_diameter", 380.0)),
		1.0
	)
	projectile_visual_scale = maxf(
		float(
			config.get(
				"projectile_visual_scale",
				capture_diameter / projectile_reference_diameter
			)
		),
		0.05
	)
	explosion_visual_scale = maxf(
		float(
			config.get(
				"explosion_visual_scale",
				explosion_diameter / explosion_reference_diameter
			)
		),
		0.05
	)

	if is_instance_valid(caster):
		global_position = caster.global_position
	rotation = direction.angle()
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * projectile_visual_scale
	charge_aura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	charge_aura.top_level = true
	charge_aura.global_position = global_position
	charge_aura.global_rotation = 0.0
	charge_aura.visible = true
	_build_trail_pool()
	state = State.CASTING
	cast_elapsed = 0.0
	travelled = 0.0
	trail_timer = 0.0
	_set_cast_frame(1)
	_update_charge_aura(0.0)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_update_trails(delta)
	match state:
		State.CASTING:
			_update_casting(delta)
		State.FLYING:
			_update_flying(delta)
		State.IMPACT_HOLD:
			_update_impact_hold(delta)
		State.EXPLODING:
			_update_explosion(delta)
		State.CAMERA_RESTORE:
			_update_camera_restore(delta)
		_:
			pass


func _update_casting(delta: float) -> void:
	if not is_instance_valid(caster) or caster.is_queued_for_deletion():
		_finish()
		return
	var hp_value = caster.get("current_hp")
	if hp_value != null and int(hp_value) <= 0:
		_finish()
		return

	global_position = caster.global_position
	rotation = direction.angle()
	cast_elapsed = minf(cast_elapsed + delta, cast_seconds)
	var normalized := clampf(cast_elapsed / cast_seconds, 0.0, 0.9999)
	var frame_offset := mini(floori(normalized * 5.0), 4)
	_set_cast_frame(frame_offset + 1)
	_update_charge_aura(normalized)

	if cast_elapsed + 0.0001 >= cast_seconds:
		_begin_flight()


func _begin_flight() -> void:
	if state != State.CASTING:
		return
	state = State.FLYING
	if is_instance_valid(charge_aura):
		charge_aura.visible = false
	trail_timer = trail_interval
	_begin_camera_flight_view()
	_set_flight_frame(5)
	_emit_trail()
	launched.emit()


func _update_flying(delta: float) -> void:
	var remaining := maxf(max_distance - travelled, 0.0)
	if remaining <= 0.001:
		_arrive()
		return

	var step_distance := minf(projectile_speed * delta, remaining)
	var movement := direction * step_distance
	global_position += movement
	travelled += step_distance
	_update_camera_flight_view(delta)

	_drag_captured(movement)
	_capture_nearby_monsters()

	var progress := clampf(travelled / max_distance, 0.0, 1.0)
	if progress >= 0.86:
		_set_flight_frame(7)
	elif progress >= 0.68:
		_set_flight_frame(6)
	else:
		_set_flight_frame(5)

	trail_timer -= delta
	while trail_timer <= 0.0:
		_emit_trail()
		trail_timer += trail_interval

	if travelled + 0.001 >= max_distance:
		_arrive()


func _arrive() -> void:
	if state != State.FLYING:
		return
	state = State.IMPACT_HOLD
	impact_elapsed = 0.0
	_set_flight_frame(8)
	_apply_explosion()
	_release_captured()
	impacted.emit()
	if impact_hold_seconds <= 0.0:
		_begin_explosion_animation()


func _update_impact_hold(delta: float) -> void:
	impact_elapsed += delta
	if impact_elapsed + 0.0001 >= impact_hold_seconds:
		_begin_explosion_animation()


func _begin_explosion_animation() -> void:
	if state == State.EXPLODING:
		return
	state = State.EXPLODING
	explosion_elapsed = 0.0
	rotation = 0.0
	visual.scale = Vector2.ONE * explosion_visual_scale
	_set_explosion_frame(10)


func _update_explosion(delta: float) -> void:
	explosion_elapsed += delta
	var frame_offset := floori(explosion_elapsed * explosion_fps)
	if frame_offset >= 8:
		_begin_camera_restore()
		return
	_set_explosion_frame(10 + frame_offset)


func _begin_camera_flight_view() -> void:
	if not is_instance_valid(caster):
		return
	var camera_node := caster.get_node_or_null("Camera2D")
	if camera_node == null or not (camera_node is Camera2D):
		return

	_camera = camera_node as Camera2D
	_camera_original_zoom = _camera.zoom
	_camera_original_position = _camera.position
	_camera_zoom_from = _camera.zoom
	_camera_position_from = _camera.position
	_camera_zoom_elapsed = 0.0
	_camera_restore_elapsed = 0.0
	_camera_effect_active = true
	_update_camera_flight_view(0.0)


func _update_camera_flight_view(delta: float) -> void:
	if not _camera_effect_active:
		return
	if not is_instance_valid(_camera):
		_camera_effect_active = false
		return

	_camera_zoom_elapsed = minf(
		_camera_zoom_elapsed + delta,
		camera_zoom_out_seconds
	)
	var zoom_progress := 1.0
	if camera_zoom_out_seconds > 0.0001:
		zoom_progress = clampf(
			_camera_zoom_elapsed / camera_zoom_out_seconds,
			0.0,
			1.0
		)
	var zoom_eased := (
		zoom_progress
		* zoom_progress
		* (3.0 - 2.0 * zoom_progress)
	)
	var target_zoom := _camera_original_zoom * camera_zoom_multiplier
	_camera.zoom = _camera_zoom_from.lerp(target_zoom, zoom_eased)
	_camera.position = (
		_camera_original_position
		+ direction * travelled * camera_focus_ratio
	)


func _begin_camera_restore() -> void:
	if not _camera_effect_active or not is_instance_valid(_camera):
		_camera_effect_active = false
		_finish()
		return

	state = State.CAMERA_RESTORE
	_camera_zoom_from = _camera.zoom
	_camera_position_from = _camera.position
	_camera_restore_elapsed = 0.0
	visual.visible = false
	_clear_trails()

	if camera_zoom_in_seconds <= 0.0001:
		_restore_camera_immediately()
		_finish()


func _update_camera_restore(delta: float) -> void:
	if not _camera_effect_active:
		_finish()
		return
	if not is_instance_valid(_camera):
		_camera_effect_active = false
		_finish()
		return

	_camera_restore_elapsed = minf(
		_camera_restore_elapsed + delta,
		camera_zoom_in_seconds
	)
	var progress := 1.0
	if camera_zoom_in_seconds > 0.0001:
		progress = clampf(
			_camera_restore_elapsed / camera_zoom_in_seconds,
			0.0,
			1.0
		)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	_camera.zoom = _camera_zoom_from.lerp(_camera_original_zoom, eased)
	_camera.position = _camera_position_from.lerp(
		_camera_original_position,
		eased
	)

	if progress >= 1.0:
		_restore_camera_immediately()
		_finish()


func _restore_camera_immediately() -> void:
	if not _camera_effect_active:
		return
	if is_instance_valid(_camera):
		_camera.zoom = _camera_original_zoom
		_camera.position = _camera_original_position
	_camera_effect_active = false


func _capture_nearby_monsters() -> void:
	var query_owner := get_parent()
	if not is_instance_valid(query_owner):
		return
	_query_scratch.clear()
	if query_owner.has_method("fill_monsters_near"):
		query_owner.call(
			"fill_monsters_near",
			global_position,
			capture_radius,
			_query_scratch
		)
	else:
		var tree := get_tree()
		if tree != null:
			_query_scratch.append_array(tree.get_nodes_in_group("monsters"))

	var radius_sq := capture_radius * capture_radius
	for raw_node in _query_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if monster == null or not monster.is_in_group("monsters"):
			continue
		if global_position.distance_squared_to(monster.global_position) > radius_sq:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if not MONSTER_RUNTIME_COMMON.can_be_forced_moved(monster):
			continue
		var instance_id := monster.get_instance_id()
		if _captured_ids.has(instance_id):
			continue
		_captured_ids[instance_id] = true
		_captured.append(monster)
		_lock_captured_monster(monster)


func _drag_captured(movement: Vector2) -> void:
	for index in range(_captured.size() - 1, -1, -1):
		var monster := _captured[index]
		if (
			not is_instance_valid(monster)
			or monster.is_queued_for_deletion()
			or not MONSTER_RUNTIME_COMMON.can_be_forced_moved(monster)
		):
			if is_instance_valid(monster):
				_release_monster(monster)
				_captured_ids.erase(monster.get_instance_id())
			_captured.remove_at(index)
			continue

		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			_release_monster(monster)
			_captured_ids.erase(monster.get_instance_id())
			_captured.remove_at(index)
			continue

		_lock_captured_monster(monster)
		if monster is CharacterBody2D:
			(monster as CharacterBody2D).velocity = Vector2.ZERO
		monster.global_position += movement


func _lock_captured_monster(monster: Node2D) -> void:
	monster.set_meta(
		"forced_movement_lock_until",
		Time.get_ticks_msec() + 180
	)
	monster.set_meta("forced_movement_source", get_instance_id())


func _release_monster(monster: Node2D) -> void:
	if not is_instance_valid(monster):
		return
	if int(monster.get_meta("forced_movement_source", 0)) != get_instance_id():
		return
	monster.remove_meta("forced_movement_source")
	monster.remove_meta("forced_movement_lock_until")


func _release_captured() -> void:
	for monster in _captured:
		if is_instance_valid(monster):
			_release_monster(monster)
	_captured.clear()
	_captured_ids.clear()


func _apply_explosion() -> void:
	var query_owner := get_parent()
	if not is_instance_valid(query_owner):
		return

	_query_scratch.clear()
	if query_owner.has_method("fill_monsters_near"):
		query_owner.call(
			"fill_monsters_near",
			global_position,
			explosion_radius,
			_query_scratch
		)
	else:
		var tree := get_tree()
		if tree != null:
			_query_scratch.append_array(tree.get_nodes_in_group("monsters"))

	var base_attack := 1.0
	if is_instance_valid(caster):
		var attack_value = caster.get("attack_damage")
		if attack_value != null:
			base_attack = maxf(float(attack_value), 1.0)
	var raw_damage := maxf(base_attack * damage_ratio, 1.0)
	var radius_sq := explosion_radius * explosion_radius
	var slow_until := Time.get_ticks_msec() + int(round(slow_duration * 1000.0))

	for raw_node in _query_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or not monster.has_method("take_damage")
			or global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue

		var holy_multiplier := 1.0
		if (
			is_instance_valid(caster)
			and caster.has_method("get_purifier_holy_damage_multiplier")
		):
			holy_multiplier = maxf(
				float(
					caster.call(
						"get_purifier_holy_damage_multiplier",
						monster
					)
				),
				0.0
			)
		var hit_damage := maxi(
			int(round(raw_damage * holy_multiplier)),
			1
		)
		monster.call("take_damage", hit_damage)

		if (
			slow_duration <= 0.0
			or not is_instance_valid(monster)
			or monster.is_queued_for_deletion()
			or not MONSTER_RUNTIME_COMMON.can_receive_movement_slow(monster)
		):
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var current_until := int(
			monster.get_meta("movement_slow_until", 0)
		)
		var current_multiplier := float(
			monster.get_meta("movement_slow_multiplier", 1.0)
		)
		monster.set_meta(
			"movement_slow_until",
			maxi(current_until, slow_until)
		)
		monster.set_meta(
			"movement_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)


func _update_charge_aura(normalized: float) -> void:
	if not is_instance_valid(charge_aura):
		return
	var progress := clampf(normalized, 0.0, 1.0)
	var frame_count := maxi(charge_frame_last - charge_frame_first + 1, 1)
	var frame_offset := mini(
		floori(progress * float(frame_count)),
		frame_count - 1
	)
	var frame_index := charge_frame_first + frame_offset
	if frame_index != _last_charge_frame:
		_last_charge_frame = frame_index
		var path := "%s/effect_%02d.png" % [
			charge_effect_dir,
			frame_index,
		]
		var texture := _load_texture_cached(path)
		if texture != null:
			charge_aura.texture = texture

	charge_aura.global_position = global_position
	charge_aura.global_rotation = 0.0
	var gather_scale := charge_visual_scale * lerpf(0.72, 1.05, progress)
	var pulse := 1.0 + sin(progress * PI * 4.0) * 0.035
	charge_aura.scale = Vector2.ONE * gather_scale * pulse
	charge_aura.modulate = Color(
		1.0,
		1.0,
		1.0,
		lerpf(charge_alpha_start, charge_alpha_end, progress)
	)
	charge_aura.visible = true


func _build_trail_pool() -> void:
	_trail_pool.clear()
	_trail_ages.clear()
	_trail_active.clear()
	_trail_base_scales.clear()
	_trail_pool_index = 0

	for index in range(trail_pool_size):
		var ghost := Sprite2D.new()
		ghost.name = "GungnirTrail%02d" % index
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.top_level = true
		ghost.z_index = -1
		ghost.visible = false
		trail_layer.add_child(ghost)
		_trail_pool.append(ghost)
		_trail_ages.append(0.0)
		_trail_active.append(false)
		_trail_base_scales.append(Vector2.ONE)


func _emit_trail() -> void:
	if (
		state != State.FLYING
		or visual.texture == null
		or _trail_pool.is_empty()
	):
		return

	var index := _trail_pool_index
	_trail_pool_index = (_trail_pool_index + 1) % _trail_pool.size()
	var ghost := _trail_pool[index]
	ghost.texture = visual.texture
	ghost.global_position = global_position
	ghost.global_rotation = rotation
	ghost.scale = visual.scale * trail_scale_multiplier
	ghost.modulate = Color(1.0, 1.0, 1.0, trail_alpha)
	ghost.visible = true
	_trail_ages[index] = 0.0
	_trail_active[index] = true
	_trail_base_scales[index] = ghost.scale


func _update_trails(delta: float) -> void:
	if _trail_pool.is_empty():
		return

	for index in range(_trail_pool.size()):
		if not _trail_active[index]:
			continue
		var ghost := _trail_pool[index]
		if not is_instance_valid(ghost):
			_trail_active[index] = false
			continue

		var age := _trail_ages[index] + delta
		_trail_ages[index] = age
		var ratio := clampf(age / trail_lifetime, 0.0, 1.0)
		if ratio >= 1.0:
			ghost.visible = false
			_trail_active[index] = false
			continue

		var fade := 1.0 - ratio
		ghost.modulate = Color(
			1.0,
			1.0,
			1.0,
			trail_alpha * fade * fade
		)
		var base_scale := _trail_base_scales[index]
		ghost.scale = base_scale * lerpf(1.0, 0.86, ratio)


func _clear_trails() -> void:
	for index in range(_trail_pool.size()):
		var ghost := _trail_pool[index]
		if is_instance_valid(ghost):
			ghost.visible = false
		_trail_active[index] = false
		_trail_ages[index] = 0.0


func _set_cast_frame(frame_index: int) -> void:
	if frame_index == _last_cast_frame:
		return
	_last_cast_frame = frame_index
	_set_texture(frame_index)


func _set_flight_frame(frame_index: int) -> void:
	if frame_index == _last_flight_frame:
		return
	_last_flight_frame = frame_index
	visual.scale = Vector2.ONE * projectile_visual_scale
	_set_texture(frame_index)


func _set_explosion_frame(frame_index: int) -> void:
	if frame_index == _last_explosion_frame:
		return
	_last_explosion_frame = frame_index
	_set_texture(frame_index)


func _set_texture(frame_index: int) -> void:
	var path := "%s/frame_%02d.png" % [effect_dir, frame_index]
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
	if state == State.DONE:
		return
	state = State.DONE
	_restore_camera_immediately()
	_release_captured()
	_clear_trails()
	if is_instance_valid(charge_aura):
		charge_aura.visible = false
	set_physics_process(false)
	finished.emit()
	queue_free()


func _exit_tree() -> void:
	_restore_camera_immediately()
	_release_captured()
	_clear_trails()
