extends Control

const RULES := preload("res://src/data/mission_catalog.gd")
const ICON_SHADER := preload("res://src/ui/mission_icon.gdshader")
const DESIGN_SIZE := Vector2(920, 1160)
var service: Node
var tools: Control
var refresh_wallet: Callable
var _tab := "daily"
var _layer: CanvasLayer
var _overlay: Control
var _panel: PanelContainer
var _rows: VBoxContainer
var _row_cache: Dictionary = {}
var _icons: Dictionary = {}
var _tabs: Dictionary = {}
var _reset: Label
var _status: Label
var _all: Button
var _layout_pending := false
var _ready_style: StyleBoxFlat
var _normal_style: StyleBoxFlat

func install(parent: Control, tray: Control, mission_service: Node, wallet_refresh: Callable) -> void:
	name = "MissionsView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
	service = mission_service
	tools = tray
	refresh_wallet = wallet_refresh
	tools.register_action(&"daily", open)
	service.changed.connect(refresh)
	parent.visibility_changed.connect(_on_parent_visibility)
	refresh()

func _style(fill: String, edge: String, padding: int = 20) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(edge)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(padding)
	return box

func _label(parent: Node, text: String, size_px: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size_px)
	node.add_theme_color_override("font_color", Color("fff0c9"))
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.clip_text = true
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 64
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", _style("32233e", "776184", 12))
	button.add_theme_stylebox_override("hover", _style("493550", "eac14d", 12))
	button.add_theme_stylebox_override("pressed", _style("604724", "f7d579", 12))
	button.add_theme_stylebox_override("disabled", _style("29262e", "524c59", 12))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build() -> void:
	_ready_style = _style("49351f", "eac14d", 12)
	_normal_style = _style("32233e", "776184", 12)
	_layer = CanvasLayer.new()
	_layer.layer = 121
	add_child(_layer)
	_overlay = Control.new()
	_overlay.name = "MissionsModal"
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.resized.connect(_queue_layout)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.8)
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "MissionsPanel"
	_panel.add_theme_stylebox_override("panel", _style("170e25", "eac14d", 28))
	_overlay.add_child(_panel)
	_panel.size = DESIGN_SIZE
	_panel.minimum_size_changed.connect(_queue_layout)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	_panel.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	_label(header, "도전과제", 38)
	_button(header, "닫기", close).custom_minimum_size.x = 112
	# Horizontal scrolling keeps future tab additions within the fixed panel.
	var tab_scroll := ScrollContainer.new()
	tab_scroll.custom_minimum_size.y = 76
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(tab_scroll)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 12)
	tab_scroll.add_child(tab_row)
	for tab in RULES.TABS:
		var id: String = tab.id
		_tabs[id] = _button(tab_row, tab.title, _select_tab.bind(id))
		_tabs[id].custom_minimum_size.x = 230
	_reset = _label(stack, "", 24)
	var scroll := ScrollContainer.new()
	scroll.name = "MissionScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	scroll.add_child(_rows)
	for id in RULES.EVENTS:
		_create_row(id)
	_status = _label(stack, "완료한 미션을 눌러 보상을 받으세요.", 24)
	_all = _button(stack, "모두 받기", _claim.bind(""))
	_all.custom_minimum_size.y = 76
	_overlay.hide()

func _create_row(id: String) -> void:
	# Cache one control per category. Refresh only updates labels/order/state.
	var button := _button(_rows, "", _claim.bind(id))
	button.custom_minimum_size.y = 136
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 22)
	margin.add_child(body)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(88, 88)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := RULES.ICON_DIR + id + ".png"
	_icons[id] = load(path) if ResourceLoader.exists(path) else null
	icon.texture = _icons[id]
	var icon_material := ShaderMaterial.new()
	icon_material.shader = ICON_SHADER
	icon.material = icon_material
	body.add_child(icon)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 7)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(content)
	var title := _label(content, "", 28)
	var reward := _label(content, "", 22)
	var gauge := ProgressBar.new()
	gauge.custom_minimum_size.y = 10
	gauge.show_percentage = false
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_theme_stylebox_override("background", _style("15101c", "15101c", 0))
	gauge.add_theme_stylebox_override("fill", _style("d4af58", "d4af58", 0))
	content.add_child(gauge)
	var state := _label(body, "", 22)
	state.custom_minimum_size.x = 140
	state.size_flags_horizontal = Control.SIZE_FILL
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row_cache[id] = {"button": button, "title": title, "reward": reward, "gauge": gauge, "state": state, "icon_material": icon_material}

