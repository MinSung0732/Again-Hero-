extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error("MUMMY_TEST: " + message)
func spawn():
	var monster = battle._spawn_monster("mummy",Vector2(1100,1000))
	monster.set_physics_process(false)
	return monster
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://mummy_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.max_hp = 100000
	hero.current_hp = 50000
	hero.shield_hp = 0
	hero.position = Vector2(1000,1000)
	check(CATALOG.get_rarity("mummy") == "uncommon" and CATALOG.get_base_cost("mummy") == 7,"identity")
	for candidate in AUGMENTS.get_monster_normal_augments("mummy",""):
		check(AUGMENTS.get_augment(candidate.id) == candidate,"normal augment lookup")
	var base = spawn()
	check(base.shield_hp == int(round(base.max_hp * 0.5)),"spawn shield half final HP")
	check(base.visual.sprite_frames.get_frame_count("attack") == 6,"existing normal frames")
	var old_hp: int = base.current_hp
	base.take_damage(10)
	check(base.current_hp == old_hp and base.shield_hp == base.shield_capacity - 10,"shield absorbs first")
	var shield: int = base.shield_hp
	base.configure_special_augments({})
	check(base.shield_hp == shield,"config refresh cannot refill shield")
	battle.demon_special_augments.assign(CATALOG.MONSTERS.mummy.special_augment_ids)
	var augmented = spawn()
	check(augmented.max_hp == int(round(float(base.max_hp)*1.7)),"HP augment uses factory growth once")
	check(augmented.shield_hp == int(round(augmented.max_hp * 0.5)),"HP augment shield matches")
	var augmented_max: int = augmented.max_hp
	var old_max: int = base.max_hp
	battle._refresh_alive_monsters_for_augments()
	base._sync_shield_capacity()
	check(augmented.max_hp == augmented_max,"repeated stat refresh does not compound seventy percent HP")
	check(base.shield_hp == int(round(float(shield) * base.max_hp / old_max)),"existing damaged shield scales remaining fraction with HP augment")
	var hp: int = hero.current_hp
	hero.invulnerability_timer = 0
	var capacity: int = augmented.shield_capacity
	augmented.take_damage(20)
	augmented.take_damage(capacity - 20)
	check(augmented.current_hp == augmented.max_hp and hero.current_hp == hp - capacity,"partial hits break shield: whole capacity retaliates once")
	check(hero.healing_reduction_timer == 2,"actual shield retaliation also applies on-damage debuff")
	augmented.take_damage(1)
	check(hero.current_hp == hp - capacity,"no second retaliation")
	augmented.configure_special_augments(augmented.special_augment_configs)
	check(augmented.shield_hp == 0,"broken shield cannot refresh")
	var immune = spawn()
	hero.invulnerability_timer = 100
	hp = hero.current_hp
	immune.take_damage(immune.shield_hp)
	check(hero.current_hp == hp and immune.shield_broken,"invulnerability blocks and consumes retaliation")
	hero._clear_received_modifiers()
	hero.invulnerability_timer = 100
	check(augmented._deal_hit(hero) == 0 and hero.healing_reduction_timer == 0,"blocked hit has no debuff")
	hero.invulnerability_timer = 0
	augmented.position = hero.position + Vector2(50,0)
	augmented.attack_timer = 0
	augmented._physics_process(0.1)
	check(hero.healing_reduction_timer == 2 and is_equal_approx(hero.healing_reduction_ratio,0.3),"real normal attack path applies debuff")
	check(hero.heal_direct(100) == 70,"direct/item healing reduced")
	hero._tick_received_modifiers(1.5)
	hero.invulnerability_timer = 0
	augmented._deal_hit(hero)
	check(hero.healing_reduction_timer == 2 and is_equal_approx(hero.healing_reduction_ratio,0.3),"refresh duration without stacking")
	hero._tick_received_modifiers(2)
	check(hero.heal_direct(100) == 100,"healing restored on expiry")
	hero.apply_healing_reduction(1,1)
	check(hero.heal_direct(100) == 0,"generic full reduction")
	hero._clear_received_modifiers()
	var elite = spawn()
	battle._apply_special_monster_modifiers(elite,"mummy",{"type":"elite"})
	check(not elite.elite_curse.is_empty() and elite.visual.sprite_frames.get_frame_count("attack") == 6,"elite passive and frames")
	elite.position = hero.position + Vector2(300,0)
	elite._physics_process(0.1)
	check(is_equal_approx(elite.velocity.length(),elite.move_speed * 1.3),"elite approach permanent thirty percent")
	hero.invulnerability_timer = 0
	elite._deal_hit(hero)
	check(hero.damage_taken_increase_timer == 2 and is_equal_approx(hero.damage_taken_increase_ratio,0.2),"elite curse active")
	hp = hero.current_hp
	hero.invulnerability_timer = 0
	hero.take_damage(100,base)
	check(hero.current_hp == hp - 120,"curse increases another source damage")
	hero._tick_received_modifiers(1.5)
	hero.invulnerability_timer = 0
	elite._deal_hit(hero)
	check(hero.damage_taken_increase_timer == 2 and is_equal_approx(hero.damage_taken_increase_ratio,0.2),"curse refresh without stacking")
	hero._tick_received_modifiers(2)
	hp = hero.current_hp
	hero.invulnerability_timer = 0
	hero.take_damage(100,base)
	check(hero.current_hp == hp - 100,"curse expires")
	hero.apply_healing_reduction(2,0.3)
	hero.apply_damage_taken_increase(2,0.2)
	hero.current_hp = 1
	hero.invulnerability_timer = 0
	hero.take_damage(100,base)
	check(hero.healing_reduction_timer == 0 and hero.damage_taken_increase_timer == 0,"death clears statuses")
	print("MUMMY_TEST: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
