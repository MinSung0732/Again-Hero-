extends RefCounted
## Rogue archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _physics_process_rogue(delta: float) -> void:
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
	hero.ultimate_flash_timer = maxf(hero.ultimate_flash_timer - delta, 0.0)
	hero.ultimate_cooldown_timer = maxf(
		hero.ultimate_cooldown_timer - delta,
		0.0
	)
	hero.rogue_slash_cooldown_timer = maxf(
		hero.rogue_slash_cooldown_timer - delta * hero.get_paralysis_attack_multiplier(),
		0.0
	)
	_update_rogue_attack_collision_ignore(delta)

	hero._update_invulnerability(delta)
	_update_rogue_slash(delta)

	var passive_charge := maxf(
		float(hero.ultimate_config.get("charge_per_second", 0.0)),
		0.0
	)
	if passive_charge > 0.0 and not hero.rogue_assassination_active:
		hero._add_ultimate_charge(passive_charge * delta)

	if hero.level_flash_timer > 0.0:
		hero.level_flash_timer = maxf(hero.level_flash_timer - delta, 0.0)
		hero.queue_redraw()

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0
			hero.queue_redraw()

	if hero.rogue_assassination_active:
		_update_rogue_assassination(delta)
		return

	if _rogue_can_start_assassination():
		_start_rogue_assassination()
		return

	if (
		not hero.rogue_slash_active
		and hero.rogue_slash_cooldown_timer <= 0.0
		and _rogue_should_use_slash()
	):
		_start_rogue_slash()

	hero._update_heal_item_goal(delta)
	hero._update_chest_goal(delta)
	hero._update_magnet_item_goal(delta)

	if (
		not is_instance_valid(hero.target)
		or hero.target.is_queued_for_deletion()
		or hero.retarget_timer <= 0.0
	):
		hero.target = hero._find_nearest_monster()
		hero.retarget_timer = 0.10

	if not is_instance_valid(hero.target):
		hero.rogue_combo_index = 0
		hero.rogue_combo_direction = Vector2.RIGHT
		hero._move_without_monsters()
		_update_rogue_pose_visual(delta)
		return

	var distance := hero.global_position.distance_to(hero.target.global_position)
	var speed_scale := 1.0
	if hero.rogue_slash_active:
		speed_scale = clampf(
			float(
				hero.rogue_slash_config.get(
					"move_speed_multiplier",
					0.48
				)
			),
			0.1,
			1.0
		)

	var move_direction := hero._choose_melee_spacing_direction(
		hero.target,
		distance,
		0.88
	)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)
	if move_direction.length_squared() > 0.01:
		hero._execute_ai_movement(
			move_direction
			* hero.move_speed
			* hero._get_effective_move_multiplier()
			* speed_scale
		)
	else:
		hero.velocity = Vector2.ZERO

	if (
		not hero.rogue_slash_active
		and distance <= hero.attack_range
		and hero.attack_timer <= 0.0
	):
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.ROGUE_COMBO, hero.target)

	_update_rogue_pose_visual(delta)


func _rogue_compare_registration_order(a: Node, b: Node) -> bool:
	return int(a.get_meta("query_registration_order", a.get_instance_id())) < int(b.get_meta("query_registration_order", b.get_instance_id()))


