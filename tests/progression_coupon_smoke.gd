extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var failed := false

class FakeCloud:
	extends "res://src/network/cloud_store.gd"
	var payload := {"stage_progress.cfg":{"progress":{"current_stage_id":"stage_3","highest_unlocked_stage":3},"meta":{"gold":500,"research_points":20}}}
	var remote_revision := 7
	var uploads := 0
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		if method == "read_game_save":
			return {"found":true,"revision":remote_revision,"payload":payload.duplicate(true)}
		if int(data.get("expected_revision", -1)) != remote_revision:
			return {"conflict":true}
		payload = data.new_payload.duplicate(true)
		remote_revision += 1
		uploads += 1
		return {"ok":true,"revision":remote_revision}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("COUPON_TEST: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://coupon_smoke_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var mode := root.get_node("LocalTestMode")
	mode.active = false
	mode.marker_path = folder.path_join("mode.cfg")
	mode.test_directory = folder.path_join("test")
	check(mode.reset_progress(), "reset normal save")
	check(PROGRESS.load_state().highest_unlocked_stage == 1 and not PROGRESS.is_stage_unlocked(2), "only stage1 unlocked")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await lobby.prepare_presentation()
	check(lobby._get_max_browsable_stage_index() == 2, "stage1/2/3 browsable, not4")
	lobby.selected_stage_index = 1
	lobby._refresh_stage_card()
	check(lobby.enter_stage_button.disabled and lobby.portrait_texture.self_modulate.r < 0.4, "stage2 dark and locked")
	check(lobby.portrait_texture.get_node("StageLock").visible, "lock icon visible")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://stage2-locked-preview.png")
	lobby.selected_stage_index = 2
	lobby._refresh_stage_card()
	check(lobby.portrait_texture.self_modulate == Color.BLACK and lobby.hero_name_label.text == "???", "stage3 silhouette")
	check(lobby.next_stage_button.disabled, "stage4 navigation blocked")
	PROGRESS.complete_stage("stage_1",1,"stage_2",2,100)
	check(PROGRESS.is_stage_unlocked(2) and not PROGRESS.is_stage_unlocked(3), "clear unlocks one stage")
	check(lobby._get_max_browsable_stage_index() == 3, "clear reveals one more preview")
	check(lobby.other_account_panel.has_node("CouponButton") and lobby.has_node("CouponOverlay"), "coupon UI installed in account")
	lobby._switch_tab("other")
	lobby.other_account_panel.get_node("CouponButton").pressed.emit()
	check(lobby.get_node("CouponOverlay").visible, "coupon button opens modal")
	var coupon_entry := lobby.get_node("CouponOverlay").find_child("CouponNumber", true, false) as LineEdit
	coupon_entry.text = "invalid"
	lobby.get_node("CouponOverlay").find_child("Submit", true, false).pressed.emit()
	check(lobby.get_node("CouponOverlay").find_child("Notice", true, false).text == "사용할 수 없는 쿠폰입니다.", "modal rejects invalid input")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://coupon-modal-preview.png")
	lobby.get_node("CouponOverlay").hide()
	check(not await mode.apply_coupon("invalid"), "unknown coupon rejected")
	check(await mode.apply_coupon("localtest"), "enter isolated local test")
	check(SCOPE.user_id.is_empty() and SCOPE.guest_directory == mode.test_directory, "test isolated namespace")
	check(PROGRESS.is_stage_unlocked(10) and PROGRESS.get_gold() == 99999 and PROGRESS.get_research_points() == 99999, "test funds/all stages")
	check(not root.get_node("CloudStore").ready_for_play, "test cannot upload")
	check(COLLECTION.get_unlocked_ids() == preload("res://src/data/monster_catalog.gd").ORDER, "localtest all catalog monsters unlocked")
	var legacy_test := COLLECTION.load_state()
	legacy_test.banshee = {"unlocked":false,"shards":7,"level":2}
	check(COLLECTION.save_state(legacy_test), "seed old locked localtest entry")
	var refreshed := COLLECTION.load_state()
	check(refreshed.banshee.unlocked and refreshed.banshee.shards == 7 and refreshed.banshee.level == 2, "old localtest unlock without shard or level inflation")
	var raw_test := ConfigFile.new()
	SCOPE.load_config(raw_test,COLLECTION.SAVE_PATH)
	check(not raw_test.get_value("monsters","banshee_unlocked",true), "read-only override does not rewrite save")
	mode.tutorial_preview = true
	check(not mode.has_all_monsters_unlocked() and not COLLECTION.is_unlocked("banshee"), "tutorial preview excluded")
	mode.tutorial_preview = false
	check(await mode.apply_coupon("normaltest"), "return normal/reset")
	check(not mode.active and PROGRESS.get_gold() == 0 and PROGRESS.get_research_points() == 0 and not PROGRESS.is_stage_unlocked(2), "normal values reset")
	check(COLLECTION.get_unlocked_ids() == ["slime","spider","orc"], "normal starter monsters")
	var grant := PROGRESS.add_research_points(141, 84)
	check(grant.success and grant.gold_granted == 84 and PROGRESS.get_gold() == 84, "research/gold same save")
	PROGRESS.complete_stage("stage_1",1,"stage_2",2,450)
	check(PROGRESS.get_gold() == 1084, "first clear adds separate gold")
	var progress := ConfigFile.new()
	SCOPE.load_config(progress, PROGRESS.SAVE_PATH)
	progress.set_value("meta", "gold", 100)
	SCOPE.save_config(progress, PROGRESS.SAVE_PATH)
	check(COLLECTION.award_shard_batch([{"monster_id":"slime","shards":1}],100).success and PROGRESS.get_gold() == 0, "normal gold spent atomically")
	check(not COLLECTION.award_shard_batch([{"monster_id":"slime","shards":1}],100).success and COLLECTION.get_shards("slime") == 1, "no funds grants nothing")
	lobby.free()
	# Revalidate the original account before a normaltest reset is uploaded.
	var old_cloud := root.get_node("CloudStore")
	root.remove_child(old_cloud)
	old_cloud.free()
	var cloud := FakeCloud.new()
	cloud.name = "CloudStore"
	root.add_child(cloud)
	var gateway := root.get_node("LoginGateway")
	gateway._cloud = cloud
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated normal account")
	mode.active = true
	check(not mode.has_all_monsters_unlocked() and not COLLECTION.is_unlocked("banshee"), "active flag cannot unlock normal account")
	mode.active = false
	var account_folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	check(SCOPE.install(cloud.payload,7), "seed normal account")
	cloud.ready_for_play = true
	gateway.user_id = id
	gateway.access_token = "fixture"
	check(await mode.apply_coupon("localtest"), "account enters localtest")
	check(cloud.uploads == 0 and cloud.payload["stage_progress.cfg"].meta.gold == 500, "test funds never reach cloud")
	check(await mode.apply_coupon("normaltest") and mode.pending_reset_id == id, "account reset awaits validated identity")
	await gateway._on_validated({"access_token":"fixture","expires_in":3600}, {"id":id})
	check(mode.pending_reset_id.is_empty() and cloud.uploads == 1, "validated reset uploaded once")
	check(cloud.payload["stage_progress.cfg"].meta.gold == 0 and cloud.payload["stage_progress.cfg"].progress.highest_unlocked_stage == 1, "cloud normal reset excludes test progress")
	check(PROGRESS.get_gold() == 0 and PROGRESS.get_research_points() == 0, "account normal reset persisted")
	for file in DirAccess.get_files_at(account_folder):
		DirAccess.remove_absolute(account_folder.path_join(file))
	DirAccess.remove_absolute(account_folder)
	for directory in [mode.test_directory, folder]:
		for file in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	SCOPE.guest_directory = "user://"
	SCOPE.select_guest()
	print("PROGRESSION_COUPON_FAILED" if failed else "PROGRESSION_COUPON_OK")
	quit(1 if failed else 0)
