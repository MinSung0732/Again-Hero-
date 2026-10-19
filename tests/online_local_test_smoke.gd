extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const ACCESS := preload("res://src/online/local_test_access.gd")
var checks := 0
var failures := 0
class AuthSpy extends Node:
	var calls := 0
	func verify(token: String) -> String:
		calls += 1
		return "verified-account" if token == "verified-fixture-jwt" else ""
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline: await process_frame
func rejected(events: Array, reason: String) -> bool:
	for event in events:
		if event.get("op", "") == "error" and event.get("reason", "") == reason: return true
	return false
func run() -> void:
	var ticket := ACCESS.new_ticket()
	var other_ticket := ACCESS.new_ticket()
	var session := ACCESS.new_session()
	check(ticket != other_ticket and ACCESS.valid_hex(ticket, ACCESS.TICKET_BYTES), "fresh server invitation")
	check(ACCESS.session_uid({"ticket":ticket,"session":session},ticket) == ACCESS.UID_PREFIX + session,"valid credentials")
	for credentials in [{}, {"ticket":other_ticket,"session":session}, {"ticket":ticket,"session":""}, {"ticket":42,"session":session}, {"ticket":ticket,"session":[]}, {"ticket":ticket,"session":"z".repeat(32)}]:
		check(ACCESS.session_uid(credentials,ticket).is_empty(),"invalid credentials denied")
	check(ACCESS.session_uid({"ticket":ticket,"session":session},"").is_empty(),"default server disables invitations")
	check(ACCESS.session_uid({"ticket":ticket,"session":session},other_ticket).is_empty(),"restarted server invalidates old code")
	var server = SERVER.new(); root.add_child(server)
	check(server.start(24844,"0.0.0.0",false,ticket) == ERR_UNAUTHORIZED,"invitation refuses public bind")
	check(server.start(24844,"127.0.0.1",false,"short") == ERR_UNAUTHORIZED,"malformed invitation rejected")
	check(server.start(24844,"127.0.0.1",true,ticket) == ERR_UNAUTHORIZED,"fixture bypass and invitation cannot mix")
	check(server.start(24844) == OK,"normal server")
	var guest = CLIENT.new(); root.add_child(guest)
	var guest_events: Array = []
	guest.event_received.connect(func(event: Dictionary): guest_events.append(event))
	check(guest.join_local_test("ws://127.0.0.1:24844",ticket,"hero") == OK,"local client attempts normal server")
	await pump(0.3)
	check(rejected(guest_events,"local_test_denied") and server.queue.members.is_empty(),"normal server rejects local invitation")
	guest.close(); guest.queue_free()
	# Real-account route remains delegated to the original verifier API.
	server.auth.queue_free()
	var auth = AuthSpy.new(); server.add_child(auth); server.auth = auth
	var ordinary = CLIENT.new(); root.add_child(ordinary)
	ordinary.join("ws://127.0.0.1:24844","verified-fixture-jwt","hero")
	await pump(0.3)
	check(auth.calls == 1 and server.queue.members.size() == 1,"ordinary auth still verifies and queues")
	ordinary.close(); ordinary.queue_free(); server.queue_free(); await pump(0.1)
	server = SERVER.new(); root.add_child(server)
	check(server.start(24844,"127.0.0.1",false,ticket) == OK,"explicit invitation server")
	var bad = CLIENT.new(); root.add_child(bad)
	var bad_events: Array = []
	bad.event_received.connect(func(event: Dictionary): bad_events.append(event))
	bad.join_local_test("ws://127.0.0.1:24844",other_ticket,"hero"); await pump(0.3)
	check(rejected(bad_events,"local_test_denied") and server.queue.members.is_empty(),"wrong code cannot queue")
	bad.close(); bad.queue_free()
	var hero = CLIENT.new(); var demon = CLIENT.new(); root.add_child(hero); root.add_child(demon)
	var hero_events: Array = []; var demon_events: Array = []
	hero.event_received.connect(func(event: Dictionary):
		hero_events.append(event)
		if event.get("op","") == "matched": hero.send({"op":"ready","match":hero.match_id}))
	demon.event_received.connect(func(event: Dictionary):
		demon_events.append(event)
		if event.get("op","") == "matched": demon.send({"op":"ready","match":demon.match_id}))
	check(hero.join_local_test("ws://127.0.0.1:24844",ticket,"hero") == OK,"local hero joins")
	await pump(0.3)
	check(server.queue.members.size() == 1 and hero.local_ticket.is_empty() and hero.token.is_empty(),"queued credentials erased after handshake")
	check(demon.join_local_test("ws://127.0.0.1:24844",ticket,"demon") == OK,"local demon joins")
	var ready_deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < ready_deadline:
		await pump(0.05)
		if not server.rooms.is_empty() and server.rooms.values()[0].node.running: break
	check(hero.local_session != demon.local_session,"two localtest devices have distinct identities")
	check(not hero.match_id.is_empty() and hero.match_id == demon.match_id and server.rooms.size() == 1,"one authoritative room")
	if not server.rooms.is_empty():
		var room = server.rooms.values()[0].node
		check(room.running,"ready starts actual Battle")
		var origin: Vector2 = room.battle.hero.position
		for index in 5: hero.command("move",[1,0]); await pump(0.05)
		check(room.battle.hero.position.x > origin.x,"local remote movement")
		var point: Vector2 = room.battle.hero.position + Vector2(300,0)
		demon.command("summon",{"id":"slime","point":[point.x,point.y]}); await pump(0.2)
		check(not room.battle.active_monsters.is_empty(),"local remote summon")
		var duplicate = CLIENT.new(); root.add_child(duplicate); duplicate.local_session = hero.local_session
		var duplicate_events: Array = []
		duplicate.event_received.connect(func(event: Dictionary): duplicate_events.append(event))
		duplicate.join_local_test("ws://127.0.0.1:24844",ticket,"hero"); await pump(0.3)
		check(rejected(duplicate_events,"duplicate_account") and room.running,"duplicate test session rejected")
		duplicate.close(); duplicate.queue_free()
		room.finish("hero","local_test_complete"); await pump(0.2)
		for events in [hero_events,demon_events]:
			var results := 0
			for event in events:
				if event.get("op","") == "result":
					results += 1
					check(event.winner == "hero" and not event.rated,"unrated authoritative result")
			check(results == 1,"one result per local client")
	hero.close(); demon.close(); hero.queue_free(); demon.queue_free(); server.queue_free(); await pump(0.1)
	print("ONLINE_LOCAL_TEST_PASS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
