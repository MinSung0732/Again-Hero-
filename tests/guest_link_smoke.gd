extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const GUEST := preload("res://src/systems/guest_progress_store.gd")
var checks := 0
var failures := 0

class OAuth extends Node:
	var starts := 0
	func begin(_provider: String) -> void: starts += 1
	func cancel() -> void: pass

class Cloud extends "res://src/network/cloud_store.gd":
	var response: Dictionary = {"ok": false, "error": "already_registered"}
	var received: Dictionary
	var owner_during_request := ""
	var writes := 0
	func link_guest(_session: Dictionary, guest: Dictionary) -> Dictionary:
		received = guest.duplicate(true)
		owner_during_request = SCOPE.user_id
		await get_tree().process_frame
		return response.duplicate(true)
	func request_rpc(_method: String, _data: Dictionary) -> Dictionary:
		writes += 1
		return {}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func _initialize() -> void: call_deferred("run")

func uuid() -> String:
	var s := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [s.substr(0,8),s.substr(8,4),s.substr(12,4),s.substr(16,4),s.substr(20,12)]

func run() -> void:
	var gateway := root.get_node("LoginGateway")
	var mode := root.get_node("LocalTestMode")
	var old := root.get_node("CloudStore")
	old.stop(); root.remove_child(old); old.free()
	var cloud := Cloud.new()
	cloud.name = "CloudStore"
	root.add_child(cloud)
	gateway._cloud = cloud
	gateway._oauth.cancel(); gateway._oauth.free()
	gateway._oauth = OAuth.new(); gateway.add_child(gateway._oauth)
	gateway.remember_session_enabled = false
	gateway.user_id = ""; gateway.access_token = ""
	mode.active = false; mode.tutorial_preview = false; mode.original_user_id = ""; mode.pending_reset_id = ""
	var folder := "user://guest_link_test_" + uuid()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder; SCOPE.select_guest()
	check(GUEST.reset(), "fresh guest initialized")
	var id := GUEST.guest_id()
	check(not id.is_empty() and GUEST.guest_id() == id, "guest identity stable/cache")
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("player_profile", "value", {"nickname": "게스트", "gender": "female", "required": true, "completed": true})
	check(SCOPE.save_config(config, "user://stage_progress.cfg") == OK, "local profile saved")
	check(GUEST.tutorial_operation("read").status == "pending", "regular guest gets first tutorial")
	check(GUEST.tutorial_operation("skip").reward_claimed, "guest skip grants once")
	check(GUEST.tutorial_operation("skip").reward_claimed, "guest repeat skip is idempotent")
	var guest := GUEST.capture()
	check(guest.payload["stage_progress.cfg"].meta.gold == 1000, "tutorial reward never doubled")
	check(guest.payload["stage_progress.cfg"].guest_tutorial.claimed, "tutorial reward ledger captured")
	var baseline: Dictionary = guest.payload.duplicate(true)
	var account := uuid()
	var session := {"access_token": "fixture", "expires_in": 3600}
	var notices: Array = []
	gateway.guest_link_failed.connect(func(message: String): notices.append(message))
	gateway.begin_guest_link("google")
	check(gateway._oauth.starts == 1, "Google link starts OAuth")
	await gateway._on_validated(session, {"id": account})
	check(SCOPE.user_id.is_empty() and gateway.user_id.is_empty() and gateway.access_token.is_empty(), "registered target cannot switch guest identity")
	check(GUEST.capture().payload == baseline and not cloud.ready_for_play, "rejection preserves guest files")
	check(notices.back().contains("이미 가입된 계정"), "registered account notice")
	check(cloud.owner_during_request.is_empty() and cloud.writes == 0, "link checks target without normal cloud initialization")
	cloud.response = {}
	gateway.begin_guest_link("kakao")
	await gateway._on_validated(session, {"id": account})
	check(GUEST.capture().payload == baseline and not gateway.guest_link_busy, "network failure keeps guest retryable")
	check(notices.back().contains("진행도는 유지"), "failure guidance preserves progress")
	mode.active = true
	gateway.begin_guest_link("google")
	check(gateway._guest_link_intent.is_empty() and GUEST.capture().is_empty(), "test mode cannot migrate")
	mode.active = false; mode.tutorial_preview = true
	gateway.begin_guest_link("google")
	check(gateway._guest_link_intent.is_empty() and GUEST.capture().is_empty(), "preview cannot migrate")
	mode.tutorial_preview = false
	gateway.begin_guest_link("google")
	gateway.begin_login("google")
	check(gateway._guest_link_intent.is_empty(), "existing login is separate and cancels link intent")
	# A save made while the OAuth browser is open must be included.
	gateway.begin_guest_link("kakao")
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("meta", "gold", 1234)
	SCOPE.save_config(config, "user://stage_progress.cfg")
	var uploaded: Dictionary = GUEST.capture().payload
	var sanitized: Dictionary = uploaded.duplicate(true)
	sanitized["stage_progress.cfg"].erase("guest_identity")
	sanitized["stage_progress.cfg"].erase("guest_tutorial")
	cloud.response = {"ok": true, "revision": 1, "payload": sanitized}
	await gateway._on_validated(session, {"id": account})
	check(cloud.received.payload["stage_progress.cfg"].meta.gold == 1234, "latest guest saves transferred")
	check(SCOPE.user_id == account and gateway.user_id == account and cloud.ready_for_play, "accepted target adopted only after acknowledgement")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 1234 and not SCOPE.dirty, "server acknowledgement stored without extra upload")
	check(not gateway.reset_guest_progress(), "reset button never resets account")
	await gateway.begin_local_guest(true)
	check(SCOPE.user_id.is_empty() and GUEST.guest_id() != id, "consumed guest gets a new identity")
	check(GUEST.capture().payload["stage_progress.cfg"].meta.gold == 0, "transferred guest cannot duplicate its wallet")
	var reroll_id := GUEST.guest_id()
	check(gateway.reset_guest_progress() and GUEST.guest_id() != reroll_id, "reroll reset creates another guest")
	check(not SCOPE.files.has("stage_progress.cfg"), "guest reset does not import account bundle")
	# Cancellation during the RPC cannot install a late result.
	gateway.begin_guest_link("google")
	gateway._on_validated(session, {"id": account})
	await gateway.begin_local_guest(true)
	for i in range(3): await process_frame
	check(SCOPE.user_id.is_empty() and gateway.user_id.is_empty(), "late link acknowledgement cannot switch guest")
	check(not gateway.guest_link_busy, "cancellation releases busy state")
	cloud.stop()
	var account_dir := "user://accounts/" + account
	for file in DirAccess.get_files_at(account_dir): DirAccess.remove_absolute(account_dir.path_join(file))
	DirAccess.remove_absolute(account_dir)
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"; SCOPE.select_guest()
	print("guest_link_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
