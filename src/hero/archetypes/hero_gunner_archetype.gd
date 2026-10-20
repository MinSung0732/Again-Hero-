extends RefCounted
## Gunner archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _physics_process_gunner(delta: float) -> void:
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
	hero.gunner_backstep_cooldown = maxf(hero.gunner_backstep_cooldown - delta, 0.0)
	hero.gunner_cylinder_cooldown = maxf(hero.gunner_cylinder_cooldown - delta, 0.0)
	hero.gunner_cylinder_decision_timer = maxf(hero.gunner_cylinder_decision_timer - delta, 0.0)
	hero.gunner_deadeye_cooldown = maxf(hero.gunner_deadeye_cooldown - delta, 0.0)
	hero._update_invulnerability(delta)
	_update_gunner_collision_ignore(delta)

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0

	if hero.gunner_deadeye_active:
		_update_gunner_deadeye(delta)
		_update_gunner_pose_visual(delta)
		return

	if hero.gunner_reloading:
		hero.gunner_reload_timer = maxf(hero.gunner_reload_timer - delta, 0.0)
		hero.gunner_reload_redraw_timer = maxf(
			hero.gunner_reload_redraw_timer - delta,
			0.0
		)
		if hero.gunner_reload_redraw_timer <= 0.0:
			hero.gunner_reload_redraw_timer = 0.08
			hero.queue_redraw()
		if hero.gunner_cylinder_decision_timer <= 0.0:
			hero.gunner_cylinder_decision_timer = 0.35
			if _gunner_should_use_cylinder():
				_use_gunner_cylinder_strike()
		if hero.gunner_reload_timer <= 0.0:
			_finish_gunner_reload()

	hero._update_heal_item_goal(delta)
	hero._update_chest_goal(delta)
	hero._update_magnet_item_goal(delta)
	if not is_instance_valid(hero.target) or hero.target.is_queued_for_deletion() or hero.retarget_timer <= 0.0:
		hero.target = hero._find_nearest_monster()
		hero.retarget_timer = 0.10

	if not is_instance_valid(hero.target):
		hero._move_without_monsters()
		_update_gunner_pose_visual(delta)
		return

	var distance := hero.global_position.distance_to(hero.target.global_position)
	var move_direction := hero._choose_move_direction(hero.target, distance)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)
	move_direction = _apply_gunner_boundary_steering(move_direction)
	var gunner_speed_scale := 1.0 + (hero.gunner_reload_move_speed_bonus if hero.gunner_reloading else 0.0)
	hero._execute_ai_movement(move_direction * hero.move_speed * hero._get_effective_move_multiplier() * gunner_speed_scale)

	if _gunner_should_start_deadeye():
		_start_gunner_deadeye()
		return

	if not hero.gunner_reloading and distance <= hero.attack_range and hero.attack_timer <= 0.0:
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.GUNNER, hero.target)

	_update_gunner_pose_visual(delta)


func _update_gunner_pose_visual(delta: float) -> void:
	if hero.hero_archetype != "pistol_gunner" or not hero.hero_sprite.visible or hero.is_dying:
		return
	if hero.hit_pose_timer > 0.0:
		return
	# 공격 중에는 발사 방향을 유지한다. 그 외에는 실제 이동 방향을 따른다.
	if hero.attack_pose_timer > 0.0:
		return

	hero._update_facing_from_horizontal(hero.velocity.x, delta)
	var speed := hero.velocity.length()
	if speed > 4.0:
		var movement_ratio := speed / maxf(hero.move_speed, 1.0)
		var animation_speed := clampf(movement_ratio, 0.78, 1.45)
		hero._play_stage1_animation("move", animation_speed)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _apply_gunner_boundary_steering(base_direction: Vector2) -> Vector2:
	return hero._apply_ranged_boundary_escape(base_direction, 360.0, 155.0)


