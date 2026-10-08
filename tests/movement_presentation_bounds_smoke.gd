extends SceneTree
const SCOPE = preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok:
		failed = true
		push_error("MOVEMENT_BOUNDS: " + message)
func run():
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://movement_bounds_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var mode = root.get_node("LocalTestMode")
	mode.active = true
	mode.tutorial_preview = false
	check(mode.request_practice_battle(), "practice requested")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var dummy = battle.hero
	dummy.set_physics_process(false)
	for point in [Vector2(-100,-100),Vector2(99999,-1),Vector2(-1,99999),Vector2(99999,99999)]:
		dummy.position = point
		dummy._physics_process(1.0/60.0)
		check(dummy.position.x >= 72 and dummy.position.y >= 357 and dummy.position.x <= battle.current_map_size.x-72 and dummy.position.y <= battle.current_map_size.y-72, "dummy contained at every corner after real action path")
	check((dummy.collision_mask & 8) != 0, "hard wall collision restored")
	dummy.petrify_timer = 1.0
	dummy.petrify_anchor = Vector2(-100,-100)
	dummy._physics_process(1.0/60.0)
	check(dummy.position.y >= 357 and dummy.petrify_anchor == dummy.global_position, "petrify cannot restore an outside anchor")
	dummy.petrify_timer = 0
	for id in ["zeus","bulgasal"]:
		var monster = preload("res://src/data/monster_catalog.gd").get_scene(id).instantiate()
		monster.set_physics_process(false)
		battle.add_child(monster)
		var visual = monster.visual
		visual.play_locomotion(true)
		for index in range(12): visual._physics_process(1.0/60.0)
		check(visual.animation == &"move" and visual.sprite_frames.get_animation_speed(&"move") * visual.speed_scale <= 8.01, id + " capped walk cadence")
		visual.set_frame_and_progress(2,0.4)
		visual.play_attack()
		check(visual.speed_scale == 1.0 and visual.animation == &"attack", id + " attack timing unchanged")
		visual._on_animation_finished()
		check(visual.animation == &"move" and visual.frame == 2 and is_equal_approx(visual.frame_progress,0.4), id + " resumes interrupted foot phase")
		visual.set_frame_and_progress(3,0.6)
		visual.set_lod_suspended(true)
		visual.set_lod_suspended(false)
		check(visual.frame == 3 and is_equal_approx(visual.frame_progress,0.6), id + " LOD keeps walk phase")
		for index in range(24):
			visual.play_locomotion(index % 2 == 0)
			if visual.is_physics_processing(): visual._physics_process(1.0/60.0)
		check(visual.animation == &"move", id + " alternating move idle requests do not flicker")
		visual.play_locomotion(false)
		for index in range(12): visual._physics_process(1.0/60.0)
		check(visual.animation == &"idle" and visual.speed_scale == 1.0, id + " sustained stop returns idle")
		monster.free()
	battle.free()
	mode.active = false
	var normal = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(normal)
	normal.set_process(false)
	normal.set_physics_process(false)
	var hero = normal.hero
	hero.set_physics_process(false)
	for point in [Vector2(-100,-100),Vector2(99999,99999)]:
		hero.position = point
		hero._physics_process(1.0/60.0)
		check(hero.position.x >= 72 and hero.position.y >= 357 and hero.position.x <= normal.current_map_size.x-72 and hero.position.y <= normal.current_map_size.y-72, "ordinary dungeon hero contained")
	normal.free()
	print("MOVEMENT_PRESENTATION_BOUNDS: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
