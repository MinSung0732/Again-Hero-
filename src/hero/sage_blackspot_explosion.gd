extends Node2D

const EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect9"
const POOL_KEY := "sage_blackspot_explosion"
const FIRST_FRAME := 1
const FRAME_COUNT := 8
const DAMAGE_FRAME := 4

static var _texture_cache: Dictionary = {}

enum State {
	INACTIVE,
	ANIMATING,
	AUDIO_TAIL,
}

var state: int = State.INACTIVE
var caster: Node2D
var damage: int = 1
var explosion_radius: float = 75.0
var explosion_fps: float = 14.0
var visual_scale: float = 0.34
var elapsed: float = 0.0
var damage_applied: bool = false
var _last_frame: int = -1
var _query_scratch: Array = []

@onready var visual: Sprite2D = $Visual
@onready var explosion_audio: AudioStreamPlayer2D = $ExplosionAudio


func _ready() -> void:
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deactivate_for_pool()


func setup(
	caster_node: Node2D,
	new_damage: int,
	new_explosion_radius: float,
	new_explosion_fps: float,
	new_visual_scale: float
) -> void:
	caster = caster_node
	damage = maxi(new_damage, 1)
	explosion_radius = maxf(new_explosion_radius, 1.0)
	explosion_fps = maxf(new_explosion_fps, 1.0)
	visual_scale = maxf(new_visual_scale, 0.05)
	elapsed = 0.0
	damage_applied = false
	_last_frame = -1
	state = State.ANIMATING
	visible = true
	set_physics_process(true)
	visual.visible = true
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE * visual_scale
	_set_frame(FIRST_FRAME)
	if is_instance_valid(explosion_audio):
		explosion_audio.stop()
		explosion_audio.stream_paused = false
		explosion_audio.pitch_scale = randf_range(0.94, 1.04)


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE:
		return

	var paused := _is_combat_simulation_paused()
	if is_instance_valid(explosion_audio):
		explosion_audio.stream_paused = paused
	if paused:
		return

	if state == State.AUDIO_TAIL:
		if not is_instance_valid(explosion_audio) or not explosion_audio.playing:
			_finish()
		return

	elapsed += delta
	var frame_offset := floori(elapsed * explosion_fps)
	var frame_index := FIRST_FRAME + mini(frame_offset, FRAME_COUNT - 1)
	_set_frame(frame_index)

	if not damage_applied and frame_index >= DAMAGE_FRAME:
		damage_applied = true
		_apply_damage()
		if is_instance_valid(explosion_audio) and explosion_audio.stream != null:
			explosion_audio.stop()
			explosion_audio.play()

	if frame_offset >= FRAME_COUNT:
		visual.visible = false
		if is_instance_valid(explosion_audio) and explosion_audio.playing:
			state = State.AUDIO_TAIL
		else:
			_finish()


func _is_combat_simulation_paused() -> bool:
	var battle := get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("is_combat_simulation_paused")
	):
		return bool(battle.call("is_combat_simulation_paused"))
	return false


func _apply_damage() -> void:
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
			_query_scratch.append_array(
				tree.get_nodes_in_group("monsters")
			)

	var radius_sq := explosion_radius * explosion_radius
	for raw_node in _query_scratch:
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

		var hp_before_value = monster.get("current_hp")
		var hp_before := (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		if hp_before == 0:
			continue

		# Hard recursion barrier: this damage path never calls the caster's
		# skill-hit hook, so Black Spot Explosion cannot re-ignite itself.
		monster.call("take_damage", damage)

		if hp_before <= 0:
			continue
		var killed := false
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if (
			killed
			and is_instance_valid(caster)
			and caster.has_method("_on_sage_blackspot_kill")
		):
			caster.call("_on_sage_blackspot_kill")

	_query_scratch.clear()


func _set_frame(frame_index: int) -> void:
	if frame_index == _last_frame:
		return
	_last_frame = frame_index
	var path := "%s/stage10_effect4_%02d.png" % [
		EFFECT_DIR,
		frame_index,
	]
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
	if (
		is_instance_valid(parent)
		and parent.has_method("recycle_projectile")
	):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	state = State.INACTIVE
	set_physics_process(false)
	visible = false
	caster = null
	elapsed = 0.0
	damage_applied = false
	_last_frame = -1
	_query_scratch.clear()
	if is_instance_valid(visual):
		visual.visible = false
		visual.position = Vector2.ZERO
	if is_instance_valid(explosion_audio):
		explosion_audio.stop()
		explosion_audio.stream_paused = false
