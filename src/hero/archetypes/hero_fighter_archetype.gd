extends RefCounted
## Fighter archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _on_fighter_guard_release_effect_finished() -> void:
	var rule := hero.HERO_PRESENTATION.get_release_effect_completion(hero.hero_archetype)
	if rule.is_empty():
		return
	if rule.has("animation") and hero.channel_effect.animation != rule["animation"]:
		return
	var properties: Dictionary = rule["properties"]
	for property in properties:
		hero.channel_effect.set(property, properties[property])


func _ensure_fighter_audio_runtime() -> void:
	if hero.hero_archetype != "sword_shield":
		return

	if hero.fighter_slash_audio_pool.is_empty():
		for index in range(3):
			hero.fighter_slash_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE3_SLASH_AUDIO_PATH,
					hero.HERO_SFX_DB_PRIMARY_ATTACK - 3.0,
					0.96
				)
			)

	if hero.fighter_thrust_audio_pool.is_empty():
		for index in range(3):
			hero.fighter_thrust_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE3_THRUST_AUDIO_PATH,
					hero.HERO_SFX_DB_PRIMARY_ATTACK - 2.0,
					1.08
				)
			)

	if not is_instance_valid(hero.fighter_guard_start_audio):
		hero.fighter_guard_start_audio = hero._create_hero_sfx_player(
			hero.STAGE3_GUARD_START_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.72
		)

	if not is_instance_valid(hero.fighter_guard_release_audio):
		hero.fighter_guard_release_audio = hero._create_hero_sfx_player(
			hero.STAGE3_GUARD_RELEASE_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.76
		)

	if hero.fighter_charge_impact_audio_pool.is_empty():
		for index in range(3):
			hero.fighter_charge_impact_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE3_CHARGE_IMPACT_AUDIO_PATH,
					hero.HERO_SFX_DB_HEAVY_SKILL - 7.0,
					0.86
				)
			)

	if not is_instance_valid(hero.fighter_hit_audio):
		hero.fighter_hit_audio = hero._create_hero_sfx_player(
			hero.STAGE3_HIT_AUDIO_PATH, hero.CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(hero.fighter_death_audio):
		hero.fighter_death_audio = hero._create_hero_sfx_player(
			hero.STAGE3_DEATH_AUDIO_PATH,
			hero.HERO_SFX_DB_DEATH,
			0.82
		)


func _play_fighter_slash_audio() -> void:
	_ensure_fighter_audio_runtime()
	if hero.fighter_slash_audio_pool.is_empty():
		return
	var player := hero.fighter_slash_audio_pool[
		hero.fighter_slash_audio_cursor % hero.fighter_slash_audio_pool.size()
	]
	hero.fighter_slash_audio_cursor = (
		hero.fighter_slash_audio_cursor + 1
	) % hero.fighter_slash_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	var pitch_steps: Array[float] = [0.94, 1.00, 0.90]
	player.pitch_scale = pitch_steps[
		hero.fighter_slash_audio_cursor % pitch_steps.size()
	]
	player.stop()
	player.play()


func _play_fighter_thrust_audio(is_charge: bool = false) -> void:
	_ensure_fighter_audio_runtime()
	if hero.fighter_thrust_audio_pool.is_empty():
		return
	var player := hero.fighter_thrust_audio_pool[
		hero.fighter_thrust_audio_cursor % hero.fighter_thrust_audio_pool.size()
	]
	hero.fighter_thrust_audio_cursor = (
		hero.fighter_thrust_audio_cursor + 1
	) % hero.fighter_thrust_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 0.90 if is_charge else 1.12
	player.stop()
	player.play()


func _play_fighter_guard_start_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(hero.fighter_guard_start_audio)
		and hero.fighter_guard_start_audio.stream != null
	):
		hero.fighter_guard_start_audio.stop()
		hero.fighter_guard_start_audio.play()


func _play_fighter_guard_release_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(hero.fighter_guard_release_audio)
		and hero.fighter_guard_release_audio.stream != null
	):
		hero.fighter_guard_release_audio.stop()
		hero.fighter_guard_release_audio.play()


