extends Button

# Only a completed tap may trigger a purchase. Gesture start is accepted only
# through GUI hit-testing, then global input tracks the release so ScrollContainer
# can still take over a drag without losing the cancellation state.
signal confirmed

const DRAG_DISTANCE := 24.0
var _start := Vector2.ZERO
var _touch_index := -1
var _mouse_down := false
var _cancelled := true


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE


func _reset_gesture() -> void:
	_touch_index = -1
	_mouse_down = false
	_cancelled = true


func _begin(position: Vector2) -> void:
	_start = position
	_cancelled = false


func _moved(position: Vector2) -> void:
	if position.distance_squared_to(_start) > DRAG_DISTANCE * DRAG_DISTANCE:
		_cancelled = true
	if not get_global_rect().has_point(position):
		_cancelled = true


func _finish_gesture(position: Vector2, event_cancelled: bool = false) -> void:
	_moved(position)
	var should_confirm := not _cancelled and not event_cancelled
	_reset_gesture()
	if should_confirm:
		confirmed.emit()


func _gui_event_position_to_global(position: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * position


func _gui_input(event: InputEvent) -> void:
	if disabled or not is_visible_in_tree():
		_reset_gesture()
		return

	if event is InputEventScreenTouch and event.pressed:
		if _touch_index != -1:
			_cancelled = true
			return
		_begin(_gui_event_position_to_global(event.position))
		_touch_index = event.index
		return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		# A physical mouse is allowed. Touch-generated emulated mouse input must
		# not start a second gesture after the real touch already started.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if _touch_index != -1:
			_cancelled = true
			return
		_mouse_down = true
		_begin(_gui_event_position_to_global(event.position))


func _input(event: InputEvent) -> void:
	if disabled or not is_visible_in_tree():
		_reset_gesture()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index != -1 and event.index != _touch_index:
				_cancelled = true
			return
		if event.index == _touch_index:
			_finish_gesture(event.position, event.canceled)
		return

	if event is InputEventScreenDrag and event.index == _touch_index:
		_moved(event.position)
		return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if not event.pressed and _mouse_down:
			_finish_gesture(event.position, event.canceled)
		return

	if event is InputEventMouseMotion and _mouse_down:
		_moved(event.position)
