extends RefCounted

# Android may suspend scene processing while the external browser is foreground.
# Only this bounded loopback receiver runs on a worker; it never touches Nodes,
# HTTPRequest, tokens, account state or the scene tree. Main-thread code joins it
# on return and then performs the existing PKCE/user validation.
var _thread: Thread
var _stop_mutex := Mutex.new()
var _stop_requested := false

func start(port: int, nonce: String, deadline: int) -> Error:
	var server := TCPServer.new()
	var error := server.listen(port, "127.0.0.1")
	if error != OK:
		return error
	_stop_requested = false
	_thread = Thread.new()
	error = _thread.start(_receive.bind(server, port, nonce, deadline))
	if error != OK:
		server.stop()
		_thread = null
	return error

func is_finished() -> bool:
	return _thread != null and not _thread.is_alive()

func finish() -> Dictionary:
	var result: Dictionary = _thread.wait_to_finish()
	_thread = null
	return result

func cancel() -> void:
	_stop_mutex.lock()
	_stop_requested = true
	_stop_mutex.unlock()
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

func _stopping() -> bool:
	_stop_mutex.lock()
	var stop := _stop_requested
	_stop_mutex.unlock()
	return stop

func _receive(server: TCPServer, port: int, nonce: String, deadline: int) -> Dictionary:
	var peer: StreamPeerTCP
	var buffer := ""
	var peer_started := 0
	var result := {"timeout": true}
	while not _stopping() and Time.get_ticks_msec() <= deadline:
		if peer == null and server.is_connection_available():
			peer = server.take_connection()
			peer_started = Time.get_ticks_msec()
			buffer = ""
		if peer != null:
			peer.poll()
			var drop := peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec() - peer_started > 3000
			var available := peer.get_available_bytes() if not drop else 0
			if available + buffer.length() > 8192:
				drop = true
			elif available > 0:
				var packet := peer.get_data(available)
				if packet[0] != OK:
					drop = true
				else:
					buffer += (packet[1] as PackedByteArray).get_string_from_utf8()
			if not drop and buffer.contains("\r\n\r\n"):
				var parts := buffer.get_slice("\r\n", 0).split(" ")
				var target := String(parts[1]) if parts.size() == 3 and parts[0] == "GET" else ""
				var valid := buffer.to_lower().contains("\r\nhost: 127.0.0.1:%d\r\n" % port) and target.get_slice("?", 0) == "/auth/callback/" + nonce
				var body := "인증 응답을 받았습니다. Godot 또는 게임 앱으로 돌아가 주세요. 이 창은 닫아도 됩니다." if valid else "Not found"
				var status := "200 OK" if valid else "404 Not Found"
				peer.put_data(("HTTP/1.1 " + status + "\r\nContent-Type: text/plain; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: %d\r\n\r\n" % body.to_utf8_buffer().size() + body).to_utf8_buffer())
				if valid:
					result = {"target": target}
					break
				drop = true
			if drop:
				peer.disconnect_from_host()
				peer = null
				buffer = ""
		OS.delay_msec(20)
	if peer != null:
		peer.disconnect_from_host()
	server.stop()
	return result
