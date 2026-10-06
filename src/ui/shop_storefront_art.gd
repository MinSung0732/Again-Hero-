extends RefCounted

# Presentation only: reward rolls, persistence and account history stay in Lobby.
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const CONTENT := "SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/"
const DRAG_SAFE_BUTTON := preload("res://src/ui/drag_safe_button.gd")
var _textures: Dictionary = {}
var _banner_art: TextureRect


# Static GPU gradients bridge illustration and UI; never sample images per frame.
func _fade(parent: Control, horizontal: bool, colors: PackedColorArray, stops: PackedFloat32Array) -> TextureRect:
	var gradient := Gradient.new()
	gradient.colors = colors
	gradient.offsets = stops
	var texture := GradientTexture2D.new()
	texture.width = 128 if horizontal else 1
	texture.height = 1 if horizontal else 128
	texture.gradient = gradient
	texture.fill_to = Vector2.RIGHT if horizontal else Vector2.DOWN
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(rect)
	return rect


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path] as Texture2D


func _image(parent: Control, path: String) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(image)
	return image


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("100917"))
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	return label


func _frame(target: Control, featured: bool = false) -> void:
	target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state in ["normal", "hover", "pressed", "disabled"]:
		var tint := Color.WHITE
		if state == "hover":
			tint = Color(1.08, 1.05, 1.12)
		elif state == "pressed":
			tint = Color("c3a0d8")
		elif state == "disabled":
			tint = Color("8c8198")
		var style := FRAMES.style("shop_featured_frame" if featured else "shop_panel_frame", 12, tint)
		target.add_theme_stylebox_override(state, style)
	target.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _section(panel: PanelContainer) -> void:
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 12))
	var margin := panel.get_node("Margin") as MarginContainer
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	var title := panel.get_node("Margin/VBox/SectionTitle") as Label
	title.custom_minimum_size = Vector2(0.0, 56.0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff0cc"))
	title.add_theme_stylebox_override("normal", FRAMES.style("shop_button_frame", 8))
	title.add_theme_font_size_override("font_size", 34)
	title.text = "◇  %s  ◇" % title.text
	var desc := panel.get_node("Margin/VBox/SectionDesc") as Label
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _plate_style() -> StyleBox:
	return FRAMES.style("shop_button_frame", 12)


func apply(lobby: Control) -> void:
	var title_plate := lobby.get_node("SafeArea/Layout/Content/ShopTab/TitlePlate") as Panel
	title_plate.hide()
	var shop_margin := lobby.get_node("SafeArea/Layout/Content/ShopTab/ShopMargin") as MarginContainer
	shop_margin.offset_left = 4.0
	shop_margin.offset_right = -4.0
	shop_margin.offset_top = 0.0
	shop_margin.offset_bottom = 0.0
	shop_margin.add_theme_constant_override("margin_left", 16)
	shop_margin.add_theme_constant_override("margin_right", 16)
	var title := shop_margin.get_node("ShopLayout/Title") as Label
	title.custom_minimum_size.y = 76.0
	title.text = "◆  마왕 상점  ◆"
	title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_stylebox_override("normal", FRAMES.style("shop_button_frame", 12))
	(shop_margin.get_node("ShopLayout/Guide") as Label).text = "소환 · 유물 · 성장 재화를 한 곳에서 만나세요."
	var content := lobby.get_node(CONTENT.trim_suffix("/")) as VBoxContainer
	content.custom_minimum_size.y = 0.0
	content.add_theme_constant_override("separation", 16)
	(content.get_node("BalancePanel") as Control).hide()
	for section in ["MonsterSection", "RelicSection", "PackageSection"]:
		_section(content.get_node(section) as PanelContainer)
	var package_panel := content.get_node("PackageSection") as PanelContainer
	package_panel.custom_minimum_size.y = 0.0
	var grid := lobby.get("shop_package_grid") as GridContainer
	grid.columns = 2
	grid.custom_minimum_size.y = 0.0
	var package_desc := package_panel.get_node("Margin/VBox/SectionDesc") as Label
	package_desc.text = "골드 · 연구 포인트 보급 상품입니다."
	var relic_vbox := content.get_node("RelicSection/Margin/VBox") as VBoxContainer
	var relic_stage := Control.new()
	relic_stage.custom_minimum_size.y = 310.0
	relic_vbox.add_child(relic_stage)
	relic_vbox.move_child(relic_stage, 2)
	_image(relic_stage, "res://assets/art/UI/shop/relic_banner.png")
	_fade(relic_stage, false, PackedColorArray([Color("100c1a", 0.0), Color("100c1a", 0.4), Color("100c1a")]), PackedFloat32Array([0.0, 0.5, 1.0]))
	var relic_row := relic_vbox.get_node("BuyRow") as HBoxContainer
	relic_row.reparent(relic_stage, false)
	relic_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	relic_row.offset_top = -90.0
	relic_row.offset_bottom = -8.0
	relic_row.offset_left = 12.0
	relic_row.offset_right = -12.0
	(relic_vbox.get_node("Notice") as Label).text = "유물 소환은 준비 중입니다."
	(lobby.get("shop_relic_single_button") as Button).custom_minimum_size.y = 82.0
	(lobby.get("shop_relic_multi_button") as Button).custom_minimum_size.y = 82.0
	relic_row.custom_minimum_size.y = 82.0
	for key in ["shop_history_button", "shop_rates_button", "shop_relic_single_button", "shop_relic_multi_button"]:
		var button := lobby.get(key) as Button
		_frame(button)
		button.custom_minimum_size.y = 76.0
		button.add_theme_font_size_override("font_size", 25)
	for path in ["ShopResultOverlay/Panel", "ShopRatesOverlay/Panel"]:
		var panel := lobby.get_node(path) as Control
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		panel.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 18))
	_configure_banner(lobby)
	_product(lobby.get("shop_single_button") as Button, false)
	_product(lobby.get("shop_multi_button") as Button, true)


