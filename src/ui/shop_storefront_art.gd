extends RefCounted

# Presentation only: reward rolls, persistence and account history stay in Lobby.
const CONTENT := "SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll/ShopContent/"
const CARD := "res://assets/art/effects/gatcha/gacha_reward_card.png"
const BUTTON := "res://assets/art/effects/gatcha/gacha_button_texture.tres"
var _textures: Dictionary = {}
var _banner_art: TextureRect


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
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = _texture(CARD)
		style.content_margin_left = 0.0
		style.content_margin_right = 0.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
		style.modulate_color = Color("ffe2a2") if featured else Color("cdbbde")
		if state == "hover":
			style.modulate_color = Color.WHITE
		elif state == "pressed":
			style.modulate_color = Color("b598c5")
		target.add_theme_stylebox_override(state, style)
	target.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _section(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100b1b", 0.94)
	style.border_color = Color("d6a344")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var title := panel.get_node("Margin/VBox/SectionTitle") as Label
	title.custom_minimum_size = Vector2(480.0, 60.0)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff0cc"))
	title.add_theme_stylebox_override("normal", _plate_style())
	var desc := panel.get_node("Margin/VBox/SectionDesc") as Label
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _plate_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture(BUTTON)
	style.content_margin_left = 38.0
	style.content_margin_right = 38.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func apply(lobby: Control) -> void:
	var title_plate := lobby.get_node("SafeArea/Layout/Content/ShopTab/TitlePlate") as Panel
	title_plate.add_theme_stylebox_override("panel", _plate_style())
	var content := lobby.get_node(CONTENT.trim_suffix("/")) as VBoxContainer
	content.custom_minimum_size.y = 0.0
	(content.get_node("BalancePanel") as Control).hide()
	for section in ["MonsterSection", "RelicSection", "PackageSection"]:
		_section(content.get_node(section) as PanelContainer)
	var package_panel := content.get_node("PackageSection") as PanelContainer
	package_panel.custom_minimum_size.y = 0.0
	var grid := lobby.get("shop_package_grid") as GridContainer
	grid.columns = 4
	grid.custom_minimum_size.y = 0.0
	var package_desc := package_panel.get_node("Margin/VBox/SectionDesc") as Label
	package_desc.text = "골드 · 연구 포인트 보급 상품입니다."
	var relic_vbox := content.get_node("RelicSection/Margin/VBox") as VBoxContainer
	var relic_art := _image(relic_vbox, "res://assets/art/UI/shop/relic_banner.png")
	relic_art.custom_minimum_size.y = 180.0
	relic_vbox.move_child(relic_art, 2)
	(relic_vbox.get_node("Notice") as Label).text = "유물 소환은 준비 중입니다."
	(lobby.get("shop_relic_single_button") as Button).custom_minimum_size.y = 82.0
	(lobby.get("shop_relic_multi_button") as Button).custom_minimum_size.y = 82.0
	(relic_vbox.get_node("BuyRow") as HBoxContainer).custom_minimum_size.y = 82.0
	_configure_banner(lobby)
	_product(lobby.get("shop_single_button") as Button, false)
	_product(lobby.get("shop_multi_button") as Button, true)


func _configure_banner(lobby: Control) -> void:
	var slide := lobby.get("shop_banner_slide") as Control
	_banner_art = _image(slide, "res://assets/art/UI/shop/monster_banner.png")
	slide.move_child(_banner_art, 0)
	var panel := slide.get_parent().get_parent() as PanelContainer
	panel.custom_minimum_size.y = 300.0
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color("100b1b")
	banner_style.border_color = Color("d6a344")
	banner_style.set_border_width_all(4)
	banner_style.content_margin_left = 4.0
	banner_style.content_margin_right = 4.0
	banner_style.content_margin_top = 4.0
	banner_style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", banner_style)
	var margin := slide.get_node("BannerMargin") as MarginContainer
	margin.anchor_right = 0.65
	margin.add_theme_constant_override("margin_left", 66)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 20)
	var description := lobby.get("shop_banner_description") as Label
	description.custom_minimum_size.y = 80.0
	description.size_flags_vertical = Control.SIZE_FILL
	var title := lobby.get("shop_banner_title") as Label
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("ffe196"))
	for label in [title, description]:
		label.add_theme_color_override("font_outline_color", Color("100917"))
		label.add_theme_constant_override("outline_size", 4)
	var viewport := slide.get_parent() as Control
	for key in ["shop_banner_prev_button", "shop_banner_next_button"]:
		var button := lobby.get(key) as Button
		button.reparent(viewport, false)
		button.custom_minimum_size = Vector2(58.0, 72.0)
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
	button.custom_minimum_size.y = 490.0
	_frame(button, featured)
	var art := _image(button, "res://assets/art/UI/shop/summon_gate.png")
	art.offset_left = 26.0
	art.offset_right = -26.0
	art.offset_top = 30.0
	art.anchor_bottom = 0.65
	art.offset_bottom = 0.0
	var copy := _label(button, "", 23, Color("fff2d5"))
	copy.name = "ProductCopy"
	copy.anchor_right = 1.0
	copy.anchor_top = 0.66
	copy.anchor_bottom = 0.82
	copy.offset_left = 18.0
	copy.offset_right = -18.0
	var cta := _image(button, BUTTON)
	cta.stretch_mode = TextureRect.STRETCH_SCALE
	cta.anchor_top = 0.84
	cta.anchor_bottom = 0.96
	cta.offset_left = 24.0
	cta.offset_right = -24.0
	var cta_text := _label(cta, "소환하기", 26, Color.WHITE)
	cta_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if featured:
		var badge := _label(button, "추천 · 10+1회", 22, Color("fff09c"))
		badge.anchor_left = 0.12
		badge.anchor_right = 0.88
		badge.offset_top = 32.0
		badge.offset_bottom = 70.0
		badge.add_theme_stylebox_override("normal", _plate_style())


func set_product_copy(button: Button, text: String) -> void:
	var copy := button.get_node_or_null("ProductCopy") as Label
	if copy != null:
		button.text = ""
		copy.text = text


func decorate_package(button: Button, data: Dictionary) -> void:
	button.text = ""
	button.custom_minimum_size.y = 254.0
	_frame(button)
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
