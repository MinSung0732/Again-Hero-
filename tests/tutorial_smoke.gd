extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false

class FakeCloud extends "res://src/network/cloud_store.gd":
	var tutorial_status := "pending"
	var awarded := false
	var offline := false
	var grants := 0
	var snapshot: Dictionary = {}
	var version := 1
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		await get_tree().process_frame
		if offline:
			return {}
		if method == "save_game_snapshot":
			if data.expected_revision != version:
				return {"conflict": true}
			snapshot = data.new_payload.duplicate(true)
			version += 1
			return {"ok": true, "revision": version}
		if method != "account_tutorial":
			return {}
		if data.action == "start" and tutorial_status == "pending":
			tutorial_status = "active"
		var result := {"ok": true, "status": tutorial_status, "reward_claimed": awarded}
		if data.action in ["skip", "complete"]:
			if data.expected_revision != version:
				return {"conflict": true}
			if not awarded:
				tutorial_status = "completed" if data.action == "complete" else "skipped"
				snapshot["stage_progress.cfg"].meta.gold += 1000
				version += 1
				awarded = true
				grants += 1
			result.merge({"status": tutorial_status, "reward_claimed": true, "granted": 1000 if grants == 1 else 0, "revision": version, "payload": snapshot.duplicate(true)}, true)
		return result

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("TUTORIAL_TEST: " + message)

func shot(name: String) -> void:
	await create_timer(0.6).timeout
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tutorial-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("CloudStore").stop()
	var bytes := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [bytes.substr(0,8),bytes.substr(8,4),bytes.substr(12,4),bytes.substr(16,4),bytes.substr(20,12)]
	SCOPE.select_account(id)
	SCOPE.install({"stage_progress.cfg": {"meta": {"gold": 23}, "progress": {"current_stage_id": "stage_1", "highest_unlocked_stage": 1}, "player_profile": {"value": {"nickname": "새벽군주", "gender": "male"}}}}, 1)
	var fake := FakeCloud.new()
	root.add_child(fake)
	fake.snapshot = SCOPE.files.duplicate(true)
	fake.ready_for_play = true
	var flow := root.get_node("TutorialFlow")
	flow.transport = fake
	var folder := "user://tutorial_fixture_" + bytes
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await shot("offer")
	check(flow.modal_visible and flow.primary.text == "진행" and flow.secondary.text == "스킵", "new-account choice")
	check(PROGRESS.get_gold() == 23, "no early reward")
	fake.offline = true
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 23 and fake.grants == 0 and flow.title.text == "보상 저장 실패", "offline never grants locally")
	fake.offline = false
	await flow.start_lobby()
	check(flow.active() and lobby.selected_stage_index == 0, "active tutorial persisted and stage one selected")
	await shot("entry")
	flow.primary_action.call()
	await shot("entry-highlight")
	check(not flow.modal_visible and flow.highlight.visible, "real entry target highlighted")
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
	await shot("summon")
	check(flow.modal_visible and main.battle.external_pause and flow.title.text == "몬스터 소환", "summon guide pauses real battle")
	flow.primary_action.call()
	var coach = flow.coach
	# Only the fixture accelerates resource recovery; live game rules are unchanged.
	main.battle.command_power = 30.0
	main.battle.try_summon(main.battle_loadout_ids[0])
	await process_frame
	check(coach.summoned and flow.title.text == "화면 고정 해제", "successful summon advances")
	flow.primary_action.call()
	main._open_pause_menu()
	main._open_settings_overlay()
	main.settings_camera_lock.button_pressed = false
	check(coach.camera and not main.camera_view_locked, "real camera checkbox works")
	main._close_pause_menu()
	# Use the normal event APIs, not timer polling or alternate tutorial battle rules.
	main.battle._open_mutation_choice({"type":"elite", "name":"튜토리얼 테스트", "mutation_profile_id":"mutation_1"})
	await shot("elite")
	check(flow.title.text == "엘리트 몬스터 소환" and main.mutation_panel.visible, "elite guide at real event")
	flow.primary_action.call()
	main._on_mutation_choice_pressed(0)
	await process_frame
	check(coach.elite, "real elite spawn completes lesson")
	main.battle._gain_demon_exp(main.battle.demon_exp_to_next_level)
	await shot("augment")
	check(flow.title.text == "마왕 증강 선택", "augment instructions include explicit confirmation")
	flow.primary_action.call()
	main._demon_choice_guard_until = 0
	main._on_demon_choice_pressed(0)
	main._demon_confirm_guard_until = 0
	main._on_demon_confirm_pressed()
	check(flow.coach_completed and flow.title.text == "튜토리얼 완료", "all actions complete tutorial")
	flow.returning_to_lobby()
	main.queue_free()
	await process_frame
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await shot("reward")
	check(PROGRESS.get_gold() == 1023 and fake.grants == 1 and fake.tutorial_status == "completed", "return grants exactly one draw cost")
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1023 and fake.grants == 1, "retry does not grant twice")
	flow.clear_guide()
	await flow.install_lobby(lobby)
	check(not flow.modal_visible, "completed account no repeat offer")
	fake.tutorial_status = "legacy"
	await flow.install_lobby(lobby)
	check(not flow.modal_visible, "legacy account excluded")
	# A distinct new-account fixture takes the immediate Skip path.
	var second := Crypto.new().generate_random_bytes(16).hex_encode()
	var second_id := "%s-%s-%s-%s-%s" % [second.substr(0,8),second.substr(8,4),second.substr(12,4),second.substr(16,4),second.substr(20,12)]
	SCOPE.select_account(second_id)
	SCOPE.install({"stage_progress.cfg": {"meta": {"gold": 0}}}, 1)
	fake.tutorial_status = "pending"
	fake.awarded = false
	fake.grants = 0
	fake.snapshot = SCOPE.files.duplicate(true)
	fake.version = 1
	await flow.install_lobby(lobby)
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000 and fake.grants == 1 and fake.tutorial_status == "skipped", "immediate skip grants same draw cost")
	await flow.finish_lobby()
	check(PROGRESS.get_gold() == 1000 and fake.grants == 1, "skip retry exactly once")
	flow.transport = null
	print("TUTORIAL_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
