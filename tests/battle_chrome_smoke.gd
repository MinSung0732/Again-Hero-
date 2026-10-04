extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CHROME_TEST: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://chrome_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(main)
	current_scene = main
	var deadline := Time.get_ticks_msec() + 20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	main.stage_intro_cutscene._finish(true)
	await process_frame
	await process_frame
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	main.battle.set_external_pause(true)
	await process_frame
	check(main.hud_layer.has_node("CastleBattleChrome"), "shared castle shell created")
	var chrome = main.hud_layer.get_node("CastleBattleChrome")
	check(chrome.mouse_filter == Control.MOUSE_FILTER_IGNORE and not chrome.is_processing(), "decor is passive and static")
	check(chrome.get_child_count() == 0, "no props/collision/input nodes in shell")
	check(main.battle_viewport_container.position.y == 540, "play area below illustrated wall")
	check(chrome.surround != null, "generated surround present")
	check(root.get_node("PresentationWarmup").get_texture("res://assets/art/UI/battle_castle_v3/flagstone_floor.png") != null, "new floor preloaded")
	check(main.settings_battle_frame.toggled.is_connected(main._on_settings_battle_frame_toggled), "frame checkbox wired")
	check(main.hero_info_bookmark.size == Vector2(144,142), "matching icon bookmarks")
	check(main.hero_info_bookmark.pressed.is_connected(main._toggle_hero_info), "hero information action retained")
	check(main.stage_menu_button.pressed.is_connected(main._on_stage_menu_pressed), "menu action retained")
	check(main.demon_ultimate_1.get_node("IllustratedBattlePanel").show_behind_parent, "art behind native skill text")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://battle-chrome-preview.png")
	main.settings_battle_frame.button_pressed = false
	await process_frame
	check(not chrome.visible and main.battle_viewport_container.offset_left == 0 and main.battle_viewport_container.position.y == 350, "off hides surround and restores wide viewport")
	main.battle_frame_enabled = true
	main._load_gameplay_settings()
	check(not main.battle_frame_enabled, "frame choice persisted")
	main._sync_gameplay_settings_ui()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://battle-chrome-off-preview.png")
		main._open_settings_overlay()
		main.settings_tabs.current_tab = 1
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://battle-frame-settings-preview.png")
		main._close_settings_overlay()
	main.settings_battle_frame.button_pressed = true
	await process_frame
	check(chrome.visible and main.battle_viewport_container.offset_left == 140, "on restores framing")
	# Exercise the existing screen-to-world path against the narrower viewport.
	main._stage_intro_active = false
	main.battle.set_external_pause(false)
	var outcome := {"ok": false}
	main.battle.summon_result.connect(func(_type: String, success: bool, _message: String): outcome.ok = success)
	for enabled in [true, false]:
		main.settings_battle_frame.button_pressed = enabled
		await process_frame
		main.battle.command_power = main.battle.max_command
		main.selected_monster_type = "slime"
		var rect: Rect2 = main.battle_viewport_container.get_global_rect()
		var local_point := rect.size * Vector2(0.18, 0.78)
		var viewport_point := local_point * (Vector2(main.battle_viewport.size) / rect.size)
		var expected: Vector2 = main.battle.to_local(main.battle_viewport.get_canvas_transform().affine_inverse() * viewport_point)
		check(main.battle.get_manual_spawn_error("slime", expected).is_empty(), "fixture placement valid")
		outcome.ok = false
		main._try_manual_spawn_at_screen_position(rect.position + local_point)
		check(outcome.ok, "manual placement remains functional in both modes")
		var found := false
		for monster in get_nodes_in_group("monsters"):
			if monster is Node2D and monster.global_position.distance_to(main.battle.to_global(expected)) < 2.0:
				found = true
		check(found, "summon lands at transformed touch coordinate")
	main.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	print("BATTLE_CHROME_FAILED" if failed else "BATTLE_CHROME_OK")
	quit(1 if failed else 0)