func _play_fighter_charge_impact_audio() -> void:
	_ensure_fighter_audio_runtime()
	if hero.fighter_charge_impact_audio_pool.is_empty():
		return
	var player := hero.fighter_charge_impact_audio_pool[
		hero.fighter_charge_impact_audio_cursor
		% hero.fighter_charge_impact_audio_pool.size()
	]
	hero.fighter_charge_impact_audio_cursor = (
		hero.fighter_charge_impact_audio_cursor + 1
	) % hero.fighter_charge_impact_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_fighter_hit_audio() -> void:
	_ensure_fighter_audio_runtime()
	if is_instance_valid(hero.fighter_hit_audio) and hero.fighter_hit_audio.stream != null:
		hero.fighter_hit_audio.stop()
		hero.fighter_hit_audio.play()


func _play_fighter_death_audio() -> void:
	_ensure_fighter_audio_runtime()
	if (
		is_instance_valid(hero.fighter_death_audio)
		and hero.fighter_death_audio.stream != null
	):
		hero.fighter_death_audio.stop()
		hero.fighter_death_audio.play()


func _physics_process_fighter(delta: float) -> void:
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
	hero._update_invulnerability(delta)
	_update_fighter_guard(delta)
	hero.fighter_charge_cooldown_timer = maxf(hero.fighter_charge_cooldown_timer - delta, 0.0)
	if hero.fighter_charge_active:
		_update_fighter_charge(delta)
		return

	if _update_fighter_slash_combo(delta):
		hero.velocity = Vector2.ZERO
		_update_fighter_pose_visual(delta)
		return

	if hero.level_flash_timer > 0.0:
		hero.level_flash_timer = maxf(hero.level_flash_timer - delta, 0.0)
		hero.queue_redraw()

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0
			hero.queue_redraw()

	hero._update_heal_item_goal(delta)
	hero._update_chest_goal(delta)
	hero._update_magnet_item_goal(delta)

	if (
		not is_instance_valid(hero.target)
		or hero.target.is_queued_for_deletion()
		or hero.retarget_timer <= 0.0
	):
		hero.target = hero._find_nearest_monster()
		hero.retarget_timer = 0.12

	var guard_move_scale := 1.0
	if hero.fighter_guard_active:
		guard_move_scale = clampf(
			float(hero.ultimate_config.get("move_speed_multiplier", 0.62))
			+ hero.fighter_guard_move_multiplier_bonus,
			0.25,
			1.0
		)

	if not is_instance_valid(hero.target):
		_fighter_move_without_monsters(guard_move_scale)
		_update_fighter_pose_visual(delta)
		return

	var distance := hero.global_position.distance_to(hero.target.global_position)
	var move_direction := hero._choose_melee_spacing_direction(
		hero.target,
		distance,
		0.90
	)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)
	if move_direction.length_squared() > 0.01:
		hero._execute_ai_movement(
			move_direction
			* hero.move_speed
			* hero._get_effective_move_multiplier()
			* guard_move_scale
		)
	else:
		hero.velocity = Vector2.ZERO

	if (
		hero.fighter_charge_cooldown_timer <= 0.0
		and _fighter_should_start_charge()
	):
		_start_fighter_charge()
		return

	if distance <= hero.attack_range and hero.attack_timer <= 0.0:
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.FIGHTER, hero.target)

	_update_fighter_pose_visual(delta)


