extends Area2D

const NORMAL_EFFECT_DIR := "res://assets/art/monsters/spider/frames/effect"
const ELITE_EFFECT_DIR := "res://assets/art/elitemonster/spider/frames/effect"
const EFFECT_FRAME_COUNT := 8
const EFFECT_FPS := 12.0
const EFFECT_TARGET_HEIGHT := 64.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 320.0
var max_range: float = 360.0
var damage: int = 5
var slow_multiplier: float = 0.72
var slow_duration: float = 1.5
var traveled_distance: float = 0.0
var has_impacted: bool = false
var elite_visual: bool = false

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite

func _ready() -> void:
	add_to_group("monster_projectiles")
	body_entered.connect(_on_body_entered)

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	new_slow_multiplier: float,
	new_slow_duration: float,
	use_elite_visual: bool
) -> void:
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	damage = new_damage
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	slow_multiplier = clampf(new_slow_multiplier, 0.0, 1.0)
	slow_duration = maxf(new_slow_duration, 0.0)
	elite_visual = use_elite_visual
	rotation = direction.angle()
	_apply_projectile_visual()

func _physics_process(delta: float) -> void:
	if has_impacted:
		return

	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()

	if traveled_distance >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if has_impacted:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not body.is_in_group("hero"):
		return

	has_impacted = true

	var damage_applied := false
	if body.has_method("take_damage"):
		damage_applied = bool(body.call("take_damage", damage))

	if damage_applied and body.has_method("apply_slow"):
		body.call("apply_slow", slow_multiplier, slow_duration)

	queue_free()

func _apply_projectile_visual() -> void:
	projectile_sprite.visible = false
	projectile_sprite.sprite_frames = null
	projectile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var effect_dir := ELITE_EFFECT_DIR if elite_visual else NORMAL_EFFECT_DIR
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", EFFECT_FPS)

	var first_texture: Texture2D = null
	for frame_index in range(1, EFFECT_FRAME_COUNT + 1):
		var path := "%s/frame_%02d.png" % [effect_dir, frame_index]
		var texture := _load_texture(path)
		if texture == null:
			continue
		if first_texture == null:
			first_texture = texture
		frames.add_frame(&"fly", texture)

	if first_texture == null:
		push_warning("Spider projectile frames not found: %s" % effect_dir)
		return

	projectile_sprite.sprite_frames = frames
	var source_height := maxf(float(first_texture.get_height()), 1.0)
	var uniform_scale := EFFECT_TARGET_HEIGHT / source_height
	projectile_sprite.scale = Vector2(uniform_scale, uniform_scale)
	projectile_sprite.visible = true
	projectile_sprite.play(&"fly")

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource

	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)

	return null
