extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("TRANSCEND_UPGRADE: " + message)

func settle() -> void:
	for i in range(5):
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
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8), hex.substr(8,4), hex.substr(12,4), hex.substr(16,4), hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated fixture account")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	check(CATALOG.get_shards_required("zeus") == 1 and CATALOG.get_max_upgrade_level("zeus") == 5, "transcend cost/cap")
	check(CATALOG.get_max_upgrade_level("slime") == 30 and CATALOG.get_shard_research_points("slime") == 1, "ordinary rules preserved")
	check(SHOP.RARITIES.transcendent.shard_min == 1 and SHOP.RARITIES.transcendent.shard_max == 1, "one shard per draw")
	for source in ["summon", "pickup"]:
		var state := STORE.load_state()
		state.zeus = {"unlocked": false, "level": 0, "shards": 0}
		check(STORE.save_state(state), "reset acquisition fixture")
		var award := STORE.award_shard_batch([{"monster_id": "zeus", "source": source, "shards": 1}])
		check(award.success and award.awards[0].first_draw_unlock and STORE.get_shards("zeus") == 0, source + " first unlock consumes acquisition")
		for lv in range(1, 6):
			award = STORE.award_shard_batch([{"monster_id": "zeus", "source": source, "shards": 1}])
			check(award.success and STORE.get_shards("zeus") == 1, "duplicate yields one")
			var upgrade := STORE.try_upgrade("zeus")
			check(upgrade.success and upgrade.level == lv and upgrade.shards == 0, "one consumed at level " + str(lv))
		check(STORE.try_upgrade("zeus").get("reason") == "max_level", "sixth upgrade blocked")
		var before := PROGRESS.get_research_points()
		var serial := SCOPE.serial
		award = STORE.award_shard_batch([{"monster_id": "zeus", "source": source, "shards": 1}, {"monster_id": "zeus", "source": source, "shards": 1}])
		check(award.success and award.research_points == 2000 and PROGRESS.get_research_points() == before + 2000 and STORE.get_shards("zeus") == 0, "maxed batch converts each shard1000")
		check(SCOPE.serial == serial + 1, "batch conversion atomic")
	var state := STORE.load_state()
	state.zeus = {"unlocked": true, "level": 4, "shards": 3}
	STORE.save_state(state)
	var result := STORE.try_upgrade("zeus")
	check(result.success and result.level == 5 and result.research_points == 2000 and result.shards == 0, "last upgrade converts leftovers")
	var old := ConfigFile.new()
	SCOPE.load_config(old, STORE.SAVE_PATH)
	old.set_value("monsters", "zeus_level", 30)
	old.set_value("monsters", "zeus_shards", 2)
	SCOPE.save_config(old, STORE.SAVE_PATH)
	var before := PROGRESS.get_research_points()
	check(STORE.normalize_maxed().success and STORE.get_upgrade_level("zeus") == 5 and PROGRESS.get_research_points() == before + 2000, "legacy cap and conversion")
	STORE.normalize_maxed()
	check(PROGRESS.get_research_points() == before + 2000, "normalization idempotent")
	state = STORE.load_state()
	state.zeus = {"unlocked": true, "level": 4, "shards": 3}
	STORE.save_state(state)
	SCOPE.files["unexpected.cfg"] = {}
	before = PROGRESS.get_research_points()
	check(STORE.try_upgrade("zeus").get("reason") == "save_failed", "failed save reported")
	SCOPE.files.erase("unexpected.cfg")
	check(STORE.get_upgrade_level("zeus") == 4 and STORE.get_shards("zeus") == 3 and PROGRESS.get_research_points() == before, "failed atomic upgrade rolls back")
	state = STORE.load_state()
	state.zeus = {"unlocked": true, "level": 5, "shards": 0}
	STORE.save_state(state)
	SCOPE.files["unexpected.cfg"] = {}
	before = PROGRESS.get_research_points()
	var rejected := STORE.award_shard_batch([{ "monster_id": "zeus", "source": "pickup", "shards": 1}])
	check(not rejected.success and rejected.research_points == 0 and rejected.awards.is_empty(), "failed draw conversion reports no payout")
	SCOPE.files.erase("unexpected.cfg")
	check(STORE.get_shards("zeus") == 0 and PROGRESS.get_research_points() == before, "failed draw leaves balances unchanged")
	SCOPE.guest_directory = "user://transcend_layout_" + hex
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	state = STORE.load_state()
	state.zeus = {"unlocked": true, "level": 0, "shards": 2}
	STORE.save_state(state)
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	lobby._show_formation_mode("transcendence")
	await settle()
	var view = lobby.transcendence_view
	var card: Control
	for candidate in view.grid.get_children():
		if candidate.get_meta("monster_id","") == "zeus":
			card = candidate
			break
	check(card != null,"select actual Zeus card independently of collection order")
	if card == null:
		quit(1)
		return
	var action: Button = card.find_child("TranscendButton", true, false)
	check(action.text == "초월  ·  조각 1개" and not action.disabled, "transcend action enabled")
	action.pressed.emit()
	var effect: Node2D = view.feedback
	check(is_instance_valid(effect) and effect.visible and effect.transcendent and effect.level == 1, "success effect on actual card")
	var portrait: TextureRect = effect._portrait
	check(is_instance_valid(portrait) and portrait.scale == Vector2.ONE, "sprite fixed scale")
	await create_timer(0.14).timeout
	await capture("panel")
	var parent_size: Vector2 = effect.get_parent().size
	var center: Vector2 = effect._center
	await create_timer(0.38).timeout
	await capture("absorb")
	check(effect.visible and portrait.scale == Vector2.ONE and effect._center.is_equal_approx(center), "stationary absorption")
	view._upgrade("zeus")
	check(view.feedback == effect and effect.elapsed == 0.0 and effect.level == 2, "repeat reuses effect")
	await settle()
	check(effect.get_parent().size == parent_size, "no card resizing")
	view._upgrade("zeus")
	check(not effect.visible and STORE.get_upgrade_level("zeus") == 2, "failed upgrade has no success effect")
	effect.restart(2, true)
	portrait = effect._portrait
	await create_timer(1.15).timeout
	check(not effect.visible and not effect.is_processing() and portrait.scale == Vector2.ONE and portrait.self_modulate == Color.WHITE, "expiry restores sprite")
	effect.restart(2, true)
	lobby._show_formation_mode("team")
	await settle()
	check(not effect.visible and portrait.self_modulate == Color.WHITE, "tab cancellation")
	state = STORE.load_state()
	state.zeus = {"unlocked": true, "level": 5, "shards": 0}
	STORE.save_state(state)
	lobby._show_formation_mode("transcendence")
	await settle()
	for candidate in view.grid.get_children():
		if candidate.get_meta("monster_id","") == "zeus":
			action = candidate.find_child("TranscendButton",true,false)
			break
	check(action.text == "최대 초월 완료" and action.disabled, "max cap disabled in UI")

	# Registration must not steal height from the monster list or move mode tabs.
	for viewport_size in [Vector2i(540, 960), Vector2i(360, 800)]:
		root.size = viewport_size
		view._register("")
		await settle()
		var list_rect: Rect2 = view.grid.get_parent().get_global_rect()
		var tabs_rect: Rect2 = view.layout.get_node("ModeTabs").get_global_rect()
		var grid_rect: Rect2 = view.grid.get_global_rect()
		await capture("unregistered" + str(viewport_size.x))
		for cycle in range(3):
			view._register("zeus")
			await settle()
			check(preload("res://src/systems/transcendence_loadout_store.gd").load_id() == "zeus", "actual registration saved")
			check(view.grid.get_parent().get_global_rect().is_equal_approx(list_rect), "registered list position/height fixed " + str(viewport_size))
			check(view.layout.get_node("ModeTabs").get_global_rect().is_equal_approx(tabs_rect), "registered tabs fixed")
			check(view.grid.get_global_rect().is_equal_approx(grid_rect), "registered grid bounds fixed")
			check(view.registered.get_combined_minimum_size().y <= view.registered_area.size.y + 1, "registered card fits viewport")
			if cycle == 0:
				await capture("registered" + str(viewport_size.x))
			view._register("")
			await settle()
			check(view.grid.get_parent().get_global_rect().is_equal_approx(list_rect), "unregistration restores same list height")
	root.size = Vector2i(360, 800)
	await settle()
	card = view.grid.get_child(0)
	for button in card.find_children("*", "Button", true, false):
		check(button.get_global_rect().end.x <= card.get_global_rect().end.x + 1, "narrow card button bounds")
	await capture("narrow")
	lobby.free()
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	for file in DirAccess.get_files_at(SCOPE.guest_directory):
		DirAccess.remove_absolute(SCOPE.guest_directory.path_join(file))
	DirAccess.remove_absolute(SCOPE.guest_directory)
	SCOPE.guest_directory = "user://"
	print("TRANSCEND_UPGRADE: FAIL" if failed else "TRANSCEND_UPGRADE: PASS")
	quit(1 if failed else 0)
