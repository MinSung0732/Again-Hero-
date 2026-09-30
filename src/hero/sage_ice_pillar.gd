extends Area2D

const EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect1"
const POOL_KEY := "sage_ice_pillar"
const CREATE_FPS := 12.0
const DESTROY_FPS := 15.0
const VISUAL_SCALE := 0.55
const SLOW_REFRESH_INTERVAL := 0.10
const SLOW_REFRESH_DURATION_MSEC := 180

static var _frames_cache: SpriteFrames

var active: bool = false
var pillar_active: bool = false
var destroying: bool = false
var damage: int = 1
var duration: float = 4.0
var active_remaining: float = 0.0
var effect_radius: float = 125.0
var slow_multiplier: float = 0.80
var collision_radius: float = 34.0
var effect_end_msec: int = 0
var initial_damage_ids: Dictionary = {}
var slowed_bodies: Dictionary = {}
var slow_refresh_timer: float = 0.0
var caster: Node2D

@onready var visual: AnimatedSprite2D = $Visual
@onready var obstacle_shape: CollisionShape2D = $Obstacle/CollisionShape2D
@onready var effect_area: Area2D = $EffectArea
@onready var effect_shape: CollisionShape2D = $EffectArea/CollisionShape2D
@onready var trap_area: Area2D = $TrapArea
@onready var trap_shape: CollisionShape2D = $TrapArea/CollisionShape2D


func _ready() -> void:
	_build_frames()
	effect_area.body_entered.connect(_on_effect_body_entered)
	effect_area.body_exited.connect(_on_effect_body_exited)
	trap_area.body_entered.connect(_on_trap_body_entered)
	visual.animation_finished.connect(_on_visual_animation_finished)
	deactivate_for_pool()


func setup(
	new_damage: int,
	new_duration: float,
	new_effect_radius: float,
	new_slow_multiplier: float,
	new_collision_radius: float,
	caster_node: Node2D
) -> void:
	_build_frames()
	active = true
	pillar_active = false
	destroying = false
	damage = maxi(new_damage, 1)
	duration = maxf(new_duration, 0.1)
	active_remaining = 0.0
	effect_radius = maxf(new_effect_radius, 1.0)
	slow_multiplier = clampf(new_slow_multiplier, 0.1, 1.0)
	collision_radius = maxf(new_collision_radius, 8.0)
	caster = caster_node
	initial_damage_ids.clear()
	slowed_bodies.clear()
	slow_refresh_timer = 0.0
	visible = true
	set_process(true)
	effect_area.monitoring = false
	trap_area.monitoring = false
	obstacle_shape.set_deferred("disabled", true)
	_set_circle_radius(effect_shape, effect_radius)
	_set_circle_radius(trap_shape, collision_radius)
	var rectangle := obstacle_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle.size = Vector2(collision_radius * 2.0, collision_radius * 1.55)
	visual.visible = true
	visual.stop()
	visual.animation = &"create"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"create")
	queue_redraw()


func _process(delta: float) -> void:
	if not active or not pillar_active:
		return

	slow_refresh_timer = maxf(slow_refresh_timer - delta, 0.0)
	if slow_refresh_timer <= 0.0:
		slow_refresh_timer = SLOW_REFRESH_INTERVAL
		_refresh_slowed_bodies()

	if destroying:
		return

	active_remaining = maxf(active_remaining - delta, 0.0)
	if active_remaining <= 0.0:
		_begin_destroy()


func _activate_pillar() -> void:
	if not active or pillar_active:
		return
	pillar_active = true
	active_remaining = duration
	var destroy_tail_msec := int(ceil(4.0 / DESTROY_FPS * 1000.0))
	effect_end_msec = Time.get_ticks_msec() + int(ceil(duration * 1000.0)) + destroy_tail_msec
	obstacle_shape.set_deferred("disabled", false)
	effect_area.set_deferred("monitoring", true)
	trap_area.set_deferred("monitoring", true)
	visual.play(&"hold")
	queue_redraw()
	_apply_initial_overlaps_after_physics()


func _apply_initial_overlaps_after_physics() -> void:
	await get_tree().physics_frame
	if not active or not pillar_active:
		return
	for body in effect_area.get_overlapping_bodies():
		_track_slow_target(body)
		_apply_initial_damage(body)
	for body in trap_area.get_overlapping_bodies():
		_apply_root(body)


func _on_effect_body_entered(body: Node) -> void:
	_track_slow_target(body)


