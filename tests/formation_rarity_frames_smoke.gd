extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FORMATION_RARITY: " + message)

func run() -> void:
	root.size = Vector2i(540, 960)
	if "--narrow" in OS.get_cmdline_user_args(): root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://rarity_frames_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var ids := ["slime", "wolf", "medusa", "succubus"]
	var state := COLLECTION.load_state()
	for id in ids: state[id].unlocked = true
	check(COLLECTION.save_state(state), "isolated collection saved")
	check(preload("res://src/systems/team_loadout_store.gd").save_ids(["wolf", "medusa", "succubus"], ids), "three rarity slots saved")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	while lobby._formation_card_cache.pending: await process_frame
	# Small real collection fixture exposes all four frame designs in one view.
	lobby.team_catalog_ids.assign(ids)
	lobby.formation_sort_criterion = "rarity"
	lobby.formation_cost_descending = true
	lobby._refresh_team_preview()
	await process_frame
	await process_frame
	for card in lobby.team_monster_grid.get_children():
		var border := card.get_node("FormationRarityFrame") as NinePatchRect
		check(border.texture.resource_path.ends_with("formation_%s_frame.png" % CATALOG.get_rarity(card.formation_id)), "authored PNG matches monster rarity")
		check(card.get_global_rect().end.x <= lobby.size.x - 60, "ornament does not widen mobile grid")
		check(border.mouse_filter == Control.MOUSE_FILTER_IGNORE, "frame leaves card drag and actions interactive")
		var team: Button = card.find_child("TeamAction", true, false)
		var upgrade: Button = card.find_child("UpgradeAction", true, false)
		var inside: Rect2 = card.get_global_rect().grow(-16)
		check(inside.encloses(team.get_global_rect()) and inside.encloses(upgrade.get_global_rect()), "large action buttons remain inside rarity border")
		check(team.size.x >= card.size.x * 0.75 and upgrade.size.x == team.size.x, "each action uses most of card width")
		check(team.size.y >= 84 and upgrade.size.y >= 84 and upgrade.global_position.y >= team.get_global_rect().end.y + 7, "separate full-width touch rows")
	for slot in [lobby.team_slot_1_button, lobby.team_slot_2_button, lobby.team_slot_3_button]:
		check(slot.get_node("FormationRarityFrame").visible, "equipped slots retain rarity art")
	var slot: Button = lobby.team_slot_1_button
	var old_border: NinePatchRect = slot.get_node("FormationRarityFrame")
	lobby._team_formation_view.refresh_slot(slot, null, "빈 슬롯", "", false)
	check(not old_border.visible, "empty slot clears old rarity art")
	lobby._refresh_team_slot(slot, 0)
	check(old_border.visible and old_border == slot.get_node("FormationRarityFrame"), "slot update reuses its frame")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../formation-rarity-cards%s.png" % ("-narrow" if "--narrow" in OS.get_cmdline_user_args() else ""))
	lobby.free()
	await process_frame
	print("FORMATION_RARITY: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
