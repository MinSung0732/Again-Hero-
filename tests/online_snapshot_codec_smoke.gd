extends SceneTree
const CODEC := preload("res://src/online/snapshot_codec.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func command(path: String) -> Array:
	return [0,path,1,2,16,18,-1,0,0,1,100,200,-8,-9,16,18,1,0.5,0.25,0.8,3,220]
func sample(count: int,unique: bool = false) -> Dictionary:
	var commands: Array = []
	for index in count: commands.append(command("res://assets/art/검증/frames/frame_%02d.png"%(index if unique else 0)))
	return {"op":"state","match":"codec-fixture","tick":3,"hero":[100,200,90,100,1],"actors":[],"bounds":[3600,3600],"visuals":commands,"ack":{"hero":7,"demon":2},"feedback":[],"feedback_cursor":0}
func until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while not condition.call() and Time.get_ticks_msec()<deadline: await process_frame
	return condition.call()
func stop_audio(host: Node) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stream_paused=false; player.stop(); player.stream=null
func run() -> void:
	var codec = CODEC.new()
	for count in [0,1,ART.MAX_COMMANDS]:
		var original := sample(count,true)
		check(codec.encode(original)==SERVER._encode(original) and not codec.used_table,"unique paths never inflate the packet")
	var state := sample(ART.MAX_COMMANDS)
	var source := JSON.stringify(state)
	var packed: String = codec.encode(state)
	check(codec.used_table and packed.to_utf8_buffer().size()<source.to_utf8_buffer().size(),"repeated UTF8 paths save actual bytes")
	check(source.to_utf8_buffer().size()-packed.to_utf8_buffer().size()==codec.saved_bytes,"exact quoted-key/UTF8/index byte accounting")
	check(JSON.stringify(state)==source,"encoder never mutates original transforms/paths/events/ack")
	var decoded := RULES.decode(packed.to_utf8_buffer(),RULES.MAX_SNAPSHOT)
	check(decoded[ART.PATH_TABLE_FIELD].size()==1 and decoded.visuals[0][ART.PATH_INDEX]==0,"one packet-local definition per repeated path")
	check(CODEC.expand(decoded) and decoded==RULES.decode(source.to_utf8_buffer(),RULES.MAX_SNAPSHOT),"all22 fields and nonvisual state roundtrip losslessly")
	var first := packed
	var other := sample(10)
	for row in other.visuals: row[ART.PATH_INDEX]="res://assets/art/different.png"
	var second: String = codec.encode(other)
	check(first==packed and JSON.stringify(state)==source,"reuse of cached row buffers does not change old strings/input")
	var newer := RULES.decode(second.to_utf8_buffer(),RULES.MAX_SNAPSHOT)
	var older := RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT)
	check(CODEC.expand(newer) and CODEC.expand(older) and newer.visuals[0][1]!=older.visuals[0][1],"packet order or fresh decoder cannot confuse texture IDs")
	for raw_table in [null,"bad",["https://invalid/x.png"],["res://assets/art/../secret.png"],["res://src/a.png"],["res://assets/art/a.wav"],["res://assets/art/"+"x".repeat(ART.MAX_PATH_LENGTH)+".png"]]:
		var bad := RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT); bad[ART.PATH_TABLE_FIELD]=raw_table
		var before := JSON.stringify(bad)
		check(not CODEC.expand(bad) and JSON.stringify(bad)==before,"bad path table rejected atomically")
	var big := RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT)
	big[ART.PATH_TABLE_FIELD].resize(ART.MAX_COMMANDS+1)
	check(not CODEC.expand(big),"path table bounded by command budget")
	for invalid in [-1,1,0.5,true,NAN,INF,"0",null]:
		var bad := RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT); bad.visuals[-1][ART.PATH_INDEX]=invalid
		var before := JSON.stringify(bad)
		check(not CODEC.expand(bad) and JSON.stringify(bad)==before,"bad final index never partially expands earlier commands")
	var bad := RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT); bad.visuals[0][6]=NAN
	check(not CODEC.expand(bad),"indexed geometry still uses shared finite field validation")
	bad = RULES.decode(first.to_utf8_buffer(),RULES.MAX_SNAPSHOT); bad.visuals[0][4]=0
	check(not CODEC.expand(bad),"indexed source extents retain original limits")
	bad = sample(ART.MAX_COMMANDS+1)
	check(codec.encode(bad).is_empty() and not CODEC.expand(bad),"command overflow rejected in both directions")
	bad = sample(2); bad[ART.PATH_TABLE_FIELD]=[]
	check(codec.encode(bad).is_empty(),"preindexed server input cannot leak across encoder calls")
	bad = sample(2); bad["oversized"]="x".repeat(RULES.MAX_SNAPSHOT)
	check(codec.encode(bad).is_empty(),"final encoded UTF8 payload budget preserved")
	var control := {"op":"result","winner":"hero","feedback":[],"feedback_cursor":0}
	check(codec.encode(control)==SERVER._encode(control) and not codec.used_table,"control/result packets unchanged")
	# Actual WebSocket pair: repeated bodies, both sides normalize, then seat resume.
	var server = SERVER.new(); root.add_child(server)
	check(server.start(24849,"127.0.0.1",true)==OK,"codec integration loopback server")
	var hero = CLIENT.new(); var demon = CLIENT.new(); root.add_child(hero); root.add_child(demon)
	var received := {"hero":[],"demon":[]}
	for client in [hero,demon]:
		var role: String = "hero" if client==hero else "demon"
		client.event_received.connect(func(event: Dictionary):
			if event.op=="matched": client.send({"op":"ready","match":client.match_id})
			if event.op=="state": received[role].append(event))
		check(client.join("ws://127.0.0.1:24849","fixture_"+role,role)==OK,"codec integration client")
	check(await until(func(): return not hero.match_id.is_empty() and server.rooms.has(hero.match_id) and server.rooms[hero.match_id].node.running),"codec pair starts authoritative battle")
	var key: String = hero.match_id; var room = server.rooms[key].node
	stop_audio(room); stop_audio(root.get_node("GameAudio"))
	room.battle.set_external_pause(true)
	for index in room.battle.get_population_limit()/2:
		room.battle._spawn_monster(RULES.ROSTER[0],room.battle.hero.position+Vector2(300+index,0))
	check(await until(func(): return server.rooms[key].codec.used_table and not received.hero.is_empty() and received.hero[-1].actors.size()==room.battle.get_population_limit()/2 and not received.demon.is_empty() and received.demon[-1].actors.size()==room.battle.get_population_limit()/2),"both real clients receive packed roster state")
	for role in received:
		var event: Dictionary = received[role][-1]
		var valid := not event.has(ART.PATH_TABLE_FIELD)
		for row in event.visuals: valid = valid and ART.valid(row)
		check(valid,"render/event consumers see original path strings only")
	var before_count: int = received.hero.size()
	hero._network_lost("codec fixture reconnect")
	check(await until(func(): return hero.socket!=null and not hero.reconnecting and received.hero.size()>before_count and received.hero[-1].actors.size()==room.battle.get_population_limit()/2),"fresh socket immediately decodes same-room recovery state")
	check(hero.match_id==key and server.rooms.size()==1,"codec recovery preserves authoritative room")
	# An old protocol must fail at join rather than misrender indexed rows.
	var old := WebSocketPeer.new(); old.connect_to_url("ws://127.0.0.1:24849")
	check(await until(func(): old.poll(); return old.get_ready_state()==WebSocketPeer.STATE_OPEN),"old-protocol probe connects")
	old.send_text(JSON.stringify({"op":"join","version":RULES.VERSION-1,"rules":RULES.ID,"role":"hero","token":"fixture_third"}))
	check(await until(func(): old.poll(); return old.get_available_packet_count()>0 or old.get_ready_state()==WebSocketPeer.STATE_CLOSED),"old-protocol rejection delivered")
	var denied := old.get_close_code()==1008 and old.get_close_reason()=="version_mismatch"
	if old.get_ready_state()==WebSocketPeer.STATE_OPEN and old.get_available_packet_count()>0: denied = RULES.decode(old.get_packet()).get("reason","")=="version_mismatch"
	check(denied,"protocol mismatch rejected before auth/queue")
	old.close(); hero.close(); demon.close(); stop_audio(server); stop_audio(root.get_node("GameAudio"))
	hero.queue_free(); demon.queue_free(); server.queue_free(); await process_frame
	var retired := Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<retired: await process_frame
	print("ONLINE_SNAPSHOT_CODEC_PASS checks=",checks); quit()
