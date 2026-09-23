extends Area2D

var skill_type: String = ""
var direction := Vector2.RIGHT
var speed := 900.0
var max_range := 900.0
var traveled := 0.0
var damage := 1
var config: Dictionary = {}
var source_hero: Node
var empowered := false
var hit_ids: Dictionary = {}
var bounce_count := 0
var current_target: Node2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var tail: AnimatedSprite2D = $Tail

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(
	new_skill_type: String,
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_range: float,
	new_config: Dictionary,
	new_source_hero: Node,
	is_empowered: bool = false,
	initial_target: Node2D = null
) -> void:
	skill_type = new_skill_type
	direction = new_direction.normalized()
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	config = new_config.duplicate(true)
	source_hero = new_source_hero
	empowered = is_empowered
	current_target = initial_target
	_apply_visual()

func _physics_process(delta: float) -> void:
	if skill_type == "chain_dagger" and is_instance_valid(current_target):
		var desired := global_position.direction_to(current_target.global_position)
		if desired.length_squared() > 0.0:
			direction = desired
			rotation = direction.angle()

	var step := direction * speed * delta
	global_position += step
	traveled += step.length()
	if traveled >= max_range:
		_finish()

func _on_body_entered(body: Node) -> void:
	if body == null or body.is_queued_for_deletion():
		return
	var monster := body as Node2D
	if monster == null or not monster.is_in_group("monsters") or not monster.has_method("take_damage"):
		return
	var iid := monster.get_instance_id()
	if hit_ids.has(iid):
		return
	hit_ids[iid] = true

	match skill_type:
		"ice_bolt":
			monster.call("take_damage", damage)
			if is_instance_valid(source_hero) and source_hero.has_method("resolve_archmage_ice_bolt_hit"):
				source_hero.call("resolve_archmage_ice_bolt_hit", monster, global_position, empowered)
			_finish()
		"chain_dagger":
			var growth := maxf(float(config.get("damage_growth_per_bounce", 0.16)), 0.0)
			var hit_damage := maxi(1, int(round(float(damage) * (1.0 + growth * float(bounce_count)))))
			if empowered:
				hit_damage = maxi(1, int(round(float(hit_damage) * float(config.get("empowered_damage_multiplier", 1.50)))))
			monster.call("take_damage", hit_damage)
			_spawn_hit_animation("res://assets/art/heroes/stage5_archmage/frames/effect5", "light", 1, 6, 24.0, global_position)
			bounce_count += 1
			var max_bounces := maxi(int(config.get("max_bounces", 7)), 0)
			if bounce_count > max_bounces:
				_finish()
				return
			current_target = _find_nearest_unhit(monster.global_position, float(config.get("bounce_range", 420.0)))
			if not is_instance_valid(current_target):
				_finish()
				return
			direction = global_position.direction_to(current_target.global_position)
			traveled = 0.0
			max_range = maxf(float(config.get("bounce_range", 420.0)), 1.0)
		"storm":
			var hit_damage := damage
			if empowered:
				hit_damage = maxi(1, int(round(float(hit_damage) * float(config.get("empowered_damage_multiplier", 1.50)))))
			monster.call("take_damage", hit_damage)
			monster.set_meta(
				"archmage_root_until",
				Time.get_ticks_msec() + int(maxf(float(config.get("root_duration", 2.0)), 0.0) * 1000.0)
			)
			if is_instance_valid(source_hero) and source_hero.has_method("restore_archmage_gauge"):
				source_hero.call("restore_archmage_gauge", maxf(float(config.get("gauge_restore_per_hit", 4.0)), 0.0))

func _find_nearest_unhit(origin: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("monsters"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or hit_ids.has(monster.get_instance_id()):
			continue
		var distance := origin.distance_to(monster.global_position)
		if distance <= radius and distance < best_distance:
			best = monster
			best_distance = distance
	return best

func _finish() -> void:
	if skill_type == "chain_dagger" and is_instance_valid(source_hero):
		if source_hero.has_method("notify_archmage_chain_dagger_finished"):
			source_hero.call("notify_archmage_chain_dagger_finished")
	queue_free()

func _apply_visual() -> void:
	var dir := ""
	var prefix := ""
	var start := 1
	var count := 1
	match skill_type:
		"ice_bolt":
			dir = "res://assets/art/heroes/stage5_archmage/frames/effect4"
			prefix = "ice"
			start = 8
			count = 4
		"chain_dagger":
			dir = "res://assets/art/heroes/stage5_archmage/frames/effect5"
			prefix = "light"
			start = 8
			count = 4
		"storm":
			dir = "res://assets/art/heroes/stage5_archmage/frames/effect8"
			prefix = "wind"
			start = 1
			count = 6

	var frames := _build_frames(dir, prefix, start, count, 22.0, true)
	if frames != null:
		sprite.sprite_frames = frames
		sprite.visible = true
		sprite.play("fx")

	if skill_type == "storm":
		var tail_frames := _build_frames(
			"res://assets/art/heroes/stage5_archmage/frames/effect8",
			"wind",
			7,
			3,
			18.0,
			true
		)
		if tail_frames != null:
			tail.sprite_frames = tail_frames
			tail.visible = true
			tail.position = Vector2(-48.0, 0.0)
			tail.play("fx")

	rotation = direction.angle()

func _spawn_hit_animation(
	dir: String,
	prefix: String,
	start: int,
	count: int,
	fps: float,
	world_position: Vector2
) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return
	var fx := AnimatedSprite2D.new()
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 7
	fx.global_position = world_position
	fx.scale = Vector2(0.52, 0.52)
	var frames := _build_frames(dir, prefix, start, count, fps, false)
	if frames == null:
		return
	fx.sprite_frames = frames
	parent.add_child(fx)
	fx.animation_finished.connect(fx.queue_free)
	fx.play("fx")

func _build_frames(
	dir: String,
	prefix: String,
	start: int,
	count: int,
	fps: float,
	looped: bool
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("fx")
	frames.set_animation_speed("fx", fps)
	frames.set_animation_loop("fx", looped)
	for index in range(start, start + count):
		var path := "%s/%s_%02d.png" % [dir, prefix, index]
		var texture := _load_texture(path)
		if texture != null:
			frames.add_frame("fx", texture)
	if frames.get_frame_count("fx") <= 0:
		return null
	return frames

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
