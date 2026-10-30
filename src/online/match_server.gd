extends Node
const RULES := preload("res://src/online/match_rules.gd")
const QUEUE := preload("res://src/online/match_queue.gd")
const AUTH := preload("res://src/online/auth_verifier.gd")
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
const RANKED := preload("res://src/data/ranked_rules.gd")
const RESULT_STORE := preload("res://src/online/ranked_result_store.gd")
const LOADOUT := preload("res://src/online/online_loadout.gd")
const LOADOUT_STORE := preload("res://src/online/ranked_loadout_store.gd")
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
# Client sequences rise by one per sent input and reset per match; a larger jump would lock that seat's later inputs.
const MAX_INPUT_SEQ_STEP := 64
var result_store
var loadout_store
var metrics = preload("res://src/online/network_metrics.gd").new()
var metrics_report_at := -1
var metrics_cache := {}
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
var map_rng := RandomNumberGenerator.new()
var test_auth := false
var local_test_ticket := ""
var auth_pending := 0
var bind_address := "127.0.0.1"
var retire: Array[int] = []
var remove_rooms: Array[String] = []
func _ready() -> void:
	map_rng.randomize()
func start(port: int,bind: String = "127.0.0.1",development_auth: bool = false,invitation: String = "") -> Error:
	if development_auth and bind != "127.0.0.1": return ERR_UNAUTHORIZED
	if not invitation.is_empty() and (bind != "127.0.0.1" or not LOCAL_ACCESS.valid_hex(invitation, LOCAL_ACCESS.TICKET_BYTES) or development_auth): return ERR_UNAUTHORIZED
	metrics.enabled = development_auth or not invitation.is_empty(); metrics.reset(); metrics_report_at=-1; metrics_cache={}
	bind_address = bind; test_auth = development_auth
	local_test_ticket = invitation
	auth = AUTH.new(); add_child(auth)
	result_store = RESULT_STORE.new(); add_child(result_store)
	loadout_store = LOADOUT_STORE.new(); add_child(loadout_store)
	return listener.listen(port,bind)
