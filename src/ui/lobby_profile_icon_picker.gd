extends RefCounted
## Retained ten-slot gallery. Navigation and selection never write the save.
const STORE := preload("res://src/systems/profile_cosmetic_store.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const BUTTON := preload("res://src/ui/drag_safe_button.gd")
const BASE := Vector2(900, 1200)
const PAGE_SIZE := 10
var owner_ref: WeakRef
var overlay: ColorRect
var panel: PanelContainer
var preview: TextureRect
var info := {}
var confirm: Button
var notice: Label
var previous: Button
var next: Button
var page_label: Label
var slots: Array[Dictionary] = []
var ids: Array[String] = []
var available: Array[String] = []
var candidate := ""
var scope_key := ""
var page := 0

func install(owner: RefCounted) -> void:
	owner_ref = weakref(owner)
	var host: Control = owner.lobby
	overlay = ColorRect.new()
	overlay.name = "ProfileIconPicker"
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.z_index = 110
	overlay.focus_mode = Control.FOCUS_ALL
	host.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.name = "IconPickerFrame"
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 24))
	overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label(header, "아이콘 변경", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var exit := _button(header, "×\n닫기", close)
	exit.custom_minimum_size = Vector2(92, 86)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.custom_minimum_size.y = 438
	column.add_child(top)
	var left := _section(top, "현재 아이콘", 338)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(center)
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(286, 286)
	icon_frame.add_theme_stylebox_override("panel", FRAMES.style("shop_featured_frame", 12))
	center.add_child(icon_frame)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_frame.add_child(preview)
	var right := _section(top, "아이콘 정보", 0)
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pair in [["type", "종류"], ["name", "이름"], ["source", "획득처"], ["status", "상태"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		right.add_child(row)
		var label := _label(row, pair[1] + "  :", 28)
		label.custom_minimum_size.x = 114
		var value := _label(row, "", 28)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info[pair[0]] = value
	confirm = _button(right, "확정하기", _confirm)
	confirm.custom_minimum_size.y = 90
	notice = _label(right, "확정하기 전에는 변경 내용이 저장되지 않습니다.", 21)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bottom := _section(column, "보유 아이콘", 0)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	bottom.add_child(grid)
	for i in range(PAGE_SIZE):
		var button := _button(grid, "", _select_slot.bind(i))
		button.custom_minimum_size = Vector2(142, 164)
		button.expand_icon = true
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 116)
		button.add_theme_font_size_override("font_size", 20)
		slots.append({"button": button, "id": ""})
	var pager := HBoxContainer.new()
	column.add_child(pager)
	previous = _button(pager, "‹", _turn_page.bind(-1))
	previous.custom_minimum_size = Vector2(84, 64)
	page_label = _label(pager, "", 26)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next = _button(pager, "›", _turn_page.bind(1))
	next.custom_minimum_size = Vector2(84, 64)
	overlay.resized.connect(_layout)
	# Wrapped labels initially measure before container widths are assigned.
	# Reset the logical size once their real minimum settles, not every frame.
	panel.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	overlay.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_cancel"):
			close()
			overlay.accept_event())
	_layout()
	close()

func _section(parent: Node, title: String, width: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size.x = width
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL if width == 0 else Control.SIZE_FILL
	frame.add_theme_stylebox_override("panel", FRAMES.style("shop_featured_frame", 18))
	parent.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	frame.add_child(column)
	var heading := _label(column, "✦  " + title + "  ✦", 30)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return column

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ead1f5"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := BUTTON.new()
	button.text = text
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color("ffe6a3"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 10, Color("8c789d") if state == "disabled" else Color.WHITE))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.connect("confirmed", callback)
	parent.add_child(button)
	return button

func _layout() -> void:
	if panel == null: return
	panel.size = BASE
	var factor := minf(1.0, minf(maxf(1, overlay.size.x - 32) / BASE.x, maxf(1, overlay.size.y - 32) / BASE.y))
	panel.scale = Vector2.ONE * factor
	panel.position = (overlay.size - BASE * factor) * 0.5

func open() -> void:
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null or owner._blocked(): return
	scope_key = owner._scope_key()
	ids.clear()
	for id in CATALOG.ids():
		var path := CATALOG.path(id, "avatar")
		if not path.is_empty() and FileAccess.file_exists(path): ids.append(id)
	available = STORE.choices("avatar")
	candidate = STORE.selected_id("avatar")
	page = maxi(0, ids.find(candidate)) / PAGE_SIZE
	_render()
	overlay.show()
	overlay.grab_focus()

func close() -> void:
	if overlay != null: overlay.hide()
	candidate = ""
	scope_key = ""

func refresh_state() -> void:
	if not overlay.visible: return
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null or owner._scope_key() != scope_key or owner._blocked():
		close()
		return
	available = STORE.choices("avatar")
	_render()

func _turn_page(direction: int) -> void:
	page = clampi(page + direction, 0, maxi(0, (ids.size() - 1) / PAGE_SIZE))
	_render()

func _select_slot(index: int) -> void:
	if slots[index].id.is_empty(): return
	candidate = slots[index].id
	refresh_state()

func _render() -> void:
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null: return
	for i in range(PAGE_SIZE):
		var offset := page * PAGE_SIZE + i
		var id := ids[offset] if offset < ids.size() else ""
		slots[i].id = id
		var button: Button = slots[i].button
		button.disabled = id.is_empty()
		button.icon = null
		button.text = ""
		if id.is_empty(): continue
		var owned: bool = id in available
		button.icon = owner._texture(CATALOG.path(id, "avatar")) if owned else owner._lock_texture()
		button.text = "미보유" if not owned else ("선택 중" if id == candidate else "")
		button.modulate = Color("ffe8a0") if id == candidate else Color.WHITE
		button.tooltip_text = CATALOG.display_name(id)
	var owned: bool = candidate in available
	preview.texture = owner._texture(CATALOG.path(candidate, "avatar")) if owned else owner._lock_texture()
	var details := CATALOG.icon_info(candidate)
	for key in ["type", "name", "source"]: info[key].text = details.get(key, "—")
	info.status.text = "보유 중" if owned else "미보유 · 잠김"
	info.status.add_theme_color_override("font_color", Color("a5eb68") if owned else Color("bcaccb"))
	confirm.disabled = not owned or candidate == STORE.selected_id("avatar")
	notice.text = "확정하기 전에는 변경 내용이 저장되지 않습니다."
	var count := maxi(1, ceili(float(ids.size()) / PAGE_SIZE))
	page_label.text = "%d / %d" % [page + 1, count]
	previous.disabled = page <= 0
	next.disabled = page + 1 >= count

func _confirm() -> void:
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null or not overlay.visible or owner._scope_key() != scope_key or owner._blocked():
		close()
		return
	if candidate not in STORE.choices("avatar") or candidate == STORE.selected_id("avatar"): return
	if not STORE.select("avatar", candidate):
		notice.text = "변경을 저장하지 못했습니다. 다시 시도해 주세요."
		return
	owner.refresh()
	close()
