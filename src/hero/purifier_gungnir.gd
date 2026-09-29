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
	DONE,
}

static var _texture_cache: Dictionary = {}

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
	state = State.CASTING
	cast_elapsed = 0.0
	travelled = 0.0
	_set_cast_frame(1)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	match state:
		State.CASTING:
			_update_casting(delta)
		State.FLYING:
			_update_flying(delta)
		State.IMPACT_HOLD:
			_update_impact_hold(delta)
		State.EXPLODING:
			_update_explosion(delta)
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

	if cast_elapsed + 0.0001 >= cast_seconds:
		_begin_flight()


func _begin_flight() -> void:
	if state != State.CASTING:
		return
	state = State.FLYING
	_set_flight_frame(5)
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

	_drag_captured(movement)
	_capture_nearby_monsters()

	var progress := clampf(travelled / max_distance, 0.0, 1.0)
	if progress >= 0.86:
		_set_flight_frame(7)
	elif progress >= 0.68:
		_set_flight_frame(6)
	else:
		_set_flight_frame(5)

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
		_finish()
		return
	_set_explosion_frame(10 + frame_offset)


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
	_release_captured()
	set_physics_process(false)
	finished.emit()
	queue_free()


func _exit_tree() -> void:
	_release_captured()
