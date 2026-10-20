extends RefCounted
## Berserker archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _apply_stage6_berserker_effect_visuals() -> void:
	hero._configure_channel_effect_profile(hero.HERO_PRESENTATION.get_channel_effect_profile(hero.hero_archetype, &"persistent"))


func _ensure_berserker_audio_runtime() -> void:
	if hero.hero_archetype != "berserker_madness":
		return

	if hero.berserker_basic_audio_pool.is_empty():
		for index in range(4):
			hero.berserker_basic_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE6_BASIC_AUDIO_PATH,
					hero.HERO_SFX_DB_PRIMARY_ATTACK - 5.0,
					0.94
				)
			)

	if hero.berserker_skill1_audio_pool.is_empty():
		for index in range(3):
			hero.berserker_skill1_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE6_SKILL1_AUDIO_PATH,
					hero.HERO_SFX_DB_REGULAR_SKILL - 3.0,
					0.82
				)
			)

	if not is_instance_valid(hero.berserker_skill2_audio):
		hero.berserker_skill2_audio = hero._create_hero_sfx_player(
			hero.STAGE6_SKILL2_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 2.0,
			0.72
		)
	if not is_instance_valid(hero.berserker_skill3_audio):
		hero.berserker_skill3_audio = hero._create_hero_sfx_player(
			hero.STAGE6_SKILL3_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.18
		)
	if not is_instance_valid(hero.berserker_skill4_audio):
		hero.berserker_skill4_audio = hero._create_hero_sfx_player(
			hero.STAGE6_SKILL4_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 1.0,
			0.90
		)
	if not is_instance_valid(hero.berserker_madness_roar_audio):
		hero.berserker_madness_roar_audio = hero._create_hero_sfx_player(
			hero.STAGE6_MADNESS_ROAR_AUDIO_PATH, hero.HERO_SFX_DB_HEAVY_SKILL - 5.0, 1.0
		)
	if not is_instance_valid(hero.berserker_hit_audio):
		hero.berserker_hit_audio = hero._create_hero_sfx_player(
			hero.STAGE6_HIT_AUDIO_PATH, hero.CONTEXT_AUDIO.HIT_DB, 1.0
		)
	if not is_instance_valid(hero.berserker_death_audio):
		hero.berserker_death_audio = hero._create_hero_sfx_player(
			hero.STAGE6_DEATH_AUDIO_PATH,
			hero.HERO_SFX_DB_DEATH,
			0.82
		)


func _play_berserker_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_berserker_basic_audio() -> void:
	_ensure_berserker_audio_runtime()
	if hero.berserker_basic_audio_pool.is_empty():
		return
	var player := hero.berserker_basic_audio_pool[
		hero.berserker_basic_audio_cursor % hero.berserker_basic_audio_pool.size()
	]
	hero.berserker_basic_audio_cursor = (
		hero.berserker_basic_audio_cursor + 1
	) % hero.berserker_basic_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = (
		1.02 + 0.04 * float(hero.berserker_basic_audio_cursor % 3)
		if hero.berserker_madness_active
		else 0.88 + 0.04 * float(hero.berserker_basic_audio_cursor % 3)
	)
	player.stop()
	player.play()


func _play_berserker_skill1_audio(wave_index: int) -> void:
	_ensure_berserker_audio_runtime()
	if hero.berserker_skill1_audio_pool.is_empty():
		return
	var player := hero.berserker_skill1_audio_pool[
		hero.berserker_skill1_audio_cursor % hero.berserker_skill1_audio_pool.size()
	]
	hero.berserker_skill1_audio_cursor = (
		hero.berserker_skill1_audio_cursor + 1
	) % hero.berserker_skill1_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 0.78 + 0.07 * float(clampi(wave_index, 0, 2))
	player.stop()
	player.play()


func _play_berserker_hit_audio() -> void:
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_hit_audio)


func _play_berserker_death_audio() -> void:
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_death_audio)


func _append_berserker_skill_cooldown_hud(
	skills: Array,
	config: Dictionary,
	remaining: float,
	icon_path: String
) -> void:
	if config.is_empty():
		return
	var cooldown_total: float = _get_berserker_skill_cooldown(
		config,
		0.0
	)
	if cooldown_total <= 0.0:
		return
	var current_remaining := maxf(remaining, 0.0)
	skills.append({
		"id": String(config.get("id", "skill")),
		"name": String(config.get("name", "기술")),
		"description": hero._skill_hud_description(config),
		"resource_text": hero._skill_hud_resource_text(config),
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
		"icon_path": icon_path,
	})


