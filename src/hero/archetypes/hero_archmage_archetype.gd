extends RefCounted
## Archmage archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _apply_archmage_boundary_steering(base_direction: Vector2) -> Vector2:
	return hero._apply_ranged_boundary_escape(base_direction, 440.0, 165.0)


func _ensure_archmage_audio_runtime() -> void:
	if hero.hero_archetype != "archmage_elementalist":
		return

	if hero.archmage_basic_audio_pool.is_empty():
		for index in range(3):
			hero.archmage_basic_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE5_BASIC_AUDIO_PATH,
					hero.HERO_SFX_DB_PRIMARY_ATTACK - 3.0,
					1.0
				)
			)

	if not is_instance_valid(hero.archmage_combustion_charge_audio):
		hero.archmage_combustion_charge_audio = hero._create_hero_sfx_player(
			hero.STAGE5_COMBUSTION_CHARGE_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL,
			0.92
		)
	if not is_instance_valid(hero.archmage_combustion_release_audio):
		hero.archmage_combustion_release_audio = hero._create_hero_sfx_player(
			hero.STAGE5_COMBUSTION_RELEASE_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 3.0,
			1.0
		)
	if not is_instance_valid(hero.archmage_ice_bolt_audio):
		hero.archmage_ice_bolt_audio = hero._create_hero_sfx_player(
			hero.STAGE5_ICE_BOLT_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.48
		)
	if not is_instance_valid(hero.archmage_ice_impact_audio):
		hero.archmage_ice_impact_audio = hero._create_hero_sfx_player(
			hero.STAGE5_ICE_IMPACT_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 1.0,
			0.94
		)

	if hero.archmage_earth_audio_pool.is_empty():
		for index in range(4):
			hero.archmage_earth_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE5_EARTH_SPIKE_AUDIO_PATH,
					hero.HERO_SFX_DB_SECONDARY_REPEAT - 1.0,
					0.78
				)
			)

	if hero.archmage_holy_audio_pool.is_empty():
		for index in range(4):
			hero.archmage_holy_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE5_HOLY_BURST_AUDIO_PATH,
					hero.HERO_SFX_DB_SECONDARY_REPEAT,
					1.20
				)
			)

	if not is_instance_valid(hero.archmage_chain_launch_audio):
		hero.archmage_chain_launch_audio = hero._create_hero_sfx_player(
			hero.STAGE5_CHAIN_LAUNCH_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.18
		)
	if hero.archmage_chain_hit_audio_pool.is_empty():
		for index in range(4):
			hero.archmage_chain_hit_audio_pool.append(
				hero._create_hero_sfx_player(
					hero.STAGE5_CHAIN_HIT_AUDIO_PATH,
					hero.HERO_SFX_DB_SECONDARY_REPEAT + 2.0,
					1.30
				)
			)

	if not is_instance_valid(hero.archmage_harmony_audio):
		hero.archmage_harmony_audio = hero._create_hero_sfx_player(
			hero.STAGE5_HARMONY_AUDIO_PATH,
			hero.HERO_SFX_DB_HEAVY_SKILL - 1.0,
			1.10
		)
	if not is_instance_valid(hero.archmage_storm_audio):
		hero.archmage_storm_audio = hero._create_hero_sfx_player(
			hero.STAGE5_STORM_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 2.0,
			1.06
		)
	if not is_instance_valid(hero.archmage_blink_audio):
		hero.archmage_blink_audio = hero._create_hero_sfx_player(
			hero.STAGE5_BLINK_AUDIO_PATH,
			hero.HERO_SFX_DB_REGULAR_SKILL - 4.0,
			1.18
		)
	if not is_instance_valid(hero.archmage_hit_audio):
		hero.archmage_hit_audio = hero._create_hero_sfx_player(
			hero.STAGE5_HIT_AUDIO_PATH, hero.CONTEXT_AUDIO.HIT_DB, 1.0
		)
	if not is_instance_valid(hero.archmage_death_audio):
		hero.archmage_death_audio = hero._create_hero_sfx_player(
			hero.STAGE5_DEATH_AUDIO_PATH,
			hero.HERO_SFX_DB_DEATH,
			0.88
		)


func _play_archmage_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _play_archmage_basic_audio(element: String) -> void:
	_ensure_archmage_audio_runtime()
	if hero.archmage_basic_audio_pool.is_empty():
		return
	var player := hero.archmage_basic_audio_pool[
		hero.archmage_basic_audio_cursor % hero.archmage_basic_audio_pool.size()
	]
	hero.archmage_basic_audio_cursor = (
		hero.archmage_basic_audio_cursor + 1
	) % hero.archmage_basic_audio_pool.size()
	if not is_instance_valid(player) or player.stream == null:
		return
	var element_pitch := {
		"earth": 0.82,
		"fire": 0.96,
		"ice": 1.16,
		"light": 1.28,
		"wind": 1.08,
		"holy": 1.22,
	}
	player.pitch_scale = float(element_pitch.get(element, 1.0))
	player.stop()
	player.play()


func _play_archmage_earth_spike_audio() -> void:
	_ensure_archmage_audio_runtime()
	if hero.archmage_earth_audio_pool.is_empty():
		return
	var player := hero.archmage_earth_audio_pool[
		hero.archmage_earth_audio_cursor % hero.archmage_earth_audio_pool.size()
	]
	hero.archmage_earth_audio_cursor = (
		hero.archmage_earth_audio_cursor + 1
	) % hero.archmage_earth_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 0.74 + 0.04 * float(hero.archmage_earth_audio_cursor % 3)
		player.stop()
		player.play()


func _play_archmage_holy_burst_audio() -> void:
	_ensure_archmage_audio_runtime()
	if hero.archmage_holy_audio_pool.is_empty():
		return
	var player := hero.archmage_holy_audio_pool[
		hero.archmage_holy_audio_cursor % hero.archmage_holy_audio_pool.size()
	]
	hero.archmage_holy_audio_cursor = (
		hero.archmage_holy_audio_cursor + 1
	) % hero.archmage_holy_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 1.14 + 0.04 * float(hero.archmage_holy_audio_cursor % 4)
		player.stop()
		player.play()


