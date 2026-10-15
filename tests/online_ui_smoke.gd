extends SceneTree
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var packed: PackedScene = load("res://src/online/OnlineMatch.tscn")
		check(packed != null,"scene compiles with autoloads")
		var scene = packed.instantiate(); root.add_child(scene)
		await process_frame; await process_frame
		check(scene.role == role,"requested role")
		check(scene.queue_button.custom_minimum_size.y >= 72,"mobile button size")
		check(scene.view.size.x > 500 and scene.view.size.y > 300,"battle panel expands")
		if role == "hero": check(scene.pad.mode == "free" and scene.pad.input_surface == scene.view,"touch binds battle only")
		else: check(scene.action_row.get_child_count() == 5,"five roster choices")
		scene._join()
		check(scene.client.socket == null,"guest without token never queues")
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		check(scene.view.size.x > 1200,"tablet width expands")
		scene.queue_free(); await process_frame
	print("ONLINE_UI_PASS checks=",checks); quit()
