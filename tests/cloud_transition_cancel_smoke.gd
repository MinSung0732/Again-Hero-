extends SceneTree
var checks := 0
var failures := 0
var actions := 0
var prepare_finished := false
var prepare_result := true
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func action() -> bool:
	actions += 1
	return true
func prepare(transition: Node) -> void:
	prepare_result = await transition.prepare_in_place(action)
	prepare_finished = true
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var transition := root.get_node("SceneTransition")
	var host := Node.new()
	root.add_child(host)
	current_scene = host
	prepare(transition)
	check(transition.is_transitioning(), "preparation started")
	var old_generation: int = transition._generation
	transition.cancel()
	for index in 4: await process_frame
	check(prepare_finished and not prepare_result and actions == 0, "cancel before setup never executes stale action")
	check(not transition.is_transitioning(), "cancel closes transition overlay")
	transition._begin_resource_load(old_generation)
	check(not transition._pending, "late deferred loader rejected")
	var node := Node.new()
	var packed := PackedScene.new()
	packed.pack(node)
	node.free()
	transition._destination_ready = false
	transition._prepare_destination_and_change(packed, transition._generation)
	transition.cancel()
	for index in 4: await process_frame
	check(current_scene == host, "old warmed scene cannot replace login destination")
	host.queue_free()
	print("CLOUD_TRANSITION_CANCEL checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
