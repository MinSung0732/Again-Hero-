extends SceneTree
const DATA := preload("res://src/data/transcendence_catalog.gd")
const STORE := preload("res://src/systems/transcendence_loadout_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("TRANSCENDENCE: " + message)
func capture(path: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func run() -> void:
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	var folder := "user://transcendence_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("player_profile","value",{"nickname":"초월 검증","gender":"female"})
	SCOPE.save_config(cfg,"user://stage_progress.cfg")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	lobby._switch_tab("team")
	lobby._show_formation_mode("transcendence")
	await process_frame
	var fixtures := "--fixtures" in OS.get_cmdline_user_args()
	check(lobby.transcendence_view.content.visible and lobby.transcendence_view.empty.visible == DATA.get_ids().is_empty(),"catalog emptiness reflects shipping or fixture entries")
	check(not lobby.skill_mode_button.disabled and not lobby.team_mode_button.disabled,"other tabs usable")
	if not fixtures:
		await capture("res://../transcendence_empty.png")
		check(not STORE.save_id("yuki_onna"),"shipping rare Yuki cannot register")
		lobby.free()
		print("TRANSCENDENCE_EMPTY: "+("FAILED" if failed else "PASS"))
		quit(1 if failed else 0)
		return
	var collection := ConfigFile.new()
	for id in ["slime","goblin","yuki_onna","wolf"]:
		collection.set_value("monsters",id+"_unlocked",true)
	SCOPE.save_config(collection,"user://monster_collection.cfg")
	check(STORE.save_id("yuki_onna") and STORE.load_id() == "yuki_onna","single slot saved")
	check(STORE.save_id("wolf") and STORE.load_id() == "wolf","single slot replacement")
	check(not STORE.save_id("slime") and STORE.load_id() == "wolf","ordinary monster rejected")
	check(STORE.save_id("") and STORE.load_id().is_empty(),"remove registration")
	STORE.save_id("yuki_onna")
	var team = load("res://src/systems/team_loadout_store.gd")
	team.save_ids(["slime","yuki_onna"],["slime","yuki_onna"])
	check(team.load_ids(["slime","yuki_onna"],[]) == ["slime"],"legacy team excludes transcendent")
	lobby._setup_team_preview()
	await process_frame
	lobby._show_formation_mode("transcendence")
	check(lobby.transcendence_view.grid.get_child_count() == 2 and not lobby.team_catalog_ids.has("yuki_onna"),"dedicated list only")
	await capture("res://../transcendence_fixture.png")
	lobby._show_formation_mode("skill")
	check(not lobby.transcendence_view.content.visible,"skill switch restores normal layout")
	lobby._show_formation_mode("team")
	check(lobby.team_monster_grid.visible and not lobby.skill_mode_button.disabled,"team switch restored")
	lobby.free()
	var runtime = RUNTIME.new()
	var rules := {"mode":"any","conditions":[{"metric":"monsters_summoned","amount":200},{"metric":"mana_spent","amount":500}]}
	runtime.configure("fixture",rules)
	for index in range(199):
		runtime.record_summon()
	check(not runtime.ready and runtime.record_summon(),"exact 200 successful summons threshold")
	check(not runtime.record_summon(),"unlock event emitted once")
	runtime.configure("fixture",rules)
	runtime.record_mana(499)
	check(not runtime.ready and runtime.record_mana(1),"exact 500 mana OR threshold")
	runtime.configure("fixture",{"mode":"all","conditions":rules.conditions})
	runtime.record_mana(500)
	check(not runtime.ready,"AND conditions")
	for index in range(200):
		runtime.record_summon()
	check(runtime.ready,"AND both met")
	runtime.configure("fixture",{"mode":"any","conditions":[{"metric":"unknown","amount":1}]})
	check(not runtime.record_summon(),"invalid rule fails closed")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(main)
	var deadline := Time.get_ticks_msec()+20000
	while not main._presentation_ready and Time.get_ticks_msec()<deadline:
		await process_frame
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
	check(not main.battle_loadout_ids.has("yuki_onna") and not main.transcendence_view.visible,"no initial button or ordinary slot")
	check(not battle.try_summon_transcendent() and not battle.try_summon("yuki_onna"),"locked and ordinary path rejected")
	check(battle.try_summon("slime") and battle.try_summon("slime"),"real summon success increments condition")
	check(battle.transcendence.ready and main.transcendence_view.visible,"button appears only on unlock")
	await create_timer(0.3).timeout
	check(battle._spawn_monster("yuki_onna",Vector2(1000,1000)) == null,"ordinary automatic spawning cannot bypass registration")
	check(main._is_pointer_over_battle_ui(main.transcendence_view.button.get_global_rect().get_center()),"button touch blocks camera and manual spawn")
	check(main.transcendence_view.button.offset_right == -12 and main.transcendence_view.button.size.x == 144,"small button slides into viewport")
	await capture("res://../transcendence_battle.png")
	battle.set_external_pause(true)
	check(not battle.try_summon_transcendent() and not battle.transcendence.used,"pause cannot consume summon")
	battle.set_external_pause(false)
	var before: float = battle.command_power
	check(battle.try_summon_transcendent() and battle.transcendence.used,"actual one monster summon")
	check(battle.command_power < before and not main.transcendence_view.visible,"cost deducted and button hidden")
	check(not battle.try_summon_transcendent(),"second summon prohibited")
	battle._start_battle()
	check(not battle.transcendence.used and not battle.transcendence.ready and battle.transcendence.monsters_summoned == 0,"new battle clears progress")
	battle.set_external_pause(false)
	battle.set_process(false)
	battle.set_physics_process(false)
	battle.demon_ultimate_charge = 100
	battle.demon_ultimate_cooldowns["encirclement"] = 0.0
	check(battle.try_use_demon_ultimate("encirclement") and battle.transcendence.mana_spent == 70 and battle.transcendence.ready,"actual mana spending unlocks")
	main.free()
	await create_timer(0.2).timeout
	print("TRANSCENDENCE: "+("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
