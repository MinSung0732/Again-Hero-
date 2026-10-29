extends SceneTree
## Compare identical paused real snapshots. Does not measure gameplay FPS/WSS.
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
const RULES := preload("res://src/online/match_rules.gd")
const WINDOW := preload("res://src/online/metric_window.gd")
const TRIALS := 96
func _initialize() -> void: run.call_deferred()
func stop_audio(host: Node) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stream_paused=false; player.stop(); player.stream=null
func run() -> void:
	root.get_node("CloudStore").stop()
	var rows: Array = []
	for count in [0,50,100]:
		var room = ROOM.new(); root.add_child(room); room.prepare()
		stop_audio(room); stop_audio(root.get_node("GameAudio"))
		for index in int(count):
			var actor = room.battle._spawn_monster(RULES.ROSTER[index%RULES.ROSTER.size()],room.battle.hero.position+Vector2(200+index*5,50))
			if not is_instance_valid(actor): push_error("fixture actor spawn"); quit(1); return
		room.start()
		for frame in 6: await physics_frame
		room.set_connection_paused(true)
		var state: Dictionary = room.snapshot(); state["match"]="codec-benchmark"
		if state.actors.size()!=int(count): push_error("fixture population changed"); quit(1); return
		var codec = CODEC.new()
		var before_encode = WINDOW.new(); var after_encode = WINDOW.new()
		var before_decode = WINDOW.new(); var after_decode = WINDOW.new()
		var plain := ""; var packed := ""
		for trial in TRIALS+8:
			# Alternate order so warm caches/scheduling do not always favor one path.
			for compact in ([false,true] if trial%2==0 else [true,false]):
				var start := Time.get_ticks_usec()
				var wire: String = codec.encode(state) if compact else SERVER._encode(state)
				var encode_ms := (Time.get_ticks_usec()-start)/1000.0
				var bytes := wire.to_utf8_buffer()
				start = Time.get_ticks_usec()
				var restored := RULES.decode(bytes,RULES.MAX_SNAPSHOT)
				if compact and not CODEC.expand(restored): push_error("fixture expand rejected"); quit(1); return
				var decode_ms := (Time.get_ticks_usec()-start)/1000.0
				if restored!=RULES.decode(JSON.stringify(state).to_utf8_buffer(),RULES.MAX_SNAPSHOT): push_error("lossless roundtrip changed state"); quit(1); return
				if compact: packed=wire
				else: plain=wire
				if trial>=8:
					(after_encode if compact else before_encode).push(encode_ms)
					(after_decode if compact else before_decode).push(decode_ms)
		var old_size := plain.to_utf8_buffer().size(); var new_size := packed.to_utf8_buffer().size()
		if new_size>old_size: push_error("codec inflated payload"); quit(1); return
		rows.append({"actors":state.actors.size(),"commands":state.visuals.size(),"used_table":codec.used_table,"plain_bytes":old_size,"packed_bytes":new_size,"saved_percent":100.0*(old_size-new_size)/old_size,"plain_encode":before_encode.report(),"packed_encode":after_encode.report(),"plain_decode":before_decode.report(),"packed_decode_and_expand":after_decode.report()})
		stop_audio(room); stop_audio(root.get_node("GameAudio"))
		room.queue_free(); await process_frame
		var retired := Time.get_ticks_msec()+200
		while Time.get_ticks_msec()<retired: await process_frame
	print("ONLINE_SNAPSHOT_BENCH ",JSON.stringify({"engine":Engine.get_version_info().string,"protocol":RULES.VERSION,"trials":TRIALS,"cpu_only":true,"scope":"same paused Battle snapshots; mixed roster via direct fixture spawn; encode includes UTF8 size check; decode includes JSON parse, new path validation/expansion; excludes snapshot generation, view/draw, socket/TLS, audio and continuing combat","rows":rows}))
	quit()
