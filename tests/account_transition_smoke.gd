extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
var failures := 0

class Cloud extends "res://src/network/cloud_store.gd":
	var accounts: Dictionary = {}
	var calls: Array = []
	var choices: Array = []
	var uploads := 0
	func initialize(choice: String = "") -> bool:
		choices.append(choice)
		return await super.initialize(choice)
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		var id := SCOPE.user_id
		calls.append(method)
		await get_tree().process_frame
		if method == "account_lifecycle_status": return {"active": true}
		if method == "read_game_save": return accounts.get(id, {"found": false, "revision": 0}).duplicate(true)
		if method == "save_game_snapshot":
			var remote: Dictionary = accounts.get(id, {"revision": 0})
			if remote.revision != data.expected_revision: return {"conflict": true}
			accounts[id] = {"found": true, "revision": int(remote.revision) + 1, "payload": data.new_payload.duplicate(true)}
			uploads += 1
			return {"ok": true, "revision": accounts[id].revision}
		return {}

class OAuth extends Node:
	var starts := 0
	func begin(_provider: String) -> void: starts += 1
	func cancel() -> void: pass

class Vault extends Node:
	var saved_id := ""
	func clear_session() -> bool:
		for i in range(6): await get_tree().process_frame
		saved_id = ""
		return true
	func save_session(_id: String, _token: String) -> bool:
		await get_tree().process_frame
		saved_id = _id
		return true

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func uuid() -> String:
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]

func payload(gold: int, stage: int) -> Dictionary:
	return {"stage_progress.cfg": {"meta": {"gold": gold, "research_points": 17}, "progress": {"highest_unlocked_stage": stage, "current_stage_id": "stage_1"}}}

func gold() -> int:
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	return int(config.get_value("meta", "gold", 0))

