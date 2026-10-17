extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
var checks := 0
var failures := 0
class Cloud extends "res://src/network/cloud_store.gd":
	var calls: Array[String] = []
	var fail_once := true
	func _request_with_token(method: String, _data: Dictionary, _token: String) -> Dictionary:
		calls.append(method)
		await get_tree().process_frame
		if fail_once:
			fail_once = false
			_last_http_status = 0
			return {}
		_last_http_status = 200
		if method == "cloud_sync": return {"ok":true,"revision":2}
		return {"ok":true,"profile":{"nickname":"별군주","gender":"male","required":true,"completed":false}}
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var id: String = root.get_node("CloudStore").new_operation_id()
	check(SCOPE.select_account(id),"isolated account")
	SCOPE.install({"stage_progress.cfg":{"meta":{"gold":17}}},1)
	var gateway := root.get_node("LoginGateway")
	gateway.user_id = id
	gateway.access_token = "fixture"
	var cloud := Cloud.new()
	root.add_child(cloud)
	cloud.ready_for_play = true
	cloud._initialized = true
	var result := await PROFILE.refresh(cloud)
	check(result.get("ok") == true and cloud.calls.count("read_player_profile") == 2,"profile automatically retries transient loss")
	check(PROFILE.get_profile().nickname == "별군주" and SCOPE.dirty,"profile cache can save after RPC releases ownership")
	check(cloud.connection_blocked and not cloud.busy and cloud._rpc_waiters == 0,"profile local change remains fenced until snapshot ack")
	check(await cloud.flush() and not cloud.connection_blocked and not SCOPE.dirty,"profile snapshot acknowledgement releases modal")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 17,"profile recovery preserves wallet")
	cloud.stop()
	cloud.queue_free()
	gateway.user_id = ""
	gateway.access_token = ""
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	await process_frame
	print("CLOUD_PROFILE_RETRY checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