func _rogue_combo_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var target_direction := hero.global_position.direction_to(
		current_target.global_position
	)
	if target_direction.length_squared() <= 0.0:
		target_direction = (
			Vector2.LEFT
			if hero.hero_sprite.flip_h
			else Vector2.RIGHT
		)

	if hero.rogue_combo_index == 0:
		hero.rogue_combo_direction = target_direction.normalized()
	elif hero.rogue_combo_direction.length_squared() <= 0.0:
		hero.rogue_combo_direction = target_direction.normalized()

	var direction := hero.rogue_combo_direction.normalized()
	hero._face_attack_direction(direction.x)

	var lunge_distance := maxf(
		float(hero.rogue_combo_config.get("lunge_distance", 85.0)),
		0.0
	)
	var target_distance := hero.global_position.distance_to(
		current_target.global_position
	)
	var lunge_stop_distance := maxf(
		float(hero.rogue_combo_config.get("lunge_stop_distance", 26.0)),
		0.0
	)
	lunge_distance = minf(
		lunge_distance,
		maxf(target_distance - lunge_stop_distance, 0.0)
	)
	var lunge_start := hero.global_position
	# Player movement stays on the pad; only the AI rogue lunges on attack.
	if not hero.player_controlled:
		hero.global_position += direction * lunge_distance
		hero._clamp_to_battlefield()
	var lunge_end := hero.global_position

	_start_rogue_attack_collision_ignore(
		maxf(
			float(
				hero.rogue_combo_config.get(
					"collision_ignore_duration",
					0.28
				)
			),
			0.0
		)
	)

	var damage_multipliers = hero.rogue_combo_config.get(
		"damage_multipliers",
		[0.75, 0.85, 1.10]
	)
	var damage_ratio := 1.0
	if (
		typeof(damage_multipliers) == TYPE_ARRAY
		and not damage_multipliers.is_empty()
	):
		var damage_index := mini(
			hero.rogue_combo_index,
			damage_multipliers.size() - 1
		)
		damage_ratio = float(damage_multipliers[damage_index])

	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* damage_ratio
			* hero.rogue_combo_damage_multiplier
		))
	)

	var aoe_radii = hero.rogue_combo_config.get(
		"aoe_radii",
		[95.0, 110.0, 130.0]
	)
	var aoe_offsets = hero.rogue_combo_config.get(
		"aoe_forward_offsets",
		[48.0, 54.0, 62.0]
	)
	var aoe_radius := 95.0
	var aoe_offset := 48.0
	if typeof(aoe_radii) == TYPE_ARRAY and not aoe_radii.is_empty():
		var radius_index := mini(
			hero.rogue_combo_index,
			aoe_radii.size() - 1
		)
		aoe_radius = float(aoe_radii[radius_index])
	if typeof(aoe_offsets) == TYPE_ARRAY and not aoe_offsets.is_empty():
		var offset_index := mini(
			hero.rogue_combo_index,
			aoe_offsets.size() - 1
		)
		aoe_offset = float(aoe_offsets[offset_index])

	var corridor_end := lunge_end + direction * aoe_offset
	if hero.player_controlled and hero.player_weapons != null:
		hero.player_weapons._effect(lunge_start,corridor_end,aoe_radius,"capsule",Color("bc9eee"))
	var corridor_vector := corridor_end - lunge_start
	var corridor_length_squared := corridor_vector.length_squared()
	var main_id := current_target.get_instance_id()
	var knockback_distance := float(
		hero.rogue_combo_config.get(
			"knockback_distance",
			30.0
		)
	)
	var secondary_lifesteal := clampf(
		float(
			hero.rogue_combo_config.get(
				"secondary_lifesteal_efficiency",
				0.50
			)
		),
		0.0,
		1.0
	)

	var corridor_bounds := Rect2(lunge_start, Vector2.ZERO).expand(corridor_end).grow(aoe_radius)
	var battle := hero.get_parent()
	if is_instance_valid(battle) and battle.has_method("fill_local_monsters_in_rect"):
		battle.call("fill_local_monsters_in_rect", corridor_bounds, hero.rogue_combo_candidates)
		hero.HERO_TARGET_POLICY.filter_detectable(hero.rogue_combo_candidates)
	else:
		hero._fill_monster_nodes_in_rect(corridor_bounds, hero.rogue_combo_candidates)
	hero.rogue_combo_candidates.sort_custom(_rogue_compare_registration_order)
	for node in hero.rogue_combo_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var nearest_point := lunge_start
		if corridor_length_squared > 0.001:
			var projection := clampf(
				(
					(monster.global_position - lunge_start)
					.dot(corridor_vector)
					/ corridor_length_squared
				),
				0.0,
				1.0
			)
			nearest_point = (
				lunge_start
				+ corridor_vector * projection
			)
		if (
			nearest_point.distance_squared_to(monster.global_position)
			> aoe_radius * aoe_radius
		):
			continue

		var is_main_target := monster.get_instance_id() == main_id
		var actual_damage := _rogue_damage_target(
			monster,
			damage,
			1.0 if is_main_target else secondary_lifesteal
		)
		if actual_damage <= 0 or not is_instance_valid(monster):
			continue

		_rogue_apply_knockback(
			monster,
			direction,
			knockback_distance
		)

	hero.rogue_combo_candidates.clear()
	# Stage 2 rogue deals +200% bonus damage to treasure chests
	# (300% total) so the fast combo can realistically break them.
	hero._damage_treasure_chests(
		corridor_end,
		aoe_radius,
		maxi(1, damage * 3)
	)
	hero.attack_pose_timer = 0.26
	hero._restart_stage1_animation("attack", 1.0)
	_play_rogue_effect(
		hero.rogue_attack_effect,
		"stab",
		direction
	)
	_play_rogue_combo_audio(hero.rogue_combo_index)

	hero._add_ultimate_charge(
		float(hero.ultimate_config.get("charge_on_attack", 0.0))
	)

	var combo_length := 3 + maxi(hero.rogue_bonus_combo_hits, 0)
	var hit_intervals = hero.rogue_combo_config.get(
		"hit_intervals",
		[0.24, 0.26, 0.28, 0.30]
	)
	var interval := hero.attack_cooldown
	if typeof(hit_intervals) == TYPE_ARRAY and not hit_intervals.is_empty():
		var interval_index := mini(
			hero.rogue_combo_index,
			hit_intervals.size() - 1
		)
		interval = float(hit_intervals[interval_index])

	var is_finisher := hero.rogue_combo_index >= combo_length - 1
	if is_finisher:
		interval = maxf(
			float(
				hero.rogue_combo_config.get(
					"finisher_recovery",
					1.05
				)
			),
			0.08
		)
		interval *= hero.rogue_combo_recovery_multiplier

	interval = hero._get_common_attack_interval(interval)
	hero.attack_timer = maxf(interval, 0.08)
	hero.rogue_combo_index = (hero.rogue_combo_index + 1) % combo_length
	if hero.rogue_combo_index == 0:
		hero.rogue_combo_direction = Vector2.ZERO