func _gunner_attack(current_target: Node2D) -> void:
	if hero.gunner_reloading or hero.gunner_ammo <= 0 or not is_instance_valid(current_target):
		return
	var direction := hero.global_position.direction_to(current_target.global_position).normalized()
	if direction.length_squared() <= 0.0:
		direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	hero.gunner_ammo -= 1
	_gunner_register_ammo_consumed(1)
	if hero.gunner_ammo <= 0:
		_refresh_gunner_empty_magazine_shield()
	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.30
	hero._face_attack_direction(direction.x)
	hero._restart_stage1_animation("attack", 1.0)
	_play_gunner_basic_shot_audio()
	_spawn_gunner_bullet(direction)
	var random_angle := deg_to_rad(randf_range(-float(hero.gunner_config.get("random_shot_angle_degrees", 28.0)), float(hero.gunner_config.get("random_shot_angle_degrees", 28.0))))
	_spawn_gunner_bullet(direction.rotated(random_angle))
	if randf() <= clampf(float(hero.gunner_config.get("quickdraw_chance", 0.03)), 0.0, 1.0):
		hero.gunner_ammo = hero.gunner_magazine_size
		hero.gunner_reloading = false
	elif hero.gunner_ammo <= 0:
		_start_gunner_reload()
	hero.queue_redraw()


func _spawn_gunner_bullet(direction: Vector2, is_deadeye_shot: bool = false) -> void:
	var headshot := randf() <= clampf(float(hero.gunner_config.get("headshot_chance", 0.10)), 0.0, 1.0)
	var damage := maxi(
		1,
		int(round(float(hero.attack_damage) * _gunner_powder_damage_multiplier()))
	)
	if headshot:
		damage = maxi(1, int(round(float(damage) * float(hero.gunner_config.get("headshot_multiplier", 1.20)))))
	var projectile := hero._acquire_projectile(
		hero.GUNNER_PROJECTILE_SCENE,
		"gunner_projectile"
	)
	if projectile == null:
		return
	projectile.global_position = hero.global_position + direction.normalized() * 42.0
	projectile.call(
		"setup",
		direction,
		damage,
		hero.projectile_speed,
		hero.attack_range,
		headshot,
		hero.gunner_ricochet_stacks,
		is_deadeye_shot
	)


func _spawn_gunner_bullet_from(origin: Vector2, direction: Vector2) -> void:
	var headshot := randf() <= clampf(float(hero.gunner_config.get("headshot_chance", 0.10)), 0.0, 1.0)
	var damage := maxi(
		1,
		int(round(float(hero.attack_damage) * _gunner_powder_damage_multiplier()))
	)
	if headshot:
		damage = maxi(1, int(round(float(damage) * float(hero.gunner_config.get("headshot_multiplier", 1.20)))))
	var projectile := hero._acquire_projectile(
		hero.GUNNER_PROJECTILE_SCENE,
		"gunner_projectile"
	)
	if projectile == null:
		return
	projectile.global_position = origin + direction.normalized() * 42.0
	projectile.call(
		"setup",
		direction,
		damage,
		hero.projectile_speed,
		hero.attack_range,
		headshot,
		hero.gunner_ricochet_stacks,
		false
	)


func _refresh_gunner_empty_magazine_shield() -> void:
	var shield_ratio := clampf(
		float(hero.gunner_config.get("empty_mag_shield_ratio", 0.10)),
		0.0,
		1.0
	)
	var refreshed_shield := float(hero.max_hp) * shield_ratio
	if refreshed_shield <= 0.0:
		return

	# 갱신형: 기존 실드에 더하지 않고 항상 새 10% 값으로 덮어쓴다.
	hero.shield_max_hp = hero._player_shield_amount(refreshed_shield)
	hero.shield_hp = hero.shield_max_hp
	hero.queue_redraw()


func _gunner_register_ammo_consumed(amount: int) -> void:
	if amount <= 0 or hero.gunner_powder_bonus_per_ammo <= 0.0:
		return
	hero.gunner_powder_consumed_stacks += amount


func _gunner_powder_damage_multiplier() -> float:
	if hero.gunner_powder_bonus_per_ammo <= 0.0 or hero.gunner_powder_consumed_stacks <= 0:
		return 1.0
	return 1.0 + hero.gunner_powder_bonus_per_ammo * float(hero.gunner_powder_consumed_stacks)


