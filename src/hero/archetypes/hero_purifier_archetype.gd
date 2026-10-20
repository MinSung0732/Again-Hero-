extends RefCounted
## Purifier archetype behaviour moved verbatim from hero.gd. State stays on the hero
## (method bindings, HUD, presentation and tests read it there); hero members
## are reached through `hero`. hero.gd keeps same-signature forwarders.

const HERO_SCRIPT := preload("res://src/hero/hero.gd")

var hero: HERO_SCRIPT


func _init(owner: HERO_SCRIPT) -> void:
	hero = owner


func _ensure_purifier_basic_audio() -> void:
	if hero.hero_archetype != "cleric_purifier":
		return
	if is_instance_valid(hero.purifier_basic_audio):
		return

	hero.purifier_basic_audio = AudioStreamPlayer.new()
	hero.purifier_basic_audio.bus = &"SFX"
	hero.purifier_basic_audio.volume_db = -13.0
	# The source is a broader elemental projectile sound. A slightly higher
	# pitch keeps the purifier version brighter and distinct from Stage 8.
	hero.purifier_basic_audio.pitch_scale = 1.12
	if ResourceLoader.exists(hero.PURIFIER_BASIC_ATTACK_AUDIO_PATH):
		var stream = load(hero.PURIFIER_BASIC_ATTACK_AUDIO_PATH)
		if stream is AudioStream:
			hero.purifier_basic_audio.stream = stream
	hero.add_child(hero.purifier_basic_audio)


func _play_purifier_basic_audio() -> void:
	_ensure_purifier_basic_audio()
	if (
		is_instance_valid(hero.purifier_basic_audio)
		and hero.purifier_basic_audio.stream != null
	):
		# One player per hero; restarting avoids overlapping a long tail every
		# 1.35s while keeping allocation-free repeated basic attacks.
		hero.purifier_basic_audio.stop()
		hero.purifier_basic_audio.play()


func _build_purifier_effect_frames(
	effect_dir: String,
	start_first: int,
	start_last: int,
	sustain_first: int,
	sustain_last: int,
	end_first: int,
	end_last: int
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"start")
	frames.set_animation_loop(&"start", false)
	frames.set_animation_speed(&"start", 10.0)
	for frame_index in range(start_first, start_last + 1):
		var texture := hero._load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"start", texture)

	frames.add_animation(&"sustain")
	frames.set_animation_loop(&"sustain", true)
	frames.set_animation_speed(&"sustain", 7.0)
	for frame_index in range(sustain_first, sustain_last + 1):
		var texture := hero._load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"sustain", texture)

	frames.add_animation(&"end")
	frames.set_animation_loop(&"end", false)
	frames.set_animation_speed(&"end", 10.0)
	for frame_index in range(end_first, end_last + 1):
		var texture := hero._load_stage1_texture(
			"%s/effect_%02d.png" % [effect_dir, frame_index]
		)
		if texture != null:
			frames.add_frame(&"end", texture)
	return frames


func _create_purifier_audio_player(
	audio_path: String,
	volume_db: float,
	pitch_scale: float = 1.0
) -> AudioStreamPlayer:
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


func _ensure_purifier_skill_runtime() -> void:
	if hero.hero_archetype != "cleric_purifier":
		return

	if not is_instance_valid(hero.purifier_protection_effect):
		if hero._purifier_protection_frames_cache == null:
			var effect_dir := String(
				hero.purifier_protection_config.get(
					"effect_dir",
					"%s/effect4" % hero.STAGE9_FRAME_DIR
				)
			)
			hero._purifier_protection_frames_cache = _build_purifier_effect_frames(
				effect_dir, 23, 24, 24, 26, 27, 28
			)
		hero.purifier_protection_effect = AnimatedSprite2D.new()
		hero.purifier_protection_effect.sprite_frames = hero._purifier_protection_frames_cache
		hero.purifier_protection_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hero.purifier_protection_effect.scale = hero.hero_sprite.scale
		# Divine Protection should stay readable without covering the hero body.
		# self_modulate keeps the effect at a consistent 50% opacity.
		hero.purifier_protection_effect.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		hero.purifier_protection_effect.offset = Vector2(16.0, -24.0)
		hero.purifier_protection_effect.z_index = 8
		hero.purifier_protection_effect.visible = false
		hero.purifier_protection_effect.animation_finished.connect(
			Callable(hero, "_on_purifier_protection_effect_finished")
		)
		hero.add_child(hero.purifier_protection_effect)

	if not is_instance_valid(hero.purifier_crown_effect):
		if hero._purifier_crown_frames_cache == null:
			var effect_dir := String(
				hero.purifier_crown_config.get(
					"effect_dir",
					"%s/effect3" % hero.STAGE9_FRAME_DIR
				)
			)
			hero._purifier_crown_frames_cache = _build_purifier_effect_frames(
				effect_dir, 17, 18, 19, 20, 21, 22
			)
		hero.purifier_crown_effect = AnimatedSprite2D.new()
		hero.purifier_crown_effect.sprite_frames = hero._purifier_crown_frames_cache
		hero.purifier_crown_effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# The raw effect3 crown is visually larger than the Stage 9 head.
		# Keep it compact and attached to the same horizontal visual anchor as
		# the animated hero frames so it does not drift a few pixels per frame.
		hero.purifier_crown_effect.scale = hero.hero_sprite.scale * 0.78
		# Center the crown on the gameplay/root X, then place it directly above
		# the head. Demon Castle Y-sort normalizes HeroSprite to z=0 after _ready().
		# Keep the crown on that same behind-parent layer: HeroSprite is an earlier
		# child, so Crown draws over the body, while Hero._draw() bars stay on top.
		hero.purifier_crown_effect.offset = Vector2(0.0, -24.0)
		hero.purifier_crown_effect.position = Vector2(0.0, -36.0)
		hero.purifier_crown_effect.show_behind_parent = true
		hero.purifier_crown_effect.z_index = 0
		hero.purifier_crown_effect.visible = false
		hero.purifier_crown_effect.animation_finished.connect(
			Callable(hero, "_on_purifier_crown_effect_finished")
		)
		hero.add_child(hero.purifier_crown_effect)

	if not is_instance_valid(hero.purifier_shield_create_audio):
		hero.purifier_shield_create_audio = _create_purifier_audio_player(
			String(hero.purifier_protection_config.get(
				"create_audio_path",
				hero.PURIFIER_SHIELD_CREATE_AUDIO_PATH
			)),
			-12.0,
			1.08
		)
	if not is_instance_valid(hero.purifier_shield_break_audio):
		hero.purifier_shield_break_audio = _create_purifier_audio_player(
			String(hero.purifier_protection_config.get(
				"break_audio_path",
				hero.PURIFIER_SHIELD_BREAK_AUDIO_PATH
			)),
			-11.0,
			0.82
		)
	if not is_instance_valid(hero.purifier_crown_audio):
		hero.purifier_crown_audio = _create_purifier_audio_player(
			String(hero.purifier_crown_config.get(
				"audio_path",
				hero.PURIFIER_CROWN_AUDIO_PATH
			)),
			-13.0,
			1.12
		)
	if not is_instance_valid(hero.purifier_orb_create_audio):
		hero.purifier_orb_create_audio = _create_purifier_audio_player(
			String(hero.purifier_orb_config.get(
				"create_audio_path",
				hero.PURIFIER_ORB_CREATE_AUDIO_PATH
			)),
			-12.0,
			1.04
		)
	if not is_instance_valid(hero.purifier_orb_explosion_audio):
		hero.purifier_orb_explosion_audio = _create_purifier_audio_player(
			String(hero.purifier_orb_config.get(
				"explosion_audio_path",
				hero.PURIFIER_ORB_EXPLOSION_AUDIO_PATH
			)),
			-10.0,
			0.96
		)
	if not is_instance_valid(hero.purifier_cleansing_audio):
		hero.purifier_cleansing_audio = _create_purifier_audio_player(
			String(hero.purifier_cleansing_config.get(
				"audio_path",
				hero.PURIFIER_CLEANSING_AUDIO_PATH
			)),
			-12.0,
			1.18
		)
	if not is_instance_valid(hero.purifier_gungnir_charge_audio):
		hero.purifier_gungnir_charge_audio = _create_purifier_audio_player(
			String(hero.purifier_gungnir_config.get(
				"charge_audio_path",
				hero.PURIFIER_GUNGNIR_CHARGE_AUDIO_PATH
			)),
			-10.0,
			1.05
		)
	if not is_instance_valid(hero.purifier_gungnir_flight_audio):
		hero.purifier_gungnir_flight_audio = _create_purifier_audio_player(
			String(hero.purifier_gungnir_config.get(
				"flight_audio_path",
				hero.PURIFIER_GUNGNIR_FLIGHT_AUDIO_PATH
			)),
			-9.0,
			1.12
		)
	if not is_instance_valid(hero.purifier_gungnir_explosion_audio):
		hero.purifier_gungnir_explosion_audio = _create_purifier_audio_player(
			String(hero.purifier_gungnir_config.get(
				"explosion_audio_path",
				hero.PURIFIER_GUNGNIR_EXPLOSION_AUDIO_PATH
			)),
			-8.0,
			0.78
		)


