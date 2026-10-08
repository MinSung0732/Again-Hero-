extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const POLICY := preload("res://src/systems/hero_target_policy.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("POPULATION_SUMMONER: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://population_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	battle.hero.set_physics_process(false)
	battle.hero.position = Vector2(2000, 2000)
	battle.loadout_restriction_enabled = false
	battle.max_command = 2.9
	battle.command_power = 999
	battle.demon_exp_to_next_level = 1000000
	check(battle.try_summon("slime") and battle.try_summon("slime"), "two direct units fit floored command capacity")
	var funds: float = battle.command_power
	check(not battle.try_summon("slime") and battle.command_power == funds, "cap rejects without charge")
	var primary = battle.active_monsters.values()[0]
	for i in range(4):
		var extra = battle._spawn_monster("slime", Vector2(500, 500), 0, i % 2 == 0)
		extra.set_physics_process(false)
	check(battle.get_population_count() == 2 and battle.monsters_alive == 6, "children/skill summons do not reserve population")
	primary.take_damage(100000)
	check(battle.get_population_count() == 1, "death frees slot before removal animation")
	check(battle.try_summon("slime"), "new summon allowed immediately after death")
	battle._unregister_monster(primary.get_instance_id())
	check(battle.get_population_count() == 2, "unregister is idempotent")
	battle.max_command = 3
	check(battle.try_summon("slime") and battle.get_population_count() == 3, "capacity increase takes effect immediately")
	# Actual watcher registry: immortal support should never be a combat target.
	var watcher = load("res://src/hero/SummonerWatcher.tscn").instantiate()
	battle.add_child(watcher)
	watcher.activate(Vector2(500, 500), battle.hero, {})
	watcher.set_physics_process(false)
	battle.set_hero_summon_active(watcher, true)
	check(battle.get_nearest_hero_combat_target(Vector2(500, 500)) == battle.hero, "army ignores invulnerable watcher")
	for name in ["Gatekeeper", "Scout", "Hound"]:
		var follower = load("res://src/hero/Summoner%s.tscn" % name).instantiate()
		battle.add_child(follower)
		check(follower.collision_layer == 0 and (follower.collision_mask & 2) == 0 and (follower.collision_mask & 12) == 12, "follower has no crowd body blocking but preserves walls: " + name)
		follower.global_position = battle.hero.global_position + Vector2(40, 0)
		follower.set_physics_process(false)
		await physics_frame
		check(battle.hero.move_and_collide(Vector2(80, 0), true) == null, "hero can move through follower body: " + name)
	var victims: Array = []
	for point in [Vector2(700, 700), Vector2(795, 700), Vector2(801, 700), Vector2(700, 760)]:
		var victim = battle._spawn_monster("slime", point)
		victim.set_physics_process(false)
		victim.max_hp = 1000
		victim.current_hp = 1000
		victims.append(victim)
	POLICY.set_hidden(victims[3], true)
	var drone = load("res://src/hero/SummonerSuicideDrone.tscn").instantiate()
	battle.add_child(drone)
	drone.activate(Vector2(700, 700), battle.hero, {"owner_attack_damage": 100, "damage_ratio": 0.30, "explosion_radius": 100})
	drone.target = victims[0]
	drone._explode_on_target()
	check(victims[0].current_hp == 970 and victims[1].current_hp == 970, "drone damages multiple units inside radius")
	check(victims[2].current_hp == 1000 and victims[3].current_hp == 1000, "outside radius and hidden units untouched")
	drone._explode_on_target()
	check(victims[0].current_hp == 970, "pooled drone cannot explode twice")
	# 800 actors in one local cell: steering bounded, AoE hit lists complete.
	var dense: Array = []
	for i in range(800):
		var actor = battle._spawn_monster("slime", Vector2(1000, 1000))
		actor.set_physics_process(false)
		dense.append(actor)
	var grid = battle.monster_local_grid
	battle._ensure_monster_spatial_grid()
	grid.ensure(battle.active_monsters, battle.monster_spatial_snapshot_revision)
	var start := Time.get_ticks_usec()
	for actor in dense:
		check(grid.separation_bias(actor, 18).is_finite(), "dense steering remains finite")
	print("DENSE_SWARM n=800 separation_full_pass_ms=", (Time.get_ticks_usec() - start) / 1000.0)
	var all_hits: Array = []
	grid.fill_rect(Rect2(990, 990, 20, 20), all_hits)
	check(all_hits.size() == 800, "dense movement sampling never truncates area hit set")
	check(battle.get_population_count() == 3, "800 generated units remain population exempt")
	battle.max_command = 4
	battle.demon_special_augments.assign(["kobolt_giant_fusion"])
	var paid_kobolt = battle._spawn_monster("kobolt", Vector2(1200, 1200), 5, false, {"counts_population": true})
	for i in range(3):
		var extra = battle._spawn_monster("kobolt", Vector2(1200 + i * 5, 1200))
		extra.set_physics_process(false)
	var fused = battle._try_fuse_nearby_kobolts(paid_kobolt)
	check(is_instance_valid(fused) and bool(fused.get_meta("kobolt_fusion", false)) and battle.get_population_count() == 4, "mixed paid/extra fusion retains one population slot")
	battle._unregister_monster(fused.get_instance_id())
	check(battle.get_population_count() == 3, "fused actor releases inherited slot once")
	for actor in battle.active_monsters.values(): actor.set_physics_process(false)
	battle.free()
	await process_frame
	print("POPULATION_SUMMONER: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
