extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROFILE := preload("res://src/systems/player_profile.gd")
const STORE := preload("res://src/systems/demon_appearance_store.gd")
const CATALOG := preload("res://src/data/demon_appearance_catalog.gd")
var failed := false

class FakeProfile extends Node:
	func request_rpc(_method: String, _data: Dictionary) -> Dictionary:
		return {"ok":true,"profile":{"nickname":"테스트","gender":"female","required":true,"completed":true}}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("APPEARANCE_TEST: " + message)

func random_id() -> String:
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var folder := "user://appearance_fixture_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("AudioSettings").config_path = folder.path_join("audio.cfg")
	var id := random_id()
	SCOPE.select_account(id)
	SCOPE.install({"stage_progress.cfg":{"meta":{"gold":777,"research_points":123},"player_profile":{"value":{"nickname":"테스트","gender":"female","required":true,"completed":true}}}}, 1)
	check(PROFILE.appearance_id() == "original_female", "legacy profile defaults by gender")
	var before_profile := PROFILE.get_profile()
	check(STORE.equip("original_male"), "equip built-in appearance")
	check(PROFILE.portrait_path("avatar") == PROFILE.PORTRAITS.male and PROFILE.portrait_path() == PROFILE.PORTRAITS.male, "avatar and dialogue share selection")
	check(PROFILE.get_profile() == before_profile and PROFILE.display_name() == "마왕(테스트)", "identity unchanged")
	var before_serial := SCOPE.serial
	check(STORE.equip("original_male") and SCOPE.serial == before_serial, "same selection is no-op")
	check(not STORE.equip("res://arbitrary.png") and not STORE.equip("unowned_skin"), "invalid/unowned IDs denied")
	check(not STORE.grant_local_preview("original_female"), "social local entitlement grants denied")
	check(PROFILE.portrait_path("dialogue", "missing_expression") == PROFILE.PORTRAITS.male, "missing expression uses selected neutral")
	var fake := FakeProfile.new()
	root.add_child(fake)
	await PROFILE.refresh(fake)
	check(PROFILE.appearance_id() == "original_male", "canonical identity refresh preserves appearance")
	var cloud_payload := SCOPE.files.duplicate(true)
	SCOPE.select_account(id)
	check(PROFILE.appearance_id() == "original_male", "restart retains selection")
	SCOPE.install(cloud_payload, 2)
	check(PROFILE.appearance_id() == "original_male", "existing cloud bundle round trip")
	var config := ConfigFile.new()
	SCOPE.load_config(config, PROFILE.PATH)
	check(config.get_value("meta", "gold", 0) == 777 and config.get_value("meta", "research_points", 0) == 123, "currency unchanged")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("options.cfg")
	root.add_child(lobby)
	current_scene = lobby
	lobby._switch_tab("other")
	lobby.settings_view.show_page("account")
	check(lobby.settings_view.profile_portrait.texture.resource_path == PROFILE.PORTRAITS.male, "profile view selected art")
	lobby.settings_view._open_appearance_picker()
	await process_frame
	check(is_instance_valid(lobby.settings_view.appearance_overlay), "owned picker opens")
	check(lobby.settings_view.appearance_overlay.find_child("original_female",true,false) != null, "owned choice available")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://demon-appearance-picker.png")
	lobby.settings_view._choose_appearance("original_female")
	check(PROFILE.appearance_id() == "original_female" and lobby.settings_view.appearance_overlay == null, "UI equips and closes")
	check(lobby.settings_view.profile_portrait.texture.resource_path == PROFILE.PORTRAITS.female, "profile refresh")
	STORE.equip("original_male")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	for path in PROFILE.appearance_resource_paths():
		check(root.get_node("PresentationWarmup").get_texture(path) != null, "selected appearance warmed " + path)
	var cutscene = load("res://src/ui/StageIntroCutscene.tscn").instantiate()
	root.add_child(cutscene)
	cutscene.play_dialogue({"hero_name":"용사","lines":[{"speaker":"demon","text":"돌아왔군.","demon_expression":"missing_expression"}]})
	check(cutscene.demon_portrait.texture != null and cutscene.demon_portrait.texture.resource_path == PROFILE.PORTRAITS.male, "real dialogue uses profile appearance")
	check(cutscene.demon_name.text == "마왕(테스트)", "dialogue identity retained")
	cutscene._finish(true)
	SCOPE.select_account(random_id())
	SCOPE.install({"stage_progress.cfg":{"player_profile":{"value":before_profile}}},1)
	check(PROFILE.appearance_id() == "original_female", "account isolation")
	SCOPE.select_account(id)
	SCOPE.load_config(config, PROFILE.PATH)
	config.set_value(STORE.SECTION, "equipped_id", "missing_catalog_entry")
	SCOPE.save_config(config, PROFILE.PATH)
	check(PROFILE.appearance_id() == "original_female", "removed/invalid entry falls back safely")
	print("DEMON_APPEARANCE_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
