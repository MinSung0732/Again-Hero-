extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("TRANSCENDENCE_LAYOUT: "+message)
func settle() -> void:
	for i in range(8): await process_frame
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://transcendence_layout_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	for id in preload("res://src/data/transcendence_catalog.gd").get_ids(): state[id] = {"unlocked":true,"shards":1,"level":0}
	COLLECTION.save_state(state)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(540,960)
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	lobby._switch_tab("team")
	lobby._show_formation_mode("transcendence")
	await settle()
	var view = lobby.transcendence_view
	for dimensions in [Vector2i(540,960),Vector2i(360,800),Vector2i(1280,720)]:
		root.size = dimensions
		await settle()
		var scroll: ScrollContainer = view.grid.get_parent()
		var card: Control = view.grid.get_child(0)
		print("LAYOUT ",dimensions," lobby=",lobby.size," list=",scroll.size," card=",card.size," registered=",view.registered_area.size)
		for entry in view.grid.get_children():
			check(scroll.size.y>=entry.size.y,"all card heights fit "+str(dimensions))
		check(scroll.size.y>=card.size.y,"one full card fits "+str(dimensions))
		check(scroll.get_global_rect().encloses(card.get_global_rect()),"first card fully visible "+str(dimensions))
	check(CATALOG.get_ui_icon_path("manticore").ends_with("/frames/idle_01.png"),"manticore dot path")
	check(CATALOG.get_role_label("exploder")=="폭발","localized role")
	check(preload("res://src/data/profile_cosmetic_catalog.gd").path("manticore","avatar").ends_with("manticore_icon.png"),"profile reward remains its icon")
	root.size = Vector2i(540,960)
	await settle()
	view._register("manticore")
	await settle()
	var registered: Control = view.registered.get_child(0)
	check(registered.find_child("ProfileBanner",true,false)!=null,"registered banner kept")
	check(registered.size.y<=view.registered_area.size.y,"registered card fits")
	check(view.registered_area.scroll_vertical==0,"registered slot does not require scrolling")
	view._upgrade("manticore")
	await settle()
	check(COLLECTION.get_upgrade_level("manticore")==1,"compact card keeps actual upgrade")
	lobby._show_formation_mode("team")
	await settle()
	check(not view.content.visible and not view.registered_area.visible,"ordinary mode restored")
	lobby.free()
	await process_frame
	print("TRANSCENDENCE_LAYOUT "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
