extends RefCounted
## Sage archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _get_sage_augment_stacks(augment_id: String) -> int:
	if hero.hero_archetype != "grand_sage_astra":
		return 0
	return maxi(int(hero.build_counts.get(augment_id, 0)), 0)


func _consume_one_sage_condensation_stack() -> bool:
	if hero.sage_condensation_stacks <= 0:
		return false
	hero.sage_condensation_stacks -= 1
	for slot_index in range(hero.sage_condensation_visuals.size()):
		if slot_index in hero.sage_condensation_free_slots:
			continue
		var sprite := hero.sage_condensation_visuals[slot_index]
		if is_instance_valid(sprite):
			sprite.stop()
			sprite.visible = false
		hero.sage_condensation_free_slots.append(slot_index)
		break
	hero.queue_redraw()
	return true


func _apply_sage_mana_conversion(incoming_damage: float) -> float:
	var augment_stacks := _get_sage_augment_stacks("sage_mana_conversion")
	if augment_stacks <= 0 or hero.sage_condensation_stacks <= 0:
		return incoming_damage
	var projected_hp := maxf(float(hero.current_hp) - incoming_damage, 0.0)
	if projected_hp / float(maxi(hero.max_hp, 1)) > 0.50:
		return incoming_damage
	var absorbed := minf(
		incoming_damage,
		float(hero.max_hp) * 0.03 * float(augment_stacks)
	)
	if absorbed <= 0.0 or not _consume_one_sage_condensation_stack():
		return incoming_damage
	return maxf(incoming_damage - absorbed, 0.0)


func _ensure_sage_runtime() -> void:
	if hero.hero_archetype != "grand_sage_astra":
		return
	if not is_instance_valid(hero.sage_basic_audio):
		hero.sage_basic_audio = _create_sage_audio_player(hero.SAGE_BASIC_ATTACK_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 1.08)
	if not is_instance_valid(hero.sage_third_audio):
		hero.sage_third_audio = _create_sage_audio_player(hero.SAGE_THIRD_ATTACK_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 0.92)
	if not is_instance_valid(hero.sage_phase_audio):
		hero.sage_phase_audio = _create_sage_audio_player(hero.SAGE_PHASE_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 1.02)
	if not is_instance_valid(hero.sage_ice_pillar_audio):
		hero.sage_ice_pillar_audio = _create_sage_audio_player(hero.SAGE_ICE_PILLAR_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 0.90)
	if not is_instance_valid(hero.sage_radiance_create_audio):
		hero.sage_radiance_create_audio = _create_sage_audio_player(hero.SAGE_RADIANCE_CREATE_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 1.04)
	if not is_instance_valid(hero.sage_condensation_stack_audio):
		hero.sage_condensation_stack_audio = _create_sage_audio_player(hero.SAGE_CONDENSATION_STACK_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 1.18)
	if not is_instance_valid(hero.sage_condensation_release_audio):
		hero.sage_condensation_release_audio = _create_sage_audio_player(hero.SAGE_CONDENSATION_RELEASE_AUDIO_PATH, hero.SAGE_SFX_REFERENCE_DB, 0.96)
	_ensure_sage_condensation_visuals()
	_ensure_sage_starlight_aura()
	_ensure_sage_blackspot_pool()
	if not hero.sage_afterimage_pool.is_empty():
		return
	if hero._sage_afterimage_frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"trail")
		frames.set_animation_loop(&"trail", false)
		frames.set_animation_speed(&"trail", 18.0)
		for frame_index in range(1, 8):
			var texture := hero._load_stage1_texture("%s/effect6/dash_%02d.png" % [hero.STAGE10_FRAME_DIR, frame_index])
			if texture != null:
				frames.add_frame(&"trail", texture)
		hero._sage_afterimage_frames_cache = frames
	if hero._sage_afterimage_frames_cache.get_frame_count(&"trail") <= 0:
		return
	var pool_size := clampi(int(hero.sage_config.get("afterimage_pool_size", 12)), 4, 20)
	for index in range(pool_size):
		var ghost := AnimatedSprite2D.new()
		ghost.name = "SageAfterimage%02d" % index
		ghost.sprite_frames = hero._sage_afterimage_frames_cache
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.top_level = true
		# Keep Astra's phase trail strictly behind the hero body. Using both a
		# lower Z and show_behind_parent avoids the trail covering the sprite
		# even when the battle root uses Y-sorting.
		ghost.z_index = -1
		ghost.show_behind_parent = true
		ghost.visible = false
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.58)
		ghost.animation_finished.connect(Callable(hero, "_on_sage_afterimage_finished").bind(ghost))
		hero.add_child(ghost)
		hero.sage_afterimage_pool.append(ghost)


func _ensure_sage_condensation_visuals() -> void:
	if not hero.sage_condensation_visuals.is_empty():
		return

	if hero._sage_condensation_frames_cache == null:
		var frames := SpriteFrames.new()
		if frames.has_animation(&"default"):
			frames.remove_animation(&"default")
		frames.add_animation(&"summon")
		frames.set_animation_loop(&"summon", false)
		frames.set_animation_speed(&"summon", 12.0)
		for frame_index in range(1, 9):
			var texture := hero._load_stage1_texture(
				"%s/effect4/summon_%02d.png"
				% [hero.STAGE10_FRAME_DIR, frame_index]
			)
			if texture != null:
				frames.add_frame(&"summon", texture)
		hero._sage_condensation_frames_cache = frames

	if hero._sage_condensation_frames_cache.get_frame_count(&"summon") <= 0:
		return

	var skill_value = hero.sage_config.get("skill_3", {})
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var radius := maxf(float(skill.get("visual_radius", 82.0)), 20.0)
	var visual_scale := maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	for index in range(hero.SAGE_CONDENSATION_SLOT_ANGLES.size()):
		var sprite := AnimatedSprite2D.new()
		sprite.name = "SageCondensation%02d" % index
		sprite.sprite_frames = hero._sage_condensation_frames_cache
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2.from_angle(
			deg_to_rad(hero.SAGE_CONDENSATION_SLOT_ANGLES[index])
		) * radius
		sprite.scale = Vector2.ONE * visual_scale
		# Health/shield/resource bars are drawn by the Hero parent itself.
		# Keep condensation visuals behind the parent draw so the orbiting
		# effect can never cover Astra's HP, shield, or yellow gauge bars.
		sprite.z_index = 0
		sprite.show_behind_parent = true
		sprite.visible = false
		hero.add_child(sprite)
		hero.sage_condensation_visuals.append(sprite)


func _reset_sage_condensation_slots() -> void:
	hero.sage_condensation_free_slots.clear()
	for index in range(8):
		hero.sage_condensation_free_slots.append(index)
	for sprite in hero.sage_condensation_visuals:
		if is_instance_valid(sprite):
			sprite.stop()
			sprite.visible = false
			sprite.modulate = Color.WHITE