func _start_gunner_reload() -> void:
	_play_gunner_reload_audio()
	hero.gunner_powder_consumed_stacks = 0
	hero.gunner_reloading = true
	hero.gunner_reload_timer = maxf(float(hero.gunner_config.get("reload_seconds", 2.4)), 0.1)
	hero.gunner_reload_redraw_timer = 0.0
	hero.attack_timer = maxf(hero.attack_timer, hero.gunner_reload_timer)
	hero.queue_redraw()


func _finish_gunner_reload() -> void:
	hero.gunner_reloading = false
	hero.gunner_reload_timer = 0.0
	hero.gunner_reload_redraw_timer = 0.0
	hero.gunner_ammo = hero.gunner_magazine_size
	hero.attack_timer = 0.05
	hero.queue_redraw()


func _gunner_surround_pressure() -> float:
	var radius := maxf(float(hero.gunner_config.get("surrounded_radius", 220.0)), 1.0)
	var required := maxi(int(hero.gunner_config.get("surrounded_enemy_count", 4)), 1)
	var nearby := hero._count_monsters_near(hero.global_position, radius)
	return clampf(float(nearby) / float(required), 0.0, 1.5)


func _gunner_should_backstep_on_hit() -> bool:
	if hero.gunner_backstep_cooldown > 0.0:
		return false
	var pressure := _gunner_surround_pressure()
	var base_chance := clampf(float(hero.gunner_config.get("backstep_base_chance", 0.30)), 0.0, 1.0)
	var surround_bonus := maxf(float(hero.gunner_config.get("surrounded_backstep_bonus", 0.55)), 0.0)
	var chance := base_chance + minf(pressure, 1.0) * surround_bonus
	var hp_ratio := float(hero.current_hp) / float(maxi(hero.max_hp, 1))
	if hp_ratio <= 0.40:
		chance += hero.gunner_low_hp_backstep_bonus
	chance = clampf(chance, 0.0, 1.0)
	return randf() <= chance


func _gunner_should_use_cylinder() -> bool:
	if not hero.gunner_reloading or hero.gunner_cylinder_cooldown > 0.0:
		return false
	var nearby := hero._count_monsters_near(
		hero.global_position,
		maxf(float(hero.gunner_config.get("cylinder_radius", 190.0)), 1.0)
	)
	var base_required := maxi(int(hero.gunner_config.get("cylinder_base_enemy_count", 2)), 1)
	var surrounded_required := maxi(
		int(hero.gunner_config.get("cylinder_surrounded_enemy_count", 4)),
		base_required
	)
	if nearby >= surrounded_required:
		return true
	if nearby < base_required:
		return false
	# 포위 상태에 가까울수록 장전 중 방어 행동의 우선도가 올라간다.
	var weight := clampf(
		float(nearby - base_required + 1)
		/ float(maxi(surrounded_required - base_required + 1, 1)),
		0.0,
		1.0
	)
	return randf() <= 0.30 + weight * 0.45


func _start_gunner_backstep() -> void:
	_play_gunner_backstep_audio()
	hero.gunner_backstep_cooldown = maxf(float(hero.gunner_config.get("backstep_cooldown", 7.0)), 0.1)
	hero.invulnerability_timer = maxf(hero.invulnerability_timer, float(hero.gunner_config.get("backstep_invulnerability", 0.75)))
	var escape_direction := _find_gunner_escape_direction()
	var start_position := hero.global_position
	var distance := maxf(float(hero.gunner_config.get("backstep_distance", 260.0)), 0.0)
	_spawn_gunner_afterimage(start_position, 0.95, 0.66, 1.12)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.25, 0.84, 0.58, 1.10)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.50, 0.72, 0.50, 1.08)
	_spawn_gunner_afterimage(start_position + escape_direction * distance * 0.75, 0.60, 0.44, 1.06)
	if hero.gunner_afterimage_shot_stacks > 0:
		var counter_direction := -escape_direction
		for shot_index in range(hero.gunner_afterimage_shot_stacks * 2):
			var spread := deg_to_rad(randf_range(-10.0, 10.0))
			_spawn_gunner_bullet_from(start_position, counter_direction.rotated(spread))
	hero.global_position += escape_direction * distance
	hero._clamp_to_battlefield()
	if hero.gunner_saved_collision_mask < 0:
		hero.gunner_saved_collision_mask = hero.collision_mask
	hero.collision_mask = 0
	hero.gunner_collision_ignore_timer = 0.22