func _fighter_should_start_charge() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.fighter_charge_config.is_empty() or hero.fighter_guard_active:
		return false
	var trigger := hero.HERO_FIGHTER_RUNTIME.get_charge_trigger(
		hero.fighter_charge_config
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return hero._count_monsters_near(
		hero.global_position,
		radius,
		required
	) >= required


func _start_fighter_charge() -> void:
	if hero.silence_timer > 0.0:
		return
	var charge_target := _find_fighter_charge_target()
	if not is_instance_valid(charge_target):
		return
	hero.fighter_charge_chain_count = 0
	_begin_fighter_charge_dash(charge_target)


func _find_fighter_charge_target(exclude: Node = null) -> Node2D:
	var max_distance := hero.HERO_FIGHTER_RUNTIME.get_charge_max_target_distance(
		hero.fighter_charge_config
	)
	hero._fill_monster_nodes_near(
		hero.global_position,
		max_distance,
		hero.fighter_charge_target_candidates
	)
	var charge_target := hero.HERO_FIGHTER_RUNTIME.find_farthest_charge_target(
		hero.fighter_charge_target_candidates,
		hero.global_position,
		max_distance,
		exclude
	)
	hero.fighter_charge_target_candidates.clear()
	return charge_target


func _begin_fighter_charge_dash(charge_target: Node2D) -> void:
	# Capture the life once; a reused Node must not inherit this dash.
	if not hero.fighter_charge_reference.capture(charge_target, hero.get_parent()):
		_finish_fighter_charge()
		return

	hero.fighter_charge_active = true
	hero.fighter_charge_target = charge_target
	hero.fighter_charge_start = hero.global_position
	var direction := hero.global_position.direction_to(charge_target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	var stop_distance := maxf(float(hero.fighter_charge_config.get("stop_distance", 46.0)), 0.0)
	hero.fighter_charge_end = charge_target.global_position - direction * stop_distance
	var distance := hero.fighter_charge_start.distance_to(hero.fighter_charge_end)
	var dash_speed := maxf(float(hero.fighter_charge_config.get("dash_speed", 1450.0)), 1.0)
	hero.fighter_charge_duration = maxf(distance / dash_speed, 0.06)
	hero.fighter_charge_elapsed = 0.0
	hero.fighter_charge_afterimage_timer = 0.0
	hero.velocity = Vector2.ZERO
	hero._face_attack_direction(direction.x)
	hero._restart_stage1_animation("attack", 1.65)
	_play_fighter_attack_effect("thrust", direction)
	if hero.fighter_charge_chain_count == 0:
		_play_fighter_thrust_audio(true)
	_spawn_fighter_afterimage(0.78)


func _update_fighter_charge(delta: float) -> void:
	if not hero.fighter_charge_active:
		return
	if hero.fighter_charge_reference.resolve(hero.get_parent()) == null:
		_finish_fighter_charge()
		return

	hero.fighter_charge_elapsed = minf(
		hero.fighter_charge_elapsed + delta,
		hero.fighter_charge_duration
	)
	var t := clampf(
		hero.fighter_charge_elapsed / maxf(hero.fighter_charge_duration, 0.001),
		0.0,
		1.0
	)
	var eased_t := 1.0 - pow(1.0 - t, 2.5)
	hero.global_position = hero.fighter_charge_start.lerp(hero.fighter_charge_end, eased_t)
	hero._clamp_to_battlefield()

	hero.fighter_charge_afterimage_timer -= delta
	if hero.fighter_charge_afterimage_timer <= 0.0:
		_spawn_fighter_afterimage(0.62)
		hero.fighter_charge_afterimage_timer = maxf(
			float(hero.fighter_charge_config.get("afterimage_interval", 0.035)),
			0.015
		)

	if t >= 1.0:
		_complete_fighter_charge_dash()


func _complete_fighter_charge_dash() -> void:
	# Revalidate immediately before damage, including callbacks during movement.
	var live_target := hero.fighter_charge_reference.resolve(hero.get_parent()) as Node2D
	if live_target == null:
		_finish_fighter_charge()
		return
	var direction := hero.fighter_charge_start.direction_to(hero.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT

	var dash_damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* float(hero.fighter_charge_config.get("dash_damage_ratio", 1.20))
		))
	)
	if is_instance_valid(live_target):
		_fighter_charge_damage_target(live_target, dash_damage)

	var impact_damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* float(hero.fighter_charge_config.get("impact_damage_ratio", 1.70))
		))
	)
	var radius := maxf(float(hero.fighter_charge_config.get("impact_radius", 175.0)), 1.0)
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.fighter_charge_impact_candidates
	)
	for node in hero.fighter_charge_impact_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			hero.global_position.distance_squared_to(monster.global_position)
			<= radius * radius
		):
			_fighter_charge_damage_target(monster, impact_damage)
	hero.fighter_charge_impact_candidates.clear()

	_play_fighter_charge_impact_effect()
	hero.fighter_charge_chain_count += 1

	var base_chains := clampi(
		int(hero.fighter_charge_config.get("max_chains", 3)),
		1,
		3
	)
	var courage_max_chains := clampi(
		int(hero.fighter_charge_config.get("courage_max_chains", 6)),
		base_chains,
		6
	)
	var should_continue := hero.fighter_charge_chain_count < base_chains
	if (
		not should_continue
		and hero.fighter_courage_bonus > 0.0
		and hero.fighter_charge_chain_count < courage_max_chains
	):
		should_continue = randf() <= hero.fighter_courage_bonus

	if should_continue:
		var next_target := _find_fighter_charge_target(hero.fighter_charge_target)
		if is_instance_valid(next_target):
			_begin_fighter_charge_dash(next_target)
			return

	_finish_fighter_charge()


