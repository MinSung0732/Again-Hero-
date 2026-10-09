extends SceneTree
const OAUTH := preload("res://src/network/windows_oauth.gd")
const LISTENER := preload("res://src/network/android_oauth_listener.gd")
var failed := false
var accepted := false

class FakeTransport extends OAUTH:
	var calls: Array[String] = []
	func request_json(path: String, _body: Variant = null, _token: String = "") -> Dictionary:
		calls.append(path)
		await get_tree().process_frame
		return {"access_token": "fixture-only"} if path.begins_with("/token") else {"id": "00000000-0000-0000-0000-000000000001"}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failed = true
		push_error("ANDROID_OAUTH: " + label)

func callback(target: String, host: String = "127.0.0.1:43817") -> String:
	var peer := StreamPeerTCP.new()
	check(peer.connect_to_host("127.0.0.1", OAUTH.PORT) == OK, "loopback connection")
	var deadline := Time.get_ticks_msec() + 2500
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() < deadline:
		peer.poll()
		await process_frame
	peer.put_data(("GET " + target + " HTTP/1.1\r\nHost: " + host + "\r\n\r\n").to_utf8_buffer())
	var reply := ""
	while reply.is_empty() and Time.get_ticks_msec() < deadline:
		peer.poll()
		if peer.get_available_bytes() > 0:
			var packet := peer.get_data(peer.get_available_bytes())
			reply = (packet[1] as PackedByteArray).get_string_from_utf8()
		await process_frame
	peer.disconnect_from_host()
	return reply

func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var oauth := FakeTransport.new()
	root.add_child(oauth)
	oauth.validated.connect(func(_session: Dictionary, _user: Dictionary): accepted = true)
	oauth.busy = true
	oauth._nonce = "mobile-fixture"
	oauth._verifier = "fixture-verifier"
	oauth._deadline = Time.get_ticks_msec() + 30000
	oauth._android_listener = LISTENER.new()
	check(oauth._android_listener.start(OAUTH.PORT, oauth._nonce, oauth._deadline) == OK, "receiver started before browser")
	# Emulate Android backgrounding: scene processing cannot answer the callback.
	oauth.set_process(false)
	var reply: String = await callback("/auth/callback/wrong?code=fixture")
	check(reply.begins_with("HTTP/1.1 404"), "foreign nonce rejected while scene paused")
	reply = await callback("/auth/callback/mobile-fixture?code=fixture", "untrusted.example")
	check(reply.begins_with("HTTP/1.1 404"), "foreign Host rejected")
	reply = await callback("/auth/callback/mobile-fixture?code=fixture")
	check(reply.begins_with("HTTP/1.1 200") and reply.contains("게임으로 돌아가기"), "browser receives app-return page while scene paused")
	check(reply.contains("againhero://resume") and not reply.contains("code=fixture"), "app return never leaks PKCE code")
	check(LISTENER._callback_page("com.example.againhero").contains("intent://resume#Intent;scheme=againhero;package=com.example.againhero;end"), "package-scoped app return")
	check(not accepted and oauth.calls.is_empty(), "worker does not mutate authentication")
	oauth.set_process(true)
	for i in range(10):
		await process_frame
	check(accepted and oauth.calls == ["/token?grant_type=pkce", "/user"], "resume exchanges PKCE and validates user on main thread")
	check(not oauth.busy and oauth._android_listener == null and not oauth.is_processing(), "receiver cleaned up after success")
	var listener := LISTENER.new()
	check(listener.start(OAUTH.PORT, "cancel", Time.get_ticks_msec() + 30000) == OK, "port reusable")
	var started := Time.get_ticks_msec()
	listener.cancel()
	check(Time.get_ticks_msec() - started < 250 and not listener.is_finished(), "cancellation promptly joins worker")
	check(listener.start(OAUTH.PORT, "timeout", Time.get_ticks_msec() + 60) == OK, "timeout fixture")
	await create_timer(0.12).timeout
	check(listener.is_finished() and listener.finish().get("timeout", false), "deadline ends worker")
	check(OAUTH.parse_query("/auth/callback/n?code=a&code=b").is_empty(), "duplicate codes rejected")
	var occupied := TCPServer.new()
	check(occupied.listen(OAUTH.PORT, "127.0.0.1") == OK, "port conflict fixture")
	check(listener.start(OAUTH.PORT, "occupied", Time.get_ticks_msec() + 1000) != OK, "port conflict fails before opening browser")
	occupied.stop()
	oauth.queue_free()
	await process_frame
	print("ANDROID_OAUTH_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
