extends RefCounted
## Alchemist archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _physics_process_alchemist(delta: float) -> void:
	_ensure_alchemist_runtime()

	hero.ai_memory_clock += delta
	hero._prune_offensive_memory()
	hero._prune_status_memory()
	hero.ai_observation_timer = maxf(hero.ai_observation_timer - delta, 0.0)
	if hero.ai_observation_timer <= 0.0:
		hero._refresh_ai_observation()

	hero.attack_timer = maxf(hero.attack_timer - delta * hero.get_paralysis_attack_multiplier(), 0.0)
	hero.retarget_timer = maxf(hero.retarget_timer - delta, 0.0)
	hero.wander_timer = maxf(hero.wander_timer - delta, 0.0)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer - delta, 0.0)
	hero.hit_pose_timer = maxf(hero.hit_pose_timer - delta, 0.0)
	hero._update_invulnerability(delta)
	hero.alchemist_equivalent_exchange_damage_reduction_timer = maxf(
		hero.alchemist_equivalent_exchange_damage_reduction_timer - delta,
		0.0
	)
	_update_alchemist_material_spawning(delta)
	hero._collect_nearby_alchemy_materials()
	hero.alchemist_philosopher_unlock_grace_timer = maxf(
		hero.alchemist_philosopher_unlock_grace_timer - delta,
		0.0
	)
	if _update_alchemist_philosopher_unlock_sequence(delta):
		return
	hero.alchemist_mixture_field_cooldown = maxf(hero.alchemist_mixture_field_cooldown - delta, 0.0)
	hero.alchemist_mystery_cauldron_cooldown = maxf(
		hero.alchemist_mystery_cauldron_cooldown - delta,
		0.0
	)
	hero.alchemist_emergency_cooldown = maxf(
		hero.alchemist_emergency_cooldown - delta,
		0.0
	)
	_update_alchemist_philosopher_gas_regen(delta)
	if (
		bool(hero.alchemist_philosopher_config.get("test_mode", false))
		and not hero.alchemist_philosopher_used
		and not hero.alchemist_philosopher_channeling
		and not hero.alchemist_transformed
	):
		hero.alchemist_philosopher_test_timer = maxf(
			hero.alchemist_philosopher_test_timer - delta,
			0.0
		)

	if _update_alchemist_philosopher_channel(delta):
		return
	if _try_start_alchemist_philosopher_stone():
		return

	# A pre-transformation vial burst may already be queued. Once the stone
	# is active, basic vial attacks are permanently disabled for this run.
	if not hero.alchemist_transformed:
		_update_alchemist_throw_sequence(delta)

	_update_alchemist_mixture_field_hero_effects(delta)
	_update_alchemist_field_locomotion_state(delta)
	if _update_alchemist_emergency_escape(delta):
		_update_alchemist_pose_visual(delta)
		return
	_try_cast_alchemist_mixture_field()
	_try_cast_alchemist_mystery_cauldron()

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0
			hero.queue_redraw()

	if hero.alchemist_transformed:
		_move_alchemist_philosopher_form(delta)
		_update_alchemist_pose_visual(delta)
		return

	var alchemist_move_speed := hero.move_speed * _get_alchemist_field_speed_multiplier()
	var basic_gas_cost := maxf(float(hero.alchemist_config.get("basic_gas_cost", 10.0)), 0.0)
	if hero.alchemist_gas + 0.001 < basic_gas_cost:
		var material_target := hero._find_nearest_active_alchemy_material()
		if is_instance_valid(material_target):
			var material_direction := hero.global_position.direction_to(material_target.global_position)
			var recovery_direction := material_direction
			var nearest_threat := hero._find_nearest_monster()
			if is_instance_valid(nearest_threat):
				var threat_distance := hero.global_position.distance_to(nearest_threat.global_position)
				if threat_distance < hero.kite_distance:
					var escape_direction := hero._choose_move_direction(
						nearest_threat,
						threat_distance
					)
					if escape_direction.length_squared() > 0.01:
						recovery_direction = (
							material_direction * 0.55
							+ escape_direction * 1.25
						).normalized()
			recovery_direction = hero._apply_ranged_boundary_escape(recovery_direction)
			hero._execute_ai_movement(recovery_direction * alchemist_move_speed * hero._get_effective_move_multiplier())
			_update_alchemist_pose_visual(delta)
			return

	hero._update_heal_item_goal(delta)
	hero._update_chest_goal(delta)
	hero._update_magnet_item_goal(delta)

	if not is_instance_valid(hero.target) or hero.target.is_queued_for_deletion() or hero.retarget_timer <= 0.0:
		hero.target = hero._find_nearest_monster()
		hero.retarget_timer = 0.12

	if not is_instance_valid(hero.target):
		hero._move_without_monsters()
		_update_alchemist_pose_visual(delta)
		return

	var distance := hero.global_position.distance_to(hero.target.global_position)
	var move_direction := hero._choose_move_direction(hero.target, distance)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)
	move_direction = hero._apply_ranged_boundary_escape(move_direction)
	hero._execute_ai_movement(move_direction * alchemist_move_speed * hero._get_effective_move_multiplier())

	if (
		distance <= hero.attack_range
		and hero.attack_timer <= 0.0
		and hero.alchemist_throw_index >= hero.alchemist_throw_positions.size()
	):
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.ALCHEMIST, _get_alchemist_chest_attack_target())

	_update_alchemist_pose_visual(delta)


func _ensure_alchemist_runtime() -> void:
	if hero.alchemist_runtime_ready or hero.hero_archetype != "alchemist_chemical":
		return
	var world_parent := hero.get_parent()
	if not is_instance_valid(world_parent):
		return

	# Base attack can reach 6 vials with Chemical Support. Keep enough pooled
	# projectiles for overlapping volleys so bonus vials are never dropped.
	for _index in range(16):
		var vial := hero.ALCHEMIST_VIAL_SCENE.instantiate() as Node2D
		if vial == null:
			continue
		world_parent.add_child(vial)
		vial.connect("landed", Callable(hero, "_on_alchemist_vial_landed"))
		hero.alchemist_vial_pool.append(vial)

	for _index in range(28):
		var poison := hero.ALCHEMIST_POISON_POOL_SCENE.instantiate() as Node2D
		if poison == null:
			continue
		world_parent.add_child(poison)
		poison.connect("damage_tick", Callable(hero, "_on_alchemist_poison_tick"))
		hero.alchemist_poison_pool.append(poison)

	var max_materials := clampi(int(hero.alchemist_config.get("material_max_count", 10)), 1, 10)
	for _index in range(max_materials):
		var material := hero.ALCHEMY_MATERIAL_SCENE.instantiate() as Node2D
		if material == null:
			continue
		world_parent.add_child(material)
		hero.alchemist_material_pool.append(material)

	var cauldron_count: int = clampi(
		int(hero.alchemist_mystery_cauldron_config.get("max_active", 2)) + 3,
		1,
		5
	)
	for _index in range(cauldron_count):
		var cauldron := hero.ALCHEMIST_CAULDRON_SCENE.instantiate() as Node2D
		if cauldron == null:
			continue
		world_parent.add_child(cauldron)
		cauldron.connect(
			"mix_completed",
			Callable(hero, "_on_alchemist_cauldron_completed")
		)
		hero.alchemist_cauldrons.append(cauldron)

	hero.alchemist_mixture_field = hero.ALCHEMIST_MIXTURE_FIELD_SCENE.instantiate() as Node2D
	if is_instance_valid(hero.alchemist_mixture_field):
		world_parent.add_child(hero.alchemist_mixture_field)
		hero.alchemist_mixture_field.connect(
			"field_tick",
			Callable(hero, "_on_alchemist_mixture_field_tick")
		)

	_ensure_alchemist_philosopher_unlock_effect()
	hero.alchemist_runtime_ready = true
	hero.alchemist_material_spawn_timer = 0.0
	var initial_count := clampi(
		int(hero.alchemist_config.get("initial_material_count", 6)),
		0,
		hero.alchemist_material_pool.size()
	)
	for _index in range(initial_count):
		hero._spawn_one_alchemy_material()