func _fighter_charge_damage_target(monster: Node2D, damage: int) -> void:
	if not is_instance_valid(monster) or monster.is_queued_for_deletion():
		return
	if not monster.has_method("take_damage"):
		return

	var hp_before_value = monster.get("current_hp")
	var hp_before := int(hp_before_value) if hp_before_value != null else -1
	preload("res://src/systems/monster_hit_context.gd").hit(monster, maxi(damage, 1), "melee", hero)

	if hero.fighter_charge_kill_heal <= 0.0 or hp_before <= 0:
		return
	var hp_after_value = monster.get("current_hp")
	if hp_after_value == null or int(hp_after_value) > 0:
		return

	var heal_amount := maxi(int(round(hero.fighter_charge_kill_heal)), 0)
	if heal_amount <= 0 or hero.current_hp <= 0:
		return

	hero.heal_direct(heal_amount)


func _finish_fighter_charge() -> void:
	hero.fighter_charge_reference.clear()
	hero.fighter_charge_active = false
	hero.fighter_charge_target = null
	hero.fighter_charge_elapsed = 0.0
	hero.fighter_charge_duration = 0.0
	hero.fighter_charge_cooldown_timer = maxf(
		float(hero.fighter_charge_config.get("cooldown", 17.0)),
		0.0
	)
	hero.attack_pose_timer = 0.24
	hero.velocity = Vector2.ZERO


