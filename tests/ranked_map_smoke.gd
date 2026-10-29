extends SceneTree
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const SERVER := preload("res://src/online/match_server.gd")
const CLIENT := preload("res://src/online/match_client.gd")
const GUIDE := preload("res://src/data/ranked_rules_guide.gd")
var checks := 0

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for path in ["res://src/data/ranked_map_catalog.gd","res://src/online/match_rules.gd","res://src/online/battle_room.gd","res://src/online/match_server.gd","res://src/online/match_client.gd","res://src/online/match_loading_view.gd","res://src/online/match_scene.gd","res://src/data/ranked_rules_guide.gd","res://src/data/online_presentation_catalog.gd"]:
		var script: Script = load(path)
		check(script != null and script.can_instantiate(),"script load " + path)
	var scene: PackedScene = load("res://src/online/OnlineMatch.tscn")
	check(scene != null and scene.can_instantiate(),"OnlineMatch scene load")
	var scene_instance = scene.instantiate()
	check(scene_instance != null,"OnlineMatch instantiate")
	scene_instance.free()
	var maps: Array = MAPS.all()
	check(maps.size() == 3,"three maps")
	var favors := {}
	var durations := {}
	for entry in maps:
		favors[entry.favor] = true
		durations[entry.duration_seconds] = true
	check(favors.size() == 3 and favors.has("hero") and favors.has("demon") and favors.has("neutral"),"three favors")
	check(durations.size() == 3 and durations.has(480) and durations.has(600) and durations.has(900),"durations")
	var rng := RandomNumberGenerator.new(); rng.seed = 41
	for index in 100:
		check(MAPS.pick(rng).id in MAPS.ids(),"selected known map")
	var guide_text := str(GUIDE.sections())
	for entry in maps: check(guide_text.contains(entry.name),"guide map name")
	var server = SERVER.new(); root.add_child(server)
	for entry in maps:
		var room = ROOM.new(); room.map_id = entry.id; root.add_child(room); room.prepare()
		check(room.is_prepared,"room prepared")
		check(room.battle.run_time_limit_seconds == float(entry.duration_seconds),"battle duration")
		check(room.battle.current_map_size == entry.map_size,"map size")
		check(room.battle.hero.battlefield_size == entry.map_size,"hero bounds")
		check(is_equal_approx(room.battle.hero.exp_gain_multiplier,float(entry.modifiers.get("hero_exp_multiplier",1.0))),"hero EXP modifier")
		check(is_equal_approx(room.battle.command_regen_per_second,4.0*float(entry.modifiers.get("command_regen_multiplier",1.0))),"mana regen modifier")
		check(room.battlefield_info.map == entry.id,"battlefield map")
		server.rooms[entry.id] = {"node":room,"seats":{"hero":{"resume_token":"hero-token"},"demon":{"resume_token":"demon-token"}}}
		var payload: Dictionary = server._matched_payload(entry.id,"hero",false)
		check(payload.map == entry.id and payload.duration == entry.duration_seconds,"matched map and duration")
		check(CLIENT.valid_ranked_map(payload),"valid client map")
		payload.map = "unknown"
		check(not CLIENT.valid_ranked_map(payload),"unknown client map rejected")
		payload = server._matched_payload(entry.id,"hero",true)
		check(payload.map == entry.id and payload.resumed,"resume same map")
		var margins: Dictionary = server._match_margins(room,"demon","kill",float(entry.duration_seconds)*0.25,0.5)
		check(is_equal_approx(float(margins.demon),0.75),"map duration MMR margin")
		server.rooms.erase(entry.id)
		room.queue_free()
		await process_frame
	server.queue_free()
	print("ranked_map_smoke PASS %d checks" % checks)
	quit()
