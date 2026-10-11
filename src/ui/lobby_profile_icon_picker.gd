extends RefCounted
## Shared avatar/banner picker. Scrolling and selection never write the save.
const STORE := preload("res://src/systems/profile_cosmetic_store.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const BUTTON := preload("res://src/ui/drag_safe_button.gd")
const BASE := Vector2(900, 1200)
var cosmetic_slot := "avatar"
var noun := "아이콘"
var rows := 2
var owner_ref: WeakRef
var overlay: ColorRect
var panel: PanelContainer
var preview: TextureRect
var preview_crop: AtlasTexture
var info := {}
var confirm: Button
var notice: Label
var scroll: ScrollContainer
var strip: HBoxContainer
var slots: Array[Dictionary] = []
var ids: Array[String] = []
var available: Array[String] = []
var candidate := ""
var scope_key := ""

func install(owner: RefCounted, slot: String = "avatar") -> void:
	cosmetic_slot = slot
	noun = "배너" if slot == "banner" else "아이콘"
	rows = 1 if slot == "banner" else 2
	owner_ref = weakref(owner)
	var host: Control = owner.lobby
	overlay = ColorRect.new()
	overlay.name = "ProfileBannerPicker" if slot == "banner" else "ProfileIconPicker"
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
	var title := _label(header, "프로필 배너 변경" if slot == "banner" else "아이콘 변경", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var exit := _button(header, "×\n닫기", close)
	exit.custom_minimum_size = Vector2(92, 86)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	top.custom_minimum_size.y = 438
	column.add_child(top)
	var left := _section(top, "현재 " + noun, 338)
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
	preview.clip_contents = true
	icon_frame.add_child(preview)
	if cosmetic_slot == "banner":
		preview_crop = AtlasTexture.new()
		preview.resized.connect(_refresh_preview_crop)
	var right := _section(top, noun + " 정보", 0)
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
	var bottom := _section(column, "보유 " + noun, 0)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll = ScrollContainer.new()
	scroll.name = "IconHorizontalScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 368
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_deadzone = 16
	scroll.scroll_started.connect(_cancel_scroll_taps)
	if slot == "banner":
		var navigation := HBoxContainer.new()
		navigation.add_theme_constant_override("separation", 10)
		bottom.add_child(navigation)
		var back := _button(navigation, "‹", _scroll_by.bind(-1))
		back.custom_minimum_size = Vector2(32, 76)
		back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(scroll)
		var forward := _button(navigation, "›", _scroll_by.bind(1))
		forward.custom_minimum_size = Vector2(32, 76)
		forward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		bottom.add_child(scroll)
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", 12)
	scroll.add_child(strip)
	var hint := _label(bottom, "좌우로 스크롤하여 " + noun + "을 확인하세요.", 21)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	if not is_instance_valid(panel) or not is_instance_valid(overlay): return
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
		var path := CATALOG.path(id, cosmetic_slot)
		if not path.is_empty() and FileAccess.file_exists(path): ids.append(id)
	available = STORE.choices(cosmetic_slot)
	candidate = STORE.selected_id(cosmetic_slot)
	_sync_slots()
	_render()
	overlay.show()
	overlay.grab_focus()
	_reveal_equipped.call_deferred()

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
	available = STORE.choices(cosmetic_slot)
	_render()

func _sync_slots() -> void:
	# Grow only when the catalog grows; reuse controls on open/selection.
	while slots.size() < ids.size():
		var index := slots.size()
		if index % rows == 0:
			var pair := VBoxContainer.new()
			pair.add_theme_constant_override("separation", 12)
			strip.add_child(pair)
		var pair: VBoxContainer = strip.get_child(index / rows)
		var button := _button(pair, "", _select_slot.bind(index))
		button.custom_minimum_size = Vector2(142, 164)
		button.expand_icon = true
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", 116)
		button.add_theme_font_size_override("font_size", 20)
		var entry := {"button": button, "id": ""}
		if cosmetic_slot == "banner":
			button.custom_minimum_size = Vector2(112, 340)
			var content := VBoxContainer.new()
			content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(content)
			content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			content.offset_left = 10
			content.offset_top = 10
			content.offset_right = -10
			content.offset_bottom = -10
			var art := TextureRect.new()
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			art.clip_contents = true
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content.add_child(art)
			var caption := _label(content, "", 22)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			entry.art = art
			entry.crop = AtlasTexture.new()
			art.resized.connect(_refresh_banner_crop.bind(index))
			entry.caption = caption
		slots.append(entry)
	for i in range(strip.get_child_count()):
		strip.get_child(i).visible = i * rows < ids.size()

static func _face_region(source: Vector2, target: Vector2, focus: Vector2) -> Rect2:
	if source.x <= 0 or source.y <= 0 or target.x <= 0 or target.y <= 0:
		return Rect2(Vector2.ZERO, source)
	var scale_factor := maxf(target.x / source.x, target.y / source.y)
	var extent := target / scale_factor
	var origin := focus * source - extent * 0.5
	origin.x = clampf(origin.x, 0.0, source.x - extent.x)
	origin.y = clampf(origin.y, 0.0, source.y - extent.y)
	return Rect2(origin, extent)

func _refresh_preview_crop() -> void:
	if not is_instance_valid(preview) or preview_crop == null or preview_crop.atlas == null: return
	preview_crop.region = _face_region(preview_crop.atlas.get_size(), preview.size, CATALOG.banner_focus(candidate))

func _refresh_banner_crop(index: int) -> void:
	if index >= slots.size(): return
	var entry := slots[index]
	var art: TextureRect = entry.art
	var crop: AtlasTexture = entry.crop
	if not is_instance_valid(art) or crop.atlas == null or art.size.x <= 0 or art.size.y <= 0: return
	# Reuse one AtlasTexture per card; resize only adjusts its source region.
	crop.region = _face_region(crop.atlas.get_size(), art.size, CATALOG.banner_focus(entry.id))

func _scroll_by(direction: int) -> void:
	# Arrow buttons move within the same strip; they do not rebuild pages.
	_cancel_scroll_taps()
	scroll.scroll_horizontal += direction * 124

func _cancel_scroll_taps() -> void:
	# Native scrolling can start before the button drag threshold is reached.
	for slot in slots: slot.button._reset_gesture()

func _reveal_equipped() -> void:
	if not is_instance_valid(overlay) or not overlay.visible: return
	var index := ids.find(candidate)
	if index >= 0: scroll.ensure_control_visible(slots[index].button)

func _select_slot(index: int) -> void:
	if index < 0 or index >= slots.size() or slots[index].id.is_empty(): return
	candidate = slots[index].id
	refresh_state()

func _render() -> void:
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null: return
	for i in range(slots.size()):
		var id := ids[i] if i < ids.size() else ""
		slots[i].id = id
		var button: Button = slots[i].button
		button.visible = not id.is_empty()
		button.disabled = id.is_empty()
		button.icon = null
		button.text = ""
		if id.is_empty(): continue
		var owned: bool = id in available
		var texture: Texture2D = owner._texture(CATALOG.path(id, cosmetic_slot)) if owned else owner._lock_texture()
		var status := "미보유" if not owned else ("선택 중" if id == candidate else "보유")
		if cosmetic_slot == "banner":
			slots[i].crop.atlas = texture if owned else null
			slots[i].art.texture = slots[i].crop if owned else texture
			slots[i].art.stretch_mode = TextureRect.STRETCH_SCALE if owned else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if owned: _refresh_banner_crop(i)
			slots[i].caption.text = status
			slots[i].caption.add_theme_color_override("font_color", Color("ffe6a3") if id == candidate else Color("ead1f5"))
		else:
			button.icon = texture
			button.text = status if not owned or id == candidate else ""
		button.modulate = Color("ffe8a0") if id == candidate else Color.WHITE
		button.tooltip_text = CATALOG.display_name(id)
	var owned: bool = candidate in available
	var selected_texture: Texture2D = owner._texture(CATALOG.path(candidate, cosmetic_slot)) if owned else owner._lock_texture()
	if cosmetic_slot == "banner":
		preview_crop.atlas = selected_texture if owned else null
		preview.texture = preview_crop if owned else selected_texture
		preview.stretch_mode = TextureRect.STRETCH_SCALE if owned else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if owned: _refresh_preview_crop()
	else:
		preview.texture = selected_texture
	var details := CATALOG.icon_info(candidate)
	for key in ["type", "name", "source"]: info[key].text = details.get(key, "—")
	info.status.text = "보유 중" if owned else "미보유 · 잠김"
	info.status.add_theme_color_override("font_color", Color("a5eb68") if owned else Color("bcaccb"))
	confirm.disabled = not owned or candidate == STORE.selected_id(cosmetic_slot)
	notice.text = "확정하기 전에는 변경 내용이 저장되지 않습니다."

func _confirm() -> void:
	var owner: RefCounted = owner_ref.get_ref()
	if owner == null or not overlay.visible or owner._scope_key() != scope_key or owner._blocked():
		close()
		return
	if candidate not in STORE.choices(cosmetic_slot) or candidate == STORE.selected_id(cosmetic_slot): return
	if not STORE.select(cosmetic_slot, candidate):
		notice.text = "변경을 저장하지 못했습니다. 다시 시도해 주세요."
		return
	owner.refresh()
	close()
