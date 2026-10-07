extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("AUGMENT_REFRESH: " + message)


func stats(actor: Node) -> Array:
	return [actor.get("max_hp"), actor.get("current_hp"), actor.get("attack_damage"), actor.get("move_speed"), actor.get("attack_cooldown")]


func choose(battle: Node, id: String) -> void:
	battle.demon_augment_selection_active = true
	battle.demon_pending_augments = 1
	battle.demon_augment_candidates.assign([AUGMENTS.get_augment(id)])
	check(battle.choose_demon_augment(id), "actual choice accepted " + id)


func run() -> void:
	# Every catalog entry keeps its original content and caller copy isolation.
	for augment in AUGMENTS.NORMAL_AUGMENTS + AUGMENTS.SPECIAL_AUGMENTS:
		check(AUGMENTS.get_augment(augment.id) == augment, "indexed catalog lookup " + augment.id)
	for owner_id in AUGMENTS.MONSTER_NAMES:
		for augment in AUGMENTS.get_monster_normal_augments(owner_id, ""):
			check(AUGMENTS.get_augment(augment.id) == augment, "generated normal lookup " + augment.id)
	var isolated := AUGMENTS.get_augment("slime_damage")
	isolated.effects[0].value = 999.0
	check(AUGMENTS.get_augment("slime_damage").effects[0].value == 1.06, "catalog deep copy isolation")
	check(AUGMENTS.get_augment("missing_augment").is_empty(), "unknown ID remains empty")
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://augment_perf_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	battle.set_external_pause(true)
	# Existing unrelated specials make per-unit catalog reconstruction expensive.
	for augment in AUGMENTS.SPECIAL_AUGMENTS:
		if augment.monster_id != "slime":
			battle.demon_special_augments.append(augment.id)
		if battle.demon_special_augments.size() == 6:
			break
	var actors: Array = []
	for population in [128, 512]:
		while actors.size() < population:
			var actor = battle._spawn_monster("slime", Vector2(1100, 1000))
			actor.set_physics_process(false)
			actors.append(actor)
		for id in ["slime_damage", "slime_hp", "slime_speed", "slime_cost", "command_capacity"]:
			var started := Time.get_ticks_usec()
			choose(battle, id)
			var elapsed := (Time.get_ticks_usec() - started) / 1000.0
			print("AUGMENT_PERF n=%d id=%s choose_ms=%.3f" % [population, id, elapsed])
			var actual: Array = []
			for actor in actors:
				actual.append(stats(actor))
			# Compare the selective path with the original full refresh semantics.
			battle._refresh_alive_monsters_for_augments()
			for index in range(actors.size()):
				check(stats(actors[index]) == actual[index], "full-refresh stat equivalence " + id)
	var started := Time.get_ticks_usec()
	choose(battle, "slime_pack_instinct")
	print("AUGMENT_PERF n=512 id=slime_pack_instinct choose_ms=%.3f" % ((Time.get_ticks_usec() - started) / 1000.0))
	for actor in actors:
		check(actor.pack_config_cache.has("radius"), "selected special applies to all existing slimes")
	var new_slime = battle._spawn_monster("slime", Vector2(1100, 1000))
	new_slime.set_physics_process(false)
	check(new_slime.max_hp == actors[0].max_hp and new_slime.attack_damage == actors[0].attack_damage, "future spawns inherit same modifiers")
	check(new_slime.pack_config_cache == actors[0].pack_config_cache, "future spawns inherit special")
	var current_ids: Array[String] = battle.demon_special_augments.duplicate()
	var cached: Dictionary = battle._get_special_augment_config("slime")
	check(is_same(cached, battle._get_special_augment_config("slime")), "unchanged selection reuses cache")
	new_slime.special_augment_configs.slime_pack_instinct.radius = 999.0
	check(cached.slime_pack_instinct.radius == 180.0 and actors[0].pack_config_cache.radius == 180.0, "per-actor config isolation")
	new_slime.get_meta("special_augment_configs").slime_pack_instinct.radius = 888.0
	check(cached.slime_pack_instinct.radius == 180.0, "metadata config isolation")
	battle.demon_special_augments.assign(["slime_cell_division"])
	check(battle._get_special_augment_config("slime").has("slime_cell_division"), "direct list replacement invalidates cache")
	battle.demon_special_augments.assign(["slime_residual_mucus"])
	check(battle._get_special_augment_config("slime").has("slime_residual_mucus") and not battle._get_special_augment_config("slime").has("slime_cell_division"), "same-size replacement invalidates cache")
	battle.demon_special_augments.clear()
	check(battle._get_special_augment_config("slime").is_empty(), "clear resets special cache")
	battle.demon_special_augments.assign(current_ids)
	battle._apply_special_augments_to_monster(new_slime, "slime")
	# Mixed roster: unrelated types must retain the very same config object.
	var mummy = battle._spawn_monster("mummy", Vector2(1200, 1000))
	mummy.set_physics_process(false)
	var untouched_config: Dictionary = mummy.get_meta("special_augment_configs")
	var untouched_stats := stats(mummy)
	choose(battle, "slime_damage")
	check(stats(mummy) == untouched_stats and is_same(untouched_config, mummy.get_meta("special_augment_configs")), "unrelated type is not reconfigured")
	var slime_config: Dictionary = new_slime.get_meta("special_augment_configs")
	choose(battle, "slime_cost")
	choose(battle, "command_capacity")
	check(is_same(slime_config, new_slime.get_meta("special_augment_configs")), "cost and command choices skip combat refresh")
	mummy.current_hp = int(round(mummy.max_hp * 0.5))
	mummy.take_damage(10)
	var old_shield: int = mummy.shield_hp
	var old_max: int = mummy.max_hp
	battle.support_buff_runtime.apply_courage(mummy, 10.0, 0.15, 0.10)
	choose(battle, "mummy_hp")
	check(mummy.max_hp == int(round(old_max * 1.08)), "target HP multiplier")
	check(mummy.current_hp == int(round(mummy.max_hp * 0.5)), "existing HP fraction preserved")
	check(mummy.shield_hp == int(round(float(old_shield) * mummy.max_hp / old_max)), "damaged innate shield fraction preserved immediately")
	var refreshed := stats(mummy)
	battle._refresh_alive_monsters_for_augments()
	check(stats(mummy) == refreshed, "support-buffed target matches full refresh")
	choose(battle, "mummy_damage")
	refreshed = stats(mummy)
	battle._refresh_alive_monsters_for_augments()
	check(stats(mummy) == refreshed, "normal damage preserves single support multiplier")
	choose(battle, "mummy_eternal_bandage")
	refreshed = stats(mummy)
	battle._refresh_alive_monsters_for_augments()
	check(stats(mummy) == refreshed and mummy.max_hp > old_max, "special HP scaling matches full refresh")
	var excluded = battle._spawn_monster("slime", Vector2(1200, 1000), 0.0, false, {"exclude_all_augments": true})
	excluded.set_physics_process(false)
	var excluded_stats := stats(excluded)
	choose(battle, "slime_hp")
	check(stats(excluded) == excluded_stats and excluded.special_augment_configs.is_empty(), "augment-excluded actor remains unchanged")
	var elite = battle._spawn_monster("slime", Vector2(1200, 1000))
	elite.set_physics_process(false)
	battle._apply_special_monster_modifiers(elite, "slime", {"type": "elite", "name": "test", "hp_multiplier": 2.0, "damage_multiplier": 1.5, "speed_multiplier": 1.2})
	choose(battle, "slime_speed")
	var elite_stats := stats(elite)
	battle._refresh_alive_monsters_for_augments()
	check(stats(elite) == elite_stats, "elite runtime variant matches full refresh")
	var old_slime_speed: float = new_slime.move_speed
	var old_mummy_speed: float = mummy.move_speed
	var global_effect := {"effects": [{"op": "multiply_runtime", "target": "monster_speed_multiplier", "value": 1.1}]}
	battle._apply_demon_augment(global_effect)
	battle._refresh_monsters_for_selected_augment(global_effect)
	check(is_equal_approx(new_slime.move_speed, old_slime_speed * 1.1) and is_equal_approx(mummy.move_speed, old_mummy_speed * 1.1), "future global effect refreshes all types")
	# Level-up/opening path uses the same cached special calculations.
	started = Time.get_ticks_usec()
	battle._gain_demon_exp(battle.demon_exp_to_next_level)
	print("AUGMENT_PERF n=%d level_up_open_ms=%.3f" % [battle.active_monsters.size(), (Time.get_ticks_usec() - started) / 1000.0])
	check(battle.demon_level == 2 and battle.demon_augment_selection_active, "level-up opens real modal")
	check(not battle.hero.is_physics_processing() and not actors[0].is_physics_processing(), "modal retains combat pause")
	battle.set_external_pause(false)
	check(not actors[0].is_physics_processing(), "modal alone retains pause after external pause releases")
	check(not battle.choose_demon_augment("missing_augment") and battle.demon_augment_selection_active, "invalid choice retains modal")
	check(battle.choose_demon_augment(String(battle.demon_augment_candidates[0].id)), "real rolled candidate is selectable")
	check(battle.hero.is_physics_processing() and actors[0].is_physics_processing(), "completed choice resumes combat")
	battle.free()
	await create_timer(0.2).timeout
	print("AUGMENT_REFRESH: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
