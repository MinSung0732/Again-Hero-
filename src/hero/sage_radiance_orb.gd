extends Area2D

const EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect3"
const POOL_KEY := "sage_radiance_orb"
const CREATE_FPS := 14.0
const EXPLOSION_FPS := 15.0

static var _frames_cache: SpriteFrames

enum OrbState {
	INACTIVE,
	TRAVEL,
	WAIT,
	EXPLODE,
}

var state: int = OrbState.INACTIVE
var destination: Vector2 = Vector2.ZERO
var speed: float = 350.0
var wait_remaining: float = 1.0
var explosion_radius: float = 50.0
var damage: int = 1
var slow_multiplier: float = 0.85
var slow_duration: float = 2.0
var caster: Node2D
var tracked_target: Node2D

@onready var visual: AnimatedSprite2D = $Visual
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_shape: CollisionShape2D = $ExplosionArea/CollisionShape2D
@onready var explosion_audio: AudioStreamPlayer2D = $ExplosionAudio


func _ready() -> void:
	_build_frames()
	visual.animation_finished.connect(_on_animation_finished)
	deactivate_for_pool()


func setup(
	new_destination: Vector2,
	new_speed: float,
	new_arrival_delay: float,
	new_explosion_radius: float,
	new_damage: int,
	new_slow_multiplier: float,
	new_slow_duration: float,
	new_visual_scale: float,
	caster_node: Node2D,
	new_tracked_target: Node2D = null
) -> void:
	_build_frames()
	destination = new_destination
	speed = maxf(new_speed, 1.0)
	wait_remaining = maxf(new_arrival_delay, 0.0)
	explosion_radius = maxf(new_explosion_radius, 1.0)
	damage = maxi(new_damage, 1)
	slow_multiplier = clampf(new_slow_multiplier, 0.1, 1.0)
	slow_duration = maxf(new_slow_duration, 0.0)
	caster = caster_node
	tracked_target = new_tracked_target
	_set_explosion_radius(explosion_radius)

	state = OrbState.TRAVEL
	visible = true
	set_physics_process(true)
	visual.visible = true
	visual.scale = Vector2.ONE * clampf(new_visual_scale, 0.05, 4.0)
	visual.stop()
	visual.animation = &"create"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"create")
	explosion_area.set_deferred("monitoring", true)
	if is_instance_valid(explosion_audio):
		explosion_audio.stop()
	queue_redraw()


func _physics_process(delta: float) -> void:
	match state:
		OrbState.TRAVEL:
			if (
				is_instance_valid(tracked_target)
				and not tracked_target.is_queued_for_deletion()
			):
				destination = tracked_target.global_position
			var offset := destination - global_position
			var step := speed * delta
			if offset.length_squared() <= step * step:
				global_position = destination
				state = OrbState.WAIT
			else:
				global_position += offset.normalized() * step
		OrbState.WAIT:
			wait_remaining = maxf(wait_remaining - delta, 0.0)
			if wait_remaining <= 0.0:
				_explode()
		_:
			pass


func _explode() -> void:
	if state == OrbState.EXPLODE or state == OrbState.INACTIVE:
		return
	state = OrbState.EXPLODE
	set_physics_process(false)
	for body in explosion_area.get_overlapping_bodies():
		if not _is_valid_monster(body):
			continue
		if body.has_method("take_damage"):
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
		_apply_slow(body)

	if is_instance_valid(explosion_audio) and explosion_audio.stream != null:
		explosion_audio.stop()
		explosion_audio.play()

	visual.stop()
	visual.animation = &"explode"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.play(&"explode")
	queue_redraw()


func _apply_slow(body: Node) -> void:
	if not _is_valid_monster(body):
		return
	var now_msec := Time.get_ticks_msec()
	var until_msec := now_msec + int(round(slow_duration * 1000.0))
	var current_until := int(body.get_meta("sage_radiance_slow_until", 0))
	body.set_meta("sage_radiance_slow_until", maxi(current_until, until_msec))
	body.set_meta(
		"sage_radiance_slow_multiplier",
		minf(
			float(body.get_meta("sage_radiance_slow_multiplier", 1.0))
				if current_until > now_msec
				else 1.0,
			slow_multiplier
		)
	)


func _is_valid_monster(body: Node) -> bool:
	return (
		body != null
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and body.is_in_group("monsters")
	)


func _on_animation_finished() -> void:
	if state == OrbState.INACTIVE:
		return
	if visual.animation == &"create":
		visual.play(&"hold")
	elif visual.animation == &"explode":
		visual.visible = false
		queue_redraw()
		if is_instance_valid(explosion_audio) and explosion_audio.playing:
			var finished_callable := Callable(self, "_finish")
			if not explosion_audio.finished.is_connected(finished_callable):
				explosion_audio.finished.connect(
					finished_callable,
					Object.CONNECT_ONE_SHOT
				)
		else:
			_finish()


func _finish() -> void:
	state = OrbState.INACTIVE
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	caster = null
	tracked_target = null
	state = OrbState.INACTIVE
	set_physics_process(false)
	visible = false
	if is_instance_valid(visual):
		visual.stop()
		visual.visible = false
	if is_instance_valid(explosion_area):
		explosion_area.set_deferred("monitoring", false)
	queue_redraw()


func _draw() -> void:
	if state == OrbState.INACTIVE or state == OrbState.EXPLODE:
		return
	draw_arc(
		Vector2.ZERO,
		explosion_radius,
		0.0,
		TAU,
		48,
		Color(1.0, 0.88, 0.42, 0.72),
		1.5,
		true
	)


func _set_explosion_radius(radius: float) -> void:
	var circle := explosion_shape.shape as CircleShape2D
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
			_add_frame(frames, &"create", "%s/starburst_%02d.png" % [EFFECT_DIR, frame_index])

		frames.add_animation(&"hold")
		frames.set_animation_loop(&"hold", true)
		frames.set_animation_speed(&"hold", 1.0)
		_add_frame(frames, &"hold", "%s/starburst_04.png" % EFFECT_DIR)

		frames.add_animation(&"explode")
		frames.set_animation_loop(&"explode", false)
		frames.set_animation_speed(&"explode", EXPLOSION_FPS)
		for frame_index in [5, 6, 7, 8, 9, 10]:
			_add_frame(frames, &"explode", "%s/starburst_%02d.png" % [EFFECT_DIR, frame_index])

		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _add_frame(frames: SpriteFrames, animation_name: StringName, path: String) -> void:
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			frames.add_frame(animation_name, texture)
