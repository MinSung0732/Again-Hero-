extends SceneTree
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var local = root.get_node("LocalTestMode")
	var scope = load("res://src/systems/account_save_scope.gd")
	local.active = true; local.tutorial_preview = false; scope.user_id = ""; scope.guest_directory = local.test_directory
	root.size = Vector2i(1080,1920)
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
		await process_frame
		check(scene.metrics_panel.get_parent() == scene and scene.metrics_panel not in scene.setup_controls,"overlay outside setup")
		scene._show_match_layout(); scene._open_match_menu()
		var button = scene.match_menu.find_child("ConnectionMetricsButton",true,false)
		check(button != null,"menu button")
		button.pressed.emit(); await process_frame
		check(scene.metrics_panel.visible and not scene.match_menu.visible and scene.metrics_label.text.contains("RTT"),"opens populated")
		if role == "hero": check(scene.metrics_panel in scene.pad.input_exclusions,"touch exclusion")
		scene._reset_metrics(); check(scene.metrics_label.text.contains("미측정"),"reset refresh")
		var close_button = scene.metrics_panel.find_children("*","Button",true,false).back(); close_button.pressed.emit()
		check(not scene.metrics_panel.visible,"close")
		scene.queue_free(); await process_frame
	local.active = false; scope.guest_directory = "user://"
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
		await process_frame
		check(scene.metrics_panel == null and scene.match_menu.find_child("ConnectionMetricsButton",true,false) == null,"ordinary account excludes metrics UI")
		scene.queue_free(); await process_frame
	print("ONLINE_METRICS_UI_PASS checks=",checks); quit()