func _start_rogue_attack_collision_ignore(duration: float) -> void:
	if duration <= 0.0 or hero.is_dying:
		return

	if hero.rogue_saved_collision_mask < 0:
		hero.rogue_saved_collision_mask = hero.collision_mask
	hero.collision_mask = 0
	hero.rogue_attack_collision_ignore_timer = maxf(
		hero.rogue_attack_collision_ignore_timer,
		duration
	)


func _update_rogue_attack_collision_ignore(delta: float) -> void:
	if hero.rogue_attack_collision_ignore_timer <= 0.0:
		if hero.rogue_saved_collision_mask >= 0 and not hero.is_dying:
			hero.collision_mask = hero.rogue_saved_collision_mask
			hero.rogue_saved_collision_mask = -1
		return

	hero.rogue_attack_collision_ignore_timer = maxf(
		hero.rogue_attack_collision_ignore_timer - delta,
		0.0
	)
	if (
		hero.rogue_attack_collision_ignore_timer <= 0.0
		and hero.rogue_saved_collision_mask >= 0
		and not hero.is_dying
	):
		hero.collision_mask = hero.rogue_saved_collision_mask
		hero.rogue_saved_collision_mask = -1


func _rogue_damage_target(
	current_target: Node2D,
	damage: int,
	lifesteal_efficiency: float = 1.0
) -> int:
	if (
		not is_instance_valid(current_target)
		or damage <= 0
		or not current_target.has_method("take_damage")
	):
		return 0

	var hp_before_value = current_target.get("current_hp")
	var hp_before := 0
	var can_measure := hp_before_value != null
	if can_measure:
		hp_before = maxi(int(hp_before_value), 0)

	preload("res://src/systems/monster_hit_context.gd").hit(current_target, damage, "melee", hero)

	if not can_measure:
		return 0

	var hp_after := 0
	if is_instance_valid(current_target):
		var hp_after_value = current_target.get("current_hp")
		if hp_after_value != null:
			hp_after = maxi(int(hp_after_value), 0)

	var actual_damage := maxi(hp_before - hp_after, 0)
	_apply_rogue_lifesteal(
		actual_damage,
		lifesteal_efficiency
	)
	return actual_damage