func _process(delta: float) -> void:
	metrics.tick_rates()
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
		var budget := 8
		while socket.get_available_packet_count() > 0 and budget > 0:
			budget -= 1
			if Time.get_ticks_msec()-int(peer.rate_at) >= 1000: peer.rate_at = Time.get_ticks_msec(); peer.rate = 0
			peer.rate = int(peer.rate)+1
			var packet := socket.get_packet(); metrics.receive_bytes(packet.size())
			var message := RULES.decode(packet)
			if message.is_empty() or int(peer.rate) > 60: retire.append(id); break
			peer.last = Time.get_ticks_msec(); _receive(id,message)
			if socket.get_ready_state() == WebSocketPeer.STATE_CLOSING: break
		# Consume buffered ready/heartbeat packets before evaluating silence.
		# Cold map preparation has its existing bounded ready budget, not the
		# running match heartbeat budget. Disconnect grace remains unchanged.
		var now := Time.get_ticks_msec()
		var age := (now-int(peer.created))/1000.0
		var idle_limit: float = RULES.READY_TIMEOUT if rooms.has(peer.room) and not peer.ready else RULES.PEER_IDLE_TIMEOUT
		if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED or (peer.uid.is_empty() and age > RULES.JOIN_TIMEOUT) or (peer.room.is_empty() and age > RULES.QUEUE_TIMEOUT) or (not peer.uid.is_empty() and (now-int(peer.last))/1000.0 > idle_limit): retire.append(id)
	for id in retire: _drop(id)
	remove_rooms.clear()
	for key in rooms:
		var match_data: Dictionary = rooms[key]; var room = match_data.node
		_expire_disconnections(key,Time.get_ticks_msec())
		if not room.running and not room.finished and not room.connection_paused and (Time.get_ticks_msec()-int(match_data.created))/1000.0 > RULES.READY_TIMEOUT: room.finish("","ready_timeout")
		if room.finished and not bool(match_data.get("result_pending",false)) and (Time.get_ticks_msec()-int(match_data.ended))/1000.0 > RULES.RESULT_RETENTION: remove_rooms.append(key)
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
			if not room.is_prepared or not room.running or room.connection_paused or room.finished: continue
			var started: int = Time.get_ticks_usec() if metrics.enabled else 0
			var state: Dictionary = room.snapshot(); state["match"] = key
			var bytes := -1
			if metrics.enabled:
				metrics.samples.snapshot.push(float(Time.get_ticks_usec()-started)/1000.0)
				state["ack"]={"hero":0,"demon":0}
				for role in rooms[key].seats:
					var peer_id: int = rooms[key].seats[role].peer
					if peers.has(peer_id): state.ack[role]=peers[peer_id].seq
				started=Time.get_ticks_usec()
			for id in rooms[key].members:
				if not peers.has(id): continue
				var own_state: Dictionary = room.snapshot_for_role(String(peers[id].role),state)
				own_state["feedback"] = room.feedback.snapshot(int(peers[id].get("feedback_sent",0)))
				var encoded := _encode_state(key,own_state)
				if metrics.enabled:
					metrics.samples.encode.push(float(Time.get_ticks_usec()-started)/1000.0)
					bytes=encoded.to_utf8_buffer().size(); metrics.snapshot_bytes=bytes
				if _send_encoded(id,encoded,bytes): peers[id]["feedback_sent"] = room.feedback.sequence
	for id in queue.members:
		if peers.has(id) and Time.get_ticks_msec()-int(peers[id].get("queue_ping",0)) > 5000:
			peers[id]["queue_ping"] = Time.get_ticks_msec(); _send_queued(id)
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
		if not LOADOUT.valid(role,message.get("loadout",null)): _reject(id,"invalid_loadout"); return
		if message.has("local_test") and (not message.local_test is Dictionary or not message.token.is_empty()): _reject(id,"invalid_request"); return
		peer.authenticating = true; _authenticate(id,message.token,role,message.loadout,message.get("local_test",{})); return
	if op == "ping" and not peer.uid.is_empty():
		var pong := {"op":"pong"}
		if preload("res://src/data/online_metrics_catalog.gd").sequence(message.get("probe",null)):
			pong["probe"]=message.probe
			if metrics.enabled: pong["metrics"]=_metrics_report()
		_send(id,pong); return
	if peer.uid.is_empty() or not rooms.has(peer.room): return
	var match_data: Dictionary = rooms[peer.room]
	if op == "leave" and message.get("match","") == peer.room:
		match_data.node.finish(("hero" if peer.role == "demon" else "demon") if match_data.node.running else "","opponent_left" if match_data.node.running else "preparation_cancelled")
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
		if sequence <= int(peer.seq) or sequence > int(peer.seq)+MAX_INPUT_SEQ_STEP: return
		peer.seq = sequence
		if message.get("kind",null) is String:
			var accepted: bool
			if message.kind == "transcend_unlock_test":
				var allowed: bool = not bool(match_data.get("rated",true)) and (test_auth or not local_test_ticket.is_empty())
				accepted = match_data.node.apply(peer.role,message.kind,message.get("argument",null),allowed)
			else:
				accepted = match_data.node.apply(peer.role,message.kind,message.get("argument",null))
			if message.kind in ["summon","skill","transcend","transcend_unlock_test"]: _send(id,{"op":"action","match":peer.room,"accepted":accepted,"message":match_data.node.last_action_message})
func _authenticate(id: int,token: String,role: String,loadout: Dictionary,local_credentials: Dictionary = {}) -> void:
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
	var rated: bool = _loadout_verification_required(local_credentials)
	if rated and not await loadout_store.verify(uid,role,loadout):
		if peers.has(id): _reject(id,"loadout_mismatch")
		return
	if not peers.has(id): return
	var mmr: int = int(RANKED.data().get("initial_mmr", 1000))
	if rated: mmr = await result_store.fetch_mmr(uid,role)
	if not peers.has(id): return
	if reserved_uids.has(uid): _reject(id,"duplicate_account"); return
	for other in peers:
		if other != id and peers[other].uid == uid:
			var prior: Dictionary = peers[other]
			if not rooms.has(prior.room) or not rooms[prior.room].node.finished: _reject(id,"duplicate_account"); return
	peers[id].uid = uid; peers[id].role = role; peers[id].loadout = loadout.duplicate(true); peers[id].rated = rated; peers[id].created = Time.get_ticks_msec()
	if not queue.enqueue(id,uid,role,RANKED.tier_index(mmr) if rated else -1): _reject(id,"queue_rejected"); return
	_send_queued(id)
