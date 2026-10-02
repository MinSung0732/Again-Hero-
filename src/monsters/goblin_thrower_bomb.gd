extends Area2D

const PROJECTILE_DIR := (
	"res://assets/art/elitemonster/goblinthrower/frames/effect1"
)
const EXPLOSION_DIR := (
	"res://assets/art/elitemonster/goblinthrower/frames/effect2"
)
const POOL_KEY := "goblin_thrower_elite_bomb"
const PROJECTILE_TARGET_SIZE := 58.0
const EXPLOSION_TARGET_SIZE := 104.0
const FLY_FPS := 14.0
const EXPLOSION_FPS := 16.0
const BLINK_INTERVAL := 0.10

static var _frames_cache: SpriteFrames

var target_position: Vector2 = Vector2.ZERO
var speed: float = 650.0
var damage: int = 1
var fuse_duration: float = 1.0
var fuse_timer: float = 0.0
var explosion_radius: float = 52.0
var state: int = 0
var explosion_timer: float = 0.0
var blink_timer: float = 0.0
var blink_on: bool = false
var source_monster: Node2D
var hero: Node2D

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	deactivate_for_pool()


func setup(
	start_position: Vector2,
	landing_position: Vector2,
	new_damage: int,
	new_speed: float,
	new_fuse_duration: float,
	new_explosion_radius: float,
	new_source: Node2D,
	new_hero: Node2D
) -> void:
	global_position = start_position
	target_position = landing_position
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	fuse_duration = maxf(new_fuse_duration, 0.05)
	fuse_timer = fuse_duration
	explosion_radius = maxf(new_explosion_radius, 1.0)
	source_monster = new_source
	hero = new_hero
	state = 1
	explosion_timer = 0.0
	blink_timer = BLINK_INTERVAL
	blink_on = false
	visible = true
	set_physics_process(true)
	_apply_frames()
	sprite.scale = Vector2.ONE * _get_scale_for_animation(&"fly")
	sprite.modulate = Color.WHITE
	sprite.play(&"fly")


func _physics_process(delta: float) -> void:
	match state:
		1:
			_tick_flying(delta)
		2:
			_tick_fuse(delta)
		3:
			_tick_explosion(delta)


func _tick_flying(delta: float) -> void:
	var offset := target_position - global_position
	var distance := offset.length()
	var step := speed * delta
	if distance <= step or distance <= 1.0:
		global_position = target_position
		state = 2
		sprite.stop()
		sprite.frame = 0
		return
	global_position += offset / distance * step


func _tick_fuse(delta: float) -> void:
	fuse_timer = maxf(fuse_timer - delta, 0.0)
	blink_timer = maxf(blink_timer - delta, 0.0)
	if blink_timer <= 0.0:
		blink_timer = BLINK_INTERVAL
		blink_on = not blink_on
		sprite.modulate = (
			Color(1.0, 1.0, 1.0, 0.28)
			if blink_on
			else Color.WHITE
		)
	if fuse_timer > 0.0:
		return
	_explode()


func _explode() -> void:
	state = 3
	sprite.modulate = Color.WHITE
	if (
		is_instance_valid(hero)
		and not hero.is_queued_for_deletion()
		and global_position.distance_squared_to(hero.global_position)
		<= explosion_radius * explosion_radius
		and hero.has_method("take_damage")
	):
		hero.call("take_damage", damage, source_monster)
	sprite.scale = Vector2.ONE * _get_scale_for_animation(&"explode")
	sprite.play(&"explode")
	explosion_timer = 8.0 / EXPLOSION_FPS


func _tick_explosion(delta: float) -> void:
	explosion_timer = maxf(explosion_timer - delta, 0.0)
	if explosion_timer <= 0.0:
		_finish()


func _apply_frames() -> void:
	if _frames_cache == null:
		_frames_cache = _build_frames()
	if _frames_cache != null:
		sprite.sprite_frames = _frames_cache
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = true


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", FLY_FPS)
	for index in range(1, 10):
		var texture := _load_texture(
			"%s/Projectile_%02d.png" % [PROJECTILE_DIR, index]
		)
		if texture != null:
			frames.add_frame(&"fly", texture)
	frames.add_animation(&"explode")
	frames.set_animation_loop(&"explode", false)
	frames.set_animation_speed(&"explode", EXPLOSION_FPS)
	for index in range(1, 9):
		var texture := _load_texture(
			"%s/explosion_%02d.png" % [EXPLOSION_DIR, index]
		)
		if texture != null:
			frames.add_frame(&"explode", texture)
	if (
		frames.get_frame_count(&"fly") <= 0
		or frames.get_frame_count(&"explode") <= 0
	):
		return null
	return frames


func _get_scale_for_animation(animation: StringName) -> float:
	if sprite.sprite_frames == null:
		return 1.0
	if sprite.sprite_frames.get_frame_count(animation) <= 0:
		return 1.0
	var texture := sprite.sprite_frames.get_frame_texture(animation, 0)
	if texture == null:
		return 1.0
	var source_size := maxf(
		float(maxi(texture.get_width(), texture.get_height())),
		1.0
	)
	var target_size := (
		EXPLOSION_TARGET_SIZE
		if animation == &"explode"
		else PROJECTILE_TARGET_SIZE
	)
	return target_size / source_size


func _finish() -> void:
	state = 0
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	state = 0
	target_position = Vector2.ZERO
	speed = 650.0
	damage = 1
	fuse_duration = 1.0
	fuse_timer = 0.0
	explosion_radius = 52.0
	explosion_timer = 0.0
	blink_timer = 0.0
	blink_on = false
	source_monster = null
	hero = null
	visible = false
	set_physics_process(false)
	if is_instance_valid(sprite):
		sprite.stop()
		sprite.visible = false
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE


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