func _play_purifier_audio(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player) or player.stream == null:
		return
	player.stop()
	player.play()


func _on_purifier_protection_effect_finished() -> void:
	if not is_instance_valid(hero.purifier_protection_effect):
		return
	if hero.purifier_protection_effect.animation == &"start":
		if hero.purifier_protection_active:
			hero.purifier_protection_effect.play(&"sustain")
		else:
			hero.purifier_protection_effect.visible = false
	elif hero.purifier_protection_effect.animation == &"end":
		hero.purifier_protection_effect.visible = false


func _on_purifier_crown_effect_finished() -> void:
	if not is_instance_valid(hero.purifier_crown_effect):
		return
	if hero.purifier_crown_effect.animation == &"start":
		if hero.purifier_crown_stacks > 0:
			hero.purifier_crown_effect.play(&"sustain")
		else:
			hero.purifier_crown_effect.visible = false
	elif hero.purifier_crown_effect.animation == &"end":
		hero.purifier_crown_effect.visible = false


func _play_purifier_effect(effect: AnimatedSprite2D, animation_name: StringName) -> void:
	if (
		not is_instance_valid(effect)
		or effect.sprite_frames == null
		or not effect.sprite_frames.has_animation(animation_name)
		or effect.sprite_frames.get_frame_count(animation_name) <= 0
	):
		return
	effect.visible = true
	effect.stop()
	effect.animation = animation_name
	effect.frame = 0
	effect.frame_progress = 0.0
	effect.play(animation_name)


func _get_purifier_augment_stacks(augment_id: String) -> int:
	if hero.hero_archetype != "cleric_purifier":
		return 0
	return maxi(int(hero.build_counts.get(augment_id, 0)), 0)


func _get_purifier_crown_effect_multiplier() -> float:
	return (
		0.85
		if _get_purifier_augment_stacks("purifier_radiant_crown") > 0
		else 1.0
	)


func _get_purifier_crown_max_stacks() -> int:
	return maxi(
		int(hero.purifier_crown_config.get("max_stacks", 5))
		+ _get_purifier_augment_stacks("purifier_radiant_crown"),
		1
	)


func _get_purifier_orb_damage_multiplier() -> float:
	return (
		0.50
		if _get_purifier_augment_stacks("purifier_book_of_purification") > 0
		else 1.0
	)


func _get_purifier_orb_range_multiplier() -> float:
	return (
		0.50
		if _get_purifier_augment_stacks("purifier_book_of_purification") > 0
		else 1.0
	)


func _get_purifier_orb_explosion_radius() -> float:
	return maxf(
		float(hero.purifier_orb_config.get("explosion_radius", 137.5))
		* _get_purifier_orb_range_multiplier(),
		1.0
	)


func _get_purifier_skill_cooldown_multiplier() -> float:
	if hero.hero_archetype != "cleric_purifier" or hero.purifier_crown_stacks <= 0:
		return 1.0
	return maxf(
		1.0
		- float(hero.purifier_crown_config.get("cooldown_reduction_per_stack", 0.04))
		* _get_purifier_crown_effect_multiplier()
		* float(hero.purifier_crown_stacks),
		0.20
	)


func _get_purifier_move_speed_multiplier() -> float:
	var multiplier := 1.0
	if hero.hero_archetype == "cleric_purifier" and hero.purifier_crown_stacks > 0:
		multiplier *= 1.0 + maxf(
			float(hero.purifier_crown_config.get("move_speed_per_stack", 0.02)),
			0.0
		) * _get_purifier_crown_effect_multiplier() * float(hero.purifier_crown_stacks)
	if hero.hero_archetype == "grand_sage_astra" and hero.sage_phase_active:
		multiplier *= maxf(
			float(hero.sage_config.get("phase_move_speed_multiplier", 1.40)),
			1.0
		)
	return multiplier


func _is_purifier_undead_target(target_node: Node) -> bool:
	return hero.MONSTER_CATALOG.is_undead_node(target_node)


func get_purifier_holy_damage_multiplier(target_node: Node = null) -> float:
	if hero.hero_archetype != "cleric_purifier":
		return 1.0
	var crown_effect_multiplier := _get_purifier_crown_effect_multiplier()
	var multiplier := (
		1.0
		+ maxf(
			float(hero.purifier_crown_config.get("holy_damage_per_stack", 0.05)),
			0.0
		) * crown_effect_multiplier * float(hero.purifier_crown_stacks)
	)
	if hero.shield_hp > 0.0:
		multiplier *= maxf(
			float(hero.purifier_protection_config.get("holy_damage_multiplier", 1.15)),
			0.0
		)
	if _is_purifier_undead_target(target_node):
		multiplier *= (
			1.0
			+ maxf(
				float(hero.purifier_crown_config.get("undead_damage_per_stack", 0.10)),
				0.0
			) * crown_effect_multiplier * float(hero.purifier_crown_stacks)
		)
	var broken_sanctuary_stacks := _get_purifier_augment_stacks(
		"purifier_broken_sanctuary"
	)
	if broken_sanctuary_stacks > 0 and hero.purifier_broken_sanctuary_timer > 0.0:
		multiplier *= 1.0 + 0.06 * float(broken_sanctuary_stacks)
	return multiplier


func _add_purifier_shield_layer() -> void:
	var layer_amount := maxf(
		float(hero.max_hp)
		* maxf(
			float(hero.purifier_protection_config.get("shield_hp_ratio_per_tick", 0.01)),
			0.0
		),
		1.0
	)
	layer_amount = hero._player_shield_amount(layer_amount)
	hero.shield_max_hp += layer_amount
	hero.shield_hp += layer_amount
	hero.queue_redraw()


