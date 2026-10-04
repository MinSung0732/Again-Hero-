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
	var warmup := root.get_node("PresentationWarmup")
	for index in range(1, 31):
		_check(warmup.get_texture("res://assets/art/UI/talk_light_only_30_frames/effect_%02d.png" % index) != null, "Reveal frame preloaded before login")
	var oauth := load("res://src/network/windows_oauth.gd")
	var verifier := "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
	var url: String = oauth.authorize_url("google", verifier, "test-nonce")
	_check(url.contains("E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"), "RFC7636 S256 test vector")
	_check(url.contains("code_challenge_method=s256"), "PKCE enabled")
	_check(oauth.parse_query("/auth/callback/x?code=a&code=b").is_empty(), "Duplicate auth code rejected")
	_check(not gateway.local_guest_active and gateway.access_token.is_empty(), "Loading cannot fabricate authentication")
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
	_check(current_scene._presentation_ready, "Lobby portrait preparation finishes under loading")
	var lobby := current_scene
	var original_index: int = lobby.selected_stage_index
	var normalized_before: int = lobby._portrait_normalization_count
	var texture_loads_before: int = warmup.texture_load_count
	var portraits: Dictionary = lobby._portrait_texture_cache.duplicate()
	for index in range(lobby._get_max_browsable_stage_index() + 1):
		var stage: Dictionary = load("res://src/data/stage_catalog.gd").get_stage(lobby.stage_ids[index])
		var path := String(stage.get("portrait_path", ""))
		_check(portraits.has(path), "Every browsable portrait is ready before first navigation")
		lobby.selected_stage_index = index
		lobby._refresh_stage_card()
		_check(lobby.portrait_texture.texture == portraits.get(path), "First card navigation reuses prepared final texture")
		await process_frame
	_check(lobby._portrait_normalization_count == normalized_before, "Card navigation performs no image normalization")
	_check(warmup.texture_load_count == texture_loads_before, "Card navigation performs no warmup texture loads")
	lobby.selected_stage_index = original_index
	lobby._refresh_stage_card()
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
	_check(current_scene._presentation_ready, "Render warmup finishes before dungeon entry")
	_check(current_scene.battle._monster_spawn_resources_warmed, "Monster caches finish beneath loading")
	var loads_before: int = warmup.texture_load_count
	await warmup.prepare_common()
	_check(warmup.texture_load_count == loads_before, "Reveal cache reuse performs no texture reload")
	_check(not transition.change_scene("res://missing-scene.tscn"), "Invalid scene rejected safely")
	print("STARTUP_SMOKE_%s: title, 30 preloaded frames, PKCE vector, retry, guest, duplicate guard, warmed dungeon transition" % ("FAILED" if _failed else "OK"))
	current_scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)
