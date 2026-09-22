extends Node2D

const HEAL_FRAME_DIR := "res://assets/art/heroes/item/heal_frames"
const HEAL_AMOUNT := 70
const FRAME_COUNT := 4

@export var pickup_distance: float = 38.0
@export var target_visible_height: float = 54.0

@onready var visual: AnimatedSprite2D = $Visual

var hero: Node2D
var collected: bool = false

func _ready() -> void:
	add_to_group("heal_items")
	hero = get_tree().get_first_node_in_group("hero") as Node2D
	_apply_visual()

func _physics_process(_delta: float) -> void:
	if collected:
		return
	if not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group("hero") as Node2D
		if not is_instance_valid(hero):
			return

	if global_position.distance_to(hero.global_position) > pickup_distance:
		return

	collected = true
	if hero.has_method("collect_heal_item"):
		hero.call("collect_heal_item", HEAL_AMOUNT)
	queue_free()

func _apply_visual() -> void:
	visual.visible = false
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("float")
	frames.set_animation_speed("float", 8.0)
	frames.set_animation_loop("float", true)

	var visible_height := 0.0
	for index in range(1, FRAME_COUNT + 1):
		var path := "%s/float_%02d.png" % [HEAL_FRAME_DIR, index]
		var texture := _load_texture(path)
		if texture == null:
			push_warning("Heal item frame load failed: %s" % path)
			return
		if index == 1:
			var image := texture.get_image()
			if image != null and not image.is_empty():
				var used_rect := image.get_used_rect()
				visible_height = float(used_rect.size.y)
		frames.add_frame("float", texture)

	visual.sprite_frames = frames
	if visible_height > 0.0:
		var uniform_scale := target_visible_height / visible_height
		visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.visible = true
	visual.play("float")

func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	return null