func _update_alchemist_material_spawning(delta: float) -> void:
	if not hero.alchemist_runtime_ready:
		return
	hero.alchemist_material_spawn_timer = maxf(hero.alchemist_material_spawn_timer - delta, 0.0)
	if hero.alchemist_material_spawn_timer > 0.0:
		return

	var active_count := hero._count_active_alchemy_materials()
	var max_count := mini(
		clampi(int(hero.alchemist_config.get("material_max_count", 10)), 1, 10),
		hero.alchemist_material_pool.size()
	)
	if active_count >= max_count:
		hero.alchemist_material_spawn_timer = 0.75
		return

	hero._spawn_one_alchemy_material()
	var gas_ratio := hero.alchemist_gas / maxf(hero.alchemist_gas_max, 1.0)
	if gas_ratio <= 0.001 and active_count < 3:
		hero.alchemist_material_spawn_timer = maxf(
			float(hero.alchemist_config.get("empty_spawn_interval", 0.8)),
			0.25
		)
	elif gas_ratio <= 0.30:
		hero.alchemist_material_spawn_timer = maxf(
			float(hero.alchemist_config.get("low_gas_spawn_interval", 2.0)),
			0.5
		)
	else:
		hero.alchemist_material_spawn_timer = maxf(
			float(hero.alchemist_config.get("material_spawn_interval", 4.0)),
			0.75
		)


func _add_alchemist_gas(amount: float) -> void:
	if amount <= 0.0:
		return
	hero.alchemist_gas = minf(hero.alchemist_gas + amount, hero.alchemist_gas_max)
	hero.queue_redraw()


func _consume_alchemist_gas(amount: float) -> bool:
	var cost := maxf(amount, 0.0)
	if hero.alchemist_gas + 0.001 < cost:
		return false
	hero.alchemist_gas = maxf(hero.alchemist_gas - cost, 0.0)
	hero.queue_redraw()
	return true


func _get_alchemist_augment_stacks(augment_id: String) -> int:
	return maxi(int(hero.build_counts.get(augment_id, 0)), 0)


func _get_alchemist_compressed_range_multiplier() -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_compressed_gas")
	return maxf(1.0 - 0.10 * float(stacks), 0.50)


func _get_alchemist_compressed_damage_multiplier() -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_compressed_gas")
	return 1.0 + 0.088 * float(stacks)


func _get_alchemist_speed_gap_damage_multiplier(monster: Node) -> float:
	var stacks := _get_alchemist_augment_stacks("alchemist_quick_decision")
	if stacks <= 0 or not is_instance_valid(monster):
		return 1.0
	var monster_speed_value = monster.get("move_speed")
	if monster_speed_value == null:
		return 1.0
	var speed_gap := absf(hero.move_speed - float(monster_speed_value))
	var gap_steps := int(floor(speed_gap / 20.0))
	return 1.0 + float(gap_steps * stacks) * 0.01


func _get_alchemist_equivalent_exchange_data(stacks: int) -> Dictionary:
	match clampi(stacks, 1, 5):
		1:
			return {"hp_cost_ratio": 0.03, "damage_multiplier": 1.20, "range_multiplier": 1.00, "material_refund_chance": 0.0, "damage_reduction": 0.0}
		2:
			return {"hp_cost_ratio": 0.025, "damage_multiplier": 1.35, "range_multiplier": 1.00, "material_refund_chance": 0.20, "damage_reduction": 0.0}
		3:
			return {"hp_cost_ratio": 0.02, "damage_multiplier": 1.50, "range_multiplier": 1.15, "material_refund_chance": 0.35, "damage_reduction": 0.0}
		4:
			return {"hp_cost_ratio": 0.015, "damage_multiplier": 1.70, "range_multiplier": 1.25, "material_refund_chance": 0.50, "damage_reduction": 0.10}
		_:
			return {"hp_cost_ratio": 0.01, "damage_multiplier": 2.00, "range_multiplier": 1.35, "material_refund_chance": 0.70, "damage_reduction": 0.20}


func _get_alchemist_equivalent_damage_multiplier() -> float:
	if not hero.alchemist_equivalent_exchange_active:
		return 1.0
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return 1.0
	return float(_get_alchemist_equivalent_exchange_data(stacks).get("damage_multiplier", 1.0))


func _get_alchemist_equivalent_range_multiplier() -> float:
	if not hero.alchemist_equivalent_exchange_active:
		return 1.0
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return 1.0
	return float(_get_alchemist_equivalent_exchange_data(stacks).get("range_multiplier", 1.0))


func _try_pay_alchemist_equivalent_exchange(required_materials: int) -> bool:
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return false
	if hero.alchemist_materials_collected >= required_materials:
		return true
	if hero.current_hp <= int(ceil(float(hero.max_hp) * 0.20)):
		return false

	var missing := maxi(required_materials - hero.alchemist_materials_collected, 0)
	if missing <= 0:
		return true
	var data := _get_alchemist_equivalent_exchange_data(stacks)
	var hp_cost := maxi(
		1,
		int(ceil(
			float(hero.current_hp)
			* float(data.get("hp_cost_ratio", 0.03))
			* float(missing)
		))
	)
	hero.alchemist_equivalent_exchange_paid_hp = mini(hp_cost, hero.current_hp - 1)
	hero.current_hp = maxi(hero.current_hp - hero.alchemist_equivalent_exchange_paid_hp, 1)
	hero.alchemist_materials_collected = required_materials
	hero.alchemist_equivalent_exchange_active = true
	if float(data.get("damage_reduction", 0.0)) > 0.0:
		hero.alchemist_equivalent_exchange_damage_reduction_timer = 3.0
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	hero.queue_redraw()
	return true


func _on_alchemist_equivalent_exchange_kill() -> void:
	if not hero.alchemist_equivalent_exchange_active:
		return
	var stacks := _get_alchemist_augment_stacks("alchemist_equivalent_exchange")
	if stacks <= 0:
		return
	var data := _get_alchemist_equivalent_exchange_data(stacks)
	var refund_chance := float(data.get("material_refund_chance", 0.0))
	if refund_chance > 0.0 and randf() < refund_chance:
		var required := maxi(
			int(hero.alchemist_philosopher_config.get("required_materials", 20)),
			1
		)
		hero.alchemist_materials_collected = mini(hero.alchemist_materials_collected + 1, required)
	if stacks >= 5 and hero.alchemist_equivalent_exchange_paid_hp > 0:
		var heal_amount := int(round(float(hero.alchemist_equivalent_exchange_paid_hp) * 0.50))
		hero.current_hp = mini(hero.current_hp + hero._get_reduced_healing(maxi(heal_amount, 1)), hero.max_hp)
		hero.alchemist_equivalent_exchange_paid_hp = 0
		hero.health_changed.emit(hero.current_hp, hero.max_hp)


func _deal_alchemist_dot_damage(monster: Node, base_damage: int) -> void:
	if not is_instance_valid(monster) or not monster.has_method("take_damage"):
		return
	var before_hp_value = monster.get("current_hp")
	var before_hp := int(before_hp_value) if before_hp_value != null else -1
	var multiplier := (
		_get_alchemist_compressed_damage_multiplier()
		* _get_alchemist_speed_gap_damage_multiplier(monster)
	)
	var final_damage := maxi(1, int(round(float(base_damage) * multiplier)))
	preload("res://src/systems/monster_hit_context.gd").hit(monster, final_damage, "ranged", hero)
	if before_hp > 0:
		var after_hp_value = monster.get("current_hp")
		if after_hp_value != null and int(after_hp_value) <= 0:
			_on_alchemist_equivalent_exchange_kill()


func _get_alchemist_mystery_cauldron_cooldown_total() -> float:
	var base := _get_alchemist_effective_cooldown(
		hero.alchemist_mystery_cauldron_config,
		20.0
	)
	var stacks := _get_alchemist_augment_stacks("alchemist_quick_preparation")
	return base * maxf(1.0 - 0.10 * float(stacks), 0.10)


func _get_alchemist_effective_cooldown(
	config: Dictionary,
	fallback: float
) -> float:
	var base_cooldown := maxf(float(config.get("cooldown", fallback)), 0.0)
	if not hero.alchemist_transformed:
		return base_cooldown
	return (
		base_cooldown
		* clampf(
			float(hero.alchemist_philosopher_config.get(
				"skill_cooldown_multiplier",
				0.70
			)),
			0.05,
			1.0
		)
	)


