extends SceneTree

const PROJECTILE := preload("res://tests/pool_projectile_spy.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var script := load("res://tests/battle_boundary_fixture.gd") as Script
	if script == null:
		push_error("Build isolated fixture first")
		quit(1)
		return
	var battle = script.new()
	root.add_child(battle)
	var template := PROJECTILE.new()
	var scene := PackedScene.new()
	check(scene.pack(template) == OK, "in-memory projectile scene")
	template.free()
	var projectile = battle.acquire_projectile(scene, "fixture")
	projectile.registry = battle.battle_entity_registry
	var first: Vector3i = battle.get_battle_entity_handle(projectile)
	check(first.x == battle.battle_command_router.get_session_id(), "router and entity epochs aligned")
	check(battle.resolve_battle_entity(first) == projectile, "actual acquire hook")
	check(projectile.tree_exited.get_connections().size() == 1, "one lifecycle connection")
	projectile.captured_handle = first
	battle.recycle_projectile(projectile, "fixture")
	check(not projectile.old_handle_valid_during_deactivation and projectile.deactivations == 1, "retired before actual deactivation callback")
	check(battle.resolve_battle_entity(first) == null and battle.get_battle_entity_diagnostics().active_count == 0, "pool node inactive")
	var old := first
	for iteration in range(200):
		var acquired = battle.acquire_projectile(scene, "fixture")
		var current: Vector3i = battle.get_battle_entity_handle(acquired)
		if iteration % 20 == 0:
			check(acquired == projectile and current.z > old.z, "same Node new life")
			check(battle.resolve_battle_entity(old) == null, "stale pooled handle")
			check(acquired.tree_exited.get_connections().size() == 1, "connections do not accumulate")
			check(battle.get_battle_entity_diagnostics().slot_count == 1, "slots do not grow with activations")
		projectile.captured_handle = current
		battle.recycle_projectile(acquired, "fixture")
		old = current
	var acquired = battle.acquire_projectile(scene, "fixture")
	var before_exit: Vector3i = battle.get_battle_entity_handle(acquired)
	battle.remove_child(acquired)
	check(battle.resolve_battle_entity(before_exit) == null, "actual tree exit retires current life")
	battle.add_child(acquired)
	var after_exit: Vector3i = battle._activate_battle_entity(acquired)
	check(after_exit.z > before_exit.z and acquired.tree_exited.get_connections().size() == 1, "reenter with new generation and same connection")
	var monster := Node2D.new()
	battle.add_child(monster)
	var monster_handle: Vector3i = battle._activate_battle_entity(monster)
	var instance_id := monster.get_instance_id()
	battle.active_monsters[instance_id] = monster
	battle.direct_population_ids[instance_id] = true
	battle.monster_population_ids[instance_id] = "slime"
	battle.monster_population_counts["slime"] = 1
	battle._unregister_monster(instance_id)
	check(battle.resolve_battle_entity(monster_handle) == null, "actual monster unregister hook")
	check(battle.active_monsters.is_empty() and battle.direct_population_ids.is_empty(), "existing population registries intact")
	check(battle.monster_population_counts.slime == 0 and battle.population_updates == 1, "original counters and signals preserved")
	battle._unregister_monster(instance_id)
	check(battle.population_updates == 1, "duplicate unregister has no extra population effect")
	var epoch: int = battle.battle_command_router.get_session_id()
	battle.battle_command_router.begin_session(battle._execute_battle_command)
	battle.battle_entity_registry.begin_session(battle.battle_command_router.get_session_id())
	check(battle.resolve_battle_entity(after_exit) == null, "restart drops old handles")
	var restarted: Vector3i = battle._activate_battle_entity(acquired)
	check(restarted.x > epoch and restarted.z == 1, "restart hook alignment")
	check(acquired.tree_exited.get_connections().size() == 1, "restart does not add callbacks")
	var full: Array = []
	full.resize(battle.MAX_PROJECTILE_POOL_PER_TYPE)
	battle.projectile_pools["overflow"] = full
	projectile.captured_handle = restarted
	battle.recycle_projectile(acquired, "overflow")
	check(acquired.is_queued_for_deletion() and battle.resolve_battle_entity(restarted) == null, "full pool discard invalidates handle immediately")
	var recreated = script.new()
	root.add_child(recreated)
	var other = recreated.acquire_projectile(scene, "fixture")
	var other_handle: Vector3i = recreated.get_battle_entity_handle(other)
	check(other_handle.x > restarted.x, "recreated battle has a fresh epoch")
	check(recreated.resolve_battle_entity(restarted) == null, "old battle cannot resolve a new battle slot")
	check(recreated.resolve_battle_entity(other_handle) == other, "new battle live handle")
	recreated.queue_free()
	battle.queue_free()
	await process_frame
	print("battle_entity_boundary_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