func play_archmage_chain_hit_audio() -> void:
	_ensure_archmage_audio_runtime()
	if hero.archmage_chain_hit_audio_pool.is_empty():
		return
	var player := hero.archmage_chain_hit_audio_pool[
		hero.archmage_chain_hit_audio_cursor % hero.archmage_chain_hit_audio_pool.size()
	]
	hero.archmage_chain_hit_audio_cursor = (
		hero.archmage_chain_hit_audio_cursor + 1
	) % hero.archmage_chain_hit_audio_pool.size()
	if is_instance_valid(player) and player.stream != null:
		player.pitch_scale = 1.22 + 0.04 * float(hero.archmage_chain_hit_audio_cursor % 4)
		player.stop()
		player.play()


func _play_archmage_hit_audio() -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_hit_audio)


func _play_archmage_death_audio() -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_death_audio)


func _fire_archmage_projectile(current_target: Node2D) -> void:
	var shot_direction := hero.global_position.direction_to(current_target.global_position)
	if shot_direction.length_squared() <= 0.0:
		return

	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.34
	hero._face_attack_direction(shot_direction.x)
	hero._restart_stage1_animation("attack")

	var element := _roll_next_archmage_element()
	var projectile := hero._acquire_projectile(
		hero.ARCHMAGE_PROJECTILE_SCENE,
		"archmage_projectile"
	)
	if projectile == null:
		return
	_play_archmage_basic_audio(element)
	projectile.global_position = hero.global_position + shot_direction * 52.0
	projectile.call(
		"setup",
		shot_direction,
		hero.attack_damage,
		hero.projectile_speed,
		hero.attack_range,
		element,
		hero.archmage_element_config,
		hero
	)
	_add_archmage_gauge(
		maxf(float(hero.archmage_skill_config.get("gauge_per_basic_attack", 4.0)), 0.0)
	)


func _configure_archmage_basic_elements() -> void:
	hero.archmage_basic_elements.clear()
	var configured = hero.archmage_element_config.get(
		"elements",
		hero.ARCHMAGE_DEFAULT_BASIC_ELEMENTS
	)
	if typeof(configured) == TYPE_ARRAY:
		for raw_element in configured:
			var element := String(raw_element)
			if (
				not element.is_empty()
				and element not in hero.archmage_basic_elements
			):
				hero.archmage_basic_elements.append(element)

	if hero.archmage_basic_elements.is_empty():
		for element in hero.ARCHMAGE_DEFAULT_BASIC_ELEMENTS:
			hero.archmage_basic_elements.append(element)


func _roll_next_archmage_element() -> String:
	if hero.archmage_basic_elements.is_empty():
		_configure_archmage_basic_elements()
	if hero.archmage_basic_elements.is_empty():
		return "earth"

	var element_count := hero.archmage_basic_elements.size()
	var chosen_index := 0
	if element_count > 1 and not hero.archmage_last_element.is_empty():
		var last_index := hero.archmage_basic_elements.find(hero.archmage_last_element)
		if last_index >= 0:
			chosen_index = randi_range(0, element_count - 2)
			if chosen_index >= last_index:
				chosen_index += 1
		else:
			chosen_index = randi_range(0, element_count - 1)
	else:
		chosen_index = randi_range(0, element_count - 1)

	var chosen := hero.archmage_basic_elements[chosen_index]
	hero.archmage_last_element = chosen
	return chosen


func _update_archmage_skill_runtime(delta: float) -> void:
	for key in hero.ARCHMAGE_SKILL_KEYS:
		hero.archmage_skill_cooldowns[key] = maxf(
			float(hero.archmage_skill_cooldowns.get(key, 0.0)) - delta,
			0.0
		)

	if hero.archmage_blink_stacks > 0:
		hero.archmage_blink_cooldown_timer = maxf(
			hero.archmage_blink_cooldown_timer - delta,
			0.0
		)
		if (
			hero.archmage_blink_cooldown_timer <= 0.0
			and _archmage_is_surrounded_for_blink()
		):
			_cast_archmage_blink()

	_add_archmage_gauge(
		maxf(float(hero.archmage_skill_config.get("gauge_per_second", 3.0)), 0.0) * delta
	)
	hero.archmage_orbit_angle = fmod(hero.archmage_orbit_angle + delta * 1.9, TAU)
	_update_archmage_orbit_positions()

	if hero.archmage_casting_sequence or hero.archmage_multicast_active:
		return

	var gauge_max := maxf(float(hero.archmage_skill_config.get("gauge_max", 100.0)), 1.0)
	if hero.ultimate_charge + 0.001 < gauge_max:
		return

	var chosen := _choose_archmage_skill()
	if chosen.is_empty():
		return
	_use_archmage_skill(chosen)


func _add_archmage_gauge(amount: float) -> void:
	if amount <= 0.0 or hero.hero_archetype != "archmage_elementalist":
		return
	var gauge_max := maxf(float(hero.archmage_skill_config.get("gauge_max", 100.0)), 1.0)
	hero.ultimate_charge = minf(hero.ultimate_charge + amount, gauge_max)
	hero.queue_redraw()


func restore_archmage_gauge(amount: float) -> void:
	_add_archmage_gauge(amount)