func _physics_process_berserker(delta: float) -> void:
	hero.ai_memory_clock += delta
	hero._prune_offensive_memory()
	hero._prune_status_memory()

	hero.ai_observation_timer = maxf(hero.ai_observation_timer - delta, 0.0)
	if hero.ai_observation_timer <= 0.0:
		hero._refresh_ai_observation()

	hero.attack_timer = maxf(hero.attack_timer - delta * hero.get_paralysis_attack_multiplier(), 0.0)
	hero.berserker_skill1_cooldown = maxf(
		hero.berserker_skill1_cooldown - delta,
		0.0
	)
	hero.berserker_skill2_cooldown = maxf(
		hero.berserker_skill2_cooldown - delta,
		0.0
	)
	hero.berserker_skill3_cooldown = maxf(
		hero.berserker_skill3_cooldown - delta,
		0.0
	)
	hero.berserker_skill4_cooldown = maxf(
		hero.berserker_skill4_cooldown - delta,
		0.0
	)
	hero.berserker_skill_global_cooldown = maxf(
		hero.berserker_skill_global_cooldown - delta,
		0.0
	)
	hero.retarget_timer = maxf(hero.retarget_timer - delta, 0.0)
	hero.wander_timer = maxf(hero.wander_timer - delta, 0.0)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer - delta, 0.0)
	hero.hit_pose_timer = maxf(hero.hit_pose_timer - delta, 0.0)
	hero.ultimate_flash_timer = maxf(hero.ultimate_flash_timer - delta, 0.0)
	hero._update_invulnerability(delta)
	_update_berserker_madness(delta)
	_update_berserker_hp_visual()

	if hero.level_flash_timer > 0.0:
		hero.level_flash_timer = maxf(hero.level_flash_timer - delta, 0.0)
		hero.queue_redraw()

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0
			hero.queue_redraw()

	if hero.berserker_reviving:
		hero.velocity = Vector2.ZERO
		return

	if hero.berserker_skill3_active:
		hero.velocity = Vector2.ZERO
		return

	if _update_berserker_skill1(delta):
		hero.velocity = Vector2.ZERO
		_update_berserker_pose_visual(delta)
		return

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

	if not is_instance_valid(hero.target):
		hero._fighter_move_without_monsters(1.0)
		_update_berserker_pose_visual(delta)
		return

	var distance: float = hero.global_position.distance_to(hero.target.global_position)
	var move_direction: Vector2 = hero._choose_melee_spacing_direction(
		hero.target,
		distance,
		0.88
	)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)

	if move_direction.length_squared() > 0.01:
		hero._execute_ai_movement(move_direction * hero.move_speed * hero._get_effective_move_multiplier())
	else:
		hero.velocity = Vector2.ZERO

	var attack_trigger_range: float = hero.attack_range
	if hero.berserker_madness_active:
		attack_trigger_range = maxf(
			float(hero.berserker_config.get("madness_target_radius", 375.0)),
			hero.attack_range
		)
	var used_contextual_skill: bool = _try_use_berserker_contextual_skill(
		hero.target,
		distance
	)
	if (
		not used_contextual_skill
		and distance <= attack_trigger_range
		and hero.attack_timer <= 0.0
	):
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.BERSERKER, hero.target)

	_update_berserker_pose_visual(delta)


func _try_use_berserker_contextual_skill(
	current_target: Node2D,
	distance: float
) -> bool:
	if hero.silence_timer > 0.0:
		return false
	if (
		hero.berserker_skill_global_cooldown > 0.0
		or not is_instance_valid(current_target)
	):
		return false

	var hp_ratio: float = clampf(
		float(hero.current_hp) / float(maxi(hero.max_hp, 1)),
		0.0,
		1.0
	)
	var close_count: int = hero._count_monsters_near(
		hero.global_position,
		245.0,
		6
	)
	var recovery_count: int = hero._count_monsters_near(
		hero.global_position,
		330.0,
		6
	)
	var skill1_value = hero.berserker_config.get("skill_1", {})
	var skill1_range: float = hero.attack_range
	if typeof(skill1_value) == TYPE_DICTIONARY:
		var skill1_config: Dictionary = skill1_value
		skill1_range = maxf(
			float(skill1_config.get("base_range", 300.0)),
			hero.attack_range
		)

	# 3식은 저체력 회복/재배치용. 적이 충분할 때만 사용한다.
	if (
		hero.berserker_skill3_cooldown <= 0.0
		and distance <= 500.0
		and recovery_count >= 2
		and (
			hp_ratio <= 0.62
			or recovery_count >= 5
		)
	):
		_start_berserker_skill3(current_target)
		return true

	# 4식은 실제 포위 압력이 있을 때 밀어내기 용도로 보존한다.
	var spin_required: int = 2 if hero.berserker_madness_active else 3
	if (
		hero.berserker_skill4_cooldown <= 0.0
		and close_count >= spin_required
		and hp_ratio >= 0.22
	):
		_start_berserker_skill4()
		return true

	# 2식은 적 밀집 또는 체력 회복 가치가 있을 때 우선한다.
	if (
		hero.berserker_skill2_cooldown <= 0.0
		and distance <= 320.0
		and hp_ratio >= 0.26
		and (
			recovery_count >= 4
			or (
				hp_ratio <= 0.58
				and recovery_count >= 2
			)
		)
	):
		_start_berserker_skill2(current_target)
		return true

	# 1식은 중거리에서 평타가 닿지 않을 때 주력 견제기로 사용한다.
	if (
		hero.berserker_skill1_cooldown <= 0.0
		and distance <= skill1_range
		and distance > maxf(hero.attack_range * 0.90, 130.0)
		and hp_ratio >= 0.30
	):
		_start_berserker_skill1(current_target)
		return true

	return false


func _get_berserker_skill_cooldown(
	skill_config: Dictionary,
	fallback: float
) -> float:
	var base_cooldown: float = maxf(
		float(skill_config.get("cooldown", fallback)),
		0.0
	)
	return base_cooldown * (
		1.0 - clampf(
			hero.berserker_blood_art_cooldown_reduction,
			0.0,
			0.15
		)
	)


func _pay_berserker_skill_hp_cost(hp_cost_ratio: float) -> void:
	var ratio: float = clampf(hp_cost_ratio, 0.0, 0.95)
	var cost_base: float = float(hero.current_hp)
	if hero.berserker_blood_art_eighth_stacks > 0:
		cost_base = float(hero.max_hp)
	var hp_cost: int = maxi(
		int(round(cost_base * ratio)),
		1
	)
	hero.current_hp = maxi(hero.current_hp - hp_cost, 1)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)


func _berserker_blood_art_eighth_heal_on_hit() -> void:
	if hero.berserker_blood_art_eighth_stacks <= 0:
		return
	var missing_hp: int = maxi(hero.max_hp - hero.current_hp, 0)
	if missing_hp <= 0:
		return
	var heal_ratio: float = (
		0.005
		+ 0.003
		* float(hero.berserker_blood_art_eighth_stacks - 1)
	)
	var heal_amount: int = maxi(
		int(round(float(missing_hp) * heal_ratio)),
		1
	)
	hero.heal_direct(heal_amount)


func notify_berserker_blood_art_hit() -> void:
	_berserker_blood_art_eighth_heal_on_hit()