func _ensure_sage_starlight_aura() -> void:
	if is_instance_valid(hero.sage_starlight_aura):
		return

	var texture := hero._load_stage1_texture(
		"%s/effect7/stage10_effect2_01.png" % hero.STAGE10_FRAME_DIR
	)
	if texture == null:
		return

	var raw_skill = hero.sage_config.get("skill_4", {})
	var skill: Dictionary = (
		raw_skill if typeof(raw_skill) == TYPE_DICTIONARY else {}
	)
	var sprite := Sprite2D.new()
	sprite.name = "SageStarlightAura"
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * maxf(
		float(skill.get("aura_visual_scale", 0.70)),
		0.05
	)
	sprite.show_behind_parent = true
	sprite.z_index = -1
	sprite.visible = false
	hero.add_child(sprite)
	hero.sage_starlight_aura = sprite


func _set_sage_starlight_aura_active(active: bool) -> void:
	if active:
		_ensure_sage_starlight_aura()
	if is_instance_valid(hero.sage_starlight_aura):
		hero.sage_starlight_aura.visible = active


func _create_sage_audio_player(audio_path: String, volume_db: float, pitch_scale: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	if ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream is AudioStream:
			player.stream = stream
	hero.add_child(player)
	return player


func _play_sage_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _fire_sage_projectile(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	var shot_direction := hero.global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return
	_ensure_sage_runtime()
	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.42
	hero._face_attack_direction(shot_direction.x)
	hero._restart_stage1_animation("attack")
	hero.sage_attack_serial += 1
	var third_interval := maxi(int(hero.sage_config.get("third_attack_interval", 3)), 1)
	var is_piercing := hero.sage_attack_serial % third_interval == 0
	var shot_damage := hero.attack_damage
	var shot_speed := maxf(float(hero.sage_config.get("basic_projectile_speed", 800.0)), 1.0)
	var shot_range := maxf(float(hero.sage_config.get("basic_range", 650.0)), 1.0)
	var diameter := 26.4
	var projectile_mode := 0

	if is_piercing:
		projectile_mode = 1
		var celestial_pierce_stacks := _get_sage_augment_stacks(
			"sage_celestial_pierce"
		)
		shot_damage = maxi(1, int(round(
			float(hero.attack_damage)
			* maxf(float(hero.sage_config.get("piercing_damage_ratio", 0.90)), 0.0)
			* (1.0 + 0.08 * float(celestial_pierce_stacks))
		)))
		shot_speed = maxf(
			float(hero.sage_config.get("piercing_projectile_speed", 800.0)),
			1.0
		)
		shot_range = maxf(
			float(hero.sage_config.get("piercing_range", 1200.0))
			+ 80.0 * float(celestial_pierce_stacks),
			1.0
		)
		diameter = maxf(
			float(hero.sage_config.get("piercing_diameter", 220.0)),
			2.0
		)

	# 탄환 강화는 1·2번째 일반 평타에만 적용한다.
	# 3번째 관통 평타는 천체관통 전용 단일탄을 유지한다.
	var projectile_count := (
		1
		if is_piercing
		else 1 + clampi(hero.projectile_count_bonus, 0, 4)
	)
	var volley := hero.PROJECTILE_VOLLEY.new() if projectile_count > 1 else null
	var spread_step := deg_to_rad(12.0)
	var center_index := float(projectile_count - 1) * 0.5
	var pool_key := (
		"sage_piercing_projectile"
		if is_piercing
		else "sage_basic_projectile"
	)

	for index in range(projectile_count):
		var projectile_direction := shot_direction
		if not is_piercing and projectile_count > 1:
			var angle_offset := (float(index) - center_index) * spread_step
			projectile_direction = shot_direction.rotated(angle_offset).normalized()

		var projectile := hero._acquire_projectile(
			hero.SAGE_PROJECTILE_SCENE,
			pool_key
		)
		if projectile == null:
			continue
		projectile.global_position = (
			hero.global_position + projectile_direction * 54.0
		)
		projectile.call(
			"setup",
			projectile_direction,
			shot_damage,
			shot_speed,
			shot_range,
			projectile_mode,
			diameter,
			hero,
			volley
		)

	if is_piercing:
		_play_sage_audio(hero.sage_third_audio)
	else:
		_play_sage_audio(hero.sage_basic_audio)


func _add_sage_gauge(amount: float) -> void:
	if amount <= 0.0 or hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty() or hero.is_dying:
		return
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	hero.ultimate_charge = minf(hero.ultimate_charge + amount, gauge_max)
	hero.queue_redraw()


func is_sage_skill_ready() -> bool:
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return false
	return hero.ultimate_charge + 0.001 >= maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)


func _update_sage_runtime(delta: float) -> void:
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty() or hero.is_dying or hero.current_hp <= 0:
		return
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var level_steps := floori(float(maxi(hero.level, 0)) / 5.0)
	var regen_per_second := maxf(float(hero.sage_config.get("gauge_regen_base", 1.0)), 0.0) + float(level_steps) * maxf(float(hero.sage_config.get("gauge_regen_per_5_levels", 1.0)), 0.0)
	if regen_per_second > 0.0 and hero.ultimate_charge < gauge_max:
		hero.ultimate_charge = minf(hero.ultimate_charge + regen_per_second * delta, gauge_max)
		hero.sage_gauge_redraw_timer -= delta
		if hero.sage_gauge_redraw_timer <= 0.0:
			hero.sage_gauge_redraw_timer = 0.10
			hero.queue_redraw()
	var sage_skill_cooldown_delta := (
		delta * _get_sage_condensation_cooldown_rate()
	)
	hero.sage_skill1_cooldown_timer = maxf(
		hero.sage_skill1_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	hero.sage_skill2_cooldown_timer = maxf(
		hero.sage_skill2_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	hero.sage_skill3_cooldown_timer = maxf(
		hero.sage_skill3_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	hero.sage_skill4_cooldown_timer = maxf(
		hero.sage_skill4_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	hero.sage_skill5_cooldown_timer = maxf(
		hero.sage_skill5_cooldown_timer - sage_skill_cooldown_delta,
		0.0
	)
	hero.sage_condensation_skill_damage_buff_timer = maxf(
		hero.sage_condensation_skill_damage_buff_timer - delta,
		0.0
	)

	if hero.sage_condensation_unlock_pending:
		hero.sage_condensation_unlock_effect_timer = maxf(
			hero.sage_condensation_unlock_effect_timer - delta,
			0.0
		)
		if hero.sage_condensation_unlock_effect_timer <= 0.0:
			hero.sage_condensation_unlock_pending = false
			_emit_sage_late_skill_unlock_cutscene()

	if hero.sage_starlight_remaining > 0.0:
		hero.sage_starlight_remaining = maxf(hero.sage_starlight_remaining - delta, 0.0)
		hero.sage_starlight_volley_timer -= delta
		var skill4_value = hero.sage_config.get("skill_4", {})
		var skill4: Dictionary = (
			skill4_value if typeof(skill4_value) == TYPE_DICTIONARY else {}
		)
		var volley_interval := maxf(
			float(skill4.get("spawn_interval", 0.75)),
			0.05
		)
		while hero.sage_starlight_remaining > 0.0 and hero.sage_starlight_volley_timer <= 0.0:
			_launch_sage_starlight_volley(skill4)
			hero.sage_starlight_volley_timer += volley_interval
		if hero.sage_starlight_remaining <= 0.0:
			_set_sage_starlight_aura_active(false)

	if hero.sage_radiance_launch_remaining > 0:
		hero.sage_radiance_launch_timer = maxf(hero.sage_radiance_launch_timer - delta, 0.0)
		if hero.sage_radiance_launch_timer <= 0.0:
			_launch_sage_radiance_orb()
			hero.sage_radiance_launch_remaining = maxi(hero.sage_radiance_launch_remaining - 1, 0)
			var skill2_value = hero.sage_config.get("skill_2", {})
			var skill2: Dictionary = (
				skill2_value if typeof(skill2_value) == TYPE_DICTIONARY else {}
			)
			hero.sage_radiance_launch_timer = maxf(
				float(skill2.get("spawn_interval", 0.25)),
				0.01
			)
	elif hero.sage_skill5_cooldown_timer <= 0.0 and _try_cast_sage_annihilation():
		pass
	elif hero.sage_skill4_cooldown_timer <= 0.0 and _try_cast_sage_starlight():
		pass
	elif hero.sage_skill3_cooldown_timer <= 0.0:
		if not _try_cast_sage_mana_condensation():
			if hero.sage_skill2_cooldown_timer <= 0.0:
				if not _try_cast_sage_radiance_singularity() and hero.sage_skill1_cooldown_timer <= 0.0:
					_try_cast_sage_ice_pillar()
			elif hero.sage_skill1_cooldown_timer <= 0.0:
				_try_cast_sage_ice_pillar()
	elif hero.sage_skill2_cooldown_timer <= 0.0:
		if not _try_cast_sage_radiance_singularity() and hero.sage_skill1_cooldown_timer <= 0.0:
			_try_cast_sage_ice_pillar()
	elif hero.sage_skill1_cooldown_timer <= 0.0:
		_try_cast_sage_ice_pillar()

	if hero.sage_post_phase_shield_timer > 0.0:
		hero.sage_post_phase_shield_timer = maxf(hero.sage_post_phase_shield_timer - delta, 0.0)
		if hero.shield_hp <= 0.0:
			hero.sage_post_phase_shield_timer = 0.0
			hero.shield_max_hp = 0.0
		elif hero.sage_post_phase_shield_timer <= 0.0:
			hero.shield_hp = 0.0
			hero.shield_max_hp = 0.0
			hero.queue_redraw()
	if hero.sage_phase_active:
		hero.sage_phase_remaining = maxf(hero.sage_phase_remaining - delta, 0.0)
		hero.sage_afterimage_timer = maxf(hero.sage_afterimage_timer - delta, 0.0)
		if hero.velocity.length_squared() > 36.0 and hero.sage_afterimage_timer <= 0.0:
			_emit_sage_afterimage()
			hero.sage_afterimage_timer = maxf(float(hero.sage_config.get("afterimage_interval", 0.075)), 0.03)
		if hero.sage_phase_remaining <= 0.0:
			_end_sage_phase()
		return
	hero.sage_phase_cooldown_timer = maxf(hero.sage_phase_cooldown_timer - delta, 0.0)
	if hero.sage_phase_cooldown_timer <= 0.0:
		_start_sage_phase()


func _try_cast_sage_ice_pillar() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return
	if not is_instance_valid(hero.target) or hero.target.is_queued_for_deletion():
		return
	var skill_value = hero.sage_config.get("skill_1", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return
	var gauge_cost := maxf(float(skill.get("gauge_cost", 35.0)), 0.0)
	if hero.ultimate_charge + 0.001 < gauge_cost:
		return

	var effect_diameter := maxf(float(skill.get("effect_diameter", 250.0)), 2.0)
	var damage := maxi(
		1,
		int(round(
			float(hero.attack_damage)
			* maxf(float(skill.get("damage_ratio", 1.0)), 0.0)
			* _get_sage_skill_damage_multiplier()
		))
	)
	var cast_position := hero.target.global_position
	var cast_direction := hero.global_position.direction_to(cast_position)
	if cast_direction.length_squared() <= 0.001:
		cast_direction = Vector2.RIGHT
	var wall_direction := cast_direction.orthogonal().normalized()
	var glacier_wall_stacks := _get_sage_augment_stacks("sage_glacier_wall")
	var spawned_any := false
	for pillar_index in range(1 + glacier_wall_stacks):
		var pillar := hero._acquire_projectile(
			hero.SAGE_ICE_PILLAR_SCENE,
			"sage_ice_pillar"
		)
		if pillar == null:
			continue
		var pillar_position := cast_position
		var pillar_damage := damage
		if pillar_index > 0:
			var side := -1.0 if pillar_index % 2 == 1 else 1.0
			var row := float(ceili(float(pillar_index) / 2.0))
			pillar_position += (
				wall_direction
				* side
				* row
				* effect_diameter
				* 0.72
			)
			pillar_damage = maxi(1, int(round(float(damage) * 0.65)))
		pillar_position.x = clampf(
			pillar_position.x,
			hero.FIELD_MARGIN,
			hero.battlefield_size.x - hero.FIELD_MARGIN
		)
		pillar_position.y = clampf(
			pillar_position.y,
			hero.FIELD_MARGIN,
			hero.battlefield_size.y - hero.FIELD_MARGIN
		)
		pillar.global_position = pillar_position
		pillar.call(
			"setup",
			pillar_damage,
			maxf(float(skill.get("duration", 4.0)), 0.1),
			effect_diameter * 0.5,
			clampf(float(skill.get("slow_multiplier", 0.80)), 0.1, 1.0),
			maxf(float(skill.get("collision_radius", 34.0)), 8.0),
			hero
		)
		spawned_any = true
	if not spawned_any:
		return

	hero.ultimate_charge = maxf(hero.ultimate_charge - gauge_cost, 0.0)
	hero.sage_skill1_cooldown_timer = maxf(float(skill.get("cooldown", 25.0)), 0.1)
	hero.attack_timer = maxf(hero.attack_timer, 0.35)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer, 0.42)
	hero._face_attack_direction(hero.target.global_position.x - hero.global_position.x)
	hero._restart_stage1_animation("attack")
	_play_sage_audio(hero.sage_ice_pillar_audio)
	hero.queue_redraw()


func _try_cast_sage_radiance_singularity() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return false
	var skill_value = hero.sage_config.get("skill_2", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty() or hero.sage_radiance_launch_remaining > 0:
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 40.0)), 0.0)
	if hero.ultimate_charge + 0.001 < gauge_cost:
		return false

	hero.ultimate_charge = maxf(hero.ultimate_charge - gauge_cost, 0.0)
	hero.sage_skill2_cooldown_timer = maxf(float(skill.get("cooldown", 45.0)), 0.1)
	hero.sage_radiance_launch_remaining = maxi(
		int(skill.get("orb_count", 10))
		+ _get_sage_augment_stacks("sage_radiance_split") * 2,
		1
	)
	hero.sage_radiance_launch_timer = 0.0
	hero.attack_timer = maxf(hero.attack_timer, 0.35)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer, 0.42)
	hero._restart_stage1_animation("attack")
	_play_sage_audio(hero.sage_radiance_create_audio)
	hero.queue_redraw()
	return true


func _launch_sage_radiance_orb() -> void:
	var skill_value = hero.sage_config.get("skill_2", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return

	var direction := Vector2.from_angle(randf_range(0.0, TAU))
	var min_distance := maxf(float(skill.get("travel_distance_min", 180.0)), 1.0)
	var max_distance := maxf(
		float(skill.get("travel_distance_max", hero.attack_range)),
		min_distance
	)
	var travel_distance := randf_range(min_distance, max_distance)
	var destination := hero.global_position + direction * travel_distance
	var tracked_target: Node2D = null
	if _get_sage_augment_stacks("sage_radiance_split") > 0:
		var monster_nodes := hero._get_monster_nodes_cached()
		var monster_count := monster_nodes.size()
		for offset in range(monster_count):
			var candidate_index := (
				hero.sage_radiance_target_cursor + offset
			) % maxi(monster_count, 1)
			var candidate := monster_nodes[candidate_index] as Node2D
			if (
				not is_instance_valid(candidate)
				or candidate.is_queued_for_deletion()
			):
				continue
			var hp_value = candidate.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			tracked_target = candidate
			destination = candidate.global_position
			hero.sage_radiance_target_cursor = (
				candidate_index + 1
			) % maxi(monster_count, 1)
			break
	destination.x = clampf(
		destination.x,
		hero.FIELD_MARGIN,
		hero.battlefield_size.x - hero.FIELD_MARGIN
	)
	destination.y = clampf(
		destination.y,
		hero.FIELD_MARGIN,
		hero.battlefield_size.y - hero.FIELD_MARGIN
	)

	var size_min := clampf(float(skill.get("orb_scale_min", 0.50)), 0.05, 4.0)
	var size_max := maxf(float(skill.get("orb_scale_max", 1.0)), size_min)
	var orb_scale := randf_range(size_min, size_max)
	var size_ratio := (
		clampf((orb_scale - size_min) / maxf(size_max - size_min, 0.001), 0.0, 1.0)
	)
	var diameter := lerpf(
		maxf(float(skill.get("explosion_diameter_min", 100.0)), 2.0),
		maxf(float(skill.get("explosion_diameter_max", 250.0)), 2.0),
		size_ratio
	)
	var damage_ratio := lerpf(
		maxf(float(skill.get("damage_ratio_min", 0.50)), 0.0),
		maxf(float(skill.get("damage_ratio_max", 1.0)), 0.0),
		size_ratio
	)
	var orb_damage := maxi(1, int(round(float(hero.attack_damage) * damage_ratio * _get_sage_skill_damage_multiplier())))

	var orb := hero._acquire_projectile(hero.SAGE_RADIANCE_ORB_SCENE, "sage_radiance_orb")
	if orb == null:
		return
	orb.global_position = hero.global_position
	orb.call(
		"setup",
		destination,
		maxf(float(skill.get("projectile_speed", 350.0)), 1.0),
		maxf(float(skill.get("arrival_delay", 1.0)), 0.0),
		diameter * 0.5,
		orb_damage,
		clampf(float(skill.get("slow_multiplier", 0.85)), 0.1, 1.0),
		maxf(float(skill.get("slow_duration", 2.0)), 0.0),
		orb_scale,
		hero,
		tracked_target
	)


func _try_cast_sage_annihilation() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return false
	if not hero.is_conditional_skill_unlocked("sage_skill_5"):
		return false

	var skill_value = hero.sage_config.get("skill_5", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 100.0)), 0.0)
	if hero.ultimate_charge + 0.001 < gauge_cost:
		return false

	var point := hero._acquire_projectile(
		hero.SAGE_ANNIHILATION_POINT_SCENE,
		"sage_annihilation_point"
	)
	if point == null:
		return false

	var damage := maxi(
		int(round(
			float(hero.attack_damage)
			* maxf(float(skill.get("damage_ratio", 0.70)), 0.0)
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	point.global_position = hero.global_position
	point.call(
		"setup",
		hero,
		maxf(
			float(skill.get("duration", 15.0))
			+ 0.6 * float(_get_sage_augment_stacks("sage_event_horizon")),
			0.1
		),
		maxf(
			float(skill.get("effect_diameter", 400.0))
			* 0.5
			* (1.0 + 0.12 * float(_get_sage_augment_stacks("sage_event_horizon"))),
			1.0
		),
		damage,
		maxf(float(skill.get("pull_interval", 0.10)), 0.05),
		maxf(
			float(skill.get("pull_step", 10.0))
			* (1.0 + 0.08 * float(_get_sage_augment_stacks("sage_event_horizon"))),
			0.0
		),
		maxf(float(skill.get("damage_interval", 0.50)), 0.05),
		clampf(float(skill.get("execution_hp_ratio", 0.10)), 0.0, 1.0),
		maxf(float(skill.get("visual_scale", 1.05)), 0.05),
		maxf(float(skill.get("create_fps", 10.0)), 1.0),
		maxf(float(skill.get("active_fps", 5.0)), 1.0),
		maxf(float(skill.get("disappear_fps", 10.0)), 1.0)
	)

	hero.ultimate_charge = maxf(hero.ultimate_charge - gauge_cost, 0.0)
	hero.sage_skill5_cooldown_timer = maxf(
		float(skill.get("cooldown", 60.0)),
		0.1
	)
	hero.attack_timer = maxf(hero.attack_timer, 0.40)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer, 0.48)
	hero._restart_stage1_animation("attack")
	hero.queue_redraw()
	return true


func _try_cast_sage_starlight() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return false
	if hero.sage_starlight_remaining > 0.0:
		return false

	var skill_value = hero.sage_config.get("skill_4", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 70.0)), 0.0)
	if hero.ultimate_charge + 0.001 < gauge_cost:
		return false

	_ensure_sage_runtime()
	hero.ultimate_charge = maxf(hero.ultimate_charge - gauge_cost, 0.0)
	hero.sage_skill4_cooldown_timer = maxf(
		float(skill.get("cooldown", 60.0)),
		0.1
	)
	hero.sage_starlight_remaining = maxf(
		float(skill.get("duration", 8.0)),
		0.1
	)
	hero.sage_starlight_volley_timer = maxf(
		float(skill.get("spawn_interval", 0.75)),
		0.05
	)
	_set_sage_starlight_aura_active(true)
	_launch_sage_starlight_volley(skill)

	hero.attack_timer = maxf(hero.attack_timer, 0.35)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer, 0.42)
	hero._restart_stage1_animation("attack")
	hero.queue_redraw()
	return true