func _spawn_gunner_afterimage(
	world_position: Vector2,
	alpha: float,
	fade_time: float,
	scale_multiplier: float = 1.0
) -> void:
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
			"gunner_afterimage",
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
	ghost.scale = hero.hero_sprite.scale * maxf(scale_multiplier, 1.0)
	ghost.rotation = hero.hero_sprite.rotation
	ghost.global_position = world_position
	ghost.z_index = hero.hero_sprite.z_index
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.82, 0.94, 1.0, clampf(alpha, 0.08, 0.95))

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, maxf(fade_time, 0.05))
	tween.tween_property(
		ghost,
		"scale",
		ghost.scale * 1.04,
		maxf(fade_time, 0.05)
	)
	if parent.has_method("recycle_transient_fx"):
		tween.finished.connect(
			Callable(parent, "recycle_transient_fx").bind(
				ghost,
				"gunner_afterimage"
			),
			Object.CONNECT_ONE_SHOT
		)
	else:
		tween.finished.connect(
			Callable(ghost, "queue_free"),
			Object.CONNECT_ONE_SHOT
		)


func _find_gunner_escape_direction() -> Vector2:
	var best := Vector2.RIGHT
	var best_score := INF
	var sample_count := 32
	var dash_distance := maxf(float(hero.gunner_config.get("backstep_distance", 260.0)), 1.0)
	var threat_radius := maxf(dash_distance + 360.0, 560.0)
	var repulsion := Vector2.ZERO
	hero.gunner_escape_monster_positions.clear()
	hero._fill_monster_nodes_near(
		hero.global_position,
		threat_radius,
		hero.gunner_query_candidates
	)

	for node in hero.gunner_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue

		var monster_position := monster.global_position
		hero.gunner_escape_monster_positions.append(monster_position)

		var offset := monster_position - hero.global_position
		var distance := offset.length()
		if distance <= 0.001 or distance > threat_radius:
			continue
		var proximity := 1.0 - clampf(distance / threat_radius, 0.0, 1.0)
		repulsion -= offset.normalized() * (0.35 + proximity * proximity * 2.65)

	hero.gunner_query_candidates.clear()
	var preferred_away := (
		repulsion.normalized()
		if repulsion.length_squared() > 0.001
		else Vector2.ZERO
	)

	for i in range(sample_count):
		var dir := Vector2.from_angle(TAU * float(i) / float(sample_count))
		var raw_endpoint := hero.global_position + dir * dash_distance
		var endpoint := Vector2(
			clampf(raw_endpoint.x, hero.FIELD_MARGIN, hero.battlefield_size.x - hero.FIELD_MARGIN),
			clampf(raw_endpoint.y, hero.FIELD_MARGIN, hero.battlefield_size.y - hero.FIELD_MARGIN)
		)
		var actual_dash_distance := hero.global_position.distance_to(endpoint)
		if actual_dash_distance <= 1.0:
			continue

		var endpoint_danger := 0.0
		var endpoint_close_count := 0
		var endpoint_near_count := 0
		var corridor_density := 0.0
		var corridor_count := 0
		var side := Vector2(-dir.y, dir.x)
		var danger_radius := 320.0

		for monster_position in hero.gunner_escape_monster_positions:
			var endpoint_distance := endpoint.distance_to(monster_position)
			if endpoint_distance < danger_radius:
				endpoint_danger += 1.0 - clampf(
					endpoint_distance / danger_radius,
					0.0,
					1.0
				)
			if endpoint_distance <= 115.0:
				endpoint_close_count += 1
			if endpoint_distance <= 220.0:
				endpoint_near_count += 1

			var offset := monster_position - hero.global_position
			var forward := offset.dot(dir)
			if forward <= 0.0 or forward > actual_dash_distance + 120.0:
				continue
			var lateral := absf(offset.dot(side))
			if lateral > 185.0:
				continue

			corridor_count += 1
			var forward_weight := 1.0 - clampf(
				forward / maxf(actual_dash_distance + 120.0, 1.0),
				0.0,
				1.0
			) * 0.35
			var center_weight := 1.0 - clampf(lateral / 185.0, 0.0, 1.0) * 0.60
			corridor_density += maxf(forward_weight * center_weight, 0.15)

		var boundary_loss := clampf(
			(dash_distance - actual_dash_distance) / dash_distance,
			0.0,
			1.0
		)
		var away_alignment_penalty := 0.0
		if preferred_away.length_squared() > 0.001:
			away_alignment_penalty = (1.0 - dir.dot(preferred_away)) * 7.0

		var score := (
			float(endpoint_close_count) * 90.0
			+ float(endpoint_near_count) * 16.0
			+ float(corridor_count) * 11.0
			+ corridor_density * 13.0
			+ endpoint_danger * 18.0
			+ away_alignment_penalty
			+ boundary_loss * 28.0
		)
		if score < best_score:
			best_score = score
			best = hero.global_position.direction_to(endpoint)

	return best.normalized()


