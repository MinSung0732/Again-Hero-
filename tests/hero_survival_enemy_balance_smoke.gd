extends SceneTree
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var checks := 0
var failures := 0
var battle
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SURVIVAL_ENEMY: "+label)
func spawn(id: String, clock: float, modifiers: Dictionary = {}):
	battle.run_metrics.elapsed_seconds = clock
	var actor = battle._spawn_monster(id,battle.hero.position+Vector2(600,0),0.0,false,modifiers)
	check(is_instance_valid(actor),"actual spawn: "+id)
	if is_instance_valid(actor): actor.set_physics_process(false)
	return actor
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var scope = load("res://src/systems/account_save_scope.gd")
	scope.select_guest(); scope.guest_directory = "user://survival_enemy_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(scope.guest_directory)
	for stat in ["hp","damage","speed"]:
		var previous := 0.0
		for clock in range(0,901,10):
			var value := MODE.monster_multiplier(stat,float(clock))
			check(value >= previous and is_finite(value),"smooth monotonic "+stat); previous = value
		check(is_equal_approx(MODE.monster_multiplier(stat,-10),MODE.monster_multiplier(stat,0)),"negative time clamps")
		check(is_equal_approx(MODE.monster_multiplier(stat,9999),MODE.monster_multiplier(stat,900)),"late time clamps")
		check(is_equal_approx(MODE.monster_multiplier(stat,NAN),MODE.monster_multiplier(stat,0)),"nonfinite time falls back")
	check(MODE.monster_multiplier("unknown",0) == 1.0,"unknown stat fails soft")
	for point in MODE.MONSTER_GROWTH:
		for stat in ["hp","damage","speed"]:
			check(absf(MODE.monster_multiplier(stat,float(point.time)+0.001)-MODE.monster_multiplier(stat,float(point.time)-0.001)) < 0.001,"no phase jump")
	battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = "stage_1"
	root.add_child(battle); battle.set_external_pause(true); battle.set_process(false); battle.set_physics_process(false)
	check(battle.hero.attack_damage == 26,"actual starting weapon damage")
	for clock in [0.0,120.0,300.0,600.0,900.0]:
		battle.demon_level = 1
		for id in ["slime","spider","orc","bomb_rat"]:
			var actor = spawn(id,clock)
			if not is_instance_valid(actor): continue
			var raw := CATALOG.get_base_stats(id)
			var rarity := CATALOG.get_rarity_combat_profile(id)
			var hp := maxi(1,roundi(float(raw.max_hp)*float(rarity.get("hp_multiplier",1.0))*MODE.monster_multiplier("hp",clock)))
			check(actor.max_hp == hp and actor.current_hp == hp,"actual clock-based HP: "+id)
			check(float(actor.get_meta("hero_survival_spawn_seconds")) == clock,"spawn snapshot stored")
			if id == "bomb_rat":
				var damage := roundi(float(raw.explosion_damage)*float(rarity.get("damage_multiplier",1.0))*MODE.monster_multiplier("damage",clock))
				check(actor.explosion_damage == damage,"explosion uses survival curve")
				battle._apply_normal_augments_to_existing_monster(actor,id)
				check(actor.explosion_damage == damage,"explosion refresh does not remove curve")
			if clock == 0.0 and id != "bomb_rat":
				var hit_count := 0
				while actor.current_hp > 0 and hit_count < 3:
					actor.take_damage(26); hit_count += 1
				check(actor.current_hp == 0 and hit_count in [1,2],"actual opening kill in one or two hits: "+id)
				print("OPENING ",id," HP=",hp," hits=",hit_count)
	var old = spawn("orc",0.0); old.current_hp = 23
	battle.run_metrics.elapsed_seconds = 600.0; battle.demon_level = 99
	battle._refresh_alive_monsters_for_demon_level()
	check(old.max_hp == 47 and old.current_hp == 23,"time and demon levels do not inflate old spawns")
	battle._apply_normal_augments_to_existing_monster(old,"orc")
	check(old.max_hp == 47 and old.current_hp == 23,"augment refresh preserves spawn envelope and wounds")
	check(battle._get_giant_monster_summon_chance() == 0.0,"survival uses scheduled giants")
	check(battle._get_demon_level_monster_exp_multiplier() == 1.0,"AI level cannot double XP")
	for clock in [0.0,600.0]:
		var fixed = spawn("fanatic",clock,{"fixed_base_stats":true,"exclude_all_augments":true})
		var expected := roundi(float(CATALOG.get_base_stats("fanatic").max_hp)*MODE.monster_multiplier("hp",clock))
		check(fixed.max_hp == expected,"fixed skill reinforcements get the survival envelope")
		battle._apply_augment_free_base_stats(fixed,"fanatic")
		check(fixed.max_hp == expected,"fixed envelope applies once")
	var elite = spawn("orc",120.0,{"elite_variant":true})
	battle._apply_special_monster_modifiers(elite,"orc",{"type":"elite","hp_multiplier":2.0,"damage_multiplier":1.2})
	var elite_hp: int = elite.max_hp
	battle._apply_normal_augments_to_existing_monster(elite,"orc")
	check(elite_hp == 260 and elite.max_hp == elite_hp,"elite ratio survives AI augment refresh")
	battle.hero_player_mode = false; battle.demon_level = 1
	check(battle._get_demon_level_monster_hp_multiplier() == 1.0 and battle._get_demon_level_monster_damage_multiplier() == 1.0,"normal demon mode stays canonical at level one")
	var normal = spawn("orc",0.0)
	check(normal.max_hp == 260,"normal demon spawn HP unchanged")
	battle.demon_level = 99
	check(battle._get_demon_level_monster_hp_multiplier() == 2.5 and battle._get_demon_level_monster_exp_multiplier() == 2.0,"normal demon growth caps unchanged")
	battle.queue_free(); await process_frame
	print("HERO_SURVIVAL_ENEMY_BALANCE_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
