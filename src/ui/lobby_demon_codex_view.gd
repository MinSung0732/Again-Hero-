extends RefCounted
## Event-driven, read-only encyclopedia. Pages, cards and textures survive navigation.
const DATA := preload("res://src/data/demon_codex_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const BUTTON := preload("res://src/ui/drag_safe_button.gd")
const ICON := preload("res://src/ui/codex_skill_icon.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var content_parent: BoxContainer
var previous_separation := 28
var root: VBoxContainer
var title_plate: PanelContainer
var tabs: GridContainer
var scroll: ScrollContainer
var stack: VBoxContainer
var pages: Dictionary = {}
var selected := "skills"
var textures: Dictionary = {}
var monster_pages: Dictionary = {}
const CARD_HEIGHT := 160.0
const DETAIL_CACHE_LIMIT := 8
const PANEL_PADDING := 44.0
const MODAL_PADDING := 32.0
var detail_layer: CanvasLayer
var detail_root: Control
var detail_panel: PanelContainer
var detail_stack: VBoxContainer
var detail_scroll: ScrollContainer
var detail_close: Button
var detail_title: Label
var detail_category := ""
const SUMMARY_HEIGHT := 132.0
var preview_layer: CanvasLayer
var preview_root: Control
var preview_background: TextureRect
var preview_exit: Button
var art_textures: Dictionary = {}
var preview_image: TextureRect
var preview_title: Label
var preview_note: Label

func install(owner: RefCounted, parent: Control) -> void:
	content_parent = parent as BoxContainer
	if content_parent != null: previous_separation = content_parent.get_theme_constant("separation")
	root = VBoxContainer.new()
	root.name = "DemonCodexContent"
	root.focus_mode = Control.FOCUS_ALL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	parent.add_child(root)
	var heading := Label.new()
	heading.text = "마왕 도감"
	title_plate = owner._title_plate(owner.lobby.other_tab, heading)
	title_plate.name = "DemonCodexTitlePlate"
	tabs = GridContainer.new()
	tabs.columns = 2
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	root.add_child(tabs)
	for category in DATA.CATEGORIES:
		var button := _button(tabs, DATA.CATEGORY_SHORT[category[0]], select_category.bind(category[0]))
		button.tooltip_text = category[1]
		button.name = String(category[0]).to_pascal_case()
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	_build_detail(owner.lobby)
	_build_preview(owner.lobby)
	root.resized.connect(_resize)
	root.visibility_changed.connect(func():
		if not root.is_visible_in_tree():
			close_preview()
			close_detail())
	hide()

func _label(parent: Node, text: String, size: int = 28) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("eadfed"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := BUTTON.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 68
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("ffe7a3"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 12))
	button.confirmed.connect(action)
	parent.add_child(button)
	return button

func _panel(parent: Node) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", PANEL_PADDING))
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(frame)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	frame.add_child(column)
	return column

func _image(parent: Node, extent: int = 104) -> TextureRect:
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(extent, extent)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _texture(path: String) -> Texture2D:
	if path.is_empty(): return null
	if not textures.has(path):
		textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return textures[path]

func _skill(parent: Node, domain: String, owner: String, id: String, title: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	parent.add_child(row)
	var icon := ICON.new()
	row.add_child(icon)
	icon.configure(domain, owner, id)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_label(column, title, 30).add_theme_color_override("font_color", Color("f0cb68"))
	_label(column, text.replace(" · ","\n"))

func show() -> void:
	if content_parent != null: content_parent.add_theme_constant_override("separation",12)
	root.show()
	title_plate.show()
	select_category(selected)

func hide() -> void:
	if root.visible and content_parent != null: content_parent.add_theme_constant_override("separation",previous_separation)
	root.hide()
	title_plate.hide()
	if preview_root != null: close_preview()
	if detail_root != null: close_detail()

func select_category(id: String) -> void:
	if not DATA.CATEGORIES.any(func(entry): return entry[0] == id): return
	if monster_pages.has(selected): monster_pages[selected].saved_scroll = scroll.scroll_vertical
	selected = id
	close_preview()
	close_detail()
	if not pages.has(id):
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 16)
		stack.add_child(page)
		pages[id] = page
		match id:
			"skills": _build_skills(page)
			"augments": _build_augments(page)
			_: _build_monsters(page, id)
	for key in pages: pages[key].visible = key == id
	for index in range(tabs.get_child_count()):
		tabs.get_child(index).modulate = Color.WHITE if DATA.CATEGORIES[index][0] == id else Color("b6a4c3")
	if monster_pages.has(id):
		_restore_list_scroll.call_deferred(id,monster_pages[id].saved_scroll)
	else: scroll.scroll_vertical = 0
	_resize()

func _build_skills(page: VBoxContainer) -> void:
	var intro := _panel(page)
	_label(intro, "마왕의 지휘", 30).add_theme_color_override("font_color", Color("f0cb68"))
	_label(intro, "몬스터를 편성·소환하고 용사의 성장을 관찰합니다. 용사의 빌드와 전투 상황에 맞춰 다음 몬스터를 선택하세요.")
	var ultimate = DATA.ULTIMATES
	_label(intro, "마왕 스킬 게이지 · 최대 %s\n자연 회복 초당 %s\n일반 소환에 쓴 지휘력 ×%s만큼 충전\n용사에게 입힌 실제 체력 피해 ×%s만큼 충전" % [str(ultimate.CHARGE_MAX), str(ultimate.PASSIVE_CHARGE_PER_SECOND), str(ultimate.SUMMON_COST_CHARGE_MULTIPLIER), str(ultimate.HERO_DAMAGE_CHARGE_MULTIPLIER)])
	for id in DATA.ULTIMATES.ORDER:
		var skill := DATA.ULTIMATES.get_skill(id)
		_skill(_panel(page), "demon", "demon", id, skill.name, skill.description + "\n" + DATA.ultimate_stats(id))

func _build_augments(page: VBoxContainer) -> void:
	_label(page, "마왕 전체에 적용되는 일반 증강입니다. 몬스터 전용 증강은 각 몬스터 상세에서 확인하세요.")
	var filter := OptionButton.new()
	filter.add_item("모든 증강")
	var categories := [""]
	for id in DATA.AUGMENT_CATEGORIES:
		categories.append(id)
		filter.add_item(DATA.AUGMENT_CATEGORIES[id])
	filter.custom_minimum_size.y = 62
	filter.add_theme_font_size_override("font_size",26)
	page.add_child(filter)
	var rows: Array[Control] = []
	for entry in DATA.AUGMENTS.NORMAL_AUGMENTS:
		var column := _panel(page)
		column.get_parent().set_meta("category", entry.get("category", ""))
		rows.append(column.get_parent())
		_label(column, String(entry.name), 26).add_theme_color_override("font_color", Color("f0cb68"))
		_label(column, String(entry.description) + "\n최대 %d레벨" % int(entry.get("max_stack", DATA.AUGMENTS.NORMAL_MAX_LEVEL)))
	filter.item_selected.connect(func(index):
		for row in rows: row.visible = index == 0 or row.get_meta("category") == categories[index])

func _build_monsters(page: VBoxContainer, category: String) -> void:
	var transcendent := category == "transcendent"
	var ids := DATA.monster_ids(transcendent)
	var search := LineEdit.new()
	search.placeholder_text = "이름 · 역할 · 종류 검색"
	search.custom_minimum_size.y = 64
	search.add_theme_font_size_override("font_size", 26)
	page.add_child(search)
	var filters := HBoxContainer.new()
	page.add_child(filters)
	var grade := OptionButton.new()
	var role := OptionButton.new()
	for filter in [grade, role]:
		filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter.custom_minimum_size.y = 62
		filter.add_theme_font_size_override("font_size",26)
		filters.add_child(filter)
	grade.add_item("모든 등급")
	role.add_item("모든 역할")
	var grades := [""]
	var roles := [""]
	for id in ids:
		var grade_label := DATA.rarity_label(id)
		var role_label := DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id))
		if not grades.has(grade_label):
			grades.append(grade_label)
			grade.add_item(grade_label)
		if not roles.has(role_label):
			roles.append(role_label)
			role.add_item(role_label)
	var detail := _panel(detail_stack)
	var detail_frame := detail.get_parent() as PanelContainer
	detail_frame.hide()
	var header := Control.new()
	header.name = "FixedMonsterSummary"
	header.custom_minimum_size.y = SUMMARY_HEIGHT
	clip_fixed(header)
	detail.add_child(header)
	var portrait := _image(header, 0)
	portrait.position = Vector2(0,6)
	portrait.size = Vector2(112,120)
	var name_label := _fixed_label(header, "", 32)
	_place_summary_label(name_label, 0, 42)
	name_label.add_theme_color_override("font_color", Color("ffe5a0"))
	var identity := _fixed_label(header, "", 26)
	_place_summary_label(identity, 46, 38)
	var status := _fixed_label(header, "", 24)
	_place_summary_label(status, 88, 34)
	status.add_theme_color_override("font_color", Color("b9a8c9"))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",20)
	detail.add_child(body)
	body.show()
	var description := _label(body, "", 28)
	_label(body,"기본 능력",30).add_theme_color_override("font_color",Color("f0cb68"))
	_label(body,"연구·증강 적용 전 · 공격 거리는 내부 판정 기준",24)
	var stat_grid := VBoxContainer.new()
	stat_grid.add_theme_constant_override("separation",2)
	body.add_child(stat_grid)
	var stat_values: Array[Label] = []
	for field in DATA.STAT_FIELDS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 38
		stat_grid.add_child(row)
		var caption := _label(row,field[1],26)
		caption.add_theme_color_override("font_color",Color("b9a8c9"))
		var value := _label(row,"",28)
		value.size_flags_horizontal = Control.SIZE_SHRINK_END
		value.custom_minimum_size.x = 104
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.clip_text = true
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_values.append(value)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation",8)
	actions.add_theme_constant_override("v_separation",8)
	body.add_child(actions)
	var art_buttons := {}
	if transcendent:
		for pair in [["illustration", "일러스트"], ["banner", "배너"], ["plus_banner", "5초월 배너"]]:
			art_buttons[pair[0]] = _button(actions, pair[1], preview.bind(category, pair[0]))
	var extra := VBoxContainer.new()
	extra.add_theme_constant_override("separation", 20)
	body.add_child(extra)
	var trans_view: RefCounted
	if transcendent:
		trans_view = preload("res://src/ui/transcendent_monster_detail_view.gd").new()
		trans_view.install(extra)
		for label in [trans_view.notes, trans_view.unlock, trans_view.upgrades]:
			label.add_theme_font_size_override("font_size",28)
		for label in trans_view.descriptions + trans_view.upgrade_descriptions:
			label.add_theme_font_size_override("font_size",28)
	var count := _label(page, "",24)
	var pager := HBoxContainer.new()
	pager.add_theme_constant_override("separation",8)
	page.add_child(pager)
	var previous := _button(pager,"‹ 이전",_change_page.bind(category,-1))
	var page_label := _label(pager,"",26)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var next := _button(pager,"다음 ›",_change_page.bind(category,1))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	page.add_child(grid)
	var slots: Array[Dictionary] = []
	for index in range(DATA.PAGE_SIZE):
		var button := _button(grid,"",_select_slot.bind(category,index))
		button.custom_minimum_size.y = CARD_HEIGHT
		var card := Control.new()
		clip_fixed(card)
		button.add_child(card)
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 8
		card.offset_right = -8
		var dot := _image(card,0)
		dot.anchor_left = 0.5
		dot.anchor_right = 0.5
		dot.offset_left = -38
		dot.offset_right = 38
		dot.offset_top = 8
		dot.offset_bottom = 86
		var card_name := _fixed_label(card,"",24)
		_place_card_label(card_name,92,32)
		var card_role := _fixed_label(card,"",20)
		_place_card_label(card_role,128,26)
		slots.append({"button":button,"dot":dot,"name":card_name,"role":card_role,"id":""})
	var search_entries := {}
	for id in ids:
		var role_label := DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id))
		search_entries[id] = {"grade":DATA.rarity_label(id),"role":role_label,"text":(DATA.MONSTERS.get_monster_name(id)+" "+role_label+" "+DATA.MONSTERS.get_species_label(DATA.MONSTERS.get_species(id))).to_lower()}
	monster_pages[category] = {"selected":ids[0],"ids":ids,"filtered":[],"page_index":0,"saved_scroll":0,"slots":slots,"cards":{},"grid":grid,"previous":previous,"next":next,"page_label":page_label,"search_entries":search_entries,"search":search,"grade":grade,"role":role,"grades":grades,"roles":roles,"count":count,"portrait":portrait,"name":name_label,"identity":identity,"status":status,"header":header,"body":body,"stat_values":stat_values,"stat_grid":stat_grid,"description":description,"extra":extra,"trans_view":trans_view,"art_buttons":art_buttons,"detail_cache":{},"detail_frame":detail_frame}
	search.text_changed.connect(func(_text): filter_monsters(category))
	grade.item_selected.connect(func(_index): filter_monsters(category))
	role.item_selected.connect(func(_index): filter_monsters(category))
	filter_monsters(category)

