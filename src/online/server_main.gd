extends SceneTree
const LOCAL_ACCESS := preload("res://src/online/local_test_access.gd")
func _initialize() -> void: _start.call_deferred()
func _start() -> void:
	if DisplayServer.get_name() != "headless": push_error("Use --headless for the dedicated server"); quit(1); return
	for name in ["CloudStore","MissionProgress"]:
		var node := root.get_node_or_null(name)
		if node != null: node.set_process(false); node.set_physics_process(false)
	var server = load("res://src/online/match_server.gd").new(); root.add_child(server)
	var bind := OS.get_environment("AGAIN_HERO_BIND")
	if bind.is_empty(): bind = "127.0.0.1"
	var port := int(OS.get_environment("AGAIN_HERO_PORT"))
	if port <= 0: port = 24840
	var local_ticket := LOCAL_ACCESS.new_ticket() if OS.get_cmdline_user_args().has(LOCAL_ACCESS.SERVER_FLAG) else ""
	if server.start(port,bind,false,local_ticket) != OK: push_error("Dedicated server could not bind"); quit(1); return
	print("AGAIN_HERO_MATCH_SERVER ready port=",port)
	if not local_ticket.is_empty(): print("LOCALTEST invitation code: ",local_ticket)
