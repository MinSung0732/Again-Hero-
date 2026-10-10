extends Control

signal tool_requested(tool_id: StringName)

const CATALOG := preload("res://src/data/lobby_tool_catalog.gd")
const BUTTON_SIZE := Vector2(104, 108)
const GAP := 8.0
const EDGE_MARGIN := 8.0
const TOP_OFFSET := 190.0
const DIRECT_LIMIT := 3
const BADGE_PATH := "res://assets/art/UI/lobby_tools/notification_dot.svg"

var can_open: Callable
var _badges := {}
var _notifications := {}
var _entries := {}
var _textures := {}
var _actions := {}
var _rails := {}
var _overflow: AcceptDialog
var _overflow_grid: GridContainer
var _notice: AcceptDialog
var _overflow_side: StringName

func install(parent: Control, permission: Callable, entries: Array = CATALOG.ENTRIES) -> void:
	name = "MainToolTrays"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	can_open = permission
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [&"left", &"right"]:
		var rail := VBoxContainer.new()
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rail.add_theme_constant_override("separation", int(GAP))
		add_child(rail)
		_rails[side] = rail
		var matching: Array[Dictionary] = []
		for entry in entries:
			if entry.get("side", &"left") != side:
				continue
			var id := StringName(entry.get("id", ""))
			if id == &"" or _entries.has(id):
				push_warning("Duplicate or empty lobby tool id: %s" % id)
				continue
			_entries[id] = entry
			matching.append(entry)
		var visible_limit := DIRECT_LIMIT if matching.size() <= DIRECT_LIMIT else DIRECT_LIMIT - 1
		for index in range(mini(matching.size(), visible_limit)):
			var entry := matching[index]
			rail.add_child(_button(entry))
		if matching.size() > DIRECT_LIMIT:
			var more := _button({"title": "더보기", "id": &"", "icon": ""})
			more.name = "MoreTools"
			_install_badge(more, StringName("__more_" + String(side)))
			more.pressed.connect(_show_more.bind(side))
			rail.add_child(more)
	resized.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()

# Future mission/community screens can register handlers without changing this view.
func register_action(tool_id: StringName, action: Callable) -> void:
	if action.is_valid():
		_actions[tool_id] = action
	else:
		_actions.erase(tool_id)

func _layout() -> void:
	for side in _rails:
		var rail: VBoxContainer = _rails[side]
		var count := rail.get_child_count()
		var height := count * BUTTON_SIZE.y + maxi(count - 1, 0) * GAP
		# Lower both trays into the side-panel tool area; clamp on resize only.
		var top := minf(TOP_OFFSET, maxf(size.y - height - EDGE_MARGIN, EDGE_MARGIN))
		rail.position = Vector2(EDGE_MARGIN if side == &"left" else size.x - BUTTON_SIZE.x - EDGE_MARGIN, top)
		rail.size = Vector2(BUTTON_SIZE.x, height)

func _style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style

