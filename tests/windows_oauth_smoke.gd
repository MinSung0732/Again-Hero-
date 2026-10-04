extends SceneTree

const ADAPTER := preload("res://src/network/windows_oauth.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var noticed := false
var accepted := false

# Transport fixture only: never signs into a real account or stores credentials.
class FakeTransport extends ADAPTER:
	var valid_user := false
	var calls: Array[String] = []
	func request_json(path: String, _body: Variant = null, _token: String = "") -> Dictionary:
		calls.append(path)
		await get_tree().process_frame
		if path.begins_with("/token"):
			return {"access_token": "fixture-only"}
		return {"id": "00000000-0000-0000-0000-000000000001"} if valid_user else {}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("OAUTH_TEST: " + message)

func send_callback(target: String) -> String:
	var peer := StreamPeerTCP.new()
	check(peer.connect_to_host("127.0.0.1", ADAPTER.PORT) == OK, "Loopback connects")
	var deadline := Time.get_ticks_msec() + 3000
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() < deadline:
		peer.poll()
		await process_frame
	peer.put_data(("GET " + target + " HTTP/1.1\r\nHost: 127.0.0.1:43817\r\n\r\n").to_utf8_buffer())
	var reply := ""
	while reply.is_empty() and Time.get_ticks_msec() < deadline:
		peer.poll()
		if peer.get_available_bytes() > 0:
			var packet := peer.get_data(peer.get_available_bytes())
			reply = (packet[1] as PackedByteArray).get_string_from_utf8()
		await process_frame
	peer.disconnect_from_host()
	return reply

func _run() -> void:
	var oauth := ADAPTER.new()
	root.add_child(oauth)
	oauth.notice.connect(func(_message: String): noticed = true)
	oauth.validated.connect(func(_session: Dictionary, _user: Dictionary): accepted = true)
	check(oauth._server.listen(ADAPTER.PORT, "127.0.0.1") == OK, "Bind loopback only")
	oauth.busy = true
	oauth._nonce = "test-secret"
	oauth._deadline = Time.get_ticks_msec() + 30000
	oauth.set_process(true)
	var reply: String = await send_callback("/auth/callback/wrong?code=fake")
	check(reply.begins_with("HTTP/1.1 404") and oauth.busy, "Foreign nonce cannot consume login")
	reply = await send_callback("/auth/callback/test-secret?error=access_denied")
	check(reply.begins_with("HTTP/1.1 200"), "Browser gets completion response")
	check(not oauth.busy and noticed and not accepted, "Cancelled auth closes listener without authentication")
	check(not oauth.is_processing() and not oauth._server.is_listening(), "No idle socket polling")
	var fake := FakeTransport.new()
	root.add_child(fake)
	fake.validated.connect(func(_session: Dictionary, _user: Dictionary): accepted = true)
	await fake._exchange("fixture", fake._generation)
	check(not accepted and fake.calls == ["/token?grant_type=pkce", "/user"], "A token alone cannot authenticate")
	fake.valid_user = true
	await fake._exchange("fixture", fake._generation)
	check(accepted, "Only server-validated user emits success")
	accepted = false
	var generation: int = fake._generation
	fake._exchange("fixture", generation)
	fake.cancel()
	await process_frame
	await process_frame
	check(not accepted, "Cancelled in-flight exchange cannot authenticate later")
	check(not SCOPE.select_account("../../guest"), "Account path rejects traversal")
	SCOPE.user_id = "00000000-0000-0000-0000-000000000001"
	check(SCOPE.resolve("user://stage_progress.cfg").contains("/accounts/00000000-0000-0000-0000-000000000001/"), "Account saves are isolated")
	SCOPE.select_guest()
	check(SCOPE.resolve("user://stage_progress.cfg") == "user://stage_progress.cfg", "Legacy guest path preserved")
	print("WINDOWS_OAUTH_SMOKE_%s: real loopback HTTP, nonce rejection, cancellation, no fake auth, account isolation" % ("FAILED" if failed else "OK"))
	oauth.queue_free()
	fake.queue_free()
	await process_frame
	quit(1 if failed else 0)
