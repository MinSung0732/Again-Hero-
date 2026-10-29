extends SceneTree
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func click(button: Button) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center(); event.pressed = true
	root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var local = root.get_node("LocalTestMode")
	var old_active: bool = local.active
	var old_preview: bool = local.tutorial_preview
	local.active = true; local.tutorial_preview = false
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate()
		scene.set_script(load("res://tests/fixtures/online_exit_spy.gd")); root.add_child(scene)
		await process_frame; await process_frame
		scene.top_bar.show()
		if role == "hero":
			for viewport_size in [Vector2i(1080,1920),Vector2i(1080,2400),Vector2i(1536,1920)]:
				root.size = viewport_size; scene._open_match_menu()
				for i in 5: await process_frame
				var surrender: Button = scene.match_menu.find_child("Pause_surrender",true,false)
				var scroll: ScrollContainer = scene.match_menu.find_child("PauseScroll",true,false)
				check(surrender.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(surrender.get_global_rect()),"surrender inside viewport " + str(viewport_size))
				check(scroll.get_global_rect().encloses(surrender.get_global_rect()) and not scroll.get_v_scroll_bar().visible,"surrender visible without scrolling " + str(viewport_size))
				scene._close_match_menu()
			scene._open_match_menu(); await process_frame
			click(scene.match_menu.find_child("Pause_surrender",true,false))
			check(scene.surrender_dialog.visible,"surrender confirmation opens")
			scene.surrender_dialog.confirmed.emit(); check(scene.leaves == 1,"surrender calls leave")
			scene.surrender_dialog.hide()
		for outcome in [["hero","victory"],["demon","defeat"],["hero","time_limit"],["demon","opponent_left"]]:
			scene.ended = false; scene.client.match_id = "test"
			scene._event({"op":"result","match":"test","winner":outcome[0],"reason":outcome[1]})
			check(scene.result_pending,"result waits for presentation")
			await create_timer(scene.result_wait_seconds+0.2).timeout
			await process_frame
			var button: Button = scene.result_overlay.find_child("ResultLobbyButton",true,false)
			check(not scene.result_pending and button != null and button.is_visible_in_tree() and not button.disabled,"result lobby button shown " + role + " " + outcome[1])
			check(not is_instance_valid(scene.result_focus),"presentation no longer blocks input")
			var before: int = scene.leaves; click(button); check(scene.leaves == before+1,"result accepts input and calls leave")
			scene.result_overlay.queue_free(); scene.result_overlay = null
		scene.queue_free(); await process_frame
	local.active = old_active; local.tutorial_preview = old_preview
	print("online_hero_exit_smoke: %d checks" % checks); quit()
