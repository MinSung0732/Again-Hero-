extends Control

# Geometry is rebuilt only when targets/layout change; no field/group scans.
var targets: Array[Control] = []
var holes: Array[Rect2] = []
var tiles: Array[Rect2] = []
var blocked_pointers: Dictionary = {}
var guard_until := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func configure(controls: Array[Control]) -> void:
	targets = controls
	blocked_pointers.clear()
	guard_until = Time.get_ticks_msec() + 450
	_refresh()

func _process(_delta: float) -> void:
	var changed := false
	var index := 0
	for target in targets:
		if not is_instance_valid(target) or not target.is_visible_in_tree():
			changed = not holes.is_empty()
			break
		if index >= holes.size() or holes[index] != target.get_global_rect():
			changed = true
			break
		index += 1
	if changed:
		_refresh()

func _refresh() -> void:
	holes.clear()
	# Fail closed if a target disappears (for example on a tab transition).
	for target in targets:
		if not is_instance_valid(target) or not target.is_visible_in_tree():
			holes.clear()
			break
		holes.append(target.get_global_rect())
	var xs: Array[float] = [0.0, size.x]
	var ys: Array[float] = [0.0, size.y]
	for hole in holes:
		xs.append(clampf(hole.position.x, 0, size.x))
		xs.append(clampf(hole.end.x, 0, size.x))
		ys.append(clampf(hole.position.y, 0, size.y))
		ys.append(clampf(hole.end.y, 0, size.y))
	xs.sort()
	ys.sort()
	tiles.clear()
	for x in range(xs.size() - 1):
		for y in range(ys.size() - 1):
			var tile := Rect2(Vector2(xs[x], ys[y]), Vector2(xs[x + 1] - xs[x], ys[y + 1] - ys[y]))
			if tile.has_area() and not allows(tile.get_center()):
				tiles.append(tile)
	queue_redraw()

func allows(point: Vector2) -> bool:
	for hole in holes:
		if hole.has_point(point):
			return true
	return false

func _has_point(point: Vector2) -> bool:
	return not allows(point)

func _draw() -> void:
	for tile in tiles:
		draw_rect(tile, Color(0.025, 0.012, 0.04, 0.82))
	for hole in holes:
		draw_rect(hole.grow(4), Color("ffe79b"), false, 4)

func blocks(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return true
	var pointer := -1
	var pressed := false
	var released := false
	if event is InputEventScreenTouch:
		pointer = event.index
		pressed = event.pressed
		released = not pressed
	elif event is InputEventScreenDrag:
		pointer = event.index
	elif event is InputEventMouseButton:
		pressed = event.pressed
		released = not pressed
	elif not event is InputEventMouseMotion:
		return false
	var blocked := blocked_pointers.has(pointer) or Time.get_ticks_msec() < guard_until or not allows(event.position)
	if pressed and blocked:
		blocked_pointers[pointer] = true
	if released:
		blocked_pointers.erase(pointer)
	return blocked

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		blocked_pointers.clear()
		guard_until = Time.get_ticks_msec() + 450
	elif what == NOTIFICATION_RESIZED and is_node_ready():
		_refresh()
