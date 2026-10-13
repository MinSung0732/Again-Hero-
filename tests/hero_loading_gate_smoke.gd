extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const ART := preload("res://src/ui/hero_weapon_art.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
var checks := 0
var failures := 0
var loading_frames := 0
var paused_frames := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_LOADING: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://hero_loading_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var unlocks := ConfigFile.new()
	unlocks.set_value("hard_cleared","stage_10",true)
	check(SCOPE.save_config(unlocks,"user://stage_progress.cfg") == OK,"isolated sage unlock")
	var transition := root.get_node("SceneTransition")
	var warmup := root.get_node("PresentationWarmup")
	var paid := STAMINA.try_enter("stage_1",true,-1,false)
	check(paid.success,"paid entry")
	check(transition.change_scene("res://src/hero_mode/HeroMode.tscn","던전 준비 중",{"stage_id":"stage_1","hero_id":"sage_astra","hero_entry":paid}),"real transition accepts selected hero")
	var deadline := Time.get_ticks_msec()+45000
	while transition.is_transitioning() and Time.get_ticks_msec() < deadline:
		loading_frames += 1
		var scene = current_scene
		if scene != null and scene.get_script().resource_path == "res://src/hero_mode/hero_mode.gd":
			check(not scene.entry_ready and not scene.is_processing() and not scene.pad.enabled,"simulation/input gated under persistent overlay")
			check(scene.entry_started_ms == -1,"early exit wall clock excludes loading")
			if is_instance_valid(scene.battle):
				paused_frames += 1
				check(scene.battle.external_pause and not scene.battle.hero.is_physics_processing(),"hero physics frozen during monster warmup")
				check(scene.battle.run_metrics.elapsed_seconds == 0 and scene.battle.get_population_count() == 0,"no survival time or enemy spawn consumed under overlay")
		await process_frame
	check(not transition.is_transitioning(),"loading completes before deadline")
	var scene = current_scene
	if scene == null or not is_instance_valid(scene.battle):
		check(false,"actual destination battle exists"); quit(1); return
	if not scene.entry_ready: await scene.entry_started
	check(loading_frames > 0 and paused_frames > 0,"real loading and battle preparation stages observed")
	check(scene.presentation_ready and scene.entry_ready and not scene.battle.external_pause,"ready gate releases combat once")
	check(scene.battle.hero.hero_id == "sage_astra" and scene.battle.current_stage_id == "stage_1","entry options override campaign/default character")
	check(scene.battle._monster_spawn_resources_warmed and not scene.battle._monster_spawn_warmup_running,"monster preparation finishes before overlay disappears")
	check(warmup.get_texture("res://assets/art/heroes/stage2_rogue/frames/idle_01.png") == null,"unselected hero combat frames are not loaded")
	for id in WEAPONS.weapon_pool("sage_astra"):
		var directory := String(WEAPONS.WEAPONS[id].get("effect_dir",""))
		var sequence := ART.sequence(directory)
		for texture in sequence:
			check(texture in warmup._destination.values(),"weapon art reuses warmed texture without duplicate upload")
	var load_count: int = warmup.texture_load_count
	await scene.prepare_presentation()
	check(warmup.texture_load_count == load_count,"repeated prepare is idempotent")
	await warmup.prepare_scene("res://src/hero_mode/HeroMode.tscn",{"hero_id":"sage_astra"})
	check(warmup.texture_load_count == load_count,"same-kit resource preparation reuses retained destination")
	var elapsed: float = scene.battle.run_metrics.elapsed_seconds
	await create_timer(1.2).timeout
	check(scene.battle.run_metrics.elapsed_seconds > elapsed and scene.battle.get_population_count() > 0,"combat and AI start after loading")
	scene._pause()
	var paused_clock: float = scene.battle.run_metrics.elapsed_seconds
	await create_timer(0.1).timeout
	check(scene.battle.run_metrics.elapsed_seconds == paused_clock,"ordinary pause still freezes combat")
	scene._resume()
	var blocked = load("res://src/hero_mode/HeroMode.tscn").instantiate(); root.add_child(blocked)
	check(blocked.entry.is_empty() and not blocked.entry_ready and not is_instance_valid(blocked.battle),"direct reload cannot consume a claimed entry twice")
	check(blocked.overlay.visible and not blocked.presentation_preparing,"invalid entry remains on usable blocked UI")
	blocked.queue_free()
	print("HERO_LOADING_GATE_SMOKE checks=",checks," failures=",failures," loading_frames=",loading_frames," paused_frames=",paused_frames)
	quit(1 if failures else 0)