func _choose_archmage_skill() -> String:
	var nearby_220 := hero._count_monsters_near(hero.global_position, 220.0)
	var nearby_360 := hero._count_monsters_near(hero.global_position, 360.0)
	var total_monsters := hero._get_monster_nodes_cached().size()

	var combustion_weight := 0.0
	var ice_bolt_weight := 0.0
	var earth_spikes_weight := 0.0
	var holy_power_weight := 0.0
	var chain_dagger_weight := 0.0
	var storm_weight := 0.0
	var harmony_weight := 0.0

	if _archmage_skill_ready("combustion"):
		combustion_weight = maxf(
			1.2 + float(nearby_220) * 0.65,
			0.05
		)
	if _archmage_skill_ready("ice_bolt") and is_instance_valid(hero.target):
		ice_bolt_weight = maxf(2.2, 0.05)
	if _archmage_skill_ready("earth_spikes"):
		earth_spikes_weight = maxf(
			1.4 + minf(float(total_monsters) * 0.14, 2.2),
			0.05
		)
	if _archmage_skill_ready("holy_power"):
		holy_power_weight = maxf(
			1.1 + float(nearby_360) * 0.45,
			0.05
		)
	if (
		_archmage_skill_ready("chain_dagger")
		and not hero.archmage_chain_dagger_active
		and total_monsters > 0
	):
		chain_dagger_weight = maxf(
			1.4 + minf(float(total_monsters) * 0.25, 2.6),
			0.05
		)
	if _archmage_skill_ready("storm"):
		storm_weight = maxf(
			1.0 + float(nearby_360) * 0.55,
			0.05
		)

	var cooling_count := 0
	for key in hero.ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		if float(hero.archmage_skill_cooldowns.get(key, 0.0)) > 0.0:
			cooling_count += 1
	if _archmage_skill_ready("harmony") and cooling_count >= 1:
		harmony_weight = maxf(
			3.0 + float(cooling_count) * 1.10,
			0.05
		)

	var total_score := (
		combustion_weight
		+ ice_bolt_weight
		+ earth_spikes_weight
		+ holy_power_weight
		+ chain_dagger_weight
		+ storm_weight
		+ harmony_weight
	)
	if total_score <= 0.0:
		return ""

	var roll := randf() * total_score
	if combustion_weight > 0.0:
		roll -= combustion_weight
		if roll <= 0.0:
			return "combustion"
	if ice_bolt_weight > 0.0:
		roll -= ice_bolt_weight
		if roll <= 0.0:
			return "ice_bolt"
	if earth_spikes_weight > 0.0:
		roll -= earth_spikes_weight
		if roll <= 0.0:
			return "earth_spikes"
	if holy_power_weight > 0.0:
		roll -= holy_power_weight
		if roll <= 0.0:
			return "holy_power"
	if chain_dagger_weight > 0.0:
		roll -= chain_dagger_weight
		if roll <= 0.0:
			return "chain_dagger"
	if storm_weight > 0.0:
		roll -= storm_weight
		if roll <= 0.0:
			return "storm"
	if harmony_weight > 0.0:
		return "harmony"

	if storm_weight > 0.0:
		return "storm"
	if chain_dagger_weight > 0.0:
		return "chain_dagger"
	if holy_power_weight > 0.0:
		return "holy_power"
	if earth_spikes_weight > 0.0:
		return "earth_spikes"
	if ice_bolt_weight > 0.0:
		return "ice_bolt"
	return "combustion"


func _archmage_skill_ready(skill_key: String) -> bool:
	if hero.archmage_skill_config.is_empty():
		return false
	var config: Dictionary = hero.archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return false
	return float(hero.archmage_skill_cooldowns.get(skill_key, 0.0)) <= 0.0


func _use_archmage_skill(skill_key: String) -> void:
	if hero.silence_timer > 0.0:
		return
	_cast_archmage_skill_internal(skill_key, true, true)


func _cast_archmage_skill_internal(
	skill_key: String,
	consume_gauge: bool,
	trigger_multicast: bool
) -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.charm_timer > 0.0:
		return false
	var config: Dictionary = hero.archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return false
	if skill_key == "chain_dagger" and hero.archmage_chain_dagger_active:
		return false

	if consume_gauge:
		var gauge_max := maxf(
			float(hero.archmage_skill_config.get("gauge_max", 100.0)),
			1.0
		)
		if hero.ultimate_charge + 0.001 < gauge_max:
			return false

	var empowered := false
	if skill_key != "harmony" and _archmage_has_all_element_orbs():
		empowered = true
		hero.archmage_element_orbs.clear()
		hero.archmage_orbit_order.clear()
		_refresh_archmage_orbit_visuals()

	if consume_gauge:
		hero.ultimate_charge = 0.0
	hero.ultimate_flash_timer = 0.28

	var cooldown_multiplier := maxf(
		1.0 - hero.archmage_cooldown_reduction,
		0.10
	)
	hero.archmage_skill_cooldowns[skill_key] = (
		maxf(float(config.get("cooldown", 0.0)), 0.0)
		* cooldown_multiplier
	)
	hero.attack_pose_timer = 0.36
	hero._restart_stage1_animation("attack")

	match skill_key:
		"combustion":
			_cast_archmage_combustion(config, empowered)
			_collect_archmage_element("fire")
		"ice_bolt":
			_cast_archmage_ice_bolt(config, empowered)
			_collect_archmage_element("water")
		"earth_spikes":
			_cast_archmage_earth_spikes(config, empowered)
			_collect_archmage_element("earth")
		"holy_power":
			_cast_archmage_holy_power(config, empowered)
			_collect_archmage_element("holy")
		"chain_dagger":
			_cast_archmage_chain_dagger(config, empowered)
			_collect_archmage_element("electric")
		"harmony":
			_cast_archmage_harmony(config)
		"storm":
			_cast_archmage_storm(config, empowered)
			_collect_archmage_element("wind")
		_:
			return false

	if hero.archmage_mana_overflow_stacks > 0:
		var gauge_per_stack := 4.0 if consume_gauge else 1.0
		_add_archmage_gauge(
			gauge_per_stack * float(hero.archmage_mana_overflow_stacks)
		)

	hero.ultimate_used.emit(
		String(config.get("id", skill_key)),
		String(config.get("name", skill_key))
	)
	hero.queue_redraw()

	if (
		trigger_multicast
		and hero.archmage_multicast_stacks > 0
		and not hero.archmage_multicast_active
	):
		_start_archmage_multicast(skill_key)

	return true


func _cancel_archmage_multicast() -> void:
	# Synchronous reset/start invalidates pending timers without copying the list.
	hero.archmage_multicast_revision += 1
	hero.archmage_multicast_candidates.clear()
	hero.archmage_multicast_active = false


func _start_archmage_multicast(origin_skill: String) -> void:
	var source_life := hero._capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	_cancel_archmage_multicast()
	var reservation_revision := hero.archmage_multicast_revision
	for key in hero.ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		if key == origin_skill:
			continue
		if not hero.archmage_skill_config.has(key):
			continue
		if key == "chain_dagger" and hero.archmage_chain_dagger_active:
			continue
		hero.archmage_multicast_candidates.append(key)

	if hero.archmage_multicast_candidates.is_empty():
		return

	hero.archmage_multicast_candidates.shuffle()
	hero.archmage_multicast_active = true
	var wanted := mini(
		hero.archmage_multicast_stacks,
		hero.archmage_multicast_candidates.size()
	)
	var casted := 0

	while (
		casted < wanted
		and not hero.archmage_multicast_candidates.is_empty()
	):
		if reservation_revision != hero.archmage_multicast_revision or not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await hero.COMBAT_DELAY.wait(hero,0.30)
		if reservation_revision != hero.archmage_multicast_revision or not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break

		var extra_skill := String(
			hero.archmage_multicast_candidates.pop_back()
		)
		if _cast_archmage_skill_internal(extra_skill, false, false):
			casted += 1

	# Do not clear candidates or active state owned by a newer reservation.
	if reservation_revision == hero.archmage_multicast_revision and hero._is_delayed_skill_life_current(source_life, source_scope_id):
		_cancel_archmage_multicast()


