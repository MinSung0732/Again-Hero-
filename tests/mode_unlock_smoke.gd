extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("MODE_UNLOCK_TEST: " + message)

func skinned(bg: String, edge: String, width: int) -> Texture2D:
	# Tutorial buttons use the shared pixel skin (StyleBoxTexture cached per background colour) since 10-06.
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(bg)
	flat.border_color = Color(edge)
	flat.set_border_width_all(width)
	return (SKIN.skin_style(flat) as StyleBoxTexture).texture

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
	# Returning guest: since 10-12 a pending/unknown guest tutorial modal suppresses unlock announcements.
	cfg.set_value("player_profile", "value", {"nickname": "해금마왕", "gender": "female", "required": true, "completed": true})
	cfg.set_value("guest_tutorial", "status", "skipped")
	cfg.set_value("guest_tutorial", "claimed", true)
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
	# Since 10-14 (b0633ef1) hero mode opens after the demon Stage 3 easy clear.
	check(view.hero_button.tooltip_text.contains("3스테이지"), "unlock condition explained")
	view.choose_difficulty("hard")
	await view.choose_perspective("hero")
	view.toggle_ranked()
	check(view.difficulty == "easy" and view.perspective == "demon" and not view.ranked, "direct handlers cannot bypass locks")
	await shot("locked")
	PROGRESS.complete_stage("stage_1", 1, "stage_2", 2, 0)
	# First clears grant once-only clear gold; announcements must not add anything on top.
	var expected_gold := PROGRESS.get_gold()
	lobby._refresh_stage_card()
	await process_frame
	check(view.hard_button.disabled and UNLOCKS.unlocked("hard","stage_1") and view.hero_button.disabled, "stage1 hard unlocked but preparing")
	check(is_instance_valid(view.unlock_feedback) and not view.unlock_feedback.ready_to_close, "opening animation focus and input guard")
	await create_timer(1.2).timeout
	check(view.unlock_feedback.ready_to_close, "opening animation finished")
	await shot("hard-open")
	view.unlock_feedback.close()
	await process_frame
	await process_frame
	check(UNLOCKS.announcement_seen("hard", "stage_1") and not is_instance_valid(view.unlock_feedback), "seen stored and no duplicate effect")
	view.choose_difficulty("hard")
	check(view.difficulty == "easy", "unlocked hard unavailable")
	lobby.selected_stage_index = 1
	lobby._refresh_stage_card()
	check(view.hard_button.disabled and view.difficulty == "easy", "uncleared stage hard locked and selection corrected")
	SCOPE.load_config(cfg, PROGRESS.SAVE_PATH)
	cfg.set_value("progress", "highest_unlocked_stage", 10)
	SCOPE.save_config(cfg, PROGRESS.SAVE_PATH)
	lobby._refresh_stage_card()
	check(view.hero_button.disabled and view.ranked_button.disabled, "stage10 access alone insufficient")
	PROGRESS.complete_stage("stage_3", 3, "stage_4", 4, 0)
	expected_gold = PROGRESS.get_gold()
	lobby._refresh_stage_card()
	await process_frame
	check(not view.hero_button.disabled and view.ranked_button.disabled, "demon stage3 opens hero but rank stays locked")
	for key in ["hero"]:
		check(is_instance_valid(view.unlock_feedback), "global opening focus " + key)
		await create_timer(1.2).timeout
		await shot(key + "-open")
		view.unlock_feedback.close()
		await process_frame
		await process_frame
		check(UNLOCKS.announcement_seen(key, "stage_2"), "global seen " + key)
	PROGRESS.complete_stage("stage_10", 10, "", 0, 0)
	expected_gold = PROGRESS.get_gold()
	lobby._refresh_stage_card()
	await process_frame
	check(view.ranked_button.disabled, "demon stage10 alone cannot open rank without hero easy10")
	var hero_progress := ConfigFile.new()
	SCOPE.load_config(hero_progress,"user://team_loadout.cfg")
	hero_progress.set_value("hero_progress","stage_10_easy_wins",1)
	SCOPE.save_config(hero_progress,"user://team_loadout.cfg")
	lobby._refresh_stage_card()
	await process_frame
	await create_timer(1.2).timeout
	check(not view.ranked_button.disabled,"both easy10 clears open rank")
	if is_instance_valid(view.unlock_feedback): view.unlock_feedback.close()
	await process_frame
	await process_frame
	await view.choose_perspective("hero")
	view.toggle_ranked()
	check(view.ranked and view.perspective == "hero", "unlocked navigation works")
	# Ranked entry now starts the online match scene (covered by the online tests); check the request only.
	check(view.request_data().page == "ranked" and view.request_data().perspective == "hero", "ranked request carries the chosen role")
	view.toggle_ranked()
	await view.choose_perspective("demon")
	UNLOCKS.mark_announced("hard", "stage_10")
	check(PROGRESS.get_gold() == expected_gold, "unlock feedback never changes rewards")
	# Actual tutorial buttons keep the same callbacks, only presentation changes.
	var flow := root.get_node("TutorialFlow")
	flow.bind_host(lobby)
	flow.show_modal("마왕의 첫 걸음", "튜토리얼을 진행할까요?", "진행", Callable(), "스킵", Callable())
	await create_timer(0.6).timeout
	check((flow.secondary.get_theme_stylebox("normal") as StyleBoxTexture).texture == skinned("34313a", "827e8b", 2), "skip is gray")
	check((flow.primary.get_theme_stylebox("normal") as StyleBoxTexture).texture == skinned("58247b", "e8bd58", 3), "proceed remains highlighted purple")
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
	root.get_node("LocalTestMode").test_directory = SCOPE.guest_directory
	root.get_node("LocalTestMode").active = true
	lobby._refresh_stage_card()
	check(not lobby.main_modes_view.hero_button.disabled and lobby.main_modes_view.hard_button.disabled, "localtest cannot bypass hard preparation")
	root.get_node("LocalTestMode").active = false
	print("MODE_UNLOCK_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
