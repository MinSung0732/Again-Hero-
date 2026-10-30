extends SceneTree
const VIEW := preload("res://src/online/battle_view.gd")
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var v = VIEW.new(); v.size = Vector2(600,800); root.add_child(v)
	v.set_match_roster([], "zeus")
	v._layout_map()
	var scale_before: Vector2 = v.map_scale
	var offset_before: Vector2 = v.map_offset
	var old_speed := Engine.time_scale
	var buffer := BUFFER.new()
	buffer.publish("transcend",Vector2(1700,1800),DATA.transcend_index("zeus"),Color.WHITE,10)
	v.feedback.suspended = false
	check(v.feedback.consume(buffer.snapshot(),buffer.sequence,10), "event accepted")
	check(v.cinematic.active and v.cinematic.view.visible, "cinematic and view active")
	v.cinematic.set_process(false); v.cinematic.advance(2.0)
	check(not v.map_scale.is_equal_approx(scale_before), "map zoomed")
	check(is_equal_approx(Engine.time_scale,old_speed), "time scale unchanged")
	v.cinematic.advance(4.0)
	check(not v.cinematic.active and v.map_scale.is_equal_approx(scale_before) and v.map_offset.is_equal_approx(offset_before), "map restored")
	buffer.publish("transcend",Vector2(1700,1800),DATA.transcend_index("zeus"),Color.WHITE,20)
	check(v.feedback.consume(buffer.snapshot(),buffer.sequence,20+int(5.0*Engine.physics_ticks_per_second)), "stale event accepted but ignored")
	check(not v.cinematic.active and is_equal_approx(Engine.time_scale,old_speed), "stale event ignored")
	var bad: Array = buffer.snapshot()[0].duplicate(); bad[5] = 0
	check(not DATA.valid_events([bad],buffer.sequence,320), "invalid catalog index rejected")
	v.hero_role = false
	buffer.publish("transcend",Vector2(1600,1700),DATA.transcend_index("zeus"),Color.WHITE,321)
	check(v.feedback.consume(buffer.snapshot(),buffer.sequence,321) and v.cinematic.active, "demon client plays event")
	v.feedback.pause_feedback()
	check(not v.cinematic.active and is_equal_approx(Engine.time_scale,old_speed), "interruption restores presentation")
	v.free()
	print("PASS online transcend cinematic" if failures == 0 else "FAIL online transcend cinematic")
	quit(0 if failures == 0 else 1)