func filter_monsters(category: String) -> void:
	var page: Dictionary = monster_pages[category]
	var query: String = page.search.text.strip_edges().to_lower()
	var filtered: Array[String] = []
	for id in page.ids:
		var entry: Dictionary = page.search_entries[id]
		if (query.is_empty() or entry.text.contains(query)) and (page.grade.selected == 0 or entry.grade == page.grades[page.grade.selected]) and (page.role.selected == 0 or entry.role == page.roles[page.role.selected]): filtered.append(id)
	page.filtered = filtered
	set_page(category,0)

func set_page(category: String, index: int) -> void:
	var page: Dictionary = monster_pages[category]
	var total := DATA.page_count(page.filtered.size())
	page.page_index = clampi(index,0,maxi(0,total-1))
	page.cards.clear()
	var visible_ids := DATA.page_ids(page.filtered,page.page_index)
	for i in range(page.slots.size()):
		var slot: Dictionary = page.slots[i]
		slot.button.visible = i < visible_ids.size()
		if i >= visible_ids.size():
			slot.id = ""
			slot.dot.texture = null
			continue
		var id: String = visible_ids[i]
		slot.id = id
		slot.name.text = DATA.MONSTERS.get_monster_name(id)
		slot.role.text = DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id))
		slot.dot.texture = _texture(DATA.MONSTERS.get_ui_icon_path(id))
		slot.button.tooltip_text = slot.name.text+"\n"+page.search_entries[id].grade+" · "+slot.role.text
		slot.button.modulate = Color.WHITE if id == page.selected else Color("b9aac5")
		page.cards[id] = slot.button
	page.previous.disabled = page.page_index == 0
	page.next.disabled = total == 0 or page.page_index >= total-1
	page.page_label.text = "%d / %d" % [page.page_index+1,total] if total > 0 else "0 / 0"
	page.count.text = "%d종 · 16칸씩 보기 · 카드를 눌러 상세" % page.filtered.size() if total > 0 else "검색 결과가 없습니다."
	page.saved_scroll = 0
	if selected == category: scroll.scroll_vertical = 0

