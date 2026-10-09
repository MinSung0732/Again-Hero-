extends RefCounted
class_name MobileScrollRouter

# Scroll routing is resolved on touch-down, never by polling the entire UI.
# A quick release coasts with friction; at the edges the content moves at most
# 24 pixels and springs back. No tweens/temporary nodes are created per swipe.
const DRAG_START_DISTANCE := 8.0
const MIN_FLING_SPEED := 150.0
const STOP_SPEED := 24.0
const MAX_FLING_SPEED := 2500.0
const FRICTION := 7.0
const ELASTIC_LIMIT := 24.0
const ELASTIC_DRAG := 0.20
const SPRING_STIFFNESS := 260.0
const SPRING_DAMPING := 30.0

var _touch_index: int = -1
var _target: ScrollContainer
var _content: Control
var _start_position := Vector2.ZERO
var _scroll_position := 0.0
var _dragging := false
var _horizontal_locked := false
var _kinetic_speed := 0.0
var _elastic := 0.0
var _elastic_speed := 0.0
var _applied_elastic := 0.0


func reset() -> void:
	_stop_motion()
	_clear_state()


func step(delta: float) -> void:
	if is_instance_valid(_target) and (
		_target.mouse_filter == Control.MOUSE_FILTER_IGNORE or _target.get_viewport().gui_is_dragging()
	):
		reset()
		return
	if not is_instance_valid(_target) or (_touch_index >= 0 and not _dragging):
		return
	if _touch_index >= 0:
		return
	if absf(_kinetic_speed) < STOP_SPEED and absf(_elastic) < 0.5 and absf(_elastic_speed) < 2.0:
		_stop_motion()
		_clear_state()
		return
	var dt := minf(delta, 0.04)
	if absf(_kinetic_speed) >= STOP_SPEED:
		_scroll_by(_kinetic_speed * dt, true)
		_kinetic_speed *= exp(-FRICTION * dt)
	else:
		_kinetic_speed = 0.0
	# Critically damped edge spring, independent of gesture frequency.
	_elastic_speed += (-SPRING_STIFFNESS * _elastic - SPRING_DAMPING * _elastic_speed) * dt
	_elastic += _elastic_speed * dt
	_apply_elastic()


func handle_input(event: InputEvent, root: Node) -> bool:
	# A long-press card owns the native GUI drag, including emulated mouse input.
	# The cached scroll was acquired before the card changed its mouse_filter.
	if is_instance_valid(root) and root.get_viewport().gui_is_dragging():
		reset()
		return false
	if is_instance_valid(_target) and _target.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		reset()
		return false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index >= 0:
				return false
			var scroll := _find_scroll_at(root, touch.position)
			if not is_instance_valid(scroll):
				return false
			_stop_motion()
			_touch_index = touch.index
			_target = scroll
			_content = _get_content(scroll)
			_start_position = touch.position
			_scroll_position = float(scroll.scroll_vertical)
			_dragging = false
			_horizontal_locked = false
			scroll.scroll_deadzone = int(DRAG_START_DISTANCE)
			return false

		if touch.index != _touch_index:
			return false
		var consumed := _dragging
		_touch_index = -1
		if _dragging and (absf(_kinetic_speed) >= MIN_FLING_SPEED or absf(_elastic) > 0.5):
			# Leave the target alive for the frame-driven coast/spring.
			_dragging = false
		else:
			_stop_motion()
			_clear_state()
		return consumed

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index or not is_instance_valid(_target):
			return false

		var total := drag.position - _start_position
		if not _dragging:
			if _horizontal_locked:
				return false
			if absf(total.x) >= DRAG_START_DISTANCE and absf(total.x) > absf(total.y):
				_horizontal_locked = true
				return false
			if absf(total.y) < DRAG_START_DISTANCE or absf(total.y) < absf(total.x):
				return false
			_dragging = true
			_target.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)

		_scroll_by(-drag.relative.y, true)
		_kinetic_speed = clampf(lerpf(_kinetic_speed, -drag.velocity.y, 0.5), -MAX_FLING_SPEED, MAX_FLING_SPEED)
		return true

	# Discard an emulated mouse companion only while an actual finger owns it.
	if _touch_index >= 0 and is_instance_valid(_target) and (
		event is InputEventMouseButton or event is InputEventMouseMotion
	) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return true
	return false


func _scroll_by(distance: float, elastic_edge: bool) -> void:
	if not is_instance_valid(_target):
		return
	var bar := _target.get_v_scroll_bar()
	var upper := maxf(bar.max_value - bar.page, 0.0)
	var desired := _scroll_position + distance
	_scroll_position = clampf(desired, 0.0, upper)
	_target.scroll_vertical = int(round(_scroll_position))
	if elastic_edge and desired != _scroll_position:
		_elastic = clampf(_elastic - (desired - _scroll_position) * ELASTIC_DRAG, -ELASTIC_LIMIT, ELASTIC_LIMIT)
		_kinetic_speed = 0.0
		_elastic_speed = 0.0
	_apply_elastic()


func _get_content(scroll: ScrollContainer) -> Control:
	for child in scroll.get_children():
		if child is Control and not child is ScrollBar:
			return child as Control
	return null


func _apply_elastic() -> void:
	if not is_instance_valid(_content):
		_applied_elastic = 0.0
		return
	_content.position.y += _elastic - _applied_elastic
	_applied_elastic = _elastic


func _stop_motion() -> void:
	if is_instance_valid(_content) and not is_zero_approx(_applied_elastic):
		_content.position.y -= _applied_elastic
	_applied_elastic = 0.0
	_elastic = 0.0
	_elastic_speed = 0.0
	_kinetic_speed = 0.0
	if is_instance_valid(_target) and _dragging:
		_target.propagate_notification(Control.NOTIFICATION_SCROLL_END)
	elif is_instance_valid(_target) and _touch_index < 0:
		_target.propagate_notification(Control.NOTIFICATION_SCROLL_END)


func _find_scroll_at(root: Node, point: Vector2) -> ScrollContainer:
	if not is_instance_valid(root):
		return null
	return _find_scroll_recursive(root, point)


func _find_scroll_recursive(node: Node, point: Vector2) -> ScrollContainer:
	var children := node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var child := children[index] as Node
		if child is CanvasItem and not (child as CanvasItem).is_visible_in_tree():
			continue
		var nested := _find_scroll_recursive(child, point)
		if is_instance_valid(nested):
			return nested
	if not node is ScrollContainer:
		return null
	var scroll := node as ScrollContainer
	if not _can_scroll(scroll, point):
		return null
	return scroll


func _can_scroll(scroll: ScrollContainer, point: Vector2) -> bool:
	if not scroll.is_visible_in_tree() or scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED or not scroll.get_global_rect().has_point(point):
		return false
	var bar := scroll.get_v_scroll_bar()
	return bar.max_value - bar.page > 0.5


func _clear_state() -> void:
	_touch_index = -1
	_target = null
	_content = null
	_start_position = Vector2.ZERO
	_scroll_position = 0.0
	_dragging = false
	_horizontal_locked = false
