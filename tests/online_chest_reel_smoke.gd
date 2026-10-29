extends SceneTree
const RULES := preload("res://src/online/match_rules.gd")
const ROOM := preload("res://src/online/battle_room.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	root.get_node("SceneTransition")._entry_options = {"role":"hero"}
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	await process_frame
	scene.set_process(false); scene.local_preparing = false; scene.waiting_for_start = false
	var first := {"serial":1,"id":"survival_power","name":"first","pool":["survival_power","survival_restore"]}
	var second := {"serial":2,"id":"survival_restore","name":"second","pool":["survival_restore"]}
	scene._receive_chests([first,second]); scene._advance_chest_notice(0.01)
	await process_frame
	check(scene.chest_panel.visible and scene.chest_reel.visible,"reel shown")
	check(scene.chest_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.chest_reel.mouse_filter == Control.MOUSE_FILTER_IGNORE,"reel ignores input")
	check(scene.chest_reel.size.y == 280 and scene.chest_reel.scale == Vector2.ONE * RULES.CHEST_REEL_SCALE,"reel retains full scaled layout")
	check(scene.chest_queue.size() == 1 and scene.chest_notice.text.contains("first"),"first receipt starts first")
	scene.pad.set_mode("fixed"); await process_frame
	for resolution in [Vector2i(1080,1920),Vector2i(1080,2400),Vector2i(1536,1920)]:
		root.size = resolution; await process_frame
		check(not scene.chest_panel.get_global_rect().intersects(scene.hold_popup.dot_row.get_global_rect()),"panel avoids held augments")
		check(not scene.chest_panel.get_global_rect().intersects(scene.hero_slots.get_global_rect()),"panel avoids inventory")
		check(not scene.chest_panel.get_global_rect().intersects(scene.pad.get_global_rect()),"panel avoids fixed joystick")
		for node_name in ["StageFrame","TimerFrame","HeroStatusFrame","MonsterFrame","StageMenuButton"]:
			var hud = scene.top_bar.get_node(node_name)
			if hud.visible: check(not scene.chest_panel.get_global_rect().intersects(hud.get_global_rect()),"panel avoids " + node_name)
		check(scene.chest_panel.get_global_rect().end.y < resolution.y,"panel fits viewport")
	scene._advance_chest_notice(RULES.CHEST_REEL_SPIN_SECONDS)
	check(scene.chest_reel.progress == 1.0 and scene.chest_notice.visible,"winner shown after spin")
	scene._advance_chest_notice(RULES.CHEST_REEL_RESULT_SECONDS)
	check(scene.chest_notice.text.contains("second") and scene.chest_queue.is_empty(),"second receipt follows first")
	scene._advance_chest_notice(3.0)
	check(not scene.chest_panel.visible,"panel closes")
	scene.role = "demon"; scene._receive_chests([first]); check(scene.chest_queue.is_empty(),"demon cannot receive reel")
	scene.queue_free(); await process_frame
	var room := ROOM.new(); root.add_child(room); room.prepare(); room.start()
	room._chest_opened()
	check(not room.chest_receipts.is_empty() and room.chest_receipts[0].pool.size() <= RULES.CHEST_REEL_POOL_LIMIT,"server bounds pool")
	room.free()
	print("ONLINE_CHEST_REEL checks=",checks," failures=",failures); quit(1 if failures else 0)