func _start_berserker_skill1(current_target: Node2D) -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.berserker_skill1_active or not is_instance_valid(current_target):
		return

	var skill_config_value = hero.berserker_config.get("skill_1", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.05)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	hero.berserker_skill1_direction = hero.global_position.direction_to(
		current_target.global_position
	)
	if hero.berserker_skill1_direction.length_squared() <= 0.0:
		hero.berserker_skill1_direction = (
			Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
		)
	hero.berserker_skill1_direction = hero.berserker_skill1_direction.normalized()

	hero.berserker_skill1_active = true
	hero.berserker_skill1_wave_index = 0
	hero.berserker_skill1_wave_timer = 0.0
	hero.berserker_skill1_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		15.0
	)
	hero.berserker_skill_global_cooldown = maxf(
		hero.berserker_skill_global_cooldown,
		2.40
	)
	hero.attack_timer = maxf(hero.attack_timer, 2.35)
	hero.attack_pose_timer = 0.0
	hero._face_attack_direction(hero.berserker_skill1_direction.x)
	hero.queue_redraw()


func _update_berserker_skill1(delta: float) -> bool:
	if not hero.berserker_skill1_active:
		return false

	var skill_config_value = hero.berserker_config.get("skill_1", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		hero.berserker_skill1_active = false
		return false
	var skill_config: Dictionary = skill_config_value

	hero.berserker_skill1_wave_timer = maxf(
		hero.berserker_skill1_wave_timer - delta,
		0.0
	)
	if hero.berserker_skill1_wave_timer > 0.0:
		return true

	var wave_count: int = maxi(
		int(skill_config.get("wave_count", 3)),
		1
	)
	if hero.berserker_skill1_wave_index >= wave_count:
		hero.berserker_skill1_active = false
		return false

	_berserker_emit_skill1_wave(
		hero.berserker_skill1_wave_index,
		skill_config
	)
	hero.berserker_skill1_wave_index += 1
	if hero.berserker_skill1_wave_index >= wave_count:
		hero.berserker_skill1_active = false
		return false

	hero.berserker_skill1_wave_timer = maxf(
		float(skill_config.get("wave_interval", 0.75)),
		0.05
	)
	return true


func _berserker_emit_skill1_wave(
	wave_index: int,
	skill_config: Dictionary
) -> void:
	var direction: Vector2 = hero.berserker_skill1_direction
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	hero._face_attack_direction(direction.x)
	hero._restart_stage1_animation("attack")
	hero.attack_pose_timer = 0.46
	_play_berserker_skill1_audio(wave_index)

	var growth: float = maxf(
		float(skill_config.get("size_growth_per_wave", 0.25)),
		0.0
	)
	var scale_multiplier: float = 1.0 + growth * float(wave_index)
	var projectile_range: float = (
		maxf(float(skill_config.get("base_range", 560.0)), 1.0)
		* scale_multiplier
	)
	var half_width: float = (
		maxf(float(skill_config.get("base_half_width", 64.0)), 1.0)
		* scale_multiplier
	)
	var projectile_speed_value: float = maxf(
		float(skill_config.get("projectile_speed", 760.0)),
		1.0
	)

	var repeat_values = skill_config.get(
		"repeat_hit_multipliers",
		[1.0, 0.80, 0.60]
	)
	var repeat_multiplier: float = 1.0
	if typeof(repeat_values) == TYPE_ARRAY:
		var repeat_array: Array = repeat_values
		if wave_index >= 0 and wave_index < repeat_array.size():
			repeat_multiplier = float(repeat_array[wave_index])

	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 1.10))
			* repeat_multiplier
		)),
		1
	)

	var back_direction: Vector2 = -direction
	var blood_recoil_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
		"%s/effect2" % hero.STAGE6_FRAME_DIR,
		"blood_effect",
		1,
		10,
		30.0,
		false,
		hero.global_position + back_direction * 38.0,
		Vector2(
			0.84 * scale_multiplier,
			0.84 * scale_multiplier
		)
	)
	if is_instance_valid(blood_recoil_fx):
		blood_recoil_fx.flip_h = back_direction.x < 0.0
		blood_recoil_fx.rotation = (
			back_direction.angle()
			if back_direction.x >= 0.0
			else back_direction.angle() - PI
		)
		blood_recoil_fx.modulate = Color(1.0, 0.72, 0.72, 0.95)
		blood_recoil_fx.z_index = 7
		var recoil_fade := blood_recoil_fx.create_tween()
		recoil_fade.tween_property(
			blood_recoil_fx,
			"modulate:a",
			0.0,
			0.24
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var projectile_config: Dictionary = {
		"hit_radius": half_width,
		"visual_scale": 0.936 * scale_multiplier,
	}
	var projectile := hero._acquire_projectile(
		hero.ARCHMAGE_SKILL_PROJECTILE_SCENE,
		"berserker_wave_projectile"
	)
	if projectile == null:
		return

	projectile.global_position = hero.global_position + direction * 54.0
	projectile.call(
		"setup",
		"berserker_wave",
		direction,
		damage,
		projectile_speed_value,
		projectile_range,
		projectile_config,
		hero,
		false,
		null
	)


func _start_berserker_skill2(current_target: Node2D) -> void:
	if hero.silence_timer > 0.0:
		return
	if not is_instance_valid(current_target):
		return

	var skill_config_value = hero.berserker_config.get("skill_2", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.07)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	hero.berserker_skill2_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		19.0
	)
	hero.berserker_skill_global_cooldown = maxf(
		hero.berserker_skill_global_cooldown,
		1.35
	)
	hero.attack_timer = maxf(hero.attack_timer, 0.72)
	hero.attack_pose_timer = 0.58
	hero._face_attack_direction(
		hero.global_position.direction_to(current_target.global_position).x
	)
	hero._restart_stage1_animation("attack")
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_skill2_audio)

	var slam_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
		"%s/effect3" % hero.STAGE6_FRAME_DIR,
		"ground_slam",
		1,
		11,
		20.0,
		false,
		hero.global_position,
		Vector2(0.92, 0.92)
	)
	if is_instance_valid(slam_fx):
		slam_fx.z_index = 6

	var wave_count: int = maxi(
		int(skill_config.get("wave_count", 4)),
		1
	)
	var base_offset: float = randf_range(-0.22, 0.22)
	for wave_index in range(wave_count):
		var angle: float = (
			TAU * float(wave_index) / float(wave_count)
			+ base_offset
			+ randf_range(-0.16, 0.16)
		)
		var wave_direction: Vector2 = Vector2.RIGHT.rotated(angle)
		_run_berserker_skill2_wave(
			hero.global_position,
			wave_direction,
			skill_config
		)

	hero.queue_redraw()


