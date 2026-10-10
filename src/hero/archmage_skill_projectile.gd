extends Area2D

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

const DAMAGE_RECEIPT := preload("res://src/systems/battle_damage_receipt.gd")
var _wave_damage_receipt

const DAMAGE_OBSERVATION := preload("res://src/systems/battle_damage_observation.gd")

const BATTLE_TARGET_REFERENCE := preload("res://src/systems/battle_target_reference.gd")
# Reuse these objects; only setup/bounce captures allocate WeakRefs.
var _chain_target_reference = BATTLE_TARGET_REFERENCE.new()
var _chain_source_reference = BATTLE_TARGET_REFERENCE.new()
var _chain_projectile_reference = BATTLE_TARGET_REFERENCE.new()
var _chain_life_revision := 0

static var _frames_cache: Dictionary = {}

const DEFAULT_SPRITE_SCALE := Vector2(0.60, 0.60)
const DEFAULT_TAIL_SCALE := Vector2(0.58, 0.58)

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
var previous_chain_hit_position := Vector2.ZERO
var has_previous_chain_hit := false
var storm_returning: bool = false
var storm_return_hit_ids: Dictionary = {}
var active: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var tail: AnimatedSprite2D = $Tail

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate_for_pool()


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
	_chain_life_revision += 1
	_clear_chain_references()
	skill_type = new_skill_type
	direction = new_direction.normalized()
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	config = new_config
	source_hero = new_source_hero
	empowered = is_empowered
	current_target = initial_target
	traveled = 0.0
	hit_ids.clear()
	bounce_count = 0
	previous_chain_hit_position = Vector2.ZERO
	has_previous_chain_hit = false
	storm_returning = false
	storm_return_hit_ids.clear()
	active = true
	visible = true
	if not is_in_group("hero_projectiles"):
		add_to_group("hero_projectiles")
	monitoring = true
	set_physics_process(true)
	_reset_visual_state()
	if skill_type == "chain_dagger":
		var scope := get_parent()
		if (
			not _chain_source_reference.capture(source_hero, scope)
			or not _chain_projectile_reference.capture(self, scope)
			or not _capture_chain_target()
		):
			_finish()
			return
	elif skill_type == "ice_bolt" or skill_type == "storm" or skill_type == "berserker_wave":
		var scope := get_parent()
		if not _chain_source_reference.capture(source_hero, scope) or not _chain_projectile_reference.capture(self, scope):
			_finish()
			return
	if skill_type == "berserker_wave" and _wave_damage_receipt == null:
		_wave_damage_receipt = DAMAGE_RECEIPT.new()
	_apply_visual()

func _physics_process(delta: float) -> void:
	if not active:
		return
	var life_revision := _chain_life_revision
	if (skill_type == "ice_bolt" or skill_type == "storm") and not _is_elemental_life_current(life_revision):
		_finish_elemental_revision(life_revision)
		return
	if skill_type == "chain_dagger" and not _is_chain_life_current(_chain_life_revision):
		_finish()
		return
	if skill_type == "chain_dagger" and not _is_chain_target_current():
		_finish()
		return
	if is_instance_valid(current_target) and not HERO_TARGET_POLICY.is_detectable(current_target):
		current_target = null
		_chain_target_reference.clear()
	if skill_type == "berserker_wave":
		if not _is_wave_life_current(life_revision):
			_finish_elemental_revision(life_revision)
			return
		var previous_position: Vector2 = global_position
		var wave_step: Vector2 = direction * speed * delta
		global_position += wave_step
		traveled += speed * delta
		_damage_berserker_wave_sweep(
			previous_position,
			global_position
		)
		if not _is_wave_life_current(life_revision):
			_finish_elemental_revision(life_revision)
			return
		if traveled >= max_range:
			_finish()
		return

	if skill_type == "storm":
		if storm_returning:
			if not is_instance_valid(source_hero):
				_finish()
				return

			var hero_node := source_hero as Node2D
			if hero_node == null:
				_finish()
				return

			var to_hero: Vector2 = hero_node.global_position - global_position
			if to_hero.length_squared() <= 55.0 * 55.0:
				_finish()
				return

			direction = to_hero.normalized()
			rotation = direction.angle()
			sprite.rotation = 0.0
			tail.rotation = 0.0

			var return_step: Vector2 = direction * speed * delta
			global_position += return_step
			_damage_storm_area(true)
			if not _is_elemental_life_current(life_revision):
				_finish_elemental_revision(life_revision)
			return

		var outward_step: Vector2 = direction * speed * delta
		global_position += outward_step
		traveled += speed * delta
		_damage_storm_area(false)
		if not _is_elemental_life_current(life_revision):
			_finish_elemental_revision(life_revision)
			return

		if traveled >= max_range:
			storm_returning = true
			traveled = 0.0
		return

		return

	if skill_type == "chain_dagger" and is_instance_valid(current_target):
		var desired := global_position.direction_to(current_target.global_position)
		if desired.length_squared() > 0.0:
			direction = desired.normalized()
			rotation = direction.angle()
			sprite.rotation = 0.0
			tail.rotation = 0.0

	var step := direction * speed * delta
	global_position += step
	traveled += speed * delta
	if traveled >= max_range:
		_finish()

