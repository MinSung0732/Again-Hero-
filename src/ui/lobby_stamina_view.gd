extends RefCounted

const STORE := preload("res://src/systems/stamina_store.gd")
const RULES := preload("res://src/data/stamina_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
var lobby: Control
var value: Label
var details: Label
var overlay: Control
var timer: Timer
var product: Control
var _refreshing := false
var _entry_cost: HBoxContainer
var _entry_amount: Label
var _entry_blocker: Control
var _spend_label: Label
var _spend_tween: Tween

func _frame(fill: Color = Color("130d21")) -> StyleBox:
	return FRAMES.style("shop_panel_frame", 22)

func _place(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.anchor_left = rect.position.x
	child.anchor_top = rect.position.y
	child.anchor_right = rect.end.x
	child.anchor_bottom = rect.end.y
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _label(parent: Control, text: String, rect: Rect2, font_size: int = 25) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ffe293"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	_place(parent, label, rect)
	return label

func _plate(root: Control, name: String, left: float, width: float) -> Panel:
	var panel := Panel.new()
	panel.name = name
	_place(root, panel, Rect2(left, 0.48, width, 0.48))
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", FRAMES.style("header_frame", 16))
	return panel

func _icon(parent: Control, texture: Texture2D, rect: Rect2) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place(parent, icon, rect)

func _plus(parent: Control, action: Callable) -> Button:
	var button := Button.new()
	button.text = "+"
	button.add_theme_font_size_override("font_size", 36)
	_place(parent, button, Rect2(0.76, 0.17, 0.21, 0.66))
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = "상점 충전 상품"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 0, Color("c8abe0") if state == "pressed" else Color.WHITE))
	button.pressed.connect(action)
	return button

func install(host: Control) -> void:
	lobby = host
	STORE.invalidate() # New scene/coupon namespace may have replaced guest files.
	lobby.get_node("SafeArea/Layout/Header").custom_minimum_size.y = 244
	var root := lobby.get_node("SafeArea/Layout/Header/HeaderSlots") as Control
	# The old center logo and wings own no gameplay controls. Replace once;
	# retain the gold/progress label names used by the existing refresh path.
	for child in root.get_children():
		root.remove_child(child)
		child.free()
	var logo := TextureRect.new()
	logo.texture = lobby._load_png_texture_direct(lobby.UI_LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.name = "HeaderLogo"
	_place(root, logo, Rect2(0.17, 0.0, 0.66, 0.45))
	var gold := _plate(root, "HeaderGoldPlate", 0.0, 0.32)
	_icon(gold, lobby._load_ui_texture_resource(lobby.UI_HEADER_COIN_PATH), Rect2(0.07, 0.29, 0.19, 0.42))
	_label(gold, "골드", Rect2(0.25, 0.13, 0.48, 0.30), 26)
	var gold_value := _label(gold, "0", Rect2(0.25, 0.46, 0.48, 0.42), 32)
	gold_value.name = "HeaderGoldValue"
	_plus(gold, lobby._switch_tab.bind("shop"))
	var stamina := _plate(root, "HeaderStaminaPlate", 0.335, 0.36)
	_icon(stamina, lobby._load_svg_texture_direct(RULES.ICON_PATH), Rect2(0.06, 0.20, 0.15, 0.60))
	_label(stamina, "스테미너", Rect2(0.24, 0.13, 0.49, 0.30), 26)
	value = _label(stamina, "30 / 30", Rect2(0.24, 0.46, 0.49, 0.42), 32)
	value.name = "HeaderStaminaValue"
	# One touch target covers both icon and number; + has a separate sibling hitbox.
	var info := Button.new()
	info.name = "StaminaInfoButton"
	_place(stamina, info, Rect2(0.02, 0.05, 0.71, 0.90))
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info.tooltip_text = "스테미너 회복 시간"
	for state in ["normal", "hover", "pressed"]:
		info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	info.pressed.connect(show_info.bind(""))
	_plus(stamina, open_shop).name = "StaminaShopButton"
	var progress := _plate(root, "HeaderProgressPlate", 0.71, 0.29)
	var title := _label(progress, "최고 해금", Rect2(0.12, 0.13, 0.80, 0.30), 26)
	title.name = "HeaderProgressTitle"
	var highest := _label(progress, "Stage 1", Rect2(0.12, 0.46, 0.80, 0.42), 32)
	highest.name = "HeaderProgressValue"
	_build_overlay()
	_build_product()
	_build_entry_feedback()
	timer = Timer.new()
	timer.name = "StaminaDisplayTimer"
	timer.wait_time = 1.0
	lobby.add_child(timer)
	timer.timeout.connect(refresh)
	timer.start()
	refresh()

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StaminaLayer"
	layer.layer = 130 # Tutorial spotlight (150) keeps authority over its input.
	lobby.add_child(layer)
	overlay = ColorRect.new()
	overlay.name = "StaminaOverlay"
	overlay.color = Color(0, 0, 0, 0.80)
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.hide()
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "PanelContainer"
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.custom_minimum_size = Vector2(800, 0)
	panel.add_theme_stylebox_override("panel", _frame())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.name = "VBoxContainer"
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)
	var title := Label.new()
	title.text = "스테미너"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)
	details = Label.new()
	details.custom_minimum_size.x = 730
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 27)
	column.add_child(details)
	var row := HBoxContainer.new()
	row.name = "HBoxContainer"
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	for heading in ["닫기", "충전 상품 보기"]:
		var button := Button.new()
		button.text = heading
		button.custom_minimum_size.y = 80
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 28)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, _frame(Color("482264")))
		row.add_child(button)
		button.pressed.connect(close_info if heading == "닫기" else open_shop)
		if heading == "닫기":
			button.name = "Close"
	overlay.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
			close_info())

