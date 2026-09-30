extends Area2D

const EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect7"
const POOL_KEY := "sage_starlight_meteor"
const FALL_FIRST_FRAME := 2
const FALL_FRAME_COUNT := 3
const EXPLOSION_FIRST_FRAME := 5
const EXPLOSION_FRAME_COUNT := 4

static var _texture_cache: Dictionary = {}

enum MeteorState {
	INACTIVE,
	FALLING,
	EXPLODING,
	AUDIO_TAIL,
}

var state: int = MeteorState.INACTIVE
var damage: int = 1
var impact_radius: float = 100.0
var fall_duration: float = 0.58
var explosion_fps: float = 14.0
var fall_elapsed: float = 0.0
var explosion_elapsed: float = 0.0
var fall_origin: Vector2 = Vector2(0.0, -430.0)
var _query_scratch: Array = []
var caster: Node2D

@onready var visual: Sprite2D = $Visual
@onready var explosion_audio: AudioStreamPlayer2D = $ExplosionAudio


func _ready() -> void:
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deactivate_for_pool()


func setup(
	new_damage: int,
	new_impact_radius: float,
	new_fall_duration: float,
	new_visual_scale: float,
	new_fall_height: float,
	new_fall_side_offset: float,
	new_explosion_fps: float,
	caster_node: Node2D
) -> void:
	damage = maxi(new_damage, 1)
	impact_radius = maxf(new_impact_radius, 1.0)
	fall_duration = maxf(new_fall_duration, 0.05)
	explosion_fps = maxf(new_explosion_fps, 1.0)
	caster = caster_node
	fall_elapsed = 0.0
	explosion_elapsed = 0.0
	var side_offset := maxf(absf(new_fall_side_offset), 0.0)
	fall_origin = Vector2(
		randf_range(side_offset * 0.85, side_offset * 1.15),
		-maxf(new_fall_height, 40.0)
	)

	state = MeteorState.FALLING
	visible = true
	set_physics_process(true)
	visual.visible = true
	visual.position = fall_origin
	visual.scale = Vector2.ONE * maxf(new_visual_scale, 0.05)
	_set_texture(FALL_FIRST_FRAME)

	if is_instance_valid(explosion_audio):
		explosion_audio.stop()
		explosion_audio.pitch_scale = randf_range(0.96, 1.04)
	queue_redraw()


func _physics_process(delta: float) -> void:
	match state:
		MeteorState.FALLING:
			_update_fall(delta)
		MeteorState.EXPLODING:
			_update_explosion(delta)
		_:
			pass


func _update_fall(delta: float) -> void:
	fall_elapsed = minf(fall_elapsed + delta, fall_duration)
	var progress := clampf(fall_elapsed / fall_duration, 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	visual.position = fall_origin.lerp(Vector2.ZERO, eased)

	var frame_offset := mini(
		floori(progress * float(FALL_FRAME_COUNT)),
		FALL_FRAME_COUNT - 1
	)
	_set_texture(FALL_FIRST_FRAME + frame_offset)
	queue_redraw()

	if fall_elapsed + 0.0001 >= fall_duration:
		_impact()


func _impact() -> void:
	if state != MeteorState.FALLING:
		return

	state = MeteorState.EXPLODING
	explosion_elapsed = 0.0
	visual.position = Vector2.ZERO
	_set_texture(EXPLOSION_FIRST_FRAME)
	_apply_damage()

	if is_instance_valid(explosion_audio) and explosion_audio.stream != null:
		explosion_audio.stop()
		explosion_audio.play()
	queue_redraw()


func _update_explosion(delta: float) -> void:
	explosion_elapsed += delta
	var frame_offset := floori(explosion_elapsed * explosion_fps)
	if frame_offset >= EXPLOSION_FRAME_COUNT:
		visual.visible = false
		queue_redraw()
		if is_instance_valid(explosion_audio) and explosion_audio.playing:
			state = MeteorState.AUDIO_TAIL
			set_physics_process(false)
			var finished_callable := Callable(self, "_finish")
			if not explosion_audio.finished.is_connected(finished_callable):
				explosion_audio.finished.connect(
					finished_callable,
					Object.CONNECT_ONE_SHOT
				)
		else:
			_finish()
		return

	_set_texture(EXPLOSION_FIRST_FRAME + frame_offset)


func _apply_damage() -> void:
	var query_owner := get_parent()
	if not is_instance_valid(query_owner):
		return

	_query_scratch.clear()
	if query_owner.has_method("fill_monsters_near"):
		query_owner.call(
			"fill_monsters_near",
			global_position,
			impact_radius,
			_query_scratch
		)
	else:
		var tree := get_tree()
		if tree != null:
			_query_scratch.append_array(tree.get_nodes_in_group("monsters"))

	var radius_sq := impact_radius * impact_radius
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
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var hit_position := monster.global_position
		monster.call("take_damage", damage)
		if (
			is_instance_valid(caster)
			and caster.has_method("_on_sage_skill_hit")
		):
			caster.call("_on_sage_skill_hit", hit_position)
	_query_scratch.clear()


func _draw() -> void:
	if state != MeteorState.FALLING:
		return
	var progress := clampf(fall_elapsed / fall_duration, 0.0, 1.0)
	draw_arc(
		Vector2.ZERO,
		impact_radius,
		0.0,
		TAU,
		48,
		Color(0.90, 0.80, 1.0, lerpf(0.38, 0.86, progress)),
		1.5,
		true
	)


func _set_texture(frame_index: int) -> void:
	var path := "%s/stage10_effect2_%02d.png" % [EFFECT_DIR, frame_index]
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
	if state == MeteorState.INACTIVE:
		return
	state = MeteorState.INACTIVE
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	state = MeteorState.INACTIVE
	set_physics_process(false)
	visible = false
	caster = null
	_query_scratch.clear()
	if is_instance_valid(visual):
		visual.visible = false
		visual.position = Vector2.ZERO
	if is_instance_valid(explosion_audio):
		explosion_audio.stop()
	queue_redraw()