func _update_gunner_collision_ignore(delta: float) -> void:
	if hero.gunner_collision_ignore_timer <= 0.0:
		return
	hero.gunner_collision_ignore_timer = maxf(hero.gunner_collision_ignore_timer - delta, 0.0)
	if hero.gunner_collision_ignore_timer <= 0.0 and hero.gunner_saved_collision_mask >= 0:
		hero.collision_mask = hero.gunner_saved_collision_mask
		hero.gunner_saved_collision_mask = -1


func _use_gunner_cylinder_strike() -> void:
	_play_gunner_cylinder_audio()
	hero.gunner_cylinder_cooldown = maxf(float(hero.gunner_config.get("cylinder_cooldown", 10.0)), 0.1)
	_play_gunner_cylinder_dust()
	var radius := maxf(float(hero.gunner_config.get("cylinder_radius", 190.0)), 1.0)
	var knockback := maxf(float(hero.gunner_config.get("cylinder_knockback", 145.0)), 0.0)
	var slow_multiplier := clampf(float(hero.gunner_config.get("cylinder_slow_multiplier", 0.50)), 0.1, 1.0)
	var slow_duration := maxf(float(hero.gunner_config.get("cylinder_slow_duration", 2.0)), 0.1)
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero.gunner_query_candidates
	)
	for node in hero.gunner_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or hero.global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		var dir := hero.global_position.direction_to(monster.global_position)
		if dir.length_squared() <= 0.0:
			dir = Vector2.RIGHT
		monster.global_position += dir.normalized() * knockback
		hero.LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
		var damage_ratio := maxf(float(hero.gunner_config.get("cylinder_damage_ratio", 0.0)), 0.0)
		if damage_ratio > 0.0 and monster.has_method("take_damage"):
			preload("res://src/systems/monster_hit_context.gd").hit(monster, maxi(1, int(round(float(hero.attack_damage) * damage_ratio))), "ranged", hero)
		monster.set_meta("gunner_slow_multiplier", slow_multiplier)
		monster.set_meta("gunner_slow_until", hero.COMBAT_DELAY.now_msec(hero) + int(slow_duration * 1000.0))
	hero.gunner_query_candidates.clear()


func _update_gunner_deadeye_aim_analysis() -> void:
	var sample_count := maxi(
		int(hero.gunner_config.get("deadeye_cluster_samples", 36)),
		8
	)
	var max_range := maxf(
		float(hero.gunner_config.get("deadeye_cluster_range", 620.0)),
		1.0
	)
	var half_width := maxf(
		float(hero.gunner_config.get("deadeye_corridor_half_width", 105.0)),
		1.0
	)
	var best_direction := (
		Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	)
	var best_score := 0.0
	var best_hits := 0
	hero.gunner_deadeye_monster_offsets.clear()

	for node in hero._get_monster_nodes_cached():
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var hp_value = monster.get("current_hp")
		if hp_value != null and int(hp_value) <= 0:
			continue
		var offset := monster.global_position - hero.global_position
		if offset.length_squared() <= max_range * max_range:
			hero.gunner_deadeye_monster_offsets.append(offset)

	for index in range(sample_count):
		var direction := Vector2.from_angle(
			TAU * float(index) / float(sample_count)
		)
		var side := Vector2(-direction.y, direction.x)
		var score := 0.0
		var hits := 0
		for offset in hero.gunner_deadeye_monster_offsets:
			var forward := offset.dot(direction)
			if forward <= 0.0 or forward > max_range:
				continue
			var lateral := absf(offset.dot(side))
			if lateral > half_width:
				continue
			hits += 1
			var distance_weight := (
				1.0
				- clampf(forward / max_range, 0.0, 1.0) * 0.35
			)
			var center_weight := (
				1.0
				- clampf(lateral / half_width, 0.0, 1.0) * 0.45
			)
			score += maxf(distance_weight * center_weight, 0.1)
		if score > best_score:
			best_score = score
			best_hits = hits
			best_direction = direction

	hero.gunner_deadeye_analysis_direction = best_direction.normalized()
	hero.gunner_deadeye_analysis_score = best_score
	hero.gunner_deadeye_analysis_hits = best_hits


