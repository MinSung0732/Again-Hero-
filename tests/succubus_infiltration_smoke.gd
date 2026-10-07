extends SceneTree

const POLICY := preload("res://src/systems/hero_target_policy.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("INFILTRATION: " + message)


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://infiltration_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1400, 1400)
	var hidden = battle._spawn_monster("succubus", Vector2(1480, 1400))
	var visible_monster = battle._spawn_monster("orc", Vector2(1800, 1400))
	hidden.set_physics_process(false)
	visible_monster.set_physics_process(false)
	visible_monster.max_hp = 100000
	visible_monster.current_hp = 100000
	await physics_frame
	await physics_frame
	var layer: int = hidden.collision_layer
	var mask: int = hidden.collision_mask
	var disabled: bool = hidden.collision_shape.disabled
	var revision: int = POLICY.revision
	check(hero._get_monster_nodes_cached().has(hidden), "visible actor enters cached query")
	battle.count_monsters_near(hidden.position, 40)
	hidden.take_damage(100000)
	check(POLICY.revision == revision + 1, "entry invalidates detection caches once")
	check(hidden.collision_layer == 0 and hidden.collision_mask == 0, "immediate collision filtering")
	check(not hero._get_monster_nodes_cached().has(hidden), "same-frame cached query excludes infiltration")
	check(battle.get_nearest_hostile_target_for_hero(hero.position) == visible_monster, "nearest hero target skips hidden")
	check(battle.get_nearest_monster_target(hero.position, 800) == visible_monster, "summon nearest target skips hidden")
	check(battle.count_monsters_near(hidden.position, 40) == 0, "same-frame grid count excludes hidden")
	var scratch: Array = []
	hero._fill_monster_nodes_near(hidden.position, 50, scratch)
	check(not scratch.has(hidden), "near query excludes hidden")
	hero._fill_monster_nodes_in_rect(Rect2(hidden.position - Vector2(30, 30), Vector2(60, 60)), scratch)
	check(not scratch.has(hidden), "rectangle query excludes hidden")
	battle.fill_active_monsters(scratch)
	check(scratch.has(hidden) and battle.active_monsters.has(hidden.get_instance_id()), "growth and buff registry retains hidden")
	check(hidden.is_in_group("monsters"), "no group or population removal")
	check(int(hero._build_ai_context().total_count) == 1, "current AI composition excludes infiltration")
	# Each real profile must discard a retained target before its own action branch.
	for profile in PROFILES.PROFILES.values():
		hero.configure_profile(profile)
		hero.position = Vector2(1400, 1400)
		hero.target = hidden
		hero.retarget_timer = 10.0
		hero.attack_timer = 1000.0
		hero._physics_process(0.01)
		check(hero.target != hidden, "cached target released: " + String(profile.id))
	# End profile-created attacks before testing collision restoration in isolation.
	for child in battle.get_children():
		if child.has_method("deactivate_for_pool"):
			child.call("deactivate_for_pool")
		elif child.is_in_group("hero_summons") and child.has_method("deactivate"):
			child.call("deactivate")
	# Summon fallback acquisition and retained pursuit use the same policy.
	for name in ["Scout", "Hound", "Watcher", "SuicideDrone", "Gatekeeper"]:
		var summon = load("res://src/hero/Summoner%s.tscn" % name).instantiate()
		battle.add_child(summon)
		summon.set_physics_process(false)
		summon.position = Vector2(1400, 1400)
		check(summon._find_nearest_target() != hidden, "summon acquisition: " + name)
		if name != "Gatekeeper":
			summon.activate(Vector2(1400, 1400), hero, {})
			summon.set_physics_process(false)
			if name != "SuicideDrone":
				summon.visual.play(&"idle")
			summon.target = hidden
			summon.retarget_timer = 10.0
			if name != "SuicideDrone":
				summon.attack_timer = 1000.0
			summon._physics_process(0.01)
			check(summon.target != hidden, "summon retained target released: " + name)
		summon.free()
	var orb = load("res://src/hero/SageRadianceOrb.tscn").instantiate()
	battle.add_child(orb)
	orb.set_physics_process(false)
	orb.state = orb.OrbState.TRAVEL
	orb.tracked_target = hidden
	orb.destination = hidden.position
	orb._physics_process(0.001)
	check(orb.tracked_target == null, "released sage orb loses hidden tracking")
	orb.free()
	# An actual physics body can pass through during infiltration, then collides again.
	var probe := CharacterBody2D.new()
	probe.collision_layer = 0
	probe.collision_mask = 2
	var probe_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	probe_shape.shape = circle
	probe.add_child(probe_shape)
	battle.add_child(probe)
	await physics_frame
	await physics_frame
	check(hidden.collision_shape.disabled, "deferred shape disabled")
	probe.position = hidden.position - Vector2(80, 0)
	check(probe.move_and_collide(Vector2(160, 0)) == null, "physical pass-through during infiltration")
	check(bool(hidden.get_meta("ignore_monster_separation", false)), "soft separation excludes hidden")
	# Prime a hidden snapshot; exit must restore detection in that same frame.
	hero._get_monster_nodes_cached()
	hidden._tick_infiltration(3)
	check(hero._get_monster_nodes_cached().has(hidden), "same-frame exit restores cache membership")
	check(hidden.collision_layer == layer and hidden.collision_mask == mask, "restore original collision masks")
	check(not bool(hidden.get_meta("ignore_monster_separation", false)), "restore separation")
	await physics_frame
	await physics_frame
	check(hidden.collision_shape.disabled == disabled, "restore original shape state")
	probe.position = hidden.position - Vector2(80, 0)
	var collision := probe.move_and_collide(Vector2(160, 0))
	check(collision != null and collision.get_collider() == hidden, "physical collision returns after expiry")
	probe.free()
	# Alternate entry route and pre-existing disabled settings are also preserved.
	var alternate = battle._spawn_monster("succubus", Vector2(2000, 1400))
	alternate.set_physics_process(false)
	alternate.collision_layer = 16
	alternate.collision_mask = 4
	alternate.collision_shape.disabled = true
	alternate.set_meta("ignore_monster_separation", true)
	alternate.configure_special_augments({"succubus_danger_sense": {"hp_ratio": 0.3}})
	alternate.current_hp = int(alternate.max_hp * 0.2)
	alternate._physics_process(0.01)
	check(not POLICY.is_detectable(alternate), "threshold route hides actor")
	alternate._tick_infiltration(3)
	await process_frame
	check(alternate.collision_layer == 16 and alternate.collision_mask == 4 and alternate.collision_shape.disabled, "preserve custom disabled collision state")
	check(bool(alternate.get_meta("ignore_monster_separation", false)), "preserve original separation exclusion")
	battle.free()
	await process_frame
	print("INFILTRATION: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