func _begin_archmage_casting_sequence() -> void:
	hero.archmage_casting_sequence_count += 1
	hero.archmage_casting_sequence = true


func _end_archmage_casting_sequence() -> void:
	hero.archmage_casting_sequence_count = maxi(
		hero.archmage_casting_sequence_count - 1,
		0
	)
	hero.archmage_casting_sequence = hero.archmage_casting_sequence_count > 0


func _cast_archmage_combustion(config: Dictionary, empowered: bool) -> void:
	var source_life := hero._capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	_begin_archmage_casting_sequence()
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_combustion_charge_audio)
	var facing := Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(hero.target):
		facing = hero.global_position.direction_to(hero.target.global_position)
	if facing.length_squared() <= 0.0:
		facing = Vector2.RIGHT
	var orb_position := hero.global_position + facing.normalized() * 76.0
	var charge_fx := _spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect2",
		"fire", 1, 7, 18.0, true, orb_position, Vector2(0.88, 0.88)
	)
	var charge_fx_revision := int(charge_fx.get_meta("archmage_cast_revision", 0)) if is_instance_valid(charge_fx) else 0
	var duration := maxf(float(config.get("charge_duration", 0.90)), 0.05)
	var tick_interval := maxf(float(config.get("charge_tick_interval", 0.18)), 0.05)
	var radius := maxf(float(config.get("charge_radius", 95.0)), 1.0)
	var tick_damage := maxi(1, int(round(
		float(hero.attack_damage)
		* maxf(float(config.get("charge_tick_damage_ratio", 0.22)), 0.0)
		* hero._skill_damage_multiplier(empowered)
	)))
	var elapsed := 0.0
	while elapsed < duration and hero._is_delayed_skill_source_current(source_life, source_scope_id):
		hero._damage_monsters_in_radius(orb_position, radius, tick_damage, source_life, source_scope_id)
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await hero.COMBAT_DELAY.wait(hero,tick_interval)
		elapsed += tick_interval
	if is_instance_valid(charge_fx):
		_recycle_archmage_fx_if_current(charge_fx, charge_fx_revision, source_scope_id)
	if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
		if hero._is_delayed_skill_life_current(source_life, source_scope_id):
			_end_archmage_casting_sequence()
		return

	var thrust_direction := facing.normalized()
	var nearest := hero._find_nearest_monster_from_point(orb_position)
	if is_instance_valid(nearest):
		thrust_direction = orb_position.direction_to(nearest.global_position)
	var thrust_range := maxf(float(config.get("thrust_range", 280.0)), 1.0)
	var thrust_end := orb_position + thrust_direction * thrust_range
	var thrust_fx := _spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect2",
		"fire", 8, 5, 24.0, false, orb_position, Vector2(0.74, 0.74)
	)
	if is_instance_valid(thrust_fx):
		thrust_fx.rotation = thrust_direction.angle()
		var tween := thrust_fx.create_tween()
		tween.tween_property(thrust_fx, "global_position", thrust_end, 0.22)
	var thrust_damage := maxi(1, int(round(
		float(hero.attack_damage)
		* maxf(float(config.get("thrust_damage_ratio", 1.60)), 0.0)
		* hero._skill_damage_multiplier(empowered)
	)))
	hero._damage_monsters_in_corridor(
		orb_position,
		thrust_end,
		maxf(float(config.get("thrust_half_width", 92.0)), 1.0),
		thrust_damage,
		source_life,
		source_scope_id
	)
	if hero._is_delayed_skill_source_current(source_life, source_scope_id):
		_ensure_archmage_audio_runtime()
		_play_archmage_player(hero.archmage_combustion_release_audio)
	if hero._is_delayed_skill_life_current(source_life, source_scope_id):
		_end_archmage_casting_sequence()


func _cast_archmage_ice_bolt(config: Dictionary, empowered: bool) -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_ice_bolt_audio)
	var current_target := hero._find_farthest_monster_from_point(hero.global_position)
	if not is_instance_valid(current_target):
		return
	var direction := hero.global_position.direction_to(current_target.global_position)
	var projectile := hero._acquire_projectile(
		hero.ARCHMAGE_SKILL_PROJECTILE_SCENE,
		"archmage_skill_projectile"
	)
	if projectile == null:
		return
	projectile.global_position = hero.global_position + direction * 58.0
	projectile.call(
		"setup", "ice_bolt", direction,
		maxi(1, int(round(float(hero.attack_damage) * float(config.get("damage_ratio", 1.15)) * hero._skill_damage_multiplier(empowered)))),
		float(config.get("projectile_speed", 1050.0)),
		float(config.get("projectile_range", 850.0)),
		config, hero, empowered, current_target
	)


func resolve_archmage_ice_bolt_hit(
	_hit_target: Node2D,
	hit_position: Vector2,
	empowered: bool
) -> void:
	# Already emitted ice keeps its impact at HP0 until this source life retires.
	var source_life := hero._capture_delayed_skill_source(false)
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_ice_impact_audio)
	var config: Dictionary = hero.archmage_skill_config.get(
		"ice_bolt",
		{}
	)
	var impact_radius := maxf(
		float(config.get("impact_radius", 125.0)),
		1.0
	)
	var impact_damage := maxi(
		1,
		int(
			round(
				float(hero.attack_damage)
				* float(config.get("impact_damage_ratio", 1.50))
				* hero._skill_damage_multiplier(empowered)
			)
		)
	)
	hero._damage_monsters_in_radius(
		hit_position,
		impact_radius,
		impact_damage, source_life, source_scope_id, false
	)
	if not hero._is_delayed_skill_life_current(source_life, source_scope_id):
		return
	_resolve_archmage_ice_pillars(hit_position, empowered)


