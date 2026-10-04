extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const VAULT := preload("res://src/network/session_vault.gd")
var failed := false

class FakeVault extends Node:
	var cached := {"user_id": "00000000-0000-4000-8000-000000000099", "refresh_token": "fixture-old"}
	func read_session() -> Dictionary:
		await get_tree().process_frame
		return cached.duplicate()
	func save_session(id: String, token: String) -> bool:
		cached = {"user_id": id, "refresh_token": token}
		await get_tree().process_frame
		return true

class FakeAuth extends Node:
	var correct_user := true
	func request_json(path: String, _data: Variant = null, _token: String = "") -> Dictionary:
		await get_tree().process_frame
		if path.begins_with("/token"):
			return {"access_token": "fixture-access", "refresh_token": "fixture-new"}
		return {"id": "00000000-0000-4000-8000-000000000099"} if correct_user else {"id": "wrong-user"}

class FakeGateway extends "res://src/network/login_gateway.gd":
	var accepted := false
	func _on_validated(_session: Dictionary, _user: Dictionary) -> void:
		accepted = true

class FakeCloud extends "res://src/network/cloud_store.gd":
	var server := {"found": false, "revision": 0}
	var unavailable := false
	func request_rpc(method: String, data: Dictionary) -> Dictionary:
		await get_tree().process_frame
		if unavailable:
			return {}
		if method == "read_game_save":
			return server.duplicate(true)
		if data.expected_revision != server.revision:
			return {"conflict": true}
		server = {"found": true, "revision": int(server.revision) + 1, "payload": data.new_payload.duplicate(true)}
		return {"ok": true, "revision": server.revision}

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CLOUD_TEST: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated UUID")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var cloud := FakeCloud.new()
	root.add_child(cloud)
	var config := ConfigFile.new()
	config.set_value("meta", "research_points", 321)
	for name in SCOPE.FILES:
		check(SCOPE.save_config(config, "user://" + name) == OK, "atomic bundle save " + name)
	check(SCOPE.select_account(id) and SCOPE.files.size() == 5 and SCOPE.dirty, "restart pending recovery")
	check(await cloud.initialize(), "first cloud upload")
	check(SCOPE.revision == 1 and not SCOPE.dirty, "upload acknowledgement")
	config.set_value("meta", "research_points", 999)
	SCOPE.save_config(config, "user://stage_progress.cfg")
	cloud.unavailable = true
	check(not await cloud.flush() and SCOPE.dirty, "offline progress retained")
	cloud.unavailable = false
	cloud.server.revision = 2
	check(not await cloud.flush() and cloud.conflict, "stale version blocked")
	check(await cloud.initialize("remote"), "explicit remote resolution")
	check(SCOPE.files["stage_progress.cfg"].meta.research_points == 321, "remote installed")
	check(FileAccess.file_exists(folder.path_join("save_bundle.json.before_cloud.bak")), "local backup preserved")
	check(not SCOPE.install({"unknown.cfg": {}}, 9), "invalid payload rejected")
	var vault := VAULT.new()
	vault.PATH = "user://cloud_test_" + hex + ".dpapi"
	root.add_child(vault)
	check(await vault.save_session(id, "fixture-refresh-1"), "DPAPI encryption")
	print("VAULT_DIAGNOSTIC: " + vault.diagnostic)
	var session: Dictionary = await vault.read_session()
	check(session.get("refresh_token") == "fixture-refresh-1", "DPAPI recovery")
	check(not FileAccess.get_file_as_bytes(vault.PATH).get_string_from_ascii().contains("fixture-refresh-1"), "no plaintext credential")
	check(await vault.save_session(id, "fixture-refresh-2"), "refresh token rotation")
	session = await vault.read_session()
	check(session.get("refresh_token") == "fixture-refresh-2", "latest credential recovery")
	await vault.clear_session()
	check(not FileAccess.file_exists(vault.PATH), "logout removes credential")
	var gateway := FakeGateway.new()
	root.add_child(gateway)
	gateway._oauth.queue_free()
	gateway._vault.queue_free()
	gateway._oauth = FakeAuth.new()
	gateway._vault = FakeVault.new()
	gateway.add_child(gateway._oauth)
	gateway.add_child(gateway._vault)
	await gateway.try_auto_login()
	check(gateway.accepted and gateway._vault.cached.refresh_token == "fixture-new", "automatic login verifies identity and rotates credential")
	gateway.accepted = false
	gateway._oauth.correct_user = false
	await gateway.try_auto_login()
	check(not gateway.accepted, "automatic login rejects a mismatched account")
	gateway.queue_free()
	cloud.stop()
	for name in ["save_bundle.json", "save_bundle.json.tmp", "save_bundle.json.before_cloud.bak"]:
		if FileAccess.file_exists(folder.path_join(name)):
			DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	SCOPE.select_guest()
	cloud.queue_free()
	vault.queue_free()
	await process_frame
	print("CLOUD_SAVE_SMOKE_OK" if not failed else "CLOUD_SAVE_SMOKE_FAILED")
	quit(1 if failed else 0)
