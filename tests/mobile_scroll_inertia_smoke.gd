extends SceneTree

const ROUTER := preload("res://src/ui/mobile_scroll_router.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, name: String) -> void:
	if not ok:
		failed = true
		push_error("MOBILE_SCROLL_INERTIA: " + name)

func _touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = pos
	return e

func _drag(index: int, pos: Vector2, dy: float, speed: float) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = Vector2(0, dy)
	e.velocity = Vector2(0, speed)
	return e

func _run() -> void:
	var parent := Control.new()
	parent.size = Vector2(450, 600)
	root.add_child(parent)
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(300, 320)
	scroll.position = Vector2(10, 10)
	parent.add_child(scroll)
	var content := ColorRect.new()
	content.custom_minimum_size = Vector2(290, 1500)
	scroll.add_child(content)
	await process_frame
	await process_frame
	var router := ROUTER.new()
	_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "scrollable")
	scroll.scroll_vertical = 400
	_check(not router.handle_input(_touch(0, true, Vector2(50, 100)), parent), "tap starts unclaimed")
	_check(router.handle_input(_drag(0, Vector2(50, 20), -80, -1700), parent), "vertical swipe claims scroll")
	var release_y := scroll.scroll_vertical
	_check(router.handle_input(_touch(0, false, Vector2(50, 20)), parent), "release is consumed")
	for i in range(8):
		router.step(1.0 / 60.0)
	_check(scroll.scroll_vertical > release_y, "fast swipe coasts after release")
	router.reset()
	scroll.scroll_vertical = 0
	router.handle_input(_touch(1, true, Vector2(50, 100)), parent)
	router.handle_input(_drag(1, Vector2(50, 200), 100, 0), parent)
	_check(absf(router._elastic) > 0.0 and absf(router._elastic) <= ROUTER.ELASTIC_LIMIT, "edge stretch capped")
	router.handle_input(_touch(1, false, Vector2(50, 200)), parent)
	for i in range(100):
		router.step(1.0 / 60.0)
	_check(absf(router._elastic) < 0.5 and content.position.y <= 1.0, "edge springs back")
	router.reset()
	scroll.scroll_vertical = 400
	router.handle_input(_touch(2, true, Vector2(50, 100)), parent)
	var swipe := InputEventScreenDrag.new()
	swipe.index = 2
	swipe.position = Vector2(150, 110)
	swipe.relative = Vector2(100, 10)
	_check(not router.handle_input(swipe, parent) and not router._dragging, "horizontal swipe untouched")
	router.reset()
	parent.queue_free()
	print("MOBILE_SCROLL_INERTIA_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
