extends Node

const CONFIG := preload("res://src/network/supabase_config.gd")
const PORT := 43817
const CALLBACK := "http://127.0.0.1:43817/auth/callback/"
const ANDROID_LISTENER := preload("res://src/network/android_oauth_listener.gd")
signal notice(message: String)
signal validated(session: Dictionary, user: Dictionary)

var _server := TCPServer.new()
var _peer: StreamPeerTCP
var _buffer := ""
var _peer_started := 0
var _nonce := ""
var _verifier := ""
var _deadline := 0
var busy := false
var _generation := 0
var _android_listener: RefCounted

func _ready() -> void:
	set_process(false)

static func base64_url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

static func authorize_url(provider: String, verifier: String, nonce: String) -> String:
	return CONFIG.PROJECT_URL + "/auth/v1/authorize?provider=" + provider.uri_encode() + "&redirect_to=" + (CALLBACK + nonce).uri_encode() + "&code_challenge=" + base64_url(verifier.sha256_buffer()) + "&code_challenge_method=s256"

func begin(provider: String) -> void:
	if busy:
		return
	if provider not in ["google", "kakao"] or OS.get_name() not in ["Windows", "Android"]:
		notice.emit("실제 계정 로그인은 Windows와 Android를 지원합니다.")
		return
	_generation += 1
	_verifier = base64_url(Crypto.new().generate_random_bytes(32))
	_nonce = Crypto.new().generate_random_bytes(24).hex_encode()
	_deadline = Time.get_ticks_msec() + 300000
	var error: Error
	if OS.get_name() == "Android":
		_android_listener = ANDROID_LISTENER.new()
		error = _android_listener.start(PORT, _nonce, _deadline, _android_package_name())
	else:
		error = _server.listen(PORT, "127.0.0.1")
	if error != OK:
		cancel()
		notice.emit("로그인 복귀 주소를 열지 못했습니다. 다른 게임 창을 닫고 다시 시도해 주세요.")
		return
	busy = true
	set_process(true)
	notice.emit("로그인을 완료하면 게임으로 자동 복귀합니다.\n전환이 차단되면 복귀 버튼을 눌러 주세요." if OS.get_name() == "Android" else "브라우저에서 로그인해 주세요. 완료 시 게임 창으로 전환합니다.")
	if OS.shell_open(authorize_url(provider, _verifier, _nonce)) != OK:
		_fail("브라우저를 열지 못했습니다. 다시 시도해 주세요.")

func _process(_delta: float) -> void:
	if _android_listener != null and _android_listener.is_finished():
		var response: Dictionary = _android_listener.finish()
		_android_listener = null
		set_process(false)
		if response.has("target"):
			_complete_callback(parse_query(String(response.target)))
		else:
			_fail("로그인 대기 시간이 지났습니다. 다시 시도해 주세요.")
		return
	if Time.get_ticks_msec() > _deadline:
		_fail("로그인 대기 시간이 지났습니다.\nSupabase의 로그인 복귀 주소 설정도 확인해 주세요.")
		return
	if _android_listener != null:
		return
	if _peer == null and _server.is_connection_available():
		_peer = _server.take_connection()
		_peer_started = Time.get_ticks_msec()
		_buffer = ""
	if _peer == null:
		return
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec() - _peer_started > 3000:
		_drop_peer()
		return
	var available := _peer.get_available_bytes()
	if available > 0:
		if available + _buffer.length() > 8192:
			_drop_peer()
			return
		var packet := _peer.get_data(available)
		if packet[0] != OK:
			_drop_peer()
			return
		_buffer += (packet[1] as PackedByteArray).get_string_from_utf8()
	if _buffer.length() > 8192:
		_drop_peer()
		return
	if not _buffer.contains("\r\n\r\n"):
		return
	var parts := _buffer.get_slice("\r\n", 0).split(" ")
	var target := String(parts[1]) if parts.size() == 3 and parts[0] == "GET" else ""
	if not _buffer.to_lower().contains("\r\nhost: 127.0.0.1:43817\r\n") or target.get_slice("?", 0) != "/auth/callback/" + _nonce:
		_reply("404 Not Found", "Not found")
		return
	var params := parse_query(target)
	_reply("200 OK", _windows_return_page(), true)
	_server.stop()
	set_process(false)
	_complete_callback(params)