func _gunner_should_start_deadeye() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.gunner_reloading or hero.gunner_deadeye_cooldown > 0.0:
		return false
	var min_ammo := maxi(int(hero.gunner_config.get("deadeye_min_ammo", 3)), 1)
	if hero.gunner_ammo < min_ammo:
		return false

	_update_gunner_deadeye_aim_analysis()
	var score := hero.gunner_deadeye_analysis_score
	var min_score := maxf(float(hero.gunner_config.get("deadeye_min_cluster_score", 3.0)), 0.0)
	if score < min_score:
		return false
	var force_score := maxf(float(hero.gunner_config.get("deadeye_force_cluster_score", 5.5)), min_score)
	if score >= force_score:
		return true

	# 밀집도가 높을수록 발동 확률 증가. 최소 문턱에서는 낮게, 강한 밀집에서는 거의 확정.
	var t := clampf((score - min_score) / maxf(force_score - min_score, 0.001), 0.0, 1.0)
	return randf() <= lerpf(0.28, 0.82, t)


func _start_gunner_deadeye() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.gunner_ammo <= 0:
		return
	var aim_direction := hero.gunner_deadeye_analysis_direction
	if aim_direction.length_squared() <= 0.0:
		aim_direction = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	hero.gunner_deadeye_cooldown = maxf(float(hero.gunner_config.get("deadeye_cooldown", 20.0)), 0.1)
	hero.gunner_deadeye_active = true
	_play_gunner_deadeye_start_audio()
	var deadeye_consumed_ammo := hero.gunner_ammo
	hero.gunner_deadeye_shots_left = maxi(
		1,
		int(round(float(deadeye_consumed_ammo) * hero.gunner_deadeye_shot_multiplier))
	)
	_gunner_register_ammo_consumed(deadeye_consumed_ammo)
	hero.gunner_ammo = 0
	_refresh_gunner_empty_magazine_shield()
	hero.gunner_deadeye_shot_timer = 0.0
	hero.gunner_deadeye_direction = aim_direction.normalized()
	hero._face_attack_direction(hero.gunner_deadeye_direction.x)
	hero.queue_redraw()


func _update_gunner_deadeye(delta: float) -> void:
	var speed_bonus := maxf(float(hero.gunner_config.get("deadeye_move_speed_multiplier", 1.30)), 1.0)
	var deadeye_move_direction := _apply_gunner_boundary_steering(hero.gunner_deadeye_direction)
	hero.velocity = deadeye_move_direction * hero.move_speed * hero._get_effective_move_multiplier() * speed_bonus
	hero._move_and_slide_with_obstacle_escape()
	hero._clamp_to_battlefield()
	hero.gunner_deadeye_shot_timer = maxf(hero.gunner_deadeye_shot_timer - delta, 0.0)
	if hero.gunner_deadeye_shot_timer <= 0.0 and hero.gunner_deadeye_shots_left > 0:
		_play_gunner_deadeye_shot_audio()
		_play_gunner_deadeye_flame(hero.gunner_deadeye_direction)
		_spawn_gunner_bullet(hero.gunner_deadeye_direction, true)
		hero.gunner_deadeye_shots_left -= 1
		hero.gunner_deadeye_shot_timer = maxf(float(hero.gunner_config.get("deadeye_shot_interval", 0.08)), 0.03)
	if hero.gunner_deadeye_shots_left <= 0:
		hero.gunner_deadeye_active = false
		_play_gunner_deadeye_smoke(hero.gunner_deadeye_direction)
		_start_gunner_reload()