func _send_queued(id: int) -> void:
	if not queue.members.has(id) or not peers.has(id): return
	var entry: Dictionary = queue.members[id]
	var thresholds: Array = RANKED.data().get("mmr_thresholds", [])
	var tier_id := String(thresholds[entry.tier].id) if entry.tier >= 0 and entry.tier < thresholds.size() else ""
	var expanded: bool = entry.tier >= 0 and Time.get_ticks_msec() / 1000.0 - float(entry.since) >= RULES.MATCH_TIER_EXPAND_SECONDS
	_send(id,{"op":"queued","role":peers[id].role,"tier":tier_id,"expanded":expanded})
func _loadout_verification_required(local_credentials: Dictionary = {}) -> bool:
	return not test_auth and local_credentials.is_empty() and loadout_store != null and loadout_store.configured()
func _match_waiters() -> void:
	if rooms.size() >= RULES.MAX_ROOMS: return
	var pair: Array = queue.pair()
	if pair.is_empty(): return
	var key := Crypto.new().generate_random_bytes(16).hex_encode()
	var room = room_factory.call() if room_factory.is_valid() else ROOM.new()
	room.map_id = String(MAPS.pick(map_rng).id)
	add_child(room)
	var seats := {}
	for id in pair:
		var peer: Dictionary = peers[id]
		var resume_token := Crypto.new().generate_random_bytes(RULES.RESUME_TOKEN_BYTES).hex_encode()
		seats[peer.role] = {"uid":peer.uid,"peer":id,"resume_token":resume_token,"deadline":0}
		reserved_uids[peer.uid] = key
		resume_tokens[resume_token] = {"match":key,"role":peer.role}
	room.set_loadouts(peers[pair[0]].loadout if peers[pair[0]].role == "hero" else peers[pair[1]].loadout,
		peers[pair[0]].loadout if peers[pair[0]].role == "demon" else peers[pair[1]].loadout)
	rooms[key] = {"node":room,"members":pair,"seats":seats,"codec":CODEC.new(),"created":Time.get_ticks_msec(),"ended":0,"result_started":false,"result_pending":false,"rated_result":{},"rated":bool(peers[pair[0]].rated) and bool(peers[pair[1]].rated)}
	room.completed.connect(_completed.bind(key)); room.prepare()
	if room.finished:
		for id in pair: _reject(id,"battle_load_failed")
		return
	# Server-side resource loading must not consume either client's ready time.
	var prepared_at := Time.get_ticks_msec()
	rooms[key].created = prepared_at
	for id in pair:
		if not peers.has(id): room.finish("","peer_left"); return
		peers[id].room = key; peers[id].ready = false; peers[id].last = prepared_at
		_send_matched(id,key,false)
func _send_matched(id: int,key: String,resumed: bool) -> void:
	var role: String = peers[id].role
	peers[id]["feedback_sent"] = rooms[key].node.feedback.sequence
	_send(id,_matched_payload(key,role,resumed))
func _matched_payload(key: String,role: String,resumed: bool) -> Dictionary:
	var room = rooms[key].node
	return {"op":"matched","match":key,"role":role,"rules":RULES.ID,"hero":room.hero_id,"roster":room.roster if role=="demon" else [],"skill_ids":room.skill_ids if role=="demon" else [],"transcendence_id":room.transcendence_id,"duration":room.battle.run_time_limit_seconds,"map":room.map_id,"resume_token":rooms[key].seats[role].resume_token,"resumed":resumed,"feedback_cursor":room.feedback.sequence,"battlefield":room.battlefield_info}
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
		var state: Dictionary = match_data.node.snapshot(String(peer.role)); state["match"] = key; _send_encoded(id,_encode_state(key,state))
	if match_data.node.finished and not bool(match_data.get("result_pending",false)): _send_result(id,key)
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
	var ranked: Dictionary = rooms[key].get("rated_result",{})
	var role: String = String(peers[id].role) if peers.has(id) else ""
	_send(id,{"op":"result","match":key,"winner":room.winner,"reason":room.reason,"rated":not ranked.is_empty(),"ranking":ranked.get(role,{}),"tick":room.tick,"feedback":room.feedback.snapshot(),"feedback_cursor":room.feedback.sequence})
