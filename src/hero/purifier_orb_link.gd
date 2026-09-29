extends Node2D

static var _frames_cache: SpriteFrames = null

var source_hero: Node = null
var damage_ratio: float = 0.0
var damage_interval: float = 0.22
var damage_timer: float = 0.22
var hit_half_width: float = 24.0
var segment_start: Vector2 = Vector2.ZERO
var segment_end: Vector2 = Vector2.ZERO
var _query_scratch: Array = []

@onready var visual: AnimatedSprite2D = $Visual


func setup(
	from_position: Vector2,
	to_position: Vector2,
	effect_dir: String,
	vertical_scale: float = 0.58,
	new_source_hero: Node = null,
	new_damage_ratio: float = 0.0,
	new_damage_interval: float = 0.22,
	new_hit_half_width: float = 24.0
) -> void:
	segment_start = from_position
	segment_end = to_position
	var segment := to_position - from_position
	var distance := segment.length()
	if distance <= 1.0:
		visible = false
		set_physics_process(false)
		return

	global_position = from_position.lerp(to_position, 0.5)
	rotation = segment.angle()
	z_index = 5

	visual.sprite_frames = _get_or_build_frames(effect_dir)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(
		maxf(distance / 320.0, 0.20),
		maxf(vertical_scale, 0.05)
	)
	visual.visible = true
	visual.frame = 0
	visual.frame_progress = 0.0
	if (
		visual.sprite_frames != null
		and visual.sprite_frames.has_animation(&"link")
	):
		visual.play(&"link")

	configure_damage(
		new_source_hero,
		new_damage_ratio,
		new_damage_interval,
		new_hit_half_width
	)


func configure_damage(
	new_source_hero: Node,
	new_damage_ratio: float,
	new_damage_interval: float = 0.22,
	new_hit_half_width: float = 24.0
) -> void:
	var was_enabled := damage_ratio > 0.0 and is_instance_valid(source_hero)
	source_hero = new_source_hero
	damage_ratio = maxf(new_damage_ratio, 0.0)
	damage_interval = maxf(new_damage_interval, 0.05)
	hit_half_width = maxf(new_hit_half_width, 1.0)
	var enabled := damage_ratio > 0.0 and is_instance_valid(source_hero)
	if enabled and not was_enabled:
		damage_timer = damage_interval
	set_physics_process(enabled)


func _physics_process(delta: float) -> void:
	if damage_ratio <= 0.0 or not is_instance_valid(source_hero):
		set_physics_process(false)
		return

	damage_timer -= delta
	if damage_timer > 0.0:
		return
	damage_timer += damage_interval
	if damage_timer <= 0.0:
		damage_timer = damage_interval
	_apply_damage_tick()


func _apply_damage_tick() -> void:
	if not is_instance_valid(source_hero):
		return
	var battle := source_hero.get_parent()
	if not is_instance_valid(battle):
		return

	var segment := segment_end - segment_start
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 1.0:
		return

	var query_radius := segment.length() * 0.5 + hit_half_width
	if battle.has_method("fill_monsters_near"):
		battle.call("fill_monsters_near", global_position, query_radius, _query_scratch)
	else:
		_query_scratch.clear()
		var tree := get_tree()
		if tree != null:
			_query_scratch.append_array(tree.get_nodes_in_group("monsters"))

	var attack_value = source_hero.get("attack_damage")
	if attack_value == null:
		_query_scratch.clear()
		return
	var raw_damage := maxf(float(attack_value) * damage_ratio, 1.0)
	var half_width_sq := hit_half_width * hit_half_width

	for raw_node in _query_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.has_method("take_damage")
			or not monster.is_in_group("monsters")
		):
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var t := clampf(
			(monster.global_position - segment_start).dot(segment)
			/ segment_length_sq,
			0.0,
			1.0
		)
		var closest := segment_start + segment * t
		if monster.global_position.distance_squared_to(closest) > half_width_sq:
			continue

		var holy_multiplier := 1.0
		if source_hero.has_method("get_purifier_holy_damage_multiplier"):
			holy_multiplier = maxf(
				float(source_hero.call("get_purifier_holy_damage_multiplier", monster)),
				0.0
			)
		var hit_damage := maxi(int(round(raw_damage * holy_multiplier)), 1)
		monster.call("take_damage", hit_damage)

	_query_scratch.clear()

static func _get_or_build_frames(effect_dir: String) -> SpriteFrames:
	if _frames_cache != null:
		return _frames_cache

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"link")
	frames.set_animation_loop(&"link", true)
	frames.set_animation_speed(&"link", 24.0)

	for frame_index in range(1, 42):
		var path := "%s/chain_%02d.png" % [effect_dir, frame_index]
		if not ResourceLoader.exists(path):
			continue
		var loaded = load(path)
		if loaded is Texture2D:
			frames.add_frame(&"link", loaded)

	_frames_cache = frames
	return frames
