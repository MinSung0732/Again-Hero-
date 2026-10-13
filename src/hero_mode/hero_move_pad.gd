extends Control
signal movement_changed(value: Vector2)
var touch_id := -1
var direction := Vector2.ZERO
var enabled := true
var mouse_owned := false
const RADIUS := 105.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(270,270)
func reset() -> void:
	touch_id = -1; mouse_owned = false; direction = Vector2.ZERO
	movement_changed.emit(direction); queue_redraw()
func _update_direction(point: Vector2) -> void:
	direction = ((point-size*0.5)/RADIUS).limit_length(1.0)
	if direction.length() < 0.12: direction = Vector2.ZERO
	movement_changed.emit(direction); queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventScreenTouch and event.pressed and touch_id == -1:
		touch_id = event.index; _update_direction(event.position); accept_event()
	elif event is InputEventMouseButton and touch_id == -1 and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: mouse_owned = true; _update_direction(event.position)
		else: reset()
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and touch_id == -1:
		_update_direction(event.position); accept_event()
func _input(event: InputEvent) -> void:
	if mouse_owned:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			reset(); get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion:
			_update_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
			get_viewport().set_input_as_handled()
	if touch_id < 0: return
	if event is InputEventScreenDrag and event.index == touch_id:
		_update_direction(get_global_transform_with_canvas().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index == touch_id and not event.pressed:
		reset(); get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset()
func _draw() -> void:
	var center := size*0.5
	draw_circle(center,RADIUS,Color(0.06,0.18,0.25,0.75))
	draw_arc(center,RADIUS,0,TAU,48,Color("76c7dc"),3.0)
	draw_circle(center+direction*RADIUS,33,Color("d9c77c"))