func _run_berserker_skill2_wave(
	start_position: Vector2,
	start_direction: Vector2,
	skill_config: Dictionary
) -> void:
	var world_points: Array[Vector2] = []
	world_points.append(start_position)
	var blood_visuals: Array[AnimatedSprite2D] = []

	var hit_ids: Dictionary = {}
	var healed_ids: Dictionary = {}
	var current_position: Vector2 = start_position
	var current_direction: Vector2 = start_direction.normalized()
	var cell_length: float = maxf(
		float(skill_config.get("cell_length", 72.0)),
		8.0
	)
	var cell_count: int = maxi(
		int(skill_config.get("cell_count", 6)),
		1
	)
	var branch_angle: float = deg_to_rad(
		maxf(float(skill_config.get("branch_angle_degrees", 68.0)), 0.0)
	)
	var branch_min_angle: float = deg_to_rad(
		clampf(
			float(skill_config.get("branch_min_angle_degrees", 28.0)),
			0.0,
			rad_to_deg(branch_angle)
		)
	)
	var turn_sign: float = -1.0 if randf() < 0.5 else 1.0
	var wave_speed: float = maxf(
		float(skill_config.get("wave_speed", 620.0)),
		1.0
	)
	var half_width: float = maxf(
		float(skill_config.get("path_half_width", 30.0)),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 0.85))
		)),
		1
	)

	for cell_index in range(cell_count):
		if not hero.is_inside_tree():
			return

		var turn_amount: float = randf_range(
			branch_min_angle,
			branch_angle
		)
		if randf() < 0.22:
			turn_sign *= -1.0
		var turn: float = turn_amount * turn_sign
		current_direction = current_direction.rotated(turn).normalized()
		turn_sign *= -1.0
		var next_position: Vector2 = (
			current_position + current_direction * cell_length
		)
		next_position = Vector2(
			clampf(
				next_position.x,
				hero.FIELD_MARGIN,
				hero.battlefield_size.x - hero.FIELD_MARGIN
			),
			clampf(
				next_position.y,
				hero.FIELD_MARGIN,
				hero.battlefield_size.y - hero.FIELD_MARGIN
			)
		)

		_damage_berserker_skill2_segment(
			current_position,
			next_position,
			half_width,
			damage,
			hit_ids
		)

		var segment: Vector2 = next_position - current_position
		var blood_position: Vector2 = current_position.lerp(
			next_position,
			0.5
		)
		var blood_scale_x: float = maxf(
			segment.length() / 128.0,
			0.42
		)
		var blood_scale_y: float = maxf(
			half_width / 46.0,
			0.46
		)
		var blood_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
			"%s/effect3" % hero.STAGE6_FRAME_DIR,
			"ground_slam",
			7,
			1,
			1.0,
			true,
			blood_position,
			Vector2(blood_scale_x, blood_scale_y)
		)
		if is_instance_valid(blood_fx):
			blood_fx.rotation = segment.angle()
			blood_fx.z_index = 4
			blood_fx.modulate = Color.WHITE
			blood_visuals.append(blood_fx)

		world_points.append(next_position)
		current_position = next_position

		var step_time: float = cell_length / wave_speed
		await hero.COMBAT_DELAY.wait(hero,
			maxf(step_time, 0.03)
		)

	var blood_duration: float = maxf(
		float(skill_config.get("blood_duration", 2.0)),
		0.0
	)
	var tick_interval: float = maxf(
		float(skill_config.get("heal_tick_interval", 0.15)),
		0.05
	)
	var heal_per_touch: int = maxi(
		int(skill_config.get("heal_per_touch_tick", 10)),
		1
	)
	var elapsed: float = 0.0
	while elapsed < blood_duration and hero.is_inside_tree():
		_heal_berserker_from_blood_path(
			world_points,
			half_width,
			heal_per_touch,
			healed_ids
		)
		await hero.COMBAT_DELAY.wait(hero,tick_interval)
		elapsed += tick_interval

	for blood_fx in blood_visuals:
		if not is_instance_valid(blood_fx):
			continue
		var fade_position: Vector2 = blood_fx.global_position
		var fade_rotation: float = blood_fx.rotation
		var fade_scale: Vector2 = blood_fx.scale
		hero._recycle_archmage_fx(blood_fx)

		var fade_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
			"%s/effect3" % hero.STAGE6_FRAME_DIR,
			"ground_slam",
			8,
			4,
			12.0,
			false,
			fade_position,
			fade_scale
		)
		if is_instance_valid(fade_fx):
			fade_fx.rotation = fade_rotation
			fade_fx.z_index = 4


func _damage_berserker_skill2_segment(
	from_position: Vector2,
	to_position: Vector2,
	half_width: float,
	damage: int,
	hit_ids: Dictionary
) -> void:
	var segment: Vector2 = to_position - from_position
	var length_sq: float = maxf(segment.length_squared(), 0.001)
	var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
	var search_radius: float = segment.length() * 0.5 + half_width + 20.0
	var half_width_sq: float = half_width * half_width
	hero._fill_monster_nodes_near(
		midpoint,
		search_radius,
		hero.berserker_query_candidates
	)

	for node in hero.berserker_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
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
			> half_width_sq
		):
			continue

		hit_ids[iid] = true
		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "melee", hero)
		_berserker_blood_art_eighth_heal_on_hit()

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()
	hero.berserker_query_candidates.clear()