func open() -> void:
	if not is_instance_valid(_overlay):
		_build()
	service.flush()
	refresh()
	_overlay.show()
	_queue_layout()

func close() -> void:
	if is_instance_valid(_overlay):
		_overlay.hide()

func _select_tab(id: String) -> void:
	_tab = id
	_status.text = "완료한 미션을 눌러 보상을 받으세요."
	refresh()
	_rows.get_parent().scroll_vertical = 0

func refresh() -> void:
	var snapshot: Dictionary = service.snapshot()
	var success := bool(snapshot.get("success", false))
	tools.set_notification(&"daily", success and int(snapshot.get("claimable", 0)) > 0)
	if not is_instance_valid(_overlay):
		return
	_all.disabled = true
	if not success:
		_status.text = "저장 상태를 확인하지 못했습니다. 다시 시도해 주세요."
		for cached in _row_cache.values():
			cached.button.disabled = true
		return
	_reset.text = RULES.tab(_tab).reset
	for id in _tabs:
		_tabs[id].modulate = Color("f6d681") if id == _tab else Color.WHITE
	var ready := 0
	var position := 0
	for row in snapshot.tabs.get(_tab, []):
		var cached: Dictionary = _row_cache[row.id]
		cached.title.text = row.title
		cached.reward.text = "골드 +%d  ·  연구포인트 +%d" % [row.gold, row.research]
		cached.gauge.max_value = row.target
		cached.gauge.value = row.count
		cached.state.text = "%d / %d\n%s" % [int(row.count), row.target, "수령 완료" if row.claimed else ("보상 받기" if row.complete else "진행 중")]
		# Claimed icons and text are desaturated as well as disabling the card.
		cached.button.modulate = Color(0.48, 0.48, 0.48) if row.claimed else Color.WHITE
		cached.icon_material.set_shader_parameter("desaturation", 1.0 if row.claimed else 0.0)
		var text_color := Color("aaaab0") if row.claimed else Color("fff0c9")
		for label_key in ["title", "reward", "state"]:
			cached[label_key].add_theme_color_override("font_color", text_color)
		cached.button.disabled = row.claimed or not row.complete
		cached.button.add_theme_stylebox_override("normal", _ready_style if row.complete and not row.claimed else _normal_style)
		_rows.move_child(cached.button, position)
		position += 1
		if row.complete and not row.claimed:
			ready += 1
	_all.text = "모두 받기 (%d)" % ready
	_all.disabled = ready == 0

func _claim(id: String) -> void:
	_all.disabled = true
	var result: Dictionary = service.claim(_tab, id)
	refresh()
	if bool(result.get("success", false)):
		_status.text = "골드 +%d · 연구포인트 +%d 획득!" % [result.gold, result.research]
		if refresh_wallet.is_valid():
			refresh_wallet.call()
	else:
		_status.text = "수령할 보상이 없습니다." if result.get("reason") == "not_ready" else "저장 실패 · 보상은 유지됩니다. 다시 시도해 주세요."

func _queue_layout() -> void:
	if not _layout_pending:
		_layout_pending = true
		_layout.call_deferred()

func _layout() -> void:
	_layout_pending = false
	if not is_instance_valid(_panel):
		return
	_panel.size = DESIGN_SIZE.max(_panel.get_combined_minimum_size())
	var available := _overlay.size - Vector2(64, 64)
	var ratio := clampf(minf(available.x / _panel.size.x, available.y / _panel.size.y), 0.05, 1.0)
	_panel.scale = Vector2(ratio, ratio)
	_panel.position = (_overlay.size - _panel.size * ratio) * 0.5

func blocks_stage_input() -> bool:
	return is_instance_valid(_overlay) and _overlay.visible

func _input(event: InputEvent) -> void:
	if blocks_stage_input() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_parent_visibility() -> void:
	if not get_parent().is_visible_in_tree():
		close()
