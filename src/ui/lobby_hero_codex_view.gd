extends RefCounted
const DATA := preload("res://src/data/hero_codex_catalog.gd")
const TAP_BUTTON := preload("res://src/ui/drag_safe_button.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const TABS := ["기본정보","기술·특성","증강","대응전략","리소스"]
var settings_ref: WeakRef
var root: VBoxContainer
var title_plate: PanelContainer
var split: HBoxContainer
var tab_grid: GridContainer
var skill_icons: HFlowContainer
var skill_slots: Array[PanelContainer] = []
var resource_page: GridContainer
var resource_images: Array[TextureRect] = []
var list_scroll: ScrollContainer
var detail_root: VBoxContainer
var list_portraits: Array[TextureRect] = []
var list_names: Array[Label] = []
var encountered_stages: Dictionary = {}
var locked_page: VBoxContainer
var revealed_stages: Dictionary = {}
var unlock_page: VBoxContainer
var unlock_icon: TextureRect
var unlock_tween: Tween
var reveal_active := false
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
		button.name = "HeroCard%d" % selectors.size()
		button.tooltip_text = "잠긴 용사"
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
		name_label.text = "?"
		list_names.append(name_label)
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
	skill_icons = HFlowContainer.new()
	skill_icons.name = "HeroSkillIconSlots"
	skill_icons.add_theme_constant_override("h_separation",12)
	skill_icons.hide()
	stack.add_child(skill_icons)
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
	locked_page = VBoxContainer.new()
	locked_page.name = "LockedHeroInformation"
	locked_page.add_theme_constant_override("separation",24)
	stack.add_child(locked_page)
	var lock_icon := TextureRect.new()
	lock_icon.custom_minimum_size = Vector2(112,112)
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_icon.texture = _portrait_texture("res://assets/art/UI/hero_codex/lock_closed.svg")
	locked_page.add_child(lock_icon)
	var lock_hint := _label(locked_page,26,Color("ded0e8"))
	lock_hint.text = "아직 마주치지 않은 용사입니다.\n전투에서 만나면 정보가 열립니다."
	lock_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_page = VBoxContainer.new()
	unlock_page.name = "HeroInformationUnlock"
	unlock_page.add_theme_constant_override("separation",24)
	stack.add_child(unlock_page)
	unlock_icon = TextureRect.new()
	unlock_icon.custom_minimum_size = Vector2(128,128)
	unlock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unlock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	unlock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	unlock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unlock_page.add_child(unlock_icon)
	var unlock_hint := _label(unlock_page,28,Color("ffe5a0"))
	unlock_hint.text = "용사 정보 해금"
	unlock_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hide()

func _fit_split() -> void:
	list_scroll.custom_minimum_size.x = clampf(root.size.x*0.26,128,240)

func _fit_tabs() -> void:
	tab_grid.columns = 5 if detail_root.size.x >= 640 else 3 if detail_root.size.x >= 440 else 2

func show() -> void:
	root.show()
	title_plate.show()
	var state := PROGRESS.get_hero_codex_state()
	encountered_stages = state.encountered
	revealed_stages = state.revealed
	if not list_loaded:
		for i in range(stage_ids.size()):
			var paths := DATA.resource_paths(stage_ids[i])
			list_portraits[i].texture = _portrait_texture(paths[2],true)
			if list_portraits[i].texture == null: list_portraits[i].texture = _portrait_texture(paths[0])
		list_loaded = true
	for i in range(stage_ids.size()):
		var known := encountered_stages.has(stage_ids[i])
		var profile := DATA.HEROES.get_profile(String(DATA.STAGES.get_stage(stage_ids[i]).get("hero_id","")))
		list_names[i].text = String(profile.get("display_name","용사")) if known else "?"
		list_portraits[i].modulate = Color.WHITE if known else Color(0,0,0,1)
		selectors[i].tooltip_text = list_names[i].text + " 상세정보" if known else "잠긴 용사"
	list_scroll.show()
	detail_root.show()
	select_stage(selected_stage if not selected_stage.is_empty() else stage_ids[0])

func _fit_list_card(button: Button, margin: MarginContainer) -> void:
	button.custom_minimum_size.y = maxf(208,margin.get_combined_minimum_size().y)

func _portrait_texture(path: String, center_content: bool = false) -> Texture2D:
	var cache_key := path + "#centered" if center_content else path
	if not cached_textures.has(cache_key):
		if center_content:
			var source := _portrait_texture(path)
			var source_image := source.get_image() if source != null else null
			var used := source_image.get_used_rect() if source_image != null else Rect2i()
			var centered: Texture2D = source
			if used.has_area():
				var atlas := AtlasTexture.new()
				atlas.atlas = source
				atlas.region = Rect2(used)
				# Keep the original canvas/scale; redistribute only transparent padding.
				var padding := source.get_size() - Vector2(used.size)
				atlas.margin = Rect2(padding * 0.5,padding)
				atlas.filter_clip = true
				centered = atlas
			cached_textures[cache_key] = centered
			return centered
		var image := Image.new()
		cached_textures[cache_key] = ImageTexture.create_from_image(image) if FileAccess.file_exists(path) and image.load(path) == OK else (load(path) as Texture2D if ResourceLoader.exists(path) else null)
	return cached_textures[cache_key] as Texture2D

func hide() -> void:
	_cancel_unlock()
	root.hide()
	title_plate.hide()

func select_stage(id: String) -> void:
	if id not in stage_ids: return
	_cancel_unlock()
	selected_stage = id
	for i in range(selectors.size()):
		selectors[i].add_theme_stylebox_override("normal",_style(stage_ids[i] == id))
	var known := encountered_stages.has(id)
	for tab in tabs: tab.disabled = not known
	portrait.visible = known
	hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if known else HORIZONTAL_ALIGNMENT_CENTER
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if known else HORIZONTAL_ALIGNMENT_CENTER
	locked_page.visible = not known
	if not known:
		skill_icons.hide()
		hero_name.text = "?"
		description.text = "용사 정보 잠김"
		portrait.texture = null
		for page in pages:
			page.text = ""
			page.hide()
		for resource in resource_images: resource.texture = null
		resource_page.hide()
		scroll.scroll_vertical = 0
		return
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
	for i in range(resource_images.size()): resource_images[i].texture = _portrait_texture(resource_paths[i],i >= 2)
	for i in range(pages.size()): pages[i].text = String(entry.pages[i])
	for i in range(selectors.size()):
		selectors[i].add_theme_stylebox_override("normal",_style(stage_ids[i] == id))
	_present_skill_slots(id)
	select_tab(selected_tab)
	if not revealed_stages.has(id): _play_unlock(id)

func _cancel_unlock() -> void:
	if unlock_tween != null:
		unlock_tween.kill()
		unlock_tween = null
	reveal_active = false
	if unlock_page != null: unlock_page.hide()

func _play_unlock(id: String) -> void:
	reveal_active = true
	skill_icons.hide()
	for page in pages: page.hide()
	resource_page.hide()
	unlock_page.modulate = Color.WHITE
	unlock_icon.modulate = Color.WHITE
	unlock_icon.texture = _portrait_texture("res://assets/art/UI/hero_codex/lock_closed.svg")
	unlock_page.show()
	var scope := PROGRESS.ACCOUNT_SCOPE.user_id + "|" + PROGRESS.ACCOUNT_SCOPE.guest_directory
	unlock_tween = root.create_tween()
	unlock_tween.tween_property(unlock_icon,"modulate",Color(1.5,1.3,0.8,1),0.25)
	unlock_tween.tween_callback(func(): unlock_icon.texture = _portrait_texture("res://assets/art/UI/hero_codex/lock_open.svg"))
	unlock_tween.tween_property(unlock_icon,"modulate",Color.WHITE,0.2)
	unlock_tween.tween_interval(0.3)
	unlock_tween.tween_property(unlock_page,"modulate:a",0.0,0.2)
	unlock_tween.tween_callback(func():
		unlock_tween = null
		reveal_active = false
		unlock_page.hide()
		if scope != PROGRESS.ACCOUNT_SCOPE.user_id + "|" + PROGRESS.ACCOUNT_SCOPE.guest_directory:
			hide()
			return
		if PROGRESS.mark_hero_codex_revealed(id): revealed_stages[id] = true
		select_tab(selected_tab)
	)

func select_tab(index: int) -> void:
	if not encountered_stages.has(selected_stage): return
	if index < 0 or index >= tabs.size(): return
	selected_tab = index
	if reveal_active: return
	for i in range(pages.size()):
		pages[i].visible = i == index
	skill_icons.visible = index == 1 and not skill_slots.is_empty()
	resource_page.visible = index == 4
	for i in range(tabs.size()): tabs[i].add_theme_stylebox_override("normal",_style(i == index))
	scroll.scroll_vertical = 0

func _present_skill_slots(id: String) -> void:
	var stage := DATA.STAGES.get_stage(id)
	var profile := DATA.HEROES.get_profile(stage.hero_id)
	var skills: Array = []
	DATA.collect_skills(profile,skills)
	while skill_slots.size() < skills.size():
		var slot := preload("res://src/ui/codex_skill_icon.gd").new()
		skill_icons.add_child(slot)
		skill_slots.append(slot)
	for i in range(skill_slots.size()):
		skill_slots[i].visible = i < skills.size()
		if i < skills.size():
			skill_slots[i].configure("hero",String(stage.hero_id),String(skills[i].id))
			skill_slots[i].tooltip_text = String(skills[i].name)+" · 스킬 아이콘 자리"
