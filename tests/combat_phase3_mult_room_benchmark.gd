extends SceneTree
## Actual isolated authoritative worlds, six MAX weapons each. No socket traffic.
const SERVER := preload("res://src/online/match_server.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
func _initialize() -> void: run.call_deferred()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var rows: Array = []
	for count in [1,2,8]:
		var server := SERVER.new(); root.add_child(server)
		if server.start(24846,"127.0.0.1",true) != OK: push_error("loopback fixture listener"); quit(1); return
		for index in count:
			var room := ROOM.new(); server.add_child(room); room.prepare()
			var b = room.battle; var h = b.hero; var runtime = h.player_weapons
			h.invulnerability_timer = 9999
			for id in DATA.weapon_pool("ranged_rookie").slice(0,6):
				while int(runtime.levels.get(id,0)) < 10: runtime.add(id)
			for weapon in 6: runtime.apply_chest(runtime.roll_chest())
			b.hero_player_mode = false
			for actor_index in 48:
				var actor = b._spawn_monster("orc",h.position+Vector2.RIGHT.rotated(actor_index*2.39996)*(90+(actor_index%9)*20))
				if not is_instance_valid(actor): push_error("requested room population"); quit(1); return
				actor.max_hp = 10000000; actor.current_hp = actor.max_hp
			b.hero_player_mode = true
			server.rooms[str(index)] = {"node":room,"members":[],"created":Time.get_ticks_msec(),"ended":0}
			room.start()
		for frame in 120: await physics_frame
		for match_data in server.rooms.values(): match_data.node.battle.combat_profile.start()
		var global_physics: Array = []; var wall_start := Time.get_ticks_usec(); var physics_start := Engine.get_physics_frames(); var process_start := Engine.get_process_frames()
		for frame in 120:
			await physics_frame
			global_physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
		var reports: Array = []
		for match_data in server.rooms.values():
			var room = match_data.node; room.battle.set_external_pause(true); room.battle.combat_profile.stop()
			var report: Dictionary = room.battle.combat_profile.report(); report["actors"] = room.battle.active_monsters.size(); report["tick"] = room.tick; reports.append(report)
		var row := {"rooms":count,"actors_per_room":48,"max_weapons_per_room":6,"warmup_physics_ticks":120,"sample_physics_ticks":Engine.get_physics_frames()-physics_start,"process_frames":Engine.get_process_frames()-process_start,"wall_elapsed_ms":(Time.get_ticks_usec()-wall_start)/1000.0,"global_physics_monitor_ms":global_physics,"reports":reports,"scope":"headless actual server step + 10Hz state encoding; no socket clients; nested scopes overlap"}
		rows.append(row); print("PHASE3_MULTIROOM_CAPTURE rooms=",count," reports=",reports.size()," wall_ms=",row.wall_elapsed_ms)
		stop_audio(server); stop_audio(root.get_node("GameAudio")); server.queue_free(); await process_frame
	var file := FileAccess.open("user://combat_phase3_mult_room_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cpu_only":true,"engine":Engine.get_version_info().string,"rows":rows},"\t")); file.close(); quit()