func _spawn_fighter_afterimage(alpha: float) -> void:
	if not hero.hero_sprite.visible or hero.hero_sprite.sprite_frames == null:
		return
	if not hero.hero_sprite.sprite_frames.has_animation(hero.hero_sprite.animation):
		return
	var frame_texture := hero.hero_sprite.sprite_frames.get_frame_texture(
		hero.hero_sprite.animation,
		hero.hero_sprite.frame
	)
	if frame_texture == null:
		return

	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return
	var ghost: Sprite2D = null
	if parent.has_method("acquire_transient_fx"):
		ghost = parent.call(
			"acquire_transient_fx",
			"fighter_charge_afterimage",
			"sprite"
		) as Sprite2D
	if ghost == null:
		ghost = Sprite2D.new()
		parent.add_child(ghost)

	ghost.visible = true
	ghost.texture = frame_texture
	ghost.centered = hero.hero_sprite.centered
	ghost.flip_h = hero.hero_sprite.flip_h
	ghost.flip_v = hero.hero_sprite.flip_v
	ghost.offset = hero.hero_sprite.offset
	ghost.scale = hero.hero_sprite.scale
	ghost.rotation = hero.hero_sprite.rotation
	ghost.global_position = hero.global_position
	ghost.z_index = hero.hero_sprite.z_index - 1
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.05, 0.92))

	var fade_time := maxf(
		float(hero.fighter_charge_config.get("afterimage_fade_time", 0.30)),
		0.05
	)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, fade_time)
	if parent.has_method("recycle_transient_fx"):
		tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				ghost,
				"fighter_charge_afterimage"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		tween.finished.connect(
			Callable(ghost, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)


func _play_fighter_charge_impact_effect() -> void:
	_play_fighter_charge_impact_audio()
	if hero.channel_effect.sprite_frames == null:
		return
	if not hero.channel_effect.sprite_frames.has_animation("charge_impact"):
		return
	hero.channel_effect.visible = true
	hero.channel_effect.stop()
	hero.channel_effect.animation = "charge_impact"
	hero.channel_effect.frame = 0
	hero.channel_effect.rotation = 0.0
	hero.channel_effect.position = Vector2(0, 34)
	hero.channel_effect.play("charge_impact")


func _fighter_move_without_monsters(speed_scale: float) -> void:
	if is_instance_valid(hero.heal_item_target):
		var heal_direction := hero._apply_heal_item_steering(Vector2.ZERO, 0.016)
		if heal_direction.length_squared() > 0.01:
			hero._execute_ai_movement(
				heal_direction
				* hero.move_speed
				* 0.90
				* hero._get_effective_move_multiplier()
				* speed_scale
			)
			return

	if is_instance_valid(hero.magnet_item_target):
		var magnet_direction := hero._apply_magnet_item_steering(
			Vector2.ZERO,
			0.016
		)
		if magnet_direction.length_squared() > 0.01:
			hero._execute_ai_movement(
				magnet_direction
				* hero.move_speed
				* 0.82
				* hero._get_effective_move_multiplier()
				* speed_scale
			)
			return

	if is_instance_valid(hero.chest_target):
		var chest_direction := hero._apply_chest_steering(Vector2.ZERO, 0.016)
		if chest_direction.length_squared() > 0.01:
			hero._execute_ai_movement(
				chest_direction
				* hero.move_speed
				* 0.72
				* hero._get_effective_move_multiplier()
				* speed_scale
			)
			if (
				hero.global_position.distance_squared_to(hero.chest_target.global_position)
				<= 105.0 * 105.0
				and hero.attack_timer <= 0.0
			):
				hero.chest_target.call("take_damage", hero.attack_damage)
				hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
			return

	var nearest_exp_orb := hero._find_nearest_exp_orb()
	if is_instance_valid(nearest_exp_orb):
		var exp_direction := hero.global_position.direction_to(nearest_exp_orb.global_position)
		hero._execute_ai_movement(
			exp_direction
			* hero.move_speed
			* 0.90
			* hero._get_effective_move_multiplier()
			* speed_scale
		)
		return

	if (
		hero.wander_timer <= 0.0
		or hero.position.distance_squared_to(hero.wander_target)
		<= hero.WANDER_REACHED_DISTANCE * hero.WANDER_REACHED_DISTANCE
	):
		hero._pick_new_wander_target()

	var direction := hero.position.direction_to(hero.wander_target)
	hero._execute_ai_movement(
		direction
		* hero.move_speed
		* 0.72
		* hero._get_effective_move_multiplier()
		* speed_scale
	)


func _update_fighter_pose_visual(delta: float) -> void:
	if hero.hero_archetype != "sword_shield" or not hero.hero_sprite.visible or hero.is_dying:
		return
	if hero.hit_pose_timer > 0.0 or hero.attack_pose_timer > 0.0:
		return

	hero._update_facing_from_horizontal(hero.velocity.x, delta)
	if hero.velocity.length() > 4.0:
		hero._play_stage1_animation("move", 1.0)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _fighter_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var direction := hero.global_position.direction_to(current_target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.42
	hero._face_attack_direction(direction.x)
	_restart_fighter_attack_animation(false)

	if _fighter_should_use_slash():
		_fighter_apply_slash(direction, false)
		_play_fighter_attack_effect("slash", direction, false)
		_play_fighter_slash_audio()
		if hero.fighter_slash_mastery_stacks > 0:
			hero.fighter_slash_bonus_hits_remaining = hero.fighter_slash_mastery_stacks
			hero.fighter_slash_combo_direction = direction
			hero.fighter_slash_combo_swing_index = 1
			hero.fighter_slash_combo_timer = hero._get_common_attack_interval(0.18)
	else:
		_fighter_apply_thrust(direction)
		_play_fighter_attack_effect("thrust", direction, false)
		_play_fighter_thrust_audio()
	hero._damage_treasure_chests(
		hero.global_position + direction * 85.0,
		145.0,
		hero.attack_damage
	)


func _update_fighter_slash_combo(delta: float) -> bool:
	if hero.fighter_slash_bonus_hits_remaining <= 0:
		return false

	hero.fighter_slash_combo_timer = maxf(hero.fighter_slash_combo_timer - delta, 0.0)
	if hero.fighter_slash_combo_timer > 0.0:
		return true

	hero.fighter_slash_combo_swing_index += 1
	var reverse_frames := hero.fighter_slash_combo_swing_index % 2 == 0
	var direction := hero.fighter_slash_combo_direction
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	hero.attack_pose_timer = 0.24
	hero._face_attack_direction(direction.x)
	_restart_fighter_attack_animation(reverse_frames)
	_fighter_apply_slash(direction, true)
	_play_fighter_attack_effect("slash", direction, reverse_frames)
	_play_fighter_slash_audio()

	hero.fighter_slash_bonus_hits_remaining -= 1
	if hero.fighter_slash_bonus_hits_remaining > 0:
		hero.fighter_slash_combo_timer = hero._get_common_attack_interval(0.18)
	else:
		hero.fighter_slash_combo_timer = 0.0
		hero.fighter_slash_combo_direction = Vector2.ZERO
	return true


func _restart_fighter_attack_animation(reverse_frames: bool) -> void:
	if not hero.hero_sprite.visible or hero.hero_sprite.sprite_frames == null:
		return
	if not hero.hero_sprite.sprite_frames.has_animation("attack"):
		return

	hero.hero_sprite.stop()
	hero.hero_sprite.animation = &"attack"
	hero._set_hero_animation_speed(1.0)
	if reverse_frames:
		var frame_count := hero.hero_sprite.sprite_frames.get_frame_count(&"attack")
		hero.hero_sprite.frame = maxi(frame_count - 1, 0)
		hero.hero_sprite.frame_progress = 0.0
		hero.hero_sprite.play_backwards(&"attack")
	else:
		hero.hero_sprite.frame = 0
		hero.hero_sprite.frame_progress = 0.0
		hero.hero_sprite.play(&"attack")


func _fighter_should_use_slash() -> bool:
	var trigger := hero.HERO_FIGHTER_RUNTIME.get_slash_trigger(
		hero.fighter_basic_config,
		hero.fighter_slash_half_width_bonus
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return hero._count_monsters_near(
		hero.global_position,
		radius,
		required
	) >= required


func _fighter_apply_slash(direction: Vector2, bonus_hit: bool = false) -> int:
	var reach := maxf(float(hero.fighter_basic_config.get("slash_reach", 135.0)), 1.0)
	var half_width := maxf(
		float(hero.fighter_basic_config.get("slash_half_width", 88.0))
		+ hero.fighter_slash_half_width_bonus,
		1.0
	)
	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* float(hero.fighter_basic_config.get("slash_damage_ratio", 1.0))
			* hero.fighter_basic_damage_multiplier
		))
	)
	var side := Vector2(-direction.y, direction.x)
	var bonus_kills := 0

	hero._fill_monster_nodes_near(
		hero.global_position,
		reach + half_width,
		hero.fighter_combat_candidates
	)
	for node in hero.fighter_combat_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := monster.global_position - hero.global_position
		var forward := offset.dot(direction)
		var lateral := absf(offset.dot(side))
		if forward < -24.0 or forward > reach or lateral > half_width:
			continue
		if not monster.has_method("take_damage"):
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before := int(hp_before_value) if hp_before_value != null else -1
		preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "melee", hero)
		if not bonus_hit or hp_before <= 0:
			continue
		if not is_instance_valid(monster):
			bonus_kills += 1
			continue
		var hp_after_value = monster.get("current_hp")
		if hp_after_value != null and int(hp_after_value) <= 0:
			bonus_kills += 1
	hero.fighter_combat_candidates.clear()

	if bonus_kills > 0 and hero.current_hp > 0:
		hero.heal_direct(bonus_kills * 10)

	return bonus_kills