func _damage_storm_area(returning: bool) -> void:
	var life_revision := _chain_life_revision
	if not _is_elemental_life_current(life_revision):
		return

	var radius: float = maxf(float(config.get("hit_radius", 125.0)), 1.0)
	var radius_sq: float = radius * radius
	var damaged_ids: Dictionary = hit_ids
	var damage_multiplier: float = 1.0
	if returning:
		damaged_ids = storm_return_hit_ids
		damage_multiplier = maxf(
			float(config.get("return_damage_multiplier", 0.50)),
			0.0
		)

	var hit_damage: int = maxi(
		1,
		int(round(float(damage) * damage_multiplier))
	)
	if empowered:
		hit_damage = maxi(
			1,
			int(round(
				float(hit_damage)
				* float(config.get("empowered_damage_multiplier", 1.50))
			))
		)

	var scope := get_parent()
	var tracked_targets := scope.has_method("get_battle_entity_handle")
	for node in _get_monster_nodes_near(global_position, radius):
		if not _is_elemental_life_current(life_revision):
			return
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if global_position.distance_squared_to(monster.global_position) > radius_sq:
			continue

		var iid: int = monster.get_instance_id()
		if damaged_ids.has(iid):
			continue
		damaged_ids[iid] = true

		var victim_handle := Vector3i.ZERO
		if tracked_targets:
			victim_handle = scope.call("get_battle_entity_handle", monster)
		monster.call("take_damage", hit_damage)
		if not _is_elemental_life_current(life_revision):
			return
		if is_instance_valid(monster) and not monster.is_queued_for_deletion() and (
			not tracked_targets or (victim_handle != Vector3i.ZERO and scope.call("resolve_battle_entity", victim_handle) == monster)
		):
			monster.set_meta(
				"archmage_root_until",
				Time.get_ticks_msec()
				+ int(
					maxf(float(config.get("root_duration", 2.0)), 0.0)
					* 1000.0
				)
			)

		if (
			not returning
			and source_hero.has_method("restore_archmage_gauge")
		):
			source_hero.call(
				"restore_archmage_gauge",
				maxf(float(config.get("gauge_restore_per_hit", 4.0)), 0.0)
			)
			if not _is_elemental_life_current(life_revision):
				return


