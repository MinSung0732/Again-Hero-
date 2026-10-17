extends SceneTree
## Actual Stage9 Battle/Hero/orc physics. Placeholder presentation, headless CPU only.
const IDS := ["purifier_hero_holy_bolt","purifier_hero_holy_lance","purifier_hero_purification","purifier_hero_sacred_orb","purifier_hero_mercy_chain","purifier_hero_judgment_seal"]
var rows: Array = []
func _initialize() -> void: run.call_deferred()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	for count in [48,120,208]:
		for trial in 2:
			for cached in [true]:
				seed(9000+trial)
				var b = load("res://src/battle/Battle.tscn").instantiate()
				b.hero_player_mode = true; b.hero_player_stage = "stage_9"; b.hero_player_hero_id = "purifier_hero"
				b._monster_spawn_resources_warmed = true; root.add_child(b); b.set_external_pause(true)
				b.monster_candidate_cache.enabled = cached
				var h = b.hero; var r = h.player_weapons
				h.invulnerability_timer = 9999
				for id in IDS:
					while int(r.levels.get(id,0)) < 10: r.add(id)
				for item in IDS.size(): r.apply_chest(r.roll_chest())
				for index in count:
					var actor = b._spawn_monster("orc",h.position+Vector2.RIGHT.rotated(index*2.39996)*(90+(index%9)*20))
					if not is_instance_valid(actor): push_error("benchmark must retain requested population"); quit(1); return
					actor.max_hp = 10000000; actor.current_hp = actor.max_hp
				b.set_external_pause(false)
				for warmup in 120: await physics_frame
				b.monster_candidate_cache.reset(); b.combat_profile.start()
				var physics_ms: Array[float] = []
				var process_start := Engine.get_process_frames()
				var physics_start := Engine.get_physics_frames()
				for sample in 120:
					await physics_frame
					physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
				b.set_external_pause(true); b.combat_profile.stop()
				var monitor_samples := physics_ms.duplicate()
				physics_ms.sort()
				var report: Dictionary = b.combat_profile.report()
				report["physics_steps"] = Engine.get_physics_frames()-physics_start
				report["process_frames"] = Engine.get_process_frames()-process_start
				report["physics_2d_active_objects"] = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
				report["physics_2d_collision_pairs"] = Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)
				report["physics_2d_islands"] = Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT)
				report["population"] = b.active_monsters.size(); report["requested_population"] = count
				report["cache_enabled"] = cached; report["trial"] = trial; report["cpu_only"] = true
				report["global_physics_mean_ms"] = physics_ms.reduce(func(a,v): return a+v,0.0)/physics_ms.size()
				report["global_physics_p95_ms"] = physics_ms[113]
				report["physics_monitor_ms_samples"] = monitor_samples
				report["monitor_note"] = "Global Performance monitor is sampled at physics boundaries; its reporting window differs from explicit per-call scopes. Do not subtract/sum to assign engine costs."
				report["query_cache"] = {"requests":b.monster_candidate_cache.requests,"hits":b.monster_candidate_cache.hits,"bucket_reads":b.monster_candidate_cache.bucket_reads}
				rows.append(report); print("PHASE2_STAGE9_BENCH ",JSON.stringify(report))
				stop_audio(b); stop_audio(root.get_node("GameAudio")); b.queue_free(); await process_frame
	var file := FileAccess.open("user://combat_phase2_stage9_breakdown.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cpu_only":true,"rows":rows},"\t")); file.close()
	print("PHASE2_STAGE9_PATH ",ProjectSettings.globalize_path("user://combat_phase2_stage9_breakdown.json")); quit()
