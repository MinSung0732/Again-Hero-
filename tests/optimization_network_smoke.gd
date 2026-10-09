extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var flush_results: Array = []
var replies: Array = []

class FixtureCloud extends "res://src/network/cloud_store.gd":
	signal release_request
	var held := true
	var calls := 0
	var answer := {"ok": true, "revision": 1}
	func request_rpc(_method: String, _data: Dictionary) -> Dictionary:
		calls += 1
		if held:
			await release_request
		return answer.duplicate(true)


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("OPT_NETWORK: " + message)


func capture_flush(cloud: Node) -> void:
	flush_results.append(await cloud.flush())


func wait_frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8), hex.substr(8,4), hex.substr(12,4), hex.substr(16,4), hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var cloud := FixtureCloud.new()
	root.add_child(cloud)
	cloud.ready_for_play = true
	SCOPE.dirty = true
	capture_flush(cloud)
	capture_flush(cloud)
	await wait_frames()
	check(cloud.calls == 1 and flush_results.is_empty(), "concurrent flush waits without issuing another RPC")
	cloud.release_request.emit()
	await wait_frames()
	check(flush_results == [true, true] and cloud.calls == 1 and SCOPE.revision == 1 and not SCOPE.dirty, "deferred wake sees applied acknowledgement")
	flush_results.clear()
	SCOPE.dirty = true
	cloud.answer = {"ok": true, "revision": 2}
	capture_flush(cloud)
	capture_flush(cloud)
	cloud.stop()
	await wait_frames()
	check(flush_results == [false], "stop cancels the old-session queued waiter immediately")
	cloud.release_request.emit()
	await wait_frames()
	check(flush_results == [false, false] and SCOPE.revision == 1 and SCOPE.dirty, "late in-flight response cannot acknowledge a stopped session")
	cloud.ready_for_play = true
	cloud.held = false
	for answer in [{"ok": true}, {"ok": true, "revision": -1}, {"ok": true, "revision": 1.5}, {"ok": true, "revision": "2"}]:
		cloud.answer = answer
		check(not await cloud.flush() and SCOPE.dirty and SCOPE.revision == 1, "malformed acknowledgement preserves pending local data")
	cloud.answer = {"found": false, "revision": -1}
	check(not await cloud.initialize(), "bad read revision rejected")
	cloud.answer = {"found": "yes", "revision": 1}
	check(not await cloud.initialize(), "bad read shape rejected")
	check(cloud._valid_revision(2.0) and not cloud._valid_revision(INF) and not cloud._valid_revision(null), "JSON integer-compatible revision rules")
	cloud.stop()
	cloud.queue_free()
	var client = load("res://src/network/supabase_client.gd").new()
	root.add_child(client)
	client.request_completed.connect(func(tag: String, status: int, payload: Variant): replies.append([tag, status, payload]))
	client.set_access_token("fixture-session-a")
	var old_generation: int = client._session_generation
	client.clear_session()
	var request := HTTPRequest.new()
	client.add_child(request)
	client._on_http_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), '{"value":1}'.to_utf8_buffer(), request, "old", old_generation)
	check(replies.is_empty() and request.is_queued_for_deletion(), "stale session reply discarded/request freed")
	request = HTTPRequest.new()
	client.add_child(request)
	client._on_http_request_completed(HTTPRequest.RESULT_TIMEOUT, 200, PackedStringArray(), PackedByteArray(), request, "timeout", client._session_generation)
	check(replies == [["timeout", 0, null]], "transport failure cannot masquerade as HTTP success")
	request = HTTPRequest.new()
	client.add_child(request)
	client._on_http_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), '{"value":2}'.to_utf8_buffer(), request, "okay", client._session_generation)
	check(replies.back()[0] == "okay" and replies.back()[1] == 200 and int(replies.back()[2].get("value", 0)) == 2, "valid JSON success contract preserved")
	request = HTTPRequest.new()
	client.add_child(request)
	client._on_http_request_completed(HTTPRequest.RESULT_SUCCESS, 500, PackedStringArray(), 'not-json'.to_utf8_buffer(), request, "error", client._session_generation)
	check(replies.back() == ["error", 500, "not-json"], "malformed HTTP body remains fail-soft")
	client.queue_free()
	await wait_frames()
	for name in ["save_bundle.json", "save_bundle.json.tmp", "save_bundle.json.before_cloud.bak"]:
		if FileAccess.file_exists(folder.path_join(name)):
			DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	SCOPE.select_guest()
	print("OPTIMIZATION_NETWORK: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
