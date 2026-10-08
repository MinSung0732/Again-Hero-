extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FORMATION_SORT: " + message)


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://formation_sort_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	while lobby._formation_card_cache.pending:
		await process_frame
	for i in range(8):
		await process_frame
	var header: Control = lobby.get_node("SafeArea/Layout/Content/TeamTab/TeamLayout/ListHeader")
	var criteria: Control = header.get_node("SortCriteria")
	lobby.team_available_ids.assign(CATALOG.ORDER)
	for criterion in ["cost", "rarity"]:
		criteria.get_node("CostButton" if criterion == "cost" else "RarityButton").pressed.emit()
		for descending in [false, true]:
			(lobby.formation_cost_high_button if descending else lobby.formation_cost_low_button).pressed.emit()
			var ids: Array = lobby._sorted_formation_ids(CATALOG.ORDER)
			check(ids.size() == CATALOG.ORDER.size(), "sorting keeps every monster")
			for i in range(1, ids.size()):
				var previous: float = CATALOG.get_base_cost(ids[i - 1]) if criterion == "cost" else SHOP.get_rarity_rank(CATALOG.get_rarity(ids[i - 1]))
				var current: float = CATALOG.get_base_cost(ids[i]) if criterion == "cost" else SHOP.get_rarity_rank(CATALOG.get_rarity(ids[i]))
				check(previous >= current if descending else previous <= current, "%s descending=%s %s %.2f -> %s %.2f" % [criterion, descending, ids[i - 1], previous, ids[i], current])
			await process_frame
			check(header.get_global_rect().end.x <= lobby.size.x + 1, "sort controls fit mobile width")
			check(header.get_node("CostSortButtons").get_global_rect().end.x <= header.get_global_rect().end.x + 1, "buttons do not overflow")
	lobby.team_available_ids.assign(["slime"])
	var locked: Control = lobby._create_team_monster_card("succubus")
	var unlocked: Control = lobby._create_team_monster_card("slime")
	check(locked.modulate.r < unlocked.modulate.r and locked.modulate.a == 1.0, "locked card darkens without becoming transparent")
	check(not locked.drag_enabled and unlocked.drag_enabled, "locked card stays unavailable for formation")
	locked.free()
	unlocked.free()
	check(lobby._sorted_formation_ids(CATALOG.ORDER)[0] == "slime", "unlocked-first grouping retained")
	lobby._show_formation_mode("skill")
	check(not criteria.visible, "monster rarity controls hidden in skill mode")
	var skills: Array = lobby._sorted_formation_ids(lobby.demon_skill_catalog_ids)
	for i in range(1, skills.size()):
		check(lobby._formation_item_cost(skills[i - 1]) >= lobby._formation_item_cost(skills[i]), "skill cost ordering retained")
	lobby._show_formation_mode("team")
	check(criteria.visible and lobby.formation_sort_criterion == "rarity", "monster criterion retained after mode switch")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
	lobby.free()
	await create_timer(0.2).timeout
	print("FORMATION_SORT: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
