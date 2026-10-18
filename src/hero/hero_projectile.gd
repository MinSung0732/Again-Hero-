extends Area2D

const DATA := preload("res://src/data/hero_basic_projectile_catalog.gd")
const POOL_KEY := DATA.POOL_KEY
const VOLLEY := preload("res://src/hero/projectile_volley.gd")

static var _frames_cache: Dictionary = {}
static var _chest_nodes_cache: Array = []
static var _chest_nodes_cache_physics_frame: int = -1

var direction: Vector2 = Vector2.RIGHT
var speed: float = DATA.DEFAULT_SPEED
var max_range: float = DATA.DEFAULT_RANGE
var damage: int = DATA.DEFAULT_DAMAGE
var traveled_distance: float = 0.0
var _projectile_profile: Dictionary = DATA.EMPTY_PROFILE
var _impact_animation: StringName = &""
var _damage_multiplier_method: StringName = &""
var source_hero_id: String = "":
	set(value):
		if source_hero_id == value: return
		source_hero_id = value
		_projectile_profile = DATA.profile(value)
		_impact_animation = StringName(_projectile_profile.get("impact_animation", &""))
		_damage_multiplier_method = StringName(_projectile_profile.get("damage_multiplier_method", &""))
var splash_radius: float = 0.0
var splash_damage_ratio: float = 0.0
var has_impacted: bool = false
var source_hero: Node
var active: bool = true
var volley: VOLLEY

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite

func _ready() -> void:
	add_to_group("hero_projectiles")
	source_hero = get_tree().get_first_node_in_group("hero")
	body_entered.connect(_on_body_entered)
	projectile_sprite.animation_finished.connect(
		Callable(self, "_on_projectile_animation_finished")
	)
	queue_redraw()

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_source_hero_id: String = "",
	new_splash_radius: float = 0.0,
	new_splash_damage_ratio: float = 0.0,
	new_volley: VOLLEY = null
) -> void:
	active = true
	visible = true
	set_physics_process(true)
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	traveled_distance = 0.0
	has_impacted = false
	volley = new_volley
	source_hero = get_tree().get_first_node_in_group("hero")
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	max_range = new_max_range
	source_hero_id = new_source_hero_id
	splash_radius = maxf(new_splash_radius, 0.0)
	splash_damage_ratio = clampf(new_splash_damage_ratio, 0.0, 1.0)
	rotation = direction.angle()
	_sync_monitoring.call_deferred()
	_apply_projectile_visual()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var previous_position := global_position
	var step := direction * speed * delta
	global_position += step
	traveled_distance += speed * delta
	_check_chest_sweep(previous_position, global_position)

	if traveled_distance >= max_range:
		_finish_projectile()

func _get_chest_nodes_cached() -> Array:
	var physics_frame := Engine.get_physics_frames()
	if physics_frame != _chest_nodes_cache_physics_frame:
		_chest_nodes_cache = get_tree().get_nodes_in_group("treasure_chests")
		_chest_nodes_cache_physics_frame = physics_frame
	return _chest_nodes_cache


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_near"):
		var nearby = source_hero.call("_get_monster_nodes_near", origin, radius)
		if nearby is Array:
			return nearby
	return get_tree().get_nodes_in_group("monsters")


func _check_chest_sweep(from_position: Vector2, to_position: Vector2) -> void:
	if has_impacted:
		return
	for node in _get_chest_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		if _distance_squared_to_segment(chest.global_position, from_position, to_position) > DATA.CHEST_HIT_RADIUS * DATA.CHEST_HIT_RADIUS:
			continue
		has_impacted = true
		chest.call("take_damage", damage)
		if not _impact_animation.is_empty():
			_play_impact()
		else:
			_finish_projectile()
		return


func _distance_squared_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_squared_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_squared_to(a + segment * t)


func _on_body_entered(body: Node) -> void:
	if not active or has_impacted:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not (body.is_in_group("monsters") or body.is_in_group("treasure_chests")) or not body.has_method("take_damage"):
		return
	if volley != null and not volley.claim_target(body):
		return # Keep flying so extra bullets can still find a different monster.

	has_impacted = true
	var dealt_damage := damage
	if (
		not _damage_multiplier_method.is_empty()
		and body.is_in_group("monsters")
		and is_instance_valid(source_hero)
		and source_hero.has_method(_damage_multiplier_method)
	):
		dealt_damage = maxi(
			1,
			int(round(
				float(damage)
				* float(source_hero.call(
					_damage_multiplier_method,
					body
				))
			))
		)
	if preload("res://src/systems/monster_hit_context.gd").reflect_projectile(body,dealt_damage,source_hero,self):
		_finish_projectile()
		return
	preload("res://src/systems/monster_hit_context.gd").hit(body, dealt_damage, "ranged", source_hero)

	if splash_radius > 0.0 and splash_damage_ratio > 0.0:
		_apply_splash_damage(body)

	if not _impact_animation.is_empty():
		_play_impact()
	else:
		_finish_projectile()

