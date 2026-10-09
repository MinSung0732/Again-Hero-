extends RefCounted
const DATA := preload("res://src/data/hero_codex_catalog.gd")
const TAP_BUTTON := preload("res://src/ui/drag_safe_button.gd")
const TABS := ["기본정보","기술·특성","증강","대응전략"]
var settings_ref: WeakRef
var root: VBoxContainer
var title_plate: PanelContainer
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
	var selector_scroll := ScrollContainer.new()
	selector_scroll.name = "HeroSelectorScroll"
	selector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	selector_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(selector_scroll)
	var hint := _label(root,22,Color("b8a3c7"))
	hint.text = "용사 목록을 좌우로 밀어 선택하세요."
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	selector_scroll.add_child(row)
	stage_ids = DATA.STAGES.get_ordered_stage_ids()
	for id in stage_ids:
		var number := int(DATA.STAGES.get_stage(id).get("number",0))
		var name := String(DATA.HEROES.get_profile(String(DATA.STAGES.get_stage(id).get("hero_id",""))).get("display_name","용사"))
		var button := _button(row,"%02d\n%s" % [number,name],select_stage.bind(id),100)
		button.add_theme_font_size_override("font_size",22)
		button.custom_minimum_size.x = 200
		button.tooltip_text = name
		selectors.append(button)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",_style(false))
	root.add_child(card)
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
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation",8)
	root.add_child(tab_row)
	for i in range(TABS.size()):
		tabs.append(_button(tab_row,TABS[i],select_tab.bind(i),72))
	scroll = ScrollContainer.new()
	scroll.name = "HeroCodexScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	for i in range(TABS.size()):
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
	hide()

func show() -> void:
	root.show()
	title_plate.show()
	if selected_stage.is_empty() and not stage_ids.is_empty(): select_stage(stage_ids[0])

func hide() -> void:
	root.hide()
	title_plate.hide()

func select_stage(id: String) -> void:
	if id not in stage_ids: return
	if not cached_entries.has(id): cached_entries[id] = DATA.get_entry(id)
	var entry: Dictionary = cached_entries[id]
	if entry.is_empty(): return
	selected_stage = id
	hero_name.text = "Stage %02d · %s" % [entry.number,entry.name]
	description.text = String(entry.description)
	var path := String(entry.portrait)
	if not cached_textures.has(path):
		# Raw PNG fallback supports editor/local test before asset import.
		var image := Image.new()
		cached_textures[path] = ImageTexture.create_from_image(image) if FileAccess.file_exists(path) and image.load(path) == OK else (load(path) as Texture2D if ResourceLoader.exists(path) else null)
	portrait.texture = cached_textures[path]
	for i in range(pages.size()): pages[i].text = String(entry.pages[i])
	for i in range(selectors.size()):
		selectors[i].add_theme_stylebox_override("normal",_style(stage_ids[i] == id))
	select_tab(selected_tab)

func select_tab(index: int) -> void:
	if index < 0 or index >= pages.size(): return
	selected_tab = index
	for i in range(pages.size()):
		pages[i].visible = i == index
		tabs[i].add_theme_stylebox_override("normal",_style(i == index))
	scroll.scroll_vertical = 0