func _change_page(category: String, delta: int) -> void:
	set_page(category,int(monster_pages[category].page_index)+delta)

func _select_slot(category: String, index: int) -> void:
	var id: String = monster_pages[category].slots[index].id
	if not id.is_empty(): _select_card(category,id)

func _restore_list_scroll(category: String, offset: int) -> void:
	if selected == category and root.is_visible_in_tree(): scroll.scroll_vertical = offset

func select_monster(category: String, id: String) -> void:
	if not monster_pages.has(category): return
	var page: Dictionary = monster_pages[category]
	if not page.ids.has(id): return
	page.selected = id
	var monster := DATA.MONSTERS.get_monster(id)
	page.name.text = monster.name
	var state := COLLECTION.load_state()
	var owned := COLLECTION.is_unlocked(id, state)
	page.identity.text = "%s · %s · %s" % [DATA.rarity_label(id), DATA.MONSTERS.get_species_label(DATA.MONSTERS.get_species(id)), DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id))]
	page.identity.tooltip_text = page.identity.text
	page.status.text = ("획득" if owned else "미획득") + " · " + DATA.MONSTERS.get_attack_type_label(DATA.MONSTERS.get_attack_type(id))
	page.description.text = String(monster.get("collection_card", {}).get("identity", "")) if category == "transcendent" else String(monster.get("description", ""))
	page.description.visible = not page.description.text.is_empty()
	page.portrait.texture = _texture(DATA.MONSTERS.get_ui_icon_path(id))
	var values := DATA.stat_values(id)
	for i in range(page.stat_values.size()): page.stat_values[i].text = values[i]
	if category == "transcendent":
		page.trans_view.present(id)
		for kind in page.art_buttons:
			var path := DATA.artwork(id, kind)
			page.art_buttons[kind].disabled = path.is_empty() or not ResourceLoader.exists(path)
			page.art_buttons[kind].tooltip_text = "보상 미리보기 · 장착/해금되지 않습니다." if not page.art_buttons[kind].disabled else "등록된 리소스가 없습니다."
	else:
		if not page.detail_cache.has(id):
			if page.detail_cache.size() >= DETAIL_CACHE_LIMIT:
				var oldest: String = page.detail_cache.keys()[0]
				var expired: Control = page.detail_cache[oldest]
				expired.hide()
				page.extra.remove_child(expired)
				expired.queue_free()
				page.detail_cache.erase(oldest)
			var content := VBoxContainer.new()
			content.add_theme_constant_override("separation", 16)
			page.extra.add_child(content)
			page.detail_cache[id] = content
			var skills := DATA.MONSTERS.get_elite_skills(id)
			var elite_header := HBoxContainer.new()
			content.add_child(elite_header)
			_label(elite_header, "엘리트 기술", 30).add_theme_color_override("font_color",Color("f0cb68"))
			var elite_art := _texture(DATA.elite_portrait(id))
			if elite_art != null and bool(monster.get("can_be_elite", true)):
				_image(elite_header, 64).texture = elite_art
			if not bool(monster.get("can_be_elite",true)):
				_label(content, "엘리트 변형이 없는 몬스터입니다.")
			elif skills.is_empty(): _label(content, "등록된 엘리트 기술이 없습니다.")
			for skill in skills:
				var text := String(skill.get("description", ""))
				if skill.has("cooldown"): text += "\n재사용 %s초" % str(skill.cooldown)
				_skill(content, "elite", id, String(skill.get("id", skill.name)), skill.name, text)
			var groups := DATA.related_augment_groups(id)
			for kind in ["normal","special"]:
				var section := VBoxContainer.new()
				section.name = "NormalAugments" if kind == "normal" else "SpecialAugments"
				section.add_theme_constant_override("separation",14)
				content.add_child(section)
				_label(section,"일반 증강" if kind == "normal" else "특수 증강",30).add_theme_color_override("font_color",Color("f0cb68"))
				section.set_meta("augment_ids",groups[kind].map(func(entry): return String(entry.id)))
				if groups[kind].is_empty(): _label(section,"등록된 증강이 없습니다.",26)
				for entry in groups[kind]: _augment(section,entry)
		for key in page.detail_cache: page.detail_cache[key].visible = key == id
	for key in page.cards:
		page.cards[key].modulate = Color.WHITE if key == id else Color("b9aac5")