func _play_impact() -> void:
	if not active:
		return
	set_physics_process(false)
	_sync_monitoring.call_deferred()
	rotation = 0.0
	if (
		projectile_sprite.sprite_frames != null
		and projectile_sprite.sprite_frames.has_animation(_impact_animation)
		and projectile_sprite.sprite_frames.get_frame_count(_impact_animation) > 0
	):
		projectile_sprite.stop()
		projectile_sprite.animation = _impact_animation
		projectile_sprite.frame = 0
		projectile_sprite.play(_impact_animation)
		return
	_finish_projectile()


func _on_projectile_animation_finished() -> void:
	if (
		active
		and has_impacted
		and not _impact_animation.is_empty()
		and projectile_sprite.animation == _impact_animation
	):
		_finish_projectile()


func _finish_projectile() -> void:
	if not active:
		return
	active = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	active = false
	volley = null
	traveled_distance = 0.0
	has_impacted = false
	direction = Vector2.RIGHT
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")
	set_physics_process(false)
	_sync_monitoring.call_deferred()
	visible = false
	projectile_sprite.stop()


func _apply_splash_damage(direct_target: Node) -> void:
	var splash_damage := maxi(
		1,
		int(round(float(damage) * splash_damage_ratio))
	)

	for node in _get_monster_nodes_near(global_position, splash_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node == direct_target:
			continue
		if not node.has_method("take_damage"):
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_squared_to(monster.global_position) > splash_radius * splash_radius:
			continue
		if volley != null and not volley.claim_target(monster):
			continue

		var dealt_damage := splash_damage
		if (
			not _damage_multiplier_method.is_empty()
			and is_instance_valid(source_hero)
			and source_hero.has_method(_damage_multiplier_method)
		):
			dealt_damage = maxi(
				1,
				int(round(
					float(splash_damage)
					* float(source_hero.call(
						_damage_multiplier_method,
						monster
					))
				))
			)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, dealt_damage, "ranged", source_hero)

func _apply_projectile_visual() -> void:
	projectile_sprite.visible = false
	projectile_sprite.sprite_frames = null
	if _projectile_profile.is_empty(): return
	var frames: SpriteFrames = _frames_cache.get(source_hero_id)
	if frames == null:
		frames = _build_projectile_frames()
		_frames_cache[source_hero_id] = frames
	var flight := StringName(_projectile_profile.get("flight_animation", &""))
	if not frames.has_animation(flight) or frames.get_frame_count(flight) <= 0: return
	projectile_sprite.sprite_frames = frames
	if _projectile_profile.get("nearest", false):
		projectile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	projectile_sprite.scale = _projectile_profile.get("scale", Vector2.ONE)
	projectile_sprite.visible = true
	projectile_sprite.play(flight)
	queue_redraw()

func _build_projectile_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"): frames.remove_animation("default")
	for animation in _projectile_profile.get("animations", []):
		var name := StringName(animation.name)
		frames.add_animation(name)
		frames.set_animation_loop(name, bool(animation.loop))
		frames.set_animation_speed(name, float(animation.fps))
		for path in animation.paths:
			var texture := _load_texture_direct(String(path))
			if texture != null: frames.add_frame(name, texture)
	return frames

func _load_texture_direct(path: String) -> Texture2D:
	# First use Godot's imported resource if it is ready.
	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture

	# Android Editor/Termux workflow: bypass delayed import cache and read
	# the actual PNG file from res:// directly.
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var png_bytes := file.get_buffer(file.get_length())
	if png_bytes.is_empty():
		return null

	var image := Image.new()
	var error := image.load_png_from_buffer(png_bytes)
	if error != OK:
		return null

	return ImageTexture.create_from_image(image)

func _draw() -> void:
	if projectile_sprite.visible:
		return

	draw_circle(Vector2.ZERO, 9.0, Color(0.95, 0.86, 0.32))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.82))

func _sync_monitoring() -> void:
	# Read the current pooled life so an old deferred disable cannot affect reuse.
	monitoring = active and not has_impacted
