extends Control

const RULES := preload("res://src/data/exploration_reward_catalog.gd")
var service: Node
var tools: Control
var refresh_wallet: Callable
const DESIGN_SIZE := Vector2(920, 560)

var _layer: CanvasLayer
var _overlay: Control
var _panel: PanelContainer
var _layout_pending := false
var _gauge: ProgressBar
var _percent: Label
var _elapsed: Label
var _gold: Label
var _research: Label
var _status: Label
var _claim: Button

func install(parent: Control, tray: Control, reward_service: Node, wallet_refresh: Callable) -> void:
	name = "ExplorationRewardsView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
	tools = tray
	service = reward_service
	refresh_wallet = wallet_refresh
	tools.register_action(&"exploration", open)
	service.changed.connect(refresh)
	parent.visibility_changed.connect(_on_parent_visibility)
	refresh()

func _style(fill: Color, edge: Color, padding: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(padding)
	return style

func _label(parent: Node, text: String, font_size: int = 28) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff0c9"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Dynamic container widths start at zero. Auto-wrap can temporarily report
	# thousands of pixels of minimum height, which a PanelContainer retains.
	# This compact fixed layout uses explicit line breaks and bounded labels.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _icon(parent: Node, path: String, icon_size: Vector2) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = icon_size
	icon.texture = load(path) if ResourceLoader.exists(path) else null
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

func _build() -> void:
	# Use the game's canvas, not a native/embedded Window with a draggable title
	# bar and its own stretch rules. Cache one fixed-center full-screen modal.
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)
	_overlay = Control.new()
	_overlay.name = "ExplorationModal"
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.resized.connect(_queue_layout)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "RewardPanel"
	_panel.add_theme_stylebox_override("panel", _style(Color("170e25"), Color("eac14d"), 28))
	_overlay.add_child(_panel)
	_panel.size = DESIGN_SIZE
	_panel.minimum_size_changed.connect(_queue_layout)
	_overlay.hide()
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	_panel.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	_label(header, "탐색보상", 38)
	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(90, 64)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 28)
	stack.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_theme_constant_override("separation", 12)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 14)
	body.add_child(right)
	_icon(left, RULES.ICON_PATH, Vector2(140, 112))
	_percent = _label(left, "0% / 300%", 32)
	_gauge = ProgressBar.new()
	_gauge.max_value = RULES.MAX_PERCENT
	_gauge.custom_minimum_size.y = 32
	_gauge.show_percentage = false
	_gauge.add_theme_stylebox_override("background", _style(Color("2b1d3c"), Color("806143"), 4))
	_gauge.add_theme_stylebox_override("fill", _style(Color("e9b951"), Color("ffeaa1"), 0))
	left.add_child(_gauge)
	_elapsed = _label(left, "적립 시간  00:00:00", 27)
	_label(left, "게임 종료·백그라운드 시간만 적립\n3분마다 1% · 최대 15시간", 24)
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 12)
	right.add_child(rewards)
	for kind in [&"gold", &"research"]:
		var plate := PanelContainer.new()
		plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plate.add_theme_stylebox_override("panel", _style(Color("291b37"), Color("806143"), 14))
		rewards.add_child(plate)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		plate.add_child(column)
		_icon(column, RULES.GOLD_ICON_PATH if kind == &"gold" else RULES.RESEARCH_ICON_PATH, Vector2(72, 72))
		_label(column, "골드" if kind == &"gold" else "연구포인트", 25)
		var amount := _label(column, "+0", 34)
		if kind == &"gold":
			_gold = amount
		else:
			_research = amount
	_status = _label(right, "51%부터 보상을\n획득할 수 있습니다.", 24)
	_claim = Button.new()
	_claim.text = "보상 획득"
	_claim.custom_minimum_size.y = 76
	_claim.add_theme_font_size_override("font_size", 30)
	_claim.add_theme_stylebox_override("normal", _style(Color("654b26"), Color("f6d681"), 12))
	_claim.add_theme_stylebox_override("hover", _style(Color("866330"), Color("fff1bb"), 12))
	_claim.add_theme_stylebox_override("pressed", _style(Color("493519"), Color("f6d681"), 12))
	_claim.add_theme_stylebox_override("disabled", _style(Color("30293a"), Color("6e607d"), 12))
	_claim.pressed.connect(_claim_reward)
	right.add_child(_claim)

func open() -> void:
	if not is_instance_valid(_overlay):
		_build()
	refresh()
	_overlay.show()
	_layout_modal()
	_queue_layout()
	_claim.grab_focus()

func close() -> void:
	if is_instance_valid(_overlay):
		_overlay.hide()

func _queue_layout() -> void:
	if _layout_pending:
		return
	_layout_pending = true
	_layout_modal.call_deferred()

func _layout_modal() -> void:
	_layout_pending = false
	if not is_instance_valid(_panel):
		return
	_panel.size = DESIGN_SIZE.max(_panel.get_combined_minimum_size())
	var available := _overlay.size - Vector2(64, 64)
	var ratio := clampf(minf(available.x / _panel.size.x, available.y / _panel.size.y), 0.1, 1.0)
	_panel.scale = Vector2(ratio, ratio)
	_panel.position = (_overlay.size - _panel.size * ratio) * 0.5

func refresh() -> void:
	var state: Dictionary = service.snapshot()
	var valid := bool(state.get("success", false))
	# Chest badge is full-only. Claim eligibility does not turn it on early.
	tools.set_notification(&"exploration", valid and bool(state.get("full", false)))
	if not is_instance_valid(_overlay):
		return
	_claim.disabled = not valid or not bool(state.get("can_claim", false))
	if not valid:
		_status.text = "저장 상태를 확인하지 못했습니다.\n잠시 후 다시 시도해 주세요."
		return
	var percent := int(state.percent)
	_gauge.value = percent
	_percent.text = "%d%% / %d%%" % [percent, RULES.MAX_PERCENT]
	var seconds := int(state.seconds)
	_elapsed.text = "적립 시간  %02d:%02d:%02d" % [int(seconds / 3600), int(seconds / 60) % 60, seconds % 60]
	_gold.text = "+%d" % int(state.gold)
	_research.text = "+%d" % int(state.research)
	_status.text = "가득 찼습니다.\n보상을 획득해 주세요." if state.full else ("보상을 획득할 수 있습니다." if state.can_claim else "51%부터 보상을\n획득할 수 있습니다.")

func _claim_reward() -> void:
	_claim.disabled = true
	var result: Dictionary = service.claim()
	refresh()
	if bool(result.get("success", false)):
		_status.text = "골드 +%d · 연구포인트 +%d\n획득!" % [int(result.gold), int(result.research)]
		if refresh_wallet.is_valid():
			refresh_wallet.call()
	else:
		_status.text = "51%부터 획득 가능합니다." if result.get("reason", "") == "below_threshold" else "저장하지 못했습니다.\n보상은 유지됩니다. 다시 시도해 주세요."

func blocks_stage_input() -> bool:
	return is_instance_valid(_overlay) and _overlay.visible

func _input(event: InputEvent) -> void:
	if blocks_stage_input() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_parent_visibility() -> void:
	if not get_parent().is_visible_in_tree():
		close()