func _heal_berserker_from_blood_path(
	world_points: Array[Vector2],
	half_width: float,
	heal_per_touch: int,
	healed_ids: Dictionary
) -> void:
	if hero.current_hp <= 0 or hero.is_dying or world_points.size() < 2:
		return

	healed_ids.clear()
	var half_width_sq: float = half_width * half_width
	for segment_index in range(world_points.size() - 1):
		var from_position: Vector2 = world_points[segment_index]
		var to_position: Vector2 = world_points[segment_index + 1]
		var segment: Vector2 = to_position - from_position
		var length_sq: float = maxf(segment.length_squared(), 0.001)
		var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
		var search_radius: float = (
			segment.length() * 0.5 + half_width + 20.0
		)
		hero._fill_monster_nodes_near(
			midpoint,
			search_radius,
			hero.berserker_query_candidates
		)

		for node in hero.berserker_query_candidates:
			if not hero.HERO_TARGET_POLICY.is_detectable(node):
				continue
			var monster := node as Node2D
			if monster == null:
				continue
			var iid: int = monster.get_instance_id()
			if healed_ids.has(iid):
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
				> half_width_sq
			):
				continue

			healed_ids[iid] = true
			hero.heal_direct(heal_per_touch)
		hero.berserker_query_candidates.clear()


func _start_berserker_skill3(current_target: Node2D) -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.berserker_skill3_active or not is_instance_valid(current_target):
		return

	var skill_config_value = hero.berserker_config.get("skill_3", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.05)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	var dash_direction: Vector2 = hero.global_position.direction_to(
		current_target.global_position
	)
	if dash_direction.length_squared() <= 0.0:
		dash_direction = (
			Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
		)
	dash_direction = dash_direction.normalized()
	hero._face_attack_direction(dash_direction.x)

	hero.berserker_skill3_active = true
	hero.berserker_skill3_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		30.0
	)
	hero.berserker_skill_global_cooldown = maxf(
		hero.berserker_skill_global_cooldown,
		1.75
	)
	hero.attack_timer = maxf(hero.attack_timer, 1.55)
	hero.attack_pose_timer = 1.55
	_execute_berserker_skill3(
		dash_direction,
		skill_config
	)
	hero.queue_redraw()