func _check_alchemist_philosopher_unlock() -> void:
	if hero.alchemist_philosopher_config.is_empty():
		return
	var required := maxi(
		int(hero.alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	if hero.alchemist_materials_collected < required:
		return

	var skill_id := String(hero.alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	if (
		hero.alchemist_philosopher_unlock_pending
		or hero.is_conditional_skill_unlocked(skill_id)
	):
		return

	hero.alchemist_philosopher_unlock_pending = true
	hero.alchemist_philosopher_unlock_timer = maxf(
		float(hero.alchemist_philosopher_config.get(
			"unlock_effect_seconds",
			0.55
		)),
		0.1
	)
	hero.velocity = Vector2.ZERO
	_play_alchemist_philosopher_unlock_effect()


func _update_alchemist_philosopher_unlock_sequence(delta: float) -> bool:
	if not hero.alchemist_philosopher_unlock_pending:
		return false

	hero.velocity = Vector2.ZERO
	hero.alchemist_philosopher_unlock_timer = maxf(
		hero.alchemist_philosopher_unlock_timer - delta,
		0.0
	)
	if hero.alchemist_philosopher_unlock_timer > 0.0:
		return true

	hero.alchemist_philosopher_unlock_pending = false
	if is_instance_valid(hero.alchemist_philosopher_unlock_effect):
		hero.alchemist_philosopher_unlock_effect.stop()
		hero.alchemist_philosopher_unlock_effect.visible = false

	var required := maxi(
		int(hero.alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var skill_id := String(hero.alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	hero._unlock_conditional_skill(
		skill_id,
		String(hero.alchemist_philosopher_config.get("name", "현자의 돌")),
		"material_count",
		hero.alchemist_materials_collected,
		required,
		{
			"hero_id": hero.hero_id,
			"archetype": hero.hero_archetype,
			"source": "alchemist_material_collection",
			"cutscene_texture_path": String(
				hero.alchemist_philosopher_config.get(
					"cutscene_texture_path",
					"res://assets/art/heroes/stage7_alchemist/cutscene/stage7_hero_cutscene.png"
				)
			),
			"cutscene_hold_seconds": float(
				hero.alchemist_philosopher_config.get(
					"cutscene_hold_seconds",
					1.20
				)
			),
		}
	)
	# The unlock signal starts the modal cutscene synchronously. Keep a small
	# post-cutscene grace so the Stone does not auto-channel on the same frame.
	hero.alchemist_philosopher_unlock_grace_timer = 0.18
	return true


func _ensure_alchemist_philosopher_unlock_effect() -> void:
	if is_instance_valid(hero.alchemist_philosopher_unlock_effect):
		return

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("unlock")
	frames.set_animation_speed(
		"unlock",
		maxf(
			float(hero.alchemist_philosopher_config.get(
				"unlock_effect_fps",
				9.0
			)),
			1.0
		)
	)
	frames.set_animation_loop("unlock", false)

	for index in range(1, 5):
		var texture := hero._load_stage1_texture(
			"%s/effect7/cast_%02d.png" % [hero.STAGE7_FRAME_DIR, index]
		)
		if texture != null:
			frames.add_frame("unlock", texture)

	if frames.get_frame_count("unlock") <= 0:
		return

	var effect := AnimatedSprite2D.new()
	effect.name = "AlchemistPhilosopherUnlockEffect"
	effect.sprite_frames = frames
	effect.animation = &"unlock"
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Same effect7 anchor correction as the Stone channel effect.
	effect.offset = Vector2(64.0, -144.0)
	effect.position = Vector2.ZERO
	effect.scale = Vector2.ONE * maxf(
		float(hero.alchemist_philosopher_config.get(
			"unlock_effect_scale",
			0.58
		)),
		0.05
	)
	effect.z_index = 11
	effect.modulate = Color(1.0, 0.92, 0.66, 1.0)
	effect.visible = false
	hero.add_child(effect)
	hero.alchemist_philosopher_unlock_effect = effect


func _play_alchemist_philosopher_unlock_effect() -> void:
	_ensure_alchemist_philosopher_unlock_effect()
	if not is_instance_valid(hero.alchemist_philosopher_unlock_effect):
		return

	hero.alchemist_philosopher_unlock_effect.stop()
	hero.alchemist_philosopher_unlock_effect.visible = true
	hero.alchemist_philosopher_unlock_effect.frame = 0
	hero.alchemist_philosopher_unlock_effect.frame_progress = 0.0
	hero.alchemist_philosopher_unlock_effect.play(&"unlock")


func _try_start_alchemist_philosopher_stone() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if (
		hero.alchemist_philosopher_config.is_empty()
		or hero.alchemist_philosopher_used
		or hero.alchemist_philosopher_channeling
		or hero.alchemist_transformed
	):
		return false

	var required_materials := maxi(
		int(hero.alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var test_ready := (
		bool(hero.alchemist_philosopher_config.get("test_mode", false))
		and hero.alchemist_philosopher_test_timer <= 0.0
	)
	var skill_id := String(hero.alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	# Philosopher's Stone is a strict collection milestone. Equivalent Exchange
	# may substitute materials for normal alchemy, but it must never synthesize
	# the 20/20 Stone progress or trigger the transformation early.
	if not test_ready:
		if hero.alchemist_materials_collected < required_materials:
			return false
		if (
			hero.alchemist_philosopher_unlock_pending
			or hero.alchemist_philosopher_unlock_grace_timer > 0.0
			or not hero.is_conditional_skill_unlocked(skill_id)
		):
			return false

	var gas_cost := maxf(
		float(hero.alchemist_philosopher_config.get("gas_cost", 100.0)),
		0.0
	)
	if hero.alchemist_gas + 0.001 < gas_cost:
		return false
	if not _consume_alchemist_gas(gas_cost):
		return false

	hero.alchemist_philosopher_used = true
	hero.alchemist_philosopher_channeling = true
	var fps := maxf(
		float(hero.alchemist_philosopher_config.get("channel_fps", 8.0)),
		1.0
	)
	hero.alchemist_philosopher_channel_timer = 12.0 / fps
	hero.velocity = Vector2.ZERO
	hero.alchemist_throw_positions.clear()
	hero.alchemist_throw_index = 0
	hero.alchemist_throw_timer = 0.0
	hero.alchemist_direct_chest_target = null

	if is_instance_valid(hero.hero_sprite):
		hero.hero_sprite.visible = false
		hero.channel_hid_hero_sprite = true
	if (
		is_instance_valid(hero.channel_effect)
		and hero.channel_effect.sprite_frames != null
		and hero.channel_effect.sprite_frames.has_animation("philosopher_stone")
	):
		hero.channel_effect.stop()
		hero.channel_effect.frame = 0
		hero.channel_effect.frame_progress = 0.0
		hero.channel_effect.visible = true
		hero.channel_effect.play(&"philosopher_stone")
	return true


func _update_alchemist_philosopher_channel(delta: float) -> bool:
	if not hero.alchemist_philosopher_channeling:
		return false

	hero.velocity = Vector2.ZERO
	hero.alchemist_philosopher_channel_timer = maxf(
		hero.alchemist_philosopher_channel_timer - delta,
		0.0
	)
	if hero.alchemist_philosopher_channel_timer > 0.0:
		return true

	hero.alchemist_philosopher_channeling = false
	if is_instance_valid(hero.channel_effect):
		hero.channel_effect.stop()
		hero.channel_effect.visible = false
	if hero.channel_hid_hero_sprite and is_instance_valid(hero.hero_sprite) and not hero.is_dying:
		hero.hero_sprite.visible = true
	hero.channel_hid_hero_sprite = false
	_activate_alchemist_philosopher_form()
	return true


func _activate_alchemist_philosopher_form() -> void:
	if hero.alchemist_transformed:
		return
	hero.alchemist_transformed = true

	var hp_multiplier := maxf(
		float(hero.alchemist_philosopher_config.get("hp_multiplier", 1.50)),
		1.0
	)
	var attack_multiplier := maxf(
		float(hero.alchemist_philosopher_config.get("attack_multiplier", 1.50)),
		1.0
	)
	var speed_multiplier := maxf(
		float(hero.alchemist_philosopher_config.get("move_speed_multiplier", 1.22)),
		1.0
	)
	hero.max_hp = maxi(1, int(round(float(hero.max_hp) * hp_multiplier)))
	hero.current_hp = clampi(
		int(round(float(hero.current_hp) * hp_multiplier)),
		1,
		hero.max_hp
	)
	hero.attack_damage = maxi(
		1,
		int(round(float(hero.attack_damage) * attack_multiplier))
	)
	hero.base_attack_damage_for_level_growth *= attack_multiplier
	hero.move_speed *= speed_multiplier
	if hero.player_controlled and hero.player_weapons != null and hero.player_weapons.identity != null:
		hero.player_weapons.identity.permanent_growth(hp_multiplier,speed_multiplier)

	var cooldown_multiplier := clampf(
		float(hero.alchemist_philosopher_config.get(
			"skill_cooldown_multiplier",
			0.70
		)),
		0.05,
		1.0
	)
	hero.alchemist_mixture_field_cooldown *= cooldown_multiplier
	hero.alchemist_mystery_cauldron_cooldown *= cooldown_multiplier
	hero.alchemist_emergency_cooldown *= cooldown_multiplier

	hero.alchemist_gas_regen_timer = maxf(
		float(hero.alchemist_philosopher_config.get("gas_regen_interval", 5.0)),
		0.1
	)
	hero.alchemist_poison_trail_timer = 0.0
	hero.alchemist_poison_trail_last_position = hero.global_position
	hero.alchemist_poison_trail_has_position = true
	hero.target = null
	hero.attack_timer = 0.0
	hero.attack_pose_timer = 0.0

	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	hero.queue_redraw()
	if is_instance_valid(hero.alchemist_philosopher_audio):
		hero.alchemist_philosopher_audio.stop()
		hero.alchemist_philosopher_audio.play()


func _update_alchemist_philosopher_gas_regen(delta: float) -> void:
	if not hero.alchemist_transformed:
		return
	hero.alchemist_gas_regen_timer -= delta
	if hero.alchemist_gas_regen_timer > 0.0:
		return

	var interval := maxf(
		float(hero.alchemist_philosopher_config.get("gas_regen_interval", 5.0)),
		0.1
	)
	var amount := maxf(
		float(hero.alchemist_philosopher_config.get("gas_regen_amount", 10.0)),
		0.0
	)
	_add_alchemist_gas(amount)
	hero.alchemist_gas_regen_timer += interval


func _move_alchemist_philosopher_form(delta: float) -> void:
	if (
		hero.wander_timer <= 0.0
		or hero.global_position.distance_squared_to(hero.wander_target)
		<= hero.WANDER_REACHED_DISTANCE * hero.WANDER_REACHED_DISTANCE
	):
		hero._pick_new_wander_target()

	var desired := hero.global_position.direction_to(hero.wander_target)
	var sense_radius := maxf(hero.ai_sense_radius, 520.0)
	var repulsion := Vector2.ZERO
	var sense_radius_sq := sense_radius * sense_radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		sense_radius,
		hero.alchemist_movement_query_candidates
	)
	for node in hero.alchemist_movement_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := hero.global_position - monster.global_position
		var distance_sq := offset.length_squared()
		if distance_sq <= 0.01 or distance_sq > sense_radius_sq:
			continue
		var distance := sqrt(distance_sq)
		var pressure := 1.0 - clampf(distance / sense_radius, 0.0, 1.0)
		repulsion += offset / distance * (0.35 + pressure * pressure * 2.4)
	hero.alchemist_movement_query_candidates.clear()

	if repulsion.length_squared() > 0.01:
		desired = desired * 0.55 + repulsion * 1.55

	var soft_margin := 330.0
	var inward := Vector2.ZERO
	var left_space := hero.global_position.x - hero.FIELD_MARGIN
	var right_space := hero.battlefield_size.x - hero.FIELD_MARGIN - hero.global_position.x
	var top_space := hero.global_position.y - hero.FIELD_MARGIN
	var bottom_space := hero.battlefield_size.y - hero.FIELD_MARGIN - hero.global_position.y
	if left_space < soft_margin:
		inward.x += 1.0 - clampf(left_space / soft_margin, 0.0, 1.0)
	if right_space < soft_margin:
		inward.x -= 1.0 - clampf(right_space / soft_margin, 0.0, 1.0)
	if top_space < soft_margin:
		inward.y += 1.0 - clampf(top_space / soft_margin, 0.0, 1.0)
	if bottom_space < soft_margin:
		inward.y -= 1.0 - clampf(bottom_space / soft_margin, 0.0, 1.0)
	if inward.length_squared() > 0.01:
		desired += inward.normalized() * 2.2

	if desired.length_squared() <= 0.01:
		desired = hero.global_position.direction_to(hero.battlefield_size * 0.5)
	if desired.length_squared() <= 0.01:
		desired = Vector2.RIGHT
	desired = hero._apply_ranged_boundary_escape(desired, 360.0, 155.0)

	var speed := (
		hero.move_speed
		* _get_alchemist_field_speed_multiplier()
		* hero._get_effective_move_multiplier()
	)
	hero.velocity = desired.normalized() * speed
	hero._move_and_slide_with_obstacle_escape()
	hero._clamp_to_battlefield()
	_update_alchemist_poison_trail(delta)


func _update_alchemist_poison_trail(delta: float) -> void:
	if not hero.alchemist_transformed:
		return

	hero.alchemist_poison_trail_timer = maxf(
		hero.alchemist_poison_trail_timer - delta,
		0.0
	)
	if hero.alchemist_poison_trail_timer > 0.0 or hero.velocity.length_squared() <= 16.0:
		return

	var min_spacing := maxf(
		float(hero.alchemist_philosopher_config.get("trail_min_spacing", 36.0)),
		1.0
	)
	if (
		hero.alchemist_poison_trail_has_position
		and hero.global_position.distance_squared_to(hero.alchemist_poison_trail_last_position)
		< min_spacing * min_spacing
	):
		return

	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(float(hero.alchemist_philosopher_config.get(
				"trail_tick_damage_ratio",
				0.18
			)), 0.0)
			* maxf(float(hero.alchemist_philosopher_config.get(
				"poison_damage_multiplier",
				1.50
			)), 0.0)
			* _get_alchemist_equivalent_damage_multiplier()
		))
	)
	for poison_node in hero.alchemist_poison_pool:
		if not is_instance_valid(poison_node):
			continue
		if not bool(poison_node.call("is_available")):
			continue
		poison_node.call(
			"activate",
			hero.global_position,
			maxf(float(hero.alchemist_philosopher_config.get(
				"trail_duration",
				2.0
			)), 0.1),
			maxf(
				float(hero.alchemist_philosopher_config.get(
					"trail_radius",
					115.0
				))
				* _get_alchemist_compressed_range_multiplier()
				* _get_alchemist_equivalent_range_multiplier(),
				1.0
			),
			maxf(float(hero.alchemist_philosopher_config.get(
				"trail_tick_interval",
				0.30
			)), 0.03),
			damage,
			_get_alchemist_compressed_range_multiplier()
		)
		hero.alchemist_poison_trail_last_position = hero.global_position
		hero.alchemist_poison_trail_has_position = true
		hero.alchemist_poison_trail_timer = maxf(
			float(hero.alchemist_philosopher_config.get(
				"trail_spawn_interval",
				0.22
			)),
			0.05
		)
		return


func _is_alchemist_inside_mixture_field() -> bool:
	return (
		is_instance_valid(hero.alchemist_mixture_field)
		and bool(hero.alchemist_mixture_field.get("active"))
		and bool(hero.alchemist_mixture_field.call("contains_world_point", hero.global_position))
	)


func _get_alchemist_field_speed_multiplier() -> float:
	if not _is_alchemist_inside_mixture_field():
		return 1.0
	return maxf(
		float(hero.alchemist_mixture_field_config.get("hero_move_speed_multiplier", 1.30)),
		1.0
	)


func _is_alchemist_inside_mixture_field_with_margin(margin: float) -> bool:
	if not is_instance_valid(hero.alchemist_mixture_field):
		return false
	if not bool(hero.alchemist_mixture_field.get("active")):
		return false

	var field_radius := maxf(float(hero.alchemist_mixture_field.get("radius")) + margin, 1.0)
	return (
		hero.alchemist_mixture_field.global_position.distance_squared_to(hero.global_position)
		<= field_radius * field_radius
	)


func _update_alchemist_field_locomotion_state(delta: float) -> void:
	var enter_delay := maxf(
		float(hero.alchemist_mixture_field_config.get("run_enter_delay", 0.08)),
		0.0
	)
	var exit_delay := maxf(
		float(hero.alchemist_mixture_field_config.get("run_exit_delay", 0.12)),
		0.0
	)
	var exit_margin := maxf(
		float(hero.alchemist_mixture_field_config.get("run_exit_margin", 24.0)),
		0.0
	)

	if not hero.alchemist_field_run_active:
		hero.alchemist_field_run_exit_timer = 0.0
		if not _is_alchemist_inside_mixture_field():
			hero.alchemist_field_run_enter_timer = 0.0
			return

		hero.alchemist_field_run_enter_timer += delta
		if hero.alchemist_field_run_enter_timer >= enter_delay:
			hero.alchemist_field_run_active = true
			hero.alchemist_field_run_enter_timer = 0.0
		return

	hero.alchemist_field_run_enter_timer = 0.0
	if _is_alchemist_inside_mixture_field_with_margin(exit_margin):
		hero.alchemist_field_run_exit_timer = 0.0
		return

	hero.alchemist_field_run_exit_timer += delta
	if hero.alchemist_field_run_exit_timer >= exit_delay:
		hero.alchemist_field_run_active = false
		hero.alchemist_field_run_exit_timer = 0.0


func _update_alchemist_mixture_field_hero_effects(delta: float) -> void:
	if not _is_alchemist_inside_mixture_field():
		hero.alchemist_mixture_heal_timer = 0.0
		return

	hero.alchemist_mixture_heal_timer = maxf(hero.alchemist_mixture_heal_timer - delta, 0.0)
	if hero.alchemist_mixture_heal_timer > 0.0:
		return

	var heal_ratio := maxf(
		float(hero.alchemist_mixture_field_config.get("heal_max_hp_ratio", 0.01)),
		0.0
	)
	if heal_ratio > 0.0:
		hero.heal_direct(maxi(1, int(round(float(hero.max_hp) * heal_ratio))))
	hero.alchemist_mixture_heal_timer = maxf(
		float(hero.alchemist_mixture_field_config.get("heal_interval", 1.0)),
		0.1
	)


func _try_cast_alchemist_mixture_field() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.alchemist_mixture_field_config.is_empty():
		return
	if hero.alchemist_mixture_field_cooldown > 0.0:
		return
	if not is_instance_valid(hero.alchemist_mixture_field):
		return
	if bool(hero.alchemist_mixture_field.get("active")):
		return

	var gas_cost := maxf(
		float(hero.alchemist_mixture_field_config.get("gas_cost", 30.0)),
		0.0
	)
	if hero.alchemist_gas + 0.001 < gas_cost:
		return

	var radius := maxf(
		float(hero.alchemist_mixture_field_config.get("radius", 660.0))
		* _get_alchemist_compressed_range_multiplier(),
		1.0
	)
	var required_enemies := maxi(
		int(hero.alchemist_mixture_field_config.get("enemy_count_trigger", 2)),
		1
	)
	var nearby_enemies := hero._count_monsters_near(
		hero.global_position,
		radius,
		required_enemies
	)
	if nearby_enemies < required_enemies:
		return

	if not _consume_alchemist_gas(gas_cost):
		return

	hero.alchemist_mixture_field_cooldown = _get_alchemist_effective_cooldown(
		hero.alchemist_mixture_field_config,
		20.0
	)
	hero.alchemist_mixture_heal_timer = 0.0
	hero.alchemist_mixture_field.call(
		"activate",
		hero.global_position,
		radius,
		maxf(float(hero.alchemist_mixture_field_config.get("duration", 8.0)), 0.1),
		maxf(float(hero.alchemist_mixture_field_config.get("tick_interval", 0.50)), 0.05)
	)


func _count_active_alchemist_cauldrons() -> int:
	var count: int = 0
	for cauldron in hero.alchemist_cauldrons:
		if is_instance_valid(cauldron) and bool(cauldron.get("active")):
			count += 1
	return count


func _try_cast_alchemist_mystery_cauldron() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.alchemist_mystery_cauldron_config.is_empty():
		return
	if hero.alchemist_mystery_cauldron_cooldown > 0.0:
		return

	var quick_prep_stacks := _get_alchemist_augment_stacks("alchemist_quick_preparation")
	var max_active: int = clampi(
		int(hero.alchemist_mystery_cauldron_config.get("max_active", 2))
		+ quick_prep_stacks,
		1,
		hero.alchemist_cauldrons.size()
	)
	if _count_active_alchemist_cauldrons() >= max_active:
		return

	var cauldron_to_use: Node2D = null
	for cauldron in hero.alchemist_cauldrons:
		if is_instance_valid(cauldron) and not bool(cauldron.get("active")):
			cauldron_to_use = cauldron
			break
	if cauldron_to_use == null:
		return

	var angle: float = randf() * TAU
	var placement_radius: float = randf_range(90.0, 145.0)
	var placement: Vector2 = (
		hero.global_position
		+ Vector2.from_angle(angle) * placement_radius
	)
	var margin: float = 96.0
	placement.x = clampf(placement.x, margin, hero.battlefield_size.x - margin)
	placement.y = clampf(placement.y, margin, hero.battlefield_size.y - margin)

	var min_mix: float = maxf(
		float(hero.alchemist_mystery_cauldron_config.get("mix_time_min", 8.0)),
		0.1
	)
	var max_mix: float = maxf(
		float(hero.alchemist_mystery_cauldron_config.get("mix_time_max", 10.0)),
		min_mix
	)
	var mix_duration: float = randf_range(min_mix, max_mix)
	cauldron_to_use.call("activate", placement, mix_duration)
	hero.alchemist_mystery_cauldron_cooldown = (
		_get_alchemist_mystery_cauldron_cooldown_total()
	)


func set_alchemist_cauldron_runtime_paused(paused: bool) -> void:
	if hero.hero_archetype != "alchemist_chemical":
		return
	for cauldron in hero.alchemist_cauldrons:
		if not is_instance_valid(cauldron):
			continue
		if paused:
			cauldron.set_process(false)
		elif bool(cauldron.get("active")):
			cauldron.set_process(true)


func _on_alchemist_cauldron_completed(
	cauldron: Node2D,
	origin: Vector2
) -> void:
	if not is_instance_valid(cauldron):
		return

	var success_mother_stacks := _get_alchemist_augment_stacks(
		"alchemist_failure_mother_success"
	)
	var chance_shift := 0.0
	if success_mother_stacks > 0:
		chance_shift = 0.10 + 0.025 * float(success_mother_stacks - 1)
	var great_chance: float = clampf(
		float(hero.alchemist_mystery_cauldron_config.get("great_success_chance", 0.20))
		+ chance_shift,
		0.0,
		1.0
	)
	var fail_chance: float = clampf(
		float(hero.alchemist_mystery_cauldron_config.get("failure_chance", 0.20))
		- chance_shift,
		0.0,
		1.0 - great_chance
	)
	var roll: float = randf()

	if roll < great_chance:
		if _get_alchemist_augment_stacks("alchemist_quick_preparation") >= 3:
			hero.alchemist_mystery_cauldron_cooldown = 0.0
		cauldron.call("play_result_sound", "great_success")
		await _execute_alchemist_cauldron_great_success(origin)
		await hero.COMBAT_DELAY.wait(hero,0.50)
	elif roll < great_chance + fail_chance:
		# Failure should feel instantaneous: hide/deactivate the cauldron
		# immediately, but let its child AudioStreamPlayer finish the boom.
		cauldron.call("play_result_sound", "failure")
		cauldron.call("deactivate")
		_execute_alchemist_cauldron_failure(origin)
		return
	else:
		cauldron.call("play_result_sound", "success")
		_execute_alchemist_cauldron_success(origin)
		await hero.COMBAT_DELAY.wait(hero,0.65)

	if is_instance_valid(cauldron):
		cauldron.call("deactivate")


func _execute_alchemist_cauldron_great_success(origin: Vector2) -> void:
	var batch_count: int = maxi(
		int(hero.alchemist_mystery_cauldron_config.get("great_success_batches", 5)),
		1
	)
	var batch_interval: float = maxf(
		float(
			hero.alchemist_mystery_cauldron_config.get(
				"great_success_batch_interval",
				0.32
			)
		),
		0.05
	)
	for batch_index in range(batch_count):
		var vial_min: int = maxi(
			int(
				hero.alchemist_mystery_cauldron_config.get(
					"great_success_vials_min",
					4
				)
			),
			1
		)
		var vial_max: int = maxi(
			int(
				hero.alchemist_mystery_cauldron_config.get(
					"great_success_vials_max",
					5
				)
			),
			vial_min
		)
		var vial_count: int = randi_range(vial_min, vial_max)
		for vial_index in range(vial_count):
			_spawn_alchemist_mystery_vial(origin)
		if batch_index + 1 < batch_count:
			await hero.COMBAT_DELAY.wait(hero,batch_interval)


func _acquire_alchemist_mystery_vial() -> Node2D:
	for vial in hero.alchemist_mystery_vial_pool:
		if (
			is_instance_valid(vial)
			and vial.has_method("is_available")
			and bool(vial.call("is_available"))
		):
			return vial

	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return null
	var vial := hero.ALCHEMIST_VIAL_SCENE.instantiate() as Node2D
	if vial == null:
		return null
	parent.add_child(vial)
	# Great-success vials keep their quieter throw mix for every reuse.
	var mystery_throw_audio := vial.get_node_or_null("ThrowAudio") as AudioStreamPlayer
	if is_instance_valid(mystery_throw_audio):
		mystery_throw_audio.volume_db = -24.0
	vial.connect(
		"landed",
		Callable(hero, "_on_alchemist_mystery_vial_landed")
	)
	hero.alchemist_mystery_vial_pool.append(vial)
	return vial


func _spawn_alchemist_mystery_vial(origin: Vector2) -> void:
	if hero.charm_timer > 0.0:
		return
	var vial := _acquire_alchemist_mystery_vial()
	if vial == null:
		return
	var throw_radius: float = maxf(
		float(
			hero.alchemist_mystery_cauldron_config.get(
				"great_success_throw_radius",
				285.0
			)
		),
		60.0
	)
	var angle: float = randf() * TAU
	var radius: float = sqrt(randf()) * throw_radius
	var landing: Vector2 = origin + Vector2.from_angle(angle) * radius
	var margin: float = 64.0
	landing.x = clampf(landing.x, margin, hero.battlefield_size.x - margin)
	landing.y = clampf(landing.y, margin, hero.battlefield_size.y - margin)
	vial.call(
		"launch",
		origin + Vector2(0.0, -24.0),
		landing,
		0.42,
		105.0,
		null,
		false
	)


func _on_alchemist_mystery_vial_landed(
	landing_position: Vector2,
	_direct_target: Node
) -> void:
	var radius: float = maxf(
		float(
			hero.alchemist_mystery_cauldron_config.get(
				"great_success_hit_radius",
				105.0
			)
		),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(hero.attack_damage)
			* maxf(
				float(
					hero.alchemist_mystery_cauldron_config.get(
						"great_success_damage_ratio",
						0.45
					)
				),
				0.0
			)
		)),
		1
	)
	hero._damage_monsters_in_radius(landing_position, radius, damage)


func _acquire_alchemist_bonus_material() -> Node2D:
	for material in hero.alchemist_bonus_material_pool:
		if is_instance_valid(material) and not bool(material.get("active")):
			return material

	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return null
	var material := hero.ALCHEMY_MATERIAL_SCENE.instantiate() as Node2D
	if material == null:
		return null
	parent.add_child(material)
	if material.has_method("set_temporary_reuse_enabled"):
		material.call("set_temporary_reuse_enabled", true)
	hero.alchemist_bonus_material_pool.append(material)
	return material


func _execute_alchemist_cauldron_success(origin: Vector2) -> void:
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return

	var material_count: int = maxi(
		int(hero.alchemist_mystery_cauldron_config.get("success_material_count", 7)),
		0
	)
	var lifetime: float = maxf(
		float(
			hero.alchemist_mystery_cauldron_config.get(
				"success_drop_duration",
				10.0
			)
		),
		0.1
	)
	for index in range(material_count):
		var material := _acquire_alchemist_bonus_material()
		if material == null:
			continue
		var material_angle: float = (
			TAU * float(index) / float(maxi(material_count, 1))
			+ randf_range(-0.24, 0.24)
		)
		var material_radius: float = randf_range(78.0, 170.0)
		var position: Vector2 = (
			origin
			+ Vector2.from_angle(material_angle) * material_radius
		)
		position.x = clampf(position.x, 64.0, hero.battlefield_size.x - 64.0)
		position.y = clampf(position.y, 64.0, hero.battlefield_size.y - 64.0)
		material.call(
			"activate",
			origin,
			maxf(float(hero.alchemist_config.get("gas_per_material", 20.0)), 0.0),
			lifetime,
			true
		)
		material.call(
			"launch_from_cauldron",
			origin + Vector2(0.0, -18.0),
			position,
			randf_range(0.36, 0.50),
			randf_range(52.0, 78.0)
		)
		if not hero.alchemist_bonus_materials.has(material):
			hero.alchemist_bonus_materials.append(material)

	var heal_count: int = maxi(
		int(
			hero.alchemist_mystery_cauldron_config.get(
				"success_heal_item_count",
				3
			)
		),
		0
	)
	for index in range(heal_count):
		var item := hero.HEAL_ITEM_SCENE.instantiate() as Node2D
		if item == null:
			continue
		parent.add_child(item)
		var heal_angle: float = (
			TAU * float(index) / float(maxi(heal_count, 1))
			+ 0.35
		)
		var heal_position: Vector2 = (
			origin
			+ Vector2.from_angle(heal_angle) * randf_range(105.0, 165.0)
		)
		heal_position.x = clampf(
			heal_position.x,
			64.0,
			hero.battlefield_size.x - 64.0
		)
		heal_position.y = clampf(
			heal_position.y,
			64.0,
			hero.battlefield_size.y - 64.0
		)
		item.global_position = heal_position
		preload("res://src/systems/pickup_placement.gd").ensure_reachable(item)
		if item.has_method("set_temporary_lifetime"):
			item.call("set_temporary_lifetime", lifetime)


func _execute_alchemist_cauldron_failure(origin: Vector2) -> void:
	var fail_fx := hero._spawn_archmage_fx(
		"%s/effect3" % hero.STAGE7_FRAME_DIR,
		"effect",
		8,
		4,
		14.0,
		false,
		origin,
		Vector2(0.52, 0.52)
	)
	if is_instance_valid(fail_fx):
		fail_fx.z_index = 9


func _on_alchemist_mixture_field_tick(origin: Vector2, radius: float) -> void:
	if hero.current_hp <= 0:
		return

	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(
				float(hero.alchemist_mixture_field_config.get("tick_damage_ratio", 0.20)),
				0.0
			)
		))
	)
	var slow_multiplier := clampf(
		float(hero.alchemist_mixture_field_config.get("slow_multiplier", 0.80)),
		0.1,
		1.0
	)
	var slow_until := hero.COMBAT_DELAY.now_msec(hero) + int(round(
		maxf(
			float(hero.alchemist_mixture_field_config.get("slow_refresh_seconds", 0.75)),
			0.05
		) * 1000.0
	))
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		origin,
		radius,
		hero.alchemist_damage_query_candidates
	)

	for node in hero.alchemist_damage_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or origin.distance_squared_to(monster.global_position) > radius_sq:
			continue
		_deal_alchemist_dot_damage(monster, damage)
		# Existing monster movement code reads these shared external-slow meta keys.
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(monster.get_meta("gunner_slow_multiplier", 1.0))
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)
	hero.alchemist_damage_query_candidates.clear()


