extends SceneTree
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
func _initialize() -> void: _start.call_deferred()
func _start() -> void:
	if DisplayServer.get_name() != "headless": push_error("Use --headless for the dedicated server"); quit(1); return
	for name in ["CloudStore","MissionProgress"]:
		var node := root.get_node_or_null(name)
		if node != null: node.set_process(false); node.set_physics_process(false)
	var server_script = load("res://src/online/match_server.gd")
	if server_script == null or not server_script.can_instantiate():
		push_error("Dedicated server scripts failed to load; check the preceding Godot errors."); quit(1); return
	var server = server_script.new(); root.add_child(server)
	var bind := OS.get_environment("AGAIN_HERO_BIND")
	if bind.is_empty(): bind = "127.0.0.1"
	var port := int(OS.get_environment("AGAIN_HERO_PORT"))
	if port <= 0: port = 24840
	var local_ticket := LOCAL_ACCESS.new_ticket() if OS.get_cmdline_user_args().has(LOCAL_ACCESS.SERVER_FLAG) else ""
	var start_error: Error = server.start(port,bind,false,local_ticket)
	if start_error != OK:
		push_error("Dedicated server start failed: bind=%s port=%d error=%s (%d)" % [bind,port,error_string(start_error),start_error]); quit(1); return
	print("AGAIN_HERO_MATCH_SERVER ready port=",port)
	if not local_ticket.is_empty(): print("LOCALTEST invitation code: ",local_ticket)
