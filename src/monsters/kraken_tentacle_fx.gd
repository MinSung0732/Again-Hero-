extends RefCounted

const POOL_KEY := "kraken_tentacle"
static var cached_frames: SpriteFrames

static func warm_cache() -> void:
	if cached_frames != null:
		return
	cached_frames = SpriteFrames.new()
	cached_frames.set_animation_loop(&"default", false)
	cached_frames.set_animation_speed(&"default", 12.0)
	for index in range(1, 9):
		var path := "res://assets/art/monsters/Kraken/frames/effect1/Projectile_%02d.png" % index
		var texture: Texture2D
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		if texture == null:
			var img := Image.new()
			if img.load(path) == OK:
				texture = ImageTexture.create_from_image(img)
		if texture != null:
			cached_frames.add_frame(&"default", texture)

static func show_at(battle: Node, location: Vector2, size_multiplier: float = 1.0) -> void:
	if not is_instance_valid(battle) or not battle.has_method("acquire_transient_fx"):
		return
	warm_cache()
	var fx = battle.call("acquire_transient_fx", POOL_KEY, "animated_sprite") as AnimatedSprite2D
	if fx == null:
		return
	fx.sprite_frames = cached_frames
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.global_position = location
	fx.scale = Vector2.ONE * (170.0 / 456.0) * size_multiplier
	# The supplied 604x456 canvas has its ground anchor at (302,444).
	fx.offset = Vector2(0, -216)
	fx.z_index = 3
	fx.modulate = Color.WHITE
	fx.flip_h = randf() < 0.5
	fx.frame = 0
	if not fx.animation_finished.is_connected(_finish.bind(fx, battle)):
		fx.animation_finished.connect(_finish.bind(fx, battle))
	fx.play(&"default")

static func _finish(fx: AnimatedSprite2D, battle: Node) -> void:
	if is_instance_valid(battle) and is_instance_valid(fx):
		battle.call("recycle_transient_fx", fx, POOL_KEY)
