extends Area2D

static var _orb_frames_cache: SpriteFrames
static var _chest_nodes_cache: Array = []
static var _chest_nodes_cache_physics_frame: int = -1

const STATUS_SCRIPT := preload("res://src/hero/archmage_element_status.gd")
const POOL_KEY := "archmage_projectile"
const ORB_FRAME_PATHS := [
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_01.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_02.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_03.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_04.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_05.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_06.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_07.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect7/orb_08.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect7/orb_09.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect7/orb_10.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect7/orb_11.png",
	"res://assets/art/heroes/stage5_archmage/frames/effect7/orb_12.png",
]

const ELEMENT_COLORS := {
	"earth": Color(0.66, 0.46, 0.24, 1.0),
	"fire": Color(1.0, 0.38, 0.16, 1.0),
	"ice": Color(0.45, 0.82, 1.0, 1.0),
	"light": Color(1.0, 0.92, 0.38, 1.0),
	"wind": Color(0.56, 1.0, 0.82, 1.0),
	"holy": Color(1.0, 0.95, 0.76, 1.0),
}

var direction: Vector2 = Vector2.RIGHT
var speed: float = 760.0
var max_range: float = 620.0
var base_damage: int = 90
var traveled_distance: float = 0.0
var element: String = "earth"
var config: Dictionary = {}
var source_hero: Node
var hit_ids: Dictionary = {}
var active: bool = true

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite

func _ready() -> void:
	add_to_group("hero_projectiles")
	body_entered.connect(_on_body_entered)

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_element: String,
	new_config: Dictionary,
	new_source_hero: Node
) -> void:
	active = true
	visible = true
	set_physics_process(true)
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	traveled_distance = 0.0
	hit_ids.clear()
	direction = new_direction.normalized()
	base_damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	element = new_element
	config = new_config.duplicate(true)
	source_hero = new_source_hero

	if element == "earth":
		speed *= clampf(float(config.get("earth_speed_multiplier", 0.62)), 0.10, 1.0)

	rotation = direction.angle()
	_apply_orb_visual()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var previous_position := global_position
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()
	_check_chest_sweep(previous_position, global_position)

	if traveled_distance >= max_range:
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
	traveled_distance = 0.0
	hit_ids.clear()
	config.clear()
	source_hero = null
	element = "earth"
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")
	set_physics_process(false)
	visible = false
	projectile_sprite.stop()


func _get_monster_nodes() -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_cached"):
		var cached = source_hero.call("_get_monster_nodes_cached")
		if cached is Array:
			return cached
	return get_tree().get_nodes_in_group("monsters")


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_near"):
		var nearby = source_hero.call("_get_monster_nodes_near", origin, radius)
		if nearby is Array:
			return nearby
	return _get_monster_nodes()


func _get_monster_nodes_in_rect(world_rect: Rect2) -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_in_rect"):
		var nearby = source_hero.call("_get_monster_nodes_in_rect", world_rect)
		if nearby is Array:
			return nearby
	return _get_monster_nodes()


func _get_chest_nodes_cached() -> Array:
	var physics_frame := Engine.get_physics_frames()
	if physics_frame != _chest_nodes_cache_physics_frame:
		_chest_nodes_cache = get_tree().get_nodes_in_group("treasure_chests")
		_chest_nodes_cache_physics_frame = physics_frame
	return _chest_nodes_cache


func _check_chest_sweep(from_position: Vector2, to_position: Vector2) -> void:
	for node in _get_chest_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		if _distance_squared_to_segment(chest.global_position, from_position, to_position) > 38.0 * 38.0:
			continue
		var chest_id := chest.get_instance_id()
		if hit_ids.has(chest_id):
			continue
		hit_ids[chest_id] = true
		chest.call("take_damage", base_damage)
		if element != "wind":
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
	if not active:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not body.is_in_group("monsters") or not body.has_method("take_damage"):
		return
	var body_2d := body as Node2D
	if body_2d == null:
		return

	var instance_id := body_2d.get_instance_id()
	if hit_ids.has(instance_id):
		return
	hit_ids[instance_id] = true

	match element:
		"earth":
			_apply_earth(body_2d)
		"fire":
			_apply_fire(body_2d)
		"ice":
			_apply_ice(body_2d)
		"light":
			_apply_light(body_2d)
		"wind":
			_apply_wind(body_2d)
		"holy":
			_apply_holy(body_2d)
		_:
			body.call("take_damage", base_damage)

	_spawn_impact_feedback(body_2d.global_position)

	if element != "wind":
		_finish_projectile()

func _apply_earth(body: Node2D) -> void:
	var direct_multiplier := maxf(float(config.get("earth_direct_damage_multiplier", 1.45)), 1.0)
	var splash_ratio := maxf(float(config.get("earth_splash_damage_ratio", 0.70)), 0.0)
	var splash_radius := maxf(float(config.get("earth_splash_radius", 150.0)), 0.0)
	body.call("take_damage", maxi(1, int(round(float(base_damage) * direct_multiplier))))

	for node in _get_monster_nodes_near(global_position, splash_radius):
		if not is_instance_valid(node) or node == body or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if global_position.distance_squared_to(monster.global_position) > splash_radius * splash_radius:
			continue
		monster.call("take_damage", maxi(1, int(round(float(base_damage) * splash_ratio))))

