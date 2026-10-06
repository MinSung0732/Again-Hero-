extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const VIEW := preload("res://src/ui/team_formation_view.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("TEAM_RARITY_BORDER: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://team_rarity_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	STORE.award_shard_batch([{"monster_id":"banshee","shards":60},{"monster_id":"dullahan","shards":50},{"monster_id":"slime","shards":60}])
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._on_team_tab_pressed()
	await process_frame
	await process_frame
	var expected := {"common":Color("92929c"),"uncommon":Color("ffd84f"),"rare":Color("54a8ff"),"legendary":Color("bc70ff"),"transcendent":Color("61e887")}
	var slot: Button = lobby.team_slot_1_button
	for rarity in expected:
		check(VIEW.rarity_border_color(rarity) == expected[rarity], "five-rarity palette " + rarity)
		lobby._team_formation_view.apply_slot_border(slot, rarity)
		for state in ["normal","hover","pressed","disabled"]:
			check(slot.get_theme_stylebox(state) is StyleBoxFlat and slot.get_theme_stylebox(state).border_color == expected[rarity], "slot state " + rarity + ":" + state)
	for selected in [false,true]:
		lobby.team_selected_ids.assign(["dullahan"] if selected else ["slime"])
		for id in CATALOG.ORDER:
			var card: Control = lobby._create_team_monster_card(id)
			var style := card.get_theme_stylebox("panel") as StyleBoxFlat
			check(style != null and style.border_color == expected[CATALOG.get_rarity(id)], "card selection/upgrade border " + id)
			card.free()
	lobby.team_selected_ids.assign(["slime","banshee","dullahan"])
	lobby._refresh_team_preview()
	for i in range(3):
		var button: Button = [lobby.team_slot_1_button,lobby.team_slot_2_button,lobby.team_slot_3_button][i]
		check(button.get_theme_stylebox("normal").border_color == expected[CATALOG.get_rarity(lobby.team_selected_ids[i])], "equipped actual slot")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
	lobby.team_selected_ids.assign(["slime"])
	lobby._refresh_team_slot(slot,2)
	check(slot.get_theme_stylebox("normal").border_color == Color("685276"), "empty slot clears old rarity")
	lobby.free()
	await create_timer(0.2).timeout
	print("TEAM_RARITY_BORDER_FAILED" if failed else "TEAM_RARITY_BORDER_OK")
	quit(1 if failed else 0)