func _configure_banner(lobby: Control) -> void:
	var slide := lobby.get("shop_banner_slide") as Control
	_banner_art = _image(slide, "res://assets/art/UI/shop/monster_banner.png")
	slide.move_child(_banner_art, 0)
	var shade := _fade(slide, true, PackedColorArray([Color("10091c", 0.96), Color("10091c", 0.90), Color("10091c", 0.0)]), PackedFloat32Array([0.0, 0.48, 0.82]))
	slide.move_child(shade, 1)
	var panel := slide.get_parent().get_parent() as PanelContainer
	panel.custom_minimum_size.y = 320.0
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 16))
	var margin := slide.get_node("BannerMargin") as MarginContainer
	margin.anchor_right = 0.68
	margin.add_theme_constant_override("margin_left", 66)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 20)
	var description := lobby.get("shop_banner_description") as Label
	description.custom_minimum_size.y = 100.0
	description.add_theme_font_size_override("font_size", 24)
	description.add_theme_color_override("font_color", Color("e5d9ef"))
	description.size_flags_vertical = Control.SIZE_FILL
	var title := lobby.get("shop_banner_title") as Label
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("ffe196"))
	for label in [title, description]:
		label.add_theme_color_override("font_outline_color", Color("100917"))
		label.add_theme_constant_override("outline_size", 4)
	var viewport := slide.get_parent() as Control
	for key in ["shop_banner_prev_button", "shop_banner_next_button"]:
		var button := lobby.get(key) as Button
		button.reparent(viewport, false)
		button.custom_minimum_size = Vector2(58.0, 72.0)
		_frame(button)
		button.add_theme_font_size_override("font_size", 36)
		button.anchor_top = 0.5
		button.anchor_bottom = 0.5
		button.offset_top = -36.0
		button.offset_bottom = 36.0
		var right_side: bool = key == "shop_banner_next_button"
		button.anchor_left = 1.0 if right_side else 0.0
		button.anchor_right = button.anchor_left
		button.offset_left = -62.0 if right_side else 4.0
		button.offset_right = -4.0 if right_side else 62.0
	var dots := lobby.get("shop_banner_dots") as Label
	dots.reparent(viewport, false)
	dots.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dots.offset_left = -100.0
	dots.offset_right = 100.0
	dots.offset_top = -36.0
	dots.offset_bottom = -4.0
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	(slide.get_node("BannerMargin/BannerVBox/BannerFooter") as Control).hide()


