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
	root.get_node("LocalTestMode").tutorial_preview = false
	root.get_node("CloudStore").stop()
	var folder := "user://main_modes_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var cfg := ConfigFile.new()
	cfg.set_value("player_profile", "value", {"nickname": "달빛마왕", "gender": "female"})
	# This fixture tests already-unlocked preview navigation, not gating.
	for id in ["stage_1", "stage_10"]:
		cfg.set_value("cleared", id, true)
	for key in ["hard:stage_1", "hero", "rank"]:
		cfg.set_value("mode_unlock_seen", key, true)
	SCOPE.save_config(cfg, "user://stage_progress.cfg")
	# Since 10-14 (667ff0e8) ranked also requires the hero-mode Stage 10 easy clear.
	var hero_cfg := ConfigFile.new()
	hero_cfg.set_value("hero_progress", "stage_10_easy_wins", 1)
	SCOPE.save_config(hero_cfg, "user://team_loadout.cfg")
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
	# Since 10-13 (bfac549e) character selection lives in the formation tab, so the lobby has no character button.
	for target in [view.demon_button, view.hero_button, view.ranked_button, view.easy_button, view.hard_button]:
		check(target.icon != null and target.icon.get_width() == 64, "crisp native icon installed")
		check(target.icon.get_image().get_pixel(0, 0).a == 0, "transparent icon padding")
	check(view.demon_button.get_theme_stylebox("normal").bg_color == Color("523068") and view.hero_button.get_theme_stylebox("normal").bg_color == Color("281832"), "continuous frame preserves selected state")
	check(lobby.get_node("/root/PresentationWarmup").get_texture("res://assets/art/UI/main_modes/icon_rank.svg") != null, "new icon preloaded before lobby")
	await capture("stage")
	check(view.mode_row.get_global_rect().end.y < 1720, "mode controls above navigation")
	check(view.difficulty_row.get_global_rect().end.y <= lobby.portrait_texture.global_position.y, "difficulty above portrait")
	view.choose_difficulty("hard")
	check(view.difficulty == "easy" and not lobby._scene_load_pending, "hard preparation rejects selection")
	view.notice.hide()
	check(view.character_button == null, "no separate lobby character picker")
	view.open_characters()
	check(lobby.team_tab.visible, "character selection routes to the formation tab")
	lobby._switch_tab("main")
	await process_frame
	var rank_gateway = root.get_node("LoginGateway")
	rank_gateway.user_id = "00000000-0000-0000-0000-000000000001"
	rank_gateway.local_guest_active = false
	view.toggle_ranked()
	check(view.ranked_button.button_pressed and lobby.enter_stage_button.text == view.RANKED_ENTRY_TEXT, "ranked pressed and entry relabeled")
	check(view.ranked_button.get_theme_stylebox("normal").bg_color == Color("523068"), "ranked skin follows toggle")
	check(lobby.hero_name_label.text == "달빛마왕" and lobby.stage_status_label.text.contains("변동 없음"), "real nickname and no fabricated ranking")
	var selected: int = lobby.selected_stage_index
	lobby._change_stage(1)
	check(lobby.selected_stage_index == selected and lobby.prev_stage_button.disabled and lobby.next_stage_button.disabled, "rank arrows never alter stages")
	await capture("ranked-demon")
	# Ranked entry now starts the online match scene (blocks_entry -> SceneTransition), covered by the online tests.
	view.toggle_ranked()
	check(not view.ranked_button.button_pressed and lobby.stage_selector_button.text.begins_with("STAGE"), "second click restores stages")
	check(view.ranked_button.get_theme_stylebox("normal").bg_color == Color("281832"), "idle skin restored after ranked")
	check(lobby.selected_stage_index == selected and lobby.STAGE_PROGRESS.load_state() == before, "toggles preserve saved progression and profile")
	check(not view.blocks_entry(), "roundtrip restores real battle route")
	await capture("return")
	print("MAIN_MODES_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