func login(gateway: Node, id: String) -> void:
	await gateway._on_validated({"access_token": "fixture", "refresh_token": "fixture", "expires_in": 3600}, {"id": id})

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var gateway := root.get_node("LoginGateway")
	var mode := root.get_node("LocalTestMode")
	var old_cloud := root.get_node("CloudStore")
	old_cloud.stop()
	root.remove_child(old_cloud)
	old_cloud.free()
	var cloud := Cloud.new()
	cloud.name = "CloudStore"
	root.add_child(cloud)
	gateway._cloud = cloud
	gateway.remember_session_enabled = false
	gateway._oauth.cancel()
	gateway._oauth.free()
	gateway._vault.free()
	gateway._oauth = OAuth.new()
	gateway._vault = Vault.new()
	gateway.add_child(gateway._oauth)
	gateway.add_child(gateway._vault)
	var id_a := uuid()
	var id_b := uuid()
	var folder := "user://account_transition_" + uuid()
	var normal := folder.path_join("normal")
	DirAccess.make_dir_recursive_absolute(normal)
	mode.marker_path = folder.path_join("mode.cfg")
	mode.test_directory = folder.path_join("test")
	mode.active = false
	mode.tutorial_preview = false
	mode.original_user_id = ""
	mode.pending_reset_id = ""
	SCOPE.guest_directory = normal
	SCOPE.select_guest()
	check(mode.reset_progress(), "isolated guest initialization")
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("meta", "gold", 53)
	check(SCOPE.save_config(config, "user://stage_progress.cfg") == OK, "guest seed")
	cloud.accounts[id_a] = {"found": true, "revision": 11, "payload": payload(700, 5)}
	cloud.accounts[id_b] = {"found": true, "revision": 4, "payload": payload(80, 2)}
	await login(gateway, id_a)
	check(SCOPE.user_id == id_a and gold() == 700 and cloud.ready_for_play, "account A server data installed")
	check(await mode.apply_coupon("localtest"), "enter local test")
	check(mode.active and SCOPE.user_id.is_empty() and gold() == 99999, "test namespace/funds")
	var calls := cloud.calls.size()
	check(not await cloud.initialize() and not await cloud.flush(), "cloud denied during test")
	check(cloud.calls.size() == calls and cloud.uploads == 0, "test never reaches transport")
	check(await mode.apply_coupon("normaltest"), "normaltest exits safely")
	check(not mode.active and gold() == 53 and mode.pending_reset_id.is_empty(), "normal guest preserved, no pending reset")
	await login(gateway, id_a)
	check(gold() == 700 and cloud.uploads == 0, "account A preserved on return")
	check(await mode.apply_coupon("localtest"), "second local test")
	gateway.begin_login("google")
	check(not mode.active and SCOPE.guest_directory == normal and gateway._oauth.starts == 1, "explicit OAuth leaves test before browser")
	await login(gateway, id_a)
	check(gold() == 700 and not mode.active, "Google login has real account state")
	mode.pending_reset_id = id_a
	mode.original_user_id = id_a
	check(mode.persist(), "seed legacy reset marker")
	await gateway.retry_cloud()
	check(mode.pending_reset_id.is_empty() and mode.original_user_id.is_empty(), "legacy reset retired")
	check(gold() == 700 and cloud.uploads == 0 and cloud.choices.back() == "", "legacy marker cannot force local overwrite")
	await login(gateway, id_b)
	check(SCOPE.user_id == id_b and gold() == 80, "account B independent")
	await gateway.begin_local_guest()
	check(SCOPE.user_id.is_empty() and gold() == 53 and not mode.active, "guest independent of account B")
	await login(gateway, id_a)
	check(gold() == 700, "return A after guest preserves cloud")
	check(not await mode.apply_coupon("normaltest") and gold() == 700, "normaltest cannot reset normal account")
	gateway.user_id = id_b
	calls = cloud.calls.size()
	check(not await cloud.initialize() and not await cloud.flush(), "owner mismatch denied")
	check(cloud.calls.size() == calls, "owner mismatch never reaches transport")
	gateway.user_id = id_a
	gateway.remember_session_enabled = true
	var guest_events := [0]
	gateway.local_guest_started.connect(func(): guest_events[0] += 1)
	gateway.begin_local_guest() # Vault deletion intentionally stays pending.
	check(gateway.user_id.is_empty() and SCOPE.user_id.is_empty(), "guest clears identity before async vault")
	await login(gateway, id_b)
	for i in range(8): await process_frame
	check(gateway.user_id == id_b and SCOPE.user_id == id_b and gold() == 80, "late guest completion cannot erase new login")
	check(guest_events[0] == 0, "late guest completion cannot enter guest lobby")
	check(gateway._vault.saved_id == id_b, "late credential clear cannot delete new account session")
	gateway.remember_session_enabled = false
	check(await mode.apply_coupon("localtest"), "test marker failure setup")
	var marker: String = mode.marker_path
	mode.marker_path = folder.path_join("missing/marker.cfg")
	check(not mode.exit_local_test() and mode.active and gold() == 99999, "marker failure restores test mode/namespace")
	await login(gateway, id_a)
	check(SCOPE.user_id.is_empty() and gateway.user_id.is_empty(), "marker failure denies account acceptance")
	mode.marker_path = marker
	check(mode.exit_local_test(), "recover marker")
	mode.tutorial_preview = true
	await login(gateway, id_a)
	check(SCOPE.user_id.is_empty() and not cloud.ready_for_play, "tutorial preview callback isolated")
	mode.tutorial_preview = false
	await login(gateway, id_a)
	cloud.initialize() # Delayed old-account response.
	await gateway.begin_local_guest()
	for i in range(6): await process_frame
	check(SCOPE.user_id.is_empty() and gold() == 53 and not cloud.ready_for_play, "old cloud response cannot install into guest")
	check(cloud.accounts[id_a].payload == payload(700, 5) and cloud.accounts[id_b].payload == payload(80, 2), "both server snapshots unchanged")
	cloud.stop()
	for id in [id_a, id_b]:
		var dir: String = "user://accounts/" + id
		for file in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(file))
		DirAccess.remove_absolute(dir)
	for dir in [mode.test_directory, normal, folder]:
		for file in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(file))
		DirAccess.remove_absolute(dir)
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://"
	print("account_transition_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
