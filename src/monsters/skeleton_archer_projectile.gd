extends Area2D

const NORMAL_EFFECT_DIR := "res://assets/art/monsters/skelletonarcher/frames/effect1"
const ELITE_EFFECT_DIR := "res://assets/art/elitemonster/skelletonarcher/frames/effect1"
const POOL_KEY := "skeleton_archer_projectile"
const FLY_TARGET_SIZE := 72.0
const FLY_FPS := 11.0
const IMPACT_FPS := 14.0

static var _frames_cache: Dictionary = {}

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var max_range: float = 190.0
var damage: int = 8
var traveled_distance: float = 0.0
var active: bool = false
var impacting: bool = false
var power_visual: bool = false
var elite_visual: bool = false

@onready var projectile_sprite: AnimatedSprite2D = $ProjectileSprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	projectile_sprite.animation_finished.connect(_on_animation_finished)
	deactivate_for_pool()


func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	use_power_visual: bool,
	use_elite_visual: bool,
	new_size_multiplier: float = 1.0
) -> void:
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	power_visual = use_power_visual
	elite_visual = use_elite_visual
	traveled_distance = 0.0
	active = true
	impacting = false
	rotation = direction.angle()
	scale = Vector2.ONE * maxf(new_size_multiplier, 0.1)
	if not is_in_group("monster_projectiles"):
		add_to_group("monster_projectiles")
	visible = true
	monitoring = true
	set_physics_process(true)
	_apply_visual()


func _physics_process(delta: float) -> void:
	if not active or impacting:
		return
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()
	if traveled_distance >= max_range:
		_finish_projectile()


func _on_body_entered(body: Node) -> void:
	if not active or impacting:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not body.is_in_group("hero") and not body.is_in_group("hero_summons"):
		return

	impacting = true
	set_deferred("monitoring", false)
	set_physics_process(false)
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	_play_impact()


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
	projectile_sprite.stop()
	projectile_sprite.animation = &"fly"
	projectile_sprite.frame = 0
	projectile_sprite.frame_progress = 0.0
	projectile_sprite.play(&"fly")


func _play_impact() -> void:
	var frames := _get_frames()
	if frames == null or not frames.has_animation(&"impact"):
		_finish_projectile()
		return
	projectile_sprite.sprite_frames = frames
	projectile_sprite.stop()
	projectile_sprite.animation = &"impact"
	projectile_sprite.frame = 0
	projectile_sprite.frame_progress = 0.0
	projectile_sprite.play(&"impact")


func _get_frames() -> SpriteFrames:
	var key := "%s|%s" % [
		"elite" if elite_visual else "normal",
		"power" if power_visual else "normal",
	]
	var cached = _frames_cache.get(key)
	if cached is SpriteFrames:
		return cached as SpriteFrames

	var effect_dir := ELITE_EFFECT_DIR if elite_visual else NORMAL_EFFECT_DIR
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", FLY_FPS)
	var fly_prefix := "power" if power_visual else "normal"
	var first_texture: Texture2D = null
	for index in range(1, 5):
		var texture := _load_texture("%s/%s_%02d.png" % [
			effect_dir,
			fly_prefix,
			index,
		])
		if texture == null:
			continue
		if first_texture == null:
			first_texture = texture
		frames.add_frame(&"fly", texture)

	frames.add_animation(&"impact")
	frames.set_animation_loop(&"impact", false)
	frames.set_animation_speed(&"impact", IMPACT_FPS)
	var impact_names: Array[String] = []
	if power_visual:
		impact_names = ["normalhit_01", "powerhit_01", "hitdelete_01"]
	else:
		impact_names = ["normalhit_01", "normalhit_02", "hitdelete_01"]
	for frame_name in impact_names:
		var texture := _load_texture("%s/%s.png" % [effect_dir, frame_name])
		if texture != null:
			frames.add_frame(&"impact", texture)

	if first_texture == null:
		return null
	var source_size := maxf(
		float(maxi(first_texture.get_width(), first_texture.get_height())),
		1.0
	)
	frames.set_meta("visual_scale", FLY_TARGET_SIZE / source_size)
	_frames_cache[key] = frames
	return frames


func _on_animation_finished() -> void:
	if impacting and projectile_sprite.animation == &"impact":
		_finish_projectile()


func _finish_projectile() -> void:
	if not active and not impacting:
		return
	active = false
	impacting = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	active = false
	impacting = false
	traveled_distance = 0.0
	direction = Vector2.RIGHT
	speed = 300.0
	max_range = 190.0
	damage = 8
	power_visual = false
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
