extends Area2D

const FRAME_DIR := "res://assets/art/heroes/stage4_gunner/frames/effect"
const PROJECTILE_FRAME_COUNT := 4
const PROJECTILE_FPS := 22.0
const IMPACT_FRAME_COUNT := 4
const IMPACT_FPS := 24.0
const IMPACT_SCALE := Vector2(0.45, 0.45)
const MAX_ACTIVE_IMPACT_FX := 24
const DEAD_EYE_RICOCHET_FX := preload("res://src/hero/deadeye_ricochet_fx.gd")
const POOL_KEY := "gunner_projectile"

static var _projectile_frames_cache: SpriteFrames
static var _impact_frames_cache: SpriteFrames
static var _active_impact_fx_count: int = 0
static var _chest_nodes_cache: Array = []
static var _chest_nodes_cache_physics_frame: int = -1

var direction := Vector2.RIGHT
var speed := 920.0
var max_range := 760.0
var damage := 28
var traveled := 0.0
var headshot := false
var ricochet_bounces_left: int = 0
var ricochet_radius: float = 260.0
var is_deadeye_shot: bool = false
var hit_ids: Dictionary = {}
var source_hero: Node
var active: bool = true

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	add_to_group("hero_projectiles")
	source_hero = get_tree().get_first_node_in_group("hero")
	body_entered.connect(_on_body_entered)
	_apply_visual()

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_range: float,
	is_headshot: bool = false,
	new_ricochet_bounces: int = 0,
	new_is_deadeye_shot: bool = false
) -> void:
	active = true
	visible = true
	set_physics_process(true)
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	traveled = 0.0
	hit_ids.clear()
	source_hero = get_tree().get_first_node_in_group("hero")
	direction = new_direction.normalized()
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	headshot = is_headshot
	ricochet_bounces_left = maxi(new_ricochet_bounces, 0)
	is_deadeye_shot = new_is_deadeye_shot
	rotation = direction.angle()
	if visual.sprite_frames != null:
		visual.visible = true
		visual.frame = 0
		visual.frame_progress = 0.0
		visual.play(&"fly")

func _physics_process(delta: float) -> void:
	if not active:
		return
	var previous_position := global_position
	var step := direction * speed * delta
	global_position += step
	traveled += speed * delta
	_check_chest_sweep(previous_position, global_position)
	if traveled >= max_range:
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
	for node in _get_chest_nodes_cached():
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		var chest_id := chest.get_instance_id()
		if hit_ids.has(chest_id):
			continue
		if _distance_squared_to_segment(chest.global_position, from_position, to_position) > 34.0 * 34.0:
			continue
		hit_ids[chest_id] = true
		chest.call("take_damage", damage)


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
	if not (body.is_in_group("monsters") or body.is_in_group("treasure_chests")) or not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	if headshot and body.is_in_group("monsters"):
		body.set_meta("damage_number_color_once", Color(1.0, 0.18, 0.12, 1.0))
	body.call("take_damage", damage)

	if body.is_in_group("monsters"):
		_spawn_hit_impact()

	if body.is_in_group("monsters") and ricochet_bounces_left > 0:
		var next_target := _find_ricochet_target()
		if is_instance_valid(next_target):
			var next_direction := global_position.direction_to(next_target.global_position).normalized()
			if next_direction.length_squared() > 0.0:
				if is_deadeye_shot:
					_spawn_deadeye_ricochet_fx(next_direction)
				ricochet_bounces_left -= 1
				direction = next_direction
				rotation = direction.angle()

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
	traveled = 0.0
	hit_ids.clear()
	ricochet_bounces_left = 0
	is_deadeye_shot = false
	headshot = false
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")
	set_physics_process(false)
	visible = false
	visual.stop()


func _spawn_deadeye_ricochet_fx(next_direction: Vector2) -> void:
	var fx := Node2D.new()
	fx.set_script(DEAD_EYE_RICOCHET_FX)
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.call("setup", next_direction)


func _find_ricochet_target() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	var max_distance_sq := ricochet_radius * ricochet_radius

	for node in _get_monster_nodes_near(global_position, ricochet_radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if hit_ids.has(monster.get_instance_id()):
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq := global_position.distance_squared_to(monster.global_position)
		if distance_sq > max_distance_sq or distance_sq >= nearest_distance:
			continue
		nearest_distance = distance_sq
		nearest = monster

	return nearest


func _apply_visual() -> void:
	var frames := _get_projectile_frames()
	if frames != null and frames.get_frame_count(&"fly") > 0:
		visual.sprite_frames = frames
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.visible = true
		visual.play(&"fly")
	else:
		visual.visible = false
		queue_redraw()


func _get_projectile_frames() -> SpriteFrames:
	if _projectile_frames_cache != null:
		return _projectile_frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", PROJECTILE_FPS)

	for i in range(1, PROJECTILE_FRAME_COUNT + 1):
		var path := "%s/effect_projectile_%02d.png" % [FRAME_DIR, i]
		var tex := _load_projectile_texture(path)
		if tex != null:
			frames.add_frame(&"fly", tex)

	_projectile_frames_cache = frames
	return _projectile_frames_cache


func _get_impact_frames() -> SpriteFrames:
	if _impact_frames_cache != null:
		return _impact_frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"impact")
	frames.set_animation_loop(&"impact", false)
	frames.set_animation_speed(&"impact", IMPACT_FPS)

	for i in range(1, IMPACT_FRAME_COUNT + 1):
		var path := "%s/effect_explosion_%02d.png" % [FRAME_DIR, i]
		var tex := _load_projectile_texture(path)
		if tex != null:
			frames.add_frame(&"impact", tex)

	_impact_frames_cache = frames
	return _impact_frames_cache


func _spawn_hit_impact() -> void:
	if _active_impact_fx_count >= MAX_ACTIVE_IMPACT_FX:
		return

	var frames := _get_impact_frames()
	if frames == null or frames.get_frame_count(&"impact") <= 0:
		return

	var parent := get_parent()
	if parent == null:
		return

	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.animation = &"impact"
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.scale = IMPACT_SCALE
	fx.z_index = 5
	parent.add_child(fx)
	fx.global_position = global_position
	_active_impact_fx_count += 1
	fx.tree_exited.connect(_on_impact_fx_tree_exited, Object.CONNECT_ONE_SHOT)
	fx.animation_finished.connect(Callable(fx, "queue_free"), Object.CONNECT_ONE_SHOT)
	fx.play(&"impact")


static func _on_impact_fx_tree_exited() -> void:
	_active_impact_fx_count = maxi(_active_impact_fx_count - 1, 0)


func _load_projectile_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded

	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)

	return null


func _draw() -> void:
	if not visual.visible:
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.82, 0.22))
