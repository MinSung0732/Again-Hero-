extends Area2D

const NORMAL_EFFECT_DIR := (
	"res://assets/art/monsters/goblinthrower/frames/effect1"
)
const ELITE_EFFECT_DIR := (
	"res://assets/art/elitemonster/goblinthrower/frames/effect1"
)
const POOL_KEY := "goblin_thrower_projectile"
const VISUAL_TARGET_SIZE := 52.0
const FLY_FPS := 14.0

static var _frames_cache: Dictionary = {}

var direction: Vector2 = Vector2.RIGHT
var speed: float = 380.0
var max_range: float = 340.0
var damage: int = 7
var traveled_distance: float = 0.0
var active: bool = false
var elite_visual: bool = false

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate_for_pool()


func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	use_elite_visual: bool,
	new_size_multiplier: float = 1.0
) -> void:
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	elite_visual = use_elite_visual
	traveled_distance = 0.0
	active = true
	rotation = direction.angle()
	scale = Vector2.ONE * maxf(new_size_multiplier, 0.1)
	if not is_in_group("monster_projectiles"):
		add_to_group("monster_projectiles")
	visible = true
	monitoring = true
	set_physics_process(true)
	_apply_visual()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()
	if traveled_distance >= max_range:
		_finish_projectile()


func _on_body_entered(body: Node) -> void:
	if (
		not active
		or body == null
		or body.is_queued_for_deletion()
		or (
			not body.is_in_group("hero")
			and not body.is_in_group("hero_summons")
		)
	):
		return
	active = false
	set_deferred("monitoring", false)
	set_physics_process(false)
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	call_deferred("_finish_projectile")


func _apply_visual() -> void:
	var frames := _get_frames()
	if frames == null:
		return
	projectile_sprite.sprite_frames = frames
	projectile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	projectile_sprite.scale = Vector2.ONE * float(
		frames.get_meta("visual_scale", 1.0)
	)
	projectile_sprite.visible = true
	projectile_sprite.play(&"fly")


func _get_frames() -> SpriteFrames:
	var key := "elite" if elite_visual else "normal"
	var cached = _frames_cache.get(key)
	if cached is SpriteFrames:
		return cached as SpriteFrames

	var effect_dir := ELITE_EFFECT_DIR if elite_visual else NORMAL_EFFECT_DIR
	var frame_count := 9 if elite_visual else 1
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", FLY_FPS)

	var first_texture: Texture2D = null
	for index in range(1, frame_count + 1):
		var texture := _load_texture(
			"%s/Projectile_%02d.png" % [effect_dir, index]
		)
		if texture == null:
			continue
		if first_texture == null:
			first_texture = texture
		frames.add_frame(&"fly", texture)

	if first_texture == null:
		return null
	var source_size := maxf(
		float(maxi(first_texture.get_width(), first_texture.get_height())),
		1.0
	)
	frames.set_meta("visual_scale", VISUAL_TARGET_SIZE / source_size)
	_frames_cache[key] = frames
	return frames


func _finish_projectile() -> void:
	if active:
		active = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	active = false
	traveled_distance = 0.0
	direction = Vector2.RIGHT
	speed = 380.0
	max_range = 340.0
	damage = 7
	elite_visual = false
	rotation = 0.0
	scale = Vector2.ONE
	if is_in_group("monster_projectiles"):
		remove_from_group("monster_projectiles")
	monitoring = false
	set_physics_process(false)
	visible = false
	if is_instance_valid(projectile_sprite):
		projectile_sprite.stop()
		projectile_sprite.visible = false
		projectile_sprite.sprite_frames = null
		projectile_sprite.scale = Vector2.ONE


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