func _resolve_archmage_ice_pillars(hit_position: Vector2, empowered: bool) -> void:
	var source_life := hero._capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	var config: Dictionary = hero.archmage_skill_config.get("ice_bolt", {})
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect4",
		"ice", 7, 1, 18.0, false, hit_position, Vector2(0.72, 0.72)
	)
	var count := maxi(int(config.get("pillar_count", 6)), 1)
	var spawn_radius := maxf(float(config.get("pillar_spawn_radius", 210.0)), 1.0)
	var hit_radius := maxf(float(config.get("pillar_hit_radius", 72.0)), 1.0)
	var pillar_damage := maxi(1, int(round(
		float(hero.attack_damage)
		* float(config.get("pillar_damage_ratio", 0.85))
		* hero._skill_damage_multiplier(empowered)
	)))
	for index in range(count):
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		var angle := randf_range(0.0, TAU)
		var position := hit_position + Vector2.from_angle(angle) * randf_range(25.0, spawn_radius)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect4",
			"ice", 1, 6, 20.0, false, position, Vector2(0.70, 0.70)
		)
		hero._damage_monsters_in_radius(position, hit_radius, pillar_damage, source_life, source_scope_id)
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await hero.COMBAT_DELAY.wait(hero,0.045)


func _cast_archmage_earth_spikes(config: Dictionary, empowered: bool) -> void:
	var source_life := hero._capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	_begin_archmage_casting_sequence()
	var direction := Vector2.LEFT if hero.hero_sprite.flip_h else Vector2.RIGHT
	if is_instance_valid(hero.target):
		direction = hero.global_position.direction_to(hero.target.global_position)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()

	var count: int = maxi(int(config.get("spike_count", 7)), 1)
	var spacing: float = maxf(float(config.get("spike_spacing", 88.0)), 1.0)
	var radius: float = maxf(float(config.get("spike_radius", 70.0)), 1.0)
	var spike_damage: int = maxi(1, int(round(
		float(hero.attack_damage) * float(config.get("damage_ratio", 1.20)) * hero._skill_damage_multiplier(empowered)
	)))
	var spike_delay: float = maxf(float(config.get("spike_delay", 0.07)), 0.02)
	var cast_origin: Vector2 = hero.global_position
	var hit_ids: Dictionary = {}

	for index in range(count):
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		var position: Vector2 = cast_origin + direction * spacing * float(index + 1)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect1",
			"earth", 1, 11, 22.0, false, position, Vector2(0.72, 0.72)
		)
		_play_archmage_earth_spike_audio()
		hero._damage_monsters_in_radius_once(position, radius, spike_damage, hit_ids, source_life, source_scope_id)
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await hero.COMBAT_DELAY.wait(hero,spike_delay)

	if hero._is_delayed_skill_source_current(source_life, source_scope_id):
		var original_distance: float = spacing * float(count)
		var branch_distance: float = original_distance * clampf(
			float(config.get("branch_distance_ratio", 0.50)),
			0.0,
			2.0
		)
		if branch_distance > 0.0:
			var endpoint: Vector2 = cast_origin + direction * original_distance
			var branch_count: int = maxi(int(ceil(branch_distance / spacing)), 1)
			var left_direction: Vector2 = direction.rotated(PI * 0.5)
			var right_direction: Vector2 = direction.rotated(-PI * 0.5)

			for branch_index in range(branch_count):
				if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
					break
				var progress: float = float(branch_index + 1) / float(branch_count)
				var left_position: Vector2 = (
					endpoint + left_direction * branch_distance * progress
				)
				var right_position: Vector2 = (
					endpoint + right_direction * branch_distance * progress
				)

				_spawn_archmage_fx(
					"res://assets/art/heroes/stage5_archmage/frames/effect1",
					"earth", 1, 11, 22.0, false,
					left_position, Vector2(0.72, 0.72)
				)
				_play_archmage_earth_spike_audio()
				hero._damage_monsters_in_radius_once(
					left_position,
					radius,
					spike_damage,
					hit_ids,
					source_life,
					source_scope_id
				)

				if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
					break
				_spawn_archmage_fx(
					"res://assets/art/heroes/stage5_archmage/frames/effect1",
					"earth", 1, 11, 22.0, false,
					right_position, Vector2(0.72, 0.72)
				)
				_play_archmage_earth_spike_audio()
				hero._damage_monsters_in_radius_once(
					right_position,
					radius,
					spike_damage,
					hit_ids,
					source_life,
					source_scope_id
				)
				if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
					break
				await hero.COMBAT_DELAY.wait(hero,spike_delay)

	# Old tasks must not decrement a new life's casting counter.
	if hero._is_delayed_skill_life_current(source_life, source_scope_id):
		_end_archmage_casting_sequence()


func _find_archmage_holy_cluster_target(config: Dictionary) -> Node2D:
	var search_radius: float = maxf(
		float(config.get("cluster_search_radius", 850.0)),
		1.0
	)
	var cluster_radius: float = maxf(
		float(config.get("cluster_score_radius", 190.0)),
		1.0
	)
	var best: Node2D = null
	var best_count: int = -1
	var best_distance_sq: float = INF
	var search_radius_sq := search_radius * search_radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		search_radius,
		hero.archmage_query_candidates
	)

	for node in hero.archmage_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue

		var distance_sq: float = hero.global_position.distance_squared_to(
			monster.global_position
		)
		if distance_sq > search_radius_sq:
			continue

		var nearby_count: int = hero._count_monsters_near(
			monster.global_position,
			cluster_radius
		)
		if nearby_count > best_count:
			best = monster
			best_count = nearby_count
			best_distance_sq = distance_sq
		elif nearby_count == best_count and distance_sq < best_distance_sq:
			best = monster
			best_distance_sq = distance_sq

	hero.archmage_query_candidates.clear()
	return best


