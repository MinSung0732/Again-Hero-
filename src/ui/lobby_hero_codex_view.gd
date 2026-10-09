extends RefCounted
const DATA := preload("res://src/data/hero_codex_catalog.gd")
const TAP_BUTTON := preload("res://src/ui/drag_safe_button.gd")
const TABS := ["기본정보","기술·특성","증강","대응전략","리소스"]
var settings_ref: WeakRef
var root: VBoxContainer
var title_plate: PanelContainer
var split: HBoxContainer
var tab_grid: GridContainer
var resource_page: GridContainer
var resource_images: Array[TextureRect] = []
var list_scroll: ScrollContainer
var detail_root: VBoxContainer
var list_portraits: Array[TextureRect] = []
var list_loaded := false
var portrait: TextureRect
var hero_name: Label
var description: Label
var scroll: ScrollContainer
var selectors: Array[Button] = []
var tabs: Array[Button] = []
var pages: Array[RichTextLabel] = []
var cached_entries: Dictionary = {}
var cached_textures: Dictionary = {}
var cached_styles: Dictionary = {}
var stage_ids: Array[String] = []
var selected_stage := ""
var selected_tab := 0

func _label(parent: Node, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _style(active: bool) -> StyleBoxFlat:
	if cached_styles.has(active): return cached_styles[active]
	var style := StyleBoxFlat.new()
	style.bg_color = Color("352447") if active else Color("1d1429")
	style.border_color = Color("ddb96a") if active else Color("695275")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	cached_styles[active] = style
	return style

func _button(parent: Control, text: String, action: Callable, height: float) -> Button:
	var button := TAP_BUTTON.new()
	button.text = text
	button.custom_minimum_size.y = height
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",25)
	button.add_theme_color_override("font_color",Color("eadbc2"))
	for state in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state,_style(false))
	parent.add_child(button)
	button.confirmed.connect(action)
	return button

