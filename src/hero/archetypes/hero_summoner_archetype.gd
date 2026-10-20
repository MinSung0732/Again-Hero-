extends RefCounted
## Summoner archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _get_summoner_slot_capacity() -> int:
	if hero.player_controlled and hero.player_weapons != null and hero.player_weapons.native_skills != null:
		return hero.player_weapons.native_skills.summon_capacity()
	return hero.HERO_SUMMONER_RUNTIME.get_slot_capacity(
		hero.summoner_slot_base,
		hero.summoner_slot_bonus,
		hero.level
	)


func _get_active_summoner_watcher_count() -> int:
	return hero.summoner_active_watchers


func _adjust_summoner_active_count(
	summon_kind: StringName,
	delta: int
) -> void:
	if delta == 0:
		return
	match summon_kind:
		&"gatekeeper":
			hero.summoner_active_gatekeepers = maxi(
				hero.summoner_active_gatekeepers + delta,
				0
			)
		&"scout":
			hero.summoner_active_scouts = maxi(
				hero.summoner_active_scouts + delta,
				0
			)
		&"hound":
			hero.summoner_active_hounds = maxi(
				hero.summoner_active_hounds + delta,
				0
			)
		&"watcher":
			hero.summoner_active_watchers = maxi(
				hero.summoner_active_watchers + delta,
				0
			)
		_:
			return
	hero.summoner_active_regular_count = (
		hero.summoner_active_gatekeepers
		+ hero.summoner_active_scouts
		+ hero.summoner_active_hounds
		+ hero.summoner_active_watchers
	)


func _get_summoner_watcher_max_active() -> int:
	return hero.HERO_SUMMONER_RUNTIME.get_watcher_max_active(
		hero.summoner_watcher_config,
		_get_summoner_augment_stacks("summoner_watcher_network")
	)


func _get_next_summoner_watcher_follow_slot() -> int:
	return hero.HERO_SUMMONER_RUNTIME.get_next_watcher_follow_slot(
		hero.summoner_watcher_pool,
		_get_summoner_watcher_max_active()
	)


func _ensure_summoner_pool_capacity() -> void:
	if hero.hero_archetype != "summoner_gatekeeper":
		return
	var world_parent := hero.get_parent()
	if not is_instance_valid(world_parent):
		return

	var pool_size := (
		_get_summoner_slot_capacity()
		+ hero.SUMMONER_POOL_HEADROOM
	)
	hero.HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		hero.summoner_gatekeeper_pool,
		hero.SUMMONER_GATEKEEPER_SCENE,
		pool_size,
		Callable(
			hero,
			"_on_summoner_gatekeeper_released"
		)
	)
	hero.HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		hero.summoner_scout_pool,
		hero.SUMMONER_SCOUT_SCENE,
		pool_size,
		Callable(
			hero,
			"_on_summoner_scout_released"
		)
	)
	hero.HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		hero.summoner_hound_pool,
		hero.SUMMONER_HOUND_SCENE,
		pool_size,
		Callable(
			hero,
			"_on_summoner_hound_released"
		)
	)

	hero.HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		hero.summoner_watcher_pool,
		hero.SUMMONER_WATCHER_SCENE,
		_get_summoner_watcher_max_active(),
		Callable(
			hero,
			"_on_summoner_watcher_released"
		)
	)

	var open_gate_pool_size := maxi(
		int(
			hero.summoner_open_gate_config.get(
				"pool_size",
				1
			)
		),
		0
	)
	hero.HERO_SUMMONER_RUNTIME.ensure_pool_capacity(
		world_parent,
		hero.summoner_open_gate_pool,
		hero.SUMMONER_OPEN_GATE_SCENE,
		open_gate_pool_size,
		Callable(
			hero,
			"_on_summoner_open_gate_released"
		),
		&"prepare_pool",
		hero.summoner_open_gate_config
	)