func _try_activate_purifier_protection() -> void:
	if hero.silence_timer > 0.0:
		return
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_protection_config.is_empty()
		or hero.purifier_protection_active
		or hero.purifier_protection_cooldown > 0.0
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return
	var gauge_max := maxf(
		float(hero.purifier_gauge_config.get("charge_max", 100.0)),
		1.0
	)
	if hero.ultimate_charge + 0.001 < gauge_max:
		return

	hero.ultimate_charge = 0.0
	hero.purifier_protection_active = true
	hero.purifier_protection_break_triggered = false
	hero.purifier_protection_duration_timer = maxf(
		float(hero.purifier_protection_config.get("duration", 20.0)),
		0.1
	)
	hero.purifier_protection_tick_timer = maxf(
		float(hero.purifier_protection_config.get("shield_tick_interval", 1.0)),
		0.05
	)
	hero.purifier_protection_cooldown = (
		maxf(float(hero.purifier_protection_config.get("cooldown", 30.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	hero.shield_hp = 0.0
	hero.shield_max_hp = 0.0
	_add_purifier_shield_layer()
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(hero.purifier_protection_effect, &"start")
	_play_purifier_audio(hero.purifier_shield_create_audio)
	hero.queue_redraw()


func _trigger_purifier_protection_break_pulse() -> void:
	var radius := maxf(
		float(hero.purifier_protection_config.get("break_radius", 240.0)),
		0.0
	)
	if radius <= 0.0:
		return
	var knockback := maxf(
		float(hero.purifier_protection_config.get("break_knockback", 135.0)),
		0.0
	)
	var slow_multiplier := clampf(
		float(hero.purifier_protection_config.get("break_slow_multiplier", 0.70)),
		0.1,
		1.0
	)
	var slow_until := hero.COMBAT_DELAY.now_msec(hero) + int(round(
		maxf(
			float(hero.purifier_protection_config.get("break_slow_duration", 1.5)),
			0.05
		) * 1000.0
	))
	var radius_sq := radius * radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		radius,
		hero._combat_monster_scratch
	)
	for node in hero._combat_monster_scratch:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or hero.global_position.distance_squared_to(monster.global_position) > radius_sq
		):
			continue
		var push_direction := hero.global_position.direction_to(monster.global_position)
		if push_direction.length_squared() <= 0.001:
			push_direction = Vector2.RIGHT
		monster.global_position += push_direction.normalized() * knockback
		hero.LOCAL_GRID_MOVEMENT.notify_forced_position_change(monster)
		var current_until := int(monster.get_meta("gunner_slow_until", 0))
		var current_multiplier := float(
			monster.get_meta("gunner_slow_multiplier", 1.0)
		)
		monster.set_meta("gunner_slow_until", maxi(current_until, slow_until))
		monster.set_meta(
			"gunner_slow_multiplier",
			minf(current_multiplier, slow_multiplier)
		)
	hero._combat_monster_scratch.clear()


func _end_purifier_protection(broken: bool) -> void:
	if not hero.purifier_protection_active and hero.shield_hp <= 0.0:
		return
	if broken and not hero.purifier_protection_break_triggered:
		hero.purifier_protection_break_triggered = true
		hero.purifier_protection_break_count += 1
		_trigger_purifier_protection_break_pulse()
		if _get_purifier_augment_stacks("purifier_broken_sanctuary") > 0:
			hero.purifier_broken_sanctuary_timer = 6.0
	hero.purifier_protection_active = false
	hero.purifier_protection_duration_timer = 0.0
	hero.purifier_protection_tick_timer = 0.0
	hero.shield_hp = 0.0
	hero.shield_max_hp = 0.0
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(hero.purifier_protection_effect, &"end")
	_play_purifier_audio(hero.purifier_shield_break_audio)
	hero.queue_redraw()


func _cast_purifier_crown() -> void:
	if hero.silence_timer > 0.0:
		return
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_crown_config.is_empty()
		or hero.purifier_crown_cooldown > 0.0
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return
	var max_stacks := _get_purifier_crown_max_stacks()
	hero.purifier_crown_stacks = mini(hero.purifier_crown_stacks + 1, max_stacks)
	hero.purifier_crown_duration_timer = maxf(
		float(hero.purifier_crown_config.get("duration", 60.0)),
		0.1
	)
	if hero.purifier_crown_heal_timer <= 0.0:
		hero.purifier_crown_heal_timer = maxf(
			float(hero.purifier_crown_config.get("heal_interval", 5.0)),
			0.1
		)
	hero.purifier_crown_cooldown = (
		maxf(float(hero.purifier_crown_config.get("cooldown", 20.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(hero.purifier_crown_effect, &"start")
	_play_purifier_audio(hero.purifier_crown_audio)
	hero.queue_redraw()


func _expire_purifier_crown() -> void:
	if hero.purifier_crown_stacks <= 0:
		return
	hero.purifier_crown_stacks = 0
	hero.purifier_crown_duration_timer = 0.0
	hero.purifier_crown_heal_timer = 0.0
	_ensure_purifier_skill_runtime()
	_play_purifier_effect(hero.purifier_crown_effect, &"end")
	hero.queue_redraw()


func _clear_purifier_orb_runtime() -> void:
	for raw_link in hero.purifier_orb_links.values():
		var link := raw_link as Node
		if is_instance_valid(link):
			link.queue_free()
	hero.purifier_orb_links.clear()

	for orb in hero.purifier_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	hero.purifier_orbs.clear()
	hero.purifier_orb_chain_queue.clear()
	hero.purifier_orb_chain_active = false
	hero.purifier_orb_chain_timer = 0.0
	hero.purifier_orb_chain_step = 0

	for entry in hero.purifier_prism_active:
		var prism_orb = entry.get("orb", null)
		if is_instance_valid(prism_orb):
			prism_orb.queue_free()
	hero.purifier_prism_active.clear()
	hero.purifier_prism_launch_queue.clear()
	hero.purifier_prism_launch_timer = 0.0


func _is_purifier_orb_active(orb: Node2D) -> bool:
	return (
		is_instance_valid(orb)
		and not orb.is_queued_for_deletion()
		and orb.has_method("is_network_active")
		and bool(orb.call("is_network_active"))
	)


func _get_active_purifier_orbs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for orb in hero.purifier_orbs:
		if _is_purifier_orb_active(orb):
			result.append(orb)
	return result


func _purifier_orb_link_key(a: Node2D, b: Node2D) -> String:
	var a_id := a.get_instance_id()
	var b_id := b.get_instance_id()
	if a_id > b_id:
		var swap := a_id
		a_id = b_id
		b_id = swap
	return "%d:%d" % [a_id, b_id]


func _refresh_purifier_orb_links() -> void:
	var active_orbs := _get_active_purifier_orbs()
	var link_distance := maxf(
		float(hero.purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var seen_links: Dictionary = {}
	var link_effect_dir := String(
		hero.purifier_orb_config.get(
			"link_effect_dir",
			"%s/effect5" % hero.STAGE5_FRAME_DIR
		)
	)
	var link_vertical_scale := maxf(
		float(hero.purifier_orb_config.get("link_vertical_scale", 0.58)),
		0.05
	)
	var pilgrims_path_stacks := _get_purifier_augment_stacks(
		"purifier_pilgrims_path"
	)
	var link_damage_ratio := (
		0.10 + 0.05 * float(pilgrims_path_stacks - 1)
		if pilgrims_path_stacks > 0
		else 0.0
	)
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return

	for first_index in range(active_orbs.size()):
		var first := active_orbs[first_index]
		for second_index in range(first_index + 1, active_orbs.size()):
			var second := active_orbs[second_index]
			if (
				first.global_position.distance_squared_to(second.global_position)
				> link_distance_sq
			):
				continue

			var key := _purifier_orb_link_key(first, second)
			seen_links[key] = true
			if hero.purifier_orb_links.has(key):
				var existing_link = hero.purifier_orb_links.get(key)
				if (
					is_instance_valid(existing_link)
					and existing_link.has_method("configure_damage")
				):
					existing_link.call(
						"configure_damage",
						hero,
						link_damage_ratio,
						0.22,
						24.0
					)
				continue

			var link := hero.PURIFIER_ORB_LINK_SCENE.instantiate() as Node2D
			if link == null:
				continue
			parent.add_child(link)
			link.call(
				"setup",
				first.global_position,
				second.global_position,
				link_effect_dir,
				link_vertical_scale,
				hero,
				link_damage_ratio,
				0.22,
				24.0
			)
			hero.purifier_orb_links[key] = link

	for raw_key in hero.purifier_orb_links.keys():
		var key := String(raw_key)
		if seen_links.has(key):
			continue
		var stale_link = hero.purifier_orb_links.get(key)
		if is_instance_valid(stale_link):
			stale_link.queue_free()
		hero.purifier_orb_links.erase(key)


func _on_purifier_orb_settled(orb: Node2D) -> void:
	if not _is_purifier_orb_active(orb):
		return
	_refresh_purifier_orb_links()
	_try_start_purifier_orb_chain_from(orb)


func _on_purifier_orb_deactivated(_orb: Node2D) -> void:
	_refresh_purifier_orb_links()


func _on_purifier_orb_finished(orb: Node2D) -> void:
	hero.purifier_orbs.erase(orb)
	hero.purifier_orb_chain_queue.erase(orb)
	_refresh_purifier_orb_links()


func _clamp_purifier_orb_target_position(candidate: Vector2) -> Vector2:
	var throw_range := maxf(
		float(hero.purifier_orb_config.get("throw_range", 820.0)),
		1.0
	)
	var offset := candidate - hero.global_position
	if offset.length_squared() > throw_range * throw_range:
		offset = offset.normalized() * throw_range
		candidate = hero.global_position + offset

	var clamped := Vector2(
		clampf(
			candidate.x,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.x - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		),
		clampf(
			candidate.y,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.y - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		)
	)
	var battle := hero.get_parent()
	if (
		is_instance_valid(battle)
		and battle.has_method("_clamp_manual_spawn_position")
	):
		var battle_clamped = battle.call(
			"_clamp_manual_spawn_position",
			clamped
		)
		if typeof(battle_clamped) == TYPE_VECTOR2:
			clamped = battle_clamped as Vector2
	return clamped


func _purifier_orb_connection_count(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	var link_distance := maxf(
		float(hero.purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var count := 0
	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			<= link_distance_sq
		):
			count += 1
	return count


func _purifier_orb_resulting_component_size(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> int:
	var link_distance := maxf(
		float(hero.purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	var visited: Dictionary = {}
	var frontier: Array[Node2D] = []

	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			<= link_distance_sq
		):
			frontier.append(orb)

	var cursor := 0
	while cursor < frontier.size():
		var current := frontier[cursor]
		cursor += 1
		if not _is_purifier_orb_active(current):
			continue
		var current_id := current.get_instance_id()
		if visited.has(current_id):
			continue
		visited[current_id] = true

		for candidate in active_orbs:
			if (
				not _is_purifier_orb_active(candidate)
				or visited.has(candidate.get_instance_id())
				or current.global_position.distance_squared_to(
					candidate.global_position
				) > link_distance_sq
			):
				continue
			frontier.append(candidate)

	# Include the candidate orb itself.
	return visited.size() + 1


func _purifier_orb_position_has_spacing(
	position: Vector2,
	active_orbs: Array[Node2D]
) -> bool:
	var min_spacing := maxf(
		float(hero.purifier_orb_config.get("min_orb_spacing", 96.0)),
		1.0
	)
	var min_spacing_sq := min_spacing * min_spacing
	for orb in active_orbs:
		if (
			_is_purifier_orb_active(orb)
			and position.distance_squared_to(orb.global_position)
			< min_spacing_sq
		):
			return false
	return true


func _choose_purifier_orb_target_position() -> Vector2:
	var throw_range := maxf(
		float(hero.purifier_orb_config.get("throw_range", 820.0)),
		1.0
	)
	var blast_radius := _get_purifier_orb_explosion_radius()
	var link_distance := maxf(
		float(hero.purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var active_orbs := _get_active_purifier_orbs()
	var candidates: Array[Vector2] = []

	if is_instance_valid(hero.target) and not hero.target.is_queued_for_deletion():
		candidates.append(hero.target.global_position)

	var monsters := hero._get_monster_nodes_near(hero.global_position, throw_range)
	var monster_sample_count := 0
	for node in monsters:
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if monster == null:
			continue
		candidates.append(monster.global_position)
		monster_sample_count += 1
		if monster_sample_count >= 12:
			break

	for orb in active_orbs:
		var desired_direction := Vector2.ZERO
		if is_instance_valid(hero.target):
			desired_direction = orb.global_position.direction_to(
				hero.target.global_position
			)
		if desired_direction.length_squared() <= 0.001:
			desired_direction = hero.global_position.direction_to(
				orb.global_position
			)
		if desired_direction.length_squared() <= 0.001:
			desired_direction = Vector2.from_angle(randf_range(0.0, TAU))

		for angle_offset in [-0.70, -0.35, 0.0, 0.35, 0.70]:
			candidates.append(
				orb.global_position
				+ desired_direction.rotated(angle_offset)
				* link_distance * 0.72
			)

	for first_index in range(active_orbs.size()):
		for second_index in range(first_index + 1, active_orbs.size()):
			var first := active_orbs[first_index]
			var second := active_orbs[second_index]
			if (
				first.global_position.distance_squared_to(second.global_position)
				<= (link_distance * 2.0) * (link_distance * 2.0)
			):
				candidates.append(
					first.global_position.lerp(second.global_position, 0.5)
				)

	var random_center := hero.global_position
	if is_instance_valid(hero.target):
		random_center = hero.target.global_position
	for _sample_index in range(8):
		candidates.append(
			random_center
			+ Vector2.from_angle(randf_range(0.0, TAU))
			* randf_range(80.0, minf(blast_radius * 1.65, throw_range))
		)

	if candidates.is_empty():
		var fallback_direction := (
			Vector2.LEFT
			if hero.hero_sprite.flip_h
			else Vector2.RIGHT
		)
		return _clamp_purifier_orb_target_position(
			hero.global_position + fallback_direction * minf(420.0, throw_range)
		)

	var hold_chain := (
		active_orbs.size() >= 2
		and randf()
		< clampf(
			float(hero.purifier_orb_config.get("chain_hold_chance", 0.25)),
			0.0,
			1.0
		)
	)
	var best_position := Vector2.ZERO
	var best_score := -INF
	var found := false

	for pass_index in range(2):
		var avoid_multi_link := hold_chain and pass_index == 0
		for raw_candidate in candidates:
			var candidate := _clamp_purifier_orb_target_position(raw_candidate)
			if not _purifier_orb_position_has_spacing(candidate, active_orbs):
				continue

			var link_count := _purifier_orb_connection_count(
				candidate,
				active_orbs
			)
			var resulting_component_size := (
				_purifier_orb_resulting_component_size(
					candidate,
					active_orbs
				)
			)
			if avoid_multi_link and resulting_component_size >= 3:
				continue

			var monster_count := hero._count_monsters_near(
				candidate,
				blast_radius
			)
			var score := float(monster_count) * 3.0
			if avoid_multi_link:
				score += (
					2.5
					if link_count == 0
					else 1.2
				)
			else:
				if resulting_component_size == 2:
					score += maxf(
						float(
							hero.purifier_orb_config.get(
								"partial_link_score_bonus",
								4.0
							)
						),
						0.0
					)
				score += (
					float(link_count)
					* maxf(
						float(
							hero.purifier_orb_config.get(
								"link_score_per_neighbor",
								5.0
							)
						),
						0.0
					)
				)
				if resulting_component_size >= 3:
					score += (
						maxf(
							float(
								hero.purifier_orb_config.get(
									"chain_ready_score_bonus",
									12.0
								)
							),
							0.0
						)
						+ float(resulting_component_size - 3)
						* maxf(
							float(
								hero.purifier_orb_config.get(
									"extra_chain_orb_score_bonus",
									5.0
								)
							),
							0.0
						)
					)

			score -= (
				hero.global_position.distance_to(candidate)
				/ throw_range
			) * 0.30
			score += randf_range(-0.35, 0.35)

			if not found or score > best_score:
				found = true
				best_score = score
				best_position = candidate

		if found:
			break

	if found:
		return best_position

	var fallback := candidates[0]
	return _clamp_purifier_orb_target_position(fallback)


func _spawn_purifier_network_orb(destination: Vector2) -> bool:
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return false

	var orb := hero.PURIFIER_ORB_SCENE.instantiate() as Node2D
	if orb == null:
		return false

	hero.purifier_orb_install_serial += 1
	parent.add_child(orb)
	orb.connect(
		"settled",
		Callable(hero, "_on_purifier_orb_settled")
	)
	orb.connect(
		"deactivated",
		Callable(hero, "_on_purifier_orb_deactivated")
	)
	orb.connect(
		"finished",
		Callable(hero, "_on_purifier_orb_finished")
	)

	var start_position := hero.global_position + Vector2(0.0, -42.0)
	orb.call(
		"setup",
		hero,
		start_position,
		destination,
		maxf(
			float(hero.purifier_orb_config.get("projectile_speed", 380.0)),
			1.0
		),
		maxf(float(hero.purifier_orb_config.get("duration", 80.0)), 0.1),
		_get_purifier_orb_explosion_radius(),
		hero.purifier_orb_install_serial,
		String(
			hero.purifier_orb_config.get(
				"effect_dir",
				"%s/effect2" % hero.STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(hero.purifier_orb_config.get("visual_scale", 0.45)),
			0.05
		)
	)
	hero.purifier_orbs.append(orb)
	return true


func _cast_purifier_orb() -> void:
	if hero.silence_timer > 0.0:
		return
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_orb_config.is_empty()
		or hero.purifier_orb_cooldown > 0.0
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return

	var book_stacks := _get_purifier_augment_stacks("purifier_book_of_purification")
	var orb_count := 1 + book_stacks
	var primary_destination := _choose_purifier_orb_target_position()
	var spacing := maxf(
		float(hero.purifier_orb_config.get("min_orb_spacing", 96.0)) * 1.20,
		72.0
	)
	var launched := 0
	var reserved_positions: Array[Vector2] = []

	for orb_index in range(orb_count):
		var destination := primary_destination
		if orb_index > 0:
			var extra_count := maxi(orb_count - 1, 1)
			var angle := (
				TAU * float(orb_index - 1) / float(extra_count)
				+ 0.35
			)
			destination = _clamp_purifier_orb_target_position(
				primary_destination
				+ Vector2.from_angle(angle)
				* spacing
				* (1.0 + 0.12 * float(orb_index - 1))
			)

		var adjustment_index := 0
		var needs_adjustment := true
		while needs_adjustment and adjustment_index < 4:
			needs_adjustment = false
			for reserved in reserved_positions:
				if destination.distance_to(reserved) < spacing * 0.85:
					needs_adjustment = true
					break
			if needs_adjustment:
				destination = _clamp_purifier_orb_target_position(
					destination
					+ Vector2.from_angle(
						0.85 + float(adjustment_index) * 1.70
					) * spacing * 0.75
				)
				adjustment_index += 1

		reserved_positions.append(destination)
		if _spawn_purifier_network_orb(destination):
			launched += 1

	if launched <= 0:
		return

	hero.purifier_orb_cooldown = (
		maxf(float(hero.purifier_orb_config.get("cooldown", 10.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_orb_create_audio)


func _get_purifier_orb_component(start_orb: Node2D) -> Array[Node2D]:
	var component: Array[Node2D] = []
	if not _is_purifier_orb_active(start_orb):
		return component

	var link_distance := maxf(
		float(hero.purifier_orb_config.get("link_distance", 780.0)),
		1.0
	)
	var link_distance_sq := link_distance * link_distance
	component.append(start_orb)
	var cursor := 0

	while cursor < component.size():
		var current := component[cursor]
		cursor += 1
		for candidate in hero.purifier_orbs:
			if (
				not _is_purifier_orb_active(candidate)
				or candidate in component
			):
				continue
			if (
				current.global_position.distance_squared_to(
					candidate.global_position
				)
				<= link_distance_sq
			):
				component.append(candidate)

	return component


func _purifier_orb_install_index(orb: Node2D) -> int:
	if (
		is_instance_valid(orb)
		and orb.has_method("get_install_index")
	):
		return int(orb.call("get_install_index"))
	return 0


func _sort_purifier_orbs_by_install_order(
	orbs: Array[Node2D]
) -> void:
	for index in range(1, orbs.size()):
		var current := orbs[index]
		var current_order := _purifier_orb_install_index(current)
		var insert_index := index - 1
		while (
			insert_index >= 0
			and _purifier_orb_install_index(orbs[insert_index])
			> current_order
		):
			orbs[insert_index + 1] = orbs[insert_index]
			insert_index -= 1
		orbs[insert_index + 1] = current


func _try_start_purifier_orb_chain_from(orb: Node2D) -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.purifier_orb_chain_active:
		return
	var component := _get_purifier_orb_component(orb)
	if component.size() < 3:
		return
	_start_purifier_orb_chain(component)


func _try_start_any_purifier_orb_chain() -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.purifier_orb_chain_active:
		return
	for orb in hero.purifier_orbs:
		if not _is_purifier_orb_active(orb):
			continue
		var component := _get_purifier_orb_component(orb)
		if component.size() >= 3:
			_start_purifier_orb_chain(component)
			return


func _start_purifier_orb_chain(component: Array[Node2D]) -> void:
	if hero.silence_timer > 0.0:
		return
	if hero.purifier_orb_chain_active or component.size() < 3:
		return

	_sort_purifier_orbs_by_install_order(component)
	hero.purifier_orb_chain_queue.clear()
	for orb in component:
		if not _is_purifier_orb_active(orb):
			continue
		orb.call("reserve_for_chain")
		hero.purifier_orb_chain_queue.append(orb)

	if hero.purifier_orb_chain_queue.size() < 3:
		hero.purifier_orb_chain_queue.clear()
		return

	hero.purifier_orb_chain_active = true
	hero.purifier_orb_chain_timer = 0.0
	hero.purifier_orb_chain_step = 0
	_advance_purifier_orb_chain()


func _get_purifier_orb_chain_interval() -> float:
	var base_interval := maxf(
		float(hero.purifier_orb_config.get("chain_interval", 1.0)),
		0.05
	)
	return base_interval / maxf(
		hero.purifier_orb_chain_speed_multiplier,
		0.05
	)


func set_purifier_orb_chain_speed_multiplier(multiplier: float) -> void:
	hero.purifier_orb_chain_speed_multiplier = maxf(multiplier, 0.05)


func _update_purifier_orb_chain(delta: float) -> void:
	if not hero.purifier_orb_chain_active:
		return
	hero.purifier_orb_chain_timer = maxf(
		hero.purifier_orb_chain_timer - delta,
		0.0
	)
	if hero.purifier_orb_chain_timer <= 0.0:
		_advance_purifier_orb_chain()


func _advance_purifier_orb_chain() -> void:
	if not hero.purifier_orb_chain_active:
		return

	var orb: Node2D = null
	while not hero.purifier_orb_chain_queue.is_empty():
		var candidate := (
			hero.purifier_orb_chain_queue.pop_front()
			as Node2D
		)
		if _is_purifier_orb_active(candidate):
			orb = candidate
			break

	if not is_instance_valid(orb):
		_finish_purifier_orb_chain()
		return

	_detonate_purifier_orb(orb, hero.purifier_orb_chain_step)
	hero.purifier_orb_chain_step += 1
	orb.call("trigger_explosion")
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_orb_explosion_audio)

	if hero.purifier_orb_chain_queue.is_empty():
		_finish_purifier_orb_chain()
	else:
		hero.purifier_orb_chain_timer = _get_purifier_orb_chain_interval()


func _finish_purifier_orb_chain() -> void:
	hero.purifier_orb_chain_active = false
	hero.purifier_orb_chain_timer = 0.0
	hero.purifier_orb_chain_step = 0
	hero.purifier_orb_chain_queue.clear()
	_try_start_any_purifier_orb_chain()


func _detonate_purifier_orb(
	orb: Node2D,
	chain_index: int
) -> void:
	if not is_instance_valid(orb):
		return

	var radius := _get_purifier_orb_explosion_radius()
	var radius_sq := radius * radius
	var base_ratio := maxf(
		float(hero.purifier_orb_config.get("base_damage_ratio", 0.80)),
		0.0
	) * _get_purifier_orb_damage_multiplier()
	var growth := maxf(
		float(hero.purifier_orb_config.get("chain_damage_growth", 0.15)),
		0.0
	)
	var chain_multiplier := 1.0 + growth * float(maxi(chain_index, 0))
	var raw_damage := maxf(
		float(hero.attack_damage) * base_ratio * chain_multiplier,
		1.0
	)
	var chain_cleansing_stacks := _get_purifier_augment_stacks("purifier_chain_cleansing")
	var chain_cleansing_chance := (
		clampf(
			0.20 + 0.08 * float(chain_cleansing_stacks - 1),
			0.0,
			1.0
		)
		if chain_cleansing_stacks > 0
		else 0.0
	)
	var cleansing_proc_positions: Array[Vector2] = []

	for node in hero._get_monster_nodes_near(orb.global_position, radius):
		if not hero.HERO_TARGET_POLICY.is_detectable(node):
			continue
		var monster := node as Node2D
		if (
			monster == null
			or not monster.has_method("take_damage")
			or orb.global_position.distance_squared_to(
				monster.global_position
			) > radius_sq
		):
			continue

		var hit_position := monster.global_position
		var holy_multiplier := get_purifier_holy_damage_multiplier(monster)
		var hit_damage := maxi(
			int(round(raw_damage * holy_multiplier)),
			1
		)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, hit_damage, "ranged", hero)
		if (
			chain_cleansing_chance > 0.0
			and randf() <= chain_cleansing_chance
		):
			cleansing_proc_positions.append(hit_position)

	_queue_purifier_prism_burst(
		orb.global_position,
		raw_damage,
		radius
	)

	for proc_position in cleansing_proc_positions:
		_trigger_purifier_auto_cleansing(proc_position)


func _queue_purifier_prism_burst(
	origin: Vector2,
	source_raw_damage: float,
	source_radius: float
) -> void:
	var prism_stacks := _get_purifier_augment_stacks("purifier_prism_phenomenon")
	if prism_stacks <= 0:
		return

	var queue_was_empty := hero.purifier_prism_launch_queue.is_empty()
	for _index in range(prism_stacks):
		hero.purifier_prism_launch_queue.append({
			"origin": origin,
			"raw_damage": maxf(source_raw_damage * 0.50, 1.0),
			"radius": maxf(source_radius * 0.50, 1.0),
		})
	if queue_was_empty:
		hero.purifier_prism_launch_timer = 0.0


func _choose_purifier_prism_target_position(origin: Vector2) -> Vector2:
	var search_range := maxf(
		float(hero.purifier_orb_config.get("throw_range", 820.0)) * 0.50,
		80.0
	)
	var search_range_sq := search_range * search_range
	var score_radius := maxf(_get_purifier_orb_explosion_radius(), 80.0)
	hero._fill_monster_nodes_near(origin, search_range, hero._combat_monster_scratch)

	var best_position := Vector2.ZERO
	var best_score := -INF
	var found := false
	for raw_node in hero._combat_monster_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if monster == null:
			continue
		var distance_sq := origin.distance_squared_to(monster.global_position)
		if distance_sq > search_range_sq:
			continue
		var nearby := hero._count_monsters_near(monster.global_position, score_radius)
		var score := (
			float(nearby) * 10.0
			- sqrt(distance_sq) / maxf(search_range, 1.0)
		)
		if not found or score > best_score:
			found = true
			best_score = score
			best_position = monster.global_position
	hero._combat_monster_scratch.clear()

	if not found:
		var direction := Vector2.RIGHT
		if is_instance_valid(hero.target) and not hero.target.is_queued_for_deletion():
			direction = origin.direction_to(hero.target.global_position)
		if direction.length_squared() <= 0.001:
			direction = Vector2.from_angle(randf_range(0.0, TAU))
		best_position = origin + direction.normalized() * minf(180.0, search_range)

	return Vector2(
		clampf(
			best_position.x,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.x - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		),
		clampf(
			best_position.y,
			hero.FIELD_MARGIN,
			maxf(hero.battlefield_size.y - hero.FIELD_MARGIN, hero.FIELD_MARGIN)
		)
	)


func _launch_purifier_prism_orb(job: Dictionary) -> void:
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return
	var orb := hero.PURIFIER_ORB_SCENE.instantiate() as Node2D
	if orb == null:
		return

	var origin: Vector2 = job.get("origin", hero.global_position)
	var destination := _choose_purifier_prism_target_position(origin)
	parent.add_child(orb)
	orb.call(
		"setup",
		hero,
		origin,
		destination,
		maxf(
			float(hero.purifier_orb_config.get("projectile_speed", 380.0)),
			1.0
		),
		3.0,
		maxf(float(job.get("radius", 1.0)), 1.0),
		-1,
		String(
			hero.purifier_orb_config.get(
				"effect_dir",
				"%s/effect2" % hero.STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(hero.purifier_orb_config.get("visual_scale", 0.45)) * 0.50,
			0.05
		)
	)
	hero.purifier_prism_active.append({
		"orb": orb,
		"timer": 2.0,
		"raw_damage": maxf(float(job.get("raw_damage", 1.0)), 1.0),
		"radius": maxf(float(job.get("radius", 1.0)), 1.0),
	})


func _detonate_purifier_prism_orb(entry: Dictionary) -> void:
	var raw_orb = entry.get("orb", null)
	if not is_instance_valid(raw_orb):
		return
	var orb := raw_orb as Node2D
	if orb == null:
		return

	var radius := maxf(float(entry.get("radius", 1.0)), 1.0)
	var radius_sq := radius * radius
	var raw_damage := maxf(float(entry.get("raw_damage", 1.0)), 1.0)
	hero._fill_monster_nodes_near(orb.global_position, radius, hero._combat_monster_scratch)
	for raw_node in hero._combat_monster_scratch:
		if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
			continue
		var monster := raw_node as Node2D
		if (
			monster == null
			or not monster.has_method("take_damage")
			or orb.global_position.distance_squared_to(monster.global_position) > radius_sq
		):
			continue
		var hit_damage := maxi(
			int(round(raw_damage * get_purifier_holy_damage_multiplier(monster))),
			1
		)
		preload("res://src/systems/monster_hit_context.gd").hit(monster, hit_damage, "ranged", hero)
	hero._combat_monster_scratch.clear()

	if orb.has_method("trigger_explosion"):
		orb.call("trigger_explosion")
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_orb_explosion_audio)


func _update_purifier_prism(delta: float) -> void:
	if not hero.purifier_prism_launch_queue.is_empty():
		hero.purifier_prism_launch_timer = maxf(
			hero.purifier_prism_launch_timer - delta,
			0.0
		)
		if hero.purifier_prism_launch_timer <= 0.0:
			var job: Dictionary = hero.purifier_prism_launch_queue.pop_front()
			_launch_purifier_prism_orb(job)
			hero.purifier_prism_launch_timer = 0.32

	for index in range(hero.purifier_prism_active.size() - 1, -1, -1):
		var entry: Dictionary = hero.purifier_prism_active[index]
		var raw_orb = entry.get("orb", null)
		if not is_instance_valid(raw_orb) or raw_orb.is_queued_for_deletion():
			hero.purifier_prism_active.remove_at(index)
			continue
		var timer := float(entry.get("timer", 0.0)) - delta
		entry["timer"] = timer
		if timer > 0.0:
			continue
		_detonate_purifier_prism_orb(entry)
		hero.purifier_prism_active.remove_at(index)


func _advance_purifier_cleansing_stack() -> void:
	var max_stacks := maxi(
		int(hero.purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	hero.purifier_cleansing_stacks = mini(
		hero.purifier_cleansing_stacks + 1,
		max_stacks
	)


func _try_purifier_o_lord_heal(total_damage: int) -> void:
	if hero.silence_timer > 0.0:
		return
	var stacks := _get_purifier_augment_stacks("purifier_o_lord")
	if stacks <= 0 or total_damage <= 0:
		return
	var chance := clampf(
		0.30 + 0.03 * float(stacks - 1),
		0.0,
		1.0
	)
	if randf() <= chance:
		hero.heal_direct(total_damage)


func _apply_purifier_cleansing_centers(centers: Array[Vector2]) -> int:
	if centers.is_empty():
		return 0
	var radius := maxf(
		float(hero.purifier_cleansing_config.get("radius", 100.0)),
		1.0
	)
	var radius_sq := radius * radius
	var base_ratio := maxf(
		float(hero.purifier_cleansing_config.get("base_damage_ratio", 0.80)),
		0.0
	)
	var undead_multiplier := maxf(
		float(
			hero.purifier_cleansing_config.get(
				"undead_damage_multiplier",
				1.50
			)
		),
		0.0
	)
	var raw_damage := maxf(float(hero.attack_damage) * base_ratio, 1.0)
	var damaged_ids: Dictionary = {}
	var total_damage := 0

	for center in centers:
		_spawn_purifier_cleansing_fx(center)
		for raw_node in hero._get_monster_nodes_near(center, radius):
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or not monster.has_method("take_damage"):
				continue
			var instance_id := monster.get_instance_id()
			if damaged_ids.has(instance_id):
				continue
			if center.distance_squared_to(monster.global_position) > radius_sq:
				continue
			damaged_ids[instance_id] = true
			var multiplier := get_purifier_holy_damage_multiplier(monster)
			if _is_purifier_undead_target(monster):
				multiplier *= undead_multiplier
			var hit_damage := maxi(
				int(round(raw_damage * multiplier)),
				1
			)
			preload("res://src/systems/monster_hit_context.gd").hit(monster, hit_damage, "ranged", hero)
			total_damage += hit_damage

	_try_purifier_o_lord_heal(total_damage)
	return total_damage


func _trigger_purifier_auto_cleansing(center: Vector2) -> void:
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_cleansing_config.is_empty()
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return
	_advance_purifier_cleansing_stack()
	var centers: Array[Vector2] = []
	centers.append(center)
	_apply_purifier_cleansing_centers(centers)
	_try_unlock_purifier_fourth_skill()
	hero.queue_redraw()


func _get_purifier_cleansing_target_count() -> int:
	var per_target := maxi(
		int(hero.purifier_cleansing_config.get("casts_per_extra_target", 20)),
		1
	)
	var max_targets := maxi(
		int(hero.purifier_cleansing_config.get("max_targets", 6)),
		1
	)
	var extra_targets := floori(
		float(hero.purifier_cleansing_stacks) / float(per_target)
	)
	return mini(1 + extra_targets, max_targets)


func _collect_purifier_cleansing_targets(
	target_count: int
) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if target_count <= 0:
		return result

	if (
		hero.HERO_TARGET_POLICY.is_detectable(hero.target)
		and hero.target.is_in_group("monsters")
	):
		var hp_value = hero.target.get("current_hp")
		if hp_value == null or int(hp_value) > 0:
			result.append(hero.target)

	var search_radius := maxf(hero.ai_sense_radius, hero.attack_range)
	var candidates := hero._get_monster_nodes_near(hero.global_position, search_radius)
	while result.size() < target_count:
		var best: Node2D = null
		var best_distance_sq := INF
		for raw_node in candidates:
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or monster in result:
				continue
			var hp_value = monster.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue
			var distance_sq := hero.global_position.distance_squared_to(
				monster.global_position
			)
			if distance_sq < best_distance_sq:
				best_distance_sq = distance_sq
				best = monster
		if best == null:
			break
		result.append(best)

	return result


func _spawn_purifier_cleansing_fx(world_position: Vector2) -> void:
	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return
	var fx := hero.PURIFIER_CLEANSING_FX_SCENE.instantiate() as Node2D
	if fx == null:
		return
	parent.add_child(fx)
	fx.call(
		"setup",
		world_position,
		String(
			hero.purifier_cleansing_config.get(
				"effect_dir",
				"%s/effect5" % hero.STAGE9_FRAME_DIR
			)
		),
		maxf(
			float(hero.purifier_cleansing_config.get("visual_scale", 1.0)),
			0.05
		),
		maxf(
			float(hero.purifier_cleansing_config.get("effect_fps", 12.0)),
			1.0
		)
	)


func _try_unlock_purifier_fourth_skill() -> void:
	var required := maxi(
		int(hero.purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	if hero.purifier_cleansing_stacks < required:
		return
	var skill_id := String(
		hero.purifier_cleansing_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	if hero.is_conditional_skill_unlocked(skill_id):
		return
	hero._unlock_conditional_skill(
		skill_id,
		String(
			hero.purifier_cleansing_config.get(
				"unlock_skill_name",
				"4스킬"
			)
		),
		"purification_cast_count",
		hero.purifier_cleansing_stacks,
		required,
		{
			"hero_id": hero.hero_id,
			"archetype": hero.hero_archetype,
			"source": "purifier_cleansing_stacks",
			"cutscene_texture_path": String(
				hero.purifier_cleansing_config.get(
					"cutscene_texture_path",
					""
				)
			),
			"cutscene_hold_seconds": float(
				hero.purifier_cleansing_config.get(
					"cutscene_hold_seconds",
					1.05
				)
			),
		}
	)


func _cast_purifier_cleansing() -> void:
	if hero.silence_timer > 0.0:
		return
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_cleansing_config.is_empty()
		or hero.purifier_cleansing_cooldown > 0.0
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return

	var previous_stacks := hero.purifier_cleansing_stacks
	_advance_purifier_cleansing_stack()

	var targets := _collect_purifier_cleansing_targets(
		_get_purifier_cleansing_target_count()
	)
	if targets.is_empty():
		hero.purifier_cleansing_stacks = previous_stacks
		return

	var centers: Array[Vector2] = []
	for cast_target in targets:
		if is_instance_valid(cast_target):
			centers.append(cast_target.global_position)

	if centers.is_empty():
		hero.purifier_cleansing_stacks = previous_stacks
		return

	_apply_purifier_cleansing_centers(centers)
	hero.purifier_cleansing_cooldown = (
		maxf(float(hero.purifier_cleansing_config.get("cooldown", 3.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_cleansing_audio)
	_try_unlock_purifier_fourth_skill()
	hero.queue_redraw()


func _choose_purifier_gungnir_direction() -> Vector2:
	if hero.purifier_gungnir_config.is_empty():
		return Vector2.ZERO

	var flight_distance := maxf(
		float(hero.purifier_gungnir_config.get("flight_distance", 1500.0)),
		1.0
	)
	var capture_radius := maxf(
		float(hero.purifier_gungnir_config.get("capture_diameter", 300.0)) * 0.5,
		1.0
	)
	var sample_count := maxi(
		int(hero.purifier_gungnir_config.get("direction_samples", 24)),
		8
	)
	var search_radius := flight_distance + capture_radius
	hero._fill_monster_nodes_near(
		hero.global_position,
		search_radius,
		hero._combat_monster_scratch
	)

	var best_direction := Vector2.ZERO
	var best_score := -INF
	var best_count := 0

	for sample_index in range(sample_count):
		var angle := TAU * float(sample_index) / float(sample_count)
		var candidate_direction := Vector2.from_angle(angle)
		var hit_count := 0
		var density_score := 0.0
		var distance_score := 0.0

		for raw_node in hero._combat_monster_scratch:
			if not is_instance_valid(raw_node) or raw_node.is_queued_for_deletion():
				continue
			var monster := raw_node as Node2D
			if monster == null or not monster.is_in_group("monsters"):
				continue
			var hp_value = monster.get("current_hp")
			if hp_value != null and int(hp_value) <= 0:
				continue

			var offset := monster.global_position - hero.global_position
			var forward := offset.dot(candidate_direction)
			if forward < 0.0 or forward > flight_distance:
				continue
			var lateral := absf(candidate_direction.cross(offset))
			if lateral > capture_radius:
				continue

			hit_count += 1
			density_score += 1.0 - clampf(
				lateral / capture_radius,
				0.0,
				1.0
			)
			distance_score += 1.0 - clampf(
				forward / flight_distance,
				0.0,
				1.0
			)

		var score := (
			float(hit_count) * 1000.0
			+ density_score * 20.0
			+ distance_score * 2.0
		)
		if hit_count > best_count or (
			hit_count == best_count and score > best_score
		):
			best_count = hit_count
			best_score = score
			best_direction = candidate_direction

	hero._combat_monster_scratch.clear()
	if best_count <= 0:
		return Vector2.ZERO
	return best_direction.normalized()


func _try_start_purifier_gungnir() -> bool:
	if hero.silence_timer > 0.0:
		return false
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_gungnir_config.is_empty()
		or hero.purifier_gungnir_casting
		or hero.purifier_gungnir_cooldown > 0.0
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return false

	var unlock_skill_id := String(
		hero.purifier_gungnir_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	if not hero.is_conditional_skill_unlocked(unlock_skill_id):
		return false

	var fire_direction := _choose_purifier_gungnir_direction()
	if fire_direction.length_squared() <= 0.001:
		return false

	var parent := hero.get_parent()
	if not is_instance_valid(parent):
		return false
	var gungnir := hero.PURIFIER_GUNGNIR_SCENE.instantiate() as Node2D
	if gungnir == null:
		return false

	parent.add_child(gungnir)
	gungnir.connect(
		"launched",
		Callable(hero, "_on_purifier_gungnir_launched")
	)
	gungnir.connect(
		"impacted",
		Callable(hero, "_on_purifier_gungnir_impacted")
	)
	gungnir.connect(
		"finished",
		Callable(hero, "_on_purifier_gungnir_finished").bind(gungnir)
	)

	hero.purifier_gungnir_instance = gungnir
	hero.purifier_gungnir_direction = fire_direction
	hero.purifier_gungnir_casting = true
	hero.purifier_gungnir_cooldown = (
		maxf(float(hero.purifier_gungnir_config.get("cooldown", 5.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)

	if absf(fire_direction.x) > 0.05 and is_instance_valid(hero.hero_sprite):
		hero.hero_sprite.flip_h = fire_direction.x < 0.0
	hero.velocity = Vector2.ZERO
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_gungnir_charge_audio)
	gungnir.call(
		"setup",
		hero,
		fire_direction,
		hero.purifier_gungnir_config
	)
	return true


func _on_purifier_gungnir_launched() -> void:
	hero.purifier_gungnir_casting = false
	if is_instance_valid(hero.purifier_gungnir_charge_audio):
		hero.purifier_gungnir_charge_audio.stop()
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_gungnir_flight_audio)


func _on_purifier_gungnir_impacted() -> void:
	if is_instance_valid(hero.purifier_gungnir_flight_audio):
		hero.purifier_gungnir_flight_audio.stop()
	_ensure_purifier_skill_runtime()
	_play_purifier_audio(hero.purifier_gungnir_explosion_audio)


func _on_purifier_gungnir_finished(instance: Node2D) -> void:
	if is_instance_valid(hero.purifier_gungnir_charge_audio):
		hero.purifier_gungnir_charge_audio.stop()
	if is_instance_valid(hero.purifier_gungnir_flight_audio):
		hero.purifier_gungnir_flight_audio.stop()
	if hero.purifier_gungnir_instance == instance:
		hero.purifier_gungnir_instance = null
	hero.purifier_gungnir_casting = false


func _update_purifier_gauge(delta: float) -> void:
	if (
		hero.hero_archetype != "cleric_purifier"
		or hero.purifier_gauge_config.is_empty()
		or hero.is_dying
		or hero.current_hp <= 0
	):
		return

	hero.purifier_protection_cooldown = maxf(
		hero.purifier_protection_cooldown - delta,
		0.0
	)
	hero.purifier_crown_cooldown = maxf(hero.purifier_crown_cooldown - delta, 0.0)
	hero.purifier_orb_cooldown = maxf(hero.purifier_orb_cooldown - delta, 0.0)
	hero.purifier_cleansing_cooldown = maxf(
		hero.purifier_cleansing_cooldown - delta,
		0.0
	)
	hero.purifier_gungnir_cooldown = maxf(
		hero.purifier_gungnir_cooldown - delta,
		0.0
	)
	hero.purifier_broken_sanctuary_timer = maxf(
		hero.purifier_broken_sanctuary_timer - delta,
		0.0
	)
	_update_purifier_orb_chain(delta)
	_update_purifier_prism(delta)

	if hero.purifier_protection_active:
		hero.purifier_protection_duration_timer = maxf(
			hero.purifier_protection_duration_timer - delta,
			0.0
		)
		hero.purifier_protection_tick_timer -= delta
		if hero.purifier_protection_duration_timer <= 0.0:
			_end_purifier_protection(false)
		else:
			var tick_interval := maxf(
				float(hero.purifier_protection_config.get("shield_tick_interval", 1.0)),
				0.05
			)
			while hero.purifier_protection_tick_timer <= 0.0:
				_add_purifier_shield_layer()
				hero.purifier_protection_tick_timer += tick_interval

	if hero.purifier_crown_stacks > 0:
		hero.purifier_crown_duration_timer = maxf(
			hero.purifier_crown_duration_timer - delta,
			0.0
		)
		hero.purifier_crown_heal_timer -= delta
		if hero.purifier_crown_duration_timer <= 0.0:
			_expire_purifier_crown()
		elif hero.purifier_crown_heal_timer <= 0.0:
			hero.heal_direct(
				maxi(
					int(round(
						float(
							int(
								hero.purifier_crown_config.get(
									"heal_per_stack",
									20
								)
							)
						)
						* float(hero.purifier_crown_stacks)
						* _get_purifier_crown_effect_multiplier()
					)),
					1
				)
			)
			hero.purifier_crown_heal_timer += maxf(
				float(hero.purifier_crown_config.get("heal_interval", 5.0)),
				0.1
			)

	if hero.purifier_gungnir_casting:
		_try_activate_purifier_protection()
		return
	if _try_start_purifier_gungnir():
		_try_activate_purifier_protection()
		return
	if hero.purifier_crown_cooldown <= 0.0:
		_cast_purifier_crown()
	if hero.purifier_orb_cooldown <= 0.0:
		_cast_purifier_orb()
	if hero.purifier_cleansing_cooldown <= 0.0:
		_cast_purifier_cleansing()
	_try_activate_purifier_protection()


func _add_purifier_gauge(amount: float) -> void:
	if (
		amount <= 0.0
		or hero.hero_archetype != "cleric_purifier"
		or hero.purifier_gauge_config.is_empty()
		or hero.is_dying
	):
		return
	var gauge_max := maxf(
		float(hero.purifier_gauge_config.get("charge_max", 100.0)),
		1.0
	)
	hero.ultimate_charge = minf(hero.ultimate_charge + amount, gauge_max)
	hero.queue_redraw()


func _append_purifier_cleansing_hud(skills: Array) -> void:
	if hero.purifier_cleansing_config.is_empty():
		return
	var cooldown_total := (
		maxf(float(hero.purifier_cleansing_config.get("cooldown", 3.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	var cooldown_remaining := maxf(hero.purifier_cleansing_cooldown, 0.0)
	var max_stacks := maxi(
		int(hero.purifier_cleansing_config.get("max_stacks", 100)),
		1
	)
	skills.append({
		"id": String(hero.purifier_cleansing_config.get("id", "purifier_cleansing")),
		"name": String(hero.purifier_cleansing_config.get("name", "정화")),
		"description": hero._skill_hud_description(hero.purifier_cleansing_config),
		"progress_text": (
			"정화 스택 %d / %d · 대상 수 %d"
			% [
				hero.purifier_cleansing_stacks,
				max_stacks,
				_get_purifier_cleansing_target_count(),
			]
		),
		"status_text": (
			"재사용 대기 중"
			if cooldown_remaining > 0.01
			else "사용 가능"
		),
		"available": cooldown_remaining <= 0.01,
		"cooldown_total": cooldown_total,
		"cooldown_remaining": cooldown_remaining,
		"icon_path": "res://assets/art/heroes/stage9_prist/frames/effect5/effect_30.png",
	})


func _append_purifier_gungnir_hud(skills: Array) -> void:
	if hero.purifier_gungnir_config.is_empty():
		return
	var required := maxi(
		int(hero.purifier_gungnir_config.get("required_cleansing_stacks", 100)),
		1
	)
	var unlock_skill_id := String(
		hero.purifier_gungnir_config.get(
			"unlock_skill_id",
			"purifier_fourth_skill"
		)
	)
	var unlocked := hero.is_conditional_skill_unlocked(unlock_skill_id)
	var cooldown_total := (
		maxf(float(hero.purifier_gungnir_config.get("cooldown", 5.0)), 0.0)
		* _get_purifier_skill_cooldown_multiplier()
	)
	var cooldown_remaining := maxf(hero.purifier_gungnir_cooldown, 0.0)
	var status := "해금 조건 대기"
	if unlocked:
		if hero.purifier_gungnir_casting:
			status = "시전 중"
		elif cooldown_remaining > 0.01:
			status = "재사용 대기 중"
		else:
			status = "사용 가능"

	skills.append({
		"id": String(hero.purifier_gungnir_config.get("id", "purifier_gungnir")),
		"name": String(hero.purifier_gungnir_config.get("name", "궁그닐")),
		"description": hero._skill_hud_description(hero.purifier_gungnir_config),
		"progress_text": (
			"정화 %d / %d · 해금 조건"
			% [mini(hero.purifier_cleansing_stacks, required), required]
		),
		"status_text": status,
		"available": (
			unlocked
			and not hero.purifier_gungnir_casting
			and cooldown_remaining <= 0.01
		),
		"cooldown_total": cooldown_total,
		"cooldown_remaining": (
			cooldown_remaining
			if unlocked
			else cooldown_total
		),
		"icon_path": "res://assets/art/heroes/stage9_prist/frames/effect6/frame_05.png",
	})


func _on_purifier_augment_stack_changed(augment_id: String) -> void:
	if hero.hero_archetype != "cleric_purifier":
		return
	if augment_id == "purifier_pilgrims_path":
		_refresh_purifier_orb_links()
	elif augment_id == "purifier_book_of_purification":
		var effective_radius := _get_purifier_orb_explosion_radius()
		for orb in hero.purifier_orbs:
			if not is_instance_valid(orb) or orb.is_queued_for_deletion():
				continue
			orb.set("blast_radius", effective_radius)
			orb.queue_redraw()
