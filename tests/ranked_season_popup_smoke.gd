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
	assert(view.result.demon_token == 250 and view.result.hero_token == 250)
	var overlay = lobby.get_node("RankedSeasonLayer/RankedSeasonOverlay")
	assert(overlay is ColorRect and overlay.mouse_filter == Control.MOUSE_FILTER_STOP and overlay.color.a > 0.0)
	for viewport_size in [Vector2i(1080, 1920), Vector2i(1080, 2400)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		var rect: Rect2 = view.panel.get_global_rect()
		assert(rect.position.x >= 16 and rect.end.x <= viewport_size.x - 16)
		assert(absf(rect.get_center().x - viewport_size.x / 2.0) < 2.0)
		assert(absf(rect.get_center().y - viewport_size.y / 2.0) < 2.0)
	var labels: Array = overlay.find_children("*", "Label", true, false)
	var rendered := " ".join(labels.map(func(label): return label.text))
	assert("2300" in rendered and "3000" in rendered and "3위" in rendered and "250" in rendered and "주력 역할: 탱커" in rendered)
	assert(overlay.find_child("HeroRow", true, false).get_node("Portrait").texture != null)
	assert(overlay.find_child("DemonRow", true, false).get_node("Portrait").texture != null)
	var icons: Array = overlay.find_children("*", "TextureRect", true, false)
	assert(icons.size() == 6)
	for icon in icons: assert(icon.texture != null)
	var saved_result: Dictionary = view.result.duplicate(true)
	view.result.hero.wins = 0
	view.result.demon.wins = 0
	view._build()
	var empty_overlay = lobby.get_children().back()
	for row_name in ["HeroRow", "DemonRow"]:
		var row = empty_overlay.find_child(row_name, true, false)
		assert(row.get_child_count() == 1 and row.get_node("TierFallback").texture != null)
	empty_overlay.queue_free()
	view.result = saved_result
	var buttons: Array = overlay.find_children("*", "Button", true, false)
	assert(buttons.size() == 2 and buttons[0].text == "우편함으로" and buttons[1].text == "확인")
	for button in buttons:
		assert(button.size.y >= 120 and button.get_global_rect().end.y <= root.size.y)
	buttons[0].pressed.emit()
	await process_frame
	assert(lobby.mailbox_view.root.visible)
	lobby._switch_tab("main")
	await process_frame
	var trays = lobby.main_tools_view
	var rail: VBoxContainer = trays._rails[&"right"]
	var friends: Button = rail.get_child(0)
	var mailbox: Button = rail.get_child(1)
	assert(friends.tooltip_text == "친구목록" and mailbox.tooltip_text == "우편함")
	assert(friends.size == mailbox.size and mailbox.position.y > friends.position.y)
	assert((mailbox.get_child(0) as TextureRect).texture != null)
	trays.set_notification_count(&"mailbox", 2)
	assert(mailbox.get_node("NotificationDot").visible and mailbox.get_node("NotificationDot/Count").text == "2")
	trays.set_notification_count(&"mailbox", 0)
	assert(not mailbox.get_node("NotificationDot").visible)
	mailbox.pressed.emit()
	await process_frame
	assert(lobby.mailbox_view.root.visible)
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