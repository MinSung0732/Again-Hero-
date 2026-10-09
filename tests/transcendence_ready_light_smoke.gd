extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const LOADOUT := preload("res://src/systems/transcendence_loadout_store.gd")
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("READY_LIGHT: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://ready_light_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var collection := COLLECTION.load_state()
	collection.bulgasal = {"unlocked":true,"level":0,"shards":0}
	COLLECTION.save_state(collection)
	LOADOUT.save_id("bulgasal")
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = SCOPE.guest_directory.path_join("options.cfg")
	root.add_child(main)
	var deadline := Time.get_ticks_msec() + 20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	check(main._presentation_ready,"actual main presentation ready")
	main.stage_intro_cutscene._finish(true)
	await process_frame
	await process_frame
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	var battle = main.battle
	battle.set_external_pause(false)
	battle.set_process(false)
	battle.set_physics_process(false)
	battle.hero.set_physics_process(false)
	battle.command_power = 1000
	var view = main.transcendence_view
	view.refresh()
	check(not view.visible and not view.ready_announced,"locked has no light")
	for index in range(20): battle.transcendence.record_summon("tank")
	for index in range(49): battle.transcendence.record_ally_death()
	view.refresh()
	check(not view.visible,"20 tanks49 deaths remains locked")
	battle.transcendence.record_ally_death()
	view.refresh()
	view.set_process(false)
	check(view.visible and view.ready_light.visible and view.ready_announced,"exact20/50 unlock lights actual button")
	check(view.ready_frames.size()==12 and view.ready_light.mouse_filter==Control.MOUSE_FILTER_IGNORE,"fixed atlas pool and noninteractive overlay")
	check(view.ready_light.size==Vector2(164,176),"same size as authored cell")
	view._process(0.5)
	var elapsed: float = view.ready_elapsed
	view.refresh()
	view.set_process(false)
	check(view.ready_elapsed==elapsed,"frequent resource refresh does not restart notice")
	battle.external_pause = true
	view._process(1.0)
	check(not view.ready_light.visible and view.ready_elapsed==elapsed,"menu pause freezes and hides light")
	battle.external_pause = false
	battle.demon_augment_selection_active = true
	view._process(1.0)
	check(not view.ready_light.visible and view.ready_elapsed==elapsed,"augment selection freezes light")
	battle.demon_augment_selection_active = false
	view._process(3.0)
	check(view.ready_light.visible and is_equal_approx(view.ready_light.modulate.a,0.55),"settles to restrained loop")
	await create_timer(0.3).timeout
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../ready_button_fixture.png")
	view.button.pressed.emit()
	check(battle.transcendence.used and not view.visible and not view.ready_announced,"actual summon button consumes and stops light")
	battle.transcendence.configure("bulgasal",DATA.RULES)
	view.refresh()
	check(not view.ready_announced,"new battle locked reset")
	root.get_node("LocalTestMode").active = true
	battle.transcendence.satisfy_conditions_for_test()
	battle.transcendence.test_unlock_confirmed = false
	view.refresh()
	check(view.visible and view.ready_light.visible and not view.button.disabled,"local natural readiness enables summon and attention cue")
	battle.transcendence.test_unlock_confirmed = true
	view.refresh()
	check(view.ready_light.visible and view.ready_elapsed==0,"click confirmation is not required and does not restart cue")
	battle.battle_over = true
	view.refresh()
	check(not view.visible and not view.is_processing(),"battle end stops cue")
	main.queue_free()
	await process_frame
	print("TRANSCENDENCE_READY_LIGHT: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
