extends SceneTree
const METRICS := preload("res://src/online/network_metrics.gd")
const WINDOW := preload("res://src/online/metric_window.gd")
const DATA := preload("res://src/data/online_metrics_catalog.gd")
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const ACCESS := preload("res://src/online/local_test_access.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while not condition.call() and Time.get_ticks_msec()<deadline: await process_frame
	return condition.call()
func run() -> void:
	var window=WINDOW.new()
	check(window.report().mean_ms==null,"empty sample is not a zero-latency claim")
	for value in range(1,DATA.SAMPLES+1): window.push(value)
	check(is_equal_approx(window.mean(),float(DATA.SAMPLES+1)/2),"exact rolling mean")
	check(window.report().p95_ms==ceili(DATA.SAMPLES*0.95),"nearest-rank p95")
	window.push(DATA.SAMPLES+1)
	check(window.count==DATA.SAMPLES and window.report().max_ms==DATA.SAMPLES+1,"bounded overwrite")
	window.push(NAN); window.push(-1)
	check(window.count==DATA.SAMPLES,"invalid samples ignored")
	var probe=METRICS.new()
	probe.receive_bytes(100); probe.input_sent(1)
	check(probe.rx_bytes==0 and probe.heartbeat()=={"op":"ping"},"disabled probe does no collection or extra ping data")
	probe.enabled=true
	probe.frame(1000000); probe.frame(1016000); probe.frame(1116000)
	var frames: Dictionary = probe.report("hero")
	check(frames.frame_time.count==2 and frames.frame_max_since_reset_ms==100.0 and frames.frame_stalls_since_reset==1,"frame timing captures stalls since reset")
	probe.reset(); check(probe.report("hero").frame_max_since_reset_ms==null and probe.report("hero").frame_stalls_since_reset==0,"reset clears frame diagnostics")
	var ping: Dictionary=probe.heartbeat()
	probe.ping_at=Time.get_ticks_usec()-25000
	probe.pong({"probe":int(ping.probe)+1})
	check(probe.samples.rtt.count==0,"unmatched pong ignored")
	probe.pong({"probe":ping.probe})
	check(probe.samples.rtt.count==1 and probe.samples.rtt.mean()>=25,"RTT uses local elapsed time")
	probe.pong({"probe":ping.probe})
	check(probe.samples.rtt.count==1,"duplicate pong ignored")
	probe.input_sent(1); probe.sent_at[1]=Time.get_ticks_usec()-5000
	probe.state({"tick":1,"ack":{"hero":1,"demon":99}},"hero")
	check(probe.samples.input.count==1 and probe.samples.input.mean()>=5,"own role input confirmation measured")
	probe.state({"tick":1,"ack":{"hero":1}},"hero")
	check(probe.samples.input.count==1 and probe.samples.gap.count==0,"stale snapshot cannot duplicate samples")
	probe.state({"tick":2,"ack":{"hero":1}},"hero")
	check(probe.samples.gap.count==1,"new state arrival gap sampled")
	probe.transport_reset(); probe.state({"tick":3},"hero")
	check(probe.samples.gap.count==1,"reconnect downtime excluded from arrival gap")
	for sequence in range(1,DATA.INPUT_SLOTS+2): probe.input_sent(sequence)
	probe.state({"tick":4,"ack":{"hero":1}},"hero")
	check(probe.samples.input.count==1,"overwritten input cannot use recycled timestamp")
	probe.receive_bytes(2048); probe.send_bytes(1024); probe.tick_rates(probe.rate_at+DATA.REFRESH_US)
	check(is_equal_approx(probe.rx_kib_s,2.0) and is_equal_approx(probe.tx_kib_s,1.0),"payload KiB/s uses actual bytes and elapsed seconds")
	var safe: Dictionary=probe.report("hero")
	check(not JSON.stringify(safe).contains("token") and not JSON.stringify(safe).contains("endpoint"),"copy schema excludes credentials/endpoint")
	var stats: Dictionary=probe.server_report(1,2,3,4)
	check(DATA.server_valid(stats),"server monitor report validates")
	stats.physics_ms=NAN; check(not DATA.server_valid(stats),"invalid remote monitor ignored")
	probe.reset(); check(probe.samples.input.count==0 and probe.rx_bytes==0 and probe.server.is_empty(),"explicit reset clears local report")
	var old_ping: Dictionary=probe.heartbeat()
	probe.transport_reset(); probe.pong({"probe":old_ping.probe})
	check(probe.samples.rtt.count==0,"old-transport pong cannot become a reconnect sample")
	var quiet=SERVER.new(); root.add_child(quiet)
	check(quiet.start(24853,"127.0.0.1")==OK and not quiet.metrics.enabled,"ordinary authenticated server collection remains off")
	quiet.queue_free(); await process_frame

	# Actual local-test server and UI clients, using the same heartbeat/input path.
	var local=root.get_node("LocalTestMode")
	local.active=true; local.tutorial_preview=false; SCOPE.user_id=""; SCOPE.guest_directory=local.test_directory
	var server=SERVER.new(); root.add_child(server); var ticket:=ACCESS.new_ticket()
	check(server.start(24852,"127.0.0.1",false,ticket)==OK,"metrics server starts with invitation")
	var screens: Array=[]
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options={"role":role}
		var screen=load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(screen); screens.append(screen)
		screen.endpoint.text="ws://127.0.0.1:24852"; screen.test_code.text=ticket; screen._join()
		check(screen.metrics_panel!=null and not screen.metrics_panel.visible,"diagnostics panel starts collapsed")
		screen._toggle_metrics()
	check(await until(func(): return not screens[0].client.match_id.is_empty() and not screens[0].waiting_for_start and not screens[1].waiting_for_start),"both real loading screens complete")
	var key: String=screens[0].client.match_id
	check(await until(func(): return screens[0].client.metrics.samples.input.count>0 and screens[0].client.metrics.samples.rtt.count>0 and screens[0].client.metrics.samples.gap.count>1),"actual RTT/gaps/processed input measured")
	for screen in screens:
		check(await until(func(): return not screen.client.metrics.server.is_empty()),"remote server metrics arrive through pong")
		screen._refresh_metrics()
		check(screen.metrics_label.text.contains("RTT") and screen.metrics_label.text.contains("서버 전체 물리"),"panel displays measured values")
		var report: Variant=JSON.parse_string(screen._metrics_json())
		check(report is Dictionary and report.role==screen.role and report.protocol==RULES.VERSION,"copy report parses for each role")
		check(report.rx_bytes>0 and report.tx_bytes>0 and DATA.server_valid(report.server),"actual transport byte counts and monitor fields")
	check(server.metrics.samples.snapshot.count>0 and server.metrics.samples.encode.count>0,"server build/encode timings sampled")
	var action: Dictionary={"id":"slime","point":[server.rooms[key].node.battle.hero.position.x+300,server.rooms[key].node.battle.hero.position.y]}
	screens[1].client.command("summon",action)
	check(await until(func(): return screens[1].client.metrics.samples.input.count>0),"demon action confirmation sampled")
	print("ONLINE_METRICS_SAMPLE ",screens[0]._metrics_json().replace("\n",""))
	screens[0]._reset_metrics()
	check(screens[0].client.metrics.samples.rtt.count==0,"panel reset works without changing match")
	check(screens[0].client.match_id==key and server.rooms[key].node.running,"measurement reset preserves gameplay")
	for screen in screens: screen.client.close(); screen.queue_free()
	server.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("ONLINE_METRICS_PASS checks=",checks); quit()
