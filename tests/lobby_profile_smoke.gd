extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const STORE := preload("res://src/systems/profile_cosmetic_store.gd")
const APPEARANCE := preload("res://src/systems/demon_appearance_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("PROFILE_TEST: " + message)

func frames() -> void:
	await process_frame
	await process_frame

func tap(button: Button, drag: bool = false) -> void:
	var position := button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = position
	down.pressed = true
	root.push_input(down, true)
	await frames()
	if drag:
		var motion := InputEventMouseMotion.new()
		motion.position = position + Vector2(60, 0)
		motion.relative = Vector2(60, 0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
		await frames()
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = position
	root.push_input(up, true)
	await frames()

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../../outputs/profile-" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var folder := "user://profile_fixture_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	var config := ConfigFile.new()
	config.set_value("player_profile", "value", {"nickname": "테스트", "gender": "male", "required": false, "completed": true})
	config.set_value("meta", "gold", 777)
	check(SCOPE.save_config(config, PROFILE.PATH) == OK, "isolated fixture")
	check(STORE.selected_id("banner") == "original_male", "legacy male default")
	var identity := PROFILE.get_profile()
	check(STORE.select("avatar", "original_female"), "select separate avatar")
	check(STORE.selected_id("banner") == "original_male" and PROFILE.appearance_id() == "original_male", "avatar cannot change banner or dialogue")
	check(STORE.select("banner", "original_female"), "select separate banner")
	check(APPEARANCE.equip("original_female"), "existing representative selection")
	check(PROFILE.get_profile() == identity, "all cosmetic choices preserve identity")
	check(not STORE.select("banner", "unknown") and not STORE.select("title", "original_male"), "invalid IDs and nonexistent features denied")
	SCOPE.load_config(config, PROFILE.PATH)
	check(config.get_value("meta", "gold") == 777, "save retains currency")
	check(config.get_value("profile_cosmetics", "avatar_id") == "original_female" and config.get_value("profile_cosmetics", "banner_id") == "original_female", "stable independent IDs persisted")
	SCOPE.select_guest()
	check(STORE.selected_id("avatar") == "original_female", "selection restores after scope reload")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	lobby._switch_tab("other")
	lobby.settings_view.other_menu_buttons.profile.pressed.emit()
	var view = lobby.settings_view.profile_view
	check(view.banner.get_parent().clip_contents and view.banner.get_parent().offset_left == 16 and view.banner.get_parent().offset_right == -16, "profile art clipped inside frame")
	check(view.gallery.get_node("ArtViewport").clip_contents, "gallery art clipped inside frame")
	await frames()
	check(view.root.visible and not lobby.settings_view.settings_root.visible, "profile opens separately")
	check(view.nickname.text == "테스트" and view.banner.texture != null and view.portrait.texture != null, "actual identity and supplied artwork")
	check(view.title_plate.get_global_rect().is_equal_approx(lobby.team_tab.get_node("TitlePlate").get_global_rect()), "shared title frame position")
	check(view.actions.title.disabled and view.gallery.disabled, "future features cannot fake ownership or run")
	check(view.reserved.get_child_count() == 0 and view.reserved.custom_minimum_size.y == 182, "empty future space has no cutscene action")
	var rank_rect: Rect2 = view.card.get_node("ProfileInformation/RankingPlaceholder").get_global_rect()
	print("PROFILE_LAYOUT: card=", view.card.get_global_rect(), " rank=", rank_rect)
	check(view.card.get_global_rect().encloses(rank_rect), "ranking text fits card")
	for button in view.actions.values():
		check(button.size.x <= view.scroll.size.x / 2 and button.size.y >= 120, "two touch-sized columns")
	await capture("female")
	var old_card_id: int = view.card.get_instance_id()
	var old_texture: Texture2D = view.banner.texture
	await tap(view.actions.banner, true)
	check(not view.picker.visible, "dragging a change button cannot open selector")
	await tap(view.actions.banner)
	check(view.picker.visible and view.picker_slot == "banner", "real selector signal")
	await frames()
	await capture("banner-picker")
	view.picker_buttons.original_male.emit_signal("confirmed")
	check(not view.picker.visible and STORE.selected_id("banner") == "original_male", "picker saves actual selection")
	view.actions.avatar.emit_signal("confirmed")
	view.picker_buttons.original_male.emit_signal("confirmed")
	view.actions.representative.emit_signal("confirmed")
	view.picker_buttons.original_male.emit_signal("confirmed")
	check(PROFILE.appearance_id() == "original_male" and PROFILE.get_profile() == identity, "representative picker retains canonical gender and nickname")
	await frames()
	await capture("male")
	view.scroll.scroll_vertical = 10000
	await frames()
	check(view.scroll.scroll_vertical > 0, "content scrolls inside profile")
	var footer := lobby.get_node("BottomNav") as Control
	check(view.scroll.get_global_rect().end.y <= footer.get_global_rect().position.y, "scroll stays above footer")
	await capture("lower")
	lobby.settings_view.show_menu()
	lobby.settings_view.show_profile()
	check(view.card.get_instance_id() == old_card_id, "reentry reuses controls")
	STORE.select("banner", "original_female")
	view.refresh()
	check(view.banner.texture == old_texture, "reentry reuses cached texture")
	view.open_picker("banner")
	var second_folder := folder + "_second"
	DirAccess.make_dir_recursive_absolute(second_folder)
	SCOPE.guest_directory = second_folder
	SCOPE.select_guest()
	view._choose("original_male")
	check(not view.picker.visible and not FileAccess.file_exists(second_folder.path_join("stage_progress.cfg")), "stale selector cannot write another scope")
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	lobby.settings_view.show_menu()
	lobby.settings_view.other_menu_buttons.settings.pressed.emit()
	lobby.settings_view.show_page("account")
	check(lobby.other_account_panel.has_node("CouponButton"), "account and coupon remain in settings")
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var account_id := "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
	check(SCOPE.select_account(account_id), "isolated account scope")
	SCOPE.install({"stage_progress.cfg": {"player_profile": {"value": {"nickname": "여마왕", "gender": "female", "completed": true, "required": false}}, "meta": {"gold": 123}}}, 1)
	check(STORE.selected_id("banner") == "original_female", "legacy female default")
	check(STORE.select("avatar", "original_male") and STORE.select("banner", "original_male"), "account saves both slots")
	var snapshot := SCOPE.files.duplicate(true)
	SCOPE.select_account(account_id)
	check(STORE.selected_id("banner") == "original_male", "account restart restores selection")
	SCOPE.install(snapshot, 2)
	check(STORE.selected_id("avatar") == "original_male" and PROFILE.get_profile().gender == "female", "snapshot round trip retains separate identity and cosmetics")
	SCOPE.load_config(config, PROFILE.PATH)
	check(config.get_value("meta", "gold") == 123, "account currency preserved")
	SCOPE.select_guest()
	check(PROFILE.get_profile() == identity, "returning to guest preserves original profile")
	lobby.queue_free()
	await frames()
	print("PROFILE_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
