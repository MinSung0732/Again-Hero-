extends SceneTree
## Real Stage 4 Battle with the pistol gunner AI: the archetype runtime must
## drive firing, reloading and its forwarders through live physics frames.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
# Loaded at run time: hero.gd needs autoloads that exist only after startup.
const GUNNER_ARCHETYPE_PATH := "res://src/hero/archetypes/hero_gunner_archetype.gd"
var checks := 0
var failures := 0


func _initialize() -> void: run.call_deferred()


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("GUNNER_ARCHETYPE_FAIL " + label)


func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	# Isolated guest save so the test never touches real progress.
	SCOPE.guest_directory = "user://gunner_archetype_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	PROGRESS.set_current_stage("stage_4")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	expect(hero.hero_archetype == "pistol_gunner", "stage 4 hero is the pistol gunner")
	hero.max_hp = 1000000
	hero.current_hp = hero.max_hp
	var runtime = hero._gunner_archetype()
	expect(runtime != null and runtime.get_script() == load(GUNNER_ARCHETYPE_PATH), "archetype runtime created")
	expect(is_same(runtime, hero._gunner_archetype()), "runtime cached per hero")
	expect(is_same(runtime.hero, hero), "runtime bound to its hero")

	var roster: Array = []
	for monster_type in ["slime", "orc", "spider"]:
		var actor = battle._spawn_monster(monster_type, hero.global_position + Vector2(220, 0).rotated(roster.size() * 2.1))
		if is_instance_valid(actor):
			actor.max_hp = 1000000
			actor.current_hp = actor.max_hp
			roster.append(actor)
	expect(not roster.is_empty(), "targets spawned")

	var start_ammo: int = hero.gunner_ammo
	var saw_shot := false
	var saw_reload := false
	for frame in 900:
		await physics_frame
		if hero.gunner_ammo < start_ammo or hero.gunner_reloading:
			saw_shot = true
		if hero.gunner_reloading:
			saw_reload = true
		start_ammo = mini(start_ammo, hero.gunner_ammo) if not hero.gunner_reloading else hero.gunner_ammo
	expect(saw_shot, "gunner AI fired through the archetype runtime")
	expect(saw_reload, "gunner AI reloaded through the archetype runtime")
	expect(hero.current_hp > 0, "hero survived the probe")

	# Direct forwarders keep their method names for bindings/tests.
	for method in ["_physics_process_gunner", "_start_gunner_reload", "_gunner_should_start_deadeye", "_play_gunner_death_audio"]:
		expect(hero.has_method(method) and runtime.has_method(method), "forwarder and runtime share " + method)

	battle.queue_free()
	await process_frame
	if failures == 0:
		print("GUNNER_ARCHETYPE_LIVE_PASS checks=", checks)
		quit(0)
	else:
		print("GUNNER_ARCHETYPE_LIVE_FAIL failures=", failures, " checks=", checks)
		quit(1)
