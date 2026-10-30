extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
const CINEMATIC := preload("res://src/data/battle_summon_cinematic_catalog.gd")
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
	check(is_equal_approx(a.room_freeze_left,float(CINEMATIC.ENTRIES.zeus.duration)), "catalog duration")
	var monster = a.transcendent_actor
	check(is_instance_valid(monster), "transcendent exists")
	var position: Vector2 = monster.position
	var elapsed_a: float = a.battle.run_metrics.elapsed_seconds
	var elapsed_b: float = b.battle.run_metrics.elapsed_seconds
	var clock_a: int = a.battle.combat_time_msec()
	check(not a.apply("demon","summon",{"id":"slime","point":[point.x,point.y]}), "frozen input rejected")
	check(not a.apply("hero","move",[1.0,0.0]), "move queued but rejected")
	for i in 30:
		await physics_frame
		a.step(1.0/60.0); b.step(1.0/60.0)
	check(is_equal_approx(elapsed_a,a.battle.run_metrics.elapsed_seconds), "room A time frozen")
	check(position.is_equal_approx(monster.position), "room A monster frozen")
	check(a.battle.combat_time_msec() == clock_a, "combat clock frozen")
	check(b.battle.run_metrics.elapsed_seconds > elapsed_b, "room B advances")
	check(a.tick == 0 and b.tick > 0, "room ticks isolated")
	var remaining: float = a.room_freeze_left
	a.battle.transcendent_died.emit("zeus",monster)
	check(a.room_freeze_left >= remaining, "overlap keeps maximum")
	check(a.snapshot().feedback.size() >= 2, "feedback available in frozen snapshot")
	a.step(a.room_freeze_left + 0.01)
	check(a.battle.process_mode != Node.PROCESS_MODE_DISABLED, "battle resumed")
	check(a.battle.hero.player_move_input == Vector2.RIGHT, "latest movement restored")
	for i in 10:
		await physics_frame
		a.step(1.0/60.0)
	check(a.battle.run_metrics.elapsed_seconds > elapsed_a, "room A advances again")
	a.battle.transcendent_died.emit("zeus", monster)
	check(is_equal_approx(a.room_freeze_left, float(CINEMATIC.DEATH_DEFAULT.duration)), "death duration")
	a.set_connection_paused(true); a.step(a.room_freeze_left + 0.01)
	check(a.battle.process_mode == Node.PROCESS_MODE_DISABLED, "disconnect remains paused")
	a.set_connection_paused(false)
	check(a.battle.process_mode != Node.PROCESS_MODE_DISABLED, "reconnect resumes")
	for room in rooms: room.queue_free()
	print("ONLINE_ROOM_FREEZE_PASS" if failures == 0 else "ONLINE_ROOM_FREEZE_FAIL "+str(failures))
	quit(0 if failures == 0 else 1)
