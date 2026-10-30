extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok, message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room = ROOM.new(); root.add_child(room)
	room.set_loadouts({"hero_id":RULES.HERO},{"team_ids":["slime","spider","orc"],"skill_ids":[],"transcendence_id":"zeus"})
	room.prepare(); room.start(); room.battle.process_mode = Node.PROCESS_MODE_DISABLED
	var server = SERVER.new(); root.add_child(server); server.set_process(false); server.set_physics_process(false)
	server.test_auth = true
	server.rooms["test"] = {"node":room,"rated":true}
	server.peers[1] = {"uid":"fixture","role":"demon","room":"test","seq":0,"socket":WebSocketPeer.new()}
	var input := {"op":"input","match":"test","seq":1,"kind":"transcend_unlock_test","argument":{}}
	server._receive(1,input)
	check(not room.snapshot().transcend_ready,"rated room rejects test unlock")
	server.rooms.test.rated = false; server.peers[1].role = "hero"; input.seq = 2; server._receive(1,input)
	check(not room.snapshot().transcend_ready,"hero rejects test unlock")
	server.peers[1].role = "demon"; server.test_auth = false; input.seq = 3; server._receive(1,input)
	check(not room.snapshot().transcend_ready,"unrated room without test authentication rejects unlock")
	server.test_auth = true; input.seq = 4; server._receive(1,input)
	check(room.snapshot().transcend_ready,"test room unlock reaches snapshot")
	check(not room.apply("demon","transcend_unlock_test",{},true),"repeat unlock rejected")
	input.seq = 2147483647; server._receive(1,input)
	check(int(server.peers[1].seq) == 4,"oversized sequence jump cannot lock the seat")
	input.seq = 5; server._receive(1,input)
	check(int(server.peers[1].seq) == 5,"next sequence still accepted")
	root.get_node("SceneTransition")._entry_options = {"role":"demon"}
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	await process_frame
	scene.transcendence_id = "zeus"
	var state := {"mana":0.0,"summon_costs":{},"demon_charge":0.0,"demon_charge_max":100.0,"demon_cooldowns":{},"demon_ready":{},"transcend_ready":false,"transcend_used":false}
	scene.initial_local_test = false; scene._update_demon_controls(state)
	check(not scene.transcendence_view.unlock_button.visible,"normal client hides button")
	scene.initial_local_test = true; scene.skill_state_signature = ""; scene._update_demon_controls(state)
	check(scene.transcendence_view.unlock_button.visible,"local test client shows button")
	state.transcend_ready = true; scene._update_demon_controls(state)
	check(not scene.transcendence_view.unlock_button.visible,"ready state hides button")
	state.transcend_ready = false; state.transcend_used = true; scene._update_demon_controls(state)
	check(not scene.transcendence_view.unlock_button.visible,"used state hides button")
	scene.queue_free(); server.rooms.clear(); server.peers.clear(); server.queue_free(); room.finish("","test"); room.queue_free()
	print("ONLINE_TRANSCEND_UNLOCK_PASS checks=",checks); quit()
