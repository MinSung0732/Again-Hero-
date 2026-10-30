extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var seen_week := ""
func fake_rpc(method: String, args: Dictionary) -> Dictionary:
	if method == "mark_ranked_season_seen": seen_week = args.get("p_week_start", "")
	return {"seen":true}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://season_popup_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	root.get_node("LocalTestMode").active = true
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	await process_frame
	var view = lobby.ranked_season_popup
	assert(view.shown and view.result.demon.final_mmr == 2300 and view.result.hero.server_rank == 3)
	assert(view.result.demon_token == 18 and view.result.hero_token == 18)
	var overlay = lobby.get_node("RankedSeasonOverlay")
	var labels: Array = overlay.find_children("*", "Label", true, false)
	var rendered := " ".join(labels.map(func(label): return label.text))
	assert("2300" in rendered and "3000" in rendered and "3위" in rendered and "18" in rendered)
	var icons: Array = overlay.find_children("*", "TextureRect", true, false)
	assert(icons.size() == 4)
	for icon in icons: assert(icon.texture != null)
	var buttons: Array = overlay.find_children("*", "Button", true, false)
	assert(buttons.size() == 2 and buttons[0].text == "우편함으로" and buttons[1].text == "확인")
	buttons[0].pressed.emit()
	await process_frame
	assert(lobby.current_tab == "other" and lobby.settings_view.mailbox_view.root.visible)
	view.shown = false
	view.refresh()
	await process_frame
	assert(not view.shown)
	root.get_node("LocalTestMode").active = false
	view.shown = false
	view.refresh()
	await process_frame
	assert(not view.shown)
	view.local = false
	view.rpc_override = fake_rpc
	var confirmation := Control.new()
	lobby.add_child(confirmation)
	await view._close(false, confirmation)
	assert(seen_week == "local-preview")
	lobby.queue_free()
	print("PASS ranked_season_popup_smoke")
	quit()