func _execute_berserker_skill3(
	dash_direction: Vector2,
	skill_config: Dictionary
) -> void:
	var start_position: Vector2 = hero.global_position
	var dash_distance: float = maxf(
		float(skill_config.get("dash_distance", 500.0)),
		1.0
	)
	var destination: Vector2 = (
		start_position + dash_direction * dash_distance
	)
	destination = Vector2(
		clampf(
			destination.x,
			hero.FIELD_MARGIN,
			hero.battlefield_size.x - hero.FIELD_MARGIN
		),
		clampf(
			destination.y,
			hero.FIELD_MARGIN,
			hero.battlefield_size.y - hero.FIELD_MARGIN
		)
	)

	var saved_collision_layer: int = hero.collision_layer
	var saved_collision_mask: int = hero.collision_mask
	hero.collision_layer = 0
	hero.collision_mask = 0
	hero.velocity = Vector2.ZERO
	hero._restart_stage1_animation("dash_start")
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_skill3_audio)

	if hero.player_controlled and hero.player_weapons != null:
		hero.player_weapons._effect(start_position,destination,12,"chain",Color(0.82,0.05,0.03,0.82))
	else:
		_spawn_berserker_blood_dash_trail(start_position,destination)

	var dash_duration: float = maxf(
		float(skill_config.get("dash_duration", 0.20)),
		0.05
	)
	var dash_tween := hero.create_tween()
	dash_tween.tween_property(
		hero,
		"global_position",
		destination,
		dash_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await dash_tween.finished

	if not hero.is_inside_tree() or hero.is_dying:
		return

	hero.collision_layer = saved_collision_layer
	hero.collision_mask = saved_collision_mask
	hero.global_position = destination
	hero.velocity = Vector2.ZERO
	hero._restart_stage1_animation("dash_finish")

	var orb_radius: float = maxf(
		float(skill_config.get("blood_orb_radius", 330.0)),
		1.0
	)
	var orb_radius_sq: float = orb_radius * orb_radius
	var orb_count: int = 0
	hero._fill_monster_nodes_near(
		hero.global_position,
		orb_radius,
		hero.berserker_query_candidates
	)
	for node in hero.berserker_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		if (
			hero.global_position.distance_squared_to(monster.global_position)
			> orb_radius_sq
		):
			continue
		_spawn_berserker_blood_orb(
			monster.global_position,
			skill_config
		)
		_berserker_blood_art_eighth_heal_on_hit()
		orb_count += 1
	hero.berserker_query_candidates.clear()

	var pickup_duration: float = maxf(
		float(skill_config.get("orb_pickup_duration", 0.42)),
		0.08
	)
	if orb_count > 0:
		await hero.COMBAT_DELAY.wait(hero,
			pickup_duration + 0.10
		)
	else:
		await hero.COMBAT_DELAY.wait(hero,0.16)

	if not hero.is_inside_tree():
		return
	hero.berserker_skill3_active = false
	hero.attack_pose_timer = 0.0
	hero._play_stage1_animation("idle", 1.0)


func _spawn_berserker_blood_orb(
	start_position: Vector2,
	skill_config: Dictionary
) -> void:
	var orb_scale: float = maxf(
		float(skill_config.get("orb_visual_scale", 1.18)),
		0.1
	)
	var orb_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
		"%s/effect5" % hero.STAGE6_FRAME_DIR,
		"hit_effect",
		1,
		9,
		18.0,
		true,
		start_position,
		Vector2(orb_scale * 0.82, orb_scale * 0.82)
	)
	if not is_instance_valid(orb_fx):
		return

	orb_fx.z_index = 12
	orb_fx.modulate = Color(1.0, 0.45, 0.45, 1.0)

	var pickup_duration: float = maxf(
		float(skill_config.get("orb_pickup_duration", 0.55)),
		0.08
	)
	var destination: Vector2 = hero.global_position + Vector2(0.0, -12.0)

	var orb_tween := orb_fx.create_tween()
	orb_tween.set_parallel(false)

	orb_tween.tween_property(
		orb_fx,
		"scale",
		Vector2(orb_scale * 1.12, orb_scale * 1.12),
		0.08
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	orb_tween.tween_property(
		orb_fx,
		"global_position",
		destination,
		pickup_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	orb_tween.parallel().tween_property(
		orb_fx,
		"scale",
		Vector2(0.18, 0.18),
		pickup_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	orb_tween.parallel().tween_property(
		orb_fx,
		"modulate:a",
		0.78,
		pickup_duration * 0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	orb_tween.finished.connect(
		Callable(hero, "_finish_berserker_blood_orb").bind(
			orb_fx,
			maxi(int(skill_config.get("heal_per_orb", 70)), 1)
		),
		Object.CONNECT_ONE_SHOT
	)


func _finish_berserker_blood_orb(
	orb_fx: AnimatedSprite2D,
	heal_amount: int
) -> void:
	if is_instance_valid(orb_fx):
		hero._recycle_archmage_fx(orb_fx)
	if hero.current_hp > 0 and not hero.is_dying:
		hero.heal_direct(heal_amount)


func _start_berserker_skill4() -> void:
	if hero.silence_timer > 0.0:
		return
	var skill_config_value = hero.berserker_config.get("skill_4", {})
	if typeof(skill_config_value) != TYPE_DICTIONARY:
		return
	var skill_config: Dictionary = skill_config_value
	if skill_config.is_empty():
		return

	var hp_cost_ratio: float = clampf(
		float(skill_config.get("hp_cost_ratio", 0.04)),
		0.0,
		0.95
	)
	_pay_berserker_skill_hp_cost(hp_cost_ratio)

	hero.berserker_skill4_cooldown = _get_berserker_skill_cooldown(
		skill_config,
		8.0
	)
	hero.berserker_skill_global_cooldown = maxf(
		hero.berserker_skill_global_cooldown,
		1.15
	)
	hero.attack_timer = maxf(hero.attack_timer, 0.72)
	hero.attack_pose_timer = 0.72
	hero._restart_stage1_animation("attack")
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_skill4_audio)

	var radius: float = maxf(
		float(skill_config.get("radius", 245.0)),
		1.0
	)
	var damage: int = maxi(
		int(round(
			float(_get_berserker_effective_attack_damage())
			* float(skill_config.get("damage_ratio", 0.65))
		)),
		1
	)
	var knockback_distance: float = maxf(
		float(skill_config.get("knockback_distance", 150.0)),
		0.0
	)
	var effect_scale: float = maxf(
		float(skill_config.get("effect_scale", 1.05)),
		0.1
	)

	var spin_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
		"%s/effect8" % hero.STAGE6_FRAME_DIR,
		"spin_slash",
		1,
		10,
		22.0,
		false,
		hero.global_position,
		Vector2(effect_scale, effect_scale)
	)
	if is_instance_valid(spin_fx):
		spin_fx.z_index = 8

	var radius_sq: float = radius * radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.berserker_query_candidates
	)
	for node in hero.berserker_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue
		if (
			hero.global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "melee", hero)
		_berserker_blood_art_eighth_heal_on_hit()

		if (
			is_instance_valid(monster)
			and knockback_distance > 0.0
		):
			var knockback_direction: Vector2 = hero.global_position.direction_to(
				monster.global_position
			)
			if knockback_direction.length_squared() <= 0.0:
				knockback_direction = Vector2.RIGHT
			var knockback_target: Vector2 = (
				monster.global_position
				+ knockback_direction.normalized() * knockback_distance
			)
			monster.global_position = Vector2(
				clampf(
					knockback_target.x,
					hero.FIELD_MARGIN,
					hero.battlefield_size.x - hero.FIELD_MARGIN
				),
				clampf(
					knockback_target.y,
					hero.FIELD_MARGIN,
					hero.battlefield_size.y - hero.FIELD_MARGIN
				)
			)
			hero.LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()
	hero.berserker_query_candidates.clear()

	hero.queue_redraw()


func notify_berserker_skill_kill() -> void:
	if hero.berserker_madness_active:
		if (
			hero.berserker_killing_urge_bonus > 0.0
			and int(
				hero.build_counts.get(
					"berserker_different_dream",
					0
				)
			) <= 0
		):
			var gauge_max: float = maxf(
				float(hero.berserker_config.get("gauge_max", 100.0)),
				1.0
			)
			hero.ultimate_charge = minf(
				hero.ultimate_charge + hero.berserker_killing_urge_bonus,
				gauge_max
			)
			hero.queue_redraw()
		return

	_add_berserker_gauge(
		maxf(
			float(hero.berserker_config.get("gauge_per_kill", 1.0)),
			0.0
		)
	)


func _update_berserker_pose_visual(delta: float) -> void:
	if (
		hero.hero_archetype != "berserker_madness"
		or not hero.hero_sprite.visible
		or hero.is_dying
		or hero.berserker_reviving
	):
		return
	if hero.hit_pose_timer > 0.0 or hero.attack_pose_timer > 0.0:
		return

	hero._update_facing_from_horizontal(hero.velocity.x, delta)
	if hero.velocity.length() > 4.0:
		hero._play_stage1_animation("move", 1.0)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _get_berserker_effective_attack_damage() -> int:
	if hero.max_hp <= 0:
		return maxi(hero.attack_damage, 1)

	var missing_ratio: float = clampf(
		float(hero.max_hp - hero.current_hp) / float(hero.max_hp),
		0.0,
		1.0
	)
	var missing_percent: float = missing_ratio * 100.0
	var bonus_per_percent: float = maxf(
		float(
			hero.berserker_config.get(
				"missing_hp_attack_bonus_per_percent",
				0.02
			)
		),
		0.0
	)
	if hero.berserker_missing_hp_bonus_override >= 0.0:
		bonus_per_percent = hero.berserker_missing_hp_bonus_override
	var passive_bonus: float = (
		hero.base_attack_damage_for_level_growth
		* missing_percent
		* bonus_per_percent
	)
	return maxi(
		int(round(float(hero.attack_damage) + passive_bonus)),
		1
	)


func _berserker_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return

	var direction: Vector2 = hero.global_position.direction_to(
		current_target.global_position
	)
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	direction = direction.normalized()

	if hero.berserker_madness_active:
		var blink_target: Node2D = _find_berserker_madness_target()
		if is_instance_valid(blink_target):
			_berserker_madness_blink_to(blink_target)
			direction = hero.global_position.direction_to(
				blink_target.global_position
			)
			if direction.length_squared() <= 0.0:
				direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
			direction = direction.normalized()

	var attack_interval: float = hero._get_common_attack_interval(
		hero.attack_cooldown
	)
	if hero.berserker_madness_active:
		var madness_speed_multiplier: float = maxf(
			float(
				hero.berserker_config.get(
					"madness_attack_speed_multiplier",
					1.50
				)
			),
			0.1
		)
		var different_dream_stacks: int = int(
			hero.build_counts.get(
				"berserker_different_dream",
				0
			)
		)
		if different_dream_stacks > 0:
			madness_speed_multiplier = (
				1.0 + 0.40 * float(different_dream_stacks)
			)
		attack_interval /= madness_speed_multiplier
	hero.attack_timer = maxf(attack_interval, 0.06)
	hero.attack_pose_timer = 0.52
	hero._face_attack_direction(direction.x)
	hero._restart_stage1_animation("attack")
	_play_berserker_basic_audio()

	if hero.berserker_madness_active:
		var slash_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
			"%s/effect1" % hero.STAGE6_FRAME_DIR,
			"basic_slash",
			1,
			13,
			24.0,
			false,
			hero.global_position + direction * 82.0,
			Vector2(1.08, 1.08)
		)
		if is_instance_valid(slash_fx):
			slash_fx.flip_h = direction.x < 0.0
			slash_fx.rotation = direction.angle() if direction.x >= 0.0 else direction.angle() - PI
			slash_fx.z_index = 8

	var reach: float = maxf(
		float(hero.berserker_config.get("basic_reach", 190.0)),
		1.0
	)
	var half_width: float = maxf(
		float(hero.berserker_config.get("basic_half_width", 118.0)),
		1.0
	)
	var damage: int = _get_berserker_effective_attack_damage()
	var side: Vector2 = Vector2(-direction.y, direction.x)
	hero._fill_monster_nodes_near(
		hero.global_position,
		reach + half_width,
		hero.berserker_query_candidates
	)

	for node in hero.berserker_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null or not monster.has_method("take_damage"):
			continue

		var offset: Vector2 = monster.global_position - hero.global_position
		var forward: float = offset.dot(direction)
		var lateral: float = absf(offset.dot(side))
		if forward < -32.0 or forward > reach or lateral > half_width:
			continue

		var hp_before_value = monster.get("current_hp")
		var hp_before: int = (
			int(hp_before_value)
			if hp_before_value != null
			else -1
		)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, damage, "melee", hero)

		if hp_before <= 0:
			continue
		var killed: bool = false
		if not is_instance_valid(monster):
			killed = true
		else:
			var hp_after_value = monster.get("current_hp")
			if hp_after_value != null and int(hp_after_value) <= 0:
				killed = true
		if killed:
			notify_berserker_skill_kill()
	hero.berserker_query_candidates.clear()

	hero._damage_treasure_chests(
		hero.global_position + direction * (reach * 0.55),
		maxf(half_width, 80.0),
		damage
	)