func _augment(parent: Node, entry: Dictionary) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	parent.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",12)
	column.add_child(header)
	_label(header,String(entry.name),28).add_theme_color_override("font_color",Color("e8d8ae"))
	var level := _label(header,"최대 %d레벨" % int(entry.get("max_stack",1)),22)
	level.size_flags_horizontal = Control.SIZE_SHRINK_END
	level.autowrap_mode = TextServer.AUTOWRAP_OFF
	level.add_theme_color_override("font_color",Color("b9a8c9"))
	_label(column,String(entry.description).replace(" · ","\n"),26)
	var divider := ColorRect.new()
	divider.color = Color("42314f")
	divider.custom_minimum_size.y = 1
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

func _select_card(category: String, id: String) -> void:
	if not monster_pages.has(category) or not monster_pages[category].ids.has(id): return
	select_monster(category,id)
	detail_category = category
	for key in monster_pages: monster_pages[key].detail_frame.visible = key == category
	detail_title.text = DATA.MONSTERS.get_monster_name(id)+" · 상세 정보"
	detail_root.show()
	detail_scroll.scroll_vertical = 0
	detail_root.grab_focus()

func close_detail() -> void:
	if detail_root == null: return
	detail_root.hide()
	if root.is_visible_in_tree(): root.grab_focus()