func _fighter_apply_thrust(direction: Vector2) -> void:
	var length := maxf(
		float(hero.fighter_basic_config.get("thrust_length", 190.0))
		+ hero.fighter_thrust_length_bonus,
		1.0
	)
	var half_width := maxf(
		float(hero.fighter_basic_config.get("thrust_half_width", 34.0)),
		1.0
	)
	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* (
				float(hero.fighter_basic_config.get("thrust_damage_ratio", 1.05))
				+ hero.fighter_thrust_damage_bonus
			)
			* hero.fighter_basic_damage_multiplier
		))
	)
	var side := Vector2(-direction.y, direction.x)

	hero._fill_monster_nodes_near(
		hero.global_position,
		length + half_width,
		hero.fighter_combat_candidates
	)
	for node in hero.fighter_combat_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := monster.global_position - hero.global_position
		var forward := offset.dot(direction)
		var lateral := absf(offset.dot(side))
		if forward < 0.0 or forward > length or lateral > half_width:
			continue
		if monster.has_method("take_damage"):
			preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "melee", hero)
	hero.fighter_combat_candidates.clear()


func _update_fighter_guard(delta: float) -> void:
	if hero.fighter_guard_active:
		hero.fighter_guard_duration_timer = maxf(
			hero.fighter_guard_duration_timer - delta,
			0.0
		)
		if hero.fighter_guard_duration_timer <= 0.0:
			_end_fighter_guard()
		return

	var charge_max := maxf(float(hero.ultimate_config.get("charge_max", 100.0)), 1.0)
	var charge_seconds := maxf(hero.fighter_guard_charge_seconds, 1.0)
	hero.ultimate_charge = minf(
		hero.ultimate_charge + (charge_max / charge_seconds) * delta,
		charge_max
	)
	if hero.ultimate_charge + 0.001 >= charge_max and _fighter_can_activate_guard():
		_start_fighter_guard()
	hero.queue_redraw()


