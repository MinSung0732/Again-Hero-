extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const DATA := preload("res://src/data/prologue_catalog.gd")
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
var failed := false
var capture := false

class FakeCloud extends Node:
	var profile := {"nickname": "", "gender": "male", "required": true, "completed": false}
	var offline := false
	var duplicate := true
	var flush_ok := true
	var writes := 0
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		await get_tree().process_frame
		if offline:
			return {}
		if method == "register_player_profile":
			writes += 1
			if duplicate:
				return {"ok": false, "error": "duplicate"}
			profile.nickname = data.chosen_name
			profile.gender = data.chosen_gender
			profile.required = true
			profile.completed = false
		elif method == "complete_player_prologue":
			profile.completed = true
		return {"ok": true, "profile": profile.duplicate(true)}
	func flush() -> bool:
		await get_tree().process_frame
		return flush_ok

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("PROLOGUE_TEST: " + message)

func shot(filename: String) -> void:
	if capture and DisplayServer.get_name() != "headless":
		await create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://prologue-" + filename + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gateway := root.get_node("LoginGateway")
	gateway.remember_session_enabled = false
	gateway.access_token = ""
	root.get_node("LocalTestMode").active = false
	root.get_node("CloudStore").stop()
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	gateway.user_id = id
	var config := ConfigFile.new()
	config.set_value("meta", "gold", 777)
	check(SCOPE.save_config(config, PROFILE.PATH) == OK, "fixture progress")
	var cloud := FakeCloud.new()
	root.add_child(cloud)
	var startup: Control = load("res://tests/player_prologue_startup_probe.gd").new()
	startup.profile_cloud = cloud
	root.add_child(startup)
	startup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	startup._lobby = PackedScene.new()
	startup.phase = startup.Phase.LOGIN
	await startup._enter_lobby()
	check(startup.phase == startup.Phase.PROLOGUE and not startup.entered, "fresh account cannot bypass prologue")
	var view: Control = startup.prologue
	check(view.index == 0 and view.background.modulate.a == 0, "begins in darkness")
	await process_frame
	view._process(0.1)
	check(view.text_label.visible_characters != 0, "typewriter advances")
	view.index = 3
	view._show_line()
	view._last_tap = -1000
	view.advance()
	check(view.index == 3 and view.text_label.visible_characters == -1, "first tap reveals without advancing")
	for i in range(1, 20):
		view.index = i
		view._show_line()
	check(is_instance_valid(view.choice), "gender gate")
	view._last_tap = -1000
	view.advance()
	check(view.index == 19, "tap cannot bypass gender")
	await shot("gender")
	view._select_gender("female")
	check(view.portrait.texture == PROLOGUE.FEMALE, "female portrait selected")
	for i in range(21, 29):
		view.index = i
		view._show_line()
	check(view.name_input.max_length == 6 and view.confirm.disabled, "empty name disabled, six-character limit")
	for bad in ["", "일곱글자이름임", "a b", " 이름", "이름!", "ㄱ", "ab\n"]:
		check(not PROFILE.valid_name(bad), "reject invalid name " + bad)
	for good in ["왕", "마왕테스트6", "Hero12"]:
		check(PROFILE.valid_name(good), "accept valid name " + good)
	for i in range(100):
		var generated := PROFILE.random_name("새벽군주1")
		check(PROFILE.valid_name(generated) and generated != "새벽군주1", "dice valid and changes")
	view.name_input.text = "새벽군주1"
	view._validate_name(view.name_input.text)
	await view._register_name()
	check(view.index == 28 and view.error_label.text.contains("이미 사용"), "duplicate remains editable")
	cloud.offline = true
	await view._register_name()
	check(view.name_input.editable and not view.dice.disabled, "offline name remains editable")
	cloud.offline = false
	cloud.duplicate = false
	view.dice.pressed.emit()
	check(view.name_input.text != "새벽군주1", "dice button updates input")
	view.name_input.text = "달빛마왕7"
	view._validate_name(view.name_input.text)
	await shot("nickname")
	await view._register_name()
	check(view.index == DATA.AFTER_REGISTRATION and PROFILE.display_name() == "마왕(달빛마왕7)", "confirmed profile stored")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 777, "existing progress preserved")
	check(SCOPE.select_account(id), "restart namespace")
	check(PROFILE.portrait_path().ends_with("female.png"), "restart gender persistence")
	view.hide()
	var resumed := PROLOGUE.new()
	resumed.cloud = cloud
	root.add_child(resumed)
	check(resumed.index == DATA.AFTER_REGISTRATION, "unfinished prologue resumes after name, no repeat reservation")
	for i in range(DATA.AFTER_REGISTRATION, DATA.LINES.size()):
		resumed.index = i
		resumed._show_line()
		check(not resumed.text_label.text.contains("{nickname}"), "name substitution")
	resumed.text_label.visible_characters = -1
	await shot("ending")
	var finished := [false]
	resumed.finished.connect(func(): finished[0] = true)
	cloud.flush_ok = false
	await resumed._finish()
	check(not finished[0] and resumed.hint.text.contains("실패"), "flush failure blocks lobby and enables retry")
	cloud.flush_ok = true
	await resumed._finish()
	check(finished[0] and not PROFILE.needs_prologue(PROFILE.get_profile()), "completion saved before lobby")
	resumed.queue_free()
	startup.queue_free()
	await process_frame
	var dialogue: CanvasLayer = load("res://src/ui/StageIntroCutscene.tscn").instantiate()
	root.add_child(dialogue)
	dialogue.play_dialogue({"hero_name": "용사", "lines": [{"speaker": "demon", "text": "귀환했다."}]})
	await process_frame
	await process_frame
	check(dialogue.demon_name.text == "마왕(달빛마왕7)" and dialogue.dialogue_speaker.text == PROFILE.display_name(), "later dialogue speaker")
	check(dialogue.demon_portrait.texture.resource_path == PROFILE.portrait_path(), "later dialogue female portrait")
	await shot("dialogue")
	dialogue.queue_free()
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	root.get_node("AudioSettings").config_path = folder.path_join("fixture_audio.cfg")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("fixture_gameplay.cfg")
	root.add_child(lobby)
	lobby._switch_tab("other")
	lobby.settings_view.show_page("account")
	check(lobby.settings_view.profile_label.text.contains("달빛마왕7") and lobby.settings_view.profile_label.text.contains("여성"), "account profile display")
	var withdrawal: Button = lobby.settings_view.pages.account.get_node("AccountWithdrawal")
	check(withdrawal.disabled and withdrawal.pressed.get_connections().is_empty(), "withdrawal presentation only, no deletion handler")
	await shot("account")
	lobby.queue_free()
	await process_frame
	cloud.profile.gender = "male"
	check(bool((await PROFILE.refresh(cloud)).get("ok", false)), "profile reloaded from server")
	check(PROFILE.portrait_path().ends_with("male.png"), "male portrait mapping")
	cloud.profile = {"nickname": "", "gender": "male", "required": false, "completed": true}
	var legacy: Control = load("res://tests/player_prologue_startup_probe.gd").new()
	legacy.profile_cloud = cloud
	root.add_child(legacy)
	legacy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	legacy._lobby = PackedScene.new()
	legacy.phase = legacy.Phase.LOGIN
	await legacy._enter_lobby()
	check(legacy.entered and legacy.prologue == null, "existing saved account skips mandatory prologue")
	legacy.queue_free()
	await process_frame
	cloud.offline = true
	var failure: Control = load("res://tests/player_prologue_startup_probe.gd").new()
	failure.profile_cloud = cloud
	root.add_child(failure)
	failure.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	failure._lobby = PackedScene.new()
	failure.phase = failure.Phase.LOGIN
	await failure._enter_lobby()
	check(not failure.entered and failure.phase == failure.Phase.LOGIN and failure.login_screen.visible, "profile outage does not misclassify account")
	failure.queue_free()
	cloud.queue_free()
	gateway.user_id = ""
	SCOPE.select_guest()
	print("PLAYER_PROLOGUE_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
