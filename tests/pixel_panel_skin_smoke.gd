extends SceneTree

const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PIXEL_PANEL: " + message)

func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://pixel-panel-" + name + ".png")

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var source := StyleBoxFlat.new()
	source.bg_color = Color("171020")
	source.border_color = Color("d8ad55")
	source.set_border_width_all(3)
	source.set_content_margin_all(4)
	# Panels take the pixel nine-patch; since 10-06 (486a6960) buttons take one continuous authored frame instead.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", source)
	var caption := Label.new()
	caption.text = "강화하기"
	panel.add_child(caption)
	root.add_child(panel)
	var minimum := panel.get_combined_minimum_size()
	var filter := panel.texture_filter
	var children := panel.get_child_count()
	SKIN.apply(panel)
	check(panel.get_theme_stylebox("panel") is StyleBoxTexture, "pixel nine-patch style")
	check(panel.get_combined_minimum_size() == minimum and panel.texture_filter == filter and panel.get_child_count() == children, "no layout/font-filter/input-node change")
	var button := Button.new()
	button.text = "강화하기"
	button.add_theme_stylebox_override("normal", source)
	button.add_theme_stylebox_override("disabled", source)
	root.add_child(button)
	var button_minimum := button.get_combined_minimum_size()
	var button_children := button.get_child_count()
	SKIN.apply(button)
	var authored := load("res://assets/art/UI/clean_frames/button_frame.tres") as StyleBoxFlat
	var frame := button.get_theme_stylebox("normal") as StyleBoxFlat
	check(frame != null and frame.bg_color == source.bg_color and frame.border_width_top == authored.border_width_top and frame.border_width_left == authored.border_width_left, "button keeps color on the continuous authored frame")
	check(button.get_combined_minimum_size() == button_minimum and button.get_child_count() == button_children, "button layout and input nodes unchanged")
	var first := panel.get_theme_stylebox("panel") as StyleBoxTexture
	var again := SKIN.skin_style(source) as StyleBoxTexture
	check(first.texture == again.texture, "same palette reuses texture")
	for color in [Color("171020"), Color("8543c8"), Color("ef3f96")]:
		var colored := source.duplicate() as StyleBoxFlat
		colored.bg_color = color
		var colored_skin := SKIN.skin_style(colored) as StyleBoxTexture
		var pixels := colored_skin.texture.get_image()
		for corner in [Vector2i(0, 0), Vector2i(63, 0), Vector2i(0, 63), Vector2i(63, 63)]:
			check(pixels.get_pixelv(corner).a == 0.0, "highlight palette preserves transparent outer corners")
		check(pixels.get_pixel(32, 32).is_equal_approx(color), "interior keeps requested highlight color")
		check(pixels.get_pixel(32, 1).a > 0.0, "authored top edge remains visible")
	SKIN.apply(panel)
	check(panel.get_theme_stylebox("panel") == first, "idempotent application")
	check(SKIN.skin_style(StyleBoxEmpty.new()) is StyleBoxEmpty, "transparent style preserved")
	button.free()
	panel.free()
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	# Offline local account fixture: lift the CloudStore write fence (10-17).
	SCOPE.write_allowed = Callable()
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var state := STORE.load_state()
	state.slime = {"unlocked": true, "level": 0, "shards": 90}
	STORE.save_state(state)
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	await process_frame
	await process_frame
	var grid_size: Vector2 = lobby.team_monster_grid.size
	for card in lobby.team_monster_grid.get_children():
		# Since 10-08 (aa9056db) cards are framed by a rarity PNG nine-patch instead of a panel texture.
		var rarity_frame := card.get_node_or_null("FormationRarityFrame") as NinePatchRect
		check(rarity_frame != null and rarity_frame.visible and rarity_frame.texture != null, "dynamic monster card themed")
	var mode_frame := lobby.team_mode_button.get_theme_stylebox("disabled") as StyleBoxFlat
	check(mode_frame != null and mode_frame.border_width_top == authored.border_width_top, "active mode remains themed")
	await capture("team")
	lobby._upgrade_team_monster("slime")
	await process_frame
	check(lobby.team_monster_grid.size == grid_size and STORE.get_upgrade_level("slime") == 1, "upgrade preserves grid and gameplay")
	lobby._open_monster_detail("slime")
	check(lobby.monster_detail_normal_panel.get_theme_stylebox("panel") is StyleBoxTexture, "detail inner panel themed")
	await capture("detail")
	lobby._close_monster_detail()
	lobby._switch_tab("research")
	await process_frame
	check(lobby.research_detail_panel.get_theme_stylebox("panel") is StyleBoxTexture, "research details themed")
	await capture("research")
	lobby._switch_tab("other")
	await capture("other")
	lobby.free()
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	print("PIXEL_PANEL_SKIN_FAILED" if failed else "PIXEL_PANEL_SKIN_OK")
	quit(1 if failed else 0)
