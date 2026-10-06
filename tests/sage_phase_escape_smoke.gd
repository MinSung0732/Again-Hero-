extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SAGE_PHASE_ESCAPE: " + message)

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var hero = load("res://src/hero/Hero.tscn").instantiate()
	world.add_child(hero)
	hero.set_physics_process(false)
	hero.configure_profile(load("res://src/data/hero_profiles.gd").get_profile("sage_astra"))
	check(hero.hero_archetype == "grand_sage_astra", "actual stage ten profile")
	hero.collision_mask = 14
	var prop := StaticBody2D.new()
	prop.collision_layer = 4
	prop.collision_mask = 0
	prop.position = Vector2(600, 600)
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(160, 160)
	collider.shape = rectangle
	prop.add_child(collider)
	world.add_child(prop)
	await physics_frame
	await physics_frame
	for offset in [Vector2.ZERO, Vector2(78, 0), Vector2(-78, -78)]:
		hero.position = Vector2(400, 400)
		hero._start_sage_phase()
		check(hero.collision_mask == 8, "phase preserves wall mask")
		hero.position = prop.position + offset
		var trapped: Vector2 = hero.position
		hero.petrify_timer = 2.0
		hero.petrify_anchor = hero.global_position
		hero._end_sage_phase()
		await process_frame
		await process_frame
		check(hero.collision_mask == 14, "collision restored")
		check(hero.position.distance_to(trapped) > 0 and hero.position.distance_to(trapped) < 180, "nearby ejection")
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = hero.get_node("CollisionShape2D").shape
		query.transform = hero.get_node("CollisionShape2D").global_transform
		query.collision_mask = 12
		query.exclude = [hero.get_rid()]
		query.margin = 1.9
		check(world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(), "landing outside obstacle including body radius")
		check(hero.petrify_anchor == hero.global_position, "petrify keeps corrected anchor")
		hero._clamp_to_battlefield()
		check(hero.petrify_anchor == hero.global_position, "petrify does not undo ejection")
		hero.petrify_timer = 0
		check(hero.shield_hp > 0 and hero.sage_phase_cooldown_timer > 0, "post-phase shield/cooldown preserved")
	hero.position = Vector2(400, 400)
	hero._start_sage_phase()
	hero._end_sage_phase()
	await process_frame
	await process_frame
	check(hero.position == Vector2(400, 400), "empty-space expiry stays in place")
	# A prop against the map edge must never eject outside the playable bounds.
	prop.position = Vector2(48, 600)
	await physics_frame
	await physics_frame
	hero.position = Vector2(300, 600)
	hero._start_sage_phase()
	hero.position = Vector2(48, 600)
	hero._end_sage_phase()
	await process_frame
	await process_frame
	check(hero.position.x >= hero.FIELD_MARGIN and hero.position.y >= hero.FIELD_MARGIN, "edge landing stays inside battlefield")
	check(hero.position.distance_to(Vector2(48, 600)) > 100, "edge prop escaped")
	prop.position = Vector2(1600, 1600)
	rectangle.size = Vector2(2000, 2000)
	await physics_frame
	await physics_frame
	hero.position = Vector2(400, 400)
	hero._start_sage_phase()
	hero.position = prop.position
	hero._end_sage_phase()
	await process_frame
	await process_frame
	check(hero.position == Vector2(400, 400), "oversized prop uses checked phase entry fallback")
	world.free()
	await process_frame
	await process_frame
	print("SAGE_PHASE_ESCAPE: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