func _add_berserker_gauge(amount: float) -> void:
	if (
		amount <= 0.0
		or hero.hero_archetype != "berserker_madness"
		or hero.berserker_madness_active
		or int(
			hero.build_counts.get(
				"berserker_different_dream",
				0
			)
		) > 0
	):
		return
	var gauge_max: float = maxf(
		float(hero.berserker_config.get("gauge_max", 100.0)),
		1.0
	)
	hero.ultimate_charge = minf(hero.ultimate_charge + amount, gauge_max)
	if hero.ultimate_charge + 0.001 >= gauge_max:
		_start_berserker_madness()
	hero.queue_redraw()


func _start_berserker_madness() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.berserker_madness_active or hero.berserker_reviving or hero.is_dying:
		return
	hero.berserker_madness_active = true
	_ensure_berserker_audio_runtime()
	_play_berserker_player(hero.berserker_madness_roar_audio)
	var gauge_max: float = maxf(
		float(hero.berserker_config.get("gauge_max", 100.0)),
		1.0
	)
	hero.ultimate_charge = gauge_max
	if hero.channel_effect.sprite_frames != null:
		hero.channel_effect.visible = true
		hero.channel_effect.play(&"madness")
	hero.queue_redraw()


func _end_berserker_madness() -> void:
	hero.berserker_madness_active = false
	hero.ultimate_charge = 0.0
	if (
		hero.channel_effect.sprite_frames != null
		and hero.channel_effect.animation == &"madness"
	):
		hero.channel_effect.visible = false
	hero.queue_redraw()


func _update_berserker_madness(delta: float) -> void:
	if hero.hero_archetype != "berserker_madness":
		return
	if not hero.berserker_madness_active:
		return

	if int(
		hero.build_counts.get(
			"berserker_different_dream",
			0
		)
	) > 0:
		hero.ultimate_charge = maxf(
			float(hero.berserker_config.get("gauge_max", 100.0)),
			1.0
		)
		hero.queue_redraw()
		return

	var drain_per_second: float = maxf(
		float(
			hero.berserker_config.get(
				"madness_drain_per_second",
				10.0
			)
		),
		0.0
	)
	hero.ultimate_charge = maxf(
		hero.ultimate_charge - drain_per_second * delta,
		0.0
	)
	if hero.ultimate_charge <= 0.001:
		_end_berserker_madness()
	else:
		hero.queue_redraw()


func _find_berserker_madness_target() -> Node2D:
	var radius: float = maxf(
		float(hero.berserker_config.get("madness_target_radius", 375.0)),
		1.0
	)
	var radius_sq: float = radius * radius
	var farthest: Node2D = null
	var farthest_distance_sq: float = -1.0
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.berserker_query_candidates
	)
	for node in hero.berserker_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var distance_sq: float = hero.global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > radius_sq or distance_sq <= farthest_distance_sq:
			continue
		farthest = monster
		farthest_distance_sq = distance_sq
	hero.berserker_query_candidates.clear()
	return farthest


