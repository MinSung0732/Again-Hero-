extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const CINEMATIC := preload("res://src/data/battle_summon_cinematic_catalog.gd")
const VIEW := preload("res://src/online/battle_view.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var rooms: Array = []
	for index in 2:
		var room = ROOM.new(); root.add_child(room)
		room.set_loadouts({"hero_id":RULES.HERO},{"team_ids":["slime","spider","orc"],"skill_ids":[],"transcendence_id":"zeus"})
		room.prepare(); room.start(); rooms.append(room)
	var a = rooms[0]; var b = rooms[1]
	check(a.apply("demon","transcend_unlock_test",{},true), "unlock")
	var point: Vector2 = a.battle.hero.position + Vector2(300,0)
	check(a.apply("demon","transcend",{"point":[point.x,point.y]}), "summon")
	check(a.room_freeze_left == 0.0, "slow profile does not freeze")
	var monster = a.transcendent_actor
	check(is_instance_valid(monster), "transcendent exists")
	var elapsed_a: float = a.battle.run_metrics.elapsed_seconds
	var elapsed_b: float = b.battle.run_metrics.elapsed_seconds
	check(a.apply("hero","move",[1.0,0.0]), "slow motion accepts input")
	for i in 30:
		await physics_frame
		a.step(1.0/60.0); b.step(1.0/60.0)
	check(a.battle.run_metrics.elapsed_seconds > elapsed_a and a.battle.run_metrics.elapsed_seconds - elapsed_a < b.battle.run_metrics.elapsed_seconds - elapsed_b, "room A advances slowly")
	check(is_equal_approx(a.battle.clock_scale, CINEMATIC.slow_motion_scale(CINEMATIC.ENTRIES.zeus.slow_motion, a.cinematic_elapsed)), "summon curve")
	check(a.battle.clock_scale < 1.0 and is_equal_approx(a.snapshot().clock_scale, a.battle.clock_scale), "snapshot carries slow scale")
	var view = VIEW.new(); root.add_child(view)
	view.allowed_actor_ids.append("zeus")
	check(view.update_state(a.snapshot()) and is_equal_approx(view.server_clock_scale, a.battle.clock_scale), "client adopts authoritative scale")
	view.shot_motion.begin(); view.shot_motion.put(1, Vector2.ZERO); view.shot_motion.finish()
	view.shot_motion.begin(); view.shot_motion.put(1, Vector2(10, 0)); view.shot_motion.finish()
	view._process(RULES.SNAPSHOT_INTERVAL * 0.5)
	check(view.shot_motion.position(1, Vector2.ZERO).is_equal_approx(Vector2(5, 0)), "slow snapshot displacement is interpolated once")
	check(b.battle.run_metrics.elapsed_seconds > elapsed_b, "room B advances")
	check(is_equal_approx(b.battle.clock_scale, 1.0), "room B scale isolated")
	a.battle.transcendent_died.emit("zeus",monster)
	check(is_equal_approx(a.battle.clock_scale, CINEMATIC.slow_motion_scale(CINEMATIC.DEATH_DEFAULT.slow_motion, 0.0)), "latest death curve wins")
	check(a.snapshot().feedback.size() >= 2, "feedback available during slow motion")
	a.set_connection_paused(true); a.step(1.0)
	check(a.battle.process_mode == Node.PROCESS_MODE_DISABLED, "disconnect remains paused")
	a.set_connection_paused(false)
	check(a.battle.process_mode != Node.PROCESS_MODE_DISABLED, "reconnect resumes")
	a.step(float(CINEMATIC.DEATH_DEFAULT.duration) + 0.01)
	check(is_equal_approx(a.battle.clock_scale, 1.0), "scale restored")
	a._start_cinematic({"duration": 0.5})
	check(a.room_freeze_left > 0.0 and not a.apply("hero", "move", [0.0,1.0]), "profileless event freezes and rejects input")
	check(is_equal_approx(a.snapshot().clock_scale, 0.0), "freeze snapshot scale")
	check(view.update_state(a.snapshot()) and is_equal_approx(view.server_clock_scale, 0.0), "client receives freeze")
	a.step(0.51)
	check(a.battle.process_mode != Node.PROCESS_MODE_DISABLED and a.battle.hero.player_move_input == Vector2.DOWN, "freeze resumes queued input")
	view.queue_free()
	for room in rooms: room.queue_free()
	print("ONLINE_ROOM_FREEZE_PASS" if failures == 0 else "ONLINE_ROOM_FREEZE_FAIL "+str(failures))
	quit(0 if failures == 0 else 1)