func _fighter_can_activate_guard() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.imposed_skill_cooldown > 0.0:
		return false
	var trigger := hero.HERO_FIGHTER_RUNTIME.get_guard_trigger(
		hero.ultimate_config
	)
	var radius := trigger.x
	var required := maxi(int(trigger.y), 1)
	return hero._count_monsters_near(
		hero.global_position,
		radius,
		required
	) >= required


func _start_fighter_guard() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.fighter_guard_active:
		return

	hero.fighter_guard_active = true
	hero.fighter_guard_duration_timer = maxf(
		float(hero.ultimate_config.get("duration", 10.0)),
		0.1
	)
	hero.fighter_guard_stored_damage = 0.0
	hero.ultimate_charge = 0.0

	var shield_ratio := maxf(
		float(hero.ultimate_config.get("shield_hp_ratio", 0.60))
		+ hero.fighter_guard_shield_ratio_bonus,
		0.0
	)
	hero.shield_max_hp = hero._player_shield_amount(float(hero.max_hp) * shield_ratio)
	hero.shield_hp = hero.shield_max_hp

	_play_fighter_guard_start_audio()
	if hero.shield_effect.sprite_frames != null and hero.shield_effect.sprite_frames.has_animation("guard_aura"):
		hero.shield_effect.visible = true
		hero.shield_effect.play("guard_aura")

	hero.ultimate_used.emit(
		String(hero.ultimate_config.get("id", "shield_guard")),
		String(hero.ultimate_config.get("name", "막기"))
	)
	hero.queue_redraw()