func _berserker_madness_blink_to(blink_target: Node2D) -> void:
	if not is_instance_valid(blink_target):
		return

	var start_position: Vector2 = hero.global_position
	var direction: Vector2 = start_position.direction_to(
		blink_target.global_position
	)
	if direction.length_squared() <= 0.0:
		return

	var stop_distance: float = 48.0
	var destination: Vector2 = (
		blink_target.global_position
		- direction.normalized() * stop_distance
	)
	destination = Vector2(
		clampf(
			destination.x,
			hero.FIELD_MARGIN,
			hero.battlefield_size.x - hero.FIELD_MARGIN
		),
		clampf(
			destination.y,
			hero.FIELD_MARGIN,
			hero.battlefield_size.y - hero.FIELD_MARGIN
		)
	)

	_spawn_berserker_blood_dash_trail(
		start_position,
		destination
	)
	hero.global_position = destination
	hero.velocity = Vector2.ZERO


func _spawn_berserker_blood_dash_trail(
	start_position: Vector2,
	end_position: Vector2
) -> void:
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return

	var parent_2d := parent as Node2D
	var trail: Line2D = null
	if parent.has_method("acquire_transient_fx"):
		trail = parent.call(
			"acquire_transient_fx",
			"berserker_blood_dash_trail",
			"line"
		) as Line2D
	if trail == null:
		trail = Line2D.new()
		parent.add_child(trail)

	trail.clear_points()
	trail.visible = true
	trail.modulate = Color.WHITE
	trail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trail.z_index = 6
	trail.width = 30.0
	trail.default_color = Color(0.82, 0.05, 0.03, 0.82)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.joint_mode = Line2D.LINE_JOINT_ROUND

	if parent_2d != null:
		trail.add_point(parent_2d.to_local(start_position))
		trail.add_point(parent_2d.to_local(end_position))
	else:
		trail.add_point(start_position)
		trail.add_point(end_position)

	var trail_tween := trail.create_tween()
	trail_tween.set_parallel(true)
	trail_tween.tween_property(
		trail,
		"modulate:a",
		0.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	trail_tween.tween_property(
		trail,
		"width",
		6.0,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if parent.has_method("recycle_transient_fx"):
		trail_tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				trail,
				"berserker_blood_dash_trail"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		trail_tween.finished.connect(
			Callable(trail, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)

	var segment: Vector2 = end_position - start_position
	var segment_length: float = segment.length()
	if segment_length <= 1.0:
		return

	var effect_count: int = clampi(
		int(ceil(segment_length / 68.0)) + 1,
		3,
		8
	)
	var effect_direction: Vector2 = segment.normalized()
	for index in range(effect_count):
		var progress: float = (
			float(index)
			/ float(maxi(effect_count - 1, 1))
		)
		var effect_position: Vector2 = start_position.lerp(
			end_position,
			progress
		)
		var blood_fx: AnimatedSprite2D = hero._spawn_archmage_fx(
			"%s/effect2" % hero.STAGE6_FRAME_DIR,
			"blood_effect",
			1,
			10,
			28.0,
			false,
			effect_position,
			Vector2(0.82, 0.82)
		)
		if not is_instance_valid(blood_fx):
			continue
		blood_fx.rotation = effect_direction.angle()
		blood_fx.modulate = Color(1.0, 0.72, 0.72, 0.92)
		blood_fx.z_index = 7
		var fade_tween := blood_fx.create_tween()
		fade_tween.tween_property(
			blood_fx,
			"modulate:a",
			0.0,
			0.30
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_berserker_hp_visual() -> void:
	if hero.hero_archetype != "berserker_madness" or not hero.hero_sprite.visible:
		return
	var hp_ratio: float = clampf(
		float(hero.current_hp) / float(maxi(hero.max_hp, 1)),
		0.0,
		1.0
	)
	var missing_ratio: float = 1.0 - hp_ratio
	hero.hero_sprite.modulate = Color(
		1.0,
		lerpf(1.0, 0.36, missing_ratio),
		lerpf(1.0, 0.36, missing_ratio),
		1.0
	)


func _begin_berserker_revive() -> void:
	if hero.berserker_revive_used or hero.berserker_reviving:
		return

	hero.berserker_revive_used = true
	hero.berserker_reviving = true
	hero.berserker_saved_collision_layer = hero.collision_layer
	hero.berserker_saved_collision_mask = hero.collision_mask
	hero.collision_layer = 0
	hero.collision_mask = 0
	hero.velocity = Vector2.ZERO
	hero.invulnerability_timer = 0.0
	hero.modulate.a = 0.45
	hero._restart_stage1_animation("death", 0.72)
	hero.queue_redraw()

	var revive_delay: float = maxf(
		float(hero.berserker_config.get("revive_delay", 3.0)),
		0.1
	)
	if hero.player_controlled and hero.player_weapons != null and hero.player_weapons.identity != null:
		hero.player_weapons.identity.revive_left = revive_delay
		return
	await hero.COMBAT_DELAY.wait(hero,revive_delay)
	if not hero.is_inside_tree() or hero.is_dying:
		return
	_finish_berserker_revive()


func _finish_berserker_revive() -> void:

	var revive_ratio: float = clampf(
		float(hero.berserker_config.get("revive_hp_ratio", 0.50)),
		0.01,
		1.0
	)
	hero.current_hp = maxi(int(round(float(hero.max_hp) * revive_ratio)), 1)
	hero.collision_layer = hero.berserker_saved_collision_layer
	hero.collision_mask = hero.berserker_saved_collision_mask
	hero.berserker_reviving = false
	hero.modulate.a = 1.0
	hero.hit_pose_timer = 0.0
	hero.attack_pose_timer = 0.0
	hero._restart_stage1_animation("idle")
	_update_berserker_hp_visual()
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	hero.queue_redraw()
