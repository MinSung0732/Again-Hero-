extends SceneTree
## Actual stores/catalogs/profile picker; in-memory scope and synthetic textures.
var checks := 0
var failures := 0
var files: Array[String] = []
class Cloud extends Node:
	var busy := false
	var conflict := false
class Warmup extends Node:
	func get_texture(path: String) -> Texture2D: return load(path) as Texture2D if ResourceLoader.exists(path) else null
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func fixture(name: String, text: String) -> String:
	var path := "user://initial-gender-smoke-"+name+".gd"
	files.append(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text); file.close()
	return path
func art_source(path: String, art: String) -> String:
	var regex := RegEx.new()
	regex.compile('res://assets/[^"\\n]+')
	return regex.sub(FileAccess.get_file_as_string(path), art, true)
func run() -> void:
	var art := "user://initial-gender-smoke-texture.tres"
	var image := Image.create(4,4,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	ResourceSaver.save(ImageTexture.create_from_image(image),art)
	files.append(art)
	var scope_path := fixture("scope", "extends RefCounted\nstatic var user_id := \"fixture-account\"\nstatic var guest_directory := \"fixture\"\nstatic var text := \"\"\nstatic var saves := 0\nstatic var fail_save := false\nstatic func load_config(config: ConfigFile, _path: String) -> int: return config.parse(text) if not text.is_empty() else ERR_FILE_NOT_FOUND\nstatic func save_config(config: ConfigFile, _path: String) -> int:\n\tif fail_save: return ERR_CANT_CREATE\n\ttext = config.encode_to_text(); saves += 1; return OK\n")
	var catalog_path := fixture("appearances", art_source("res://src/data/demon_appearance_catalog.gd",art))
	var appearance_path := fixture("appearance", FileAccess.get_file_as_string("res://src/systems/demon_appearance_store.gd").replace("res://src/systems/account_save_scope.gd",scope_path).replace("res://src/data/demon_appearance_catalog.gd",catalog_path))
	var profile_path := fixture("profile", "extends RefCounted\nconst SCOPE = preload(\""+scope_path+"\")\nconst APPEARANCE = preload(\""+appearance_path+"\")\nstatic func get_profile() -> Dictionary:\n\tvar config := ConfigFile.new()\n\tSCOPE.load_config(config,\"fixture\")\n\treturn config.get_value(\"player_profile\",\"value\",{})\nstatic func appearance_id() -> String: return APPEARANCE.equipped_id(String(get_profile().get(\"gender\",\"male\")))\n")
	var collection_path := fixture("collection", "extends RefCounted\nstatic func load_state() -> Dictionary: return {}\nstatic func is_unlocked(id: String, _state: Dictionary) -> bool: return id == \"zeus\"\nstatic func get_upgrade_level(_id: String, _state: Dictionary) -> int: return 5\n")
	var monsters_path := fixture("monsters", "extends RefCounted\nstatic func get_rarity(_id: String) -> String: return \"transcendent\"\n")
	var cosmetics_path := fixture("cosmetics", art_source("res://src/data/profile_cosmetic_catalog.gd",art).replace("res://src/data/demon_appearance_catalog.gd",catalog_path))
	var store_path := fixture("store", FileAccess.get_file_as_string("res://src/systems/profile_cosmetic_store.gd").replace("res://src/systems/account_save_scope.gd",scope_path).replace("res://src/systems/player_profile.gd",profile_path).replace("res://src/systems/demon_appearance_store.gd",appearance_path).replace("res://src/systems/monster_collection_store.gd",collection_path).replace("res://src/data/monster_catalog.gd",monsters_path).replace("res://src/data/profile_cosmetic_catalog.gd",cosmetics_path))
	var frames_path := fixture("frames", "extends RefCounted\nstatic func style(_name: String, _size: int, _color: Color = Color.WHITE) -> StyleBox: return StyleBoxFlat.new()\n")
	var button_path := fixture("button", FileAccess.get_file_as_string("res://src/ui/drag_safe_button.gd"))
	var icon_path := fixture("icon-picker", FileAccess.get_file_as_string("res://src/ui/lobby_profile_icon_picker.gd").replace("res://src/systems/profile_cosmetic_store.gd",store_path).replace("res://src/data/profile_cosmetic_catalog.gd",cosmetics_path).replace("res://src/ui/commerce_frame_skin.gd",frames_path).replace("res://src/ui/drag_safe_button.gd",button_path))
	var view_source := FileAccess.get_file_as_string("res://src/ui/lobby_profile_view.gd").replace("res://src/systems/player_profile.gd",profile_path).replace("res://src/systems/profile_cosmetic_store.gd",store_path).replace("res://src/data/profile_cosmetic_catalog.gd",cosmetics_path).replace("res://src/systems/demon_appearance_store.gd",appearance_path).replace("res://src/data/demon_appearance_catalog.gd",catalog_path).replace("res://src/ui/commerce_frame_skin.gd",frames_path).replace("res://src/ui/drag_safe_button.gd",button_path).replace("res://src/ui/lobby_profile_icon_picker.gd",icon_path)
	var refresh_start := view_source.find("func refresh() -> void:")
	var refresh_end := view_source.find("\nfunc show()", refresh_start)
	view_source = view_source.substr(0, refresh_start) + "func refresh() -> void: test_refreshes += 1\n" + view_source.substr(refresh_end) + "\nvar test_refreshes := 0\n"
	var view_path := fixture("view", view_source)
	var scope: GDScript = load(scope_path)
	var appearance: GDScript = load(appearance_path)
	var store: GDScript = load(store_path)
	var view_script: GDScript = load(view_path)
	check(appearance != null and store != null and view_script != null, "actual complete scripts compile")
	var cloud := Cloud.new(); cloud.name = "CloudStore"; root.add_child(cloud)
	var warmup := Warmup.new(); warmup.name = "PresentationWarmup"; root.add_child(warmup)
	var host := Control.new(); root.add_child(host)
	var view: RefCounted = view_script.new(); view.lobby = host; view._build_picker()
	# Only owned textures are supplied. Locked cards must use their lock texture.
	for gender in ["male","female"]:
		var own: String = "original_"+gender
		var other: String = "original_"+("female" if gender == "male" else "male")
		for account in ["fixture-account", ""]:
			scope.user_id = account
			var config := ConfigFile.new()
			config.set_value("player_profile","value",{"gender":gender,"nickname":"fixture"})
			config.set_value("demon_appearance","equipped_id",other)
			config.set_value("demon_appearance","local_owned",[own,other])
			config.set_value("profile_cosmetics","avatar_id",other)
			config.set_value("profile_cosmetics","banner_id",other)
			scope.text = config.encode_to_text()
			var before: int = scope.saves
			check(appearance.owned_ids() == [own], "only chosen gender owned")
			check(appearance.equipped_id(gender) == own, "old opposite equipment falls back")
			check(not appearance.equip(other), "direct opposite equip blocked")
			check(not appearance.grant_local_preview(other), "preview cannot grant opposite initial gender")
			check(scope.saves == before, "ownership/fallback do not write")
			for slot in ["avatar","banner","representative"]:
				if slot != "representative":
					check(own in store.choices(slot) and other not in store.choices(slot), "cosmetic ownership follows gender")
					check(store.selected_id(slot) == own and not store.select(slot,other), "old cosmetic falls back/direct choice blocked")
				if slot == "avatar":
					view.open_picker(slot)
					var icons: RefCounted = view.icon_picker
					check(icons.overlay.visible and icons.slots.size() == 8, "retained two-row icon strip opens")
					check(icons.ids.size() == 8, "only existing avatar resources listed")
					var index: int = icons.ids.find(other)
					icons._select_slot(index)
					check(icons.confirm.disabled and icons.preview.texture == view._lock_texture(), "locked gender preview masked")
					icons._confirm()
					check(scope.saves == before, "locked confirm never saves")
					view.close_picker()
					continue
				view.open_picker(slot)
				var locked: Button = view.picker_buttons[other]
				check(locked.visible and locked.disabled and locked.text.contains("잠김"), "other gender shown locked in "+slot)
				check(locked.icon == view._lock_texture(), "locked art masked by lock icon")
				check(view.picker_buttons[own].visible and view.picker_buttons[own].text.contains("사용 중"), "chosen default retained")
				before = scope.saves
				view._choose(other)
				check(scope.saves == before and view.picker.visible, "bypassed UI choice remains blocked")
				view.close_picker()
			check("zeus" in store.choices("avatar") and "zeus_plus_banner" in store.choices("banner"), "earned monster rewards unchanged")
			check(appearance.equip(own), "owned representative still selectable")
	# New confirmation workflow with real selection/save methods.
	scope.user_id = "fixture-account"
	var config := ConfigFile.new()
	config.set_value("player_profile","value",{"gender":"male"})
	scope.text = config.encode_to_text()
	view.open_picker("avatar")
	var icons: RefCounted = view.icon_picker
	var before: int = scope.saves
	icons._select_slot(icons.ids.find("zeus"))
	check(not icons.confirm.disabled and store.selected_id("avatar") == "original_male", "preview does not equip")
	view.close_picker()
	check(scope.saves == before and store.selected_id("avatar") == "original_male", "close cancels pending selection")
	view.open_picker("avatar")
	check(icons.candidate == "original_male", "reopen starts at equipped icon")
	icons._select_slot(icons.ids.find("zeus"))
	scope.fail_save = true
	icons._confirm()
	check(icons.overlay.visible and scope.saves == before and icons.notice.text.contains("못했습니다"), "save failure retains preview")
	scope.fail_save = false
	icons._confirm()
	check(not icons.overlay.visible and store.selected_id("avatar") == "zeus" and scope.saves == before+1 and view.test_refreshes == 1, "confirm equips once and refreshes profile")
	view.open_picker("avatar")
	check(icons.candidate == "zeus" and icons.confirm.disabled, "equipped icon restored/no duplicate save")
	icons._select_slot(icons.ids.find("original_male"))
	cloud.busy = true
	icons._confirm()
	check(not icons.overlay.visible and scope.saves == before+1, "busy guard prevents confirm")
	cloud.busy = false
	view.open_picker("avatar")
	icons._select_slot(icons.ids.find("original_male"))
	scope.user_id = "another-account"
	icons._confirm()
	check(not icons.overlay.visible and scope.saves == before+1, "account change invalidates pending selection")
	scope.user_id = "fixture-account"
	view.open_picker("avatar")
	for bounds in [Vector2(1080,1920),Vector2(1920,1080),Vector2(360,640)]:
		host.size = bounds
		icons._layout()
		await process_frame
		await process_frame
		var frame_end: Vector2 = icons.panel.position + icons.panel.size * icons.panel.scale
		check(icons.panel.position.x >= 0 and icons.panel.position.y >= 0 and frame_end.x <= bounds.x+1 and frame_end.y <= bounds.y+1, "modal inside viewport "+str(bounds))
		check(icons.panel.size.y <= icons.BASE.y+1, "content stays within logical modal height")
	for i in range(15): icons.ids.append("original_male")
	icons._sync_slots()
	icons._render()
	await process_frame
	await process_frame
	check(icons.slots.size() == 23 and icons.strip.get_child_count() == 12, "future icons extend two-row strip")
	var bar: HScrollBar = icons.scroll.get_h_scroll_bar()
	check(bar.max_value > bar.page and icons.scroll.get_v_scroll_bar().visible == false, "only horizontal overflow")
	icons.scroll.scroll_horizontal = 300
	var offset: int = icons.scroll.scroll_horizontal
	icons._select_slot(0)
	check(icons.scroll.scroll_horizontal == offset, "selection preserves scroll offset")
	icons._sync_slots()
	check(icons.slots.size() == 23 and icons.strip.get_child_count() == 12, "refresh reuses strip controls")
	var button: Button = icons.slots[0].button
	var saved_candidate: String = icons.candidate
	button._begin(button.get_global_rect().get_center())
	button._finish_gesture(button.get_global_rect().get_center() + Vector2(80, 0))
	check(icons.candidate == saved_candidate, "drag does not select card")
	button._begin(button.get_global_rect().get_center())
	icons.scroll.scroll_started.emit()
	check(button._cancelled, "native scroll takeover cancels pending tap")
	icons.candidate = "zeus"
	button._begin(button.get_global_rect().get_center())
	button._finish_gesture(button.get_global_rect().get_center())
	check(icons.candidate == "original_male", "completed tap selects card")
	view.close_picker()
	scope.text = ""; scope.user_id = "fixture-account"
	check(appearance.owned_ids() == ["original_male"], "legacy missing profile fallback")
	check(view._lock_texture() == view._lock_texture(), "lock texture reused")
	host.free(); cloud.free(); warmup.free()
	for path in files: DirAccess.remove_absolute(path)
	await process_frame
	print("INITIAL_GENDER_COSMETICS: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
