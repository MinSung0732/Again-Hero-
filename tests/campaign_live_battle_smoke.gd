extends SceneTree
const S := preload("res://src/systems/account_save_scope.gd")
const P := preload("res://src/systems/stage_progress.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
var failures := 0
var battle
var clock := 0.0
var stage_index := 0
var reported_seconds := -1
var choice_count := 0
var first_damage_time := -1.0
var result_rows: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures += 1; push_error("LIVE_CAMPAIGN: "+label)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	S.guest_directory = "user://campaign_live_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(S.guest_directory); S.select_guest()
	var mode := root.get_node("LocalTestMode"); mode.active = false; mode.tutorial_preview = false; mode.marker_path = S.guest_directory.path_join("mode.cfg")
	Engine.time_scale = 6.0
	_start_next()
func _start_next() -> void:
	stage_index += 1
	if stage_index > 3:
		print("CAMPAIGN_LIVE rows=",JSON.stringify(result_rows)," failures=",failures)
		quit(1 if failures else 0); return
	seed(20261012+stage_index)
	P.set_current_stage("stage_%d" % stage_index)
	battle = load("res://src/battle/Battle.tscn").instantiate()
	battle.set_allowed_monster_ids(["slime","spider","orc"] if stage_index == 1 else (["bomb_rat","spider","orc"] if stage_index == 2 else ["skeleton_archer","slime","orc"]))
	root.add_child(battle)
	check(battle.command_power == 24.0,"opening24 stage%d" % stage_index)
	check(battle.run_time_limit_seconds == STAGES.get_stage("stage_%d" % stage_index).run_duration_seconds,"real stage limit")
	choice_count = 0; first_damage_time = -1; reported_seconds = -1; clock = 0
	battle.hero_augment_selected.connect(func(_level,_candidates,_name,_reason,_build): choice_count += 1)
	var hp_before: int = battle.hero.current_hp
	battle.try_summon("orc"); battle.try_summon("spider" if stage_index < 3 else "skeleton_archer"); battle.try_summon("slime" if stage_index != 2 else "bomb_rat")
	check(battle.active_monsters.size() >= 2 and battle.hero.current_hp == hp_before,"immediate paid starter army")
func _process(delta: float) -> bool:
	if not is_instance_valid(battle): return false
	clock += delta
	if battle.demon_augment_selection_active and not battle.demon_augment_candidates.is_empty(): battle.choose_demon_augment(String(battle.demon_augment_candidates[0].id))
	if battle.mutation_director.is_active() and not battle.mutation_director.get_candidates().is_empty(): battle.try_choose_mutation(String(battle.mutation_director.get_candidates()[0]))
	if not battle.battle_over:
		var second := int(battle.run_metrics.elapsed_seconds)
		if second != reported_seconds:
			reported_seconds = second
			if battle.run_metrics.total_damage_dealt > 0 and first_damage_time < 0: first_damage_time = battle.run_metrics.elapsed_seconds
			# A simple alternating army, with no free resources or extra damage.
			var roster := ["slime","spider","slime","orc"] if stage_index == 1 else (["bomb_rat","spider","bomb_rat","orc"] if stage_index == 2 else ["skeleton_archer","slime","skeleton_archer","orc"])
			var id: String = roster[second%roster.size()]
			if battle.command_power >= battle.get_monster_cost(id): battle.try_summon(id)
		return false
	check(first_damage_time >= 0,"real damage occurs stage%d" % stage_index)
	result_rows.append({"stage":stage_index,"seconds":battle.run_metrics.elapsed_seconds,"damage":battle.run_metrics.total_damage_dealt,"min_hp_percent":roundi(battle.run_metrics.lowest_hero_hp_ratio*100),"first_damage_seconds":first_damage_time,"hero_choices":choice_count,"demon_level":battle.demon_level,"cleared":P.is_stage_cleared("stage_%d" % stage_index)})
	var old = battle; battle = null; old.queue_free()
	call_deferred("_start_next")
	return false