func _cast_archmage_holy_power(config: Dictionary, empowered: bool) -> void:
	var source_life := hero._capture_delayed_skill_source()
	if source_life.x < 0:
		return
	var source_scope_id := hero.get_parent().get_instance_id()
	var source_scope := hero.get_parent()
	var tracked_targets := source_scope.has_method("get_battle_entity_handle")
	_begin_archmage_casting_sequence()

	var cluster_target: Node2D = _find_archmage_holy_cluster_target(config)
	if not is_instance_valid(cluster_target):
		if hero._is_delayed_skill_life_current(source_life, source_scope_id):
			_end_archmage_casting_sequence()
		return

	var cast_center: Vector2 = cluster_target.global_position
	var count: int = maxi(int(config.get("burst_count", 7)), 1)
	var spawn_radius: float = maxf(
		float(config.get("burst_spawn_radius", 210.0)),
		1.0
	)
	var hit_radius: float = maxf(
		float(config.get("burst_hit_radius", 86.0)),
		1.0
	)
	var base_damage: int = maxi(1, int(round(
		float(hero.attack_damage)
		* float(config.get("damage_ratio", 0.90))
		* hero._skill_damage_multiplier(empowered)
	)))
	var hit_radius_sq := hit_radius * hit_radius

	for index in range(count):
		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break

		var angle: float = randf_range(0.0, TAU)
		var position: Vector2 = (
			cast_center
			+ Vector2.from_angle(angle) * randf_range(0.0, spawn_radius)
		)
		_spawn_archmage_fx(
			"res://assets/art/heroes/stage5_archmage/frames/effect3",
			"holy", 1, 5, 20.0, false, position, Vector2(0.94, 0.94)
		)
		_play_archmage_holy_burst_audio()

		hero._fill_monster_nodes_near(
			position,
			hit_radius,
			hero.archmage_query_candidates
		)
		for node in hero.archmage_query_candidates:
			if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
				break
			if not is_instance_valid(node):
				continue
			if not hero.HERO_TARGET_POLICY.is_detectable(node):
				continue
			var monster := node as Node2D
			if monster == null or not monster.has_method("take_damage"):
				continue
			if position.distance_squared_to(monster.global_position) > hit_radius_sq:
				continue

			var dealt: int = base_damage
			if hero.MONSTER_CATALOG.is_undead_node(monster):
				dealt = maxi(
					1,
					int(round(
						float(dealt)
						* float(config.get("undead_damage_multiplier", 1.70))
					))
				)

			# Capture a scalar handle only; damage callbacks may recycle this Node.
			var victim_handle := Vector3i.ZERO
			if tracked_targets:
				victim_handle = source_scope.call("get_battle_entity_handle", monster)
			preload("res://src/systems/monster_hit_context.gd").hit(monster, dealt, "ranged", hero)
			if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
				break
			if not is_instance_valid(monster) or monster.is_queued_for_deletion():
				continue
			if tracked_targets and (
				victim_handle == Vector3i.ZERO
				or source_scope.call("resolve_battle_entity", victim_handle) != monster
			):
				continue
			monster.set_meta(
				"gunner_slow_multiplier",
				clampf(
					float(config.get("slow_multiplier", 0.60)),
					0.0,
					1.0
				)
			)
			monster.set_meta(
				"gunner_slow_until",
				hero.COMBAT_DELAY.now_msec(hero)
				+ int(
					maxf(
						float(config.get("slow_duration", 2.0)),
						0.0
					) * 1000.0
				)
			)
		hero.archmage_query_candidates.clear()

		if not hero._is_delayed_skill_source_current(source_life, source_scope_id):
			break
		await hero.COMBAT_DELAY.wait(hero,
			maxf(float(config.get("burst_delay", 0.09)), 0.02)
		)

	if hero._is_delayed_skill_life_current(source_life, source_scope_id):
		_end_archmage_casting_sequence()


func _get_archmage_chain_dagger_targets(
	max_count: int,
	search_radius: float
) -> Array[Node2D]:
	hero.archmage_chain_target_candidates.clear()
	hero.archmage_chain_target_results.clear()
	var radius_sq := search_radius * search_radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		search_radius,
		hero.archmage_query_candidates
	)
	for node in hero.archmage_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or not monster.is_in_group("monsters")
			or hero.global_position.distance_squared_to(monster.global_position)
			> radius_sq
		):
			continue
		hero.archmage_chain_target_candidates.append(monster)
	hero.archmage_query_candidates.clear()

	if hero.archmage_chain_target_candidates.is_empty():
		return hero.archmage_chain_target_results

	if (
		hero.HERO_TARGET_POLICY.is_detectable(hero.target)
		and hero.target.is_in_group("monsters")
		and hero.global_position.distance_squared_to(hero.target.global_position)
		<= radius_sq
	):
		hero.archmage_chain_target_results.append(hero.target)

	while (
		hero.archmage_chain_target_results.size() < max_count
		and hero.archmage_chain_target_results.size()
		< hero.archmage_chain_target_candidates.size()
	):
		var best: Node2D = null
		var best_score := -INF
		for candidate in hero.archmage_chain_target_candidates:
			if candidate in hero.archmage_chain_target_results:
				continue
			var direction := hero.global_position.direction_to(
				candidate.global_position
			)
			if direction.length_squared() <= 0.001:
				continue

			var min_angle := PI
			if not hero.archmage_chain_target_results.is_empty():
				for chosen in hero.archmage_chain_target_results:
					var chosen_direction := hero.global_position.direction_to(
						chosen.global_position
					)
					min_angle = minf(
						min_angle,
						absf(direction.angle_to(chosen_direction))
					)

			var distance_ratio := clampf(
				hero.global_position.distance_to(candidate.global_position)
				/ maxf(search_radius, 1.0),
				0.0,
				1.0
			)
			# Prefer a wide fan first, then slightly favor nearer targets.
			var score := min_angle * 3.0 + (1.0 - distance_ratio) * 0.35
			if score > best_score:
				best_score = score
				best = candidate

		if not is_instance_valid(best):
			break
		hero.archmage_chain_target_results.append(best)

	if hero.archmage_chain_target_results.is_empty():
		hero.archmage_chain_target_results.append(
			hero.archmage_chain_target_candidates[0]
		)
	return hero.archmage_chain_target_results


