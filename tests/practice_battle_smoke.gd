extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PRACTICE: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	SCOPE.guest_directory="user://practice_fixture_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var mode := root.get_node("LocalTestMode")
	mode.tutorial_preview=false
	mode.active=false
	check(not mode.request_practice_battle(),"normal mode cannot request")
	mode.active=true
	mode.tutorial_preview=true
	check(not mode.request_practice_battle(),"tutorial isolated from practice")
	mode.tutorial_preview=false
	SCOPE.user_id="authenticated"
	check(not mode.request_practice_battle(),"signed-in account cannot request")
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	state.bulgasal={"unlocked":true,"shards":0,"level":0}
	COLLECTION.save_state(state)
	check(LOADOUT.save_id("bulgasal"),"register practice actor")
	var before := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg")) if FileAccess.file_exists(SCOPE.guest_directory.path_join("stage_progress.cfg")) else ""
	check(mode.request_practice_battle(),"local practice authorized")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	var dummy = battle.hero
	dummy.set_physics_process(false)
	check(battle.practice_mode and not mode.practice_requested and not mode.consume_practice_request(),"one-shot request consumed")
	check(dummy.get_meta("practice_dummy",false) and dummy.attack_damage==1 and dummy.practice_attack_enabled,"real Hero adapter, 1-damage attacks enabled")
	check(dummy.take_damage(2000000000,null) and dummy.take_status_damage(2000000000,null),"ordinary/status hits accepted")
	check(dummy.current_hp==dummy.INFINITE_HP and not dummy.is_dying,"cannot die from lethal hits")
	var level_before: int=dummy.level
	dummy.gain_exp(100000)
	check(dummy.level==level_before,"no EXP or augment growth")
	battle._on_hero_died()
	battle._on_run_time_up()
	check(not battle.battle_over and battle._grant_run_research_reward(true).is_empty(),"no completion/time limit/rewards")
	battle.transcendence.satisfy_conditions_for_test()
	check(battle.try_summon_transcendent(),"existing local unlock and once-only summon")
	var actor = battle.transcendent_actor
	actor.set_physics_process(false)
	actor.pillars.set_physics_process(false)
	actor.position=dummy.position-Vector2(100,0)
	actor._set_phase("idle")
	dummy.decision_remaining=0
	dummy._physics_process_actions(0.1)
	check(dummy.flee_direction.x>0 and dummy.velocity.x>0,"dummy flees registered nearby actor")
	check(dummy.attack_timer>0,"fleeing dummy fires pooled projectile")
	dummy.set_practice_attack_enabled(false)
	dummy.attack_timer=0
	dummy._physics_process_actions(0.1)
	check(dummy.attack_timer==0 and dummy.velocity.length()>0,"OFF stops attacks while fleeing")
	dummy.set_practice_attack_enabled(true)
	dummy._physics_process_actions(0.1)
	check(dummy.attack_timer>0,"ON resumes attacks")
	check(actor.visual.scale.x>0 and is_equal_approx(DATA.VISIBLE_HEIGHT,118.0*1.27),"visual1.27 uniform enlargement")
	actor.gauge=0
	actor._set_phase("pick")
	actor._physics_process(2.99)
	check(actor.phase=="pick" and not actor.rock_active,"rock picking lasts3 seconds")
	actor._physics_process(0.42)
	check(actor.rock_active and actor.phase=="idle","3-second pick plus existing hold then launch")
	actor._set_phase("launch")
	check(not TARGETS.is_detectable(actor) and battle.get_nearest_hostile_target_for_hero(actor.position)==null,"takeoff excluded from real query")
	actor._physics_process(0.35)
	check(actor.phase=="air" and not TARGETS.is_detectable(actor),"air excluded")
	actor._physics_process(1)
	check(actor.phase=="land" and not TARGETS.is_detectable(actor),"falling still excluded")
	actor.landing_position=dummy.position
	actor._physics_process(0.25)
	check(TARGETS.is_detectable(actor) and actor.wave_visual_distance==0,"landing restores and starts visual train")
	actor._tick_waves(0.1)
	check(actor.wave_distance==90 and actor.wave_visual_distance==90,"one unchanged front sweep, second visual starts behind")
	actor._tick_waves(0.7)
	check(not actor.wave_active and actor.wave_visual_distance>0,"visual tail survives primary sweep without damage")
	actor._tick_waves(1)
	check(actor.wave_visual_distance<0,"visual tail terminates")
	var after := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg")) if FileAccess.file_exists(SCOPE.guest_directory.path_join("stage_progress.cfg")) else ""
	check(before==after,"practice does not write stage/gold/stamina")
	battle.queue_free()
	await process_frame
	await process_frame
	mode.active=false
	var normal = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(normal)
	check(not normal.practice_mode and not normal.hero.has_meta("practice_dummy"),"next normal entry is ordinary Hero")
	normal.queue_free()
	await process_frame
	print("PRACTICE_BATTLE: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
