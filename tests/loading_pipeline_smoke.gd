extends SceneTree
const SCOPE = preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize(): call_deferred("run")
func run():
	Engine.max_fps = 60
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://loading_bench_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var warm = root.get_node("PresentationWarmup")
	var start = Time.get_ticks_msec()
	await warm.prepare_common()
	print("LOAD common ms=", Time.get_ticks_msec()-start)
	for path in ["res://src/lobby/Lobby.tscn", "res://src/lobby/Lobby.tscn", "res://src/main/Main.tscn"]:
		start = Time.get_ticks_msec()
		var before = warm.texture_load_count
		if not await warm.prepare_scene(path): failed = true
		if warm._busy: failed = true
		if warm.get_texture("res://assets/art/UI/logo/AgainHeroLogo.png") == null and path.contains("Lobby"): failed = true
		if path.contains("Lobby") and warm.get_cropped("res://assets/art/Transcendent_monster/zeus/zeus_icon.png") == null: failed = true
		if before > 100 and path.contains("Lobby") and warm.texture_load_count != before: failed = true
		print("LOAD ",path," ms=",Time.get_ticks_msec()-start," textures=",warm.texture_load_count-before)
	print("LOADING_PIPELINE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
