extends RefCounted
class_name MobileScrollRouter

# Raw touch scrolling for nested/mobile UI. Godot's native ScrollContainer can
# lose a swipe when the gesture begins on a Button/drag card inside the list.
# This router only claims a gesture after a short vertical move, so taps and
# horizontal banner swipes still belong to the original child control.
const DRAG_START_DISTANCE := 8.0

var _touch_index: int = -1
var _target: ScrollContainer
var _start_position := Vector2.ZERO
var _scroll_position := 0.0
var _dragging := false
var _horizontal_locked := false


func reset() -> void:
	if is_instance_valid(_target) and _dragging:
		_target.propagate_notification(Control.NOTIFICATION_SCROLL_END)
	_clear_state()


func handle_input(event: InputEvent, root: Node) -> bool:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index >= 0:
				return false
			var scroll := _find_scroll_at(root, touch.position)
			if not is_instance_valid(scroll):
				return false
			_touch_index = touch.index
			_target = scroll
			_start_position = touch.position
			_scroll_position = float(scroll.scroll_vertical)
			_dragging = false
			_horizontal_locked = false
			# Stop old kinetic motion immediately. Keep a small native fallback
			# deadzone for cases where the router does not claim the gesture.
			scroll.scroll_vertical = scroll.scroll_vertical
			scroll.scroll_deadzone = int(DRAG_START_DISTANCE)
			return false

		if touch.index != _touch_index:
			return false
		var consumed := _dragging
		if is_instance_valid(_target) and _dragging:
			_target.propagate_notification(
				Control.NOTIFICATION_SCROLL_END
			)
		_clear_state()
		return consumed

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if (
			drag.index != _touch_index
			or not is_instance_valid(_target)
		):
			return false

		var total := drag.position - _start_position
		if not _dragging:
			if _horizontal_locked:
				return false
			if (
				absf(total.x) >= DRAG_START_DISTANCE
				and absf(total.x) > absf(total.y)
			):
				_horizontal_locked = true
				return false
			if absf(total.y) < DRAG_START_DISTANCE:
				return false
			if absf(total.y) < absf(total.x):
				return false
			_dragging = true
			_target.propagate_notification(
				Control.NOTIFICATION_SCROLL_BEGIN
			)

		var bar := _target.get_v_scroll_bar()
		var max_scroll := maxf(
			bar.max_value - bar.page,
			0.0
		)
		_scroll_position = clampf(
			_scroll_position - drag.relative.y,
			0.0,
			max_scroll
		)
		_target.scroll_vertical = int(round(_scroll_position))
		return true

	# Once a real touch owns a scroll gesture, discard its emulated mouse
	# companion so the same finger cannot click/scroll twice.
	if (
		_touch_index >= 0
		and is_instance_valid(_target)
		and (
			event is InputEventMouseButton
			or event is InputEventMouseMotion
		)
		and event.device == InputEvent.DEVICE_ID_EMULATION
	):
		return true

	return false


func _find_scroll_at(root: Node, point: Vector2) -> ScrollContainer:
	if not is_instance_valid(root):
		return null
	return _find_scroll_recursive(root, point)


func _find_scroll_recursive(
	node: Node,
	point: Vector2
) -> ScrollContainer:
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


func _can_scroll(
	scroll: ScrollContainer,
	point: Vector2
) -> bool:
	if (
		not scroll.is_visible_in_tree()
		or scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE
		or scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
		or not scroll.get_global_rect().has_point(point)
	):
		return false
	var bar := scroll.get_v_scroll_bar()
	return bar.max_value - bar.page > 0.5


func _clear_state() -> void:
	_touch_index = -1
	_target = null
	_start_position = Vector2.ZERO
	_scroll_position = 0.0
	_dragging = false
	_horizontal_locked = false
