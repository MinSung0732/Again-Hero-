extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const TENTACLE := preload("res://src/monsters/kraken_tentacle_fx.gd")
class TrainingTarget extends Node2D:
	var current_hp := 10000
	func take_damage(amount: int, _source: Node) -> void:
		current_hp -= amount
var failed := false
var battle
var hero
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("KRAKEN_TEST: " + message)
func spawn():
	var monster = battle._spawn_monster("kraken", hero.position + Vector2(1000,0))
	if is_instance_valid(monster):
		monster.set_physics_process(false)
	return monster
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://kraken_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	battle.set_process(false)
	battle.set_physics_process(false)
	hero = battle.hero
	hero.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	hero.position = Vector2(2000,2000)
	check(CATALOG.get_rarity("kraken") == "legendary" and CATALOG.get_species("kraken") == "beast" and CATALOG.get_base_cost("kraken") == 15, "catalog identity")
	for augment in AUGMENTS.get_monster_normal_augments("kraken", ""):
		check(AUGMENTS.get_augment(augment.id) == augment and not augment.name.ends_with("이동속도 증가"), "normal augment resolves, movement excluded")
	check(CATALOG.get_elite_skills("kraken").is_empty() and not battle.spawn_special_monster("kraken", {}), "no elite path")
	var monster = spawn()
	check(is_equal_approx(monster.position.distance_to(hero.position),1000), "spawn at radius 1000")
	check(monster.visual.sprite_frames.get_frame_count("death") == 4 and TENTACLE.cached_frames.get_frame_count("default") == 8, "existing body and tentacle frames")
	var old_position: Vector2 = monster.position
	var damage: int = monster.attack_damage
	hero.invulnerability_timer = 0
	monster._physics_process(0.01)
	check(monster.burst_index == 1 and monster.burst_count == 2, "first immediate strike")
	monster._physics_process(0.99)
	check(monster.burst_index == 1, "no premature second strike")
	hero.invulnerability_timer = 0
	monster._physics_process(0.01)
	check(monster.burst_index == 2, "second strike at one second")
	hero.invulnerability_timer = 0
	monster._physics_process(1.0)
	check(monster.burst_count == 0 and monster.growth_stacks == 1 and monster.growth_hits == 0, "third strike at two seconds, one growth stack")
	check(monster.position == old_position and monster.velocity == Vector2.ZERO, "fixed turret")
	var sibling = spawn()
	check(sibling.growth_stacks == 0, "growth isolated per instance")
	var training := TrainingTarget.new()
	battle.add_child(training)
	training.position = hero.position
	sibling.hero = training
	sibling._start_burst()
	sibling._tick_tentacle()
	sibling._tick_tentacle()
	check(training.current_hp == 10000 - damage, "three split strikes preserve exact total damage")
	training.free()
	monster.growth_stacks = 1000
	battle._apply_demon_level_scaling_to_monster(monster,true)
	check(abs(monster.attack_damage - damage * 2) <= 1, "fractional growth retained until integer damage rounds")
	hero.invulnerability_timer = 10
	monster._strike(hero, hero.position, 30, true)
	check(monster.growth_hits == 0, "rejected strike does not grow")
	monster.free()
	sibling.free()
	check(battle.monster_population_counts.kraken == 0, "tree exit removes count")
	battle.demon_special_augments.assign(CATALOG.MONSTERS.kraken.special_augment_ids)
	monster = spawn()
	var base: Dictionary = CATALOG.get_base_stats("kraken")
	var plain_hp := int(round(base.max_hp * CATALOG.get_rarity_combat_profile("kraken").hp_multiplier * battle._get_demon_level_monster_hp_multiplier()))
	check(monster.max_hp == plain_hp * 2 or abs(monster.max_hp - plain_hp * 2) <= 1, "titan doubles HP")
	check(monster.attack_damage == damage * 4 or abs(monster.attack_damage - damage * 4) <= 2, "two augments multiply damage")
	check(is_equal_approx(monster.attack_cooldown, base.attack_cooldown * CATALOG.get_rarity_combat_profile("kraken").attack_cooldown_multiplier * 0.5), "titan doubles attack rate")
	check(monster.attack_range == 2000 and monster.scale == Vector2.ONE * 1.5 and monster.move_speed == 0, "titan range, size, stationary")
	var hp: int = monster.max_hp
	var cooldown: float = monster.attack_cooldown
	battle._refresh_alive_monsters_for_augments()
	check(monster.max_hp == hp and is_equal_approx(monster.attack_cooldown, cooldown), "refresh does not compound stats")
	var second = spawn()
	var third = spawn()
	check(spawn() == null, "fourth spawn prevented")
	battle.loadout_restriction_enabled = false
	battle.demon_augment_selection_active = false
	battle.external_pause = false
	battle.battle_over = false
	var command: float = battle.command_power
	check(not battle.try_summon("kraken") and battle.command_power == command, "blocked summon costs no resource")
	second.free()
	check(battle.monster_population_counts.kraken == 2 and is_instance_valid(spawn()), "slot reusable after removal")
	monster._start_burst()
	check(monster.burst_count == 5, "barrage uses six strikes")
	monster.position = hero.position + Vector2(50,0)
	monster._physics_process(0.01)
	check(monster.dodge_used and monster.dodge_state == 1 and monster.burst_count == 0, "one-shot retreat cancels burst")
	await create_timer(0.5).timeout
	monster._physics_process(0.01)
	check(monster.dodge_state == 2 and monster.position.distance_to(hero.position) > 900, "forward death then distant relocation")
	await create_timer(0.5).timeout
	check(monster.dodge_state == 0, "reverse death completes retreat")
	monster.position = hero.position + Vector2(50,0)
	monster._physics_process(0.01)
	check(monster.dodge_state == 0, "retreat used only once")
	monster.position = hero.position + Vector2(800,0)
	var before: int = hero.current_hp
	hero.invulnerability_timer = 0
	monster.take_damage(monster.max_hp + 1)
	check(hero.current_hp == before, "death strikes centered on body, distant hero untouched")
	third.position = hero.position - Vector2(155,0)
	hero.invulnerability_timer = 0
	third.take_damage(third.max_hp + 1)
	check(hero.current_hp < before, "death strike hits nearby hero")
	await create_timer(0.8).timeout
	check(battle.transient_fx_pools.get(TENTACLE.POOL_KEY, []).size() >= 8, "tentacles return to pool after death")
	print("KRAKEN_TEST: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
