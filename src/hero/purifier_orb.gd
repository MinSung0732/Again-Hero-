extends Node2D

signal settled(orb: Node2D)
signal deactivated(orb: Node2D)
signal finished(orb: Node2D)

static var _frames_cache: Dictionary = {}

var source_hero: Node = null
var target_position: Vector2 = Vector2.ZERO
var projectile_speed: float = 380.0
var lifetime_remaining: float = 50.0
var blast_radius: float = 275.0
var install_index: int = 0
var _traveling: bool = false
var _network_active: bool = false
var _chain_reserved: bool = false
var _ending: bool = false

@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("hero_projectiles")
	visual.animation_finished.connect(_on_visual_animation_finished)


func setup(
	new_source_hero: Node,
	start_position: Vector2,
	destination: Vector2,
	new_projectile_speed: float,
	duration: float,
	new_blast_radius: float,
	new_install_index: int,
	effect_dir: String,
	visual_scale: float = 0.45
) -> void:
	source_hero = new_source_hero
	global_position = start_position
	target_position = destination
	projectile_speed = maxf(new_projectile_speed, 1.0)
	lifetime_remaining = maxf(duration, 0.1)
	blast_radius = maxf(new_blast_radius, 1.0)
	install_index = new_install_index
	_traveling = true
	_network_active = false
	_chain_reserved = false
	_ending = false

	visual.sprite_frames = _get_or_build_frames(effect_dir)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * maxf(visual_scale, 0.05)
	visual.visible = true
	if visual.sprite_frames != null and visual.sprite_frames.has_animation(&"spawn"):
		visual.play(&"spawn")
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _ending:
		return

	if _traveling:
		var distance := global_position.distance_to(target_position)
		var step_distance := projectile_speed * delta
		if distance <= step_distance + 0.001:
			global_position = target_position
			_settle()
		else:
			global_position = global_position.move_toward(
				target_position,
				step_distance
			)
		return

	if _network_active and not _chain_reserved:
		lifetime_remaining = maxf(lifetime_remaining - delta, 0.0)
		if lifetime_remaining <= 0.0:
			expire_without_damage()


func _settle() -> void:
	if _ending or _network_active:
		return
	_traveling = false
	_network_active = true
	if (
		visual.sprite_frames != null
		and visual.sprite_frames.has_animation(&"idle")
	):
		visual.play(&"idle")
	queue_redraw()
	settled.emit(self)


func reserve_for_chain() -> void:
	if _network_active and not _ending:
		_chain_reserved = true


func is_network_active() -> bool:
	return _network_active and not _ending


func get_install_index() -> int:
	return install_index


func trigger_explosion() -> void:
	if _ending:
		return
	_begin_end()


func expire_without_damage() -> void:
	if _ending:
		return
	_begin_end()


func _begin_end() -> void:
	_ending = true
	_traveling = false
	_network_active = false
	_chain_reserved = false
	set_physics_process(false)
	queue_redraw()
	deactivated.emit(self)

	if (
		visual.sprite_frames != null
		and visual.sprite_frames.has_animation(&"end")
		and visual.sprite_frames.get_frame_count(&"end") > 0
	):
		visual.stop()
		visual.frame = 0
		visual.frame_progress = 0.0
		visual.play(&"end")
	else:
		_finish()


func _finish() -> void:
	if not is_inside_tree():
		return
	finished.emit(self)
	queue_free()


func _on_visual_animation_finished() -> void:
	if _ending and visual.animation == &"end":
		_finish()


func _draw() -> void:
	if not _network_active or _ending:
		return
	draw_arc(
		Vector2.ZERO,
		blast_radius,
		0.0,
		TAU,
		96,
		Color(1.0, 0.88, 0.42, 0.58),
		2.0,
		false
	)


static func _get_or_build_frames(effect_dir: String) -> SpriteFrames:
	var cached = _frames_cache.get(effect_dir)
	if cached is SpriteFrames:
		return cached

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"spawn")
	frames.set_animation_loop(&"spawn", false)
	frames.set_animation_speed(&"spawn", 12.0)
	for frame_index in [11, 12, 13, 14]:
		var texture := _load_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"spawn", texture)

	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 7.0)
	for frame_index in [13, 14]:
		var texture := _load_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"idle", texture)

	frames.add_animation(&"end")
	frames.set_animation_loop(&"end", false)
	frames.set_animation_speed(&"end", 12.0)
	for frame_index in [13, 12, 11, 15, 16]:
		var texture := _load_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"end", texture)

	_frames_cache[effect_dir] = frames
	return frames


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var loaded = load(path)
	return loaded as Texture2D