func refresh_banner(data: Dictionary) -> void:
	if _banner_art != null:
		_banner_art.texture = _texture(String(data.get("art_path", "")))


func _product(button: Button, featured: bool) -> void:
	button.custom_minimum_size.y = 570.0
	# Keep the existing node/path as a passive visual card. Do not disable the
	# parent BaseButton: a disabled ancestor can make child-button input brittle
	# across desktop/mobile GUI routing. IGNORE is enough to make the card inert.
	button.disabled = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame(button, featured)
	var art := _image(button, "res://assets/art/UI/shop/summon_gate.png")
	art.offset_left = 6.0
	art.offset_right = -6.0
	art.offset_top = 6.0
	art.anchor_bottom = 0.82
	art.offset_bottom = 0.0
	art.modulate = Color("e6caff") if featured else Color("a69caf")
	var shade := _fade(button, false, PackedColorArray([Color("130e20", 0.0), Color("130e20", 0.0), Color("130e20", 0.95), Color("130e20")]), PackedFloat32Array([0.0, 0.40, 0.72, 1.0]))
	shade.offset_left = 6.0
	shade.offset_right = -6.0
	shade.offset_top = 6.0
	shade.offset_bottom = -6.0
	var copy := _label(button, "", 27, Color("fff2d5"))
	copy.name = "ProductCopy"
	copy.anchor_right = 1.0
	copy.anchor_top = 0.64
	copy.anchor_bottom = 0.72
	copy.offset_left = 18.0
	copy.offset_right = -18.0
	var price := _label(button, "", 34, Color("ffe08a"))
	price.name = "ProductPrice"
	price.anchor_right = 1.0
	price.anchor_top = 0.72
	price.anchor_bottom = 0.81
	price.offset_left = 18.0
	price.offset_right = -18.0
	var cta := DRAG_SAFE_BUTTON.new()
	cta.name = "SummonButton"
	cta.text = "소환하기"
	cta.mouse_filter = Control.MOUSE_FILTER_PASS
	cta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cta.add_theme_font_size_override("font_size", 30)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := _plate_style()
		if state == "pressed":
			style.bg_color = Color("3b224b")
		elif state == "disabled":
			style.bg_color = Color("211729")
		cta.add_theme_stylebox_override(state, style)
	cta.add_theme_color_override("font_disabled_color", Color("a99eae"))
	cta.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_child(cta)
	cta.anchor_right = 1.0
	cta.anchor_top = 0.84
	cta.anchor_bottom = 0.96
	cta.offset_left = 16.0
	cta.offset_right = -16.0
	if featured:
		var badge := _label(button, "추천 · 10+1회", 22, Color("fff09c"))
		badge.anchor_left = 0.12
		badge.anchor_right = 0.88
		badge.offset_top = 14.0
		badge.offset_bottom = 64.0
		badge.add_theme_stylebox_override("normal", _plate_style())


func set_product_copy(button: Button, text: String) -> void:
	var copy := button.get_node_or_null("ProductCopy") as Label
	if copy != null:
		button.text = ""
		copy.text = text.get_slice("\n", 0)
		(button.get_node("ProductPrice") as Label).text = text.get_slice("\n", 1)


func decorate_package(button: Button, data: Dictionary) -> void:
	button.text = ""
	button.custom_minimum_size.y = 254.0
	_frame(button, bool(data.get("featured", false)))
	var icon := _image(button, String(data.get("art_path", "")))
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_bottom = 0.49
	icon.offset_top = 18.0
	icon.offset_left = 12.0
	icon.offset_right = -12.0
	var copy := _label(button, "%s\n%s" % [data.get("title", ""), data.get("reward_text", "")], 19, Color("dccce9"))
	copy.anchor_top = 0.49
	copy.anchor_bottom = 0.76
	copy.anchor_right = 1.0
	copy.offset_left = 12.0
	copy.offset_right = -12.0
	var status_text := String(data.get("price_text", "준비 중")) if bool(data.get("enabled", false)) else "준비 중"
	var status := _label(button, status_text, 19, Color("9f91af"))
	status.anchor_top = 0.79
	status.anchor_bottom = 0.94
	status.anchor_right = 1.0
	status.offset_left = 12.0
	status.offset_right = -12.0
