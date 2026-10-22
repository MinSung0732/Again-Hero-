extends Node
const RULES := preload("res://src/online/match_rules.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
const DRAIN := preload("res://src/online/socket_drain.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
signal event_received(event: Dictionary)
signal connection_closed(message: String)
signal connection_recovering(active: bool, remaining: float)
var metrics = preload("res://src/online/network_metrics.gd").new()
var socket: WebSocketPeer
var token := ""
var local_ticket := ""
var local_session := ""
var role := "hero"
var loadout := {}
var sequence := 0
var match_id := ""
var greeted := false
var last_message := 0
var endpoint_url := ""
var resume_token := ""
var reconnecting := false
var reconnect_deadline := 0
var next_retry := 0
var heartbeat_left := 0.0
var result_received := false
var local_test_connection := false
var test_transport_paused := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not match_id.is_empty() and not resume_token.is_empty() and not result_received:
		_network_lost("백그라운드에서 돌아오면 경기에 다시 연결합니다.")
func join(endpoint: String,access_token: String,requested_role: String,requested_loadout: Dictionary = {}) -> Error:
	close(); metrics.enabled=false; metrics.reset(); token = access_token; role = requested_role
	if requested_loadout.is_empty():
		requested_loadout = {"hero_id":preload("res://src/data/hero_character_catalog.gd").DEFAULT_HERO} if role == "hero" else preload("res://src/online/online_loadout.gd").default_demon()
	if not RULES.endpoint_valid(endpoint) or requested_role not in ["hero","demon"] or not preload("res://src/online/online_loadout.gd").valid(role,requested_loadout): token = ""; return ERR_INVALID_PARAMETER
	loadout = requested_loadout.duplicate(true)
	endpoint_url = endpoint
	var error := _connect_transport()
	if error != OK: _reset_transport(); return error
	set_process(true); return OK
func _connect_transport() -> Error:
	socket = WebSocketPeer.new(); socket.inbound_buffer_size = 262144; socket.outbound_buffer_size = 65536
	metrics.transport_reset()
	greeted = false; heartbeat_left = 0.0; last_message = Time.get_ticks_msec()
	return socket.connect_to_url(endpoint_url)
func join_local_test(endpoint: String,invitation: String,requested_role: String,requested_loadout: Dictionary = {}) -> Error:
	if not LOCAL_ACCESS.valid_hex(invitation,LOCAL_ACCESS.TICKET_BYTES): close(); return ERR_INVALID_PARAMETER
	var error := join(endpoint,"",requested_role,requested_loadout)
	if error == OK:
		metrics.enabled=true
		local_test_connection = true
		local_ticket = invitation
		if local_session.is_empty(): local_session = LOCAL_ACCESS.new_session()
	return error
func set_local_test_disconnected(disconnected: bool) -> bool:
	# Exercise real socket loss without sending leave or changing server deadlines.
	var local_mode = get_node_or_null("/root/LocalTestMode") if is_inside_tree() else null
	if local_mode == null or not local_mode.is_online_match_allowed() or not local_test_connection or match_id.is_empty() or resume_token.is_empty() or result_received: return false
	if disconnected:
		if reconnecting or socket == null or socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return false
		test_transport_paused = true
		_network_lost("로컬 테스트 연결을 끊었습니다.")
	else:
		if not test_transport_paused or not reconnecting: return false
		test_transport_paused = false
		next_retry = Time.get_ticks_msec()
		connection_recovering.emit(true,maxf(0.0,float(reconnect_deadline-next_retry)/1000.0))
	return true
func _reset_transport() -> void:
	if socket != null: socket.close()
	metrics.transport_reset()
	socket = null; token = ""; local_ticket = ""; greeted = false
func close() -> void:
	# Intentional lobby exit/cancel is a forfeit; transport failures use recovery.
	if not match_id.is_empty() and not result_received and send({"op":"leave","match":match_id}) and is_inside_tree():
		var drain := DRAIN.new(); drain.socket = socket
		get_tree().root.add_child(drain); socket = null
	_reset_transport()
	match_id = ""; resume_token = ""; endpoint_url = ""; sequence = 0; result_received = false
	local_test_connection = false; test_transport_paused = false
	reconnecting = false; reconnect_deadline = 0; next_retry = 0; set_process(false)
func send(data: Dictionary) -> bool:
	if socket == null or socket.get_ready_state()!=WebSocketPeer.STATE_OPEN: return false
	var encoded := JSON.stringify(data)
	var sent := socket.send_text(encoded)==OK
	if sent and metrics.enabled:
		metrics.send_bytes(encoded.to_utf8_buffer().size())
		if data.get("op","")=="ready": metrics.transport_reset()
	return sent
func command(kind: String,argument: Variant) -> bool:
	if match_id.is_empty() or reconnecting or result_received or socket == null or socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return false
	sequence += 1
	var sent := send({"op":"input","match":match_id,"seq":sequence,"kind":kind,"argument":argument})
	if sent: metrics.input_sent(sequence)
	return sent
func _network_lost(message: String) -> void:
	_reset_transport()
	if resume_token.is_empty() or match_id.is_empty() or result_received:
		close(); connection_closed.emit(message); return
	var now := Time.get_ticks_msec()
	if not reconnecting:
		reconnecting = true; reconnect_deadline = now + int(RULES.RECONNECT_WINDOW * 1000.0)
	next_retry = now + int(RULES.RECONNECT_RETRY * 1000.0)
	connection_recovering.emit(true,maxf(0.0,float(reconnect_deadline-now)/1000.0))
func _process(delta: float) -> void:
	metrics.tick_rates()
	var now := Time.get_ticks_msec()
	if reconnecting and now >= reconnect_deadline:
		close(); connection_closed.emit("연결을 복구하지 못했습니다. 로비로 돌아가 주세요."); return
	if socket == null:
		if reconnecting and not test_transport_paused and now >= next_retry:
			if _connect_transport() != OK: _network_lost("서버에 연결할 수 없습니다.")
		return
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not greeted:
		greeted = true
		var request := {"op":"join","version":RULES.VERSION,"rules":RULES.ID,"role":role,"token":token,"loadout":loadout}
		if reconnecting:
			request = {"op":"resume","version":RULES.VERSION,"rules":RULES.ID,"match":match_id,"resume_token":resume_token}
		elif not local_ticket.is_empty(): request["local_test"] = {"ticket":local_ticket,"session":local_session}
		send(request); token = ""; local_ticket = ""
	# Drain authoritative results/errors before responding to a close frame.
	var budget := 8
	while socket != null and socket.get_available_packet_count() > 0 and budget > 0:
		budget -= 1
		var packet := socket.get_packet()
		metrics.receive_bytes(packet.size())
		var event := RULES.decode(packet,RULES.MAX_SNAPSHOT)
		if event.is_empty(): continue
		last_message = Time.get_ticks_msec()
		var op: String = String(event.get("op",""))
		if op == "error" and event.get("reason","") == "resume_busy" and reconnecting:
			_network_lost("기존 연결의 종료를 확인하고 있습니다."); return
		if op == "matched":
			if not event.get("match",null) is String or event.get("rules","") != RULES.ID or event.get("role","") != role or not RULES.resume_token_valid(event.get("resume_token",null)): continue
			if reconnecting and event.match != match_id: continue
			match_id = event.match; resume_token = event.resume_token; sequence = 0
			if reconnecting:
				reconnecting = false; reconnect_deadline = 0; connection_recovering.emit(false,0.0)
		if op == "connection" and event.get("match","")==match_id and event.get("paused",false)==true: metrics.transport_reset()
		if op == "pong": metrics.pong(event)
		if op == "state":
			if event.get("match","") != match_id or not CODEC.expand(event): continue
			metrics.state(event,role)
		if op == "result":
			if event.get("match","") != match_id or result_received: continue
			result_received = true; resume_token = ""; reconnecting = false; reconnect_deadline = 0
		if op == "error": resume_token = ""; reconnecting = false; reconnect_deadline = 0
		if op != "pong":
			var receiving_socket := socket
			event_received.emit(event)
			# A synchronous scene preparation callback is local work, not server
			# silence. Never apply its timing/packets to a replacement transport.
			if socket != receiving_socket: return
			last_message = Time.get_ticks_msec()
	if socket == null: return
	if state == WebSocketPeer.STATE_CLOSED:
		var reason := socket.get_close_reason()
		if socket.get_close_code() == 1008 and RULES.ERROR_MESSAGES.has(reason):
			if reason == "resume_busy" and reconnecting: _network_lost(reason); return
			resume_token = ""; reconnecting = false; event_received.emit({"op":"error","reason":reason})
		_network_lost("서버 연결이 종료되었습니다."); return
	if state == WebSocketPeer.STATE_OPEN:
		heartbeat_left -= delta
		if heartbeat_left <= 0.0: heartbeat_left = RULES.HEARTBEAT_INTERVAL; send(metrics.heartbeat())
	var timeout: float = RULES.RESPONSE_TIMEOUT if not match_id.is_empty() else RULES.JOIN_TIMEOUT
	if Time.get_ticks_msec()-last_message > int(timeout*1000.0): _network_lost("서버 응답 시간이 초과되었습니다.")
