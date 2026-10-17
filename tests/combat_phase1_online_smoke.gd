extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func stop_audio(host) -> void:
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in host.find_children("*",kind,true,false): player.stop(); player.stream = null
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	var rooms: Array = []
	for index in 2:
		var room = load("res://src/online/battle_room.gd").new(); root.add_child(room); room.prepare(); rooms.append(room)
		var actor = room.battle._spawn_monster("orc",room.battle.hero.position+Vector2(90,0))
		check(is_instance_valid(actor),"real online actor spawned")
		var before: Dictionary = room.snapshot()
		room.battle.combat_profile.start()
		var after: Dictionary = room.snapshot()
		check(before == after,"capture never changes wire snapshot")
		check(room.battle.combat_profile.calls[room.battle.combat_profile.Scope.NETWORK_SNAPSHOT] == 1,"snapshot scope opt-in")
		check(before.keys() == after.keys(),"protocol keys unchanged")
		var candidates: Array = []
		room.battle.fill_monsters_near(actor.position,100,candidates)
		check(candidates == [actor],"room query sees owned actor only")
	check(rooms[0].battle.monster_candidate_cache != rooms[1].battle.monster_candidate_cache,"rooms never share candidate cache")
	check(rooms[0].battle.combat_profile != rooms[1].battle.combat_profile,"rooms never share profile")
	for room in rooms: stop_audio(room); room.queue_free()
	stop_audio(root.get_node("GameAudio")); await process_frame
	print("COMBAT_PHASE1_ONLINE checks=",checks," failures=",failures); quit(1 if failures else 0)
