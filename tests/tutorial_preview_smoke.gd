extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const LINES := preload("res://src/data/prologue_catalog.gd")
var failed := false

class NoNetwork extends Node:
	var calls := 0
	func request_rpc(_method: String, _data: Dictionary) -> Dictionary:
		calls += 1
		return {}
	func flush() -> bool:
		calls += 1
		return false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("PREVIEW_TEST: " + message)

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tutorial-preview-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gateway := root.get_node("LoginGateway")
	gateway.remember_session_enabled = false
	root.get_node("CloudStore").stop()
	var folder := "user://tutorial_preview_fixture_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	var mode := root.get_node("LocalTestMode")
	mode.active = false
	mode.tutorial_preview = false
	mode.pending_reset_id = ""
	mode.marker_path = folder.path_join("mode.cfg")
	mode.test_directory = folder.path_join("test")
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	check(mode.reset_progress(), "seed original guest")
	PROGRESS.add_research_points(73, 41)
	var original := FileAccess.get_file_as_string(folder.path_join("stage_progress.cfg"))
	var good_marker: String = mode.marker_path
	mode.marker_path = folder.path_join("missing/marker.cfg")
	check(not await mode.apply_coupon("tutorialtest"), "marker save failure denies entry")
	check(not mode.tutorial_preview and SCOPE.guest_directory == folder and FileAccess.get_file_as_string(folder.path_join("stage_progress.cfg")) == original, "failed entry restores original namespace")
	mode.marker_path = good_marker
	check(await mode.apply_coupon("tutorialtest"), "coupon enters preview")
	check(mode.is_tutorial_preview() and not mode.active, "isolated guest without cheat funds")
	check(PROGRESS.get_gold() == 0 and not PROGRESS.is_stage_unlocked(2), "first user defaults")
	var first_directory: String = mode.preview_directory
	var persisted := ConfigFile.new()
	persisted.load(mode.marker_path)
	check(persisted.get_value("mode", "tutorial_preview", false), "preview survives restart")
	# Re-read startup marker as on app restart, using only fixture paths.
	mode._ready()
	check(SCOPE.guest_directory == first_directory, "restart keeps namespace")
	var network := NoNetwork.new()
	root.add_child(network)
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var startup = load("res://src/startup/Startup.tscn").instantiate()
	root.add_child(startup)
	current_scene = startup
	startup.profile_cloud = network
	startup._lobby = load("res://src/lobby/Lobby.tscn")
	startup.phase = startup.Phase.LOGIN
	startup._enter_lobby()
	await process_frame
	check(startup.phase == startup.Phase.PROLOGUE and is_instance_valid(startup.prologue), "guest startup enters real prologue")
	var view = startup.prologue
	# Run the authored sequence and real choice controls with fixture typing speed.
	while LINES.LINES[view.index].get("kind", "") != "gender":
		view.text_label.visible_characters = -1
		view._last_tap = -1000
		view.advance()
	view._select_gender("female")
	while LINES.LINES[view.index].get("kind", "") != "name":
		view.text_label.visible_characters = -1
		view._last_tap = -1000
		view.advance()
	view.name_input.text = "테스트"
	view._validate_name(view.name_input.text)
	check(view.error_label.text.contains("서버 등록/중복 검사 없음"), "no fake uniqueness promise")
	await capture("name")
	await view._register_name()
	check(PROFILE.display_name() == "마왕(테스트)" and PROFILE.get_profile().gender == "female", "real choice stored locally")
	# Completion uses the same profile operation but suppress scene transition in fixture.
	check(await PROFILE.complete(network), "prologue completion persisted")
	check(not PROFILE.needs_prologue((await PROFILE.refresh(network)).profile), "restart skips completed prologue")
	startup.queue_free()
	await process_frame
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await create_timer(0.7).timeout
	var flow := root.get_node("TutorialFlow")
	check(flow.modal_visible and flow.primary.text == "진행", "guest gets tutorial offer")
	await capture("offer")
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000 and flow.status == "skipped", "skip gives local draw cost")
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000, "repeat skip no duplicate")
	check(network.calls == 0 and not root.get_node("CloudStore").ready_for_play, "no server calls or writes")
	check(FileAccess.get_file_as_string(folder.path_join("stage_progress.cfg")) == original, "original guest unchanged")
	check(not await mode.apply_coupon("localtest"), "cannot accidentally switch cheat mode")
	check(await mode.apply_coupon("tutorialtest"), "repeat coupon creates fresh first user")
	check(mode.preview_directory != first_directory and PROFILE.get_profile().is_empty() and PROGRESS.get_gold() == 0, "profile and reward reset only in fresh preview")
	await flow.install_lobby(lobby)
	await flow.start_lobby()
	check(flow.active(), "proceed activates existing battle coach")
	flow.clear_guide()
	lobby.queue_free()
	await process_frame
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
	main._start_battle_after_intro("stage_1")
	check(flow.modal_visible and flow.title.text == "몬스터 소환", "preview installs actual battle coach")
	flow.primary_action.call()
	# Fixture-only acceleration: production battle timing/resources are unchanged.
	main.battle.command_power = 30
	main.battle.try_summon(main.battle_loadout_ids[0])
	await process_frame
	check(flow.coach.summoned and flow.title.text == "화면 고정 해제", "summon taught")
	flow.primary_action.call()
	main._open_pause_menu()
	main._open_settings_overlay()
	main.settings_camera_lock.button_pressed = false
	main._close_pause_menu()
	main.battle._open_mutation_choice({"type":"elite", "name":"테스트", "mutation_profile_id":"mutation_1"})
	flow.primary_action.call()
	main._on_mutation_choice_pressed(0)
	await process_frame
	main.battle._gain_demon_exp(main.battle.demon_exp_to_next_level)
	flow.primary_action.call()
	main._demon_choice_guard_until = 0
	main._on_demon_choice_pressed(0)
	main._demon_confirm_guard_until = 0
	main._on_demon_confirm_pressed()
	check(flow.coach_completed and flow.title.text == "튜토리얼 완료", "all actual actions taught in preview")
	flow.returning_to_lobby()
	main.queue_free()
	await process_frame
	lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await create_timer(0.7).timeout
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000 and flow.status == "completed", "complete equals skip")
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000, "complete retry once")
	check(await mode.apply_coupon("normaltest"), "exit preview")
	check(not mode.tutorial_preview and mode.pending_reset_id.is_empty(), "no deferred social reset")
	check(SCOPE.guest_directory == folder and FileAccess.get_file_as_string(folder.path_join("stage_progress.cfg")) == original, "normaltest restores original guest without reset")
	check(PROGRESS.get_gold() == 41 and PROGRESS.get_research_points() == 73, "original currency preserved")
	await flow.install_lobby(lobby)
	check(not flow.active(), "normal guest excluded again")
	# A clean isolated social snapshot must remain byte-for-byte unchanged.
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	SCOPE.select_account(id)
	SCOPE.install({"stage_progress.cfg":{"meta":{"gold":987,"research_points":654},"player_profile":{"value":{"nickname":"원래마왕","gender":"male","required":true,"completed":true}}}}, 5)
	var original_path := SCOPE.resolve("user://save_bundle.json")
	var original_account := FileAccess.get_file_as_string(original_path)
	check(not await mode.apply_coupon("tutorialtest"), "unverified cloud save prevents social entry")
	check(SCOPE.user_id == id and FileAccess.get_file_as_string(original_path) == original_account, "failed social entry unchanged")
	root.get_node("CloudStore").ready_for_play = true # Clean snapshot flush does not make a request.
	gateway.user_id = id
	check(await mode.apply_coupon("tutorialtest"), "social account enters isolated guest preview")
	await gateway._on_validated({"access_token":"late_fixture"}, {"id":id})
	check(SCOPE.user_id.is_empty(), "late OAuth cannot select original social account")
	await PROFILE.refresh(network)
	await PROFILE.register(network, "테스트", "female")
	check(network.calls == 0, "preview profile never sends requests")
	check(await mode.apply_coupon("normaltest") and mode.pending_reset_id.is_empty(), "social preview exit never schedules reset")
	check(FileAccess.get_file_as_string(original_path) == original_account, "original account profile and progress unchanged")
	print("TUTORIAL_PREVIEW_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