func _cast_archmage_chain_dagger(config: Dictionary, empowered: bool) -> void:
	var projectile_range := maxf(
		float(config.get("projectile_range", 900.0)),
		1.0
	)
	var projectile_count := 1 + hero.archmage_chain_multithrow_stacks
	var targets := _get_archmage_chain_dagger_targets(
		projectile_count,
		projectile_range
	)
	if targets.is_empty():
		return

	hero.archmage_chain_dagger_active_count += targets.size()
	hero.archmage_chain_dagger_active = (
		hero.archmage_chain_dagger_active_count > 0
	)
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_chain_launch_audio)

	for current_target in targets:
		if not is_instance_valid(current_target):
			notify_archmage_chain_dagger_finished()
			continue
		var direction := hero.global_position.direction_to(
			current_target.global_position
		)
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT

		var projectile := hero._acquire_projectile(
			hero.ARCHMAGE_SKILL_PROJECTILE_SCENE,
			"archmage_chain_dagger_projectile"
		)
		if projectile == null:
			notify_archmage_chain_dagger_finished()
			continue
		if not projectile.is_in_group(
			"archmage_chain_dagger_projectile"
		):
			projectile.add_to_group(
				"archmage_chain_dagger_projectile"
			)
		projectile.global_position = (
			hero.global_position + direction.normalized() * 58.0
		)
		projectile.call(
			"setup",
			"chain_dagger",
			direction,
			maxi(
				1,
				int(
					round(
						float(hero.attack_damage)
						* float(config.get("damage_ratio", 1.0))
					)
				)
			),
			float(config.get("projectile_speed", 700.0)),
			projectile_range,
			config,
			hero,
			empowered,
			current_target
		)


func notify_archmage_chain_dagger_finished() -> void:
	hero.archmage_chain_dagger_active_count = maxi(
		hero.archmage_chain_dagger_active_count - 1,
		0
	)
	hero.archmage_chain_dagger_active = (
		hero.archmage_chain_dagger_active_count > 0
	)


func _archmage_is_surrounded_for_blink() -> bool:
	if hero.archmage_blink_stacks <= 0:
		return false
	return hero._count_monsters_near(
		hero.global_position,
		230.0,
		5
	) >= 5


func _archmage_blink_cooldown() -> float:
	return maxf(
		30.0 - float(maxi(hero.archmage_blink_stacks - 1, 0)) * 3.0,
		18.0
	)


func _cast_archmage_blink() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.archmage_blink_stacks <= 0:
		return

	var start_position := hero.global_position
	var repulsion := Vector2.ZERO
	hero._fill_monster_nodes_near(
		hero.global_position,
		460.0,
		hero.archmage_query_candidates
	)
	for node in hero.archmage_query_candidates:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		var offset := hero.global_position - monster.global_position
		var distance_sq := offset.length_squared()
		if distance_sq <= 0.001:
			continue
		repulsion += offset.normalized() / maxf(
			sqrt(distance_sq),
			1.0
		)
	hero.archmage_query_candidates.clear()

	var preferred := (
		repulsion.normalized()
		if repulsion.length_squared() > 0.001
		else Vector2.RIGHT
	)
	var best_position := start_position
	var best_score := INF
	var blink_distance := 700.0

	for index in range(20):
		var direction := Vector2.from_angle(
			TAU * float(index) / 20.0
		)
		var raw_target := start_position + direction * blink_distance
		var candidate := Vector2(
			clampf(
				raw_target.x,
				hero.FIELD_MARGIN,
				hero.battlefield_size.x - hero.FIELD_MARGIN
			),
			clampf(
				raw_target.y,
				hero.FIELD_MARGIN,
				hero.battlefield_size.y - hero.FIELD_MARGIN
			)
		)
		var actual_distance := start_position.distance_to(candidate)
		if actual_distance < 120.0:
			continue

		var nearby_count := hero._count_monsters_near(
			candidate,
			320.0
		)
		var alignment_penalty := (
			1.0 - direction.dot(preferred)
		) * 2.5
		var distance_loss := (
			blink_distance - actual_distance
		) / blink_distance
		var score := (
			float(nearby_count) * 100.0
			+ alignment_penalty
			+ distance_loss * 12.0
		)
		if score < best_score:
			best_score = score
			best_position = candidate

	if best_position == start_position:
		return

	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_blink_audio)
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect8",
		"wind",
		1,
		9,
		24.0,
		false,
		start_position,
		Vector2(0.86, 0.86)
	)
	hero.global_position = best_position
	hero.velocity = Vector2.ZERO
	hero._clamp_to_battlefield()
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect8",
		"wind",
		1,
		9,
		24.0,
		false,
		hero.global_position,
		Vector2(0.86, 0.86)
	)
	hero.archmage_blink_cooldown_timer = _archmage_blink_cooldown()


func _cast_archmage_harmony(config: Dictionary) -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_harmony_audio)
	for key in hero.ARCHMAGE_OFFENSIVE_SKILL_KEYS:
		hero.archmage_skill_cooldowns[key] = 0.0
	_add_archmage_gauge(maxf(float(config.get("gauge_refund", 50.0)), 0.0))
	_spawn_archmage_fx(
		"res://assets/art/heroes/stage5_archmage/frames/effect7",
		"orb", 8, 5, 16.0, false, hero.global_position, Vector2(0.82, 0.82)
	)


func _cast_archmage_storm(config: Dictionary, empowered: bool) -> void:
	_ensure_archmage_audio_runtime()
	_play_archmage_player(hero.archmage_storm_audio)
	for index in range(8):
		var direction := Vector2.from_angle(TAU * float(index) / 8.0)
		var projectile := hero._acquire_projectile(
			hero.ARCHMAGE_SKILL_PROJECTILE_SCENE,
			"archmage_skill_projectile"
		)
		if projectile == null:
			continue
		projectile.global_position = hero.global_position + direction * 56.0
		projectile.call(
			"setup", "storm", direction,
			maxi(1, int(round(float(hero.attack_damage) * float(config.get("damage_ratio", 0.75))))),
			float(config.get("projectile_speed", 350.0)),
			float(config.get("projectile_range", 950.0)),
			config, hero, empowered, null
		)


func _collect_archmage_element(element: String) -> void:
	if element.is_empty():
		return

	var already_owned := bool(
		hero.archmage_element_orbs.get(element, false)
	)
	hero.archmage_element_orbs[element] = true
	if not already_owned:
		hero.archmage_orbit_order.append(element)

	if (
		already_owned
		and hero.archmage_element_cycle_stacks > 0
		and randf() <= 0.25 * float(hero.archmage_element_cycle_stacks)
	):
		var missing: Array[String] = []
		for candidate in hero.ARCHMAGE_ORB_ELEMENTS:
			if not bool(hero.archmage_element_orbs.get(candidate, false)):
				missing.append(candidate)
		if not missing.is_empty():
			var granted := String(missing.pick_random())
			hero.archmage_element_orbs[granted] = true
			hero.archmage_orbit_order.append(granted)

	_refresh_archmage_orbit_visuals()