func _ensure_gunner_audio_runtime() -> void:
	if hero.hero_archetype != "pistol_gunner":
		return

	if hero.gunner_shot_audio_pool.is_empty():
		for index in range(3):
			hero.gunner_shot_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE4_GUNSHOT_AUDIO_PATH, hero.HERO_SFX_DB_PRIMARY_ATTACK - 3.0, 1.0
				)
			)

	if hero.gunner_deadeye_shot_audio_pool.is_empty():
		for index in range(4):
			hero.gunner_deadeye_shot_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE4_DEADEYE_SHOT_AUDIO_PATH, hero.HERO_SFX_DB_HIT - 2.0, 1.0
				)
			)

	if not is_instance_valid(hero.gunner_reload_audio):
		hero.gunner_reload_audio = hero._create_hero_sfx_player(
			hero.STAGE4_RELOAD_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL + 1.0,
			1.0
		)

	if not is_instance_valid(hero.gunner_backstep_audio):
		hero.gunner_backstep_audio = hero._create_hero_sfx_player(
			hero.STAGE4_BACKSTEP_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.12
		)

	if not is_instance_valid(hero.gunner_cylinder_audio):
		hero.gunner_cylinder_audio = hero._create_hero_sfx_player(
			hero.STAGE4_CYLINDER_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 6.0,
			0.78
		)

	if not is_instance_valid(hero.gunner_deadeye_start_audio):
		hero.gunner_deadeye_start_audio = hero._create_hero_sfx_player(
			hero.STAGE4_DEADEYE_START_AUDIO_PATH, hero.HERO_SFX_DB_REGULAR_SKILL - 3.0, 1.0
		)

	if not is_instance_valid(hero.gunner_hit_audio):
		hero.gunner_hit_audio = hero._create_hero_sfx_player(
			hero.STAGE4_HIT_AUDIO_PATH, hero.CONTEXT_AUDIO.HIT_DB, 1.0
		)

	if not is_instance_valid(hero.gunner_death_audio):
		hero.gunner_death_audio = hero._create_hero_sfx_player(
			hero.STAGE4_DEATH_AUDIO_PATH,
			hero.HERO_SFX_DB_DEATH,
			0.92
		)


func _play_gunner_basic_shot_audio() -> void:
	_ensure_gunner_audio_runtime()
	if hero.gunner_shot_audio_pool.is_empty():
		return
	var player := hero.gunner_shot_audio_pool[
		hero.gunner_shot_audio_cursor % hero.gunner_shot_audio_pool.size()
	]
	hero.gunner_shot_audio_cursor = (
		hero.gunner_shot_audio_cursor + 1
	) % hero.gunner_shot_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_gunner_deadeye_shot_audio() -> void:
	_ensure_gunner_audio_runtime()
	if hero.gunner_deadeye_shot_audio_pool.is_empty():
		return
	var player := hero.gunner_deadeye_shot_audio_pool[
		hero.gunner_deadeye_shot_audio_cursor
		% hero.gunner_deadeye_shot_audio_pool.size()
	]
	hero.gunner_deadeye_shot_audio_cursor = (
		hero.gunner_deadeye_shot_audio_cursor + 1
	) % hero.gunner_deadeye_shot_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	player.pitch_scale = 1.0
	player.stop()
	player.play()


func _play_gunner_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_gunner_reload_audio() -> void:
	_ensure_gunner_audio_runtime()
	if (
		not is_instance_valid(hero.gunner_reload_audio)
		or hero.gunner_reload_audio.stream == null
	):
		return
	hero.gunner_reload_audio.stop()
	hero.gunner_reload_audio.play(hero.STAGE4_RELOAD_AUDIO_START_OFFSET)


func _play_gunner_backstep_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(hero.gunner_backstep_audio)


func _play_gunner_cylinder_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(hero.gunner_cylinder_audio)


func _play_gunner_deadeye_start_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(hero.gunner_deadeye_start_audio)


