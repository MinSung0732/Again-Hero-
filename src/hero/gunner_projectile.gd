extends Area2D

const FRAME_DIR := "res://assets/art/heroes/stage4_gunner/frames/effect"
const FRAME_COUNT := 13
const FPS := 22.0
const DEAD_EYE_RICOCHET_FX := preload("res://src/hero/deadeye_ricochet_fx.gd")

static var _projectile_frames_cache: SpriteFrames

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

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	add_to_group("hero_projectiles")
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
	direction = new_direction.normalized()
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	headshot = is_headshot
	ricochet_bounces_left = maxi(new_ricochet_bounces, 0)
	is_deadeye_shot = new_is_deadeye_shot
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var previous_position := global_position
	var step := direction * speed * delta
	global_position += step
	traveled += step.length()
	_check_chest_sweep(previous_position, global_position)
	if traveled >= max_range:
		queue_free()

func _check_chest_sweep(from_position: Vector2, to_position: Vector2) -> void:
	for node in get_tree().get_nodes_in_group("treasure_chests"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		var chest_id := chest.get_instance_id()
		if hit_ids.has(chest_id):
			continue
		if _distance_to_segment(chest.global_position, from_position, to_position) > 34.0:
			continue
		hit_ids[chest_id] = true
		chest.call("take_damage", damage)


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(a + segment * t)


func _on_body_entered(body: Node) -> void:
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

	for node in get_tree().get_nodes_in_group("monsters"):
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
	var frames := _projectile_frames_cache
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"fly")
		frames.set_animation_loop(&"fly", true)
		frames.set_animation_speed(&"fly", FPS)
		for i in range(1, FRAME_COUNT + 1):
			var path := "%s/effect_projectile_%02d.png" % [FRAME_DIR, i]
			if not ResourceLoader.exists(path):
				continue
			var tex = load(path)
			if tex is Texture2D:
				frames.add_frame(&"fly", tex)
		_projectile_frames_cache = frames

	if frames.get_frame_count(&"fly") > 0:
		visual.sprite_frames = frames
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.visible = true
		visual.play(&"fly")
	else:
		visual.visible = false
		queue_redraw()

func _draw() -> void:
	if not visual.visible:
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.82, 0.22))
