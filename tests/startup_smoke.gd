extends SceneTree

# Run with: godot --headless --path . --script res://tests/startup_smoke.gd
# With -- --capture-dir=<absolute directory>, also captures real rendered screens.
var _out := ""
var _failed := false


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			_out = argument.trim_prefix("--capture-dir=").path_join("")
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("STARTUP_TEST: " + message)


func _capture(name: String) -> void:
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _wait_login(startup: Control) -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while startup.phase != startup.Phase.LOGIN and startup.phase != startup.Phase.ERROR and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(startup.phase == startup.Phase.LOGIN, "Loading must reach login within 30 seconds")


func _run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gateway := root.get_node("LoginGateway")
	gateway.reset_local_guest()
	var startup: Control = load("res://src/startup/Startup.tscn").instantiate()
	root.add_child(startup)
	current_scene = startup
	await process_frame
	await process_frame
	_check(startup.phase == startup.Phase.TITLE, "Starts at title")
	_check(not startup.login_screen.visible, "Login cannot bypass loading")
	await _capture("startup-title")
	# Any-screen mouse/touch release should start once, even repeated/emulated input.
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(200, 500)
	touch.pressed = true
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	touch = touch.duplicate()
	touch.pressed = false
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	await process_frame
	_check(startup.phase == startup.Phase.RESOURCES, "Touch starts resource preparation")
	startup.begin_startup()
	_check(startup.phase == startup.Phase.RESOURCES, "Duplicate start is ignored")
	await process_frame
	await _capture("startup-resources")
	var deadline := Time.get_ticks_msec() + 30000
	while startup.phase == startup.Phase.RESOURCES and Time.get_ticks_msec() < deadline:
		await process_frame
	await _capture("startup-loading")
	await _wait_login(startup)
	if _failed:
		quit(1)
		return
	_check(startup._lobby is PackedScene, "Real lobby scene is cached")
	_check(startup._resources.size() == 3, "Core resources actually loaded")
	startup.login_screen.find_child("GoogleLogin", true, false).pressed.emit()
	_check(startup.phase == startup.Phase.LOGIN and not gateway.local_guest_active, "Google placeholder must not authenticate")
	_check(startup.status_label.text.contains("서버 복구"), "Unavailable provider gives an explanation")
	startup.login_screen.find_child("KakaoLogin", true, false).pressed.emit()
	_check(not gateway.local_guest_active, "Kakao placeholder must not create a guest account")
	await _capture("startup-login")
	# Error/retry must leave the screen usable and reload cleanly.
	startup.loading_view.show()
	startup.login_screen.hide()
	startup._fail("테스트 오류")
	_check(startup.retry_button.visible, "Failed load offers retry")
	startup.begin_startup()
	await _wait_login(startup)
	if _failed:
		quit(1)
		return
	startup.guest_button.pressed.emit()
	startup.guest_button.pressed.emit()
	deadline = Time.get_ticks_msec() + 30000
	var transition := root.get_node("SceneTransition")
	while (current_scene == startup or transition.is_transitioning()) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(current_scene != null and current_scene.name == "Lobby", "Guest opens actual lobby")
	_check(gateway.local_guest_active, "Guest remains explicitly local-only")
	_check(not transition.is_transitioning(), "Transition clears after new scene is ready")
	_check(not transition.is_processing(), "No idle per-frame transition polling")
	await _capture("startup-lobby")
	# Dungeon entry uses the same real threaded scene transition, not a timed fake.
	_check(transition.change_scene("res://src/main/Main.tscn", "던전 불러오는 중..."), "Dungeon load accepted")
	_check(not transition.change_scene("res://src/main/Main.tscn"), "Duplicate transition rejected")
	await process_frame
	await _capture("startup-dungeon-loading")
	deadline = Time.get_ticks_msec() + 30000
	while transition.is_transitioning() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not transition.is_transitioning() and current_scene.name == "Main", "Actual dungeon scene opens")
	_check(not transition.change_scene("res://missing-scene.tscn"), "Invalid scene rejected safely")
	print("STARTUP_SMOKE_%s: title, real resources, lobby preload, provider placeholders, retry, guest, duplicate guard, dungeon transition" % ("FAILED" if _failed else "OK"))
	current_scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)
