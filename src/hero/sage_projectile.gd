extends Area2D

enum ProjectileMode {
	BASIC,
	PIERCING,
}

const BASIC_EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect2"
const PIERCING_EFFECT_DIR := "res://assets/art/heroes/stage10_sage/frames/effect5"
const BASIC_POOL_KEY := "sage_basic_projectile"
const PIERCING_POOL_KEY := "sage_piercing_projectile"
const BASIC_FLY_FPS := 16.0
const BASIC_IMPACT_FPS := 18.0
const PIERCING_FLY_FPS := 15.0
const PIERCING_EXPIRE_FPS := 15.0

static var _basic_frames_cache: SpriteFrames
static var _piercing_frames_cache: SpriteFrames
static var _chest_nodes_cache: Array = []
static var _chest_nodes_cache_physics_frame: int = -1

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var speed: float = 800.0
var max_range: float = 650.0
var traveled_distance: float = 0.0
var projectile_mode: int = ProjectileMode.BASIC
var active: bool = false
var expiring: bool = false
var visual_diameter: float = 44.0
var hit_ids: Dictionary = {}
var caster: Node2D

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("hero_projectiles")
	var local_shape := CircleShape2D.new()
	local_shape.radius = 22.0
	collision_shape.shape = local_shape
	body_entered.connect(_on_body_entered)
	projectile_sprite.animation_finished.connect(_on_animation_finished)
	visible = false
	set_physics_process(false)


func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_mode: int,
	new_diameter: float,
	caster_node: Node2D
) -> void:
	active = true
	expiring = false
	visible = true
	set_physics_process(true)
	monitoring = true
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	direction = new_direction.normalized() if new_direction.length_squared() > 0.001 else Vector2.RIGHT
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	projectile_mode = clampi(new_mode, ProjectileMode.BASIC, ProjectileMode.PIERCING)
	visual_diameter = maxf(new_diameter, 2.0)
	caster = caster_node
	traveled_distance = 0.0
	hit_ids.clear()
	rotation = direction.angle()
	_set_collision_diameter(visual_diameter)
	_apply_visual()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var previous_position := global_position
	var travel_step := speed * delta
	global_position += direction * travel_step
	traveled_distance += travel_step
	if _check_chest_sweep(previous_position, global_position):
		return
	if projectile_mode == ProjectileMode.PIERCING:
		var expire_duration := 5.0 / PIERCING_EXPIRE_FPS
		var expire_start := maxf(max_range - speed * expire_duration, 0.0)
		if not expiring and traveled_distance >= expire_start:
			_begin_piercing_expire()
		if traveled_distance >= max_range:
			set_physics_process(false)
			monitoring = false
			if not expiring:
				_begin_piercing_expire()
		return
	if traveled_distance >= max_range:
		_finish_projectile()


func _get_chest_nodes_cached() -> Array:
	var physics_frame := Engine.get_physics_frames()
	if physics_frame != _chest_nodes_cache_physics_frame:
		_chest_nodes_cache = get_tree().get_nodes_in_group("treasure_chests")
		_chest_nodes_cache_physics_frame = physics_frame
	return _chest_nodes_cache


func _check_chest_sweep(from_position: Vector2, to_position: Vector2) -> bool:
	for node in _get_chest_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		var sweep_radius := maxf(36.0, visual_diameter * 0.5)
		if _distance_squared_to_segment(chest.global_position, from_position, to_position) > sweep_radius * sweep_radius:
			continue
		if not _try_hit_target(chest):
			continue
		# Piercing shots continue through chests just like monsters; the basic
		# shot stops and plays its normal impact animation.
		return projectile_mode == ProjectileMode.BASIC
	return false


func _distance_squared_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_squared_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_squared_to(a + segment * t)


func _on_body_entered(body: Node) -> void:
	_try_hit_target(body)


func _try_hit_target(body: Node) -> bool:
	if not active or body == null or body.is_queued_for_deletion():
		return false
	if not (body.is_in_group("monsters") or body.is_in_group("treasure_chests")) or not body.has_method("take_damage"):
		return false
	var instance_id := body.get_instance_id()
	if hit_ids.has(instance_id):
		return false
	hit_ids[instance_id] = true
	var hit_position := (
		(body as Node2D).global_position
		if body is Node2D
		else global_position
	)
	body.call("take_damage", damage)
	if (
		projectile_mode == ProjectileMode.PIERCING
		and body.is_in_group("monsters")
		and is_instance_valid(caster)
		and caster.has_method("_on_sage_skill_hit")
	):
		caster.call("_on_sage_skill_hit", hit_position)
	if projectile_mode == ProjectileMode.BASIC:
		set_physics_process(false)
		monitoring = false
		projectile_sprite.stop()
		projectile_sprite.play(&"impact")
	return true


