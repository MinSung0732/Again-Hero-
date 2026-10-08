extends SceneTree
const SCOPE = preload("res://src/systems/account_save_scope.gd")
const STAMINA = preload("res://src/systems/stamina_store.gd")
const PROGRESS = preload("res://src/systems/stage_progress.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value:
		failed = true
		push_error("DUNGEON_ENTRY: " + message)
func settle():
	await process_frame
	await process_frame
func wait_entry():
	var deadline := Time.get_ticks_msec() + 30000
	var transition = root.get_node("SceneTransition")
	while transition.is_transitioning() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not transition.is_transitioning(), "transition completes within deadline")
	await settle()
func seed_wallet(amount: int, unlock: int = 1):
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("stamina", "amount", amount)
	config.set_value("stamina", "recovery_at", int(Time.get_unix_time_from_system()))
	config.set_value("progress", "highest_unlocked_stage", unlock)
	check(SCOPE.save_configs({"stage_progress.cfg": config}) == OK, "wallet seed")
	STAMINA.invalidate()
func check_reveal(label: String):
	check(not current_scene.stage_intro_cutscene._active, label + " skips dialogue")
	check(current_scene.hero_reveal_cutscene._active, label + " starts reveal")
	check(current_scene.hero_reveal_cutscene.EFFECT_FRAME_COUNT == 30, label + " retains thirty-frame entry")
	check(current_scene.battle.external_pause, label + " pauses battle until reveal completes")
	check(current_scene._presentation_ready and current_scene.battle._monster_spawn_resources_warmed, label + " preparation complete")
	check(root.get_node("SceneTransition").consume_entry_options().is_empty(), label + " context consumed once")
func wait_reveal():
	var deadline := Time.get_ticks_msec() + 12000
	while current_scene.hero_reveal_cutscene._active and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not current_scene.battle.external_pause and current_scene.hud_layer.visible, "reveal completion enters playable battle")
func run():
	Engine.max_fps = 60
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	var folder := "user://dungeon_entry_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.guest_directory = folder
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.select_guest()
	preload("res://src/systems/team_loadout_store.gd").save_ids(["slime", "spider", "orc"], preload("res://src/data/monster_catalog.gd").ORDER)
	var skills: Array = preload("res://src/data/demon_ultimate_catalog.gd").get_ordered_ids()
	preload("res://src/systems/demon_skill_loadout_store.gd").save_ids(skills.slice(0, 3), skills)
	seed_wallet(30)
	var transition = root.get_node("SceneTransition")
	check(transition.change_scene("res://src/lobby/Lobby.tscn"), "lobby load")
	await wait_entry()
	var started := Time.get_ticks_msec()
	check(transition.change_scene("res://src/main/Main.tscn"), "normal dungeon load")
	check(not transition.change_scene("res://src/main/Main.tscn", "duplicate", {"skip_stage_dialogue":true}), "duplicate rejected without context overwrite")
	await wait_entry()
	print("DUNGEON_ENTRY cold lobby-to-dialogue ms=", Time.get_ticks_msec() - started)
	check(current_scene.stage_intro_cutscene._active, "normal entry keeps dialogue")
	current_scene.stage_intro_cutscene._on_skip_pressed()
	await settle()
	await wait_reveal()
	var before: int = STAMINA.read_state().amount
	current_scene._open_pause_menu()
	check(current_scene.pause_menu.visible, "actual pause menu opens")
	current_scene.pause_restart_button.pressed.emit()
	current_scene.pause_restart_button.pressed.emit()
	await wait_entry()
	check(STAMINA.read_state().amount == before - 5, "menu restart debits once")
	check_reveal("menu restart")
	await wait_reveal()
	before = STAMINA.read_state().amount
	current_scene.battle._finish_battle("테스트 패배", false)
	check(current_scene.result_panel.visible, "actual result panel opens")
	current_scene.restart_button.pressed.emit()
	await wait_entry()
	check(STAMINA.read_state().amount == before - 5, "result restart debit")
	check_reveal("result restart")
	await wait_reveal()
	seed_wallet(4)
	var previous_scene = current_scene
	current_scene.restart_button.pressed.emit()
	await settle()
	check(current_scene == previous_scene and not transition.is_transitioning() and not current_scene._stamina_entry_pending, "insufficient restart stays in battle")
	check(transition.consume_entry_options().is_empty() and STAMINA.read_state().amount == 4, "failed restart leaks no flag/debit")
	seed_wallet(30, 2)
	current_scene._on_next_stage_pressed()
	await wait_entry()
	check(current_scene.battle.current_stage_id == "stage_2", "next-stage enters correct stage")
	check(current_scene.stage_intro_cutscene._active, "next-stage keeps its dialogue")
	check(not PROGRESS.has_seen_stage_intro("stage_2"), "restart does not mark future dialogue seen")
	print("DUNGEON_ENTRY_RESTART: ", "FAIL" if failed else "PASS")
	current_scene.queue_free()
	await settle()
	for filename in SCOPE.FILES + ["gameplay_transaction.json", "gameplay_transaction.json.tmp"]:
		if FileAccess.file_exists(folder.path_join(filename)):
			DirAccess.remove_absolute(folder.path_join(filename))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	quit(1 if failed else 0)
