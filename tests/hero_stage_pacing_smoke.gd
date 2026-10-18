extends SceneTree
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
const HARNESS := preload("res://tests/hero_opening_pressure_smoke.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for difficulty in ["easy","hard"]:
		var previous_hp := 0.0
		for stage in range(1,11):
			var learning := DATA.pacing_value("learning",stage,difficulty)
			var hp := DATA.monster_multiplier_for_stage("hp",180,stage,difficulty)
			check(hp > previous_hp,"stage HP increases "+str(stage)+difficulty); previous_hp = hp
			var previous := 0.0
			for tick in range(901):
				var value := DATA.monster_multiplier_for_stage("hp",tick,stage,difficulty)
				check(value >= previous and is_finite(value),"monotonic HP"); previous = value
				check(is_equal_approx(DATA.monster_multiplier_for_stage("speed",tick,stage,difficulty),DATA.monster_multiplier("speed",tick)),"pursuit kept")
				check(is_equal_approx(DATA.monster_multiplier_for_stage("damage",tick,stage,difficulty),DATA.monster_multiplier("damage",tick)),"damage clock kept")
			check(DATA.required_exp(1,learning) <= DATA.required_exp(1),"first level eased")
			for level in range(10,41): check(DATA.required_exp(level,learning) == DATA.required_exp(level),"later EXP unchanged")
			var boss := DATA.boss_data(stage,difficulty)
			var base := DATA.MONSTERS.get_base_stats(DATA.boss_for(stage,difficulty))
			var hp_actual: float = float(base.max_hp)*DATA.monster_multiplier_for_stage("hp",900,stage,difficulty)*(1.25 if difficulty == "hard" else 1.0)*float(boss.hp_multiplier)
			check(absf(hp_actual-float(boss.target_hp)) < 1.0,"boss target preserved")
			var arena := HARNESS.Arena.new(); root.add_child(arena)
			arena.current_stage_data.number = stage; arena.campaign_difficulty = difficulty
			arena.hero = HARNESS.Hero.new(); arena.add_child(arena.hero); arena.hero.position = Vector2(1200,1200)
			var director := DIRECTOR.new(); director.install(arena)
			director.next_elite = 10000; director.giant_index = DATA.GIANT_TIMES.size(); director.encounters.next_event = 10000
			arena.run_metrics.elapsed_seconds = 180.0
			for step in 300: director.tick(0.1)
			var cap := mini(DATA.monster_limit(stage),int(DATA.phase_at(180).limit*director.pressure*director.supply_scale))-2
			print("PACING_ROW\t%d\t%s\t%.2f\t%.2f\t%.2f\t%.4f\t%d\t%d\t%d" % [stage,difficulty,DATA.pacing_value("hp_clock",stage,difficulty),director.supply_scale,learning,hp*(1.25 if difficulty == "hard" else 1.0),cap,DATA.required_exp(1,learning),boss.target_hp])
			check(arena.population <= cap,"actual director respects ordinary cap")
			check(is_equal_approx(arena.command_regen_per_second,DATA.phase_at(180).regen*director.pressure*director.supply_scale),"actual regen matches pacing")
			arena.queue_free(); await process_frame
	check(DATA.required_exp(1,0.65) == 39,"easy1 first EXP60 to39")
	check(DATA.monster_multiplier_for_stage("hp",180,1,"easy") < DATA.monster_multiplier("hp",180)*0.34,"easy1 three-minute HP relief")
	for stage in range(1,11):
		check(DATA.monster_multiplier_for_stage("hp",180,stage,"hard")*1.25 > DATA.monster_multiplier_for_stage("hp",180,stage,"easy"),"hard remains tougher")
	# Exercise original Battle/Hero setup, not just catalog arithmetic.
	var old_directory := SCOPE.guest_directory
	SCOPE.guest_directory = "user://stage_pacing_fixture"; SCOPE.select_guest()
	var scene: PackedScene = load("res://src/battle/Battle.tscn")
	for difficulty in ["easy","hard"]:
		for stage in range(1,11):
			var battle = scene.instantiate(); battle.hero_player_mode = true
			battle.hero_player_stage = "stage_%d" % stage; battle.hero_player_hero_id = "ranged_rookie"
			battle.campaign_difficulty = difficulty; battle._monster_spawn_resources_warmed = true
			root.add_child(battle); battle.set_external_pause(true)
			check(is_equal_approx(battle.hero.player_exp_requirement_scale,DATA.pacing_value("learning",stage,difficulty)),"actual Hero installs learning")
			check(battle.hero.exp_to_next_level == DATA.required_exp(1,battle.hero.player_exp_requirement_scale),"actual initial EXP")
			check(is_equal_approx(battle._hero_survival_multiplier("hp",180),DATA.monster_multiplier_for_stage("hp",180,stage,difficulty)),"actual Battle HP envelope")
			battle.run_metrics.elapsed_seconds = 180
			var actor = battle._spawn_monster("slime",battle.hero.position+Vector2(300,0))
			check(is_instance_valid(actor) and actor.max_hp > 0,"actual stage monster spawns")
			var expected_hp := maxi(1,roundi(float(actor.get_meta("demon_level_base_max_hp"))*DATA.monster_multiplier_for_stage("hp",180,stage,difficulty)*(1.25 if difficulty == "hard" else 1.0)))
			check(actor.max_hp == expected_hp,"spawn HP uses tuned envelope once")
			actor.current_hp = maxi(1,actor.max_hp/2)
			var wounded_hp: int = actor.current_hp
			battle.run_metrics.elapsed_seconds = 600
			battle._apply_demon_level_scaling_to_monster(actor,true)
			check(actor.max_hp == expected_hp and actor.current_hp == wounded_hp,"later recalculation keeps spawn clock and wounds")
			battle.online_match_mode = true
			check(battle._hero_survival_multiplier("hp",180) == DATA.monster_multiplier("hp",180),"online HP unchanged")
			battle.queue_free(); await process_frame
	SCOPE.guest_directory = old_directory; SCOPE.select_guest()
	await create_timer(0.15).timeout
	print("HERO_STAGE_PACING checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