func _resize() -> void:
	tabs.columns = 4 if root.size.x >= 460 else 2
	for page in monster_pages.values(): page.grid.columns = 4 if root.size.x >= 640 else (3 if root.size.x >= 460 else 2)

func clip_fixed(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.clip_contents = true

func _fixed_label(parent: Node, text: String, font_size: int) -> Label:
	var label := _label(parent,text,font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.tooltip_text = text
	return label

func _place_summary_label(label: Label, top: float, height: float) -> void:
	label.anchor_right = 1.0
	label.offset_left = 128
	label.offset_top = top
	label.offset_bottom = top + height
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _place_card_label(label: Label, top: float, height: float) -> void:
	label.anchor_right = 1.0
	label.offset_top = top
	label.offset_bottom = top + height
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _build_detail(host: Control) -> void:
	detail_layer = CanvasLayer.new()
	detail_layer.layer = 180
	detail_layer.name = "CodexDetailLayer"
	host.add_child(detail_layer)
	detail_root = Control.new()
	detail_root.name = "CodexDetailModal"
	detail_root.focus_mode = Control.FOCUS_ALL
	detail_root.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_layer.add_child(detail_root)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.01,0.04,0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_panel = PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel",FRAMES.style("shop_featured_frame",MODAL_PADDING))
	detail_root.add_child(detail_panel)
	detail_panel.anchor_left = 0.04
	detail_panel.anchor_top = 0.04
	detail_panel.anchor_right = 0.96
	detail_panel.anchor_bottom = 0.96
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	detail_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	detail_title = _label(header,"몬스터 상세",30)
	detail_close = _button(header,"닫기",close_detail)
	detail_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail_close.custom_minimum_size.x = 140
	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(detail_scroll)
	detail_stack = VBoxContainer.new()
	detail_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_stack)
	detail_root.gui_input.connect(func(event):
		if event.is_action_pressed("ui_cancel"):
			close_detail()
			detail_root.accept_event())
	detail_root.hide()

func _build_preview(host: Control) -> void:
	preview_layer = CanvasLayer.new()
	preview_layer.name = "CodexArtworkLayer"
	preview_layer.layer = 200
	host.add_child(preview_layer)
	preview_root = Control.new()
	preview_root.name = "FullscreenArtwork"
	preview_root.focus_mode = Control.FOCUS_ALL
	preview_root.mouse_filter = Control.MOUSE_FILTER_STOP
	preview_layer.add_child(preview_root)
	# CanvasLayer can still inherit the host Control's tiny rect for anchors.
	# Size explicitly in logical viewport units, only on viewport resize.
	preview_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.get_viewport().size_changed.connect(_resize_preview)
	root.tree_exiting.connect(_disconnect_preview_resize)
	_resize_preview()
	var backdrop := ColorRect.new()
	backdrop.color = Color("0c0814")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_background = _image(preview_root,0)
	preview_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_background.modulate = Color(0.24,0.20,0.28,1)
	preview_image = _image(preview_root,0)
	preview_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_image.offset_top = 104
	preview_image.offset_bottom = -48
	var bar := ColorRect.new()
	bar.color = Color(0.05,0.03,0.09,0.94)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_root.add_child(bar)
	bar.anchor_right = 1.0
	bar.offset_bottom = 96
	preview_exit = _button(preview_root,"‹ 나가기",close_preview)
	preview_exit.position = Vector2(16,14)
	preview_exit.size = Vector2(210,68)
	preview_title = _fixed_label(preview_root,"",28)
	preview_title.anchor_right = 1.0
	preview_title.offset_left = 246
	preview_title.offset_right = -16
	preview_title.offset_top = 14
	preview_title.offset_bottom = 82
	preview_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_note = _fixed_label(preview_root,"리소스 미리보기",22)
	preview_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	preview_note.offset_top = -44
	preview_note.offset_bottom = -8
	preview_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_root.gui_input.connect(func(event):
		if event.is_action_pressed("ui_cancel"):
			close_preview()
			preview_root.accept_event())
	preview_root.hide()

func _resize_preview() -> void:
	preview_root.position = Vector2.ZERO
	preview_root.size = root.get_viewport().get_visible_rect().size
	if detail_root != null: detail_root.size = preview_root.size

func _disconnect_preview_resize() -> void:
	var viewport := root.get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_resize_preview):
		viewport.size_changed.disconnect(_resize_preview)

