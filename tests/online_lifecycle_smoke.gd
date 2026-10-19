extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const ACCESS := preload("res://src/online/local_test_access.gd")
const RULES := preload("res://src/online/match_rules.gd")
var server
var hero
var demon
var ticket := ""
var events := {}
var auto_ready := {}
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func pump(seconds: float) -> void:
	var until_ms := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<until_ms: await process_frame
func until(condition: Callable) -> bool:
	var until_ms := Time.get_ticks_msec()+6000
	while not condition.call() and Time.get_ticks_msec()<until_ms: await process_frame
	return condition.call()
func make_client():
	var client = CLIENT.new(); root.add_child(client)
	var id: int = client.get_instance_id(); events[id] = []; auto_ready[id] = true
	client.event_received.connect(func(event: Dictionary):
		events[id].append(event)
		if event.get("op","") == "matched" and auto_ready[id]: client.send({"op":"ready","match":client.match_id}))
	return client
func count_results(client,key: String) -> int:
	var count := 0
	for event in events[client.get_instance_id()]:
		if event.get("op","") == "result" and event.get("match","") == key: count += 1
	return count
func join_pair(ready: bool = true) -> String:
	auto_ready[hero.get_instance_id()] = ready; auto_ready[demon.get_instance_id()] = ready
	check(hero.join_local_test("ws://127.0.0.1:24848",ticket,"hero") == OK,"hero joins invitation server")
	check(demon.join_local_test("ws://127.0.0.1:24848",ticket,"demon") == OK,"demon joins invitation server")
	check(await until(func(): return not hero.match_id.is_empty() and hero.match_id == demon.match_id and server.rooms.has(hero.match_id) and (server.rooms[hero.match_id].node.running if ready else true)),"pair shares prepared/running real room")
	return hero.match_id
func retire_room(key: String) -> void:
	check(server.rooms[key].node.finished,"only finished room may retire")
	server.rooms[key].ended = Time.get_ticks_msec()-int((RULES.RESULT_RETENTION+1)*1000)
	server._process(0.0); await process_frame
	check(not server.rooms.has(key),"expired receipt and room retired")
func run() -> void:
	server = SERVER.new(); root.add_child(server); ticket = ACCESS.new_ticket()
	check(server.start(24848,"127.0.0.1",false,ticket) == OK,"real invitation server")
	hero = make_client(); demon = make_client()
	# A live socket that never acknowledged preparation cannot win a timeout.
	var key: String = await join_pair(false)
	var room = server.rooms[key].node
	demon._network_lost("pre-ready loss"); demon.set_process(false)
	check(await until(func(): return room.connection_paused),"unready disconnect enters grace")
	server.rooms[key].seats.demon.deadline = Time.get_ticks_msec()-1
	server._expire_disconnections(key,Time.get_ticks_msec())
	check(room.finished and room.winner.is_empty() and room.reason == "both_disconnected","unready surviving socket cannot receive a free win")
	demon.set_process(true); demon.next_retry = 0
	check(await until(func(): return count_results(hero,key)==1 and count_results(demon,key)==1),"both recover single void result")
	hero.close(); demon.close()
	check(await until(func(): return server.peers.is_empty()),"post-result transports removed")
	await retire_room(key)
	# Cancellation does not poison a later queue entry for the same identity.
	for cycle in 3:
		check(hero.join_local_test("ws://127.0.0.1:24848",ticket,"hero") == OK,"queue join")
		check(await until(func(): return server.queue.members.size()==1),"one player waits")
		hero.close()
		check(await until(func(): return server.queue.members.is_empty() and server.peers.is_empty()),"cancel removes queue entry and socket")
		check(server.rooms.is_empty() and server.reserved_uids.is_empty(),"cancel creates no room/reservation")
	# Both lose transport; one return alone must keep the original battle paused.
	key = await join_pair(); room = server.rooms[key].node
	var instance: int = room.get_instance_id()
	hero._network_lost("both lost"); demon._network_lost("both lost")
	hero.set_process(false); demon.set_process(false)
	check(await until(func(): return room.connection_paused and server.peers.is_empty()),"both old transports removed")
	var frozen: int = room.tick
	hero.set_process(true); hero.next_retry = 0
	check(await until(func(): return not hero.reconnecting),"first participant returns")
	check(room.connection_paused and room.tick == frozen,"one return cannot advance battle")
	demon.set_process(true); demon.next_retry = 0
	check(await until(func(): return not demon.reconnecting and not room.connection_paused and room.tick>frozen),"second ready resumes battle")
	check(room.get_instance_id() == instance and hero.match_id == key and demon.match_id == key,"both resume same instance")
	# Explicit leave must survive immediate destruction of the outgoing client.
	var previous_session: String = hero.local_session
	var old_tokens: Array = [hero.resume_token,demon.resume_token]
	hero.close(); hero.queue_free()
	check(await until(func(): return room.finished and count_results(demon,key)==1),"leave drains across client destruction")
	check(room.winner == "demon" and room.reason == "opponent_left","explicit exit yields one opponent victory")
	check(server.reserved_uids.is_empty(),"finished match releases identities immediately")
	hero = make_client(); hero.local_session = previous_session
	var next_key: String = await join_pair()
	var next_room = server.rooms[next_key].node
	check(next_key != key and next_room != room,"immediate rematch creates fresh room")
	check(server.rooms.size()==2 and next_room.running,"retained receipt and new live match coexist")
	await retire_room(key)
	for token in old_tokens: check(not server.resume_tokens.has(token),"old capability erased")
	for seat in server.rooms[next_key].seats.values():
		check(server.reserved_uids.get(seat.uid,"") == next_key and server.resume_tokens.has(seat.resume_token),"old cleanup preserves new seat reservation/capability")
	check(next_room.running and not next_room.connection_paused and server.peers.size()==2,"old cleanup cannot drop rematched peers")
	var stale = make_client()
	stale.endpoint_url = "ws://127.0.0.1:24848"; stale.match_id = key; stale.resume_token = old_tokens[0]
	stale._network_lost("retired room"); stale.set_process(true); stale.next_retry = 0
	check(await until(func(): return stale.resume_token.is_empty()),"retired capability rejected")
	check(next_room.running and not next_room.connection_paused,"stale recovery does not affect current match")
	stale.close(); stale.queue_free()
	# Actual battle completion is terminal even if duplicate signals/packets arrive.
	next_room.battle._on_run_time_up()
	check(await until(func(): return count_results(hero,next_key)==1 and count_results(demon,next_key)==1),"rematched participants receive result once")
	next_room.finish("demon","duplicate")
	for peer in server.rooms[next_key].members: server._send_result(peer,next_key)
	await pump(0.1)
	check(next_room.winner == "hero" and count_results(hero,next_key)==1 and count_results(demon,next_key)==1,"duplicate result cannot overwrite or redisplay")
	hero.close(); demon.close()
	check(await until(func(): return server.peers.is_empty()),"all clients leave")
	await retire_room(next_key)
	check(server.rooms.is_empty() and server.queue.members.is_empty() and server.reserved_uids.is_empty() and server.resume_tokens.is_empty(),"all match resources retired")
	hero.queue_free(); demon.queue_free(); server.queue_free(); await pump(0.2)
	print("ONLINE_LIFECYCLE_PASS checks=",checks); quit()
