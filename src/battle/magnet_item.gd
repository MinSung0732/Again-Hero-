extends Node2D

const PICKUP_PLACEMENT := preload("res://src/systems/pickup_placement.gd")
const BATTLE_SCOPE := preload("res://src/systems/battle_scope.gd")
var _placement_pending := true

const FRAME_COUNT := 4
const FRAME_SIZE := Vector2(627.0, 627.0)
const TARGET_HEIGHT := 82.0
const PICKUP_RADIUS := 46.0

static var _frames_cache: SpriteFrames

@onready var visual: AnimatedSprite2D = $Visual

var hero: Node2D
var picked_up := false


func _ready() -> void:
	add_to_group("magnet_items")
	hero = BATTLE_SCOPE.resolve_hero(self)
	_apply_visual()


func _physics_process(_delta: float) -> void:
	if _placement_pending:
		PICKUP_PLACEMENT.ensure_reachable(self)
		_placement_pending = false
	if picked_up:
		return
	if not is_instance_valid(hero):
		hero = BATTLE_SCOPE.resolve_hero(self)
		if not is_instance_valid(hero):
			return

	if (
		global_position.distance_squared_to(hero.global_position)
		> PICKUP_RADIUS * PICKUP_RADIUS
	):
		return

	picked_up = true
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("activate_exp_magnet"):
		parent.call("activate_exp_magnet", 2.0)
	queue_free()


func _apply_visual() -> void:
	if not is_instance_valid(visual):
		return
	if _frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"idle")
		frames.set_animation_loop(&"idle", true)
		frames.set_animation_speed(&"idle", 9.0)
		for index in range(1, FRAME_COUNT + 1):
			var path := (
				"res://assets/art/heroes/item/magunet_frames/"
				+ "magnet_%02d.png" % index
			)
			var texture = load(path)
			if texture is Texture2D:
				frames.add_frame(&"idle", texture)
		_frames_cache = frames

	visual.sprite_frames = _frames_cache
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var uniform_scale := TARGET_HEIGHT / FRAME_SIZE.y
	visual.scale = Vector2(uniform_scale, uniform_scale)
	visual.play(&"idle")
