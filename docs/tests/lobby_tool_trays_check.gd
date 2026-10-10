extends SceneTree
const TRAYS = preload("res://src/ui/lobby_tool_trays.gd")
var fired := 0
var allowed := true
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1080, 1920)
	var host := Control.new()
	host.size = Vector2(1080, 1400)
	root.add_child(host)
	var tray = TRAYS.new()
	tray.install(host, func(): return allowed)
	await process_frame
	assert(tray._rails[&"left"].get_child_count() == 3)
	assert(tray._rails[&"right"].get_child_count() == 1)
	assert(tray._rails[&"right"].position.x == 968)
	tray.register_action(&"daily", func(): fired += 1)
	tray._activate(&"daily")
	assert(fired == 1)
	allowed = false
	tray._activate(&"daily")
	assert(fired == 1)
	allowed = true
	tray._activate(&"weekly")
	assert(tray._notice.visible)
	host.hide()
	assert(not tray._notice.visible)
	host.show()
	var event := InputEventScreenTouch.new()
	event.position = Vector2(20, 55)
	assert(tray.blocks_stage_input(event))
	event.position = Vector2(520, 600)
	assert(not tray.blocks_stage_input(event))
	var entries: Array = []
	for i in range(100):
		entries.append({"id":StringName("test%d" % i), "title":"도구%d" % i,"side":&"left"})
	var large = TRAYS.new()
	large.install(host, func():return true, entries)
	await process_frame
	assert(large._rails[&"left"].get_child_count() == 3)
	assert(large._rails[&"left"].get_child(2).get_global_rect().end.y < 400)
	large._show_more(&"left")
	await process_frame
	assert(large._overflow_grid.get_child_count() == 100)
	var existing = large._overflow_grid.get_child(0)
	large._overflow.hide()
	large._show_more(&"left")
	assert(large._overflow_grid.get_child(0) == existing)
	host.size.x = 1440
	await process_frame
	assert(large._rails[&"right"].position.x == 1328)
	host.hide()
	assert(not large._overflow.visible)
	print("PASS: rails, overflow reuse, actions, permission, tab hide, touch hitboxes, resize")
	quit()
