extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const RULES := preload("res://src/online/match_rules.gd")
var mode := ""
var metrics_mode := false
var server
var client
var age := 0.0
var input_left := 0.0
var ended_age := 0.0
var states := 0
var sent_summon := false
func _initialize() -> void: start.call_deferred()
func start() -> void:
	var arguments := OS.get_cmdline_user_args()
	mode = arguments[0] if not arguments.is_empty() else ""
	metrics_mode = "--metrics" in arguments
	if mode == "server":
		server = SERVER.new(); root.add_child(server)
		if server.start(24843,"127.0.0.1",true) != OK: quit(1); return
		print("ONLINE_PROCESS_SERVER_READY")
	elif mode in ["hero","demon"]:
		client = CLIENT.new(); root.add_child(client); client.event_received.connect(event)
		client.connection_closed.connect(func(_message: String): quit(1))
		if client.join("ws://127.0.0.1:24843","fixture_"+mode,mode) != OK: quit(1)
		client.metrics.enabled=metrics_mode
	else: quit(1)
func event(value: Dictionary) -> void:
	if value.op == "matched": client.send({"op":"ready","match":client.match_id})
	elif value.op == "state":
		states += 1
		if metrics_mode and states==1: client.metrics.reset()
		if mode == "demon" and not sent_summon:
			sent_summon = true
			client.command("summon",{"id":"slime","point":[value.hero[0]+300,value.hero[1]]})
	elif value.op == "result":
		if value.winner != "hero" or states < 5 or value.rated: quit(1); return
		var result := {"role":mode,"match":value.match,"winner":value.winner,"states":states}
		if metrics_mode:
			var report: Dictionary=client.metrics.report(mode)
			if report.rtt.count==0 or report.input_confirmation.count==0 or report.state_gap.count<5 or report.server.is_empty() or report.server.snapshot_samples==0:
				push_error("Separate-process transport metrics missing"); quit(1); return
			result["metrics"]=report
		print("ONLINE_PROCESS_CLIENT_PASS ",JSON.stringify(result))
		client.close(); quit()
	elif value.op == "error": quit(1)
func _process(delta: float) -> bool:
	age += delta
	if age > 18: quit(1); return false
	if mode == "server" and server != null:
		for item in server.rooms.values():
			var room = item.node
			if room.running and not room.has_meta("short_test_clock"):
				# Test-only clock change; the shipped rule stays180s.
				room.set_meta("short_test_clock",true); room.battle.run_metrics.elapsed_seconds = RULES.DURATION-3
			if room.finished:
				ended_age += delta
				if ended_age > 0.6: _shutdown_server()
	elif mode == "hero" and client != null and not client.match_id.is_empty():
		input_left -= delta
		if input_left <= 0: input_left = 0.05; client.command("move",[0,1])
	return false

func _shutdown_server() -> void:
	# Let child worlds/audio callbacks retire before the process tears down.
	var retiring = server; server = null
	retiring.queue_free()
	await process_frame; await create_timer(0.2).timeout
	print("ONLINE_PROCESS_SERVER_PASS"); quit()