func _update_alchemist_emergency_escape(delta: float) -> bool:
	if hero.alchemist_emergency_config.is_empty():
		hero.alchemist_emergency_trapped_timer = 0.0
		hero.alchemist_emergency_threats.clear()
		return false
	if hero.alchemist_emergency_cooldown > 0.0 or hero.alchemist_gas > 0.001:
		hero.alchemist_emergency_trapped_timer = 0.0
		hero.alchemist_emergency_threats.clear()
		return false

	var trigger_radius := clampf(
		float(hero.alchemist_emergency_config.get("trigger_radius", 230.0)),
		200.0,
		240.0
	)
	var min_enemies := maxi(
		int(hero.alchemist_emergency_config.get("min_enemy_count", 4)),
		2
	)
	hero._fill_monster_nodes_near(
		hero.global_position,
		trigger_radius,
		hero.alchemist_emergency_query_candidates
	)
	hero.alchemist_emergency_threats.clear()
	var radius_sq := trigger_radius * trigger_radius
	for node in hero.alchemist_emergency_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		if hero.global_position.distance_squared_to(monster.global_position) <= radius_sq:
			hero.alchemist_emergency_threats.append(monster)
	hero.alchemist_emergency_query_candidates.clear()

	if hero.alchemist_emergency_threats.size() < min_enemies:
		hero.alchemist_emergency_trapped_timer = 0.0
		return false

	var blocked_ratio := _update_alchemist_escape_direction(
		hero.alchemist_emergency_threats,
		trigger_radius
	)
	var required_blocked_ratio := clampf(
		float(hero.alchemist_emergency_config.get("blocked_direction_ratio", 0.75)),
		0.50,
		1.0
	)
	if blocked_ratio + 0.001 < required_blocked_ratio:
		hero.alchemist_emergency_trapped_timer = 0.0
		return false

	hero.alchemist_emergency_trapped_timer += delta
	var trapped_duration := clampf(
		float(hero.alchemist_emergency_config.get("trapped_duration", 0.40)),
		0.30,
		0.50
	)
	if hero.alchemist_emergency_trapped_timer < trapped_duration:
		return false

	hero.alchemist_emergency_trapped_timer = 0.0
	_cast_alchemist_emergency_escape(
		hero.alchemist_emergency_threats,
		hero.alchemist_emergency_escape_direction
	)
	hero.alchemist_emergency_threats.clear()
	return true