func _begin_piercing_expire() -> void:
	if not active or projectile_mode != ProjectileMode.PIERCING or expiring:
		return
	expiring = true
	projectile_sprite.stop()
	projectile_sprite.play(&"expire")


func _on_animation_finished() -> void:
	if not active:
		return
	if projectile_mode == ProjectileMode.BASIC:
		if projectile_sprite.animation == &"launch":
			projectile_sprite.play(&"hold")
		elif projectile_sprite.animation == &"impact":
			_finish_projectile()
		return
	if projectile_sprite.animation == &"launch" and not expiring:
		projectile_sprite.play(&"hold")
	elif projectile_sprite.animation == &"expire":
		_finish_projectile()


func _finish_projectile() -> void:
	if not active:
		return
	active = false
	var pool_key := PIERCING_POOL_KEY if projectile_mode == ProjectileMode.PIERCING else BASIC_POOL_KEY
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, pool_key)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	active = false
	expiring = false
	traveled_distance = 0.0
	hit_ids.clear()
	direction = Vector2.RIGHT
	caster = null
	monitoring = false
	set_physics_process(false)
	visible = false
	projectile_sprite.stop()
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")


func _set_collision_diameter(diameter: float) -> void:
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = maxf(diameter * 0.5, 1.0)


func _apply_visual() -> void:
	var frames := _get_piercing_frames() if projectile_mode == ProjectileMode.PIERCING else _get_basic_frames()
	projectile_sprite.sprite_frames = frames
	projectile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	projectile_sprite.visible = true
	projectile_sprite.scale = Vector2.ONE
	if projectile_mode == ProjectileMode.PIERCING:
		_fit_piercing_visual(visual_diameter * 1.50)
	else:
		projectile_sprite.scale = Vector2.ONE * 0.60
	projectile_sprite.play(&"launch")


func _fit_piercing_visual(target_diameter: float) -> void:
	var texture := projectile_sprite.sprite_frames.get_frame_texture(&"hold", 0)
	if texture == null:
		return
	var size := texture.get_size()
	var authored_diameter := maxf(maxf(size.x, size.y), 1.0)
	projectile_sprite.scale = Vector2.ONE * (target_diameter / authored_diameter)


func _get_basic_frames() -> SpriteFrames:
	if _basic_frames_cache != null:
		return _basic_frames_cache
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"launch")
	frames.set_animation_loop(&"launch", false)
	frames.set_animation_speed(&"launch", BASIC_FLY_FPS)
	for frame_index in [4, 5, 6, 7]:
		_add_frame(frames, &"launch", "%s/projectile_%02d.png" % [BASIC_EFFECT_DIR, frame_index])
	frames.add_animation(&"hold")
	frames.set_animation_loop(&"hold", true)
	frames.set_animation_speed(&"hold", 1.0)
	_add_frame(frames, &"hold", "%s/projectile_07.png" % BASIC_EFFECT_DIR)
	frames.add_animation(&"impact")
	frames.set_animation_loop(&"impact", false)
	frames.set_animation_speed(&"impact", BASIC_IMPACT_FPS)
	for frame_index in [3, 2, 1]:
		_add_frame(frames, &"impact", "%s/projectile_%02d.png" % [BASIC_EFFECT_DIR, frame_index])
	_basic_frames_cache = frames
	return frames


func _get_piercing_frames() -> SpriteFrames:
	if _piercing_frames_cache != null:
		return _piercing_frames_cache
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"launch")
	frames.set_animation_loop(&"launch", false)
	frames.set_animation_speed(&"launch", PIERCING_FLY_FPS)
	for frame_index in [1, 2, 3, 4, 5]:
		_add_frame(frames, &"launch", "%s/crescent_%02d.png" % [PIERCING_EFFECT_DIR, frame_index])
	frames.add_animation(&"hold")
	frames.set_animation_loop(&"hold", true)
	frames.set_animation_speed(&"hold", 1.0)
	_add_frame(frames, &"hold", "%s/crescent_05.png" % PIERCING_EFFECT_DIR)
	frames.add_animation(&"expire")
	frames.set_animation_loop(&"expire", false)
	frames.set_animation_speed(&"expire", PIERCING_EXPIRE_FPS)
	for frame_index in [6, 8, 9, 7, 10]:
		_add_frame(frames, &"expire", "%s/crescent_%02d.png" % [PIERCING_EFFECT_DIR, frame_index])
	_piercing_frames_cache = frames
	return frames


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