func _end_fighter_guard() -> void:
	if not hero.fighter_guard_active:
		return

	hero.fighter_guard_active = false
	hero.fighter_guard_duration_timer = 0.0
	hero.shield_effect.visible = false

	var release_ratio := maxf(
		float(hero.ultimate_config.get("stored_damage_release_ratio", 0.50))
		+ hero.fighter_guard_release_ratio_bonus,
		0.0
	)
	var release_damage := maxi(
		int(round(hero.fighter_guard_stored_damage * release_ratio)),
		0
	)
	var release_radius := maxf(
		float(hero.ultimate_config.get("release_radius", 250.0)),
		0.0
	)

	if release_damage > 0 and release_radius > 0.0:
		hero._fill_monster_nodes_near(
			hero.global_position,
			release_radius,
			hero.fighter_combat_candidates
		)
		var release_radius_sq := release_radius * release_radius
		for node in hero.fighter_combat_candidates:
			if not hero.HERO_TARGET_POLICY.is_detectable(node):
				continue
			var monster := node as Node2D
			if monster == null:
				continue
			if (
				hero.global_position.distance_squared_to(monster.global_position)
				> release_radius_sq
			):
				continue
			if monster.has_method("take_damage"):
				preload("res://src/systems/monster_hit_context.gd").hit(monster, release_damage, "ranged", hero)
		hero.fighter_combat_candidates.clear()

	_play_fighter_guard_release_effect()

	hero.fighter_guard_stored_damage = 0.0
	hero.shield_hp = 0.0
	hero.shield_max_hp = 0.0
	hero.queue_redraw()


func _fighter_reflect_damage(raw_damage: float, source: Node) -> void:
	if hero.fighter_reflect_ratio <= 0.0:
		return
	var reflected := maxi(
		1,
		int(round(raw_damage * hero.fighter_reflect_ratio))
	)

	if (
		is_instance_valid(source)
		and source.is_in_group("monsters")
		and source.has_method("take_damage")
	):
		preload("res://src/systems/monster_hit_context.gd").hit(source, reflected, "melee", hero)
		return

	var reflect_radius := maxf(
		float(hero.ultimate_config.get("reflect_radius", 175.0)),
		1.0
	)
	var nearest: Node2D = null
	var nearest_distance_sq := INF
	var reflect_radius_sq := reflect_radius * reflect_radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		reflect_radius,
		hero.fighter_combat_candidates
	)
	for node in hero.fighter_combat_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var distance_sq := hero.global_position.distance_squared_to(
			monster.global_position
		)
		if (
			distance_sq <= reflect_radius_sq
			and distance_sq < nearest_distance_sq
		):
			nearest = monster
			nearest_distance_sq = distance_sq
	hero.fighter_combat_candidates.clear()
	if is_instance_valid(nearest) and nearest.has_method("take_damage"):
		preload("res://src/systems/monster_hit_context.gd").hit(nearest, reflected, "melee", hero)


func _play_fighter_attack_effect(
	animation_name: String,
	direction: Vector2,
	reverse_frames: bool = false
) -> void:
	if hero.rogue_attack_effect.sprite_frames == null:
		return
	if not hero.rogue_attack_effect.sprite_frames.has_animation(animation_name):
		return

	hero.rogue_attack_effect.visible = true
	hero.rogue_attack_effect.stop()
	hero.rogue_attack_effect.animation = animation_name
	hero.rogue_attack_effect.rotation = direction.angle()
	if reverse_frames:
		var frame_count := hero.rogue_attack_effect.sprite_frames.get_frame_count(animation_name)
		hero.rogue_attack_effect.frame = maxi(frame_count - 1, 0)
		hero.rogue_attack_effect.frame_progress = 0.0
		hero.rogue_attack_effect.play_backwards(animation_name)
	else:
		hero.rogue_attack_effect.frame = 0
		hero.rogue_attack_effect.frame_progress = 0.0
		hero.rogue_attack_effect.play(animation_name)


func _play_fighter_guard_release_effect() -> void:
	_play_fighter_guard_release_audio()
	if hero.channel_effect.sprite_frames == null:
		return
	if not hero.channel_effect.sprite_frames.has_animation("guard_release"):
		return

	hero.channel_effect.visible = true
	hero.channel_effect.stop()
	hero.channel_effect.animation = "guard_release"
	hero.channel_effect.frame = 0
	hero.channel_effect.rotation = 0.0
	hero.channel_effect.play("guard_release")


func _apply_stage3_fighter_effect_visuals() -> void:
	hero._configure_combat_effect_profile(hero.HERO_PRESENTATION.get_combat_effect_profile(hero.hero_archetype, &"fighter"))
