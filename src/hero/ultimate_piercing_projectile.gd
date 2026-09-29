extends Area2D

const EFFECT_FRAME_COUNT := 6
const EFFECT_TARGET_HEIGHT := 128.0
const EFFECT_FRAME_SIZE := Vector2(512, 512)
const EFFECT_FPS := 12.0
const EFFECT_BASE_PATH := "res://assets/art/heroes/stage1_mage/frames/effect_01"
const POOL_KEY := "ultimate_piercing_projectile"

static var _visual_frames_cache: SpriteFrames

var direction: Vector2 = Vector2.RIGHT
var speed: float = 950.0
var max_range: float = 900.0
var damage: int = 110
var traveled_distance: float = 0.0
var hit_ids: Dictionary = {}
var active: bool = false

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate_for_pool()

func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float
) -> void:
	direction = new_direction.normalized()
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT

	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	traveled_distance = 0.0
	hit_ids.clear()
	active = true
	rotation = direction.angle()
	visible = true
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	monitoring = true
	set_physics_process(true)
	_apply_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()

	if traveled_distance >= max_range:
		_finish()


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body == null or body.is_queued_for_deletion():
		return
	if not body.is_in_group("monsters") or not body.has_method("take_damage"):
		return

	var instance_id := body.get_instance_id()
	if hit_ids.has(instance_id):
		return

	hit_ids[instance_id] = true
	body.call("take_damage", damage)

func _finish() -> void:
	if not active:
		return
	active = false
	var parent := get_parent()
	if (
		is_instance_valid(parent)
		and parent.has_method("recycle_projectile")
	):
		parent.call("recycle_projectile", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	active = false
	direction = Vector2.RIGHT
	speed = 950.0
	max_range = 900.0
	damage = 110
	traveled_distance = 0.0
	hit_ids.clear()
	rotation = 0.0
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")
	monitoring = false
	set_physics_process(false)
	visible = false
	if is_instance_valid(visual):
		visual.stop()
		visual.visible = false
		visual.frame = 0
		visual.frame_progress = 0.0


func _apply_visual() -> void:
	visual.stop()
	visual.visible = false
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := _visual_frames_cache
	if frames == null:
		frames = SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")

		frames.add_animation(&"fly")
		frames.set_animation_loop(&"fly", true)
		frames.set_animation_speed(&"fly", EFFECT_FPS)

		for index in range(1, EFFECT_FRAME_COUNT + 1):
			var path := "%s/frame_%02d.png" % [EFFECT_BASE_PATH, index]
			var texture := _load_texture(path)
			if texture == null:
				push_warning("Ultimate projectile frame load failed: %s" % path)
				visual.sprite_frames = null
				visual.visible = false
				return
			frames.add_frame(&"fly", texture)
		_visual_frames_cache = frames

	visual.sprite_frames = frames
	var uniform_scale := EFFECT_TARGET_HEIGHT / EFFECT_FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.visible = true
	visual.play(&"fly")

func _load_texture(path: String) -> Texture2D:
	# Prefer the current source PNG over a possibly stale imported .ctex.
	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(path)
		if error == OK:
			return ImageTexture.create_from_image(image)

	if ResourceLoader.exists(path):
		var imported_texture = load(path)
		if imported_texture is Texture2D:
			return imported_texture

	return null

func _draw() -> void:
	if visual.visible:
		return

	draw_rect(
		Rect2(-58.0, -28.0, 116.0, 56.0),
		Color(0.35, 0.75, 1.0, 0.85),
		true
	)
