extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const RULES := preload("res://src/online/match_rules.gd")
var server
var hero
var demon
var logs := {}
var ready_flags := {}
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline: await process_frame
func until(condition: Callable,seconds: float = 6.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while not condition.call() and Time.get_ticks_msec()<deadline: await process_frame
	return condition.call()
func make_client(automatic_ready: bool = true):
	var client = CLIENT.new(); root.add_child(client)
	var id: int = client.get_instance_id(); logs[id] = []; ready_flags[id] = automatic_ready
	client.event_received.connect(func(event: Dictionary):
		logs[id].append(event)
		if event.get("op","") == "matched" and ready_flags[id]: client.send({"op":"ready","match":client.match_id}))
	return client
func result_count(client) -> int:
	var count := 0
	for event in logs[client.get_instance_id()]:
		if event.get("op","") == "result": count += 1
	return count
func has_error(client,reason: String) -> bool:
	for event in logs[client.get_instance_id()]:
		if event.get("op","") == "error" and event.get("reason","") == reason: return true
	return false
func pair(ready: bool = true):
	hero = make_client(ready); demon = make_client()
	check(hero.join("ws://127.0.0.1:24845","fixture_hero","hero") == OK,"hero initial join")
	check(demon.join("ws://127.0.0.1:24845","fixture_demon","demon") == OK,"demon initial join")
	check(await until(func(): return not hero.match_id.is_empty() and server.rooms.has(hero.match_id) and (server.rooms[hero.match_id].node.running if ready else true)),"pair ready")
	return server.rooms[hero.match_id].node
func cleanup_pair() -> void:
	var key: String = hero.match_id
	hero.close(); demon.close(); hero.queue_free(); demon.queue_free(); await pump(0.1)
	if server.rooms.has(key):
		server.rooms[key].node.finish("","fixture_cleanup")
		server.rooms[key].ended = Time.get_ticks_msec()-int((RULES.RESULT_RETENTION+1)*1000)
		server._process(0.0)
	await process_frame
func run() -> void:
	server = SERVER.new(); root.add_child(server)
	check(server.start(24845,"127.0.0.1",true) == OK,"loopback server")
	var room = await pair()
	var key: String = hero.match_id
	var instance: int = room.get_instance_id()
	var saved_token: String = hero.resume_token
	check(RULES.resume_token_valid(saved_token) and saved_token != demon.resume_token,"unique per-seat resume capabilities")
	room.battle.hero._level_up()
	check(not room.choice.is_empty(),"actual pending level-up choice")
	hero.command("move",[1,0]); await pump(0.1)
	hero._network_lost("fixture cable cut")
	check(await until(func(): return room.connection_paused),"unexpected disconnect pauses room")
	check(hero.reconnecting and not hero.command("move",[1,0]),"disconnected client cannot send gameplay")
	var frozen := [room.tick,room.choice_age,room.battle.run_metrics.elapsed_seconds,room.battle.command_power,room.battle.hero.current_hp,room.battle.hero.level,room.choice_revision,room.battle.hero.build_counts.duplicate(true)]
	check(room.battle.hero.player_move_input == Vector2.ZERO and room.battle.external_pause,"input zero and actual Battle paused")
	await pump(0.2)
	check(frozen == [room.tick,room.choice_age,room.battle.run_metrics.elapsed_seconds,room.battle.command_power,room.battle.hero.current_hp,room.battle.hero.level,room.choice_revision,room.battle.hero.build_counts],"clock/HP/mana/level/build/augment timeout frozen")
	var mana: float = room.battle.command_power
	demon.command("summon",{"id":"slime","point":[400,600]}); await pump(0.1)
	check(room.battle.command_power == mana and room.battle.active_monsters.is_empty(),"paused server rejects opponent input")
	var duplicate = make_client()
	duplicate.join("ws://127.0.0.1:24845","fixture_hero","hero")
	check(await until(func(): return has_error(duplicate,"duplicate_account")),"disconnected identity remains reserved")
	duplicate.close(); duplicate.queue_free()
	check(await until(func(): return not hero.reconnecting and not room.connection_paused),"automatic authenticated seat recovery")
	check(hero.match_id == key and room.get_instance_id() == instance and hero.resume_token == saved_token,"same room/state and retry-safe token")
	check(room.battle.hero.level == frozen[5] and room.choice_revision == frozen[6] and not room.choice.is_empty(),"pending augment restored")
	var revision: int = room.choice_revision
	hero.command("choose",{"revision":revision,"id":String(room.choice[0].id)})
	check(await until(func(): return room.choice_revision > revision),"restored augment choice accepted")
	var x: float = room.battle.hero.position.x
	hero.command("move",[1,0]); await pump(0.12)
	check(room.battle.hero.position.x>x,"new sequence moves after reconnect")
	hero.command("move",[0,0]); await pump(0.05)
	var sequence: int = server.peers[server.rooms[key].seats.hero.peer].seq
	hero.send({"op":"input","match":key,"seq":sequence,"kind":"move","argument":[0,-1]}); await pump(0.05)
	check(room.battle.hero.player_move_input == Vector2.ZERO,"stale sequence rejected after reconnect")
	# Old/bogus capabilities cannot take over a live or disconnected seat.
	var attacker = make_client()
	attacker.endpoint_url = "ws://127.0.0.1:24845"; attacker.match_id = key
	attacker.resume_token = "0".repeat(RULES.RESUME_TOKEN_BYTES*2); attacker._network_lost("attack"); attacker.next_retry = 0
	check(await until(func(): return has_error(attacker,"resume_unavailable")),"unknown capability rejected")
	check(room.running and not room.connection_paused,"attacker does not disturb active room")
	attacker.close(); attacker.queue_free()
	var wrong_room = make_client()
	wrong_room.endpoint_url = "ws://127.0.0.1:24845"; wrong_room.match_id = key + "wrong"
	wrong_room.resume_token = saved_token; wrong_room._network_lost("wrong room"); wrong_room.next_retry = 0
	check(await until(func(): return has_error(wrong_room,"resume_unavailable")),"valid token is scoped to its original match")
	wrong_room.close(); wrong_room.queue_free()
	var duplicate_resume = make_client()
	duplicate_resume.endpoint_url = "ws://127.0.0.1:24845"; duplicate_resume.match_id = key
	duplicate_resume.resume_token = saved_token; duplicate_resume._network_lost("duplicate resume"); duplicate_resume.next_retry = 0
	var active_peer: int = server.rooms[key].seats.hero.peer
	await pump(0.2)
	check(duplicate_resume.reconnecting and server.rooms[key].seats.hero.peer == active_peer and not room.connection_paused,"live seat cannot be stolen by concurrent resume")
	duplicate_resume.close(); duplicate_resume.queue_free()
	# Android pause notification takes the recovery path, never explicit leave.
	hero._notification(NOTIFICATION_APPLICATION_PAUSED)
	check(await until(func(): return room.connection_paused),"app pause holds match")
	check(await until(func(): return not hero.reconnecting and not room.connection_paused),"app return resumes match")
	await pump(RULES.HEARTBEAT_INTERVAL+0.1)
	check(not room.connection_paused and hero.socket != null and demon.socket != null,"heartbeats keep idle match connected")
	# Duplicate terminal packets are ignored client-side.
	demon.close()
	check(await until(func(): return room.finished and result_count(hero)==1),"explicit healthy leave forfeits immediately")
	check(room.winner == "hero" and room.reason == "opponent_left","forfeit result")
	server._send_result(int(server.rooms[key].seats.hero.peer),key); await pump(0.1)
	check(result_count(hero)==1 and hero.resume_token.is_empty(),"one terminal result and capability erased")
	await cleanup_pair()
	check(server.resume_tokens.is_empty() and server.reserved_uids.is_empty(),"retired room releases both registries")
	# Deadline expiry with one survivor; disconnected client can recover result.
	room = await pair(); key = hero.match_id
	hero._network_lost("fixture cut"); hero.set_process(false)
	check(await until(func(): return room.connection_paused),"expiry setup")
	var seat: Dictionary = server.rooms[key].seats.hero
	var original_deadline: int = seat.deadline
	server._drop(int(seat.peer))
	check(seat.deadline == original_deadline,"repeated disconnect does not extend grace")
	seat.deadline = Time.get_ticks_msec()-1
	server._expire_disconnections(key,Time.get_ticks_msec())
	check(await until(func(): return result_count(demon)==1),"survivor receives timeout result")
	check(room.winner == "demon" and room.reason == "reconnect_timeout","absent hero loses at deadline")
	hero.set_process(true); hero.next_retry = 0
	check(await until(func(): return result_count(hero)==1),"late reconnect recovers authoritative terminal result")
	check(hero.result_received and not hero.reconnecting and room.finished,"late reconnect cannot restart battle")
	room.finish("hero","duplicate_finish")
	check(room.winner == "demon" and result_count(hero)==1,"terminal result immutable")
	await cleanup_pair()
	# Both absent at first expiry means void, not a locally invented winner.
	room = await pair(); key = hero.match_id
	hero._network_lost("cut"); demon._network_lost("cut"); hero.set_process(false); demon.set_process(false)
	check(await until(func(): return not server.peers.has(server.rooms[key].seats.hero.peer) and not server.peers.has(server.rooms[key].seats.demon.peer)),"both transports lost")
	server.rooms[key].seats.hero.deadline = Time.get_ticks_msec()-1
	server._expire_disconnections(key,Time.get_ticks_msec())
	check(room.finished and room.winner.is_empty() and room.reason == "both_disconnected","both absent yields void")
	hero.set_process(true); demon.set_process(true); hero.next_retry = 0; demon.next_retry = 0
	check(await until(func(): return result_count(hero)==1 and result_count(demon)==1),"both recover same void result")
	await cleanup_pair()
	# A restored transport must acknowledge readiness before unpausing.
	room = await pair(false); key = hero.match_id
	hero._network_lost("pre-ready cut")
	check(await until(func(): return room.connection_paused),"pre-ready disconnect held")
	check(await until(func(): return not hero.reconnecting),"pre-ready transport restored")
	check(room.connection_paused and not room.running,"resume packet alone cannot start battle")
	ready_flags[hero.get_instance_id()] = true
	hero.send({"op":"ready","match":key})
	check(await until(func(): return room.running and not room.connection_paused),"ready ACK starts original prepared room")
	# A one-way silent connection is detected even if TCP remains open.
	hero.set_process(false)
	server.peers[server.rooms[key].seats.hero.peer].last = Time.get_ticks_msec()-int((RULES.PEER_IDLE_TIMEOUT+1)*1000)
	server._process(0.0)
	check(room.connection_paused and not room.finished,"heartbeat loss enters grace")
	hero.set_process(true)
	check(await until(func(): return not room.connection_paused),"heartbeat-loss auto recovery")
	await cleanup_pair()
	# Symmetric timeout: a demon with an open resumed socket but no ready ACK
	# remains absent and must not be counted as the connected winner.
	room = await pair(); key = hero.match_id
	ready_flags[demon.get_instance_id()] = false
	demon._network_lost("demon cut")
	check(await until(func(): return room.connection_paused),"demon disconnect held")
	check(await until(func(): return not demon.reconnecting),"demon transport returns")
	check(room.connection_paused and server.rooms[key].seats.demon.deadline > 0,"ready ACK retains original deadline")
	server.rooms[key].seats.demon.deadline = Time.get_ticks_msec()-1
	server._expire_disconnections(key,Time.get_ticks_msec())
	check(await until(func(): return result_count(hero)==1 and result_count(demon)==1),"unready resumed client receives final timeout")
	check(room.winner == "hero" and room.reason == "reconnect_timeout","unready demon cannot win its own timeout")
	await cleanup_pair()
	check(server.rooms.is_empty() and server.resume_tokens.is_empty() and server.reserved_uids.is_empty(),"all recovery resources retired")
	var offline = make_client()
	offline.endpoint_url = "ws://127.0.0.1:24846"; offline.match_id = "offline-server"; offline.resume_token = "1".repeat(RULES.RESUME_TOKEN_BYTES*2)
	offline._network_lost("server unavailable")
	var retry_deadline: int = offline.reconnect_deadline
	offline._network_lost("still unavailable")
	check(offline.reconnect_deadline == retry_deadline,"retry cannot extend client recovery deadline")
	var closed: Array = []; offline.connection_closed.connect(func(message: String): closed.append(message))
	offline.reconnect_deadline = Time.get_ticks_msec()-1; offline._process(0.01)
	check(closed.size()==1 and offline.resume_token.is_empty() and not offline.reconnecting and offline.socket == null,"permanent failure stops retries and erases capability")
	check(result_count(offline)==0,"failed client never invents a winner")
	offline.queue_free()
	server.queue_free(); await process_frame
	print("ONLINE_RECONNECT_PASS checks=",checks)
	quit()
