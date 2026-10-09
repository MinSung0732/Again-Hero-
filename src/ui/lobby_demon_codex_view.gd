extends RefCounted
## Event-driven, read-only encyclopedia. Pages, cards and textures survive navigation.
const DATA := preload("res://src/data/demon_codex_catalog.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const BUTTON := preload("res://src/ui/drag_safe_button.gd")
const ICON := preload("res://src/ui/codex_skill_icon.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var root: VBoxContainer
var title_plate: PanelContainer
var tabs: GridContainer
var scroll: ScrollContainer
var stack: VBoxContainer
var pages: Dictionary = {}
var selected := "skills"
var textures: Dictionary = {}
var monster_pages: Dictionary = {}
var popup: PopupPanel
var preview_image: TextureRect
var preview_title: Label
var preview_note: Label

func install(owner: RefCounted, parent: Control) -> void:
	root = VBoxContainer.new()
	root.name = "DemonCodexContent"
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
		var button := _button(tabs, category[1], select_category.bind(category[0]))
		button.name = String(category[0]).to_pascal_case()
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	_build_preview()
	root.resized.connect(_resize)
	root.visibility_changed.connect(func():
		if not root.is_visible_in_tree(): popup.hide())
	hide()

func _label(parent: Node, text: String, size: int = 22) -> Label:
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
	button.custom_minimum_size.y = 62
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("ffe7a3"))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 12))
	button.confirmed.connect(action)
	parent.add_child(button)
	return button

func _panel(parent: Node) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", FRAMES.style("shop_panel_frame", 16))
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
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var icon := ICON.new()
	row.add_child(icon)
	icon.configure(domain, owner, id)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_label(column, title, 26).add_theme_color_override("font_color", Color("f0cb68"))
	_label(column, text)

func show() -> void:
	root.show()
	title_plate.show()
	select_category(selected)

func hide() -> void:
	root.hide()
	title_plate.hide()
	if popup != null: popup.hide()

func select_category(id: String) -> void:
	if not DATA.CATEGORIES.any(func(entry): return entry[0] == id): return
	selected = id
	popup.hide()
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
	if monster_pages.has(id): select_monster(id, monster_pages[id].selected)
	scroll.scroll_vertical = 0
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
	filter.custom_minimum_size.y = 56
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
	_label(page, "초월 기술·해금조건과 보상 미리보기" if transcendent else "기본 능력 · 엘리트 기술 · 몬스터 전용 증강", 26)
	var search := LineEdit.new()
	search.placeholder_text = "이름 · 역할 · 종류 검색"
	search.custom_minimum_size.y = 58
	page.add_child(search)
	var filters := HBoxContainer.new()
	page.add_child(filters)
	var grade := OptionButton.new()
	var role := OptionButton.new()
	for filter in [grade, role]:
		filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter.custom_minimum_size.y = 56
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
	var detail := _panel(page)
	var header := HBoxContainer.new()
	detail.add_child(header)
	var portrait := _image(header)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(column)
	var name_label := _label(column, "", 28)
	name_label.add_theme_color_override("font_color", Color("f0cb68"))
	var identity := _label(column, "")
	var description := _label(detail, "")
	var stats := _label(detail, "")
	var actions := VBoxContainer.new()
	detail.add_child(actions)
	var art_buttons := {}
	if transcendent:
		for pair in [["illustration", "일러스트 보기"], ["banner", "배너 보기"], ["plus_banner", "5초월 배너 보기"]]:
			art_buttons[pair[0]] = _button(actions, pair[1], preview.bind(category, pair[0]))
	var extra := VBoxContainer.new()
	extra.add_theme_constant_override("separation", 16)
	var toggle := _button(detail, "기술 · 강화 효과 펼치기", _toggle.bind(extra))
	detail.add_child(extra)
	extra.hide()
	var trans_view: RefCounted
	if transcendent:
		trans_view = preload("res://src/ui/transcendent_monster_detail_view.gd").new()
		trans_view.install(extra)
	var count := _label(page, "")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	page.add_child(grid)
	var cards := {}
	for id in ids:
		var button := _button(grid, "", _select_card.bind(category, id))
		button.custom_minimum_size.y = 206
		var card := VBoxContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card)
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 18
		card.offset_right = -18
		card.offset_top = 12
		card.offset_bottom = -12
		_image(card, 100).texture = _texture(DATA.MONSTERS.get_ui_icon_path(id))
		_label(card, DATA.MONSTERS.get_monster_name(id), 24).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label(card, DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id)), 20).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cards[id] = button
	monster_pages[category] = {"selected": ids[0], "ids": ids, "cards": cards, "grid": grid, "search": search, "grade": grade, "role": role, "grades": grades, "roles": roles, "count": count, "portrait": portrait, "name": name_label, "identity": identity, "description": description, "stats": stats, "extra": extra, "toggle": toggle, "trans_view": trans_view, "art_buttons": art_buttons, "detail_cache": {}}
	search.text_changed.connect(func(_text): filter_monsters(category))
	grade.item_selected.connect(func(_index): filter_monsters(category))
	role.item_selected.connect(func(_index): filter_monsters(category))
	filter_monsters(category)

func _toggle(extra: Control) -> void:
	extra.visible = not extra.visible
	for page in monster_pages.values():
		if page.extra == extra: page.toggle.text = "기술 · 강화 효과 접기" if extra.visible else "기술 · 강화 효과 펼치기"