func _damage_berserker_wave_sweep(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	var life_revision := _chain_life_revision
	if not _is_wave_life_current(life_revision):
		return
	var scope := get_parent()
	var tracked_targets := scope.has_method("get_battle_entity_handle")
	var hit_radius: float = maxf(
		float(config.get("hit_radius", 64.0)),
		1.0
	)
	var segment: Vector2 = to_position - from_position
	var length_sq: float = maxf(segment.length_squared(), 0.001)
	var search_radius: float = hit_radius + segment.length() + 24.0
	for node in _get_monster_nodes_near(
		from_position.lerp(to_position, 0.5),
		search_radius
	):
		if not _is_wave_life_current(life_revision):
			return
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue

		var iid: int = monster.get_instance_id()
		if hit_ids.has(iid):
			continue

		var t: float = clampf(
			(monster.global_position - from_position).dot(segment)
			/ length_sq,
			0.0,
			1.0
		)
		var closest: Vector2 = from_position + segment * t
		if (
			monster.global_position.distance_squared_to(closest)
			> hit_radius * hit_radius
		):
			continue

		hit_ids[iid] = true
		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		var victim_handle := Vector3i.ZERO
		if tracked_targets:
			victim_handle = scope.call("get_battle_entity_handle", monster)
		var uses_receipt := (
			monster.has_method("supports_damage_receipt")
			and monster.has_method("take_damage_with_result")
			and bool(monster.call("supports_damage_receipt"))
		)
		if not _is_wave_life_current(life_revision):
			return
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			continue
		if tracked_targets and victim_handle != Vector3i.ZERO and scope.call("resolve_battle_entity", victim_handle) != monster:
			continue
		var receipt_ready := false
		var receipt_revision: int = _wave_damage_receipt.revision + 1
		if uses_receipt:
			receipt_ready = bool(monster.call("take_damage_with_result", damage, _wave_damage_receipt))
		else:
			monster.call("take_damage", damage)
		if not _is_wave_life_current(life_revision):
			return

		# Copy the result before hit-heal callbacks can overwrite this shared buffer.
		var killed := false
		if uses_receipt:
			if (
				receipt_ready and _wave_damage_receipt.complete
				and _wave_damage_receipt.revision == receipt_revision
				and _wave_damage_receipt.victim_instance_id == iid
				and _wave_damage_receipt.victim_life == victim_handle
				and (not tracked_targets or _wave_damage_receipt.identity_verified)
			):
				# Preserve the legacy reward gate for targets already at HP0.
				killed = hp_before > 0 and _wave_damage_receipt.accepted and _wave_damage_receipt.death_started
		else:
			var observation := DAMAGE_OBSERVATION.observe_legacy_hit(
				monster if is_instance_valid(monster) else null, scope, victim_handle, hp_before
			)
			killed = DAMAGE_OBSERVATION.is_legacy_kill_candidate(observation)
		if source_hero.has_method("notify_berserker_blood_art_hit"):
			source_hero.call("notify_berserker_blood_art_hit")
			if not _is_wave_life_current(life_revision):
				return
		if killed and source_hero.has_method("notify_berserker_skill_kill"):
			source_hero.call("notify_berserker_skill_kill")
			if not _is_wave_life_current(life_revision):
				return


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	var life_revision := _chain_life_revision
	if skill_type == "chain_dagger" and (
		not _is_chain_life_current(life_revision) or not _is_chain_target_current()
	):
		_finish()
		return
	if skill_type == "ice_bolt" and not _is_elemental_life_current(life_revision):
		_finish_elemental_revision(life_revision)
		return
	if skill_type in ["storm", "berserker_wave"]:
		return
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
			var hit_position := global_position
			var scope := get_parent()
			var tracked_target := scope.has_method("get_battle_entity_handle")
			var victim_handle := Vector3i.ZERO
			if tracked_target:
				victim_handle = scope.call("get_battle_entity_handle", monster)
			monster.call("take_damage", damage)
			if not _is_elemental_life_current(life_revision):
				_finish_elemental_revision(life_revision)
				return
			var live_target: Node2D = null
			if is_instance_valid(monster) and not monster.is_queued_for_deletion() and (
				not tracked_target or (victim_handle != Vector3i.ZERO and scope.call("resolve_battle_entity", victim_handle) == monster)
			):
				live_target = monster
			if source_hero.has_method("resolve_archmage_ice_bolt_hit"):
				source_hero.call("resolve_archmage_ice_bolt_hit", live_target, hit_position, empowered)
			_finish_elemental_revision(life_revision)
		"chain_dagger":
			# Keep the impact origin valid even if damage frees/reuses the victim.
			var hit_position := monster.global_position
			var growth := maxf(
				float(config.get("damage_growth_per_bounce", 0.16)),
				0.0
			)
			var hit_damage := maxi(
				1,
				int(
					round(
						float(damage)
						* (1.0 + growth * float(bounce_count))
					)
				)
			)
			if empowered:
				hit_damage = maxi(
					1,
					int(
						round(
							float(hit_damage)
							* float(
								config.get(
									"empowered_damage_multiplier",
									1.50
								)
							)
						)
					)
				)
			monster.call("take_damage", hit_damage)
			# Damage callbacks may retire/reuse this projectile or its source.
			if not _is_chain_life_current(life_revision):
				return
			if (
				is_instance_valid(source_hero)
				and source_hero.has_method("play_archmage_chain_hit_audio")
			):
				source_hero.call("play_archmage_chain_hit_audio")
			if not _is_chain_life_current(life_revision):
				return
			_spawn_hit_animation(
				"res://assets/art/heroes/stage5_archmage/frames/effect5",
				"light",
				1,
				6,
				24.0,
				global_position
			)

			if not _is_chain_life_current(life_revision):
				return
			# A chain link belongs to the bounce that has actually arrived.
			# Do not preview the next link before the dagger reaches its target.
			if has_previous_chain_hit:
				_spawn_chain_current(
					previous_chain_hit_position,
					global_position
				)
			if not _is_chain_life_current(life_revision):
				return
			previous_chain_hit_position = global_position
			has_previous_chain_hit = true

			bounce_count += 1
			var max_bounces := maxi(
				int(config.get("max_bounces", 7)),
				0
			)
			if bounce_count > max_bounces:
				if bounce_count > 1:
					_finish_after_chain_ticks()
				else:
					_finish()
				return

			current_target = _find_nearest_unhit(
				hit_position,
				float(config.get("bounce_range", 600.0))
			)
			if not is_instance_valid(current_target) or not _capture_chain_target():
				if bounce_count > 1:
					_finish_after_chain_ticks()
				else:
					_finish()
				return

			direction = global_position.direction_to(
				current_target.global_position
			).normalized()
			rotation = direction.angle()
			traveled = 0.0
			max_range = maxf(
				float(config.get("bounce_range", 600.0)),
				1.0
			)

func _spawn_chain_current(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	var parent := get_parent()
	if not is_instance_valid(parent):
		return

	var segment := to_position - from_position
	var distance := segment.length()
	if distance <= 1.0:
		return

	var chain_duration_bonus := maxf(
		float(config.get("chain_duration_bonus", 0.0)),
		0.0
	)
	var base_visual_duration := 41.0 / 44.0
	var visual_duration := base_visual_duration + chain_duration_bonus
	var chain_fps := 41.0 / maxf(visual_duration, 0.05)
	var frames := _build_frames(
		"res://assets/art/heroes/stage5_archmage/frames/effect5",
		"chain",
		1,
		41,
		chain_fps,
		false
	)
	if frames != null:
		var fx: AnimatedSprite2D = null
		if parent.has_method("acquire_transient_fx"):
			fx = parent.call(
				"acquire_transient_fx",
				"archmage_chain_current_fx",
				"animated_sprite"
			) as AnimatedSprite2D
		if fx == null:
			fx = AnimatedSprite2D.new()
			parent.add_child(fx)

		fx.stop()
		fx.sprite_frames = frames
		fx.animation = &"fx"
		fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fx.z_index = 8
		fx.global_position = from_position.lerp(
			to_position,
			0.5
		)
		fx.rotation = segment.angle()
		# Source chain frames use a 320 px wide aligned canvas.
		# Stretch only along the link axis to bridge the two impacts.
		fx.scale = Vector2(
			maxf(distance / 320.0, 0.35),
			0.72
		)
		fx.modulate = Color.WHITE
		fx.frame = 0
		fx.frame_progress = 0.0
		fx.visible = true

		if parent.has_method("recycle_transient_fx"):
			fx.animation_finished.connect(
				Callable(
					parent,
					"recycle_transient_fx"
				).bind(
					fx,
					"archmage_chain_current_fx"
				),
				Object.CONNECT_ONE_SHOT
			)
		else:
			fx.animation_finished.connect(
				Callable(fx, "queue_free"),
				Object.CONNECT_ONE_SHOT
			)
		fx.play(&"fx")

	# Multi-hit damage starts at the same moment the arrived bounce
	# creates the visible link between the previous and current target.
	_apply_chain_current_ticks(
		from_position,
		to_position
	)


func _get_chain_tick_count() -> int:
	var base_count := maxi(
		int(config.get("chain_tick_count", 4)),
		1
	)
	var tick_interval := maxf(
		float(config.get("chain_tick_interval", 0.18)),
		0.01
	)
	var duration_bonus := maxf(
		float(config.get("chain_duration_bonus", 0.0)),
		0.0
	)
	var bonus_ticks := maxi(
		int(round(duration_bonus / tick_interval)),
		0
	)
	return base_count + bonus_ticks


func _finish_after_chain_ticks() -> void:
	var life_revision := _chain_life_revision
	set_physics_process(false)
	call_deferred("_disable_chain_monitoring", life_revision)
	sprite.visible = false
	tail.visible = false
	var tick_count := _get_chain_tick_count()
	var tick_interval := maxf(
		float(config.get("chain_tick_interval", 0.18)),
		0.01
	)
	var wait_time := (
		tick_interval
		* float(maxi(tick_count - 1, 0))
		+ 0.04
	)
	await get_tree().create_timer(wait_time).timeout
	# Only this local pool life may finish; a dead source still needs cleanup.
	if active and _chain_life_revision == life_revision and is_inside_tree():
		_finish()

func _apply_chain_current_ticks(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	var life_revision := _chain_life_revision
	var tick_count := _get_chain_tick_count()
	var tick_interval := maxf(float(config.get("chain_tick_interval", 0.18)), 0.01)
	var tick_ratio := maxf(float(config.get("chain_tick_damage_ratio", 0.11)), 0.0)
	var width := maxf(float(config.get("chain_width", 34.0)), 1.0)
	var tick_damage := maxi(1, int(round(float(damage) * tick_ratio)))
	if empowered:
		tick_damage = maxi(
			1,
			int(round(float(tick_damage) * float(config.get("empowered_damage_multiplier", 1.50))))
		)

	for tick_index in range(tick_count):
		if not _is_chain_life_current(life_revision):
			break
		_damage_monsters_along_segment(from_position, to_position, width, tick_damage)
		if not _is_chain_life_current(life_revision):
			break
		if tick_index < tick_count - 1:
			await get_tree().create_timer(tick_interval).timeout

func _get_monster_nodes() -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_cached"):
		var cached = source_hero.call("_get_monster_nodes_cached")
		if cached is Array:
			return cached
	return get_tree().get_nodes_in_group("monsters")


func _get_monster_nodes_near(origin: Vector2, radius: float) -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_near"):
		var nearby = source_hero.call("_get_monster_nodes_near", origin, radius)
		if nearby is Array:
			return nearby
	return _get_monster_nodes()


func _get_monster_nodes_in_rect(world_rect: Rect2) -> Array:
	if is_instance_valid(source_hero) and source_hero.has_method("_get_monster_nodes_in_rect"):
		var nearby = source_hero.call("_get_monster_nodes_in_rect", world_rect)
		if nearby is Array:
			return nearby
	return _get_monster_nodes()


func _damage_monsters_along_segment(
	from_position: Vector2,
	to_position: Vector2,
	half_width: float,
	tick_damage: int
) -> void:
	var life_revision := _chain_life_revision
	var segment := to_position - from_position
	var length_sq := maxf(segment.length_squared(), 0.001)
	var min_point := Vector2(
		minf(from_position.x, to_position.x) - half_width,
		minf(from_position.y, to_position.y) - half_width
	)
	var max_point := Vector2(
		maxf(from_position.x, to_position.x) + half_width,
		maxf(from_position.y, to_position.y) + half_width
	)
	var query_rect := Rect2(min_point, max_point - min_point)
	for node in _get_monster_nodes_in_rect(query_rect):
		if not _is_chain_life_current(life_revision):
			break
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		var t := clampf(
			(monster.global_position - from_position).dot(segment) / length_sq,
			0.0,
			1.0
		)
		var closest := from_position + segment * t
		if monster.global_position.distance_squared_to(closest) <= half_width * half_width:
			monster.call("take_damage", tick_damage)


func _find_nearest_unhit(origin: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in _get_monster_nodes_near(origin, radius):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var monster := node as Node2D
		if monster == null or hit_ids.has(monster.get_instance_id()):
			continue
		var distance := origin.distance_squared_to(monster.global_position)
		if distance <= radius * radius and distance < best_distance:
			best = monster
			best_distance = distance
	return best

func _finish() -> void:
	if not active:
		return

	var life_revision := _chain_life_revision
	var finished_skill_type := skill_type
	var should_notify := (
		finished_skill_type == "chain_dagger"
		and _chain_source_reference.resolve(get_parent()) == source_hero
		and is_instance_valid(source_hero)
	)
	# Consume before callbacks; a nested finish must not notify/recycle twice.
	active = false
	_clear_chain_references()
	if should_notify and source_hero.has_method("notify_archmage_chain_dagger_finished"):
		source_hero.call("notify_archmage_chain_dagger_finished")
	if _chain_life_revision != life_revision:
		return  # A callback has already recycled/reconfigured this Node.

	var pool_key := _pool_key_for_skill(finished_skill_type)
	var parent := get_parent()
	if (
		not pool_key.is_empty()
		and is_instance_valid(parent)
		and parent.has_method("recycle_projectile")
	):
		parent.call("recycle_projectile", self, pool_key)
	else:
		queue_free()


func _pool_key_for_skill(projectile_skill_type: String) -> String:
	match projectile_skill_type:
		"ice_bolt", "storm":
			return "archmage_skill_projectile"
		"chain_dagger":
			return "archmage_chain_dagger_projectile"
		"berserker_wave":
			return "berserker_wave_projectile"
		_:
			return ""


func deactivate_for_pool() -> void:
	_chain_life_revision += 1
	_clear_chain_references()
	active = false
	skill_type = ""
	direction = Vector2.RIGHT
	speed = 900.0
	max_range = 900.0
	traveled = 0.0
	damage = 1
	config = {}
	source_hero = null
	empowered = false
	hit_ids.clear()
	bounce_count = 0
	current_target = null
	previous_chain_hit_position = Vector2.ZERO
	has_previous_chain_hit = false
	storm_returning = false
	storm_return_hit_ids.clear()
	rotation = 0.0
	if is_in_group("hero_projectiles"):
		remove_from_group("hero_projectiles")
	monitoring = false
	set_physics_process(false)
	visible = false
	_reset_visual_state()


func _reset_visual_state() -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(tail):
		return
	sprite.stop()
	sprite.visible = false
	sprite.scale = DEFAULT_SPRITE_SCALE
	sprite.position = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.flip_h = false
	sprite.modulate = Color.WHITE
	sprite.frame = 0
	sprite.frame_progress = 0.0
	tail.stop()
	tail.visible = false
	tail.scale = DEFAULT_TAIL_SCALE
	tail.position = Vector2.ZERO
	tail.rotation = 0.0
	tail.flip_h = false
	tail.modulate = Color.WHITE
	tail.frame = 0
	tail.frame_progress = 0.0


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
			start = 5
			count = 2
		"berserker_wave":
			dir = "res://assets/art/heroes/stage6_berserker/frames/effect4"
			prefix = "heavy_slash"
			start = 1
			count = 11

	var frames := _build_frames(dir, prefix, start, count, 22.0, true)
	if frames != null:
		sprite.sprite_frames = frames
		sprite.visible = true
		sprite.play("fx")

	if skill_type == "berserker_wave":
		var visual_scale: float = maxf(
			float(config.get("visual_scale", 0.72)),
			0.1
		)
		sprite.scale = Vector2(visual_scale, visual_scale)
		sprite.flip_h = direction.x < 0.0
		sprite.rotation = (
			0.0
			if direction.x >= 0.0
			else PI
		)

	if skill_type == "storm":
		sprite.scale *= 2.176
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
			tail.scale *= 0.408
			tail.position = Vector2(-38.0, 0.0)
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

	var frames := _build_frames(dir, prefix, start, count, fps, false)
	if frames == null:
		return

	var fx: AnimatedSprite2D = null
	if parent.has_method("acquire_transient_fx"):
		fx = parent.call(
			"acquire_transient_fx",
			"archmage_skill_hit_fx",
			"animated_sprite"
		) as AnimatedSprite2D
	if fx == null:
		fx = AnimatedSprite2D.new()
		parent.add_child(fx)

	fx.stop()
	fx.sprite_frames = frames
	fx.animation = &"fx"
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 7
	fx.global_position = world_position
	fx.scale = Vector2(0.52, 0.52)
	fx.modulate = Color.WHITE
	fx.rotation = 0.0
	fx.frame = 0
	fx.frame_progress = 0.0
	fx.visible = true

	if parent.has_method("recycle_transient_fx"):
		fx.animation_finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				fx,
				"archmage_skill_hit_fx"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		fx.animation_finished.connect(
			Callable(fx, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)
	fx.play(&"fx")

func _build_frames(
	dir: String,
	prefix: String,
	start: int,
	count: int,
	fps: float,
	looped: bool
) -> SpriteFrames:
	var cache_key := "%s|%s|%d|%d|%.3f|%s" % [
		dir,
		prefix,
		start,
		count,
		fps,
		str(looped),
	]
	var cached = _frames_cache.get(cache_key)
	if cached is SpriteFrames:
		return cached

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
	_frames_cache[cache_key] = frames
	return frames

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _is_elemental_life_current(life_revision: int) -> bool:
	return (
		active and (skill_type == "ice_bolt" or skill_type == "storm")
		and _chain_life_revision == life_revision and is_inside_tree()
		and is_instance_valid(source_hero)
		and _chain_projectile_reference.resolve(get_parent()) == self
		and _chain_source_reference.resolve(get_parent()) == source_hero
	)

func _finish_elemental_revision(life_revision: int) -> void:
	# Source invalidation cancels this local shot; a reconfigured shot owns a new revision.
	if active and _chain_life_revision == life_revision and is_inside_tree():
		_finish()

func _capture_chain_target() -> bool:
	_chain_target_reference.clear()
	if current_target == null:
		return true  # Existing direction-only/undetectable-target behavior.
	return _chain_target_reference.capture(current_target, get_parent())

func _is_chain_target_current() -> bool:
	return current_target == null or _chain_target_reference.resolve(get_parent()) == current_target

func _is_chain_life_current(life_revision: int) -> bool:
	return (
		active and skill_type == "chain_dagger"
		and _chain_life_revision == life_revision and is_inside_tree()
		and is_instance_valid(source_hero)
		and _chain_projectile_reference.resolve(get_parent()) == self
		and _chain_source_reference.resolve(get_parent()) == source_hero
	)

func _clear_chain_references() -> void:
	_chain_target_reference.clear()
	_chain_source_reference.clear()
	_chain_projectile_reference.clear()


func _disable_chain_monitoring(life_revision: int) -> void:
	# Deferred property writes also belong to the life that scheduled them.
	if active and skill_type == "chain_dagger" and _chain_life_revision == life_revision:
		monitoring = false


func _is_wave_life_current(life_revision: int) -> bool:
	return (
		active and skill_type == "berserker_wave"
		and _chain_life_revision == life_revision and is_inside_tree()
		and is_instance_valid(source_hero)
		and _chain_projectile_reference.resolve(get_parent()) == self
		and _chain_source_reference.resolve(get_parent()) == source_hero
	)