func _on_effect_body_exited(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	slowed_bodies.erase(body.get_instance_id())


func _on_trap_body_entered(body: Node) -> void:
	_apply_root(body)


func _apply_initial_damage(body: Node) -> void:
	if not _is_valid_monster(body) or not body.has_method("take_damage"):
		return
	var instance_id := body.get_instance_id()
	if initial_damage_ids.has(instance_id):
		return
	initial_damage_ids[instance_id] = true
	var hit_position := (
		(body as Node2D).global_position
		if body is Node2D
		else global_position
	)
	body.call("take_damage", damage)
	if (
		is_instance_valid(caster)
		and caster.has_method("_on_sage_skill_hit")
	):
		caster.call("_on_sage_skill_hit", hit_position)


func _track_slow_target(body: Node) -> void:
	if not _is_valid_monster(body):
		return
	slowed_bodies[body.get_instance_id()] = body
	_refresh_slow(body)


func _refresh_slowed_bodies() -> void:
	if not is_instance_valid(effect_area) or not effect_area.monitoring:
		return

	# Physics overlap is the source of truth. This catches enemies that enter,
	# remain, or were already inside when the pillar became active without
	# scanning the global monster group.
	slowed_bodies.clear()
	for body in effect_area.get_overlapping_bodies():
		if not _is_valid_monster(body):
			continue
		slowed_bodies[body.get_instance_id()] = body
		_refresh_slow(body)


func _refresh_slow(body: Node) -> void:
	if not _is_valid_monster(body):
		return
	var now_msec := Time.get_ticks_msec()
	body.set_meta(
		"sage_ice_slow_until",
		now_msec + SLOW_REFRESH_DURATION_MSEC
	)
	body.set_meta("sage_ice_slow_multiplier", slow_multiplier)
	body.set_meta("sage_ice_slow_source", get_instance_id())


func _apply_root(body: Node) -> void:
	if not _is_valid_monster(body):
		return
	var current_until := int(body.get_meta("sage_ice_root_until", 0))
	body.set_meta("sage_ice_root_until", maxi(current_until, effect_end_msec))


func _is_valid_monster(body: Node) -> bool:
	return (
		active
		and body != null
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and body.is_in_group("monsters")
	)


func _begin_destroy() -> void:
	if not active or destroying:
		return
	destroying = true
	visual.stop()
	visual.animation = &"destroy"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"destroy")


func _on_visual_animation_finished() -> void:
	if not active:
		return
	if visual.animation == &"create":
		_activate_pillar()
	elif visual.animation == &"destroy":
		_finish_pillar()


func _finish_pillar() -> void:
	if not active:
		return
	# Keep collision and roots through the destroy frames; release only when
	# ice_08 has finished and the pillar has visually disappeared.
	effect_area.set_deferred("monitoring", false)
	trap_area.set_deferred("monitoring", false)
	obstacle_shape.set_deferred("disabled", true)
	slowed_bodies.clear()
	active = false
	pillar_active = false
	destroying = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	caster = null
	active = false
	pillar_active = false
	destroying = false
	active_remaining = 0.0
	effect_end_msec = 0
	initial_damage_ids.clear()
	slowed_bodies.clear()
	slow_refresh_timer = 0.0
	set_process(false)
	visible = false
	if is_instance_valid(visual):
		visual.stop()
		visual.visible = false
	if is_instance_valid(effect_area):
		effect_area.set_deferred("monitoring", false)
	if is_instance_valid(trap_area):
		trap_area.set_deferred("monitoring", false)
	if is_instance_valid(obstacle_shape):
		obstacle_shape.set_deferred("disabled", true)
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	draw_arc(
		Vector2.ZERO,
		effect_radius,
		0.0,
		TAU,
		64,
		Color(0.45, 0.82, 1.0, 0.72),
		1.5,
		true
	)


func _set_circle_radius(shape_node: CollisionShape2D, radius: float) -> void:
	var circle := shape_node.shape as CircleShape2D
	if circle != null:
		circle.radius = radius


func _build_frames() -> void:
	if _frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")

		frames.add_animation(&"create")
		frames.set_animation_loop(&"create", false)
		frames.set_animation_speed(&"create", CREATE_FPS)
		for frame_index in [1, 2, 3, 4]:
			_add_frame(frames, &"create", "%s/ice_%02d.png" % [EFFECT_DIR, frame_index])

		frames.add_animation(&"hold")
		frames.set_animation_loop(&"hold", true)
		frames.set_animation_speed(&"hold", 1.0)
		_add_frame(frames, &"hold", "%s/ice_04.png" % EFFECT_DIR)

		frames.add_animation(&"destroy")
		frames.set_animation_loop(&"destroy", false)
		frames.set_animation_speed(&"destroy", DESTROY_FPS)
		for frame_index in [5, 6, 7, 8]:
			_add_frame(frames, &"destroy", "%s/ice_%02d.png" % [EFFECT_DIR, frame_index])

		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * VISUAL_SCALE


func _add_frame(frames: SpriteFrames, animation_name: StringName, path: String) -> void:
	var texture := _load_texture_direct(path)
	if texture != null:
		frames.add_frame(animation_name, texture)


func _load_texture_direct(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var png_bytes := file.get_buffer(file.get_length())
	if png_bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(png_bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)
