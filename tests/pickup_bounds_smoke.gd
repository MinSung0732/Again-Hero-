extends SceneTree
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks += 1
	if not ok: failures += 1; push_error(message)
func inside(point: Vector2,bounds: Rect2) -> bool:
	return point.x >= bounds.position.x and point.y >= bounds.position.y and point.x <= bounds.end.x and point.y <= bounds.end.y
func run():
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var placement = load("res://src/systems/pickup_placement.gd")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	battle._monster_spawn_resources_warmed = true
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(battle)
	battle.hero_player_mode = true
	var hero = battle.hero
	var bounds: Rect2 = hero._get_battlefield_movement_bounds()
	check(bounds.position.y == 357.0,"real castle wall + hero clearance is 357, not item margin 150")
	for point in [Vector2(-100,-100),Vector2(300,150),Vector2(99999,99999),Vector2(200,500),bounds.position,bounds.end]:
		var safe: Vector2 = placement.clamp_local(battle,point)
		check(inside(safe,bounds),"all four edges are reachable")
		hero.position = safe; hero._clamp_to_battlefield()
		check(hero.position == safe,"same authority as actual hero movement")
	# Random generator can hit the original forbidden top band deterministically.
	seed(2387)
	for index in 80:
		battle._spawn_random_heal_item(); battle._spawn_random_magnet_item()
		for registry in [battle.active_heal_items,battle.active_magnet_items]:
			for item in registry.values():
				check(inside(item.position,bounds),"random heal/magnet spawn inside hero bounds immediately")
				item.free()
			registry.clear()
		hero.position = bounds.position+Vector2(30,0)
		check(battle._spawn_random_treasure_chest(),"chest spawns near upper corner")
		for item in battle.active_treasure_chests.values():
			check(inside(item.position,bounds),"chest spawn inside hero bounds immediately")
			item.free()
		battle.active_treasure_chests.clear()
	# Repair externally spawned items, then actually collect at the upper limit.
	hero.position = Vector2(400,bounds.position.y)
	for kind in ["HealItem","MagnetItem"]:
		var item = load("res://src/battle/"+kind+".tscn").instantiate()
		battle.add_child(item); item.position = Vector2(400,150)
		var hp_before: int = hero.current_hp
		if kind == "HealItem": hero.current_hp = hero.max_hp-100; hp_before = hero.current_hp
		item._physics_process(0.01)
		check(item.position.y == bounds.position.y,"external item rescued from wall")
		if kind == "HealItem": check(item.collected and hero.current_hp > hp_before,"actual healing item collected from movement limit")
		else: check(item.picked_up and battle._remaining_exp_magnet_seconds() > 0,"actual magnet collected from movement limit")
	await process_frame
	battle.exp_magnet_until_msec = 0
	# Pool setup and scatter cannot escape the boundary, including reused orbs.
	for attempt in 2:
		battle._spawn_exp_orb(Vector2(400,120),5,Vector2(0,-1000),0.35)
		var orb = get_nodes_in_group("exp_orbs")[0]
		check(inside(orb.position,bounds),"EXP drop clamped on creation/reuse")
		for step in 22:
			orb._physics_process(0.01)
			check(inside(orb.position,bounds),"burst stays below castle wall")
		check(not orb._placement_pending,"placement initialized per activation")
		orb.pickup_delay_left = 0.0; orb.idle_sense_timer = 0.0; orb.burst_time = 0.0
		hero.position = orb.position
		var exp_before: int = hero.current_exp
		orb._physics_process(0.01)
		check(hero.current_exp == exp_before+5 and not orb.visible,"EXP collected exactly once and recycled")
	# High magnet speed/long mobile frame must not cross the wall on overshoot.
	for global_pull in [true,false]:
		battle._spawn_exp_orb(Vector2(400,bounds.position.y+40),5)
		var orb = get_nodes_in_group("exp_orbs")[0]
		hero.position = Vector2(400,bounds.position.y)
		if global_pull:
			orb.activate_global_magnet(hero,2.0); orb.global_magnet_elapsed = 2.0
		else: orb.magnetized = true
		orb._physics_process(0.15)
		check(inside(orb.position,bounds),"fast attraction cannot cross a map edge")
		orb._physics_process(0.01)
		check(not orb.visible,"overshooting attraction still delivers EXP")
	# Cauldron materials use the same rule on activate and landing.
	var material = load("res://src/hero/AlchemyMaterial.tscn").instantiate(); battle.add_child(material)
	material.activate(Vector2(400,100),20)
	check(inside(material.position,bounds),"alchemist material spawn corrected")
	material.launch_from_cauldron(Vector2(400,400),Vector2(400,100),0.05,50)
	material._process(0.1)
	check(inside(material.position,bounds) and not material.in_flight,"cauldron landing remains collectible")
	material.free()
	# Mode isolation: keep existing demon-mode placements and scatter semantics.
	battle.hero_player_mode = false
	check(placement.clamp_local(battle,Vector2(400,150)) == Vector2(400,150),"demon-mode placement unchanged")
	var item = load("res://src/battle/HealItem.tscn").instantiate(); battle.add_child(item); item.position = Vector2(200,150)
	item._physics_process(0.01)
	check(item.position == Vector2(200,150),"demon-mode external item unchanged")
	battle.queue_free(); await process_frame
	print("PICKUP_BOUNDS checks=",checks," failures=",failures)
	quit(1 if failures else 0)
