extends Area2D

const STAGE1_PROJECTILE_FRAME_PATHS := [
	"res://assets/art/projectiles/stage1_mage/projectile_01.png",
	"res://assets/art/projectiles/stage1_mage/projectile_02.png",
	"res://assets/art/projectiles/stage1_mage/projectile_03.png",
	"res://assets/art/projectiles/stage1_mage/projectile_04.png",
]
const STAGE1_PROJECTILE_FPS := 12.0

static var _stage1_frames_cache: SpriteFrames

var direction: Vector2 = Vector2.RIGHT
var speed: float = 680.0
var max_range: float = 420.0
var damage: int = 34
var traveled_distance: float = 0.0
var source_hero_id: String = ""
var splash_radius: float = 0.0
var splash_damage_ratio: float = 0.0
var has_impacted: bool = false

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite

func _ready() -> void:
	add_to_group("hero_projectiles")
	body_entered.connect(_on_body_entered)
	queue_redraw()

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_source_hero_id: String = "",
	new_splash_radius: float = 0.0,
	new_splash_damage_ratio: float = 0.0
) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	max_range = new_max_range
	source_hero_id = new_source_hero_id
	splash_radius = maxf(new_splash_radius, 0.0)
	splash_damage_ratio = clampf(new_splash_damage_ratio, 0.0, 1.0)
	rotation = direction.angle()
	_apply_projectile_visual()

func _physics_process(delta: float) -> void:
	var previous_position := global_position
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()
	_check_chest_sweep(previous_position, global_position)

	if traveled_distance >= max_range:
		queue_free()

func _check_chest_sweep(from_position: Vector2, to_position: Vector2) -> void:
	if has_impacted:
		return
	for node in get_tree().get_nodes_in_group("treasure_chests"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var chest := node as Node2D
		if chest == null or not chest.has_method("take_damage"):
			continue
		if _distance_to_segment(chest.global_position, from_position, to_position) > 36.0:
			continue
		has_impacted = true
		chest.call("take_damage", damage)
		queue_free()
		return


func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(a + segment * t)


func _on_body_entered(body: Node) -> void:
	if has_impacted:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not (body.is_in_group("monsters") or body.is_in_group("treasure_chests")) or not body.has_method("take_damage"):
		return

	has_impacted = true
	body.call("take_damage", damage)

	if splash_radius > 0.0 and splash_damage_ratio > 0.0:
		_apply_splash_damage(body)

	queue_free()

func _apply_splash_damage(direct_target: Node) -> void:
	var splash_damage := maxi(
		1,
		int(round(float(damage) * splash_damage_ratio))
	)

	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node == direct_target:
			continue
		if not node.has_method("take_damage"):
			continue

		var monster := node as Node2D
		if monster == null:
			continue
		if global_position.distance_to(monster.global_position) > splash_radius:
			continue

		monster.call("take_damage", splash_damage)

func _apply_projectile_visual() -> void:
	projectile_sprite.visible = false
	projectile_sprite.sprite_frames = null

	if source_hero_id != "ranged_rookie":
		return

	var frames := _stage1_frames_cache
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")

		frames.add_animation("fly")
		frames.set_animation_loop("fly", true)
		frames.set_animation_speed("fly", STAGE1_PROJECTILE_FPS)

		for frame_path in STAGE1_PROJECTILE_FRAME_PATHS:
			var texture := _load_texture_direct(frame_path)
			if texture == null:
				continue
			frames.add_frame("fly", texture)
		_stage1_frames_cache = frames

	if frames.get_frame_count("fly") <= 0:
		return

	projectile_sprite.sprite_frames = frames
	projectile_sprite.visible = true
	projectile_sprite.play("fly")
	queue_redraw()

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