func _apply_rogue_lifesteal(
	actual_damage: int,
	efficiency: float
) -> void:
	if (
		actual_damage <= 0
		or hero.rogue_lifesteal_ratio <= 0.0
		or hero.current_hp <= 0
		or hero.current_hp >= hero.max_hp
	):
		return

	hero.rogue_lifesteal_buffer += (
		float(actual_damage)
		* hero.rogue_lifesteal_ratio
		* clampf(efficiency, 0.0, 1.0)
	)
	var heal_amount := int(floor(hero.rogue_lifesteal_buffer))
	if heal_amount <= 0:
		return

	hero.rogue_lifesteal_buffer -= float(heal_amount)
	hero.heal_direct(heal_amount)


func _rogue_apply_knockback(
	current_target: Node2D,
	direction: Vector2,
	distance: float
) -> void:
	if not is_instance_valid(current_target) or distance <= 0.0:
		return
	var hp_value = current_target.get("current_hp")
	if hp_value != null and int(hp_value) <= 0:
		return

	current_target.global_position += direction.normalized() * distance
	hero.LOCAL_GRID_MOVEMENT.notify_forced_position_change(current_target)


func _rogue_should_use_slash() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.rogue_slash_config.is_empty():
		return false

	var radius := maxf(
		float(hero.rogue_slash_config.get("radius", 205.0)),
		0.0
	)
	var required := maxi(
		int(
			hero.rogue_slash_config.get(
				"enemy_count_trigger",
				3
			)
		),
		1
	)
	if radius <= 0.0:
		return false
	return hero._count_monsters_near(
		hero.global_position,
		radius,
		required
	) >= required


func _start_rogue_slash() -> void:
	if hero.silence_timer > 0.0:
		return
	hero.rogue_combo_index = 0
	hero.rogue_slash_active = true
	hero.rogue_slash_duration_timer = maxf(
		float(hero.rogue_slash_config.get("duration", 1.20)),
		0.1
	)
	hero.rogue_slash_tick_timer = 0.0
	hero.rogue_slash_cooldown_timer = maxf(
		float(hero.rogue_slash_config.get("cooldown", 14.0)),
		0.0
	)

	var shield_ratio := maxf(
		float(
			hero.rogue_slash_config.get(
				"shield_hp_ratio",
				0.18
			)
		)
		+ hero.rogue_slash_shield_ratio_bonus,
		0.0
	)
	hero.shield_max_hp = hero._player_shield_amount(float(hero.max_hp) * shield_ratio)
	hero.shield_hp = hero.shield_max_hp

	_play_rogue_blade_storm_audio()
	_apply_rogue_slash_tick()
	hero.queue_redraw()


func _update_rogue_slash(delta: float) -> void:
	if not hero.rogue_slash_active:
		return

	hero.rogue_slash_duration_timer = maxf(
		hero.rogue_slash_duration_timer - delta,
		0.0
	)
	hero.rogue_slash_tick_timer = maxf(
		hero.rogue_slash_tick_timer - delta,
		0.0
	)

	if hero.rogue_slash_tick_timer <= 0.0:
		_apply_rogue_slash_tick()
		hero.rogue_slash_tick_timer = maxf(
			float(
				hero.rogue_slash_config.get(
					"tick_interval",
					0.24
				)
			),
			0.08
		)

	if hero.rogue_slash_duration_timer <= 0.0:
		hero.rogue_slash_active = false
		hero.shield_effect.visible = false


func _apply_rogue_slash_tick() -> void:
	var radius := maxf(
		float(hero.rogue_slash_config.get("radius", 205.0)),
		0.0
	)
	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(
				float(
					hero.rogue_slash_config.get(
						"damage_ratio",
						0.50
					)
				),
				0.0
			)
		))
	)
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.rogue_query_candidates
	)

	for node in hero.rogue_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			hero.global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		if monster.has_method("take_damage"):
			_rogue_damage_target(
				monster,
				damage,
				0.50
			)
	hero.rogue_query_candidates.clear()

	if hero.shield_effect.sprite_frames != null:
		hero.shield_effect.visible = true
		hero.shield_effect.stop()
		hero.shield_effect.animation = &"slash"
		hero.shield_effect.frame = 0
		hero.shield_effect.play(&"slash")


