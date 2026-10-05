extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("MAIN_MODES_TEST: " + message)

func capture(name: String) -> void:
	await process_frame
	await process_frame
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://main-modes-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("CloudStore").stop()
	var folder := "user://main_modes_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("player_profile", "value", {"nickname": "달빛마왕", "gender": "female"})
	SCOPE.save_config(cfg, "user://stage_progress.cfg")
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("gameplay.cfg")
	root.add_child(lobby)
	current_scene = lobby
	var view = lobby.main_modes_view
	var before: Dictionary = lobby.STAGE_PROGRESS.load_state().duplicate(true)
	check(not view.ranked and view.perspective == "demon" and view.difficulty == "easy", "default keeps existing battle route")
	check(not view.blocks_entry(), "normal demon entry remains available")
	await capture("stage")
	check(view.mode_row.get_global_rect().end.y < 1720, "mode controls above navigation")
	check(view.difficulty_row.get_global_rect().end.y <= lobby.portrait_texture.global_position.y, "difficulty above portrait")
	view.choose_difficulty("hard")
	check(view.blocks_entry() and not lobby._scene_load_pending, "hard is UI only")
	view.notice.hide()
	view.choose_difficulty("easy")
	view.choose_perspective("hero")
	check(view.blocks_entry(), "hero stage is UI only")
	view.notice.hide()
	view.toggle_ranked()
	check(view.ranked_button.button_pressed and lobby.enter_stage_button.text == "매칭 시작", "ranked pressed and entry relabeled")
	check(lobby.hero_name_label.text == "달빛마왕" and lobby.stage_status_label.text.contains("미배치"), "real nickname and no fabricated ranking")
	check(view.character_button.visible and view.heroes.size() == 1, "only known unlocked hero selectable")
	var selected: int = lobby.selected_stage_index
	lobby._change_stage(1)
	check(lobby.selected_stage_index == selected, "rank arrows never alter stages")
	await capture("ranked-hero")
	view.open_characters()
	await capture("characters")
	for child in lobby.get_children():
		if child is AcceptDialog and child != view.notice:
			child.queue_free()
	await process_frame
	view.choose_perspective("demon")
	check(not view.character_button.visible and lobby.prev_stage_button.disabled and lobby.next_stage_button.disabled, "demon portrait has no hero cycling")
	check(view.blocks_entry(), "matching is preview only")
	view.notice.hide()
	await capture("ranked-demon")
	view.toggle_ranked()
	check(not view.ranked_button.button_pressed and lobby.stage_selector_button.text.begins_with("STAGE"), "second click restores stages")
	check(lobby.selected_stage_index == selected and lobby.STAGE_PROGRESS.load_state() == before, "toggles preserve saved progression and profile")
	check(not view.blocks_entry(), "roundtrip restores real battle route")
	await capture("return")
	print("MAIN_MODES_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
