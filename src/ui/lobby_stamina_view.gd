extends RefCounted

const STORE := preload("res://src/systems/stamina_store.gd")
const RULES := preload("res://src/data/stamina_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
var lobby: Control
var value: Label
var details: Label
var overlay: Control
var _info_button: Button
var _info_pinned := false
var _info_title: Label
var timer: Timer
var product: Control
var _refreshing := false
var _entry_center: CenterContainer
var _entry_title: Label
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
	button.add_theme_font_size_override("font_size", 30)
	_place(parent, button, Rect2(0.78, 0.24, 0.16, 0.52))
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
	_info_button = info
	info.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	info.pressed.connect(_toggle_info)
	info.mouse_entered.connect(_hover_info)
	info.mouse_exited.connect(_leave_info)
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
	# One reusable anchored card; no screen dimmer or modal input blocker.
	overlay = PanelContainer.new()
	overlay.name = "StaminaInfoCard"
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 24))
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)
	overlay.hide()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(column)
	_info_title = Label.new()
	_info_title.add_theme_font_size_override("font_size", 30)
	_info_title.add_theme_color_override("font_color", Color("ffe298"))
	_info_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_info_title)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 24)
	details.add_theme_constant_override("line_spacing", 6)
	details.add_theme_color_override("font_color", Color("e8dcf0"))
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(details)
	lobby.resized.connect(_position_info)

func _hover_info() -> void:
	# Mobile touch emulates mouse entry: it must not open then immediately toggle shut.
	if not OS.has_feature("mobile") and not _info_pinned:
		show_info("", false)

func _leave_info() -> void:
	if not _info_pinned:
		close_info()

func _toggle_info() -> void:
	if overlay.visible and _info_pinned:
		close_info()
	else:
		show_info()

func _position_info() -> void:
	if not is_instance_valid(overlay) or not overlay.visible:
		return
	var viewport := lobby.get_viewport_rect()
	var target := _info_button.get_global_rect()
	var width := minf(650, viewport.size.x - 32)
	overlay.custom_minimum_size.x = width
	overlay.size = Vector2(width, overlay.get_combined_minimum_size().y)
	var x := clampf(target.get_center().x - width * 0.5, 16, viewport.size.x - width - 16)
	var y := minf(target.end.y + 12, viewport.size.y - overlay.size.y - 16)
	overlay.position = Vector2(x, maxf(16, y))

func handle_info_input(event: InputEvent) -> bool:
	if not overlay.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		close_info()
		return true
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	else:
		return false
	if not overlay.get_global_rect().has_point(point) and not _info_button.get_global_rect().has_point(point):
		close_info()
	# Outside clicks still activate the requested lobby control.
	return false

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
		_info_title.text = "스테미너  %d / %d" % [int(state.amount), RULES.MAX_NATURAL]
		var copy := "입장 · %d 소모\n로비 복귀 · 전투 시작 %d초 이내 +%d" % [RULES.ENTRY_COST, RULES.EARLY_EXIT_WINDOW_MS / 1000, RULES.EARLY_EXIT_REFUND]
		copy += "\n\n자연회복 · %d분마다 +1 (최대 %d)" % [RULES.RECOVERY_SECONDS / 60, RULES.MAX_NATURAL]
		if not bool(state.get("success", false)):
			copy = "저장 상태를 확인하지 못했습니다. 다시 시도해 주세요."
		elif int(state.amount) >= RULES.MAX_NATURAL:
			copy += "\n회복 완료 · 자연회복이 멈춰 있습니다."
		else:
			copy += "\n다음 +1까지  %s\n최대 충전까지  %s" % [format_duration(int(state.next_seconds)), format_duration(int(state.full_seconds))]
		copy += "\n\n선물·구매분은 %d을 넘겨 보유할 수 있어요.\n충전 상품은 재화 칸의 +에서 확인하세요." % RULES.MAX_NATURAL
		details.text = (_notice + "\n\n" if not _notice.is_empty() else "") + copy

	_refreshing = false

func show_info(message: String = "", pinned: bool = true) -> void:
	if lobby.get_node("/root/TutorialFlow").locks_lobby() or lobby.get_node("/root/SceneTransition").is_transitioning():
		return
	_notice = message
	_info_pinned = pinned
	overlay.show()
	refresh()
	_position_info.call_deferred()

func close_info() -> void:
	_info_pinned = false
	overlay.hide()

func _build_product() -> void:
	var content: Node = lobby.shop_package_grid.get_parent().get_parent().get_parent()
	var parent: Node = content.get_parent()
	product = PanelContainer.new()
	product.name = "StaminaSupply"
	product.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	product.add_theme_stylebox_override("panel", preload("res://src/ui/shop_frame_skin.gd").style("shop_panel_frame", 22))
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
	preload("res://src/ui/shop_frame_skin.gd").apply_button(buy)
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
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entry_center = CenterContainer.new()
	_entry_center.name = "StaminaEntryContent"
	_place(button, _entry_center, Rect2(0, 0, 1, 1))
	_entry_cost = HBoxContainer.new()
	_entry_cost.name = "StaminaEntryCost"
	_entry_cost.add_theme_constant_override("separation", 8)
	_entry_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_center.add_child(_entry_cost)
	_entry_title = Label.new()
	_entry_title.text = "던전 입장"
	_entry_title.add_theme_font_size_override("font_size", 34)
	_entry_title.add_theme_color_override("font_color", Color("fff1ca"))
	_entry_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_entry_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_cost.add_child(_entry_title)
	var icon := TextureRect.new()
	icon.texture = lobby._load_svg_texture_direct(RULES.ICON_PATH)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(30, 38)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	_entry_center.visible = unlocked and not modes.ranked and modes.perspective == "demon" and modes.difficulty == "easy"
	if _entry_center.visible:
		lobby.enter_stage_button.text = ""
	_entry_amount.text = "-%d" % cost if cost > 0 else "무료"

func play_entry_cost(amount: int) -> void:
	refresh()
	if amount <= 0:
		_entry_center.hide()
		return
	if _spend_tween != null and _spend_tween.is_valid():
		_spend_tween.kill()
	_entry_blocker.show()
	_entry_blocker.grab_focus()
	_spend_label.text = "-%d" % amount
	var rect := _entry_amount.get_global_rect()
	_spend_label.position = rect.get_center() - Vector2(80, 48)
	_spend_label.modulate = Color.WHITE
	_spend_label.show()
	_spend_tween = lobby.create_tween().set_parallel(true)
	_spend_tween.tween_property(_spend_label, "position:y", _spend_label.position.y - 74, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spend_tween.tween_property(_spend_label, "modulate:a", 0.0, 0.23).set_delay(0.22)
	await _spend_tween.finished
	_spend_label.hide()
	_entry_blocker.hide()
	_entry_center.hide()