func _update_alchemist_escape_direction(
	threats: Array[Node2D],
	trigger_radius: float
) -> float:
	const SAMPLE_COUNT := 12
	var best_direction := Vector2.RIGHT
	var best_score := -INF
	var blocked_count := 0
	var block_distance := minf(trigger_radius, 185.0)

	for sample_index in range(SAMPLE_COUNT):
		var direction := Vector2.from_angle(
			TAU * float(sample_index) / float(SAMPLE_COUNT)
		)
		var blocked := false
		var score := 0.0
		for monster in threats:
			if not is_instance_valid(monster):
				continue
			var offset := monster.global_position - hero.global_position
			var distance := maxf(offset.length(), 1.0)
			var toward := direction.dot(offset / distance)
			if distance <= block_distance and toward > 0.45:
				blocked = true
			if toward > 0.0:
				score -= toward * (1.0 - clampf(distance / trigger_radius, 0.0, 1.0))
			else:
				score += (-toward) * 0.18

		var probe := hero.global_position + direction * 150.0
		var margin := 72.0
		if (
			probe.x < margin
			or probe.y < margin
			or probe.x > hero.battlefield_size.x - margin
			or probe.y > hero.battlefield_size.y - margin
		):
			blocked = true
			score -= 2.0

		if blocked:
			blocked_count += 1
		else:
			score += 1.25
		if score > best_score:
			best_score = score
			best_direction = direction

	hero.alchemist_emergency_escape_direction = best_direction
	return float(blocked_count) / float(SAMPLE_COUNT)


