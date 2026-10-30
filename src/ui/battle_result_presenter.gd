extends RefCounted

const CATALOG = preload("res://src/data/battle_result_catalog.gd")
const SKIN = preload("res://src/ui/pixel_panel_skin.gd")
const PNG_SOURCE = preload("res://src/ui/png_texture_source.gd")
var panel: PanelContainer
var banner: TextureRect
var banner_title: Label
var rewards: GridContainer
var stats: GridContainer
var tip: Label
var cards: Array[PanelContainer] = []
var rows: Array[Label] = []
var tween: Tween

func install(main: Node) -> void:
	panel = main.result_panel
	var box: VBoxContainer = main.result_title.get_parent()
	box.add_theme_constant_override("separation", 8)
	banner = TextureRect.new()
	banner.name = "ResultBanner"
	banner.custom_minimum_size.y = CATALOG.BANNER_HEIGHT
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(banner)
	box.move_child(banner, 0)
	banner_title = Label.new()
	banner_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_title.add_theme_font_size_override("font_size", 42)
	banner_title.add_theme_color_override("font_color", CATALOG.TEXT_COLOR)
	banner_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_title)
	main.result_title.hide()
	main.result_reward.hide()
	rewards = GridContainer.new()
	rewards.name = "RewardCards"
	rewards.columns = 2
	rewards.add_theme_constant_override("h_separation", 8)
	rewards.add_theme_constant_override("v_separation", 6)
	box.add_child(rewards)
	box.move_child(rewards, main.result_reward.get_index() + 1)
	var area: Control = main.result_analysis.get_parent()
	main.result_analysis.hide()
	var analysis_panel := PanelContainer.new()
	analysis_panel.add_theme_stylebox_override("panel", _style())
	area.add_child(analysis_panel)
	var analysis_box := VBoxContainer.new()
	analysis_panel.add_child(analysis_box)
	stats = GridContainer.new()
	stats.name = "ResultStats"
	stats.columns = 2
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analysis_box.add_child(stats)
	tip = Label.new()
	tip.name = "ResultTip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 22)
	analysis_box.add_child(tip)
	_allow_panel_taps(box)
	panel.gui_input.connect(_on_panel_input)

func _allow_panel_taps(node: Node) -> void:
	if node is Control and not node is BaseButton:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_allow_panel_taps(child)

func _style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = CATALOG.CARD_COLOR
	style.border_color = CATALOG.BORDER_COLOR
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	return SKIN.skin_style(style)

func _make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style())
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(content)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)
	var label := Label.new()
	label.name = "Text"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", CATALOG.FONT_SIZE)
	content.add_child(label)
	var quantity := Label.new()
	quantity.name = "Quantity"
	quantity.add_theme_font_size_override("font_size", CATALOG.FONT_SIZE)
	content.add_child(quantity)
	var first := Label.new()
	first.name = "First"
	first.text = "최초"
	first.add_theme_font_size_override("font_size", 18)
	first.add_theme_color_override("font_color", CATALOG.TEXT_COLOR)
	content.add_child(first)
	rewards.add_child(card)
	return card

func show_result(won: bool, title: String, _subtitle: String, reward_text: String, analysis_text: String) -> void:
	if tween and tween.is_valid(): tween.kill()
	var path: String = CATALOG.VICTORY if won else CATALOG.DEFEAT
	if ResourceLoader.exists(path):
		banner.texture = load(path)
	else:
		var image := Image.new()
		if image.load(path) == OK:
			banner.texture = PNG_SOURCE.annotate(ImageTexture.create_from_image(image), path)
	banner_title.text = title
	var lines := reward_text.split("\n", false)
	for i in lines.size():
		if i >= cards.size(): cards.append(_make_card())
		var card := cards[i]
		var content := card.get_child(0)
		var icon: TextureRect = content.get_node("Icon")
		icon.texture = null
		for keyword in CATALOG.ICONS:
			if lines[i].contains(keyword):
				icon.texture = load(CATALOG.ICONS[keyword])
				break
		var regex := RegEx.new()
		regex.compile("\\+[0-9,]+")
		var match_result := regex.search(lines[i])
		var amount := match_result.get_string() if match_result else ""
		content.get_node("Text").text = lines[i].replace(amount, "").strip_edges() if not amount.is_empty() else lines[i]
		content.get_node("Quantity").text = amount
		content.get_node("First").visible = lines[i].contains("최초")
		card.show()
		card.modulate.a = 0.0
	for i in range(lines.size(), cards.size()): cards[i].hide()
	set_analysis(analysis_text)
	banner.modulate.a = 0.0
	banner.position.y = -24.0
	tween = panel.create_tween().set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(banner, "position:y", 0.0, 0.3).from(-24.0)
	for i in lines.size():
		tween.tween_property(cards[i], "modulate:a", 1.0, 0.2).set_delay(0.06 * i)

func set_analysis(value: String) -> void:
	for row in rows: row.hide()
	var count := 0
	var tips: PackedStringArray = []
	for line in value.split("\n", false):
		var colon := line.find(":")
		if colon < 0:
			tips.append(line)
			continue
		for text in [line.left(colon), line.substr(colon + 1).strip_edges()]:
			if count >= rows.size():
				var label := Label.new()
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.add_theme_font_size_override("font_size", CATALOG.FONT_SIZE)
				stats.add_child(label)
				rows.append(label)
			rows[count].text = text
			rows[count].show()
			count += 1
	tip.text = "\n".join(tips)

func finish_animation() -> void:
	if tween and tween.is_valid(): tween.kill()
	banner.modulate.a = 1.0
	banner.position.y = 0.0
	for card in cards: card.modulate.a = 1.0

func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed:
		finish_animation()
