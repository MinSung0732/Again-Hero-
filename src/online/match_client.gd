extends Node
const RULES := preload("res://src/online/match_rules.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
signal event_received(event: Dictionary)
signal connection_closed(message: String)
var socket: WebSocketPeer
var token := ""
var local_ticket := ""
var local_session := ""
var role := "hero"
var sequence := 0
var match_id := ""
var greeted := false
var last_message := 0
func join(endpoint: String,access_token: String,requested_role: String) -> Error:
	close(); token = access_token; role = requested_role
	if not RULES.endpoint_valid(endpoint) or requested_role not in ["hero","demon"]: token = ""; return ERR_INVALID_PARAMETER
	socket = WebSocketPeer.new(); socket.inbound_buffer_size = 262144; socket.outbound_buffer_size = 65536
	var error := socket.connect_to_url(endpoint)
	if error != OK: socket = null; token = ""; return error
	last_message = Time.get_ticks_msec(); set_process(true); return OK
func join_local_test(endpoint: String,invitation: String,requested_role: String) -> Error:
	if not LOCAL_ACCESS.valid_hex(invitation,LOCAL_ACCESS.TICKET_BYTES): close(); return ERR_INVALID_PARAMETER
	var error := join(endpoint,"",requested_role)
	if error == OK:
		local_ticket = invitation
		if local_session.is_empty(): local_session = LOCAL_ACCESS.new_session()
	return error
func close() -> void:
	if socket != null: socket.close()
	socket = null; token = ""; local_ticket = ""; greeted = false; match_id = ""; sequence = 0; set_process(false)
func send(data: Dictionary) -> bool:
	return socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.send_text(JSON.stringify(data)) == OK
func command(kind: String,argument: Variant) -> bool:
	if match_id.is_empty(): return false
	sequence += 1
	return send({"op":"input","match":match_id,"seq":sequence,"kind":kind,"argument":argument})
func _process(_delta: float) -> void:
	if socket == null: return
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not greeted:
		greeted = true
		var request := {"op":"join","version":RULES.VERSION,"rules":RULES.ID,"role":role,"token":token}
		if not local_ticket.is_empty(): request["local_test"] = {"ticket":local_ticket,"session":local_session}
		send(request); token = ""; local_ticket = ""
	# Drain error/result packets even if a close frame arrived in the same poll.
	var budget := 8
	while socket != null and socket.get_available_packet_count() > 0 and budget > 0:
		budget -= 1
		var event := RULES.decode(socket.get_packet(),RULES.MAX_SNAPSHOT)
		if event.is_empty(): continue
		last_message = Time.get_ticks_msec()
		if event.get("op","") == "matched":
			if not event.get("match",null) is String or event.get("rules","") != RULES.ID: continue
			match_id = event.match; sequence = 0
		event_received.emit(event)
	if socket == null: return
	if state == WebSocketPeer.STATE_CLOSED:
		var close_reason := socket.get_close_reason()
		if socket.get_close_code() == 1008 and RULES.ERROR_MESSAGES.has(close_reason): event_received.emit({"op":"error","reason":close_reason})
		close(); connection_closed.emit("서버 연결이 종료되었습니다."); return
	if Time.get_ticks_msec()-last_message > 20000:
		close(); connection_closed.emit("서버 응답 시간이 초과되었습니다.")
