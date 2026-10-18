extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
var server
var hero
var demon
var hero_events: Array = []
var demon_events: Array = []
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec() < deadline: await process_frame
func run() -> void:
	server = SERVER.new(); root.add_child(server)
	check(server.start(24842,"0.0.0.0",true) == ERR_UNAUTHORIZED,"fixture auth rejects public bind")
	check(server.start(24842,"127.0.0.1",true) == OK,"loopback listener")
	hero = CLIENT.new(); demon = CLIENT.new(); root.add_child(hero); root.add_child(demon)
	hero.event_received.connect(func(event: Dictionary):
		hero_events.append(event)
		if event.get("op","") == "matched": hero.send({"op":"ready","match":hero.match_id}))
	demon.event_received.connect(func(event: Dictionary):
		demon_events.append(event)
		if event.get("op","") == "matched": demon.send({"op":"ready","match":demon.match_id}))
	check(hero.join("ws://127.0.0.1:24842","fixture_hero","hero") == OK,"hero joins")
	await pump(0.3)
	check(server.rooms.is_empty(),"one player cannot start")
	check(demon.join("ws://127.0.0.1:24842","fixture_demon","demon") == OK,"demon joins")
	await pump(2)
	check(server.rooms.size() == 1,"network pair creates room")
	check(not hero.match_id.is_empty() and hero.match_id == demon.match_id,"same match ID")
	var room = server.rooms[hero.match_id].node
	check(room.running,"both ready starts actual Battle")
	var origin: Vector2 = room.battle.hero.position
	for i in 8: hero.command("move",[1,0]); await pump(0.05)
	check(room.battle.hero.position.x > origin.x,"remote move actual hero")
	var spawn: Vector2 = room.battle.hero.position+Vector2(300,0)
	demon.command("summon",{"id":"slime","point":[spawn.x,spawn.y]}); await pump(0.1)
	check(not room.battle.active_monsters.is_empty(),"remote summon actual monster")
	var before: int = room.tick
	await pump(0.3)
	check(room.tick > before,"server advances battle")
	var states := 0
	for event in hero_events:
		if event.op == "state": states += 1
	check(states > 2,"repeated authoritative state")
	var duplicate = CLIENT.new(); root.add_child(duplicate)
	var duplicate_events: Array = []
	duplicate.event_received.connect(func(event: Dictionary): duplicate_events.append(event))
	duplicate.join("ws://127.0.0.1:24842","fixture_hero","hero"); await pump(0.3)
	var rejected := false
	for event in duplicate_events:
		if event.op == "error" and event.reason == "duplicate_account": rejected = true
	check(rejected and room.running,"duplicate account rejected without disturbing room")
	duplicate.close(); duplicate.queue_free()
	var queued = CLIENT.new(); root.add_child(queued)
	queued.join("ws://127.0.0.1:24842","fixture_third","hero"); await pump(0.2)
	check(server.queue.members.size() == 1 and server.rooms.size() == 1,"same role waits")
	queued.close(); await pump(0.2)
	check(server.queue.members.is_empty(),"queue cancellation")
	queued.queue_free()
	var seq: int = server.peers.values()[0].seq
	hero.send({"op":"input","match":hero.match_id,"seq":seq,"kind":"move","argument":[0,-1]})
	hero.command("summon",{"id":"slime","point":[spawn.x,spawn.y]}); await pump(0.1)
	check(room.battle.hero.player_move_input.y == 0,"replayed move rejected")
	demon.close(); await pump(0.4)
	check(room.finished and room.winner == "hero","disconnect result")
	var received := false
	for event in hero_events:
		if event.op == "result": received = event.winner == "hero" and event.rated == false
	check(received,"authoritative result delivered")
	hero.close(); server.queue_free(); hero.queue_free(); demon.queue_free(); await process_frame
	print("ONLINE_WEBSOCKET_REAL_BATTLE_PASS checks=",checks); quit()
