extends SceneTree
var checks := 0
var failures := 0
class OAuth extends Node:
	signal notice(message: String)
	signal validated(session: Dictionary, user: Dictionary)
	var last_http_status := 0
	var response: Dictionary = {}
	var calls := 0
	func cancel() -> void: pass
	func request_json(_path: String, _body: Variant = null, _token: String = "") -> Dictionary:
		calls += 1
		await get_tree().process_frame
		return response.duplicate(true)
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var cloud := root.get_node("CloudStore")
	var gateway := root.get_node("LoginGateway")
	cloud.stop()
	gateway.remember_session_enabled = false
	gateway._refresh_timer.stop()
	gateway._oauth.cancel()
	gateway._oauth.free()
	var oauth := OAuth.new()
	gateway._oauth = oauth
	gateway.add_child(oauth)
	gateway._set_session({"access_token":"fixture-expired","refresh_token":"fixture-recoverable","expires_in":-10})
	check(not await gateway.refresh_session(), "offline refresh fails safely")
	check(gateway._refresh_token == "fixture-recoverable" and gateway.access_token == "fixture-expired", "offline expiration retains recoverable credential")
	check(cloud.connection_blocked and not cloud.terminal, "offline uses reconnect mode")
	oauth.response = {"access_token":"fixture-new","refresh_token":"fixture-rotated","expires_in":3600}
	check(await gateway.refresh_session(), "refresh recovers without browser login")
	check(gateway.access_token == "fixture-new" and gateway._refresh_token == "fixture-rotated", "rotated credential installed")
	oauth.response = {}
	oauth.last_http_status = 400
	check(not await gateway.refresh_session() and cloud.terminal, "invalid refresh requires explicit login")
	cloud._retry_later()
	cloud._set_connection(false)
	check(cloud.terminal and cloud.connection_blocked, "late successful check cannot release terminal state")
	cloud.stop()
	gateway.access_token = ""
	gateway._refresh_token = ""
	print("CLOUD_AUTH_RECOVERY checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
