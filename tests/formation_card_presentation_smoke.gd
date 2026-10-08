extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FORMATION_CARD: " + message)

func settle(lobby: Control) -> void:
	for i in range(120):
		if not lobby._formation_card_cache.pending:
			break
		await process_frame
	await process_frame
	await process_frame
	check(not lobby._formation_card_cache.pending, "cold collection finishes")

func capture(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../" + name + ".png")

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://formation_card_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	state.zeus = {"unlocked": true, "shards": 3, "level": 2}
	for id in ["slime", "spider", "orc", "wolf"]:
		state[id]["unlocked"] = true
	check(COLLECTION.save_state(state), "isolated collection")
	if "--no-warmup" not in OS.get_cmdline_user_args():
		await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
		for id in preload("res://src/data/monster_catalog.gd").ORDER:
			var data: Dictionary = preload("res://src/data/monster_catalog.gd").get_monster(id)
			var path := String(data.get("display_icon_path", data.get("card_icon_path", "")))
			check(root.get_node("PresentationWarmup").get_cropped(path) != null or data.has("card_icon_region"), "icon prepared before navigation: " + id)
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	var cache = lobby._formation_card_cache
	var before: int = cache.created_count
	var start := Time.get_ticks_usec()
	lobby._on_team_tab_pressed()
	print("FORMATION_ENTRY_HANDLER_US: ", Time.get_ticks_usec() - start)
	check(lobby.team_tab.visible, "tab opens immediately")
	check(cache.created_count == before and cache.pending, "input frame creates no cold cards")
	await settle(lobby)
	check(cache.max_created_in_slice <= 3, "cold construction is bounded per frame")
	check(lobby.team_monster_grid.get_child_count() == lobby.team_catalog_ids.size(), "all ordinary cards populated")
	check(cache.created_count == lobby.team_catalog_ids.size(), "each ordinary card built only once")
	var slime: Control = cache.cards.slime.card
	slime._begin_hold(Vector2(10, 10))
	before = cache.created_count
	lobby._switch_tab("main")
	lobby._on_team_tab_pressed()
	check(cache.created_count == before and cache.cards.slime.card == slime, "re-entry reuses cards")
	check(not slime.is_processing() and not slime._hold_active, "cached card cancels pending drag hold")
	lobby._on_formation_cost_sort_selected(true)
	check(cache.created_count == before, "sorting reorders without rebuilding")
	var wolf: Control = cache.cards.wolf.card
	check(wolf.get_meta("team_action").disabled, "full formation blocks unselected card")
	lobby._toggle_team_monster("slime")
	check(not wolf.get_meta("team_action").disabled and wolf == cache.cards.wolf.card, "capacity change updates unchanged cached action")
	before = cache.created_count
	lobby._show_formation_mode("transcendence")
	await process_frame
	await process_frame
	var view = lobby.transcendence_view
	var grid_y: float = view.grid.global_position.y
	var card: Control = view.grid.get_child(0)
	var portrait: TextureRect = card.find_child("MonsterPortrait", true, false)
	var icon: Texture2D = portrait.texture
	check(portrait.texture.get_size() == Vector2(1254, 1254), "authored Zeus icon used, not idle sprite")
	check(portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel icon uses nearest")
	check(card.find_child("TranscendentFrame", true, false) is NinePatchRect, "rarity PNG frame attached")
	check(card.find_child("MonsterName", true, false).text == "제우스", "card name readable")
	check(card.find_child("RarityLabel", true, false).text == "초월  ·  Lv.2 / 5", "rarity and progression explicit")
	check(card.get_global_rect().end.x <= lobby.size.x - 60, "card fits mobile width")
	await capture("transcendent-card-unregistered")
	check(card.formation_kind == "transcendence" and card.drag_enabled, "owned transcendent supports long hold")
	var scroll: ScrollContainer = view.grid.get_parent()
	var filler := Control.new()
	filler.custom_minimum_size.y = 1800
	view.grid.add_child(filler)
	await process_frame
	var old_filter := scroll.mouse_filter
	card._begin_hold(Vector2(40, 40))
	card._process(0.30)
	check(root.gui_is_dragging(), "transcendent starts a real drag")
	check(scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE, "drag suspends panel scrolling")
	var saved_position := scroll.scroll_vertical
	scroll.get_v_scroll_bar().value += 100
	check(scroll.scroll_vertical == saved_position, "drag locks inertia/edge scrolling")
	check(not view.registered_area._can_drop_data(Vector2.ZERO, {"formation_kind": "monster", "formation_id": "slime"}), "ordinary units cannot enter transcendence slot")
	var target: Vector2 = view.registered_area.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = target
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = target
	release.button_index = MOUSE_BUTTON_LEFT
	root.push_input(release, true)
	await process_frame
	check(preload("res://src/systems/transcendence_loadout_store.gd").load_id() == "zeus", "viewport drop registers actual monster")
	check(not root.gui_is_dragging() and scroll.mouse_filter == old_filter, "drop restores scroll")
	await process_frame
	await process_frame
	check(absf(view.grid.global_position.y - grid_y) <= 1, "registration never shifts list")
	check(view.registered_area.size.y == 244, "equipped viewport fixed height")
	var equipped: Control = view.registered.get_child(0)
	check(equipped.get_combined_minimum_size().y <= 244, "equipped card fits fixed viewport")
	check(equipped.find_child("MonsterPortrait", true, false).texture == icon, "shared icon texture cached")
	check(equipped.find_child("ProfileBanner", true, false) is TextureRect, "original profile banner attached")
	check(not equipped.find_child("MonsterPortrait", true, false).visible, "banner replaces compact portrait")
	var inner := equipped.get_global_rect().grow(-12)
	var action: Button = equipped.find_child("RegisterButton", true, false)
	for item in action.get_parent().get_children():
		var draw: Rect2 = item.get_global_rect()
		var style: StyleBox = item.get_theme_stylebox("normal")
		if style is StyleBoxFlat or style is StyleBoxTexture:
			draw.position -= Vector2(style.expand_margin_left, style.expand_margin_top)
			draw.size += Vector2(style.expand_margin_left + style.expand_margin_right, style.expand_margin_top + style.expand_margin_bottom)
		check(inner.encloses(draw), "registered action artwork stays inside frame")
	await capture("transcendent-card-registered")
	view._upgrade("zeus")
	check(COLLECTION.get_upgrade_level("zeus") == 3, "card action preserves actual transcendence")
	check(is_instance_valid(view.feedback) and view.feedback.transcendent, "upgrade absorption effect preserved")
	lobby._show_formation_mode("team")
	await settle(lobby)
	check(cache.created_count == before, "mode round trip reuses ordinary cards")
	# Cancel cold population midway: a stale coroutine cannot insert ordinary cards
	# into the skill list or complete an obsolete sort/filter generation.
	var old_card: Control = cache.cards.mummy.card
	old_card.get_parent().remove_child(old_card)
	old_card.free()
	cache.cards.erase("mummy")
	lobby._refresh_team_preview()
	lobby._show_formation_mode("skill")
	for i in range(10): await process_frame
	for child in lobby.team_monster_grid.get_children():
		check(child.formation_kind == "skill", "cancelled build never corrupts skill grid")
	lobby.free()
	await process_frame
	print("FORMATION_CARD: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