func _rogue_can_start_assassination() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.ultimate_config.is_empty():
		return false
	if hero.ultimate_cooldown_timer > 0.0:
		return false

	var charge_max := maxf(
		float(hero.ultimate_config.get("charge_max", 100.0)),
		1.0
	)
	if hero.ultimate_charge + 0.001 < charge_max:
		return false

	return _find_rogue_assassination_target() != null


func _start_rogue_assassination() -> void:
	if hero.silence_timer > 0.0:
		return
	hero.rogue_combo_index = 0
	hero.rogue_assassination_active = true
	hero.rogue_assassination_hits_left = maxi(
		int(hero.ultimate_config.get("hit_count", 5))
		+ hero.rogue_assassination_hit_bonus,
		1
	)
	hero.rogue_assassination_cast_timer = maxf(
		float(hero.ultimate_config.get("cast_time", 0.35)),
		0.0
	)
	hero.rogue_assassination_timer = 0.0
	hero.ultimate_charge = 0.0
	hero.ultimate_cooldown_timer = maxf(
		float(hero.ultimate_config.get("cooldown", 8.0)),
		0.0
	)
	hero.velocity = Vector2.ZERO
	hero.modulate.a = 0.18
	_play_rogue_assassination_start_audio()
	hero.ultimate_used.emit(
		String(hero.ultimate_config.get("id", "shadow_assassination")),
		String(hero.ultimate_config.get("name", "급습-암살"))
	)
	hero.queue_redraw()


func _update_rogue_assassination(delta: float) -> void:
	hero.velocity = Vector2.ZERO

	if hero.rogue_assassination_cast_timer > 0.0:
		hero.rogue_assassination_cast_timer = maxf(
			hero.rogue_assassination_cast_timer - delta,
			0.0
		)
		return

	hero.rogue_assassination_timer = maxf(
		hero.rogue_assassination_timer - delta,
		0.0
	)
	if hero.rogue_assassination_timer > 0.0:
		return

	var current_target := _find_rogue_assassination_target()
	if current_target == null:
		_end_rogue_assassination()
		return

	var approach_direction := hero.global_position.direction_to(
		current_target.global_position
	)
	if approach_direction.length_squared() <= 0.0:
		approach_direction = Vector2.RIGHT

	var behind_offset := maxf(
		float(hero.ultimate_config.get("behind_offset", 54.0)),
		0.0
	)
	hero.global_position = (
		current_target.global_position
		+ approach_direction * behind_offset
	)
	hero._clamp_to_battlefield()
	hero._face_attack_direction(-approach_direction.x)

	var base_damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(
				float(
					hero.ultimate_config.get(
						"damage_ratio",
						0.85
					)
				),
				0.0
			)
		))
	)
	var damage := base_damage
	var stage_event_type := String(
		current_target.get_meta(
			"stage_event_type",
			""
		)
	)
	var current_target_hp = current_target.get("current_hp")
	var max_target_hp = current_target.get("max_hp")
	var is_special_target := not stage_event_type.is_empty()

	if (
		not is_special_target
		and current_target_hp != null
		and max_target_hp != null
	):
		var execute_ratio := clampf(
			float(
				hero.ultimate_config.get(
					"execute_hp_ratio",
					0.30
				)
			)
			+ hero.rogue_execute_threshold_bonus,
			0.0,
			0.20
		)
		var hp_ratio := (
			float(current_target_hp)
			/ float(maxi(int(max_target_hp), 1))
		)
		if hp_ratio <= execute_ratio:
			damage = maxi(int(current_target_hp), damage)
	elif is_special_target:
		damage = maxi(
			1,
			int(round(
				float(damage)
				* maxf(
					float(
						hero.ultimate_config.get(
							"elite_damage_multiplier",
							1.75
						)
					),
					1.0
				)
			))
		)

	var main_target_id := current_target.get_instance_id()
	_rogue_damage_target(
		current_target,
		damage,
		1.0
	)

	var assassination_aoe_radius := maxf(
		float(hero.ultimate_config.get("aoe_radius", 120.0)),
		0.0
	)
	var secondary_damage := maxi(
		1,
		int(round(
			float(base_damage)
			* clampf(
				float(
					hero.ultimate_config.get(
						"secondary_damage_ratio",
						0.78
					)
				),
				0.0,
				2.0
			)
		))
	)
	var secondary_lifesteal := clampf(
		float(
			hero.ultimate_config.get(
				"secondary_lifesteal_efficiency",
				0.50
			)
		),
		0.0,
		1.0
	)
	var assassination_aoe_radius_sq := (
		assassination_aoe_radius * assassination_aoe_radius
	)
	hero._fill_monster_nodes_near(
		current_target.global_position,
		assassination_aoe_radius,
		hero.rogue_query_candidates
	)

	for node in hero.rogue_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if monster.get_instance_id() == main_target_id:
			continue
		if (
			current_target.global_position.distance_squared_to(
				monster.global_position
			)
			> assassination_aoe_radius_sq
		):
			continue

		_rogue_damage_target(
			monster,
			secondary_damage,
			secondary_lifesteal
		)
	hero.rogue_query_candidates.clear()

	hero.attack_pose_timer = 0.20
	hero._restart_stage1_animation("attack", 1.35)
	_play_rogue_effect(
		hero.channel_effect,
		"assassinate",
		-approach_direction
	)
	_play_rogue_assassination_hit_audio()

	hero.rogue_assassination_hits_left -= 1
	if hero.rogue_assassination_hits_left <= 0:
		_end_rogue_assassination()
		return

	hero.rogue_assassination_timer = maxf(
		float(hero.ultimate_config.get("hit_interval", 0.18)),
		0.08
	)