func _ensure_summoner_runtime() -> void:
	if hero.summoner_runtime_ready or hero.hero_archetype != "summoner_gatekeeper":
		return
	var world_parent := hero.get_parent()
	if not is_instance_valid(world_parent):
		return

	_ensure_summoner_pool_capacity()

	hero.summoner_basic_effect = AnimatedSprite2D.new()
	var effect_frames := SpriteFrames.new()
	if effect_frames.has_animation(&"default"):
		effect_frames.remove_animation(&"default")
	effect_frames.add_animation(&"cast")
	effect_frames.set_animation_loop(&"cast", false)
	effect_frames.set_animation_speed(&"cast", 10.0)
	var effect_dir := String(
		hero.summoner_config.get(
			"basic_effect_dir",
			"%s/effect2" % hero.STAGE8_FRAME_DIR
		)
	)
	for frame_index in range(1, 3):
		var texture := hero._load_stage1_texture(
			"%s/summon_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			effect_frames.add_frame(&"cast", texture)
	hero.summoner_basic_effect.sprite_frames = effect_frames
	hero.summoner_basic_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.summoner_basic_effect.scale = Vector2(0.46, 0.46)
	hero.summoner_basic_effect.position = Vector2(0.0, -18.0)
	hero.summoner_basic_effect.z_index = 7
	hero.summoner_basic_effect.visible = false
	hero.summoner_basic_effect.animation_finished.connect(
		Callable(hero, "_on_summoner_basic_effect_finished")
	)
	world_parent.add_child(hero.summoner_basic_effect)

	hero.summoner_basic_audio = AudioStreamPlayer.new()
	hero.summoner_basic_audio.bus = &"SFX"
	hero.summoner_basic_audio.volume_db = hero.SUMMONER_AUDIO.BASIC_DB
	hero.summoner_basic_audio.max_polyphony = 1
	var audio_path := String(
		hero.summoner_config.get(
			"basic_attack_audio_path",
			hero.SUMMONER_BASIC_ATTACK_AUDIO_PATH
		)
	)
	if ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream is AudioStream:
			hero.summoner_basic_audio.stream = stream
	hero.add_child(hero.summoner_basic_audio)

	hero.summoner_runtime_ready = (
		hero.HERO_SUMMONER_RUNTIME.are_runtime_pools_ready(
			hero.summoner_gatekeeper_pool,
			hero.summoner_scout_config,
			hero.summoner_scout_pool,
			hero.summoner_hound_config,
			hero.summoner_hound_pool,
			hero.summoner_watcher_config,
			hero.summoner_watcher_pool,
			hero.summoner_open_gate_config,
			hero.summoner_open_gate_pool
		)
	)
	if hero.summoner_runtime_ready:
		# Keep explicit requests alive until a pooled summon is actually acquired.
		hero.summoner_cast_pending = not hero.summoner_gatekeeper_config.is_empty()
		hero.summoner_scout_cast_pending = not hero.summoner_scout_config.is_empty()
		hero.summoner_hound_cast_pending = not hero.summoner_hound_config.is_empty()
		hero.summoner_watcher_cast_pending = not hero.summoner_watcher_config.is_empty()
		hero.summoner_open_gate_cast_pending = (
			not hero.summoner_open_gate_config.is_empty()
			and hero.summoner_open_gate_unlocked
		)
	hero.queue_redraw()


func _physics_process_summoner(delta: float) -> void:
	_ensure_summoner_runtime()

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
	hero.summoner_gatekeeper_cooldown = maxf(
		hero.summoner_gatekeeper_cooldown - delta,
		0.0
	)
	hero.summoner_scout_cooldown = maxf(
		hero.summoner_scout_cooldown - delta,
		0.0
	)
	hero.summoner_hound_cooldown = maxf(
		hero.summoner_hound_cooldown - delta,
		0.0
	)
	hero.summoner_watcher_cooldown = maxf(
		hero.summoner_watcher_cooldown - delta,
		0.0
	)
	hero.summoner_open_gate_cooldown = maxf(
		hero.summoner_open_gate_cooldown - delta,
		0.0
	)
	hero.summoner_cast_lock_timer = maxf(
		hero.summoner_cast_lock_timer - delta,
		0.0
	)
	_update_summoner_full_slot_shield(delta)
	hero._update_invulnerability(delta)

	if hero.slow_timer > 0.0:
		hero.slow_timer = maxf(hero.slow_timer - delta, 0.0)
		if hero.slow_timer <= 0.0:
			hero.move_multiplier = 1.0
			hero.queue_redraw()

	if hero.summoner_open_gate_unlocked and hero.summoner_open_gate_cooldown <= 0.0:
		hero.summoner_open_gate_cast_pending = true

	if hero._get_active_summon_count() < _get_summoner_slot_capacity():
		if hero.summoner_gatekeeper_cooldown <= 0.0:
			hero.summoner_cast_pending = true
		if hero.summoner_scout_cooldown <= 0.0:
			hero.summoner_scout_cast_pending = true
		if hero.summoner_hound_cooldown <= 0.0:
			hero.summoner_hound_cast_pending = true
		if (
			hero.summoner_watcher_cooldown <= 0.0
			and _get_active_summoner_watcher_count()
			< _get_summoner_watcher_max_active()
		):
			hero.summoner_watcher_cast_pending = true

	if hero.summoner_cast_lock_timer <= 0.0:
		var selected_summon := _choose_summoner_ai_cast()
		var summon_casted := _try_cast_summoner_ai_choice(selected_summon)
		if summon_casted:
			hero.summoner_ai_last_choice = selected_summon
			hero.summoner_ai_choice_counts[selected_summon] = (
				int(hero.summoner_ai_choice_counts.get(selected_summon, 0)) + 1
			)
			hero.summoner_cast_lock_timer = hero.summoner_cast_interval

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
		_move_summoner_without_monsters_near_open_gate()
		_update_summoner_pose_visual(delta)
		return

	var distance := hero.global_position.distance_to(hero.target.global_position)
	var move_direction := hero._choose_move_direction(hero.target, distance)
	move_direction = _apply_summoner_open_gate_tether(move_direction)
	move_direction = hero._apply_heal_item_steering(move_direction, delta)
	move_direction = hero._apply_chest_steering(move_direction, delta)
	move_direction = hero._apply_magnet_item_steering(move_direction, delta)
	move_direction = hero._apply_ranged_boundary_escape(move_direction)
	hero._execute_ai_movement(move_direction * hero.move_speed * hero._get_effective_move_multiplier())

	if distance <= hero.attack_range and hero.attack_timer <= 0.0:
		hero._execute_ai_basic_attack(hero.HERO_ACTION_INTENT.AttackKind.SUMMONER, hero.target)

	_update_summoner_pose_visual(delta)


func _roll_summoner_ai_personality() -> String:
	return hero.HERO_SUMMONER_RUNTIME.roll_ai_personality(
		hero.summoner_ai_config
	)


func _get_summoner_target_hp_ratio() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_target_hp_ratio(hero.target)


func _score_summoner_ai_candidate(
	skill_id: String,
	nearby_count: int
) -> float:
	var hero_hp_ratio := clampf(
		float(hero.current_hp) / float(maxi(hero.max_hp, 1)),
		0.0,
		1.0
	)
	var gatekeepers := hero.summoner_active_gatekeepers
	var scouts := hero.summoner_active_scouts
	var hounds := hero.summoner_active_hounds
	var watchers := hero.summoner_active_watchers
	return hero.HERO_SUMMONER_RUNTIME.score_ai_candidate(
		skill_id,
		nearby_count,
		hero_hp_ratio,
		is_instance_valid(hero.target),
		_get_summoner_target_hp_ratio(),
		gatekeepers,
		scouts,
		hounds,
		watchers,
		hero._get_active_summon_count(),
		int(hero.summoner_ai_choice_counts.get(skill_id, 0)),
		hero.summoner_ai_last_choice,
		hero.summoner_ai_personality,
		float(
			hero.summoner_ai_config.get(
				"random_score_span",
				8.0
			)
		)
	)


func _choose_summoner_ai_cast() -> String:
	var shared_slot_available := (
		hero._get_active_summon_count() < _get_summoner_slot_capacity()
	)
	var gatekeeper_available := (
		shared_slot_available
		and hero.summoner_cast_pending
		and hero.summoner_gatekeeper_cooldown <= 0.0
	)
	var scout_available := (
		shared_slot_available
		and hero.summoner_scout_cast_pending
		and hero.summoner_scout_cooldown <= 0.0
	)
	var hound_available := (
		shared_slot_available
		and hero.summoner_hound_cast_pending
		and hero.summoner_hound_cooldown <= 0.0
	)
	var watcher_available := (
		shared_slot_available
		and hero.summoner_watcher_cast_pending
		and hero.summoner_watcher_cooldown <= 0.0
		and _get_active_summoner_watcher_count() < _get_summoner_watcher_max_active()
	)
	var open_gate_available := (
		hero.summoner_open_gate_cast_pending
		and hero.summoner_open_gate_unlocked
		and hero.summoner_open_gate_cooldown <= 0.0
		and not is_instance_valid(_get_active_summoner_open_gate())
	)
	if not (
		gatekeeper_available
		or scout_available
		or hound_available
		or watcher_available
		or open_gate_available
	):
		return ""

	hero._fill_monster_nodes_near(
		hero.global_position,
		maxf(float(hero.summoner_ai_config.get("observation_radius", 760.0)), 1.0),
		hero.summoner_ai_query_candidates
	)
	var nearby_count := hero.summoner_ai_query_candidates.size()
	hero.summoner_ai_query_candidates.clear()
	var gatekeeper_weight := 0.0
	var scout_weight := 0.0
	var hound_weight := 0.0
	var watcher_weight := 0.0
	var open_gate_weight := 0.0
	var total_weight := 0.0

	if gatekeeper_available:
		gatekeeper_weight = pow(
			maxf(_score_summoner_ai_candidate("gatekeeper", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += gatekeeper_weight
	if scout_available:
		scout_weight = pow(
			maxf(_score_summoner_ai_candidate("scout", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += scout_weight
	if hound_available:
		hound_weight = pow(
			maxf(_score_summoner_ai_candidate("hound", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += hound_weight
	if watcher_available:
		watcher_weight = pow(
			maxf(_score_summoner_ai_candidate("watcher", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += watcher_weight
	if open_gate_available:
		open_gate_weight = pow(
			maxf(_score_summoner_ai_candidate("open_gate", nearby_count) - 25.0, 1.0),
			1.35
		)
		total_weight += open_gate_weight

	var roll := randf() * total_weight
	if gatekeeper_available:
		roll -= gatekeeper_weight
		if roll <= 0.0:
			return "gatekeeper"
	if scout_available:
		roll -= scout_weight
		if roll <= 0.0:
			return "scout"
	if hound_available:
		roll -= hound_weight
		if roll <= 0.0:
			return "hound"
	if watcher_available:
		roll -= watcher_weight
		if roll <= 0.0:
			return "watcher"
	if open_gate_available:
		roll -= open_gate_weight
		if roll <= 0.0:
			return "open_gate"

	if open_gate_available:
		return "open_gate"
	if watcher_available:
		return "watcher"
	if hound_available:
		return "hound"
	if scout_available:
		return "scout"
	return "gatekeeper"


func _try_cast_summoner_ai_choice(skill_id: String) -> bool:
	if hero.silence_timer > 0.0:
		return false
	match skill_id:
		"gatekeeper":
			if _try_cast_summoner_gatekeeper():
				hero.summoner_cast_pending = false
				return true
		"scout":
			if _try_cast_summoner_scout():
				hero.summoner_scout_cast_pending = false
				return true
		"hound":
			if _try_cast_summoner_hound():
				hero.summoner_hound_cast_pending = false
				return true
		"watcher":
			if _try_cast_summoner_watcher():
				hero.summoner_watcher_cast_pending = false
				return true
		"open_gate":
			if _try_cast_summoner_open_gate():
				hero.summoner_open_gate_cast_pending = false
				return true
	return false


func _get_active_summoner_open_gate() -> Node2D:
	for open_gate in hero.summoner_open_gate_pool:
		if is_instance_valid(open_gate) and bool(open_gate.get("active")):
			return open_gate
	return null


func _apply_summoner_open_gate_tether(move_direction: Vector2) -> Vector2:
	var open_gate := _get_active_summoner_open_gate()
	if not is_instance_valid(open_gate):
		return move_direction

	var preference_radius := maxf(
		float(hero.summoner_open_gate_config.get("hero_tether_radius", 650.0)),
		1.0
	)
	var influence_radius := maxf(
		float(hero.summoner_open_gate_config.get("hero_tether_hard_radius", 950.0)),
		preference_radius + 1.0
	)
	var distance := hero.global_position.distance_to(open_gate.global_position)
	if distance <= preference_radius:
		return move_direction

	# Gate proximity is only a soft tactical preference. It must never behave
	# like an invisible wall or override a useful combat target.
	var return_direction := hero.global_position.direction_to(open_gate.global_position)
	var distance_factor := clampf(
		(distance - preference_radius) / (influence_radius - preference_radius),
		0.0,
		1.0
	)
	var max_strength := clampf(
		float(hero.summoner_open_gate_config.get("hero_tether_max_strength", 0.28)),
		0.0,
		0.45
	)
	var strength := distance_factor * max_strength
	var blended := move_direction.lerp(return_direction, strength)
	return blended.normalized() if blended.length_squared() > 0.001 else move_direction


func _move_summoner_without_monsters_near_open_gate() -> void:
	# With no combat target, keep the normal wander behaviour. The open gate
	# influences combat positioning but never cages the hero around the portal.
	hero._move_without_monsters()


func _get_summoner_augment_stacks(augment_id: String) -> int:
	return hero.HERO_SUMMONER_RUNTIME.get_augment_stacks(
		hero.build_counts,
		augment_id
	)


func get_summoner_runtime_attack_speed_multiplier() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_runtime_attack_speed_multiplier(
		hero.shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_runtime_move_speed_multiplier() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_runtime_move_speed_multiplier(
		hero.shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_runtime_speed_multipliers() -> Dictionary:
	return hero.HERO_SUMMONER_RUNTIME.get_runtime_speed_multipliers(
		hero.shield_hp > 0.0,
		_get_summoner_augment_stacks(
			"summoner_shield_resonance"
		)
	)


func get_summoner_scout_attack_speed_multiplier() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_scout_swarm_attack_speed_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		hero.summoner_active_scouts
	)


func get_summoner_scout_damage_multiplier() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_scout_swarm_damage_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		hero.summoner_active_scouts
	)


func get_summoner_scout_move_speed_multiplier() -> float:
	return hero.HERO_SUMMONER_RUNTIME.get_scout_swarm_move_speed_multiplier(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		hero.summoner_active_scouts
	)


func get_summoner_scout_swarm_multipliers() -> Dictionary:
	return hero.HERO_SUMMONER_RUNTIME.get_scout_swarm_multipliers(
		_get_summoner_augment_stacks(
			"summoner_scout_swarm_tactics"
		),
		hero.summoner_active_scouts
	)


func _update_summoner_full_slot_shield(delta: float) -> void:
	if hero.summoner_full_slot_shield_config.is_empty():
		return

	hero.summoner_full_slot_shield_cooldown = maxf(
		hero.summoner_full_slot_shield_cooldown - delta,
		0.0
	)

	if hero.shield_duration_timer > 0.0:
		hero.shield_duration_timer = maxf(hero.shield_duration_timer - delta, 0.0)
		if hero.shield_duration_timer <= 0.0 and hero.shield_hp > 0.0:
			hero._end_shield()

	if hero.summoner_full_slot_shield_cooldown > 0.0:
		return
	if hero._get_active_summon_count() < _get_summoner_slot_capacity():
		return

	var shield_fortify_stacks := _get_summoner_augment_stacks("summoner_shield_fortify")
	var shield_ratio := clampf(
		float(hero.summoner_full_slot_shield_config.get("shield_hp_ratio", 0.15))
		+ float(shield_fortify_stacks) * 0.014,
		0.0,
		1.0
	)
	var refreshed_shield := float(hero.max_hp) * shield_ratio
	if refreshed_shield <= 0.0:
		return

	# Refresh-type passive: replace remaining shield amount and duration.
	hero.shield_max_hp = hero._player_shield_amount(refreshed_shield)
	hero.shield_hp = hero.shield_max_hp
	hero.shield_duration_timer = maxf(
		float(hero.summoner_full_slot_shield_config.get("duration", 8.0))
		+ float(shield_fortify_stacks) * 0.4,
		0.0
	)
	hero.summoner_full_slot_shield_cooldown = maxf(
		float(hero.summoner_full_slot_shield_config.get("cooldown", 40.0)),
		0.0
	)
	hero.queue_redraw()


func _try_cast_summoner_gatekeeper() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.summoner_gatekeeper_config.is_empty():
		return false
	if hero.summoner_gatekeeper_cooldown > 0.0:
		return false
	if hero._get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			hero.summoner_gatekeeper_pool
		)
	)
	if summon_to_use == null:
		return false

	var runtime_config := (
		hero.HERO_SUMMONER_RUNTIME.build_gatekeeper_runtime_config(
			hero.summoner_gatekeeper_config,
			hero.attack_damage,
			_get_summoner_augment_stacks(
				"summoner_gatekeeper_fortress"
			),
			_get_summoner_augment_stacks(
				"summoner_gatekeeper_barrage"
			)
		)
	)
	if not hero.HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		hero.global_position,
		hero,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"gatekeeper", 1)
	hero._set_summon_registry_active(summon_to_use, true)
	hero.summoner_gatekeeper_cooldown = maxf(
		float(hero.summoner_gatekeeper_config.get("cooldown", 10.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	hero.queue_redraw()
	return true


func _on_summoner_gatekeeper_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"gatekeeper", -1)
	hero._refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_scout() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.summoner_scout_config.is_empty():
		return false
	if hero.summoner_scout_cooldown > 0.0:
		return false
	if hero._get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			hero.summoner_scout_pool
		)
	)
	if summon_to_use == null:
		_ensure_summoner_pool_capacity()
		summon_to_use = (
			hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
				hero.summoner_scout_pool
			)
		)
	if summon_to_use == null:
		return false

	var runtime_config := (
		hero.HERO_SUMMONER_RUNTIME.build_scout_runtime_config(
			hero.summoner_scout_config,
			hero.attack_damage,
			_get_summoner_augment_stacks(
				"summoner_scout_reinforcement"
			)
		)
	)
	if not hero.HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		hero.global_position,
		hero,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"scout", 1)
	hero._set_summon_registry_active(summon_to_use, true)
	hero.summoner_scout_cooldown = maxf(
		float(hero.summoner_scout_config.get("cooldown", 20.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	hero.queue_redraw()
	return true


func _on_summoner_scout_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"scout", -1)
	hero._refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_hound() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.summoner_hound_config.is_empty():
		return false
	if hero.summoner_hound_cooldown > 0.0:
		return false
	if hero._get_active_summon_count() >= _get_summoner_slot_capacity():
		return false

	var summon_to_use := (
		hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			hero.summoner_hound_pool
		)
	)
	if summon_to_use == null:
		_ensure_summoner_pool_capacity()
		summon_to_use = (
			hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
				hero.summoner_hound_pool
			)
		)
	if summon_to_use == null:
		return false

	var runtime_config := (
		hero.HERO_SUMMONER_RUNTIME.build_hound_runtime_config(
			hero.summoner_hound_config,
			hero.attack_damage,
			_get_summoner_augment_stacks(
				"summoner_hound_frenzy"
			),
			_get_summoner_augment_stacks(
				"summoner_hound_blood_track"
			)
		)
	)
	if not hero.HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		hero.global_position,
		hero,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"hound", 1)
	hero._set_summon_registry_active(summon_to_use, true)
	hero.summoner_hound_cooldown = maxf(
		float(hero.summoner_hound_config.get("cooldown", 30.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	hero.queue_redraw()
	return true


func _on_summoner_hound_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"hound", -1)
	hero._refresh_regular_summon_pending_after_release(_summon)


func _try_cast_summoner_watcher() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.summoner_watcher_config.is_empty():
		return false
	if hero.summoner_watcher_cooldown > 0.0:
		return false
	if hero._get_active_summon_count() >= _get_summoner_slot_capacity():
		return false
	if (
		_get_active_summoner_watcher_count()
		>= _get_summoner_watcher_max_active()
	):
		return false

	var follow_slot := _get_next_summoner_watcher_follow_slot()
	if follow_slot < 0:
		return false

	var summon_to_use := (
		hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			hero.summoner_watcher_pool
		)
	)
	if summon_to_use == null:
		return false

	var runtime_config := (
		hero.HERO_SUMMONER_RUNTIME.build_watcher_runtime_config(
			hero.summoner_watcher_config,
			hero.attack_damage,
			_get_summoner_augment_stacks(
				"summoner_watcher_focus"
			),
			_get_summoner_augment_stacks(
				"summoner_watcher_network"
			),
			follow_slot
		)
	)
	if not hero.HERO_SUMMONER_RUNTIME.activate_summon(
		summon_to_use,
		hero.global_position,
		hero,
		runtime_config
	):
		return false
	_adjust_summoner_active_count(&"watcher", 1)
	hero._set_summon_registry_active(summon_to_use, true)
	hero.summoner_watcher_cooldown = maxf(
		float(hero.summoner_watcher_config.get("cooldown", 7.0)),
		0.0
	)
	_record_summoner_spawn_for_open_gate_unlock()
	hero.queue_redraw()
	return true


func _on_summoner_watcher_released(_summon: Node2D) -> void:
	_adjust_summoner_active_count(&"watcher", -1)
	hero._refresh_regular_summon_pending_after_release(_summon)


func _get_summoner_open_gate_required_summons() -> int:
	return hero.HERO_SUMMONER_RUNTIME.get_open_gate_required_summons(
		hero.summoner_open_gate_config
	)


func _record_summoner_spawn_for_open_gate_unlock() -> void:
	if hero.summoner_open_gate_config.is_empty() or hero.summoner_open_gate_unlocked:
		return
	hero.summoner_total_summons += 1
	var required := _get_summoner_open_gate_required_summons()
	if not hero.HERO_SUMMONER_RUNTIME.has_reached_open_gate_unlock(
		hero.summoner_open_gate_config,
		hero.summoner_open_gate_unlocked,
		hero.summoner_total_summons
	):
		return

	hero.summoner_open_gate_unlocked = true
	hero.summoner_open_gate_cast_pending = true
	hero._unlock_conditional_skill(
		String(hero.summoner_open_gate_config.get("id", "summoner_open_gate")),
		String(hero.summoner_open_gate_config.get("name", "이계의 문 - 개방")),
		"summon_count",
		hero.summoner_total_summons,
		required,
		{
			"hero_id": hero.hero_id,
			"archetype": hero.hero_archetype,
			"source": "summoner_spawn_count",
			"cutscene_texture_path": String(
				hero.summoner_open_gate_config.get("cutscene_texture_path", "")
			),
			"cutscene_hold_seconds": float(
				hero.summoner_open_gate_config.get("cutscene_hold_seconds", 1.05)
			),
		}
	)


func _try_cast_summoner_open_gate() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if hero.summoner_open_gate_config.is_empty():
		return false
	if not hero.summoner_open_gate_unlocked:
		return false
	if hero.summoner_open_gate_cooldown > 0.0:
		return false

	var gate_to_use := (
		hero.HERO_SUMMONER_RUNTIME.acquire_inactive_summon(
			hero.summoner_open_gate_pool
		)
	)
	if gate_to_use == null:
		return false

	if not hero.HERO_SUMMONER_RUNTIME.activate_summon(
		gate_to_use,
		hero.global_position,
		hero,
		hero.summoner_open_gate_config.duplicate(true)
	):
		return false
	hero._set_summon_registry_active(gate_to_use, true)
	hero.summoner_open_gate_cooldown = maxf(
		float(hero.summoner_open_gate_config.get("cooldown", 100.0)),
		0.0
	)
	hero.queue_redraw()
	return true


func _on_summoner_open_gate_released(_open_gate: Node2D) -> void:
	hero._set_summon_registry_active(_open_gate, false)
	if hero.summoner_open_gate_cooldown <= 0.0:
		hero.summoner_open_gate_cast_pending = true
	hero.queue_redraw()


func _summoner_basic_attack(current_target: Node2D) -> void:
	if not is_instance_valid(current_target):
		return
	hero.attack_timer = hero._get_common_attack_interval(hero.attack_cooldown)
	hero.attack_pose_timer = 0.38
	hero._face_attack_direction(
		current_target.global_position.x - hero.global_position.x
	)
	hero._apply_stage8_sprite_anchor()
	hero._restart_stage1_animation("attack", 1.0)

	if is_instance_valid(hero.summoner_basic_effect):
		# effect2 summon_01~02 is impact feedback for this hitscan attack.
		# Keep it in world space at the monster's feet/root instead of on caster.
		hero.summoner_basic_effect.global_position = current_target.global_position
		hero.summoner_basic_effect.flip_h = false
		hero.summoner_basic_effect.stop()
		hero.summoner_basic_effect.frame = 0
		hero.summoner_basic_effect.visible = true
		hero.summoner_basic_effect.play(&"cast")
	if (
		is_instance_valid(hero.summoner_basic_audio)
		and hero.summoner_basic_audio.stream != null
		and not hero.summoner_basic_audio.playing
		and hero.COMBAT_DELAY.now_msec(hero) >= hero.summoner_basic_audio_next_ms
	):
		hero.summoner_basic_audio_next_ms = hero.COMBAT_DELAY.now_msec(hero)+hero.SUMMONER_AUDIO.BASIC_INTERVAL_MS
		hero.summoner_basic_audio.play()

	# Hitscan: damage is decided immediately; the summon_01~02 frames are
	# feedback only, keeping combat state easy to make server-authoritative.
	if current_target.has_method("take_damage"):
		preload("res://src/systems/monster_hit_context.gd").hit(current_target, maxi(hero.attack_damage, 1), "ranged", hero)


func _on_summoner_basic_effect_finished() -> void:
	if is_instance_valid(hero.summoner_basic_effect):
		hero.summoner_basic_effect.visible = false


func _update_summoner_pose_visual(delta: float) -> void:
	if not hero.hero_sprite.visible or hero.is_dying:
		return
	if hero.hit_pose_timer > 0.0 or hero.attack_pose_timer > 0.0:
		return

	hero._update_facing_from_horizontal(hero.velocity.x, delta)
	hero._apply_stage8_sprite_anchor()
	if hero.velocity.length() > 4.0:
		var movement_ratio := hero.velocity.length() / maxf(hero.move_speed, 1.0)
		hero._play_stage1_animation(
			"move",
			clampf(movement_ratio, 0.72, 1.35)
		)
	else:
		hero._play_stage1_animation("idle", 1.0)


func _append_summoner_open_gate_hud(skills: Array) -> void:
	if hero.summoner_open_gate_config.is_empty():
		return
	var required := maxi(_get_summoner_open_gate_required_summons(), 1)
	var cooldown_total := maxf(
		float(hero.summoner_open_gate_config.get("cooldown", 100.0)),
		0.0
	)
	var cooldown_remaining := maxf(hero.summoner_open_gate_cooldown, 0.0)
	var status := "사용 조건 대기"
	if hero.summoner_open_gate_unlocked:
		status = (
			"재사용 대기 중"
			if cooldown_remaining > 0.01
			else "사용 가능"
		)
	skills.append({
		"id": String(hero.summoner_open_gate_config.get("id", "summoner_open_gate")),
		"name": String(hero.summoner_open_gate_config.get("name", "이계의 문 - 개방")),
		"description": hero._skill_hud_description(hero.summoner_open_gate_config),
		"progress_text": (
			"누적 소환 %d / %d"
			% [mini(hero.summoner_total_summons, required), required]
		),
		"status_text": status,
		"available": hero.summoner_open_gate_unlocked and cooldown_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": (
			cooldown_remaining
			if hero.summoner_open_gate_unlocked
			else cooldown_total
		),
		"icon_path": "res://assets/art/heroes/stage8_summoner/frames/effect5/effect_06.png",
	})


func _get_summoner_augment_ai_settings() -> Dictionary:
	if hero.hero_archetype != "summoner_gatekeeper":
		return hero.ai_settings.duplicate(true)
	return hero.HERO_SUMMONER_RUNTIME.build_augment_ai_settings(
		hero.ai_settings,
		hero.summoner_ai_choice_counts,
		hero._get_active_summon_count(),
		_get_summoner_slot_capacity()
	)
