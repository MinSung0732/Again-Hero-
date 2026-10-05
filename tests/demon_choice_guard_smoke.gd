extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CHOICE_GUARD_TEST: " + message)
func tap(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
		await process_frame
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://choice_guard_" + Crypto.new().generate_random_bytes(16).hex_encode()
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
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	main.battle.set_external_pause(true)
	var held := InputEventScreenTouch.new()
	held.index = 2
	held.pressed = true
	main._guard_demon_choice_pointer(held)
	main.battle.demon_pending_augments = 2
	main.battle.demon_pending_augment_levels.assign([2, 3])
	main.battle._open_next_demon_augment_if_needed()
	await process_frame
	check(main.demon_choice_0.disabled and main.demon_confirm_button.disabled, "modal starts locked")
	await tap(main.demon_choice_0)
	main._on_demon_choice_pressed(0)
	main._on_demon_confirm_pressed()
	main._on_demon_reroll_pressed()
	check(main._demon_selected_index == -1 and main.battle.demon_pending_augments == 2, "opening taps and handler calls do not apply")
	await create_timer(0.7).timeout
	check(main.demon_choice_0.disabled, "finger held before opening remains blocked after delay")
	held.pressed = false
	check(main._guard_demon_choice_pointer(held), "old finger release is consumed")
	await process_frame
	await process_frame
	check(not main.demon_choice_0.disabled, "new input enabled after release")
	await tap(main.demon_choice_0)
	check(main._demon_selected_index == 0 and main.battle.demon_pending_augments == 2, "card tap previews only, no augment applied")
	check(main.demon_choice_0.button_pressed, "selection visibly highlighted")
	await tap(main.demon_confirm_button)
	main._on_demon_confirm_pressed()
	check(main.battle.demon_pending_augments == 2, "same rapid input cannot confirm")
	await create_timer(0.3).timeout
	await process_frame
	await tap(main.demon_confirm_button)
	check(main.battle.demon_pending_augments == 1, "separate confirm applies exactly one augment")
	check(main.demon_augment_panel.visible and not main.current_demon_candidates.is_empty(), "queued level modal stays visible")
	check(main._demon_selected_index == -1 and main.demon_choice_0.disabled, "queued modal clears selection and rearms guard")
	await create_timer(0.7).timeout
	await process_frame
	await tap(main.demon_choice_1)
	await create_timer(0.3).timeout
	await process_frame
	var rerolls: int = main.battle.demon_rerolls_left
	await tap(main.demon_reroll_button)
	check(main.battle.demon_rerolls_left == rerolls - 1, "reroll retains existing cost")
	check(main._demon_selected_index == -1 and main.demon_confirm_button.disabled and main.demon_choice_0.disabled, "reroll clears selection and rearms guard")
	main._on_demon_confirm_pressed()
	check(main.battle.demon_pending_augments == 1, "stale confirm cannot apply rerolled choice")
	await create_timer(0.7).timeout
	await process_frame
	await tap(main.demon_choice_2)
	await create_timer(0.3).timeout
	await process_frame
	await tap(main.demon_confirm_button)
	check(main.battle.demon_pending_augments == 0 and not main.demon_augment_panel.visible, "final confirm closes modal")
	check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(main.demon_confirm_button.get_global_rect()), "confirm button stays inside screen")
	if "--capture" in OS.get_cmdline_user_args():
		main._on_demon_augment_ready(main.battle._roll_demon_augment_candidates(false), 1, 4)
		await create_timer(0.7).timeout
		await process_frame
		await tap(main.demon_choice_0)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://demon-choice-confirm.png")
	main.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	SCOPE.select_guest()
	print("DEMON_CHOICE_GUARD_FAILED" if failed else "DEMON_CHOICE_GUARD_OK")
	quit(1 if failed else 0)