func _launch_sage_starlight_volley(skill: Dictionary) -> void:
	if skill.is_empty():
		return

	var meteor_count := maxi(
		int(skill.get("meteors_per_volley", 3))
		+ _get_sage_augment_stacks("sage_constellation_chain"),
		1
	)
	var spawn_radius := maxf(
		float(skill.get("spawn_diameter", 1200.0)) * 0.5,
		1.0
	)
	var impact_radius := maxf(
		float(skill.get("impact_diameter", 200.0)) * 0.5,
		1.0
	)
	var damage_ratio := maxf(float(skill.get("damage_ratio", 1.10)), 0.0)
	var hit_damage := maxi(
		int(round(
			float(hero.attack_damage)
			* damage_ratio
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	var fall_duration := maxf(float(skill.get("fall_duration", 0.58)), 0.05)
	var fall_height := maxf(float(skill.get("fall_height", 430.0)), 40.0)
	var fall_side_offset := maxf(
		float(skill.get("fall_side_offset", 90.0)),
		0.0
	)
	var visual_scale := maxf(
		float(skill.get("meteor_visual_scale", 0.62)),
		0.05
	)
	var explosion_fps := maxf(
		float(skill.get("explosion_fps", 14.0)),
		1.0
	)

	for _index in range(meteor_count):
		var angle := randf_range(0.0, TAU)
		var distance := sqrt(randf()) * spawn_radius
		var impact_position := (
			hero.global_position
			+ Vector2.from_angle(angle) * distance
		)
		impact_position.x = clampf(
			impact_position.x,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.x - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		)
		impact_position.y = clampf(
			impact_position.y,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.y - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		)

		var meteor := hero._acquire_projectile(
			hero.SAGE_STARLIGHT_METEOR_SCENE,
			"sage_starlight_meteor"
		)
		if meteor == null:
			continue
		meteor.global_position = impact_position
		meteor.call(
			"setup",
			hit_damage,
			impact_radius,
			fall_duration,
			visual_scale,
			fall_height,
			fall_side_offset,
			explosion_fps,
			hero
		)


func _try_cast_sage_mana_condensation() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_config.is_empty():
		return false
	var skill_value = hero.sage_config.get("skill_3", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return false
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return false

	var gauge_cost := maxf(float(skill.get("gauge_cost", 20.0)), 0.0)
	if hero.ultimate_charge + 0.001 < gauge_cost:
		return false

	_ensure_sage_runtime()
	hero.ultimate_charge = maxf(hero.ultimate_charge - gauge_cost, 0.0)
	hero.sage_skill3_cooldown_timer = maxf(float(skill.get("cooldown", 13.0)), 0.1)
	hero.attack_timer = maxf(hero.attack_timer, 0.30)
	hero.attack_pose_timer = maxf(hero.attack_pose_timer, 0.38)
	hero._restart_stage1_animation("attack")

	var max_stacks := maxi(int(skill.get("max_stacks", 8)), 1)
	if hero.sage_condensation_stacks >= max_stacks:
		_consume_sage_condensation(skill)
	else:
		_add_sage_condensation_stack(skill)
	hero.queue_redraw()
	return true


func _add_sage_condensation_stack(skill: Dictionary) -> void:
	if hero.sage_condensation_free_slots.is_empty():
		return
	var pick_index := randi_range(0, hero.sage_condensation_free_slots.size() - 1)
	var slot_index := hero.sage_condensation_free_slots[pick_index]
	hero.sage_condensation_free_slots.remove_at(pick_index)
	hero.sage_condensation_stacks = mini(
		hero.sage_condensation_stacks + 1,
		maxi(int(skill.get("max_stacks", 8)), 1)
	)

	if slot_index >= 0 and slot_index < hero.sage_condensation_visuals.size():
		var sprite := hero.sage_condensation_visuals[slot_index]
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
			sprite.visible = true
			sprite.stop()
			sprite.animation = &"summon"
			sprite.frame = 0
			sprite.frame_progress = 0.0
			sprite.play(&"summon")
	_play_sage_audio(hero.sage_condensation_stack_audio)


func _consume_sage_condensation(skill: Dictionary) -> void:
	hero.sage_condensation_stacks = 0
	_reset_sage_condensation_slots()
	hero.sage_condensation_completion_count += 1

	var hp_multiplier := 1.0 + maxf(
		float(skill.get("permanent_hp_ratio", 0.03)),
		0.0
	)
	var attack_multiplier := 1.0 + maxf(
		float(skill.get("permanent_attack_ratio", 0.03)),
		0.0
	)
	var move_multiplier := 1.0 + maxf(
		float(skill.get("permanent_move_speed_ratio", 0.0025)),
		0.0
	)
	var attack_speed_gain := maxf(
		float(skill.get("permanent_attack_speed_ratio", 0.0025)),
		0.0
	)

	var previous_max_hp := hero.max_hp
	hero.max_hp = maxi(1, int(round(float(hero.max_hp) * hp_multiplier)))
	hero.current_hp = mini(
		hero.max_hp,
		hero.current_hp + maxi(hero.max_hp - previous_max_hp, 0)
	)
	hero.attack_damage = maxi(
		1,
		int(round(float(hero.attack_damage) * attack_multiplier))
	)
	hero.base_attack_damage_for_level_growth *= attack_multiplier
	hero.move_speed *= move_multiplier
	hero.common_attack_speed_bonus += attack_speed_gain
	if hero.player_controlled and hero.player_weapons != null and hero.player_weapons.identity != null:
		hero.player_weapons.identity.permanent_growth(hp_multiplier,move_multiplier)
	hero.sage_condensation_skill_damage_buff_timer = maxf(
		float(skill.get("skill_damage_buff_duration", 10.0)),
		0.0
	)

	_play_sage_audio(hero.sage_condensation_release_audio)
	hero.health_changed.emit(hero.current_hp, hero.max_hp)
	_try_start_sage_late_skill_unlock_sequence(skill)


func _get_sage_condensation_cooldown_reduction() -> float:
	if (
		hero.hero_archetype != "grand_sage_astra"
		or hero.sage_condensation_stacks <= 0
	):
		return 0.0
	var skill_value = hero.sage_config.get("skill_3")
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var per_stack := maxf(
		float(skill.get("cooldown_reduction_per_stack", 0.02)),
		0.0
	)
	return clampf(
		per_stack * float(hero.sage_condensation_stacks),
		0.0,
		0.90
	)


func _get_sage_condensation_cooldown_rate() -> float:
	var reduction := _get_sage_condensation_cooldown_reduction()
	return (
		1.0 / maxf(1.0 - reduction, 0.10)
		* (1.0 + 0.05 * float(_get_sage_augment_stacks("sage_multicast")))
	)


func _get_sage_skill_damage_multiplier() -> float:
	if hero.hero_archetype != "grand_sage_astra":
		return 1.0

	var bonus_ratio := 0.0
	if hero.sage_condensation_skill_damage_buff_timer > 0.0:
		var skill3_value = hero.sage_config.get("skill_3", {})
		var skill3: Dictionary = (
			skill3_value
			if typeof(skill3_value) == TYPE_DICTIONARY
			else {}
		)
		bonus_ratio += maxf(
			float(skill3.get("skill_damage_buff_ratio", 0.30)),
			0.0
		)

	if hero.is_conditional_skill_unlocked("sage_skill_6"):
		var skill6_value = hero.sage_config.get("skill_6", {})
		var skill6: Dictionary = (
			skill6_value
			if typeof(skill6_value) == TYPE_DICTIONARY
			else {}
		)
		bonus_ratio += maxf(
			float(skill6.get("skill_damage_bonus_ratio", 0.10)),
			0.0
		)
	bonus_ratio += 0.08 * float(_get_sage_augment_stacks("sage_multicast"))

	return 1.0 + bonus_ratio


func _ensure_sage_blackspot_pool() -> void:
	if not hero.sage_blackspot_effects.is_empty(): return
	var world := hero.get_parent()
	if not is_instance_valid(world) or not world.has_method("acquire_projectile"): return
	var skill: Dictionary = hero.sage_config.get("skill_6",{})
	for index in maxi(int(skill.get("max_active",8)),1):
		var effect := world.acquire_projectile(hero.SAGE_BLACKSPOT_EXPLOSION_SCENE,"sage_blackspot_explosion") as Node2D
		if effect != null: hero.sage_blackspot_effects.append(effect)
	for effect in hero.sage_blackspot_effects:
		world.recycle_projectile(effect,"sage_blackspot_explosion")


func _on_sage_skill_hit(hit_position: Vector2) -> void:
	if (
		hero.hero_archetype != "grand_sage_astra"
		or hero.is_dying
		or hero.current_hp <= 0
		or not hero.is_conditional_skill_unlocked("sage_skill_6")
	):
		return

	var skill_value = hero.sage_config.get("skill_6", {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = skill_value
	if skill.is_empty():
		return
	if randf() >= clampf(
		float(skill.get("trigger_chance", 0.50)),
		0.0,
		1.0
	):
		return

	var authority := hero.get_parent()
	if authority.has_method("acquire_projectile"):
		if not authority.projectile_pools.has("sage_blackspot_explosion") or authority.projectile_pools["sage_blackspot_explosion"].is_empty(): return
	# This effect is Node2D, not Area2D; the projectile-only helper rejected it
	# after allocating a pooled actor and then an unparented fallback instance.
	var explosion: Node2D
	var world := hero.get_parent()
	if is_instance_valid(world) and world.has_method("acquire_projectile"):
		explosion = world.acquire_projectile(hero.SAGE_BLACKSPOT_EXPLOSION_SCENE,"sage_blackspot_explosion") as Node2D
	elif is_instance_valid(world):
		explosion = hero.SAGE_BLACKSPOT_EXPLOSION_SCENE.instantiate() as Node2D
		world.add_child(explosion)
	if explosion == null:
		return

	var blackspot_damage := maxi(
		int(round(
			float(hero.attack_damage)
			* maxf(float(skill.get("damage_ratio", 0.80)), 0.0)
			* _get_sage_skill_damage_multiplier()
		)),
		1
	)
	explosion.global_position = hit_position
	explosion.call(
		"setup",
		hero,
		blackspot_damage,
		maxf(
			float(skill.get("explosion_diameter", 150.0)) * 0.5,
			1.0
		),
		maxf(float(skill.get("explosion_fps", 14.0)), 1.0),
		maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	)


func _on_sage_blackspot_kill() -> void:
	if (
		hero.hero_archetype != "grand_sage_astra"
		or hero.is_dying
		or hero.current_hp <= 0
		or hero.current_hp >= hero.max_hp
	):
		return

	var skill_value = hero.sage_config.get("skill_6", {})
	var skill: Dictionary = (
		skill_value
		if typeof(skill_value) == TYPE_DICTIONARY
		else {}
	)
	var heal_ratio := maxf(
		float(skill.get("kill_heal_current_hp_ratio", 0.005)),
		0.0
	)
	if heal_ratio <= 0.0:
		return

	var heal_amount := maxi(
		int(round(float(hero.current_hp) * heal_ratio)),
		1
	)
	var previous_hp := hero.current_hp
	hero.current_hp = mini(hero.current_hp + hero._get_reduced_healing(heal_amount), hero.max_hp)
	if hero.current_hp != previous_hp:
		hero.health_changed.emit(hero.current_hp, hero.max_hp)
		hero.queue_redraw()


func _try_start_sage_late_skill_unlock_sequence(skill: Dictionary) -> void:
	var required := maxi(int(skill.get("unlock_completion_count", 2)), 1)
	if hero.sage_condensation_completion_count < required:
		return
	if (
		hero.is_conditional_skill_unlocked("sage_skill_5")
		and hero.is_conditional_skill_unlocked("sage_skill_6")
	):
		return

	hero.conditional_skill_unlocks["sage_skill_5"] = true
	hero.conditional_skill_unlocks["sage_skill_6"] = true
	hero.sage_condensation_unlock_pending = true
	hero.sage_condensation_unlock_effect_timer = maxf(
		float(skill.get("unlock_effect_seconds", 0.80)),
		0.1
	)
	_play_sage_condensation_unlock_effect(skill)


func _play_sage_condensation_unlock_effect(skill: Dictionary) -> void:
	var visual_scale := maxf(float(skill.get("visual_scale", 0.34)), 0.05)
	for sprite in hero.sage_condensation_visuals:
		if not is_instance_valid(sprite):
			continue
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		sprite.scale = Vector2.ONE * visual_scale * 1.18
		sprite.visible = true
		sprite.stop()
		sprite.animation = &"summon"
		sprite.frame = 0
		sprite.frame_progress = 0.0
		sprite.play(&"summon")
		var tween := hero.create_tween()
		tween.set_parallel(true)
		tween.tween_property(
			sprite,
			"scale",
			Vector2.ONE * visual_scale * 1.42,
			0.72
		)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.72)
		tween.chain().tween_callback(
			Callable(hero, "_hide_sage_condensation_unlock_sprite").bind(
				sprite,
				visual_scale
			)
		)


func _hide_sage_condensation_unlock_sprite(
	sprite: AnimatedSprite2D,
	visual_scale: float
) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.stop()
	sprite.visible = false
	sprite.scale = Vector2.ONE * visual_scale
	sprite.modulate = Color.WHITE


func _emit_sage_late_skill_unlock_cutscene() -> void:
	var skill_value = hero.sage_config.get("skill_3", {})
	var skill: Dictionary = (
		skill_value if typeof(skill_value) == TYPE_DICTIONARY else {}
	)
	var required := maxi(int(skill.get("unlock_completion_count", 2)), 1)
	var payload := {
		"hero_id": hero.hero_id,
		"archetype": hero.hero_archetype,
		"source": "sage_condensation_completions",
		"condition_type": "mana_condensation_cycles",
		"current_value": hero.sage_condensation_completion_count,
		"required_value": required,
		"skill_id": "sage_skill_5_6",
		"skill_name": "스킬 5·6",
		"unlocked_skill_ids": ["sage_skill_5", "sage_skill_6"],
		"cutscene_texture_path": String(
			skill.get(
				"cutscene_texture_path",
				"res://assets/art/heroes/stage10_sage/cutscene/stage10_hero_cutscene.png"
			)
		),
		"cutscene_hold_seconds": float(
			skill.get("cutscene_hold_seconds", 1.20)
		),
	}
	hero.conditional_skill_unlocked.emit(
		"sage_skill_5_6",
		"스킬 5·6",
		payload
	)


func _start_sage_phase() -> void:
	if hero.sage_phase_active or hero.hero_archetype != "grand_sage_astra":
		return
	_ensure_sage_runtime()
	hero.sage_phase_entry_position = hero.position
	hero.sage_phase_active = true
	hero.sage_phase_remaining = maxf(float(hero.sage_config.get("phase_duration", 7.0)), 0.1)
	hero.sage_afterimage_timer = 0.0
	if hero.sage_saved_collision_mask < 0:
		hero.sage_saved_collision_mask = hero.collision_mask
	# Ignore monsters and decorative obstacles, but preserve hard castle
	# boundaries so phase cannot cross the upper wall and get trapped behind it.
	hero.collision_mask = (
		hero.sage_saved_collision_mask
		& hero.SAGE_PHASE_BOUNDARY_COLLISION_MASK
	)
	_play_sage_audio(hero.sage_phase_audio)


func _end_sage_phase() -> void:
	if not hero.sage_phase_active:
		return
	hero.sage_phase_active = false
	hero.sage_phase_remaining = 0.0
	if hero.sage_saved_collision_mask >= 0:
		hero.collision_mask = hero.sage_saved_collision_mask
	hero.sage_saved_collision_mask = -1
	# Resolve after the physics action wrapper, including its petrify anchor lock.
	hero.call_deferred("_resolve_sage_phase_obstacle_overlap")
	var interval := maxf(float(hero.sage_config.get("phase_interval", 25.0)), 0.1)
	var duration := maxf(float(hero.sage_config.get("phase_duration", 7.0)), 0.0)
	hero.sage_phase_cooldown_timer = maxf(interval - duration, 0.1)
	var shield_ratio := maxf(float(hero.sage_config.get("post_phase_shield_ratio", 0.10)), 0.0)
	hero.shield_max_hp = hero._player_shield_amount(float(hero.max_hp) * shield_ratio)
	hero.shield_hp = hero.shield_max_hp
	hero.sage_post_phase_shield_timer = maxf(float(hero.sage_config.get("post_phase_shield_duration", 3.0)), 0.0)
	hero.queue_redraw()


func _resolve_sage_phase_obstacle_overlap() -> void:
	if hero.hero_archetype != "grand_sage_astra" or hero.sage_phase_active or hero.is_dying or hero.current_hp <= 0 or not hero.is_inside_tree():
		return
	var body_shape := hero.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.disabled or body_shape.shape == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape.shape
	query.transform = body_shape.global_transform
	query.collision_mask = hero.collision_mask & (
		hero.HERO_DECOR_COLLISION_LAYER | hero.SAGE_PHASE_BOUNDARY_COLLISION_MASK
	)
	query.exclude = [hero.get_rid()]
	query.margin = 2.0
	var space := hero.get_world_2d().direct_space_state
	if space.intersect_shape(query, 1).is_empty():
		return
	var origin := hero.position
	var shape_offset := body_shape.global_position - hero.global_position
	# Bounded one-shot search, only on expiry inside a prop; no frame/group scan.
	for ring in range(1, 33):
		for direction_index in range(16):
			var direction := Vector2.RIGHT.rotated(TAU * float(direction_index) / 16.0)
			var candidate := origin + direction * float(ring) * 24.0
			if not _sage_phase_landing_is_clear(candidate, query, space, shape_offset):
				continue
			var blocked_distance := float(ring - 1) * 24.0
			var clear_distance := float(ring) * 24.0
			for refinement in range(6):
				var midpoint := (blocked_distance + clear_distance) * 0.5
				if _sage_phase_landing_is_clear(origin + direction * midpoint, query, space, shape_offset):
					clear_distance = midpoint
				else:
					blocked_distance = midpoint
			_apply_sage_phase_landing(origin + direction * clear_distance)
			return
	# The phase entry is a checked fallback for unusually large/concave props.
	if _sage_phase_landing_is_clear(hero.sage_phase_entry_position, query, space, shape_offset):
		_apply_sage_phase_landing(hero.sage_phase_entry_position)


func _sage_phase_landing_is_clear(
	candidate: Vector2,
	query: PhysicsShapeQueryParameters2D,
	space: PhysicsDirectSpaceState2D,
	shape_offset: Vector2
) -> bool:
	if (
		candidate.x < hero.FIELD_MARGIN or candidate.y < hero.FIELD_MARGIN
		or candidate.x > hero.battlefield_size.x - hero.FIELD_MARGIN
		or candidate.y > hero.battlefield_size.y - hero.FIELD_MARGIN
	):
		return false
	query.transform.origin = hero.get_parent().to_global(candidate) + shape_offset
	return space.intersect_shape(query, 1).is_empty()


func _apply_sage_phase_landing(candidate: Vector2) -> void:
	hero.position = candidate
	hero.velocity = Vector2.ZERO
	hero.obstacle_stuck_timer = 0.0
	hero.obstacle_escape_timer = 0.0
	if hero.petrify_timer > 0.0:
		hero.petrify_anchor = hero.global_position


func _emit_sage_afterimage() -> void:
	if hero.sage_afterimage_pool.is_empty() or not is_instance_valid(hero.hero_sprite):
		return
	var ghost := hero.sage_afterimage_pool[hero.sage_afterimage_index]
	hero.sage_afterimage_index = (hero.sage_afterimage_index + 1) % hero.sage_afterimage_pool.size()
	if not is_instance_valid(ghost):
		return
	ghost.stop()
	ghost.global_position = hero.global_position
	ghost.global_rotation = 0.0
	ghost.scale = hero.hero_sprite.scale
	ghost.offset = hero.hero_sprite.offset
	ghost.flip_h = hero.hero_sprite.flip_h
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.58)
	ghost.visible = true
	ghost.frame = 0
	ghost.play(&"trail")


func _on_sage_afterimage_finished(ghost: AnimatedSprite2D) -> void:
	if is_instance_valid(ghost):
		ghost.visible = false


func _append_sage_skill1_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_1", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 25.0)), 0.0)
	var cooldown_remaining := maxf(hero.sage_skill1_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 35.0)), 0.0)
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(hero.ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var cooldown_ready := cooldown_remaining <= 0.01
	var ready := cooldown_ready and has_gauge

	var status := "사용 가능"
	if not cooldown_ready:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	skills.append({
		"id": String(skill.get("id", "freezing_point_explosion")),
		"name": String(skill.get("name", "빙점폭발")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": "게이지 %.0f / %.0f" % [gauge_current, gauge_max],
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect1/ice_04.png",
	})


func _append_sage_skill2_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_2", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 45.0)), 0.0)
	var cooldown_remaining := maxf(hero.sage_skill2_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 40.0)), 0.0)
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(hero.ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var launching := hero.sage_radiance_launch_remaining > 0
	var ready := cooldown_remaining <= 0.01 and has_gauge and not launching

	var status := "사용 가능"
	if launching:
		status = "광휘구체 방출 중"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	skills.append({
		"id": String(skill.get("id", "radiance_singularity")),
		"name": String(skill.get("name", "광휘의 특이점")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": "게이지 %.0f / %.0f" % [gauge_current, gauge_max],
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect3/starburst_04.png",
	})


func _append_sage_skill3_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_3", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 13.0)), 0.0)
	var cooldown_remaining := maxf(hero.sage_skill3_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 20.0)), 0.0)
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(hero.ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var cooldown_ready := cooldown_remaining <= 0.01
	var ready := cooldown_ready and has_gauge
	var max_stacks := maxi(int(skill.get("max_stacks", 8)), 1)
	var required_completions := maxi(
		int(skill.get("unlock_completion_count", 2)),
		1
	)
	var unlocked := (
		hero.is_conditional_skill_unlocked("sage_skill_5")
		and hero.is_conditional_skill_unlocked("sage_skill_6")
	)

	var status := "사용 가능"
	if cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"
	elif hero.sage_condensation_stacks >= max_stacks:
		status = "8스택 소모 가능"
	if unlocked:
		status += " · 스킬 5·6 해금 완료"

	var progress := "마력응축 (%d/%d) · 완성 %d/%d" % [
		hero.sage_condensation_stacks,
		max_stacks,
		mini(hero.sage_condensation_completion_count, required_completions),
		required_completions,
	]
	var cooldown_reduction_percent := (
		_get_sage_condensation_cooldown_reduction() * 100.0
	)
	if cooldown_reduction_percent > 0.01:
		progress += " · 스킬 쿨감 +%.0f%%" % cooldown_reduction_percent
	if hero.sage_condensation_skill_damage_buff_timer > 0.0:
		progress += " · 스킬피해 +30%% %.1f초" % (
			hero.sage_condensation_skill_damage_buff_timer
		)

	skills.append({
		"id": String(skill.get("id", "mana_condensation")),
		"name": String(skill.get("name", "마력응축")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect4/summon_08.png",
	})


func _append_sage_skill4_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_4", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var cooldown_total := maxf(float(skill.get("cooldown", 60.0)), 0.0)
	var cooldown_remaining := maxf(hero.sage_skill4_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 70.0)), 0.0)
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(hero.ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var active := hero.sage_starlight_remaining > 0.0
	var ready := cooldown_remaining <= 0.01 and has_gauge and not active

	var status := "사용 가능"
	if active:
		status = "스타라이트 전개 중"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	var progress := "게이지 %.0f / %.0f" % [gauge_current, gauge_max]
	if active:
		progress += " · 남은 시간 %.1f초" % hero.sage_starlight_remaining

	skills.append({
		"id": String(skill.get("id", "starlight")),
		"name": String(skill.get("name", "스타라이트")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect7/stage10_effect2_01.png",
	})


func _append_sage_skill5_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_5", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var unlocked := hero.is_conditional_skill_unlocked("sage_skill_5")
	var cooldown_total := maxf(float(skill.get("cooldown", 60.0)), 0.0)
	var cooldown_remaining := maxf(hero.sage_skill5_cooldown_timer, 0.0)
	var gauge_cost := maxf(float(skill.get("gauge_cost", 100.0)), 0.0)
	var gauge_max := maxf(float(hero.sage_config.get("gauge_max", 100.0)), 1.0)
	var gauge_current := clampf(hero.ultimate_charge, 0.0, gauge_max)
	var has_gauge := gauge_current + 0.001 >= gauge_cost
	var ready := unlocked and cooldown_remaining <= 0.01 and has_gauge

	var status := "사용 가능"
	if not unlocked:
		status = "해금 조건 대기"
	elif cooldown_remaining > 0.01:
		status = "재사용 대기 중"
	elif not has_gauge:
		status = "게이지 부족"

	var progress := "게이지 %.0f / %.0f" % [gauge_current, gauge_max]
	if not unlocked:
		var skill3_value = hero.sage_config.get("skill_3", {})
		var skill3: Dictionary = (
			skill3_value
			if typeof(skill3_value) == TYPE_DICTIONARY
			else {}
		)
		var required_completions := maxi(
			int(skill3.get("unlock_completion_count", 2)),
			1
		)
		progress = "마력응축 완성 %d/%d · 스킬 5 해금 조건" % [
			mini(hero.sage_condensation_completion_count, required_completions),
			required_completions,
		]

	skills.append({
		"id": String(skill.get("id", "annihilation")),
		"name": String(skill.get("name", "소멸")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "게이지 %.0f" % gauge_cost,
		"progress_text": progress,
		"status_text": status,
		"available": ready,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect8/stage10_effect3_05.png",
	})


func _append_sage_skill6_hud(skills: Array) -> void:
	var raw_skill = hero.sage_config.get("skill_6", {})
	if typeof(raw_skill) != TYPE_DICTIONARY:
		return
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return

	var unlocked := hero.is_conditional_skill_unlocked("sage_skill_6")
	var skill3_value = hero.sage_config.get("skill_3", {})
	var skill3: Dictionary = (
		skill3_value
		if typeof(skill3_value) == TYPE_DICTIONARY
		else {}
	)
	var required_completions := maxi(
		int(skill3.get("unlock_completion_count", 2)),
		1
	)
	var progress := (
		"스킬 피해 +%.0f%% · 적중 시 %.0f%% 발동"
		% [
			maxf(
				float(skill.get("skill_damage_bonus_ratio", 0.10)),
				0.0
			) * 100.0,
			clampf(
				float(skill.get("trigger_chance", 0.50)),
				0.0,
				1.0
			) * 100.0,
		]
		if unlocked
		else "마력응축 완성 %d/%d · 스킬 6 해금 조건" % [
			mini(
				hero.sage_condensation_completion_count,
				required_completions
			),
			required_completions,
		]
	)

	skills.append({
		"id": String(skill.get("id", "black_spot_explosion")),
		"name": String(skill.get("name", "흑점폭발")),
		"description": hero._skill_hud_description(skill),
		"resource_text": "패시브",
		"progress_text": progress,
		"status_text": "패시브 활성" if unlocked else "해금 조건 대기",
		"available": unlocked,
		"cooldown_total": 0.0,
		"cooldown_remaining": 0.0,
		"icon_path": "res://assets/art/heroes/stage10_sage/frames/effect9/stage10_effect4_04.png",
	})