func _archmage_has_all_element_orbs() -> bool:
	for element in hero.ARCHMAGE_ORB_ELEMENTS:
		if not bool(hero.archmage_element_orbs.get(element, false)):
			return false
	return true


func _refresh_archmage_orbit_visuals() -> void:
	for element in hero.ARCHMAGE_ORB_ELEMENTS:
		var existing = hero.archmage_orbit_sprites.get(element)
		if is_instance_valid(existing):
			existing.visible = false

	if hero.hero_archetype != "archmage_elementalist":
		return

	for element in hero.archmage_orbit_order:
		if not bool(hero.archmage_element_orbs.get(element, false)):
			continue
		var frame_index := int(hero.ARCHMAGE_ORB_FRAME_INDEX.get(element, 0))
		if frame_index <= 0:
			continue

		var sprite := hero.archmage_orbit_sprites.get(element) as Sprite2D
		if not is_instance_valid(sprite):
			var texture := hero._load_stage1_texture(
				"res://assets/art/heroes/stage5_archmage/frames/effect6/orb_%02d.png" % frame_index
			)
			if texture == null:
				continue
			sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(0.20, 0.20)
			sprite.z_index = 8
			hero.add_child(sprite)
			hero.archmage_orbit_sprites[element] = sprite
		sprite.visible = true

	_update_archmage_orbit_positions()


func _update_archmage_orbit_positions() -> void:
	var count := 0
	for element in hero.archmage_orbit_order:
		if not bool(hero.archmage_element_orbs.get(element, false)):
			continue
		var sprite := hero.archmage_orbit_sprites.get(element) as Sprite2D
		if is_instance_valid(sprite) and sprite.visible:
			count += 1
	if count <= 0:
		return

	var index := 0
	for element in hero.archmage_orbit_order:
		if not bool(hero.archmage_element_orbs.get(element, false)):
			continue
		var sprite := hero.archmage_orbit_sprites.get(element) as Sprite2D
		if not is_instance_valid(sprite) or not sprite.visible:
			continue
		var angle := hero.archmage_orbit_angle + TAU * float(index) / float(count)
		sprite.position = Vector2.from_angle(angle) * 64.0 + Vector2(0.0, -8.0)
		index += 1


func _spawn_archmage_fx(
	dir: String,
	prefix: String,
	start: int,
	count: int,
	fps: float,
	looped: bool,
	world_position: Vector2,
	fx_scale: Vector2
) -> AnimatedSprite2D:
	var cache_key := "%s|%s|%d|%d|%.3f|%s" % [
		dir,
		prefix,
		start,
		count,
		fps,
		str(looped),
	]
	var cached = hero._archmage_fx_frames_cache.get(cache_key)
	var frames: SpriteFrames
	if cached is SpriteFrames:
		frames = cached
	else:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("fx")
		frames.set_animation_speed("fx", fps)
		frames.set_animation_loop("fx", looped)
		for index in range(start, start + count):
			var texture := hero._load_stage1_texture(
				"%s/%s_%02d.png" % [dir, prefix, index]
			)
			if texture != null:
				frames.add_frame("fx", texture)
		hero._archmage_fx_frames_cache[cache_key] = frames

	if frames.get_frame_count("fx") <= 0:
		return null

	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return null

	var fx: AnimatedSprite2D = null
	if parent.has_method("acquire_transient_fx"):
		fx = parent.call(
			"acquire_transient_fx",
			"archmage_cast_fx",
			"animated_sprite"
		) as AnimatedSprite2D
	if fx == null:
		fx = AnimatedSprite2D.new()
		parent.add_child(fx)

	# A pooled sprite may now belong to another delayed cast.
	fx.set_meta("archmage_cast_revision", int(fx.get_meta("archmage_cast_revision", 0)) + 1)
	fx.stop()
	fx.sprite_frames = frames
	fx.animation = &"fx"
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = 7
	fx.global_position = world_position
	fx.scale = fx_scale
	fx.rotation = 0.0
	fx.modulate = Color.WHITE
	fx.frame = 0
	fx.frame_progress = 0.0
	fx.visible = true

	if not looped:
		if parent.has_method("recycle_transient_fx"):
			fx.animation_finished.connect(
				Callable(parent, "recycle_transient_fx").bind(
					fx,
					"archmage_cast_fx"
				),
				Object.CONNECT_ONE_SHOT
			)
		else:
			fx.animation_finished.connect(
				Callable(fx, "queue_free"),
				Object.CONNECT_ONE_SHOT
			)

	fx.play(&"fx")
	return fx


func _recycle_archmage_fx_if_current(fx: AnimatedSprite2D, revision: int, scope_id: int) -> void:
	# Recycle only this playback, through its original parent, even after reparenting Hero.
	if not is_instance_valid(fx) or fx.is_queued_for_deletion() or not fx.visible:
		return
	if int(fx.get_meta("archmage_cast_revision", 0)) != revision:
		return
	var scope := fx.get_parent()
	if not is_instance_valid(scope) or scope.is_queued_for_deletion() or scope.get_instance_id() != scope_id:
		return
	if scope.has_method("recycle_transient_fx"):
		scope.call("recycle_transient_fx", fx, "archmage_cast_fx")
	else:
		fx.queue_free()


func _recycle_archmage_fx(fx: AnimatedSprite2D) -> void:
	if not is_instance_valid(fx):
		return
	var parent := hero.get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_transient_fx"):
		parent.call("recycle_transient_fx", fx, "archmage_cast_fx")
	else:
		fx.queue_free()


func _append_archmage_skill_hud(
	skills: Array,
	skill_key: String,
	icon_path: String
) -> void:
	var config: Dictionary = hero.archmage_skill_config.get(skill_key, {})
	if config.is_empty():
		return
	var cooldown_total := maxf(float(config.get("cooldown", 0.0)), 0.0)
	if cooldown_total <= 0.0:
		return
	var current_remaining := maxf(
		float(hero.archmage_skill_cooldowns.get(skill_key, 0.0)),
		0.0
	)
	skills.append({
		"id": String(config.get("id", skill_key)),
		"name": String(config.get("name", skill_key)),
		"description": hero._skill_hud_description(config),
		"resource_text": hero._skill_hud_resource_text(config),
		"status_text": "재사용 대기 중" if current_remaining > 0.01 else "사용 가능",
		"available": current_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": current_remaining,
		"icon_path": icon_path,
	})
