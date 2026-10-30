extends SceneTree
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok, message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("SceneTransition")._entry_options = {"role":"demon"}
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	await process_frame
	scene.transcendence_id = "zeus"
	scene.initial_local_test = false
	var state := {"mana":0.0,"summon_costs":{},"demon_charge":0.0,"demon_charge_max":100.0,"demon_cooldowns":{},"demon_ready":{},"transcend_ready":false,"transcend_used":false}
	scene._update_demon_controls(state)
	check(not scene.transcendence_view.is_visible_in_tree(), "hidden before ready")
	state.transcend_ready = true; scene._update_demon_controls(state)
	check(scene.transcendence_view.button.visible and scene.transcendence_view.ready_announced, "ready shows button and light")
	await create_timer(0.4).timeout
	check(is_equal_approx(scene.transcendence_view.button.offset_left,-156.0) and is_equal_approx(scene.transcendence_view.button.offset_right,-12.0), "slide reaches target")
	scene.transcendence_view.button.pressed.emit()
	check(scene.transcend_placement and scene.bottom_bar.get_node("Status").text == scene.RULES.TRANSCEND_STATUS, "button selects manual placement")
	state.transcend_used = true; scene._update_demon_controls(state)
	check(not scene.transcendence_view.visible and not scene.transcend_placement, "used hides button and clears placement")
	scene.queue_free()
	print("ONLINE_TRANSCEND_BUTTON_PASS checks=",checks); quit()
