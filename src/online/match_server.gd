extends Node
const RULES := preload("res://src/online/match_rules.gd")
const QUEUE := preload("res://src/online/match_queue.gd")
const AUTH := preload("res://src/online/auth_verifier.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
const ROOM := preload("res://src/online/battle_room.gd")
var listener := TCPServer.new()
var peers := {}
var rooms := {}
var reserved_uids := {}
var resume_tokens := {}
var queue := QUEUE.new()
var auth
var next_peer := 0
var snapshot_left := 0.0
var room_factory: Callable
var test_auth := false
var local_test_ticket := ""
var auth_pending := 0
var bind_address := "127.0.0.1"
var retire: Array[int] = []
var remove_rooms: Array[String] = []
func start(port: int,bind: String = "127.0.0.1",development_auth: bool = false,invitation: String = "") -> Error:
	if development_auth and bind != "127.0.0.1": return ERR_UNAUTHORIZED
	if not invitation.is_empty() and (bind != "127.0.0.1" or not LOCAL_ACCESS.valid_hex(invitation, LOCAL_ACCESS.TICKET_BYTES) or development_auth): return ERR_UNAUTHORIZED
	bind_address = bind; test_auth = development_auth
	local_test_ticket = invitation
	auth = AUTH.new(); add_child(auth)
	return listener.listen(port,bind)
func _process(delta: float) -> void:
	if listener.is_connection_available():
		var stream := listener.take_connection()
		if peers.size() >= RULES.MAX_CLIENTS: stream.disconnect_from_host()
		else:
			next_peer += 1
			var socket := WebSocketPeer.new(); socket.inbound_buffer_size = 32768; socket.outbound_buffer_size = 262144
			if socket.accept_stream(stream) == OK:
				peers[next_peer] = {"socket":socket,"uid":"","role":"","room":"","ready":false,"authenticating":false,"seq":0,"created":Time.get_ticks_msec(),"last":Time.get_ticks_msec(),"rate_at":Time.get_ticks_msec(),"rate":0}
	retire.clear()
	for id in peers:
		var peer: Dictionary = peers[id]; var socket: WebSocketPeer = peer.socket
		socket.poll()
		var age := (Time.get_ticks_msec()-int(peer.created))/1000.0
		var closed := socket.get_ready_state() == WebSocketPeer.STATE_CLOSED
		if (closed and socket.get_available_packet_count() == 0) or (peer.uid.is_empty() and age > RULES.JOIN_TIMEOUT) or (peer.room.is_empty() and age > RULES.QUEUE_TIMEOUT) or (not peer.uid.is_empty() and (Time.get_ticks_msec()-int(peer.last))/1000.0 > RULES.PEER_IDLE_TIMEOUT): retire.append(id); continue
		var budget := 8
		while socket.get_available_packet_count() > 0 and budget > 0:
			budget -= 1
			if Time.get_ticks_msec()-int(peer.rate_at) >= 1000: peer.rate_at = Time.get_ticks_msec(); peer.rate = 0
			peer.rate = int(peer.rate)+1
			var message := RULES.decode(socket.get_packet())
			if message.is_empty() or int(peer.rate) > 60: retire.append(id); break
			peer.last = Time.get_ticks_msec(); _receive(id,message)
			if socket.get_ready_state() == WebSocketPeer.STATE_CLOSING: break
		if closed: retire.append(id)
	for id in retire: _drop(id)
	remove_rooms.clear()
	for key in rooms:
		var match_data: Dictionary = rooms[key]; var room = match_data.node
		_expire_disconnections(key,Time.get_ticks_msec())
		if not room.running and not room.finished and not room.connection_paused and (Time.get_ticks_msec()-int(match_data.created))/1000.0 > RULES.READY_TIMEOUT: room.finish("","ready_timeout")
		if room.finished and (Time.get_ticks_msec()-int(match_data.ended))/1000.0 > RULES.RESULT_RETENTION: remove_rooms.append(key)
	for key in remove_rooms:
		for id in rooms[key].members: _drop(id)
		for seat in rooms[key].seats.values():
			resume_tokens.erase(seat.resume_token)
			if reserved_uids.get(seat.uid,"") == key: reserved_uids.erase(seat.uid)
		rooms[key].node.queue_free(); rooms.erase(key)
	_match_waiters()
	snapshot_left -= delta
	if snapshot_left <= 0.0:
		snapshot_left = RULES.SNAPSHOT_INTERVAL
		for key in rooms:
			var room = rooms[key].node
			if not room.is_prepared or room.connection_paused or room.finished: continue
			var state: Dictionary = room.snapshot(); state["match"] = key
			var encoded := _encode(state)
			for id in rooms[key].members: _send_encoded(id,encoded)
	for id in queue.members:
		if peers.has(id) and Time.get_ticks_msec()-int(peers[id].get("queue_ping",0)) > 5000:
			peers[id]["queue_ping"] = Time.get_ticks_msec(); _send(id,{"op":"queued","role":peers[id].role})
func _physics_process(delta: float) -> void:
	for key in rooms: rooms[key].node.step(delta)
func _receive(id: int,message: Dictionary) -> void:
	if not peers.has(id): return
	var peer: Dictionary = peers[id]
	if not message.get("op",null) is String: _reject(id,"invalid_request"); return
	var op: String = message.op
	if op == "resume":
		if peer.authenticating or not peer.uid.is_empty(): return
		_resume(id,message); return
	if op == "join":
		if peer.authenticating or not peer.uid.is_empty(): return
		if message.get("version",null) != RULES.VERSION or message.get("rules","") != RULES.ID: _reject(id,"version_mismatch"); return
		if not message.get("role",null) is String or not message.get("token",null) is String: _reject(id,"invalid_request"); return
		var role: String = message.role
		if role not in ["hero","demon"]: _reject(id,"invalid_role"); return
		if message.has("local_test") and (not message.local_test is Dictionary or not message.token.is_empty()): _reject(id,"invalid_request"); return
		peer.authenticating = true; _authenticate(id,message.token,role,message.get("local_test",{})); return
	if op == "ping" and not peer.uid.is_empty(): _send(id,{"op":"pong"}); return
	if peer.uid.is_empty() or not rooms.has(peer.room): return
	var match_data: Dictionary = rooms[peer.room]
	if op == "leave" and message.get("match","") == peer.room:
		match_data.node.finish("hero" if peer.role == "demon" else "demon","opponent_left")
	elif op == "ready" and message.get("match","") == peer.room:
		_expire_disconnections(peer.room,Time.get_ticks_msec())
		if match_data.node.finished: return
		peer.ready = true
		match_data.seats[peer.role].deadline = 0
		_sync_connection_state(peer.room)
		var all_ready := true
		for other in match_data.members:
			if not peers.has(other) or not peers[other].ready: all_ready = false
		if all_ready and not match_data.node.running: match_data.node.start()
	elif op == "input" and message.get("match","") == peer.room:
		var raw_seq: Variant = message.get("seq",null)
		if not RULES.number(raw_seq,2147483647.0) or float(raw_seq) != floorf(float(raw_seq)): return
		var sequence := int(raw_seq)
		if sequence <= int(peer.seq): return
		peer.seq = sequence
		if message.get("kind",null) is String:
			var accepted: bool = match_data.node.apply(peer.role,message.kind,message.get("argument",null))
			if message.kind == "summon": _send(id,{"op":"action","match":peer.room,"accepted":accepted,"message":match_data.node.last_action_message})
func _authenticate(id: int,token: String,role: String,local_credentials: Dictionary = {}) -> void:
	var uid := ""
	if not local_credentials.is_empty():
		uid = LOCAL_ACCESS.session_uid(local_credentials,local_test_ticket)
		if uid.is_empty(): _reject(id,"local_test_denied"); return
	elif test_auth:
		if token in ["fixture_hero","fixture_demon","fixture_third"]: uid = token
	else:
		if auth_pending >= RULES.MAX_AUTH_REQUESTS: _reject(id,"server_busy"); return
		auth_pending += 1; uid = await auth.verify(token); auth_pending -= 1
	token = ""
	if not peers.has(id): return
	if uid.is_empty(): _reject(id,"authentication_failed"); return
	if reserved_uids.has(uid): _reject(id,"duplicate_account"); return
	for other in peers:
		if other != id and peers[other].uid == uid:
			var prior: Dictionary = peers[other]
			if not rooms.has(prior.room) or not rooms[prior.room].node.finished: _reject(id,"duplicate_account"); return
	peers[id].uid = uid; peers[id].role = role; peers[id].created = Time.get_ticks_msec()
	if not queue.enqueue(id,uid,role): _reject(id,"queue_rejected"); return
	_send(id,{"op":"queued","role":role})
func _match_waiters() -> void:
	if rooms.size() >= RULES.MAX_ROOMS: return
	var pair: Array = queue.pair()
	if pair.is_empty(): return
	var key := Crypto.new().generate_random_bytes(16).hex_encode()
	var room = room_factory.call() if room_factory.is_valid() else ROOM.new()
	add_child(room)
	var seats := {}
	for id in pair:
		var peer: Dictionary = peers[id]
		var resume_token := Crypto.new().generate_random_bytes(RULES.RESUME_TOKEN_BYTES).hex_encode()
		seats[peer.role] = {"uid":peer.uid,"peer":id,"resume_token":resume_token,"deadline":0}
		reserved_uids[peer.uid] = key
		resume_tokens[resume_token] = {"match":key,"role":peer.role}
	rooms[key] = {"node":room,"members":pair,"seats":seats,"created":Time.get_ticks_msec(),"ended":0}
	room.completed.connect(_completed.bind(key)); room.prepare()
	if room.finished:
		for id in pair: _reject(id,"battle_load_failed")
		return
	for id in pair:
		if not peers.has(id): room.finish("","peer_left"); return
		peers[id].room = key; peers[id].ready = false
		_send_matched(id,key,false)
func _send_matched(id: int,key: String,resumed: bool) -> void:
	var role: String = peers[id].role
	_send(id,{"op":"matched","match":key,"role":role,"rules":RULES.ID,"hero":RULES.HERO,"roster":RULES.ROSTER,"duration":RULES.DURATION,"resume_token":rooms[key].seats[role].resume_token,"resumed":resumed})
func _resume(id: int,message: Dictionary) -> void:
	if message.get("version",null) != RULES.VERSION or message.get("rules","") != RULES.ID: _reject(id,"version_mismatch"); return
	var token_value: Variant = message.get("resume_token",null)
	if not RULES.resume_token_valid(token_value) or not resume_tokens.has(token_value): _reject(id,"resume_unavailable"); return
	var reservation: Dictionary = resume_tokens[token_value]
	var key: String = reservation.match
	if message.get("match",null) != key or not rooms.has(key): _reject(id,"resume_unavailable"); return
	_expire_disconnections(key,Time.get_ticks_msec())
	var match_data: Dictionary = rooms[key]
	if match_data.node.finished and (Time.get_ticks_msec()-int(match_data.ended))/1000.0 > RULES.RESULT_RETENTION: _reject(id,"resume_unavailable"); return
	var seat: Dictionary = match_data.seats[reservation.role]
	if peers.has(seat.peer): _reject(id,"resume_busy"); return
	var member_index: int = match_data.members.find(seat.peer)
	if member_index < 0: _reject(id,"resume_unavailable"); return
	var peer: Dictionary = peers[id]
	peer.uid = seat.uid; peer.role = reservation.role; peer.room = key; peer.seq = 0
	match_data.members[member_index] = id; seat.peer = id
	if match_data.node.finished: seat.deadline = 0
	if not match_data.node.running and not match_data.node.finished: match_data.created = Time.get_ticks_msec()
	_send_matched(id,key,true)
	_sync_connection_state(key)
	if match_data.node.is_prepared:
		var state: Dictionary = match_data.node.snapshot(); state["match"] = key; _send(id,state)
	if match_data.node.finished: _send_result(id,key)
func _sync_connection_state(key: String) -> void:
	if not rooms.has(key) or rooms[key].node.finished: return
	var match_data: Dictionary = rooms[key]
	var deadline := 0
	for seat in match_data.seats.values():
		if int(seat.deadline) > 0: deadline = int(seat.deadline) if deadline == 0 else mini(deadline,int(seat.deadline))
	match_data.node.set_connection_paused(deadline > 0)
	var message := {"op":"connection","match":key,"paused":deadline > 0,"remaining":maxf(0.0,float(deadline-Time.get_ticks_msec())/1000.0) if deadline > 0 else 0.0}
	for member in match_data.members: _send(member,message)
func _expire_disconnections(key: String,now: int) -> void:
	var match_data: Dictionary = rooms[key]
	if match_data.node.finished: return
	var expired := false
	var connected_role := ""
	for role in match_data.seats:
		var seat: Dictionary = match_data.seats[role]
		if int(seat.deadline) > 0 and now >= int(seat.deadline): expired = true
		if peers.has(seat.peer) and peers[seat.peer].ready and int(seat.deadline) == 0: connected_role = role
	if expired: match_data.node.finish(connected_role,"both_disconnected" if connected_role.is_empty() else "reconnect_timeout")
func _send_result(id: int,key: String) -> void:
	var room = rooms[key].node
	_send(id,{"op":"result","match":key,"winner":room.winner,"reason":room.reason,"rated":false})
func _completed(winner: String,reason: String,key: String) -> void:
	if not rooms.has(key): return
	rooms[key].ended = Time.get_ticks_msec()
	for seat in rooms[key].seats.values():
		if reserved_uids.get(seat.uid,"") == key: reserved_uids.erase(seat.uid)
	for id in rooms[key].members: _send(id,{"op":"result","match":key,"winner":winner,"reason":reason,"rated":false})
static func _encode(message: Dictionary) -> String:
	var encoded := JSON.stringify(message)
	return encoded if encoded.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT else ""

func _send(id: int,message: Dictionary) -> void:
	_send_encoded(id,_encode(message))

func _send_encoded(id: int,encoded: String) -> void:
	if not peers.has(id): return
	var socket: WebSocketPeer = peers[id].socket
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return
	if socket.get_current_outbound_buffered_amount() > RULES.MAX_SNAPSHOT*2: socket.close(1008,"slow consumer"); return
	if not encoded.is_empty(): socket.send_text(encoded)
func _reject(id: int,reason: String) -> void:
	_send(id,{"op":"error","reason":reason})
	if peers.has(id): peers[id].socket.close(1008,reason)
func _drop(id: int) -> void:
	if not peers.has(id): return
	var peer: Dictionary = peers[id]; queue.remove(id)
	peer.socket.close(); peers.erase(id)
	if rooms.has(peer.room) and not rooms[peer.room].node.finished:
		var seat: Dictionary = rooms[peer.room].seats[peer.role]
		if int(seat.peer) == id and int(seat.deadline) == 0:
			seat.deadline = Time.get_ticks_msec() + int(RULES.RECONNECT_GRACE * 1000.0)
			_sync_connection_state(peer.room)
func _exit_tree() -> void:
	listener.stop()
	for peer in peers.values(): peer.socket.close()
