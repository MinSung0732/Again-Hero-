extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var failed := false
var battle
var hero
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error("SHAMAN_TEST: " + message)
func spawn(id := "powwow_mummy"):
	var monster = battle._spawn_monster(id,Vector2(1100,1000))
	monster.set_physics_process(false)
	return monster
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://shaman_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
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
	check(CATALOG.get_rarity("powwow_mummy") == "rare" and CATALOG.get_base_cost("powwow_mummy") == 4.5,"identity")
	check(CATALOG.get_base_stats("powwow_mummy").attack_range == 237.5 and CATALOG.get_base_stats("powwow_mummy").projectile_speed == 275,"radius and projectile defaults")
	for candidate in AUGMENTS.get_monster_normal_augments("powwow_mummy",""):
		check(AUGMENTS.get_augment(candidate.id) == candidate,"normal augment lookup")
	var shaman = spawn()
	check(shaman.visual.sprite_frames.get_frame_count("skill") == 4,"normal four-step skill with final hold")
	check(not shaman._cast_buffs(),"no self buff when alone")
	var ally = spawn("mummy")
	var ally_damage: int = ally.attack_damage
	shaman._apply_buff(ally,0)
	check(ally.attack_damage == int(round(ally_damage * 1.15)) and ally.get_meta("support_shield_hp") == int(round(ally.max_hp * 0.1)),"base courage damage and shield")
	var hp: int = ally.current_hp
	var own_shield: int = ally.shield_hp
	ally.take_damage(5)
	check(ally.current_hp == hp and ally.shield_hp == own_shield,"support shield before innate shield")
	shaman._apply_buff(ally,0)
	check(ally.attack_damage == int(round(ally_damage * 1.15)) and ally.get_meta("support_shield_hp") == int(round(ally.max_hp * 0.1)),"refresh not additive")
	battle.demon_level = 2
	battle._apply_demon_level_scaling_to_monster(ally,true)
	var grown_damage := int(ally.get_meta("support_base_damage"))
	check(ally.attack_damage == int(round(grown_damage * 1.15)),"growth preserves courage once")
	battle.support_buff_runtime.tick(10)
	check(ally.attack_damage == grown_damage,"expiry restores grown base")
	ally.current_hp = ally.max_hp - 100
	shaman._apply_buff(ally,1)
	check(ally.current_hp == ally.max_hp - 95,"heal five percent missing HP")
	shaman._apply_buff(ally,2)
	check(is_equal_approx(COMMON.get_external_movement_multiplier(ally),1.5),"agility fifty percent")
	shaman._apply_buff(ally,2)
	check(is_equal_approx(COMMON.get_external_movement_multiplier(ally),1.5),"agility no stack")
	battle.support_buff_runtime.tick(10)
	check(is_equal_approx(COMMON.get_external_movement_multiplier(ally),1.0),"agility expires")
	battle.demon_special_augments.assign(CATALOG.MONSTERS.powwow_mummy.special_augment_ids)
	var upgraded = spawn()
	check(upgraded.buff_interval == 15 and upgraded.buff_timer == 15,"cadence augmentation includes first cast")
	upgraded._apply_buff(ally,0)
	check(ally.attack_damage == int(round(grown_damage * 1.225)) and ally.get_meta("support_shield_hp") == int(round(ally.max_hp * 0.15)),"courage fifty percent stronger")
	ally.current_hp = ally.max_hp - 100
	upgraded._apply_buff(ally,1)
	check(ally.current_hp == ally.max_hp - 90,"healing doubles to ten percent missing")
	var second = spawn("slime")
	var third = spawn("orc")
	battle._apply_special_monster_modifiers(upgraded,"powwow_mummy",{"type":"elite"})
	check(upgraded.elite_multi and upgraded.visual.sprite_frames.get_frame_count("skill") == 4 and upgraded.visual.sprite_frames.get_frame_count("attack") == 3,"elite passive and frames")
	check(upgraded._cast_buffs() and upgraded.buff_targets.size() == 3,"elite three ally targets")
	check(upgraded.buff_targets[0] != upgraded.buff_targets[1] and upgraded.buff_targets[0] != upgraded.buff_targets[2] and upgraded.buff_targets[1] != upgraded.buff_targets[2] and not upgraded.buff_targets.has(upgraded),"all buffs distinct targets excluding caster")
	upgraded.buff_timer = 12
	upgraded._fire_projectile(hero.position - upgraded.position)
	var projectiles := get_nodes_in_group("monster_projectiles")
	check(projectiles.size() == 1,"one pooled projectile")
	var projectile = projectiles[0]
	check(projectile.projectile_sprite.sprite_frames.get_frame_count("fly") == 2,"existing projectile frames")
	var origin: Vector2 = projectile.global_position
	projectile._physics_process(0.1)
	check(is_equal_approx(projectile.global_position.distance_to(origin),projectile.speed * 0.1),"projectile travels at configured speed")
	hero.invulnerability_timer = 0
	projectile._on_body_entered(hero)
	check(upgraded.buff_timer == 11,"actual projectile hit reduces next buff by one")
	projectile._on_body_entered(hero)
	check(upgraded.buff_timer == 11,"duplicate collision cannot reduce again")
	await process_frame
	upgraded._fire_projectile(hero.position - upgraded.position)
	var reused = get_nodes_in_group("monster_projectiles")[0]
	check(reused == projectile,"projectile reuse")
	hero.invulnerability_timer = 100
	reused._on_body_entered(hero)
	check(upgraded.buff_timer == 11,"invulnerable hit gives no cooldown reduction")
	await process_frame
	# Every roster actor can absorb a support shield, including inherited Medusa/Kraken.
	for id in CATALOG.ORDER:
		var target = spawn(id)
		target.set_meta("support_shield_hp",100)
		hp = target.current_hp
		target.take_damage(10)
		check(target.current_hp == hp and int(target.get_meta("support_shield_hp")) < 100,"support shield consumed " + id)
		battle.support_buff_runtime.apply_courage(target,1,0.15,0.10)
		battle.support_buff_runtime.tick(1)
		check(is_equal_approx(float(target.get_meta("support_damage_multiplier")),1.0),"all actor courage expiry " + id)
	shaman.buff_timer = 0
	shaman._physics_process(0.1)
	check(shaman.visual.animation == &"skill" and shaman.cast_timer > 0,"actual buff casting uses skill frames")
	var death_id: int = shaman.get_instance_id()
	shaman.take_damage(100000)
	check(shaman.dying and shaman.visual.animation == &"idle" and shaman.visual.frame == 0,"death starts idle first frame")
	await create_timer(0.2).timeout
	check(is_instance_valid(shaman) and shaman.visual.self_modulate.a < 1.0 and shaman.visual.self_modulate.a > 0.0,"death fades gradually")
	await create_timer(0.5).timeout
	check(not is_instance_valid(shaman) and not battle.active_monsters.has(death_id),"fade frees and unregisters")
	print("SHAMAN_TEST: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
