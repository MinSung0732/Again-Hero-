extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SETTINGS_TEST: " + message)

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://settings-v2-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var gateway := root.get_node("LoginGateway")
	gateway.remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var folder := "user://settings_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var audio := root.get_node("AudioSettings")
	audio.config_path = folder.path_join("audio.cfg")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("gameplay.cfg")
	root.add_child(lobby)
	current_scene = lobby
	var view = lobby.settings_view
	view.notice_path = folder.path_join("notice.cfg")
	lobby._switch_tab("other")
	check(view.buttons.size() == 5 and view.pages.size() == 5, "five expandable settings pages")
	check(view.selected == "game", "game is default")
	for id in view.pages:
		view.show_page(id)
		await process_frame
		await process_frame
		for other in view.pages:
			check(view.pages[other].visible == (other == id), "only selected page visible")
		for button in view.buttons.values():
			check(button.size.x >= 140 and button.size.y >= 90, "touch-sized tabs fit")
		check(view.pages[id].size.x <= view.scroll.size.x + 1, "no horizontal overflow")
		if id == "sound":
			check(view.pages[id].size.y <= view.scroll.size.y + 1, "all sound controls and guide fit without clipping")
		await capture(id)
	view.show_page("game")
	view.game_checks.camera_view_locked.button_pressed = false
	view.game_checks.battle_frame_enabled.button_pressed = false
	var settings := ConfigFile.new()
	check(settings.load(lobby.gameplay_settings_path) == OK, "game settings persisted")
	check(not settings.get_value("gameplay", "camera_view_locked") and not settings.get_value("gameplay", "battle_frame_enabled"), "same keys as battle")
	view.show_page("sound")
	lobby.bgm_slider.value = 3
	lobby.sfx_slider.value = 6
	lobby.bgm_mute_check.button_pressed = true
	lobby.sfx_mute_check.button_pressed = true
	check(audio.bgm_level == 3 and audio.sfx_level == 6, "original audio actions connected once")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "mute applies immediately")
	var saved := ConfigFile.new()
	check(saved.load(audio.config_path) == OK and saved.get_value("audio", "bgm_level") == 3, "audio saved in isolated fixture")
	for slider in [lobby.bgm_slider, lobby.sfx_slider]:
		check(slider.get_node("GemThumb").texture != null and slider.get_node("GemThumb").mouse_filter == Control.MOUSE_FILTER_IGNORE, "generated thumb ready and cannot consume input")
		check(slider.get_node("GemThumb").texture.get_image().get_pixel(0, 0).a == 0.0, "generated thumb keeps transparent padding")
	lobby.bgm_slider.value = 1
	await process_frame
	var x_min: float = lobby.bgm_slider.get_node("GemThumb").position.x
	lobby.bgm_slider.value = 10
	await process_frame
	check(lobby.bgm_slider.get_node("GemThumb").position.x > x_min, "thumb tracks native range")
	view.show_page("notice")
	check(not view.notice_checks.push_enabled.button_pressed and view.notice_checks.lunch_enabled.disabled, "notification consent defaults off")
	view.notice_checks.push_enabled.button_pressed = true
	view.notice_checks.lunch_enabled.button_pressed = true
	view.notice_checks.dinner_enabled.button_pressed = true
	view.notice_checks.push_enabled.button_pressed = false
	check(view.notice_checks.lunch_enabled.disabled and view.notice_checks.dinner_enabled.disabled, "master consent gates schedules")
	view.show_page("game")
	view.show_page("notice")
	check(view.notice_checks.lunch_enabled.button_pressed and view.notice_checks.dinner_enabled.button_pressed, "disabled schedule choices retained")
	view.notice_checks.push_enabled.button_pressed = true
	check(not view.notice_checks.lunch_enabled.disabled, "master opt-in restores schedule control")
	view.show_page("account")
	await process_frame
	await process_frame
	var heading_y: float = view.account_heading.global_position.y
	check(view.account_heading.get_parent() == view.scroll.get_parent(), "account title outside scroll clipping")
	check(view.account_heading.get_global_rect().end.y <= view.scroll.global_position.y, "title has full-height safe space")
	check(view.account_inset.get_theme_constant("margin_left") >= 28 and view.account_inset.get_theme_constant("margin_right") >= 28, "account body balanced inset")
	view.scroll.scroll_vertical = 200
	await process_frame
	check(is_equal_approx(view.account_heading.global_position.y, heading_y), "dragging cannot clip account title")
	view.scroll.scroll_vertical = 0
	check(view.account_identity.text.begins_with("게스트") and view.cloud_status.text.contains("연결 안 됨"), "guest is not shown as cloud-linked")
	check(lobby.other_account_panel.has_node("CouponButton") and not lobby.other_settings_panel.has_node("CouponButton"), "coupon moved to account")
	lobby.other_account_panel.get_node("CouponButton").pressed.emit()
	check(lobby.get_node("CouponOverlay").visible, "existing coupon modal opens")
	lobby.get_node("CouponOverlay").hide()
	gateway.user_id = "fixture-display-only"
	gateway._set_account_display({"email": "fixture@example.test", "app_metadata": {"provider": "kakao"}})
	gateway.access_token = "fixture-display-only"
	var cloud := root.get_node("CloudStore")
	cloud.ready_for_play = true
	view.show_page("account")
	check(view.account_identity.text.contains("카카오") and view.account_identity.text.contains("fixture@example.test"), "validated profile display")
	gateway._set_account_display({"email": "fixture@example.test", "app_metadata": {"provider": "google"}})
	view.show_page("account")
	check(view.account_identity.text.begins_with("Google"), "Google account display")
	check(view.cloud_status.text == "클라우드 저장 사용 중", "ready cloud status")
	cloud.conflict = true
	cloud.status_changed.emit("저장 충돌 테스트")
	check(view.cloud_status.text.contains("충돌"), "cloud status updates by signal")
	check(lobby.other_account_panel.get_node("Guide").text == "저장 충돌 테스트", "last sync result remains visible")
	cloud.stop()
	gateway.user_id = ""
	gateway.access_token = ""
	gateway._set_account_display({})
	view.show_page("game")
	lobby._switch_tab("main")
	lobby._switch_tab("other")
	check(view.selected == "game" and not view.game_checks.camera_view_locked.button_pressed, "tab reentry preserves page and gameplay value")
	# Main consumes exactly the same shared file and options, no schema migration.
	var main = load("res://src/main/Main.tscn").instantiate()
	main.gameplay_settings_path = lobby.gameplay_settings_path
	main._load_gameplay_settings()
	check(not main.camera_view_locked and not main.battle_frame_enabled, "battle reads lobby settings")
	main.free()
	var restored = load("res://src/lobby/Lobby.tscn").instantiate()
	restored.gameplay_settings_path = lobby.gameplay_settings_path
	root.add_child(restored)
	restored.settings_view.notice_path = view.notice_path
	restored.settings_view.show_page("notice")
	check(restored.settings_view.notice_checks.push_enabled.button_pressed and restored.settings_view.notice_checks.lunch_enabled.button_pressed and restored.settings_view.notice_checks.dinner_enabled.button_pressed, "consent survives new screen instance")
	restored.settings_view.show_page("game")
	check(not restored.settings_view.game_checks.camera_view_locked.button_pressed and not restored.settings_view.game_checks.battle_frame_enabled.button_pressed, "game options survive new screen instance")
	restored.queue_free()
	lobby.queue_free()
	await process_frame
	print("SETTINGS_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