func _play_gunner_hit_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(hero.gunner_hit_audio)


func _play_gunner_death_audio() -> void:
	_ensure_gunner_audio_runtime()
	_play_gunner_audio(hero.gunner_death_audio)


func _append_gunner_cooldown_hud(
	skills: Array,
	skill_id: String,
	skill_name: String,
	cooldown_total: float,
	remaining: float,
	icon_path: String
) -> void:
	if cooldown_total <= 0.0:
		return
	var current_remaining := maxf(remaining, 0.0)
	skills.append({
		"id": skill_id,
		"name": skill_name,
		"description": (
			"위험한 순간 뒤로 빠르게 이동해 거리를 벌립니다."
			if skill_id == "gunner_backstep"
			else (
				"재장전 중 실린더를 타격해 주변 적을 공격하고 제어합니다."
				if skill_id == "gunner_cylinder"
				else (
					"집중 상태에 들어가 강력한 연속 사격을 가합니다."
					if skill_id == "gunner_deadeye"
					else "권총의 용사가 전투 상황에 맞춰 자동으로 사용하는 전용 기술입니다."
				)
			)
		),
		"resource_text": "",
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
		"icon_path": icon_path,
	})


func _apply_stage4_gunner_effect_visuals() -> void:
	hero._configure_combat_effect_profile(hero.HERO_PRESENTATION.get_combat_effect_profile(hero.hero_archetype, &"gunner"))


func _set_gunner_muzzle_transform(direction: Vector2) -> void:
	var dir := direction.normalized()
	if dir.length_squared() <= 0.0:
		dir = Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	hero.rogue_attack_effect.position = dir * 48.0 + Vector2(0.0, -6.0)
	hero.rogue_attack_effect.rotation = dir.angle()


func _play_gunner_deadeye_flame(direction: Vector2) -> void:
	if hero.rogue_attack_effect.sprite_frames == null:
		return
	if not hero.rogue_attack_effect.sprite_frames.has_animation(&"deadeye_flame"):
		return
	if hero.rogue_attack_effect.sprite_frames.get_frame_count(&"deadeye_flame") <= 0:
		return

	_set_gunner_muzzle_transform(direction)
	hero.rogue_attack_effect.visible = true

	# Deadeye muzzle flame must pop on every single shot.
	hero.rogue_attack_effect.stop()
	hero.rogue_attack_effect.animation = &"deadeye_flame"
	hero.rogue_attack_effect.frame = 0
	hero.rogue_attack_effect.frame_progress = 0.0
	hero.rogue_attack_effect.play(&"deadeye_flame")


func _play_gunner_deadeye_smoke(direction: Vector2) -> void:
	if hero.rogue_attack_effect.sprite_frames == null:
		return
	if not hero.rogue_attack_effect.sprite_frames.has_animation(&"deadeye_smoke"):
		hero.rogue_attack_effect.visible = false
		return
	if hero.rogue_attack_effect.sprite_frames.get_frame_count(&"deadeye_smoke") <= 0:
		hero.rogue_attack_effect.visible = false
		return

	_set_gunner_muzzle_transform(direction)
	hero.rogue_attack_effect.visible = true
	hero.rogue_attack_effect.stop()
	hero.rogue_attack_effect.animation = &"deadeye_smoke"
	hero.rogue_attack_effect.frame = 0
	hero.rogue_attack_effect.frame_progress = 0.0
	hero.rogue_attack_effect.play(&"deadeye_smoke")


func _play_gunner_cylinder_dust() -> void:
	if hero.channel_effect.sprite_frames == null:
		return
	if not hero.channel_effect.sprite_frames.has_animation(&"cylinder_dust"):
		return
	hero.channel_effect.visible = true
	hero.channel_effect.stop()
	hero.channel_effect.position = Vector2.ZERO
	hero.channel_effect.rotation = randf_range(-0.10, 0.10)
	hero.channel_effect.modulate = Color(0.76, 0.68, 0.55, 0.88)
	hero.channel_effect.animation = &"cylinder_dust"
	hero.channel_effect.frame = 0
	hero.channel_effect.frame_progress = 0.0
	hero.channel_effect.play(&"cylinder_dust")
