extends PanelContainer

const HOLD_DURATION := 0.28
const CANCEL_DISTANCE := 18.0
signal tapped
var drag_enabled := true

var formation_kind := ""
var formation_id := ""
var preview_title := ""
var preview_icon: Texture2D

var _hold_active := false
var _hold_elapsed := 0.0
var _hold_start := Vector2.ZERO
var _drag_scroll: ScrollContainer
var _scroll_mouse_filter := Control.MOUSE_FILTER_STOP
var _locked_scroll_position := Vector2i.ZERO
var _restoring_scroll := false


func configure_drag(
	kind: String,
	item_id: String,
	title: String,
	icon: Texture2D = null
) -> void:
	formation_kind = kind
	formation_id = item_id
	preview_title = title
	preview_icon = icon
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_begin_hold(event.position)
		else:
			_finish_tap(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_hold(event.position)
		else:
			if event.canceled:
				_cancel_hold()
			else:
				_finish_tap(event.position)
	elif event is InputEventMouseMotion:
		_cancel_hold_after_move(event.position)
	elif event is InputEventScreenDrag:
		_cancel_hold_after_move(event.position)


func _process(delta: float) -> void:
	if not _hold_active:
		set_process(false)
		return
	_hold_elapsed += delta
	if _hold_elapsed < HOLD_DURATION:
		return

	_hold_active = false
	set_process(false)
	_lock_parent_scroll()
	force_drag(
		{
			"formation_kind": formation_kind,
			"formation_id": formation_id,
		},
		_build_drag_preview()
	)


func reset_for_cache() -> void:
	_cancel_hold()
	_restore_parent_scroll()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		_cancel_hold()
	elif what == NOTIFICATION_DRAG_END or what == NOTIFICATION_EXIT_TREE:
		_restore_parent_scroll()


func _lock_parent_scroll() -> void:
	var ancestor := get_parent()
	while ancestor != null and not ancestor is ScrollContainer:
		ancestor = ancestor.get_parent()
	if not ancestor is ScrollContainer:
		return
	_drag_scroll = ancestor as ScrollContainer
	_scroll_mouse_filter = _drag_scroll.mouse_filter
	_locked_scroll_position = Vector2i(_drag_scroll.scroll_horizontal, _drag_scroll.scroll_vertical)
	# Setting the current value cancels the native touch gesture/inertia
	# without changing the list's position or its minimum size.
	_drag_scroll.scroll_vertical = _drag_scroll.scroll_vertical
	_drag_scroll.scroll_horizontal = _drag_scroll.scroll_horizontal
	_drag_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_scroll.get_v_scroll_bar().value_changed.connect(_on_locked_scroll_changed)
	_drag_scroll.get_h_scroll_bar().value_changed.connect(_on_locked_scroll_changed)


func _on_locked_scroll_changed(_value: float) -> void:
	if _restoring_scroll or not is_instance_valid(_drag_scroll):
		return
	_restoring_scroll = true
	_drag_scroll.scroll_vertical = _locked_scroll_position.y
	_drag_scroll.scroll_horizontal = _locked_scroll_position.x
	_restoring_scroll = false


func _restore_parent_scroll() -> void:
	if is_instance_valid(_drag_scroll):
		_drag_scroll.mouse_filter = _scroll_mouse_filter
		_drag_scroll.get_v_scroll_bar().value_changed.disconnect(_on_locked_scroll_changed)
		_drag_scroll.get_h_scroll_bar().value_changed.disconnect(_on_locked_scroll_changed)
	_drag_scroll = null


func _finish_tap(pointer_position: Vector2) -> void:
	var valid := _hold_active and Rect2(Vector2.ZERO, size).has_point(pointer_position)
	if (get_global_transform() * pointer_position).distance_to(_hold_start) > CANCEL_DISTANCE:
		valid = false
	_cancel_hold()
	if valid:
		tapped.emit()


func _begin_hold(pointer_position: Vector2) -> void:
	if formation_kind.is_empty() or formation_id.is_empty():
		return
	_hold_active = true
	_hold_elapsed = 0.0
	_hold_start = get_global_transform() * pointer_position
	set_process(drag_enabled)


func _cancel_hold_after_move(pointer_position: Vector2) -> void:
	if not _hold_active:
		return
	if (get_global_transform() * pointer_position).distance_to(_hold_start) > CANCEL_DISTANCE:
		_cancel_hold()


func _cancel_hold() -> void:
	_hold_active = false
	_hold_elapsed = 0.0
	set_process(false)


func _build_drag_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(230.0, 96.0)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.92)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("24172f")
	style.border_color = Color("e0ad46")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 5.0)
	preview.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	preview.add_child(row)
	preload("res://src/ui/pixel_panel_skin.gd").apply(preview)

	if preview_icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(62.0, 62.0)
		icon_rect.texture = preview_icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = preview_title
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("fff0c2"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return preview
