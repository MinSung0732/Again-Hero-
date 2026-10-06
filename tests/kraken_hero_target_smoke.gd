extends SceneTree
const TENTACLE := preload("res://src/monsters/kraken_tentacle_fx.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("KRAKEN_HERO: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://kraken_hero_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1600,1600)
	hero.max_hp = 100000
	hero.current_hp = 100000
	var monsters: Array = []
	for index in range(6):
		var k = battle._spawn_monster("kraken", hero.position + Vector2.from_angle(TAU * index / 6) * 1000)
		k.max_hp = 100000
		k.current_hp = 100000
		k.set_physics_process(false)
		monsters.append(k)
	# Put six turrets in buckets returned by the broad-phase query, but outside
	# the true 850px pressure radius. They remain valid attack targets.
	for index in range(6):
		monsters[index].position = hero.position + Vector2.from_angle(TAU * index / 6) * 900
	battle.monster_spatial_grid_physics_frame = -1
	hero.ranged_pressure_refresh_timer = 0
	hero._update_ranged_pressure_cache(0.2)
	check(hero.ranged_pressure_count == 0, "pressure counts only actual sensing radius")
	for index in range(6):
		monsters[index].position = hero.position + Vector2.from_angle(TAU * index / 6) * 700
	battle.monster_spatial_grid_physics_frame = -1
	hero.ranged_pressure_refresh_timer = 0
	hero._update_ranged_pressure_cache(0.2)
	check(hero.ranged_pressure_count == 6 and hero._has_ranged_pressure(), "nearby turrets retain ranged pressure")
	var target = monsters[0]
	var direction: Vector2 = hero._choose_move_direction(target,700)
	check(direction.dot(hero.position.direction_to(target.position)) > 0.99, "approach stationary target outside own attack range despite pressure")
	target.position = hero.position + Vector2(300,0)
	battle.monster_spatial_grid_physics_frame = -1
	hero.ranged_pressure_count = 0
	hero.combat_strafe_burst_timer = 0
	check(hero._choose_move_direction(target,300) == Vector2.ZERO, "single turret in firing band retains stand-and-shoot behavior")
	var old_range: float = hero.attack_range
	hero.attack_range = 80
	check(hero._choose_melee_spacing_direction(target,300,0.9).dot(Vector2.RIGHT) > 0.99, "melee approaches body")
	hero.attack_range = old_range
	TENTACLE.show_at(battle, hero.position)
	var count: int = battle.active_monsters.size()
	check(count == 6 and hero._find_nearest_monster() == target, "tentacle near hero does not replace body target or enter registry")
	for fx in battle.get_children():
		if fx is AnimatedSprite2D and fx.sprite_frames == TENTACLE.cached_frames:
			check(not fx.is_in_group("monsters") and not fx is CollisionObject2D, "tentacle is noncombat noncollision visual")
	# Actual simulation: previously the hero orbited outside firing range.
	for index in range(6):
		monsters[index].position = hero.position + Vector2.from_angle(TAU * index / 6) * 700
	battle.monster_spatial_grid_physics_frame = -1
	hero.target = null
	hero.retarget_timer = 0
	hero.set_physics_process(true)
	var fired := false
	for i in range(300):
		await physics_frame
		for k in monsters:
			if k.current_hp < 100000:
				fired = true
		if fired:
			break
	check(fired, "live ranged hero reaches firing range and damages turret")
	check(hero.current_hp > 0, "hero remains alive")
	hero.set_physics_process(false)
	battle.free()
	await process_frame
	print("KRAKEN_HERO: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