func _complete_callback(params: Dictionary) -> void:
	if OS.get_name() == "Windows":
		_focus_windows_game()
	if params.has("error") or String(params.get("code", "")).is_empty():
		_fail("로그인이 취소되었거나 인증에 실패했습니다. 다시 시도해 주세요.")
		return
	_exchange(String(params.code), _generation)

static func parse_query(target: String) -> Dictionary:
	var params := {}
	for pair in target.get_slice("?", 1).split("&"):
		var key := pair.get_slice("=", 0).uri_decode()
		if params.has(key):
			return {}
		params[key] = pair.get_slice("=", 1).uri_decode()
	return params

func _exchange(code: String, generation: int) -> void:
	notice.emit("계정 인증을 확인하고 있습니다...")
	var session := await request_json("/token?grant_type=pkce", {"auth_code": code, "code_verifier": _verifier})
	if generation != _generation:
		return
	var token := String(session.get("access_token", ""))
	if token.is_empty():
		_fail("로그인 인증 교환에 실패했습니다. 네트워크와 서버 설정을 확인해 주세요.")
		return
	var user := await request_json("/user", null, token)
	if generation != _generation:
		return
	if String(user.get("id", "")).is_empty():
		_fail("서버에서 계정을 확인하지 못했습니다.")
		return
	cancel()
	validated.emit(session, user)

func request_json(path: String, body: Variant = null, token: String = "") -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 20.0
	request.body_size_limit = 1048576
	add_child(request)
	var headers := PackedStringArray(["apikey: " + CONFIG.PUBLISHABLE_KEY, "Content-Type: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var error := request.request(CONFIG.PROJECT_URL + "/auth/v1" + path, headers, HTTPClient.METHOD_GET if body == null else HTTPClient.METHOD_POST, "" if body == null else JSON.stringify(body))
	if error != OK:
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300:
		return {}
	var decoded: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	return decoded if decoded is Dictionary else {}

func _reply(status: String, body: String, html: bool = false) -> void:
	var content_type := "text/html" if html else "text/plain"
	_peer.put_data(("HTTP/1.1 " + status + "\r\nContent-Type: " + content_type + "; charset=utf-8\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\nContent-Length: %d\r\n\r\n" % body.to_utf8_buffer().size() + body).to_utf8_buffer())
	_drop_peer()


static func _windows_return_page() -> String:
	return """<!doctype html><html lang="ko"><head><meta charset="utf-8">
<title>용사, 또 너야?</title></head>
<body style="font-family:sans-serif;text-align:center;padding:3em">
<h2>로그인 응답 완료</h2><p>게임 창으로 복귀합니다.</p>
<p>이 탭이 남아 있으면 닫아도 됩니다.</p>
<script>window.close();</script>
</body></html>"""


func _android_package_name() -> String:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return ""
	var runtime := Engine.get_singleton("AndroidRuntime")
	var context: Variant = runtime.getApplicationContext()
	if context == null:
		return ""
	return String(context.getPackageName())


# Focus is requested only after the loopback callback has passed Host/nonce
# checks. This transports no code/token and does not change OAuth verification.
func _focus_windows_game() -> void:
	var command := "$w=New-Object -ComObject WScript.Shell;[void]$w.AppActivate(%d)" % OS.get_process_id()
	OS.create_process("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", command
	]), false)

func _drop_peer() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
	_peer = null
	_buffer = ""

func cancel() -> void:
	_generation += 1
	if _android_listener != null:
		_android_listener.cancel()
		_android_listener = null
	_server.stop()
	_drop_peer()
	set_process(false)
	busy = false
	_verifier = ""
	_nonce = ""

func _fail(message: String) -> void:
	cancel()
	notice.emit(message)

func _exit_tree() -> void:
	cancel()