func _cast_alchemist_emergency_escape(
	threats: Array[Node2D],
	escape_direction: Vector2
) -> void:
	if hero.silence_timer > 0.0:
		return
	hero.alchemist_emergency_cooldown = maxf(
		_get_alchemist_effective_cooldown(
			hero.alchemist_emergency_config,
			10.0
		),
		0.1
	)
	if escape_direction.length_squared() <= 0.01:
		escape_direction = Vector2.RIGHT
	escape_direction = escape_direction.normalized()

	var effect_radius := maxf(
		float(hero.alchemist_emergency_config.get("effect_radius", 245.0)),
		1.0
	)
	var knockback := maxf(
		float(hero.alchemist_emergency_config.get("knockback_distance", 185.0)),
		0.0
	)
	var damage_ratio := maxf(
		float(hero.alchemist_emergency_config.get("damage_ratio", 0.35)),
		0.0
	)
	var slow_multiplier := clampf(
		float(hero.alchemist_emergency_config.get("slow_multiplier", 0.85)),
		0.1,
		1.0
	)
	var slow_duration := maxf(
		float(hero.alchemist_emergency_config.get("slow_duration", 2.0)),
		0.05
	)
	var effect_radius_sq := effect_radius * effect_radius
	var enemy_damage := maxi(1, int(round(float(hero.attack_damage) * damage_ratio)))
	var slow_until := hero.COMBAT_DELAY.now_msec(hero) + int(round(slow_duration * 1000.0))

	for monster in threats:
		if not is_instance_valid(monster) or monster.is_queued_for_deletion():
			continue
		if hero.global_position.distance_squared_to(monster.global_position) > effect_radius_sq:
			continue
		var radial := hero.global_position.direction_to(monster.global_position)
		if radial.length_squared() <= 0.01:
			radial = -escape_direction
		var lane_dot := radial.dot(escape_direction)
		var push_direction := radial
		if lane_dot > 0.15:
			var side := Vector2(-escape_direction.y, escape_direction.x)
			var side_sign := 1.0 if side.dot(radial) >= 0.0 else -1.0
			push_direction = (
				radial * 0.55
				+ side * side_sign * 0.85
				- escape_direction * 0.30
			).normalized()
		monster.global_position += push_direction * knockback
		hero.LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
		if monster.has_method("take_damage"):
			preload("res://src/systems/monster_hit_context.gd").hit(monster, enemy_damage, "ranged", hero)
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(monster.get_meta("gunner_slow_multiplier", 1.0))
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)

	var fx := hero._spawn_archmage_fx(
		"%s/effect8" % hero.STAGE7_FRAME_DIR,
		"effect",
		1,
		7,
		16.0,
		false,
		hero.global_position,
		Vector2(0.50, 0.50)
	)
	if is_instance_valid(fx):
		fx.z_index = 10

	if is_instance_valid(hero.alchemist_emergency_audio):
		hero.alchemist_emergency_audio.stop()
		hero.alchemist_emergency_audio.play()

	_apply_alchemist_emergency_self_damage()
	_flash_alchemist_emergency_red()


