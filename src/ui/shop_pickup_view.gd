extends RefCounted

const CATALOG := preload("res://src/data/pickup_catalog.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
var lobby: Control
var rates_button: Button
var art: TextureRect
var placeholder: Label
var notice: Label
var buttons: Array[Button] = []
var textures: Dictionary = {}

func _label(parent: Control, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("eee3f4"))
	parent.add_child(label)
	return label

func _texture(path: String) -> Texture2D:
	if not textures.has(path):
		var image := Image.new()
		textures[path] = ImageTexture.create_from_image(image) if FileAccess.file_exists(path) and image.load(path) == OK else null
	return textures[path] as Texture2D

func install(host: Control) -> void:
	lobby = host
	var content := lobby.get_node(lobby.SHOP_STOREFRONT_ART.CONTENT.trim_suffix("/"))
	var section := PanelContainer.new()
	section.name = "PickupSection"
	section.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	section.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 12))
	content.add_child(section)
	content.move_child(section, content.get_node("MonsterSection").get_index() + 1)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	section.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := _label(column, "◇  픽업 몬스터 소환  ◇", 34)
	title.custom_minimum_size.y = 56
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_stylebox_override("normal", FRAMES.style("shop_button_frame", 8))
	var stage := AspectRatioContainer.new()
	stage.name = "Banner"
	stage.ratio = 1939.0 / 811.0
	stage.custom_minimum_size.y = 360
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(stage)
	var viewport := Control.new()
	viewport.clip_contents = true
	stage.add_child(viewport)
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder = _label(viewport, "진행 중인 픽업이 없습니다.\n다음 픽업을 준비하고 있습니다.", 28)
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_outline_color", Color("100917"))
	placeholder.add_theme_constant_override("outline_size", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	for single in [true, false]:
		var button := preload("res://src/ui/drag_safe_button.gd").new() as Button
		button.name = "SingleButton" if single else "MultiButton"
		button.custom_minimum_size.y = 112
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		lobby._apply_lobby_button_skin(button, false, 25)
		button.add_theme_stylebox_override("disabled", FRAMES.style("shop_button_frame", 12, Color("827489")))
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
		button.connect("confirmed", _summon.bind(1 if single else SHOP.MULTI_DRAW_COUNT))
		buttons.append(button)
	rates_button = preload("res://src/ui/drag_safe_button.gd").new() as Button
	rates_button.text = "픽업 확률"
	rates_button.custom_minimum_size.y = 64
	column.add_child(rates_button)
	lobby._apply_lobby_button_skin(rates_button, false, 24)
	rates_button.connect("confirmed", _rates)
	notice = _label(column, "", 22)
	refresh()

func refresh() -> void:
	var event := CATALOG.current()
	var active := not event.is_empty()
	var path := String(event.get("art_path", CATALOG.INACTIVE_ART))
	art.texture = _texture(path)
	# Preserve all baked-in banner text and edges. Only the empty state fills
	# the same viewport with a subdued environmental background.
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if active else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	placeholder.visible = not active or art.texture == null
	if active and art.texture == null:
		placeholder.text = "%s 픽업 이미지를 준비하고 있습니다." % event.get("name", "")
	else:
		placeholder.text = "진행 중인 픽업이 없습니다.\n다음 픽업을 준비하고 있습니다."
	notice.text = "%s · 초월 0.5%% / 초월 내 픽업 가중치 3배\n첫 해금 시 프로필 초상화와 배너 제공" % event.get("name", "") if active else "픽업 소환은 다음 이벤트가 열리면 이용할 수 있습니다."
	for index in range(buttons.size()):
		var cost := SHOP.SINGLE_DRAW_COST if index == 0 else SHOP.MULTI_DRAW_COST
		buttons[index].text = "픽업 소환 %s\n%s 골드" % ["1회" if index == 0 else "10+1회", lobby._format_shop_number(cost)]
		buttons[index].disabled = not CATALOG.can_draw() or lobby._get_shop_gold() < cost
		buttons[index].tooltip_text = ""
	rates_button.disabled = not CATALOG.can_draw()

func _summon(count: int) -> void:
	if CATALOG.can_draw():
		lobby._open_monster_boxes(count, String(CATALOG.current().get("monster_id", "")))

func _rates() -> void:
	if CATALOG.can_draw():
		lobby._show_shop_rates_modal(String(CATALOG.current().get("monster_id", "")))
