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
	var scope_path := fixture("scope", "extends RefCounted\nstatic var user_id := \"fixture-account\"\nstatic var guest_directory := \"fixture\"\nstatic var text := \"\"\nstatic var saves := 0\nstatic func load_config(config: ConfigFile, _path: String) -> int: return config.parse(text) if not text.is_empty() else ERR_FILE_NOT_FOUND\nstatic func save_config(config: ConfigFile, _path: String) -> int: text = config.encode_to_text(); saves += 1; return OK\n")
	var catalog_path := fixture("appearances", art_source("res://src/data/demon_appearance_catalog.gd",art))
	var appearance_path := fixture("appearance", FileAccess.get_file_as_string("res://src/systems/demon_appearance_store.gd").replace("res://src/systems/account_save_scope.gd",scope_path).replace("res://src/data/demon_appearance_catalog.gd",catalog_path))
	var profile_path := fixture("profile", "extends RefCounted\nconst SCOPE = preload(\""+scope_path+"\")\nconst APPEARANCE = preload(\""+appearance_path+"\")\nstatic func get_profile() -> Dictionary:\n\tvar config := ConfigFile.new()\n\tSCOPE.load_config(config,\"fixture\")\n\treturn config.get_value(\"player_profile\",\"value\",{})\nstatic func appearance_id() -> String: return APPEARANCE.equipped_id(String(get_profile().get(\"gender\",\"male\")))\n")
	var collection_path := fixture("collection", "extends RefCounted\nstatic func load_state() -> Dictionary: return {}\nstatic func is_unlocked(id: String, _state: Dictionary) -> bool: return id == \"zeus\"\nstatic func get_upgrade_level(_id: String, _state: Dictionary) -> int: return 5\n")
	var monsters_path := fixture("monsters", "extends RefCounted\nstatic func get_rarity(_id: String) -> String: return \"transcendent\"\n")
	var cosmetics_path := fixture("cosmetics", art_source("res://src/data/profile_cosmetic_catalog.gd",art).replace("res://src/data/demon_appearance_catalog.gd",catalog_path))
	var store_path := fixture("store", FileAccess.get_file_as_string("res://src/systems/profile_cosmetic_store.gd").replace("res://src/systems/account_save_scope.gd",scope_path).replace("res://src/systems/player_profile.gd",profile_path).replace("res://src/systems/demon_appearance_store.gd",appearance_path).replace("res://src/systems/monster_collection_store.gd",collection_path).replace("res://src/data/monster_catalog.gd",monsters_path).replace("res://src/data/profile_cosmetic_catalog.gd",cosmetics_path))
	var frames_path := fixture("frames", "extends RefCounted\nstatic func style(_name: String, _size: int, _color: Color = Color.WHITE) -> StyleBox: return StyleBoxFlat.new()\n")
	var button_path := fixture("button", "extends Button\nsignal confirmed\n")
	var view_path := fixture("view", FileAccess.get_file_as_string("res://src/ui/lobby_profile_view.gd").replace("res://src/systems/player_profile.gd",profile_path).replace("res://src/systems/profile_cosmetic_store.gd",store_path).replace("res://src/data/profile_cosmetic_catalog.gd",cosmetics_path).replace("res://src/systems/demon_appearance_store.gd",appearance_path).replace("res://src/data/demon_appearance_catalog.gd",catalog_path).replace("res://src/ui/commerce_frame_skin.gd",frames_path).replace("res://src/ui/drag_safe_button.gd",button_path))
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
	scope.text = ""; scope.user_id = "fixture-account"
	check(appearance.owned_ids() == ["original_male"], "legacy missing profile fallback")
	check(view._lock_texture() == view._lock_texture(), "lock texture reused")
	host.free(); cloud.free(); warmup.free()
	for path in files: DirAccess.remove_absolute(path)
	await process_frame
	print("INITIAL_GENDER_COSMETICS: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
