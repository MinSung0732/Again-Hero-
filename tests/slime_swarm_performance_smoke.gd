extends SceneTree

const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const POLICY := preload("res://src/systems/hero_target_policy.gd")
var failed := false
var scratch: Array = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SWARM: " + message)


func legacy_bias(owner: Node2D, battle: Node) -> Vector2:
	var radius := clampf(owner.get_node("CollisionShape2D").shape.radius * 0.78, 18.0, 25.0)
	battle.fill_monsters_near(owner.global_position, radius, scratch)
	var bias := Vector2.ZERO
	for other in scratch:
		if other == owner or not is_instance_valid(other) or other.is_queued_for_deletion() or bool(other.get_meta("ignore_monster_separation", false)):
			continue
		var offset: Vector2 = owner.global_position - other.global_position
		var distance_sq := offset.length_squared()
		if distance_sq >= radius * radius:
			continue
		var distance := 0.0
		var away: Vector2
		if distance_sq <= 0.01:
			away = COMMON._deterministic_overlap_direction(owner.get_instance_id(), other.get_instance_id())
		else:
			distance = sqrt(distance_sq)
			away = offset / distance
		bias += away * (1.0 - clampf(distance / radius, 0.0, 1.0))
	return bias.normalized() if bias.length_squared() > 0.0001 else Vector2.ZERO


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://swarm_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	hero.configure_profile(PROFILES.get_profile("swift_hunter"))
	hero.position = Vector2(700, 1000)
	var actors: Array = []
	for i in range(128):
		var actor = battle._spawn_monster("slime", Vector2(1000 + (i % 16) * 11, 1000 + (i / 16) * 13))
		actor.set_physics_process(false)
		actor.max_hp = 100000
		actor.current_hp = 100000
		actors.append(actor)
	actors[1].position = actors[0].position
	actors[2].set_meta("ignore_monster_separation", true)
	for actor in actors:
		check(COMMON.compute_soft_separation_bias(actor, battle).distance_to(legacy_bias(actor, battle)) < 0.001 if not bool(actor.get_meta("ignore_monster_separation", false)) else COMMON.compute_soft_separation_bias(actor, battle) == Vector2.ZERO, "exact separation including overlap/ignored actor")
	# Forced moves must be visible in the same frame, across many local cells.
	actors[127].position = actors[0].position + Vector2(-12, 0)
	COMMON.notify_forced_position_change(actors[127])
	check(COMMON.compute_soft_separation_bias(actors[0], battle).distance_to(legacy_bias(actors[0], battle)) < 0.001, "same-frame forced move")
	# Ordinary movement across a local cell boundary stays inside the padding.
	actors[126].position = actors[0].position + Vector2(-15, 0)
	COMMON.notify_forced_position_change(actors[126])
	COMMON.compute_soft_separation_bias(actors[0], battle)
	actors[126].position += Vector2(8, 0)
	check(COMMON.compute_soft_separation_bias(actors[0], battle).distance_to(legacy_bias(actors[0], battle)) < 0.001, "ordinary same-frame cell crossing")
	actors[0].configure_special_augments({"slime_pack_instinct": {"radius": 180.0, "required_nearby": 2, "move_speed_multiplier": 1.18, "attack_speed_multiplier": 1.20}})
	check(is_equal_approx(float(actors[0]._get_pack_bonuses().get("move_speed_multiplier", 0)), 1.18), "pack enabled with two neighbors")
	actors[0].position = Vector2(3000, 3000)
	COMMON.notify_forced_position_change(actors[0])
	check(actors[0]._get_pack_bonuses().is_empty(), "pack disabled without neighbors")
	actors[0].configure_special_augments({})
	check(actors[0]._get_pack_bonuses().is_empty(), "pack configuration removed")
	# Real combo must keep the legacy capsule hit set and hidden-target policy.
	hero.position = Vector2(900, 1000)
	actors[0].position = Vector2(1050, 1000)
	COMMON.notify_forced_position_change(actors[0])
	POLICY.set_hidden(actors[3], true)
	var start: Vector2 = hero.global_position
	var direction: Vector2 = start.direction_to(actors[0].global_position)
	var stop := start + direction * minf(85.0, start.distance_to(actors[0].global_position) - 26.0)
	var end := stop + direction * 48.0
	var expected: Dictionary = {}
	for actor in actors:
		var nearest := Geometry2D.get_closest_point_to_segment(actor.global_position, start, end)
		expected[actor.get_instance_id()] = POLICY.is_detectable(actor) and nearest.distance_squared_to(actor.global_position) <= 95.0 * 95.0
	hero._rogue_combo_attack(actors[0])
	for actor in actors:
		check((actor.current_hp < 100000) == bool(expected[actor.get_instance_id()]), "legacy combo hit set")
	check(hero.rogue_combo_candidates.is_empty(), "combo scratch released")
	for i in range(actors.size()):
		actors[i].position = Vector2(1000 + (i % 16) * 10, 1000 + (i / 16) * 10)
	battle.invalidate_monster_spatial_snapshot()
	# Both timings use identical actors and the imported project in one run.
	for optimized in [false, true]:
		var t := Time.get_ticks_usec()
		for repeat in range(3):
			for actor in actors:
				if optimized:
					COMMON.compute_soft_separation_bias(actor, battle)
				else:
					legacy_bias(actor, battle)
		print("SWARM benchmark n=128 optimized=%s full_pass_ms=%.3f" % [optimized, float(Time.get_ticks_usec() - t) / 3000.0])
	for i in range(128, 512):
		var actor = battle._spawn_monster("slime", Vector2(1000 + (i % 16) * 10, 1000 + (i / 16) * 10))
		actor.set_physics_process(false)
		actors.append(actor)
	for optimized in [false, true]:
		var t := Time.get_ticks_usec()
		for repeat in range(3):
			for actor in actors:
				if optimized:
					COMMON.compute_soft_separation_bias(actor, battle)
				else:
					legacy_bias(actor, battle)
		print("SWARM benchmark n=512 optimized=%s full_pass_ms=%.3f" % [optimized, float(Time.get_ticks_usec() - t) / 3000.0])
	var local_candidates: Array = []
	var bounds := Rect2(950, 950, 200, 100)
	battle.fill_local_monsters_in_rect(bounds, local_candidates)
	var reference_count := 0
	for actor in actors:
		var point: Vector2 = actor.global_position
		if point.x >= bounds.position.x and point.y >= bounds.position.y and point.x <= bounds.end.x and point.y <= bounds.end.y:
			reference_count += 1
	check(local_candidates.size() == reference_count, "rectangle boundaries and same-frame spawned actors")
	print("SWARM rectangle live=%d local_candidates=%d" % [actors.size(), local_candidates.size()])
	actors[511].take_damage(100000)
	battle.fill_local_monsters_in_rect(Rect2(actors[511].position - Vector2.ONE * 100, Vector2.ONE * 200), local_candidates)
	check(not local_candidates.has(actors[511]), "same-frame death removes local candidate")
	battle.free()
	print("SWARM: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