func _button(entry: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.tooltip_text = String(entry.get("title", ""))
	button.add_theme_stylebox_override("normal", _style(Color("241831"), Color("b59252")))
	button.add_theme_stylebox_override("hover", _style(Color("3a254b"), Color("ffe4a0")))
	button.add_theme_stylebox_override("pressed", _style(Color("160e20"), Color("e8bd65")))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), Color("fff1b9")))
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(16, 5)
	art.size = Vector2(72, 72)
	var path := String(entry.get("icon", ""))
	if not path.is_empty():
		if not _textures.has(path):
			_textures[path] = load(path) if ResourceLoader.exists(path) else null
		art.texture = _textures[path]
	button.add_child(art)
	var label := Label.new()
	label.text = String(entry.get("title", ""))
	label.position = Vector2(4, 77)
	label.size = Vector2(96, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("fff0c9"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	var id := StringName(entry.get("id", ""))
	if id != &"":
		button.pressed.connect(_activate.bind(id))
		_install_badge(button, id)
	else:
		var dots := Label.new()
		dots.text = "···"
		dots.position = Vector2(12, 6)
		dots.size = Vector2(80, 70)
		dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dots.add_theme_font_size_override("font_size", 48)
		dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(dots)
	return button

func _allowed() -> bool:
	return is_visible_in_tree() and (not can_open.is_valid() or bool(can_open.call()))

func _activate(id: StringName) -> void:
	if not _allowed():
		return
	if is_instance_valid(_overflow):
		_overflow.hide()
	tool_requested.emit(id)
	if _actions.has(id) and _actions[id].is_valid():
		_actions[id].call()
		return
	if not is_instance_valid(_notice):
		_notice = _dialog()
	_notice.title = String(_entries[id].get("title", "도구"))
	_notice.dialog_text = String(_entries[id].get("empty_message", "이 기능은 준비 중입니다.\n업데이트 후 이 버튼에서 이용할 수 있습니다."))
	_notice.popup_centered(Vector2i(580, 220))

func _dialog() -> AcceptDialog:
	var dialog := AcceptDialog.new()
	dialog.exclusive = true
	dialog.ok_button_text = "닫기"
	dialog.add_theme_stylebox_override("panel", _style(Color("170e25"), Color("eac14d")))
	dialog.add_theme_font_size_override("font_size", 26)
	dialog.get_ok_button().custom_minimum_size = Vector2(150, 64)
	add_child(dialog)
	return dialog

func _show_more(side: StringName) -> void:
	if not _allowed():
		return
	if not is_instance_valid(_overflow):
		_overflow = _dialog()
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(460, 360)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_overflow.add_child(scroll)
		_overflow_grid = GridContainer.new()
		_overflow_grid.columns = 4
		_overflow_grid.add_theme_constant_override("h_separation", 12)
		_overflow_grid.add_theme_constant_override("v_separation", 12)
		scroll.add_child(_overflow_grid)
	if _overflow_side != side:
		# Rebuild only when switching category, never on a frame or repeated opening.
		for child in _overflow_grid.get_children():
			_overflow_grid.remove_child(child)
			child.queue_free()
		for entry in _entries.values():
			if entry.get("side", &"left") == side:
				_overflow_grid.add_child(_button(entry))
		_overflow_side = side
	_overflow.title = "미션 · 이벤트" if side == &"left" else "친구 · 커뮤니티"
	_overflow.popup_centered(Vector2i(560, 500))

func blocks_stage_input(event: InputEvent) -> bool:
	if not is_visible_in_tree():
		return false
	if (is_instance_valid(_notice) and _notice.visible) or (is_instance_valid(_overflow) and _overflow.visible):
		return true
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		for rail in _rails.values():
			# Blank space below shorter rails must remain available for stage swiping.
			for button in rail.get_children():
				if button.get_global_rect().has_point(event.position):
					return true
	return false

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		if is_instance_valid(_notice):
			_notice.hide()
		if is_instance_valid(_overflow):
			_overflow.hide()

# Completion providers call this when unclaimed mission/event rewards change.
# Multiple copies (rail/overflow) share one state; badges do not consume clicks.
func set_notification(tool_id: StringName, active: bool) -> void:
	_notifications[tool_id] = active
	if not _badges.has(tool_id):
		_update_more_notifications()
		return
	for weak in _badges[tool_id]:
		var badge = weak.get_ref()
		if is_instance_valid(badge):
			badge.visible = active
	_update_more_notifications()

func _install_badge(button: Button, id: StringName) -> void:
	var badge := TextureRect.new()
	badge.name = "NotificationDot"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.position = Vector2(80, 1)
	badge.size = Vector2(24, 24)
	if not _textures.has(BADGE_PATH):
		_textures[BADGE_PATH] = load(BADGE_PATH)
	badge.texture = _textures[BADGE_PATH]
	badge.visible = bool(_notifications.get(id, false))
	button.add_child(badge)
	if not _badges.has(id):
		_badges[id] = []
	# Remove dead weak refs when an overflow category is rebuilt.
	var refs: Array = _badges[id]
	for index in range(refs.size() - 1, -1, -1):
		if refs[index].get_ref() == null:
			refs.remove_at(index)
	refs.append(weakref(badge))

func _update_more_notifications() -> void:
	for side in _rails:
		var rail: VBoxContainer = _rails[side]
		var more := rail.get_node_or_null("MoreTools") as Button
		if more == null:
			continue
		var active := false
		for id in _entries:
			if _entries[id].get("side", &"left") == side and bool(_notifications.get(id, false)):
				active = true
				break
		more.get_node("NotificationDot").visible = active
