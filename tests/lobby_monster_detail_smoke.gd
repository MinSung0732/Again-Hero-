extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("MONSTER_DETAIL: " + message)
func settle() -> void:
	for i in range(8):
		await process_frame
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://detail_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	var scroll: ScrollContainer = lobby.get_node("MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll")
	var compare: Control = scroll.get_node("Compare")
	for id in CATALOG.ORDER:
		lobby._open_monster_detail(id)
		await settle()
		check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "hidden scrollbar")
		check(compare.size.x <= scroll.size.x + 1, "columns fit viewport " + id)
		for label in [lobby.monster_detail_normal_stats, lobby.monster_detail_elite_stats, lobby.monster_detail_elite_skills]:
			if label.is_visible_in_tree():
				check(label.size.y >= label.get_content_height(), "entire rich text laid out " + id)
		check(compare.get_node("ElitePanel").visible == bool(CATALOG.MONSTERS[id].get("can_be_elite",true)), "elite capability shown " + id)
		check(lobby.monster_detail_close_button.get_global_rect().end.y < scroll.get_global_rect().position.y, "close stays above scroll")
		if id in ["banshee", "goblin_thrower", "dullahan", "kraken", "medusa", "mummy", "powwow_mummy"] and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{id}", id))
		scroll.scroll_vertical = 100000
		await settle()
		var last: Control = compare.get_node("ElitePanel/Margin/VBox/Note")
		if last.is_visible_in_tree():
			check(last.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "last note reachable " + id)
		check(lobby.monster_detail_specials.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "last special reachable " + id)
		if id == "banshee" and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{id}", "banshee-bottom"))
		lobby._close_monster_detail()
	lobby._open_monster_detail("banshee")
	await settle()
	check(scroll.scroll_vertical == 0, "reopen resets scroll")
	lobby.free()
	await create_timer(0.2).timeout
	print("MONSTER_DETAIL_SMOKE_FAILED" if failed else "MONSTER_DETAIL_SMOKE_OK")
	quit(1 if failed else 0)