func close_preview() -> void:
	if preview_root == null: return
	var was_open := preview_root.visible
	preview_root.hide()
	preview_image.texture = null
	preview_background.texture = null
	if was_open and root.is_visible_in_tree():
		if detail_root.visible: detail_root.grab_focus()
		else: root.grab_focus()

func _art_texture(path: String, trim: bool) -> Texture2D:
	var key := path + (":trim" if trim else "")
	if art_textures.has(key): return art_textures[key]
	var texture := _texture(path)
	if texture != null and trim:
		var image := texture.get_image()
		if image != null:
			var bounds := image.get_used_rect()
			if bounds.has_area():
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(bounds)
				texture = atlas
	art_textures[key] = texture
	return texture

func preview(category: String, kind: String) -> void:
	if not monster_pages.has(category): return
	var id: String = monster_pages[category].selected
	var texture := _art_texture(DATA.artwork(id,kind),kind == "illustration")
	if texture == null: return
	preview_title.text = DATA.MONSTERS.get_monster_name(id) + (" · 5초월 배너" if kind == "plus_banner" else (" · 일러스트" if kind == "illustration" else " · 배너"))
	preview_title.tooltip_text = preview_title.text
	preview_image.texture = texture
	preview_background.texture = texture if kind != "illustration" else null
	preview_root.show()
	preview_root.grab_focus()