func install(owner: RefCounted, parent: Control) -> void:
	settings_ref = weakref(owner)
	root = VBoxContainer.new()
	root.name = "HeroCodexContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation",16)
	parent.add_child(root)
	var heading := Label.new()
	heading.text = "용사도감"
	title_plate = owner._title_plate(owner.lobby.other_tab,heading)
	title_plate.name = "HeroCodexTitlePlate"
	split = HBoxContainer.new()
	split.name = "HeroCodexSplit"
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation",16)
	root.add_child(split)
	root.resized.connect(_fit_split)
	list_scroll = ScrollContainer.new()
	list_scroll.name = "HeroCodexListScroll"
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.custom_minimum_size.x = 192
	split.add_child(list_scroll)
	var rows := VBoxContainer.new()
	rows.name = "HeroList"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",16)
	list_scroll.add_child(rows)
	stage_ids = DATA.STAGES.get_ordered_stage_ids()
	for id in stage_ids:
		var stage := DATA.STAGES.get_stage(id)
		var name := String(DATA.HEROES.get_profile(String(stage.get("hero_id",""))).get("display_name","용사"))
		var button := _button(rows,"",select_stage.bind(id),208)
		button.name = String(stage.get("hero_id","")) + "Card"
		button.tooltip_text = name + " 상세정보"
		selectors.append(button)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]:
			margin.add_theme_constant_override("margin_"+side,12)
		var row := VBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation",8)
		margin.add_child(row)
		var image := TextureRect.new()
		image.custom_minimum_size = Vector2(88,112)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(image)
		list_portraits.append(image)
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",10)
		row.add_child(column)
		var name_label := _label(column,22,Color("ffe5a0"))
		name_label.text = name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# The card is a Button, so explicitly propagate its wrapping content's
		# height instead of allowing long introductions to overlap the next row.
		margin.minimum_size_changed.connect(_fit_list_card.bind(button,margin))
	detail_root = VBoxContainer.new()
	detail_root.name = "HeroCodexDetails"
	detail_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_root.add_theme_constant_override("separation",16)
	detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_root)
	detail_root.resized.connect(_fit_tabs)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",_style(false))
	detail_root.add_child(card)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation",18)
	card.add_child(identity)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(160,180)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	identity.add_child(column)
	hero_name = _label(column,32,Color("ffe5a0"))
	description = _label(column,24,Color("ded0e8"))
	tab_grid = GridContainer.new()
	tab_grid.columns = 2
	tab_grid.add_theme_constant_override("h_separation",8)
	tab_grid.add_theme_constant_override("v_separation",8)
	detail_root.add_child(tab_grid)
	for i in range(TABS.size()):
		tabs.append(_button(tab_grid,TABS[i],select_tab.bind(i),64))
	scroll = ScrollContainer.new()
	scroll.name = "HeroCodexScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	for i in range(4):
		var page := RichTextLabel.new()
		page.name = "CodexPage%d" % i
		page.bbcode_enabled = true
		page.fit_content = true
		page.scroll_active = false
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_theme_font_size_override("normal_font_size",26)
		page.add_theme_color_override("default_color",Color("e1d5e7"))
		page.add_theme_constant_override("line_separation",8)
		stack.add_child(page)
		pages.append(page)
	resource_page = GridContainer.new()
	resource_page.name = "HeroResourcePreview"
	resource_page.columns = 2
	resource_page.add_theme_constant_override("h_separation",12)
	resource_page.add_theme_constant_override("v_separation",16)
	stack.add_child(resource_page)
	for title in ["초상화","아이콘 · 초상화 축소","대기 도트","이동 도트"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resource_page.add_child(cell)
		_label(cell,22,Color("f0cb68")).text = title
		var image := TextureRect.new()
		image.custom_minimum_size = Vector2(96,160)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(image)
		resource_images.append(image)
	hide()

func _fit_split() -> void:
	list_scroll.custom_minimum_size.x = clampf(root.size.x*0.26,128,240)

func _fit_tabs() -> void:
	tab_grid.columns = 5 if detail_root.size.x >= 640 else 3 if detail_root.size.x >= 440 else 2

func show() -> void:
	root.show()
	title_plate.show()
	if not list_loaded:
		for i in range(stage_ids.size()):
			var paths := DATA.resource_paths(stage_ids[i])
			list_portraits[i].texture = _portrait_texture(paths[2])
			if list_portraits[i].texture == null: list_portraits[i].texture = _portrait_texture(paths[0])
		list_loaded = true
	list_scroll.show()
	detail_root.show()
	select_stage(selected_stage if not selected_stage.is_empty() else stage_ids[0])

func _fit_list_card(button: Button, margin: MarginContainer) -> void:
	button.custom_minimum_size.y = maxf(208,margin.get_combined_minimum_size().y)

func _portrait_texture(path: String) -> Texture2D:
	if not cached_textures.has(path):
		var image := Image.new()
		cached_textures[path] = ImageTexture.create_from_image(image) if FileAccess.file_exists(path) and image.load(path) == OK else (load(path) as Texture2D if ResourceLoader.exists(path) else null)
	return cached_textures[path] as Texture2D

func hide() -> void:
	root.hide()
	title_plate.hide()

func select_stage(id: String) -> void:
	if id not in stage_ids: return
	if not cached_entries.has(id): cached_entries[id] = DATA.get_entry(id)
	var entry: Dictionary = cached_entries[id]
	if entry.is_empty(): return
	selected_stage = id
	list_scroll.show()
	detail_root.show()
	hero_name.text = String(entry.name)
	description.text = String(entry.description)
	portrait.texture = _portrait_texture(String(entry.portrait))
	var resource_paths := DATA.resource_paths(id)
	for i in range(resource_images.size()): resource_images[i].texture = _portrait_texture(resource_paths[i])
	for i in range(pages.size()): pages[i].text = String(entry.pages[i])
	for i in range(selectors.size()):
		selectors[i].add_theme_stylebox_override("normal",_style(stage_ids[i] == id))
	select_tab(selected_tab)

func select_tab(index: int) -> void:
	if index < 0 or index >= tabs.size(): return
	selected_tab = index
	for i in range(pages.size()):
		pages[i].visible = i == index
	resource_page.visible = index == 4
	for i in range(tabs.size()): tabs[i].add_theme_stylebox_override("normal",_style(i == index))
	scroll.scroll_vertical = 0
