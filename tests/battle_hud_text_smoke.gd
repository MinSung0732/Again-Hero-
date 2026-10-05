extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("HUD_TEXT_TEST: " + message)
func fits(label: Label) -> bool:
	return label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x + 8 <= label.size.x
func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://hud-text-" + name + ".png")
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://hud_text_" + Crypto.new().generate_random_bytes(16).hex_encode()
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
	for enabled in [true, false]:
		main.settings_battle_frame.button_pressed = enabled
		for value in [0, 99, 100, 999]:
			main._on_command_changed(value, 999 if value == 999 else 100)
			await process_frame
			check(fits(main.command_label), "command digits fit " + str(value))
			check(not main.command_label.get_rect().intersects(main.command_bar.get_rect()), "command label/bar separated")
			check(not main.command_label.get_rect().intersects(main.status_label.get_rect()), "status/command separated")
			check(not main.command_bar.get_rect().intersects(main.placement_toggle.get_rect()), "bar/toggle separated")
	main._on_command_changed(100, 100)
	await capture("command")
	for special in [false, true]:
		var candidates: Array = (AUGMENTS.SPECIAL_AUGMENTS if special else AUGMENTS.NORMAL_AUGMENTS).slice(0,3)
		main._on_demon_augment_ready(candidates, 3, 10 if special else 2)
		await process_frame
		await process_frame
		check(main.demon_augment_guide.text.contains("특수증강" if special else "일반증강"), "complete guide belongs in modal")
		check(main.demon_augment_guide.get_visible_line_count() >= main.demon_augment_guide.get_line_count(), "all guide lines visible")
		check(fits(main.status_label), "compact augment status fits")
		check(main.demon_augment_guide.get_global_rect().end.y <= main.demon_choice_0.get_global_rect().position.y, "guide not over cards")
		check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(main.demon_augment_panel.get_global_rect()), "modal remains inside screen")
		await capture("special" if special else "normal")
	main.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	SCOPE.select_guest()
	print("BATTLE_HUD_TEXT_FAILED" if failed else "BATTLE_HUD_TEXT_OK")
	quit(1 if failed else 0)