func _apply_alchemist_emergency_self_damage() -> void:
	if hero.current_hp <= 0 or hero.is_dying:
		return
	var self_ratio := clampf(
		float(hero.alchemist_emergency_config.get("self_damage_current_hp_ratio", 0.02)),
		0.0,
		1.0
	)
	var minimum_damage := maxi(
		int(hero.alchemist_emergency_config.get("self_damage_min", 100)),
		1
	)
	var self_damage := maxi(
		minimum_damage,
		int(ceil(float(hero.current_hp) * self_ratio))
	)
	var previous_hp := hero.current_hp
	hero.current_hp = maxi(hero.current_hp - self_damage, 0)
	var applied := previous_hp - hero.current_hp
	if applied > 0:
		hero.DAMAGE_NUMBERS.show(hero, applied)
		hero.health_changed.emit(hero.current_hp, hero.max_hp)
		hero.queue_redraw()
	if hero.current_hp <= 0:
		hero._begin_death_sequence()


func _flash_alchemist_emergency_red() -> void:
	if not is_instance_valid(hero.hero_sprite):
		return
	var tween := hero.create_tween()
	hero.hero_sprite.modulate = Color(1.0, 0.22, 0.22, 1.0)
	tween.tween_property(hero.hero_sprite, "modulate", Color.WHITE, 0.18)


func _get_alchemist_chest_attack_target() -> Node2D:
	if (
		not is_instance_valid(hero.chest_target)
		or hero.chest_target.is_queued_for_deletion()
	):
		return null

	var max_distance := maxf(hero.attack_range, 1.0)
	var chest_distance_sq := hero.global_position.distance_squared_to(hero.chest_target.global_position)
	if chest_distance_sq > max_distance * max_distance:
		return null

	if not is_instance_valid(hero.target) or hero.target.is_queued_for_deletion():
		return hero.chest_target

	var monster_distance_sq := hero.global_position.distance_squared_to(hero.target.global_position)
	return hero.chest_target if chest_distance_sq <= monster_distance_sq else null


