extends Button

# Only confirmed taps may trigger a purchase. Native pressed remains presentation
# input; clients connect to confirmed instead. Coordinates use the canvas scale.
signal confirmed

const DRAG_DISTANCE := 24.0
var _start := Vector2.ZERO
var _touch_index := -1
var _mouse_down := false
var _cancelled := true
var _allowed := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	pressed.connect(_on_native_pressed)


func _begin(position: Vector2) -> void:
	_start = position
	_cancelled = false
	_allowed = false


func _moved(position: Vector2) -> void:
	if position.distance_squared_to(_start) > DRAG_DISTANCE * DRAG_DISTANCE:
		_cancelled = true
	if not get_global_rect().has_point(position):
		_cancelled = true


func _input(event: InputEvent) -> void:
	if disabled or not is_visible_in_tree():
		_cancelled = true
		_allowed = false
		_touch_index = -1
		_mouse_down = false
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index != -1:
				_cancelled = true
			elif get_global_rect().has_point(event.position):
				_begin(event.position)
				_touch_index = event.index
		elif event.index == _touch_index:
			_moved(event.position)
			_allowed = not _cancelled and not event.canceled
			_touch_index = -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_moved(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Touch-generated mouse events must not reset a cancelled touch gesture.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			_allowed = false
			_mouse_down = get_global_rect().has_point(event.position)
			if _mouse_down:
				_begin(event.position)
		elif _mouse_down:
			_moved(event.position)
			_allowed = not _cancelled
			_mouse_down = false
	elif event is InputEventMouseMotion and _mouse_down:
		_moved(event.position)


func _on_native_pressed() -> void:
	if not _allowed or _cancelled:
		return
	_allowed = false
	confirmed.emit()
