extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("MODE_UNLOCK_TEST: " + message)

func shot(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://mode-unlock-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	root.get_node("CloudStore").stop()
	var folder := "user://mode_unlock_fixture_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "gold", 777)
	SCOPE.save_config(cfg, PROGRESS.SAVE_PATH)
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await lobby.prepare_presentation()
	var view = lobby.main_modes_view
	check(view.hard_button.disabled and view.hero_button.disabled and view.ranked_button.disabled, "fresh user locks")
	check(view.hard_button.icon == view.icons.lock and view.hero_button.icon == view.icons.lock, "lock icons")
	check(view.hero_button.tooltip_text.contains("10"), "unlock condition explained")
	view.choose_difficulty("hard")
	view.choose_perspective("hero")
	view.toggle_ranked()
	check(view.difficulty == "easy" and view.perspective == "demon" and not view.ranked, "direct handlers cannot bypass locks")
	await shot("locked")
	PROGRESS.complete_stage("stage_1", 1, "stage_2", 2, 0)
	lobby._refresh_stage_card()
	await process_frame
	check(not view.hard_button.disabled and view.hero_button.disabled, "stage1 clear unlocks only stage1 hard")
	check(is_instance_valid(view.unlock_feedback) and not view.unlock_feedback.ready_to_close, "opening animation focus and input guard")
	await create_timer(1.2).timeout
	check(view.unlock_feedback.ready_to_close, "opening animation finished")
	await shot("hard-open")
	view.unlock_feedback.close()
	await process_frame
	await process_frame
	check(UNLOCKS.announcement_seen("hard", "stage_1") and not is_instance_valid(view.unlock_feedback), "seen stored and no duplicate effect")
	view.choose_difficulty("hard")
	check(view.difficulty == "hard", "unlocked hard selectable")
	lobby.selected_stage_index = 1
	lobby._refresh_stage_card()
	check(view.hard_button.disabled and view.difficulty == "easy", "uncleared stage hard locked and selection corrected")
	SCOPE.load_config(cfg, PROGRESS.SAVE_PATH)
	cfg.set_value("progress", "highest_unlocked_stage", 10)
	SCOPE.save_config(cfg, PROGRESS.SAVE_PATH)
	lobby._refresh_stage_card()
	check(view.hero_button.disabled and view.ranked_button.disabled, "stage10 access alone insufficient")
	PROGRESS.complete_stage("stage_10", 10, "", 0, 0)
	lobby._refresh_stage_card()
	await process_frame
	check(not view.hero_button.disabled and not view.ranked_button.disabled, "stage10 clear unlocks hero and ranked")
	for key in ["hero", "rank"]:
		check(is_instance_valid(view.unlock_feedback), "global opening focus " + key)
		await create_timer(1.2).timeout
		await shot(key + "-open")
		view.unlock_feedback.close()
		await process_frame
		await process_frame
		check(UNLOCKS.announcement_seen(key, "stage_2"), "global seen " + key)
	view.choose_perspective("hero")
	view.toggle_ranked()
	check(view.ranked and view.perspective == "hero", "unlocked navigation works")
	check(view.blocks_entry(), "not-yet-implemented modes remain preview only")
	view.notice.hide()
	view.toggle_ranked()
	view.choose_perspective("demon")
	UNLOCKS.mark_announced("hard", "stage_10")
	check(PROGRESS.get_gold() == 777, "unlock feedback never changes rewards")
	# Actual tutorial buttons keep the same callbacks, only presentation changes.
	var flow := root.get_node("TutorialFlow")
	flow.bind_host(lobby)
	flow.show_modal("마왕의 첫 걸음", "튜토리얼을 진행할까요?", "진행", Callable(), "스킵", Callable())
	await create_timer(0.6).timeout
	check(flow.secondary.get_theme_stylebox("normal").bg_color == Color("34313a"), "skip is gray")
	check(flow.primary.get_theme_stylebox("normal").bg_color == Color("58247b"), "proceed remains highlighted purple")
	await shot("tutorial")
	flow.clear_guide()
	lobby.queue_free()
	await process_frame
	lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await lobby.prepare_presentation()
	await process_frame
	check(not is_instance_valid(lobby.main_modes_view.unlock_feedback), "reentry does not replay seen effects")
	# Another account/guest namespace must not inherit clear or seen state.
	var other := folder.path_join("other")
	DirAccess.make_dir_recursive_absolute(other)
	SCOPE.guest_directory = other
	SCOPE.select_guest()
	lobby._refresh_stage_card()
	check(lobby.main_modes_view.hero_button.disabled and not UNLOCKS.announcement_seen("hero", "stage_1"), "namespace isolation")
	root.get_node("LocalTestMode").active = true
	lobby._refresh_stage_card()
	check(not lobby.main_modes_view.hero_button.disabled and not lobby.main_modes_view.hard_button.disabled, "localtest keeps all-mode preview override")
	root.get_node("LocalTestMode").active = false
	print("MODE_UNLOCK_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
