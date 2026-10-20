extends SceneTree
## CPU-only fixture. Fixed real actor snapshots; no GPU/socket/combat-FPS claim.
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const SERVER := preload("res://src/online/match_server.gd")
const RULES := preload("res://src/online/match_rules.gd")
const WINDOW := preload("res://src/online/metric_window.gd")
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const TRIALS := 96
const RENDER_STEPS := 6
func _initialize() -> void: run.call_deferred()
func stop_audio(host: Node) -> void:
	# Test teardown, outside measured work. Retire active playback before quit.
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stream_paused = false; player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop()
	var rows: Array = []
	for count in [0,RULES.POPULATION/2,RULES.POPULATION]:
		var room = ROOM.new(); root.add_child(room); room.prepare()
		var b = room.battle
		# Audio is outside this CPU fixture; prevent attack playback during setup.
		stop_audio(room); stop_audio(root.get_node("GameAudio"))
		b.hero_player_mode = false
		# Direct fixture spawn bypasses mana/population-cost validation deliberately.
		# Production summon rules are exercised by the existing online smoke tests.
		for index in int(count):
			var actor = b._spawn_monster(RULES.ROSTER[index%RULES.ROSTER.size()],b.hero.position+Vector2(200+index*5,50))
			if not is_instance_valid(actor): push_error("fixture actor spawn failed"); quit(1); return
		b.hero_player_mode = true
		# Let deferred visuals bind in a short actual battle, then freeze the world.
		room.start()
		for frame in 6: await physics_frame
		room.set_connection_paused(true)
		var view = VIEW.new(); root.add_child(view); view.set_process(false)
		var snapshot_ms = WINDOW.new(); var encode_ms = WINDOW.new(); var install_ms = WINDOW.new(); var motion_ms = WINDOW.new()
		var frame_costs := PackedFloat64Array(); frame_costs.resize(RENDER_STEPS)
		var wire := ""; var last: Dictionary = {}; var command_count := 0
		# Paused battle and synchronous trials isolate snapshot/encoding/display CPU.
		for trial in TRIALS+8:
			var begin := Time.get_ticks_usec(); last = room.snapshot()
			if last.actors.size()!=int(count) or last.visuals.is_empty(): push_error("fixture population/visual baseline changed"); quit(1); return
			var snapshot_cost := (Time.get_ticks_usec()-begin)/1000.0
			begin = Time.get_ticks_usec(); wire = SERVER._encode(last)
			var encode_cost := (Time.get_ticks_usec()-begin)/1000.0
			# Display-only movement trace, using authentic PNG commands and static props.
			var shift := float(trial%2)*100.0
			last.hero[1] += shift
			for actor in last.actors: actor[3] += shift
			for command in last.visuals:
				if int(command[0])>=0: command[11] += shift; command[21] += shift
			begin = Time.get_ticks_usec()
			if not view.update_state(last): push_error("fixture state rejected"); quit(1); return
			var install_cost := (Time.get_ticks_usec()-begin)/1000.0
			for frame in RENDER_STEPS:
				begin = Time.get_ticks_usec(); view.advance_motion(DATA.MOTION_SECONDS/RENDER_STEPS)
				frame_costs[frame] = (Time.get_ticks_usec()-begin)/1000.0
			if trial>=8:
				snapshot_ms.push(snapshot_cost); encode_ms.push(encode_cost); install_ms.push(install_cost)
				for cost in frame_costs: motion_ms.push(cost)
			command_count = view.render_visuals.size()
		rows.append({"actors":last.actors.size(),"visual_commands_including_props":command_count,"payload_bytes":wire.to_utf8_buffer().size(),"snapshot":snapshot_ms.report(),"encode":encode_ms.report(),"install":install_ms.report(),"motion_and_depth_per_frame":motion_ms.report()})
		stop_audio(room); stop_audio(root.get_node("GameAudio"))
		view.queue_free(); room.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("ONLINE_MOTION_BENCH ",JSON.stringify({"engine":Engine.get_version_info().string,"cpu_only":true,"scope":"paused real actor snapshot/JSON encode/view install + synthetic display trace; excludes socket/JSON decode/GPU/ongoing combat; no before-after speedup claim","trials":TRIALS,"rows":rows}))
	quit()