func filter_monsters(category: String) -> void:
	var page: Dictionary = monster_pages[category]
	var query: String = page.search.text.strip_edges().to_lower()
	var count := 0
	for id in page.ids:
		var grade := DATA.rarity_label(id)
		var role := DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id))
		var species := DATA.MONSTERS.get_species_label(DATA.MONSTERS.get_species(id))
		var text := (DATA.MONSTERS.get_monster_name(id) + " " + role + " " + species).to_lower()
		var matches: bool = (query.is_empty() or text.contains(query)) and (page.grade.selected == 0 or grade == page.grades[page.grade.selected]) and (page.role.selected == 0 or role == page.roles[page.role.selected])
		page.cards[id].visible = matches
		if matches: count += 1
	page.count.text = "%d / %d종 · 카드를 눌러 상세 보기" % [count, page.ids.size()] if count > 0 else "검색 결과가 없습니다."

func select_monster(category: String, id: String) -> void:
	if not monster_pages.has(category): return
	var page: Dictionary = monster_pages[category]
	if not page.cards.has(id): return
	page.selected = id
	var monster := DATA.MONSTERS.get_monster(id)
	page.name.text = monster.name
	var state := COLLECTION.load_state()
	var owned := COLLECTION.is_unlocked(id, state)
	page.identity.text = "%s · %s · %s\n%s" % [DATA.rarity_label(id), DATA.MONSTERS.get_species_label(DATA.MONSTERS.get_species(id)), DATA.MONSTERS.get_role_label(DATA.MONSTERS.get_role(id)), "획득" if owned else "미획득 · 도감 미리보기"]
	page.description.text = String(monster.get("collection_card", {}).get("identity", "")) if category == "transcendent" else String(monster.get("description", ""))
	page.identity.text += "\n" + DATA.MONSTERS.get_attack_type_label(DATA.MONSTERS.get_attack_type(id))
	page.portrait.texture = _texture(DATA.MONSTERS.get_ui_icon_path(id))
	page.stats.text = "기본 능력 (연구·증강 적용 전)\n" + DATA.stats(id)
	if category == "transcendent":
		page.trans_view.present(id)
		for kind in page.art_buttons:
			var path := DATA.artwork(id, kind)
			page.art_buttons[kind].disabled = path.is_empty() or not ResourceLoader.exists(path)
			page.art_buttons[kind].tooltip_text = "보상 미리보기 · 장착/해금되지 않습니다." if not page.art_buttons[kind].disabled else "등록된 리소스가 없습니다."
	else:
		if not page.detail_cache.has(id):
			var content := VBoxContainer.new()
			content.add_theme_constant_override("separation", 16)
			page.extra.add_child(content)
			page.detail_cache[id] = content
			var skills := DATA.MONSTERS.get_elite_skills(id)
			_label(content, "엘리트 기술", 26)
			var elite_art := _texture(DATA.elite_portrait(id))
			if elite_art != null and bool(monster.get("can_be_elite", true)):
				_image(content, 116).texture = elite_art
			if not bool(monster.get("can_be_elite",true)):
				_label(content, "엘리트 변형이 없는 몬스터입니다.")
			elif skills.is_empty(): _label(content, "등록된 엘리트 기술이 없습니다.")
			for skill in skills:
				var text := String(skill.get("description", ""))
				if skill.has("cooldown"): text += "\n재사용 %s초" % str(skill.cooldown)
				_skill(content, "elite", id, String(skill.get("id", skill.name)), skill.name, text)
			_label(content, "몬스터 전용 증강", 26)
			for entry in DATA.related_augments(id):
				_label(content, String(entry.name) + "\n" + String(entry.description) + "\n최대 %d레벨" % int(entry.get("max_stack", 1)))
		for key in page.detail_cache: page.detail_cache[key].visible = key == id
	for key in page.cards:
		page.cards[key].modulate = Color.WHITE if key == id else Color("b9aac5")

func _select_card(category: String, id: String) -> void:
	select_monster(category, id)
	scroll.scroll_vertical = 0

func _resize() -> void:
	tabs.columns = 4 if root.size.x >= 880 else 2
	for page in monster_pages.values():
		page.grid.columns = 3 if root.size.x >= 960 else (2 if root.size.x >= 460 else 1)
	if popup.visible:
		var extent := root.get_viewport_rect().size * 0.85
		preview_image.custom_minimum_size.y = maxf(100, extent.y - 200)
		popup.size = Vector2i(extent)

func _build_preview() -> void:
	popup = PopupPanel.new()
	popup.name = "CodexArtworkPreview"
	popup.add_theme_stylebox_override("panel", FRAMES.style("shop_featured_frame", 18))
	root.add_child(popup)
	var column := VBoxContainer.new()
	popup.add_child(column)
	preview_title = _label(column, "", 26)
	preview_image = _image(column, 0)
	preview_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_note = _label(column, "보상 미리보기 · 해금/장착되지 않습니다.", 20)
	_button(column, "닫기", popup.hide)

func preview(category: String, kind: String) -> void:
	var id: String = monster_pages[category].selected
	var path := DATA.artwork(id, kind)
	var image := _texture(path)
	if image == null: return
	preview_title.text = DATA.MONSTERS.get_monster_name(id) + (" · 5초월 배너" if kind == "plus_banner" else (" · 일러스트" if kind == "illustration" else " · 배너"))
	preview_image.texture = image
	var extent := root.get_viewport_rect().size * 0.85
	preview_image.custom_minimum_size.y = maxf(100, extent.y - 200)
	popup.popup_centered(Vector2i(extent))
