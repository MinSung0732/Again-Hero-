extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SUCCUBUS_TEST: " + message)

func spawn():
	var actor = battle._spawn_monster("succubus", Vector2(1100,1000))
	actor.set_physics_process(false)
	return actor

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://succubus_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1000,1000)
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	var first = spawn()
	var second = spawn()
	check(CATALOG.get_rarity("succubus") == "legendary" and CATALOG.get_base_cost("succubus") == 13.5, "legendary cost")
	check(load("res://src/data/shop_catalog.gd").get_monster_pool("legendary").has("succubus"), "real legendary pool")
	check(first.visual.sprite_frames.get_frame_count("attack") == 6, "normal supplied frames")
	for i in range(15):
		hero.invulnerability_timer = 0
		(first if i % 2 == 0 else second)._deal_hit(hero, 10)
	check(hero.charm_timer == 2.0 and hero.charm_stacks == 0 and hero.charm_source.get_ref() == first, "shared stacks charm last source")
	var hp: int = first.current_hp
	hero._physics_process(0.1)
	check(first.current_hp == hp and hero.velocity.x > 0 and is_equal_approx(hero.velocity.length(), hero.move_speed * 0.6), "charm seals attacks and approaches at slow speed")
	hero.invulnerability_timer = 0
	check(first._deal_hit(hero,100) > 100, "charmed extra damage")
	hero._tick_charm_timers(1.9)
	check(hero.charm_timer <= 0.0 and is_equal_approx(hero.charm_immunity_timer,7.0), "immunity starts at charm end")
	for i in range(20):
		hero.register_succubus_hit(first)
	check(hero.charm_stacks == 0, "immune hits do not bank stacks")
	hero._tick_charm_timers(7)
	check(hero.apply_charm(first,2), "charm allowed after immunity")
	hero.apply_petrify(1)
	var pos: Vector2 = hero.global_position
	hero._physics_process(0.1)
	check(hero.global_position == pos and hero.velocity == Vector2.ZERO, "petrify blocks charm movement")
	hero._clear_charm()
	hero._clear_medusa_statuses()
	var survivor = spawn()
	survivor.configure_special_augments({"succubus_shadow_recovery": AUGMENTS.get_augment("succubus_shadow_recovery").effect_values, "succubus_shadow_ambush": AUGMENTS.get_augment("succubus_shadow_ambush").effect_values})
	var base_damage: int = survivor.attack_damage
	survivor.take_damage(100000)
	check(not survivor.dying and survivor.current_hp == int(round(survivor.max_hp * 0.3)) and survivor.infiltration_timer == 3, "fatal survives once and heals to thirty percent")
	hp = survivor.current_hp
	survivor.take_damage(100000)
	survivor._physics_process(1)
	check(survivor.current_hp == hp and survivor.velocity == Vector2.ZERO and is_equal_approx(survivor.visual.modulate.a,0.4), "infiltration immune action locked translucent")
	survivor._physics_process(2)
	check(survivor.infiltration_finished and survivor.attack_damage == int(round(base_damage * 1.2)), "exit twenty percent growth")
	battle._apply_demon_level_scaling_to_monster(survivor,true)
	check(survivor.attack_damage == int(round(base_damage * 1.2)), "growth does not compound exit bonus")
	survivor.take_damage(100000)
	check(survivor.dying, "second fatal death")
	var threshold = spawn()
	threshold.configure_special_augments({"succubus_danger_sense": AUGMENTS.get_augment("succubus_danger_sense").effect_values})
	threshold.take_damage(int(threshold.max_hp * 0.75))
	check(threshold.infiltration_timer == 3 and threshold.current_hp > 1, "thirty percent trigger before fatal")
	var elite = spawn()
	battle._apply_special_monster_modifiers(elite, "succubus", {"type":"elite", "hp_multiplier":2.0, "damage_multiplier":2.0, "attack_speed_multiplier":1.2})
	check(elite.visual.sprite_frames.get_frame_count("attack") == 5 and elite.visual.sprite_frames.get_frame_count("death") == 5, "supplied elite animations")
	var runtime = battle.elite_monster_skill_runtime
	var registered: Array = runtime._skill_states[elite.get_instance_id()].skills
	check(registered.size() == 3 and registered[0]._timer == 0 and registered[1]._timer == 6 and registered[2]._timer == 10, "three skills registered with real initial timers")
	var skills: Array = CATALOG.get_monster("succubus").elite_skills
	hero.invulnerability_timer = 0
	hero.get_node("HeroSprite").flip_h = false
	check(elite.try_cast_elite_skill(skills[0]) and elite.global_position.x < hero.global_position.x, "cut teleports behind target")
	check(elite.damage_bank > 0, "cut records actual damage")
	elite.current_hp = 1
	var bank: int = elite.damage_bank
	check(elite.try_cast_elite_skill(skills[1]) and elite.current_hp == 1 + int(round(bank * 0.55)) and elite.damage_bank == 0, "drain consumes real damage bank")
	check(not elite.try_cast_elite_skill(skills[1]), "empty drain waits")
	elite.current_hp = elite.max_hp
	check(elite.try_cast_elite_skill(skills[2]), "waltz starts")
	elite.take_damage(20)
	check(elite.current_hp == elite.max_hp - 10, "waltz half received damage")
	elite.current_hp = 1
	var before: int = hero.current_hp
	for i in range(5):
		hero.invulnerability_timer = 0
		elite._tick_waltz(0.5)
	check(elite.waltz_index == 5 and not elite.waltz_active and elite.waltz_distributed == elite.attack_damage * 2, "five ticks exact total two hundred percent")
	check(elite.waltz_actual_damage == before - hero.current_hp and elite.current_hp == 1 + int(round(elite.waltz_actual_damage * 0.4)), "waltz heals exact actual forty percent")
	var interrupted = spawn()
	interrupted.try_cast_elite_skill(skills[2])
	interrupted.take_damage(100000)
	check(interrupted.infiltration_timer == 3 and not interrupted.waltz_active and is_equal_approx(interrupted.visual.modulate.a,0.4), "fatal cancels waltz into infiltration")
	for candidate in AUGMENTS.get_monster_normal_augments("succubus", ""):
		check(AUGMENTS.get_augment(candidate.id) == candidate, "normal augments registered")
	# Every profile goes through the common charm gate before its own AI dispatch.
	for profile in load("res://src/data/hero_profiles.gd").PROFILES.values():
		hero.configure_profile(profile)
		hero.position = Vector2(1000,1000)
		hero.apply_charm(first,2)
		hp = first.current_hp
		hero._physics_process(0.01)
		check(first.current_hp == hp and hero.charm_timer > 0, "charm gates profile " + String(profile.id))
		hero._clear_charm()
	# A solid obstacle behind the target forces a safe alternate angle.
	var obstacle := StaticBody2D.new()
	obstacle.collision_layer = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50,50)
	shape.shape = rect
	obstacle.add_child(shape)
	battle.add_child(obstacle)
	obstacle.global_position = hero.global_position + Vector2(-64,0)
	await physics_frame
	await physics_frame
	check(elite._teleport_near(hero,Vector2.LEFT), "teleport finds alternate unblocked angle")
	check(absf(elite.global_position.x - obstacle.global_position.x) > 45 or absf(elite.global_position.y - obstacle.global_position.y) > 45, "teleport body avoids obstacle")
	obstacle.queue_free()
	print("SUCCUBUS_TEST: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
