extends Area2D

const STAGE1_PROJECTILE_SHEET_PATH := "res://assets/art/projectiles/stage1_mage/stage1_mage_projectile_sheet.png"
const STAGE1_PROJECTILE_FRAME_SIZE := Vector2(128, 128)
const STAGE1_PROJECTILE_FRAME_COUNT := 4
const STAGE1_PROJECTILE_FPS := 12.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 680.0
var max_range: float = 420.0
var damage: int = 34
var traveled_distance: float = 0.0
var source_hero_id: String = ""

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
	new_source_hero_id: String = ""
) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	max_range = new_max_range
	source_hero_id = new_source_hero_id
	rotation = direction.angle()
	_apply_projectile_visual()

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()

	if traveled_distance >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null or body.is_queued_for_deletion():
		return

	if body.is_in_group("monsters") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()

func _apply_projectile_visual() -> void:
	projectile_sprite.visible = false
	projectile_sprite.sprite_frames = null

	if source_hero_id != "ranged_rookie":
		return

	var sheet := _load_stage1_projectile_sheet()
	if sheet == null:
		push_warning(
			"Stage 1 projectile spritesheet load failed: %s"
			% STAGE1_PROJECTILE_SHEET_PATH
		)
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", STAGE1_PROJECTILE_FPS)

	for column in range(STAGE1_PROJECTILE_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			Vector2(column, 0) * STAGE1_PROJECTILE_FRAME_SIZE,
			STAGE1_PROJECTILE_FRAME_SIZE
		)
		frames.add_frame("fly", atlas)

	projectile_sprite.sprite_frames = frames
	projectile_sprite.visible = true
	projectile_sprite.play("fly")
	queue_redraw()

func _load_stage1_projectile_sheet() -> Texture2D:
	if ResourceLoader.exists(STAGE1_PROJECTILE_SHEET_PATH):
		var imported_texture = load(STAGE1_PROJECTILE_SHEET_PATH)
		if imported_texture is Texture2D:
			return imported_texture

	if FileAccess.file_exists(STAGE1_PROJECTILE_SHEET_PATH):
		var image := Image.new()
		var error := image.load(STAGE1_PROJECTILE_SHEET_PATH)
		if error == OK:
			return ImageTexture.create_from_image(image)

	return null

func _draw() -> void:
	if projectile_sprite.visible:
		return

	draw_circle(Vector2.ZERO, 9.0, Color(0.95, 0.86, 0.32))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.82))
