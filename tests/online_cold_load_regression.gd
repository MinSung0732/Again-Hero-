extends SceneTree
const SERVER = preload("res://src/online/match_server.gd")
const CLIENT = preload("res://src/online/match_client.gd")
const RULES = preload("res://src/online/match_rules.gd")
var server
var client
var role := ""
var results := 0
var failed := false
var started := false
var deadline := 0
func _initialize(): run.call_deferred()
func fail(message: String):
	failed = true; push_error(message); quit(1)
func run():
	role = OS.get_cmdline_user_args()[0]
	deadline = Time.get_ticks_msec()+35000
	if role == "server":
		server = SERVER.new(); root.add_child(server)
		if server.start(24849,"127.0.0.1",true) != OK: fail("bind failed"); return
		print("COLD_LOAD_SERVER_READY")
	else:
		client = CLIENT.new(); root.add_child(client)
		client.connection_recovering.connect(func(active, _remaining):
			if active: fail("cold loading incorrectly triggers recovery: "+role))
		client.connection_closed.connect(func(message): fail(role+": "+message))
		client.event_received.connect(receive)
		client.join("ws://127.0.0.1:24849","fixture_"+role,role)
func receive(event: Dictionary):
	if event.op == "matched":
		if role == "demon": OS.delay_msec(int((RULES.PEER_IDLE_TIMEOUT+0.5)*1000))
		client.send({"op":"ready","match":client.match_id})
	if event.op == "result":
		results += 1
		if event.reason != "cold_load_complete" or event.winner != "": fail("loading yielded false match result: "+role); return
		if results != 1: fail("duplicate result"); return
		print("COLD_LOAD_CLIENT_PASS role=",role); client.close(); quit()
func _process(_delta):
	if failed: return true
	if Time.get_ticks_msec() > deadline: fail("test timed out: "+role); return true
	if role == "server" and server != null:
		for value in server.rooms.values():
			if value.node.finished and not started: fail("room ended while loading"); return true
			if value.node.running and value.node.tick > 3:
				started = true
				value.node.finish("","cold_load_complete")
		if started and server.peers.is_empty():
			print("COLD_LOAD_SERVER_PASS"); quit()
	return false