func _completed(winner: String,reason: String,key: String) -> void:
	if not rooms.has(key): return
	if bool(rooms[key].get("result_pending",false)): return
	rooms[key].ended = Time.get_ticks_msec()
	for seat in rooms[key].seats.values():
		if reserved_uids.get(seat.uid,"") == key: reserved_uids.erase(seat.uid)
	if _result_can_record(rooms[key],winner,reason):
		rooms[key].result_started = true; rooms[key].result_pending = true
		_record_result(key,winner,reason)
		return
	for id in rooms[key].members: _send_result(id,key)

func _result_can_record(match_data: Dictionary,winner: String,reason: String) -> bool:
	if not bool(match_data.get("rated",true)): return false
	if bool(match_data.get("result_started",false)) or result_store == null: return false
	var seats: Dictionary = match_data.get("seats",{})
	if not seats.has("demon") or not seats.has("hero"): return false
	return RANKED.rated_allowed(test_auth,local_test_ticket,winner,reason,result_store.configured(),
		String(seats.demon.uid),String(seats.hero.uid))

func _record_result(key: String,winner: String,reason: String) -> void:
	var match_data: Dictionary = rooms[key]
	var room = match_data.node
	var elapsed := 0.0
	var hp_ratio := 0.0
	if is_instance_valid(room.battle) and is_instance_valid(room.battle.hero):
		elapsed = float(room.battle.run_metrics.elapsed_seconds)
		hp_ratio = float(room.battle.hero.current_hp) / maxf(1.0,float(room.battle.hero.max_hp))
	var margins: Dictionary = _match_margins(room,winner,reason,elapsed,hp_ratio)
	var result: Dictionary = await result_store.record(key,String(match_data.seats.demon.uid),
		String(match_data.seats.hero.uid),winner,reason,margins)
	if not rooms.has(key): return
	rooms[key].rated_result = result
	rooms[key].result_pending = false
	rooms[key].ended = Time.get_ticks_msec()
	for id in rooms[key].members: _send_result(id,key)
func _match_margins(room: Node,winner: String,reason: String,elapsed: float,hp_ratio: float) -> Dictionary:
	return RANKED.margins(winner,reason,elapsed,room.battle.run_time_limit_seconds,hp_ratio)
static func _encode(message: Dictionary) -> String:
	var encoded := JSON.stringify(message)
	return encoded if encoded.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT else ""
func _encode_state(key: String,message: Dictionary) -> String:
	# Lazy fallback also supports isolated test rooms installed without the lobby.
	if not rooms[key].has("codec"): rooms[key]["codec"] = CODEC.new()
	return rooms[key].codec.encode(message)

func _send(id: int,message: Dictionary) -> void:
	_send_encoded(id,_encode(message))

func _send_encoded(id: int,encoded: String,bytes: int = -1) -> bool:
	if not peers.has(id): return false
	var socket: WebSocketPeer = peers[id].socket
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN: return false
	if socket.get_current_outbound_buffered_amount() > RULES.MAX_SNAPSHOT*2: socket.close(1008,"slow consumer"); return false
	if encoded.is_empty() or socket.send_text(encoded) != OK: return false
	if metrics.enabled: metrics.send_bytes(bytes if bytes>=0 else encoded.to_utf8_buffer().size())
	return true
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

func _metrics_report() -> Dictionary:
	var now := Time.get_ticks_usec()
	if metrics_report_at>=0 and now-metrics_report_at<preload("res://src/data/online_metrics_catalog.gd").REFRESH_US: return metrics_cache
	metrics_report_at=now
	var actors := 0
	var projectiles := 0
	for key in rooms:
		var room = rooms[key].node
		if not room.is_prepared or room.finished: continue
		actors += room.battle.active_monsters.size()
		projectiles += room.battle.online_visual_projectiles.size()
		if room.battle.hero.player_weapons != null:
			for shot in room.battle.hero.player_weapons.projectiles:
				if shot.active: projectiles += 1
	metrics_cache=metrics.server_report(rooms.size(),peers.size(),actors,projectiles)
	return metrics_cache
