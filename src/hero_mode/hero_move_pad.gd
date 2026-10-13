extends Control
signal movement_changed(value: Vector2)
const MODE_FIXED := "fixed"
const MODE_FREE := "free"
const MODES := [MODE_FIXED, MODE_FREE]
const RADIUS := 105.0
const BASE_COLOR := Color(0.42, 0.42, 0.42, 0.28)
const RIM_COLOR := Color(0.72, 0.72, 0.72, 0.50)
const KNOB_COLOR := Color(0.68, 0.68, 0.68, 0.60)
var touch_id := -1
var direction := Vector2.ZERO
var mouse_owned := false
var mode := MODE_FIXED
var input_surface: Control
var enabled := true:
	set(value):
		enabled = value
		if not value: reset()

func _ready() -> void:
	custom_minimum_size = Vector2(270,270)
	set_mode(mode)

func set_mode(value: String) -> void:
	mode = value if value in MODES else MODE_FIXED
	reset()
	if mode == MODE_FIXED:
		set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		offset_left = -135; offset_right = 135; offset_top = -315; offset_bottom = -45
		mouse_filter = Control.MOUSE_FILTER_STOP
		show()
	else:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		size = Vector2(270,270)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hide()
	queue_redraw()

func reset() -> void:
	touch_id = -1; mouse_owned = false; direction = Vector2.ZERO
	if mode == MODE_FREE: hide()
	movement_changed.emit(direction); queue_redraw()

func _update_direction(point: Vector2) -> void:
	direction = ((point-size*0.5)/RADIUS).limit_length(1.0)
	if direction.length() < 0.12: direction = Vector2.ZERO
	movement_changed.emit(direction); queue_redraw()

func _can_start_free(point: Vector2) -> bool:
	if mode != MODE_FREE or not enabled or touch_id >= 0 or mouse_owned: return false
	if not is_instance_valid(input_surface) or not input_surface.is_visible_in_tree(): return false
	var local := input_surface.get_global_transform_with_canvas().affine_inverse()*point
	return Rect2(Vector2.ZERO,input_surface.size).has_point(local)

func _place_free_origin(point: Vector2) -> void:
	# Keep the origin at the initial finger position until release; dragging does
	# not move the base. Input is in viewport space, including canvas transforms.
	var parent_control := get_parent() as Control
	position = parent_control.get_global_transform_with_canvas().affine_inverse()*point-size*0.5
	show()
	_update_direction(size*0.5)

func _gui_input(event: InputEvent) -> void:
	if not enabled or mode != MODE_FIXED or touch_id >= 0 or mouse_owned: return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		touch_id = event.index; _update_direction(event.position); accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		mouse_owned = true; _update_direction(event.position); accept_event()

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if mouse_owned:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			reset(); get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion:
			_update_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
			get_viewport().set_input_as_handled()
		return
	if touch_id >= 0:
		if event is InputEventScreenDrag and event.index == touch_id:
			_update_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index == touch_id and not event.pressed:
			reset(); get_viewport().set_input_as_handled()
		return
	# HeroMode disables the pad for every modal/loading phase. Only the actual
	# battle panel can own a new free-pad gesture; HUD and frame margins pass on.
	if event is InputEventScreenTouch and event.pressed and not event.canceled and _can_start_free(event.position):
		touch_id = event.index; _place_free_origin(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _can_start_free(event.position):
		mouse_owned = true; _place_free_origin(event.position)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset()

func _draw() -> void:
	var center := size*0.5
	draw_circle(center,RADIUS,BASE_COLOR)
	draw_arc(center,RADIUS,0,TAU,48,RIM_COLOR,3.0)
	draw_circle(center+direction*RADIUS,33,KNOB_COLOR)