func _find_rogue_assassination_target() -> Node2D:
	var radius := maxf(
		float(hero.ultimate_config.get("target_radius", 520.0)),
		1.0
	)
	var best: Node2D = null
	var best_score := INF
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.rogue_query_candidates
	)

	for node in hero.rogue_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var distance_sq := hero.global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > radius_sq:
			continue
		var distance := sqrt(distance_sq)

		var hp_ratio := 1.0
		var max_hp_value = monster.get("max_hp")
		if hp_value != null and max_hp_value != null:
			hp_ratio = (
				float(hp_value)
				/ float(maxi(int(max_hp_value), 1))
			)

		var score := distance + hp_ratio * 120.0
		if score < best_score:
			best_score = score
			best = monster

	hero.rogue_query_candidates.clear()
	return best


func _end_rogue_assassination() -> void:
	hero.rogue_assassination_active = false
	hero.rogue_assassination_hits_left = 0
	hero.rogue_assassination_timer = 0.0
	hero.rogue_assassination_cast_timer = 0.0
	hero.modulate.a = 1.0
	hero.channel_effect.visible = false
	hero.queue_redraw()


func _play_rogue_effect(
	effect_sprite: AnimatedSprite2D,
	animation_name: String,
	direction: Vector2
) -> void:
	if effect_sprite.sprite_frames == null:
		return
	if not effect_sprite.sprite_frames.has_animation(animation_name):
		return

	effect_sprite.visible = true
	effect_sprite.position = direction.normalized() * 28.0
	effect_sprite.rotation = direction.angle()
	effect_sprite.stop()
	effect_sprite.animation = animation_name
	effect_sprite.frame = 0
	effect_sprite.play(animation_name)


func _on_rogue_attack_effect_finished() -> void:
	hero.rogue_attack_effect.visible = false


func _update_rogue_pose_visual(delta: float) -> void:
	if not hero.hero_sprite.visible or hero.is_dying:
		return
	if hero.hit_pose_timer > 0.0 or hero.attack_pose_timer > 0.0:
		return

	hero._update_facing_from_horizontal(hero.velocity.x, delta)

	if hero.velocity.length() > 4.0:
		hero._play_stage1_animation("move", 1.0)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _apply_stage2_rogue_effect_visuals() -> void:
	# This reset is unconditional, including calls for another archetype.
	hero.rogue_attack_effect.visible = false
	hero.rogue_attack_effect.sprite_frames = null
	hero._configure_combat_effect_profile(hero.HERO_PRESENTATION.get_combat_effect_profile(hero.hero_archetype, &"rogue"))