func _start_alchemist_basic_attack(direct_chest_target: Node2D = null) -> void:
	var gas_cost := maxf(float(hero.alchemist_config.get("basic_gas_cost", 10.0)), 0.0)
	if not _consume_alchemist_gas(gas_cost):
		return

	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.52
	hero._restart_stage1_animation("attack", 1.0)

	hero.alchemist_throw_positions.clear()
	hero.alchemist_direct_chest_target = (
		direct_chest_target
		if is_instance_valid(direct_chest_target)
		else null
	)
	var throw_radius := maxf(float(hero.alchemist_config.get("basic_throw_radius", 400.0)), 1.0)
	var vial_count := maxi(
		int(hero.alchemist_config.get("basic_vial_count", 3))
		+ _get_alchemist_augment_stacks("alchemist_chemical_support"),
		1
	)
	for index in range(vial_count):
		var landing_position := Vector2.ZERO
		if index == 0 and is_instance_valid(hero.alchemist_direct_chest_target):
			landing_position = hero.alchemist_direct_chest_target.global_position
		else:
			var angle := randf() * TAU
			var radius := sqrt(randf()) * throw_radius
			landing_position = hero.global_position + Vector2.from_angle(angle) * radius
			var margin := 64.0
			landing_position.x = clampf(landing_position.x, margin, hero.battlefield_size.x - margin)
			landing_position.y = clampf(landing_position.y, margin, hero.battlefield_size.y - margin)
		hero.alchemist_throw_positions.append(landing_position)

	if is_instance_valid(hero.alchemist_direct_chest_target):
		hero._face_attack_direction(
			hero.alchemist_direct_chest_target.global_position.x - hero.global_position.x
		)
	hero.alchemist_throw_index = 0
	hero.alchemist_throw_timer = 0.0


func _update_alchemist_throw_sequence(delta: float) -> void:
	if hero.alchemist_throw_index >= hero.alchemist_throw_positions.size():
		return
	hero.alchemist_throw_timer = maxf(hero.alchemist_throw_timer - delta, 0.0)
	if hero.alchemist_throw_timer > 0.0:
		return

	var landing_position: Vector2 = hero.alchemist_throw_positions[hero.alchemist_throw_index]
	var direct_target: Node2D = null
	if hero.alchemist_throw_index == 0 and is_instance_valid(hero.alchemist_direct_chest_target):
		direct_target = hero.alchemist_direct_chest_target
	if not _launch_alchemist_vial(landing_position, direct_target):
		# Retry on the next physics tick instead of silently losing a Chemical
		# Support bonus vial when every pooled projectile is still in flight.
		hero.alchemist_throw_timer = 0.01
		return
	if hero.alchemist_throw_index == 0:
		hero.alchemist_direct_chest_target = null
	hero.alchemist_throw_index += 1
	hero.alchemist_throw_timer = maxf(
		float(hero.alchemist_config.get("vial_throw_interval", 0.19)),
		0.01
	)


func _launch_alchemist_vial(
	landing_position: Vector2,
	direct_target: Node2D = null
) -> bool:
	for vial in hero.alchemist_vial_pool:
		if not is_instance_valid(vial):
			continue
		if not bool(vial.call("is_available")):
			continue
		vial.set("warning_radius",maxf(float(hero.alchemist_config.get("poison_radius",275.0))*_get_alchemist_compressed_range_multiplier(),1.0))
		vial.call(
			"launch",
			hero.global_position,
			landing_position,
			maxf(float(hero.alchemist_config.get("vial_flight_duration", 0.46)), 0.08),
			maxf(float(hero.alchemist_config.get("vial_arc_height", 120.0)), 0.0),
			direct_target
		)
		return true
	return false


func _on_alchemist_vial_landed(
	landing_position: Vector2,
	direct_target: Node
) -> void:
	if (
		is_instance_valid(direct_target)
		and not direct_target.is_queued_for_deletion()
		and direct_target.is_in_group("treasure_chests")
		and direct_target.has_method("take_damage")
	):
		preload("res://src/systems/monster_hit_context.gd").hit(direct_target, maxi(hero.attack_damage, 1), "ranged", hero)

	var tick_damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(float(hero.alchemist_config.get("poison_tick_damage_ratio", 0.18)), 0.0)
		))
	)
	for poison in hero.alchemist_poison_pool:
		if not is_instance_valid(poison):
			continue
		if not bool(poison.call("is_available")):
			continue
		poison.call(
			"activate",
			landing_position,
			maxf(float(hero.alchemist_config.get("poison_duration", 4.0)), 0.1),
			maxf(
				float(hero.alchemist_config.get("poison_radius", 275.0))
				* _get_alchemist_compressed_range_multiplier(),
				1.0
			),
			maxf(float(hero.alchemist_config.get("poison_tick_interval", 0.27)), 0.03),
			tick_damage,
			_get_alchemist_compressed_range_multiplier()
		)
		return


func _on_alchemist_poison_tick(origin: Vector2, radius: float, damage: int) -> void:
	if hero.current_hp <= 0:
		return
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		origin,
		radius,
		hero.alchemist_damage_query_candidates
	)
	for node in hero.alchemist_damage_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if origin.distance_squared_to(monster.global_position) > radius_sq:
			continue
		_deal_alchemist_dot_damage(monster, damage)
	hero.alchemist_damage_query_candidates.clear()


func _update_alchemist_pose_visual(delta: float) -> void:
	if hero.hero_archetype != "alchemist_chemical" or not hero.hero_sprite.visible or hero.is_dying:
		return
	if hero.hit_pose_timer > 0.0 or hero.attack_pose_timer > 0.0:
		return
	hero._update_facing_from_horizontal(hero.velocity.x, delta)
	var speed := hero.velocity.length()
	if speed > 4.0:
		var movement_ratio := speed / maxf(hero.move_speed, 1.0)
		var locomotion_animation := (
			"move"
			if hero.alchemist_transformed
			else ("run" if hero.alchemist_field_run_active else "move")
		)
		hero._play_stage1_animation(
			locomotion_animation,
			clampf(movement_ratio, 0.80, 1.45)
		)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _apply_alchemist_philosopher_effect_visuals() -> void:
	hero._configure_channel_effect_profile(hero.HERO_PRESENTATION.get_channel_effect_profile(hero.hero_archetype, &"channelled"))


func _append_alchemist_philosopher_hud(skills: Array) -> void:
	if hero.alchemist_philosopher_config.is_empty():
		return
	var required := maxi(
		int(hero.alchemist_philosopher_config.get("required_materials", 20)),
		1
	)
	var gas_cost := maxf(
		float(hero.alchemist_philosopher_config.get("gas_cost", 100.0)),
		0.0
	)
	var skill_id := String(hero.alchemist_philosopher_config.get(
		"id",
		"alchemist_philosopher_stone"
	))
	var unlocked := hero.is_conditional_skill_unlocked(skill_id)
	var ready := (
		unlocked
		and not hero.alchemist_philosopher_unlock_pending
		and hero.alchemist_philosopher_unlock_grace_timer <= 0.0
		and not hero.alchemist_philosopher_used
		and not hero.alchemist_philosopher_channeling
		and not hero.alchemist_transformed
		and hero.alchemist_materials_collected >= required
		and hero.alchemist_gas + 0.001 >= gas_cost
	)
	var status := "해금 조건 대기"
	if hero.alchemist_philosopher_unlock_pending:
		status = "현자의 돌 해금 중"
	elif hero.alchemist_philosopher_channeling:
		status = "채널링 중"
	elif hero.alchemist_transformed:
		status = "사용 완료 · 현자의 돌 활성화"
	elif hero.alchemist_philosopher_used:
		status = "사용 완료"
	elif ready:
		status = "사용 가능"
	elif unlocked:
		status = "사용 준비 중"

	skills.append({
		"id": String(hero.alchemist_philosopher_config.get(
			"id",
			"alchemist_philosopher_stone"
		)),
		"name": String(hero.alchemist_philosopher_config.get(
			"name",
			"현자의 돌"
		)),
		"description": hero._skill_hud_description(hero.alchemist_philosopher_config),
		"resource_text": "화학가스 %.0f · 전투당 1회" % gas_cost,
		"progress_text": "연금술 재료 %d / %d · 현재 가스 %.0f / %.0f" % [
			mini(hero.alchemist_materials_collected, required),
			required,
			hero.alchemist_gas,
			hero.alchemist_gas_max,
		],
		"status_text": status,
		"available": ready,
		"cooldown_total": 0.0,
		"cooldown_remaining": 0.0,
		"icon_path": "res://assets/art/heroes/stage7_alchemist/frames/effect7/cast_04.png",
	})
