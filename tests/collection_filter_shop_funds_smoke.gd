extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FILTER_FUNDS_TEST: " + message)

func set_gold(amount: int) -> void:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PROGRESS.SAVE_PATH)
	config.set_value("meta", "gold", amount)
	check(SCOPE.save_config(config, PROGRESS.SAVE_PATH) == OK, "gold fixture saved")

func ids(lobby: Control) -> Array:
	var result := []
	for card in lobby.team_monster_grid.get_children():
		result.append(card.formation_id)
	return result

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://collection-" + name + "-preview.png")

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	var folder := "user://filter_funds_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var lobby: Control = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	await process_frame
	await process_frame
	var selected: Array = lobby.team_selected_ids.duplicate()
	var ordered: Array = ids(lobby)
	check(ordered.size() == CATALOG.ORDER.size(), "all monsters shown")
	for descending in [false, true]:
		lobby._on_formation_cost_sort_selected(descending)
		ordered = ids(lobby)
		var locked_seen := false
		for id in ordered:
			if id not in lobby.team_available_ids:
				locked_seen = true
			else:
				check(not locked_seen, "unlocked always before locked")
		for index in range(1, ordered.size()):
			var previous: String = ordered[index-1]
			var id: String = ordered[index]
			if (previous in lobby.team_available_ids) == (id in lobby.team_available_ids):
				var a := CATALOG.get_base_cost(previous)
				var b := CATALOG.get_base_cost(id)
				check(a >= b if descending else a <= b, "cost sort within unlock group")
	var filters := lobby.get_node("SafeArea/Layout/Content/TeamTab/TeamLayout/UnlockFilters")
	filters.get_node("UnlockedButton").pressed.emit()
	check(ids(lobby).size() == 3, "three unlocked starters")
	await capture("unlocked")
	for card in lobby.team_monster_grid.get_children():
		check(card.drag_enabled and card.tapped.is_connected(lobby._open_monster_detail.bind(card.formation_id)), "unlocked details/drag unchanged")
	filters.get_node("LockedButton").pressed.emit()
	check(ids(lobby).size() == CATALOG.ORDER.size()-3, "locked filter count")
	await capture("locked")
	for card in lobby.team_monster_grid.get_children():
		check(not card.drag_enabled, "locked cannot drag")
	check(lobby.team_selected_ids == selected, "filter never modifies team")
	lobby._show_formation_mode("skill")
	check(not filters.visible and lobby.team_monster_grid.get_child_count() == lobby.demon_skill_catalog_ids.size(), "skills not filtered")
	lobby._show_formation_mode("team")
	check(filters.visible and lobby.formation_unlock_filter == "locked", "filter retained on return")
	var state := STORE.load_state()
	for id in CATALOG.ORDER:
		state[id].unlocked = true
	STORE.save_state(state)
	lobby._restore_saved_team_selection()
	check(ids(lobby).is_empty() and lobby.get_node("SafeArea/Layout/Content/TeamTab/TeamLayout/EmptyCollection").visible, "empty filter explains no results")
	filters.get_node("AllButton").pressed.emit()
	check(ids(lobby).size() == CATALOG.ORDER.size(), "all filter recovers list")
	lobby._switch_tab("shop")
	var single := lobby.shop_single_button.get_node("SummonButton") as Button
	var multi := lobby.shop_multi_button.get_node("SummonButton") as Button
	for amount in [0, 99, 100, 999, 1000]:
		set_gold(amount)
		lobby._refresh_header()
		check(single.disabled == (amount < 100) and multi.disabled == (amount < 1000), "cost threshold " + str(amount))
	check(not lobby.shop_single_button.disabled and not lobby.shop_multi_button.disabled, "passive card ancestors stay enabled")
	set_gold(0)
	lobby._refresh_header()
	await capture("insufficient-gold")
	set_gold(100)
	lobby._refresh_header()
	lobby._open_monster_boxes(1)
	check(PROGRESS.get_gold() == 0 and single.disabled and multi.disabled, "actual summon immediately disables after spending")
	root.get_node("LocalTestMode").active = true
	lobby._refresh_header()
	check(not single.disabled and not multi.disabled, "localtest retains free draws")
	root.get_node("LocalTestMode").active = false
	lobby.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	SCOPE.select_guest()
	print("COLLECTION_FILTER_SHOP_FUNDS_FAILED" if failed else "COLLECTION_FILTER_SHOP_FUNDS_OK")
	quit(1 if failed else 0)