func _apply_fire(body: Node2D) -> void:
	body.call("take_damage", base_damage)
	var duration := maxf(float(config.get("fire_burn_duration", 3.0)), 0.1)
	var tick_interval := maxf(float(config.get("fire_burn_tick_interval", 0.5)), 0.1)
	var damage_ratio := maxf(float(config.get("fire_burn_tick_damage_ratio", 0.18)), 0.0)
	_get_or_create_status(body).apply_burn(
		maxi(1, int(round(float(base_damage) * damage_ratio))),
		duration,
		tick_interval
	)

func _apply_ice(body: Node2D) -> void:
	body.call("take_damage", base_damage)
	var freeze_chance := clampf(float(config.get("ice_freeze_chance", 0.10)), 0.0, 1.0)
	if randf() <= freeze_chance:
		_get_or_create_status(body).apply_freeze(
			maxf(float(config.get("ice_freeze_duration", 1.0)), 0.05)
		)

func _apply_light(body: Node2D) -> void:
	body.call("take_damage", base_damage)
	var chain_range := maxf(float(config.get("light_chain_range", 260.0)), 1.0)
	var chain_ratio := maxf(float(config.get("light_chain_damage_ratio", 0.72)), 0.0)
	var nearest: Node2D = null
	var nearest_distance := INF
	for node in _get_monster_nodes_near(body.global_position, chain_range):
		if not is_instance_valid(node) or node == body or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var distance := body.global_position.distance_squared_to(monster.global_position)
		if distance <= chain_range * chain_range and distance < nearest_distance:
			nearest_distance = distance
			nearest = monster

	if is_instance_valid(nearest):
		nearest.call("take_damage", maxi(1, int(round(float(base_damage) * chain_ratio))))
		_spawn_chain_line(body.global_position, nearest.global_position)

func _apply_wind(body: Node2D) -> void:
	body.call("take_damage", base_damage)
	var knockback := maxf(float(config.get("wind_knockback_distance", 105.0)), 0.0)
	var monster := body as Node2D
	if monster != null and knockback > 0.0:
		monster.global_position += direction.normalized() * knockback

func _apply_holy(body: Node2D) -> void:
	var holy_damage := base_damage
	if bool(body.get_meta("undead", false)) or bool(body.get_meta("is_undead", false)):
		holy_damage = maxi(
			1,
			int(round(float(base_damage) * maxf(float(config.get("holy_undead_damage_multiplier", 1.50)), 1.0)))
		)
	body.call("take_damage", holy_damage)

	var heal_chance := clampf(float(config.get("holy_heal_chance", 0.15)), 0.0, 1.0)
	var heal_amount := maxi(int(config.get("holy_heal_amount", 25)), 0)
	if heal_amount > 0 and randf() <= heal_chance and is_instance_valid(source_hero):
		if source_hero.has_method("heal_direct"):
			source_hero.call("heal_direct", heal_amount)

func _get_or_create_status(body: Node):
	var existing := body.get_node_or_null("ArchmageElementStatus")
	if is_instance_valid(existing):
		return existing
	var status = STATUS_SCRIPT.new()
	body.add_child(status)
	status.setup(body)
	return status

func _spawn_chain_line(from_position: Vector2, to_position: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var line := Line2D.new()
	line.width = 5.0
	line.default_color = Color(1.0, 0.94, 0.48, 0.92)
	line.z_index = 8
	line.add_point(parent.to_local(from_position))
	line.add_point(parent.to_local(to_position))
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.finished.connect(line.queue_free)

func _spawn_impact_feedback(world_position: Vector2) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = ELEMENT_COLORS.get(element, Color.WHITE)
	ring.z_index = 7
	ring.position = parent.to_local(world_position)
	var radius := 22.0 if element != "earth" else 34.0
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		ring.add_point(Vector2.from_angle(angle) * radius)
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.45, 1.45), 0.16)
	tween.tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.finished.connect(ring.queue_free)

func _apply_orb_visual() -> void:
	var frames := _orb_frames_cache
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("fly")
		frames.set_animation_loop("fly", true)
		frames.set_animation_speed("fly", 18.0)

		for path in ORB_FRAME_PATHS:
			var texture := _load_texture_direct(path)
			if texture != null:
				frames.add_frame("fly", texture)
		_orb_frames_cache = frames

	if frames.get_frame_count("fly") <= 0:
		return

	projectile_sprite.sprite_frames = frames
	projectile_sprite.modulate = ELEMENT_COLORS.get(element, Color.WHITE)
	projectile_sprite.visible = true
	projectile_sprite.play("fly")

func _load_texture_direct(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null