func _ensure_rogue_audio_runtime() -> void:
	if hero.hero_archetype != "rogue_combo":
		return

	if hero.rogue_combo_audio_pool.is_empty():
		for index in range(3):
			hero.rogue_combo_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE2_COMBO_SLASH_AUDIO_PATH,
					hero.HERO_SFX_DB_PRIMARY_ATTACK - 10.0,
					1.0
				)
			)

	if not is_instance_valid(hero.rogue_blade_storm_audio):
		hero.rogue_blade_storm_audio = hero._create_hero_sfx_player(
			hero.STAGE2_BLADE_STORM_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL,
			1.0
		)

	if not is_instance_valid(hero.rogue_assassination_start_audio):
		hero.rogue_assassination_start_audio = hero._create_hero_sfx_player(
			hero.STAGE2_ASSASSINATION_START_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL,
			1.0
		)

	if hero.rogue_assassination_hit_audio_pool.is_empty():
		for index in range(3):
			hero.rogue_assassination_hit_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE2_ASSASSINATION_HIT_AUDIO_PATH,
					hero.HERO_SFX_DB_HIT - 3.0,
					1.0
				)
			)

	if not is_instance_valid(hero.rogue_hit_audio):
		hero.rogue_hit_audio = hero._create_hero_sfx_player(
			hero.STAGE2_HIT_AUDIO_PATH, hero.CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(hero.rogue_death_audio):
		hero.rogue_death_audio = hero._create_hero_sfx_player(
			hero.STAGE2_DEATH_AUDIO_PATH,
			hero.HERO_SFX_DB_DEATH,
			0.96
		)


func _play_rogue_combo_audio(_combo_index: int) -> void:
	if hero.COMBAT_DELAY.now_msec(hero) < hero.rogue_combo_audio_next_ms:
		return
	_ensure_rogue_audio_runtime()
	if hero.rogue_combo_audio_pool.is_empty():
		return
	var player := hero.rogue_combo_audio_pool[
		hero.rogue_combo_audio_cursor % hero.rogue_combo_audio_pool.size()
	]
	hero.rogue_combo_audio_cursor = (
		hero.rogue_combo_audio_cursor + 1
	) % hero.rogue_combo_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	hero.rogue_combo_audio_next_ms = hero.COMBAT_DELAY.now_msec(hero)+hero.CONTEXT_AUDIO.ROGUE_ATTACK_INTERVAL_MS
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_rogue_blade_storm_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(hero.rogue_blade_storm_audio) and hero.rogue_blade_storm_audio.stream != null:
		hero.rogue_blade_storm_audio.stop()
		hero.rogue_blade_storm_audio.play()


func _play_rogue_assassination_start_audio() -> void:
	_ensure_rogue_audio_runtime()
	if (
		is_instance_valid(hero.rogue_assassination_start_audio)
		and hero.rogue_assassination_start_audio.stream != null
	):
		hero.rogue_assassination_start_audio.stop()
		hero.rogue_assassination_start_audio.play()


func _play_rogue_assassination_hit_audio() -> void:
	if hero.COMBAT_DELAY.now_msec(hero) < hero.rogue_assassination_audio_next_ms:
		return
	_ensure_rogue_audio_runtime()
	if hero.rogue_assassination_hit_audio_pool.is_empty():
		return
	var player := hero.rogue_assassination_hit_audio_pool[
		hero.rogue_assassination_hit_audio_cursor
		% hero.rogue_assassination_hit_audio_pool.size()
	]
	hero.rogue_assassination_hit_audio_cursor = (
		hero.rogue_assassination_hit_audio_cursor + 1
	) % hero.rogue_assassination_hit_audio_pool.size()
	hero.rogue_assassination_audio_next_ms = hero.COMBAT_DELAY.now_msec(hero)+hero.CONTEXT_AUDIO.ROGUE_ASSASSINATION_INTERVAL_MS
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_rogue_hit_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(hero.rogue_hit_audio) and hero.rogue_hit_audio.stream != null:
		hero.rogue_hit_audio.stop()
		hero.rogue_hit_audio.play()


func _play_rogue_death_audio() -> void:
	_ensure_rogue_audio_runtime()
	if is_instance_valid(hero.rogue_death_audio) and hero.rogue_death_audio.stream != null:
		hero.rogue_death_audio.stop()
		hero.rogue_death_audio.play()