var _notice := ""

static func format_duration(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]

func refresh() -> void:
	if _refreshing or not is_instance_valid(value):
		return
	_refreshing = true
	var state := STORE.read_state()
	value.text = "%s / %d" % [lobby._format_shop_number(int(state.amount)), RULES.MAX_NATURAL] if bool(state.get("success", false)) else "확인 필요"
	if is_instance_valid(overlay) and overlay.visible:
		var copy := "%s\n\n현재 스테미너  %d / %d\n던전 입장  %d 소모\n자연회복  1시간마다 1" % [_notice, int(state.amount), RULES.MAX_NATURAL, RULES.ENTRY_COST]
		copy += "\n전투 시작 %d초 이내 로비 복귀 시 %d 반환" % [RULES.EARLY_EXIT_WINDOW_MS / 1000, RULES.EARLY_EXIT_REFUND]
		if not bool(state.get("success", false)):
			copy = "저장 상태를 확인하지 못했습니다. 다시 시도해 주세요."
		elif int(state.amount) >= RULES.MAX_NATURAL:
			copy += "\n\n자연회복 한도에 도달했습니다.\n30 이상에서는 자연회복이 멈춥니다."
		else:
			copy += "\n\n다음 1 회복까지  %s\n30까지 충전 완료  %s" % [format_duration(int(state.next_seconds)), format_duration(int(state.full_seconds))]
		copy += "\n\n선물·구매 충전분은 30을 넘겨 보유할 수 있습니다."
		details.text = copy.strip_edges()
	_refreshing = false

func show_info(message: String = "") -> void:
	if lobby.get_node("/root/TutorialFlow").locks_lobby() or lobby.get_node("/root/SceneTransition").is_transitioning():
		return
	_notice = message
	overlay.show()
	refresh()
	overlay.get_node("CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/Close").grab_focus()

func close_info() -> void:
	overlay.hide()

