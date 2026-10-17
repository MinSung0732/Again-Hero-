extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
func _initialize() -> void: run.call_deferred()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func work(rooms: Array,optimized: bool) -> void:
	for repeat in 80:
		for index in rooms.size():
			var state: Dictionary = rooms[index].snapshot(); state["match"] = "room_"+str(index)
			# Two recipients, exactly the same state. Includes UTF8 size validation.
			for recipient in (1 if optimized else 2): SERVER._encode(state)
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase3/battle_room_before.gd.txt")
	if script.reload() != OK: quit(1); return
	var rooms: Array = []; var previous: Array = []; var rows: Array = []
	for room_count in [1,2,8]:
		while rooms.size() < room_count:
			var room := ROOM.new(); root.add_child(room); room.prepare(); room.battle.hero_player_mode = false
			for index in 48: room.battle._spawn_monster("orc",room.battle.hero.position+Vector2(100+index*3,50))
			room.battle.hero_player_mode = true; rooms.append(room)
			var old = script.new(); old.battle = room.battle; previous.append(old)
		work(previous,false); work(rooms,true)
		var before: Array = []; var after: Array = []
		for trial in 7:
			for optimized in ([false,true] if trial%2 == 0 else [true,false]):
				var begin := Time.get_ticks_usec(); work(rooms if optimized else previous,optimized)
				(after if optimized else before).append((Time.get_ticks_usec()-begin)/1000.0)
		before.sort(); after.sort()
		var row := {"rooms":room_count,"actors_per_room":48,"snapshots_per_room_trial":80,"recipients_per_room":2,"runs":7,"before_median_ms":before[3],"after_median_ms":after[3],"before_samples_ms":before,"after_samples_ms":after,"payload_bytes":SERVER._encode(rooms[0].snapshot()).to_utf8_buffer().size()}
		rows.append(row); print("PHASE3_ONLINE_BENCH ",JSON.stringify(row))
	var file := FileAccess.open("user://combat_phase3_online_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cpu_only":true,"engine":Engine.get_version_info().string,"excludes_socket_io":true,"rows":rows},"\t")); file.close()
	for old in previous: old.free()
	for room in rooms: stop_audio(room); room.free()
	stop_audio(root.get_node("GameAudio")); quit()
