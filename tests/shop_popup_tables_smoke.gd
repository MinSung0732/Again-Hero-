extends SceneTree
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var lobby

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SHOP_TABLES: " + message)

func settle() -> void:
	for i in range(8):
		await process_frame

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{name}", name))

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	SCOPE.guest_directory = "user://shop_tables_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	lobby._switch_tab("shop")
	var view = lobby.shop_popup_view
	for pickup in ["", "zeus"]:
		lobby._show_shop_rates_modal(pickup)
		await settle()
		var total := 0.0
		for rarity in SHOP.RARITY_ORDER:
			var color: Color = SHOP.get_rarity(rarity).color
			var summary = view.rates.get_node("Summary_" + rarity)
			check(summary.get_node("Rows/Row").get_child(0).get_theme_color("font_color") == color, "actual grade color " + rarity)
			check(summary.get_node("Rows/Row").get_child(1).text == "%.3f%%" % SHOP.get_effective_probability(rarity), "effective grade odds " + rarity)
			var group = view.rates.get_node("Group_" + rarity + "/Rows")
			for id in SHOP.get_monster_pool(rarity):
				var row = group.get_node("Monster_" + id)
				var odds := float(row.get_meta("probability"))
				total += odds
				check(is_equal_approx(odds, SHOP.get_monster_probability(id, pickup)), "same real draw odds " + id)
				check(row.get_child(0).get_child(0).texture != null, "icon or pixel sprite present " + id)
		check(is_equal_approx(total, 100.0), "all individual probabilities total one hundred")
		check(view.rates.has_node("PickupFeature") == (not pickup.is_empty()), "pickup feature visibility")
		if not pickup.is_empty():
			check(view.rates.get_node("PickupFeature/Rows").get_child(0).text.contains("3배"), "pickup multiplier copy valid")
		check(view.rates.size.x <= view.rates_scroll.size.x + 1, "rate columns fit")
		check(view.rates_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER, "scroll without scrollbar")
		await capture("rates" if pickup.is_empty() else "pickup")
		view.rates_scroll.scroll_vertical = 100000
		await settle()
		check(view.rates.get_child(-1).get_global_rect().end.y <= view.rates_scroll.get_global_rect().end.y + 1, "last grade note reachable")
		await capture("rates-bottom" if pickup.is_empty() else "pickup-bottom")
	lobby._close_shop_rates_modal()
	var entries: Array = []
	for i in range(100):
		var id: String = MONSTERS.ORDER[i % MONSTERS.ORDER.size()]
		entries.append({"monster_id":id, "rarity":MONSTERS.get_rarity(id), "shards":2, "unlocked":false})
	entries[99] = {"monster_id":"zeus", "rarity":"transcendent", "shards":0, "unlocked":true, "first_draw_unlock":true}
	entries[98] = {"monster_id":"succubus", "rarity":"legendary", "shards":3, "unlocked":true, "research_points":9}
	lobby.shop_summon_history = entries.duplicate(true)
	var before: Array = entries.duplicate(true)
	lobby._refresh_shop_summon_history()
	lobby._show_shop_result_modal()
	await settle()
	check(view.history.get_child_count() == 101, "one header and one hundred entries")
	check(view.history.get_node("Entry_0").get_meta("monster_id") == "zeus", "newest first")
	check(view.history.get_node("Entry_0/Rows/Row").get_child(-1).text == "첫 획득 · 해금", "first acquisition reward instead of fake shards")
	check(view.history.get_node("Entry_1/Rows/Row").get_child(-1).text.contains("연구 +9"), "research conversion retained")
	check(lobby.shop_summon_history == before, "presentation cannot mutate history")
	check(view.history.size.x <= view.history_scroll.size.x + 1, "history columns fit")
	await capture("history")
	view.history_scroll.scroll_vertical = 100000
	await settle()
	check(view.history.get_child(-1).get_global_rect().end.y <= view.history_scroll.get_global_rect().end.y + 1, "hundredth entry reachable")
	for size_to_use in [Vector2i(360,800), Vector2i(720,1280)]:
		root.size = size_to_use
		await settle()
		check(view.history.size.x <= view.history_scroll.size.x + 1, "responsive width " + str(size_to_use))
		check(lobby.shop_result_panel.get_global_rect().end.y < lobby.get_node("BottomNav").get_global_rect().position.y, "popup avoids footer " + str(size_to_use))
	print("SHOP_TABLES: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