func _build_product() -> void:
	var content: Node = lobby.shop_package_grid.get_parent().get_parent().get_parent()
	var parent: Node = content.get_parent()
	product = PanelContainer.new()
	product.name = "StaminaSupply"
	product.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	product.add_theme_stylebox_override("panel", _frame())
	parent.add_child(product)
	# Place with existing packages, while keeping the monster tutorial draw first.
	parent.move_child(product, content.get_index())
	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.add_theme_constant_override("separation", 16)
	product.add_child(box)
	var title := Label.new()
	title.text = "스테미너 충전"
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var copy := Label.new()
	copy.text = "선물·구매 스테미너는 최대 30을 넘겨 충전됩니다.\n충전 상품의 가격과 결제 연결을 준비하고 있습니다."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 25)
	box.add_child(copy)
	var buy := Button.new()
	buy.name = "StaminaPurchase"
	buy.text = "구매 준비 중"
	buy.disabled = true
	buy.custom_minimum_size.y = 80
	buy.add_theme_font_size_override("font_size", 28)
	buy.add_theme_stylebox_override("disabled", _frame(Color("21172b")))
	box.add_child(buy)

func open_shop() -> void:
	if lobby.get_node("/root/TutorialFlow").locks_lobby():
		return
	close_info()
	lobby._switch_tab("shop")
	var scroll := lobby.get_node("SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll") as ScrollContainer
	# Containers settle after tab visibility/rebuild before the target can scroll.
	_scroll_to_product.call_deferred(scroll)

func _scroll_to_product(scroll: ScrollContainer) -> void:
	if is_instance_valid(scroll) and is_instance_valid(product):
		scroll.ensure_control_visible(product)

func _build_entry_feedback() -> void:
	var button: Button = lobby.enter_stage_button
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_entry_cost = HBoxContainer.new()
	_entry_cost.name = "StaminaEntryCost"
	_entry_cost.add_theme_constant_override("separation", 8)
	_place(button, _entry_cost, Rect2(0.64, 0.14, 0.30, 0.72))
	var icon := TextureRect.new()
	icon.texture = lobby._load_svg_texture_direct(RULES.ICON_PATH)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size.x = 30
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_cost.add_child(icon)
	_entry_amount = Label.new()
	_entry_amount.text = "-5"
	_entry_amount.add_theme_font_size_override("font_size", 32)
	_entry_amount.add_theme_color_override("font_color", Color("ffe298"))
	_entry_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_entry_amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_cost.add_child(_entry_amount)
	var layer := lobby.get_node("StaminaLayer") as CanvasLayer
	_entry_blocker = Control.new()
	_entry_blocker.name = "EntryFeedbackBlocker"
	layer.add_child(_entry_blocker)
	_entry_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_entry_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_entry_blocker.focus_mode = Control.FOCUS_ALL
	_entry_blocker.hide()
	_spend_label = Label.new()
	_spend_label.name = "StaminaSpendFeedback"
	_spend_label.custom_minimum_size = Vector2(160, 78)
	_spend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spend_label.add_theme_font_size_override("font_size", 54)
	_spend_label.add_theme_color_override("font_color", Color("ffdb8b"))
	_spend_label.add_theme_color_override("font_outline_color", Color("1a092b"))
	_spend_label.add_theme_constant_override("outline_size", 5)
	_spend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_spend_label)
	_spend_label.hide()

func configure_entry(unlocked: bool, cost: int) -> void:
	if _entry_cost == null:
		return
	var modes = lobby.main_modes_view
	_entry_cost.visible = unlocked and not modes.ranked and modes.perspective == "demon" and modes.difficulty == "easy"
	_entry_amount.text = "-%d" % cost if cost > 0 else "무료"

func play_entry_cost(amount: int) -> void:
	refresh()
	if amount <= 0:
		return
	if _spend_tween != null and _spend_tween.is_valid():
		_spend_tween.kill()
	_entry_blocker.show()
	_entry_blocker.grab_focus()
	_spend_label.text = "-%d" % amount
	var rect := _entry_cost.get_global_rect()
	_spend_label.position = rect.get_center() - Vector2(80, 48)
	_spend_label.modulate = Color.WHITE
	_spend_label.show()
	_spend_tween = lobby.create_tween().set_parallel(true)
	_spend_tween.tween_property(_spend_label, "position:y", _spend_label.position.y - 74, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spend_tween.tween_property(_spend_label, "modulate:a", 0.0, 0.23).set_delay(0.22)
	await _spend_tween.finished
	_spend_label.hide()
	_entry_blocker.hide()
	_entry_cost.hide()
