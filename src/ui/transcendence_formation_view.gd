extends RefCounted
const DATA := preload("res://src/data/transcendence_catalog.gd")
const STORE := preload("res://src/systems/transcendence_loadout_store.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var lobby: Control
var layout: VBoxContainer
var tab: Button
var content: VBoxContainer
var registered_area: ScrollContainer
var registered: VBoxContainer
var grid: GridContainer
var heading: Label
var empty: Label
var descending := true
var collection_state: Dictionary = {}
var feedback: Node2D
var _frame_texture: Texture2D
const DRAG_CARD := preload("res://src/ui/formation_drag_card.gd")
const DROP_AREA := preload("res://src/ui/transcendence_drop_area.gd")
const COSMETICS := preload("res://src/data/profile_cosmetic_catalog.gd")
const BANNER_SHADER := preload("res://src/ui/transcendence_banner.gdshader")
const EMERALD := Color("61e887")

func panel(parent: Control, gold: bool = false, rarity: String = "", draggable: bool = false) -> VBoxContainer:
	var frame: PanelContainer = DRAG_CARD.new() if draggable else PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	var style = lobby._team_formation_view.panel_style(gold)
	style.set_corner_radius_all(0)
	if not rarity.is_empty():
		style = lobby._team_formation_view.rarity_card_style(rarity, style)
	if rarity == "transcendent":
		style.set_border_width_all(0)
		style.shadow_size = 0
	frame.add_theme_stylebox_override("panel",style)
	parent.add_child(frame)
	if rarity == "transcendent":
		_add_frame(frame)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 2
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,24 if rarity == "transcendent" else 16)
	frame.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)
	return box

func label(parent: Control, text: String, size: int = 24) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",size)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_color_override("font_color",Color("f1eafa"))
	parent.add_child(result)
	return result

func button(parent: Control, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 64
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	lobby._apply_lobby_button_skin(result,false,22)
	lobby._team_formation_view.fit_action(result)
	result.pressed.connect(action)
	return result

func _add_frame(parent: Control) -> void:
	if _frame_texture == null:
		_frame_texture = load("res://assets/art/UI/clean_frames/transcendent_card_frame.png") as Texture2D
	if _frame_texture == null:
		return
	var border := NinePatchRect.new()
	border.name = "TranscendentFrame"
	border.z_index = 1
	border.texture = _frame_texture
	border.draw_center = false
	border.patch_margin_left = 32
	border.patch_margin_top = 32
	border.patch_margin_right = 32
	border.patch_margin_bottom = 32
	border.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(border)

func install(host: Control) -> void:
	lobby = host
	layout = host.get_node(host.TEAM_FORMATION_VIEW.PATH)
	tab = button(layout.get_node("ModeTabs"),"초월 등록",host._show_formation_mode.bind("transcendence"))
	content = VBoxContainer.new()
	content.name = "TranscendenceContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",16)
	layout.add_child(content)
	layout.move_child(content,layout.get_node("ModeTabs").get_index()+1)
	# Replace the slot contents inside the shared equipped area, keeping the
	# guide, summary and mode tabs at the same positions in every mode.
	var equipped := layout.get_node("EquippedArea/Margin/Content") as VBoxContainer
	heading = equipped.get_node("EquippedHeading") as Label
	# The viewport reserves the ordinary slot height regardless of child minimums.
	registered_area = DROP_AREA.new()
	registered_area.accepts_monster = _can_register
	registered_area.monster_dropped.connect(_register)
	registered_area.name = "TranscendenceRegisteredArea"
	registered_area.custom_minimum_size.y = 244.0
	registered_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	registered_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	registered_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	equipped.add_child(registered_area)
	registered = VBoxContainer.new()
	registered.name = "TranscendenceRegistered"
	registered.custom_minimum_size.y = 244.0
	registered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	registered.alignment = BoxContainer.ALIGNMENT_CENTER
	registered.add_theme_constant_override("separation",16)
	registered_area.add_child(registered)
	registered_area.hide()
	var guide := panel(content)
	label(guide,"일반 편성과 별도로 1종 등록 · 조건 달성 후 전투당 1회 소환",22)
	label(guide,"조각 1개당 초월 · 최대 Lv.5 · 초과 조각은 연구 1,000 P",22)
	var header := HBoxContainer.new()
	content.add_child(header)
	label(header,"◇  초월 몬스터 목록",26).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(header,"레벨 높은순 ▾",_toggle_sort).name = "LevelSort"
	empty = label(content,"초월 몬스터가 아직 추가되지 않았습니다.\n새 초월 몬스터가 추가되면 이 목록에 표시됩니다.",25)
	var scroll := ScrollContainer.new()
	scroll.name = "TranscendenceScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 14
	# Reserve space inside the outer gold panel before clipping the list.
	var inset := MarginContainer.new()
	inset.name = "TranscendenceListInset"
	inset.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override("margin_left", 12)
	inset.add_theme_constant_override("margin_right", 12)
	inset.add_theme_constant_override("margin_top", 8)
	inset.add_theme_constant_override("margin_bottom", 36)
	content.add_child(inset)
	inset.add_child(scroll)
	scroll.clip_contents = true
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	content.hide()

func refresh(showing: bool) -> void:
	if is_instance_valid(feedback):
		feedback.stop()
		feedback.reparent(lobby, false)
	content.visible = showing
	lobby._apply_lobby_button_skin(tab,showing,22)
	tab.add_theme_stylebox_override("disabled",lobby.PIXEL_PANEL_SKIN.button_style(lobby.primary_button_style))
	tab.add_theme_color_override("font_disabled_color",Color("fff0d2"))
	tab.disabled = showing
	registered_area.visible = showing
	layout.get_node("EquippedArea/Margin/Content/SlotRow").visible = not showing
	for name in ["ListHeader","UnlockFilters","MonsterScroll","Status"]:
		layout.get_node(name).visible = not showing
	if showing:
		layout.get_node("EmptyCollection").hide()
	else:
		return
	collection_state = COLLECTION.load_state()
	for child in registered.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	for child in grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var selected := STORE.load_id()
	heading.text = "◇  등록된 초월 몬스터  %d / 1  ◇" % (0 if selected.is_empty() else 1)
	if selected.is_empty():
		label(registered,"등록된 초월몬스터가 없습니다",28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label(registered,"아래 카드를 꾹 눌러 이곳에 놓거나 등록하기를 누르세요.",22).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_build_card(panel(registered,false,"transcendent",true),selected,selected,true)
	var state := collection_state
	var ids := DATA.get_ids()
	ids.sort_custom(func(a,b):
		var left := COLLECTION.get_upgrade_level(a,state)
		var right := COLLECTION.get_upgrade_level(b,state)
		return a < b if left == right else (left > right if descending else left < right))
	empty.visible = ids.is_empty()
	for id in ids:
		_build_card(panel(grid,false,"transcendent",true),String(id),selected,false)

func _build_card(box: VBoxContainer, id: String, selected: String, registered_card: bool) -> void:
	var state := collection_state
	var data: Dictionary = lobby.MONSTER_CATALOG.get_monster(id)
	var copy: Dictionary = data.get("collection_card", {})
	var unlocked := COLLECTION.is_unlocked(id, state)
	var chosen := id == selected
	var level := COLLECTION.get_upgrade_level(id, state)
	var frame := box.get_parent().get_parent() as Control
	frame.set_meta("monster_id", id)
	frame.tapped.connect(lobby._open_monster_detail.bind(id))
	frame.configure_drag("transcendence", id, lobby.MONSTER_CATALOG.get_monster_name(id), lobby._team_monster_card_icon(id))
	frame.drag_enabled = not registered_card and _can_register(id)
	var margin := box.get_parent() as MarginContainer
	if registered_card:
		margin.add_theme_constant_override("margin_left", 36)
		margin.add_theme_constant_override("margin_top", 22)
		margin.add_theme_constant_override("margin_bottom", 26)
		box.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "MonsterPortrait"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(124, 124) if registered_card else Vector2(148, 148)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.texture = lobby._team_monster_card_icon(id)
	row.add_child(portrait)
	if registered_card and _add_banner(frame, id):
		portrait.hide()
		# Reserve the right half for the portrait; no overlapping text/buttons.
		margin.add_theme_constant_override("margin_right", 360)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	row.add_child(details)
	var grade := label(details, "초월  ·  Lv.%d / 5" % level, 22)
	grade.name = "RarityLabel"
	grade.add_theme_color_override("font_color", EMERALD)
	var title := label(details, lobby.MONSTER_CATALOG.get_monster_name(id), 32)
	title.name = "MonsterName"
	label(details, lobby.MONSTER_CATALOG.get_species_label(lobby.MONSTER_CATALOG.get_species(id)), 21)
	label(details, String(copy.get("style_label", lobby._team_monster_role_label(id))), 22).add_theme_color_override("font_color", Color("e2c786"))
	if not registered_card:
		var identity := label(box, String(copy.get("identity", "초월 몬스터")), 24)
		identity.name = "Identity"
		label(box, String(copy.get("feature", "전투당 한 번 소환하는 특수 몬스터")), 22).add_theme_color_override("font_color", Color("d4ccde"))
		var stats: Dictionary = data.get("base_stats", {})
		label(box, "기본 공격 %d  ·  체력 %d" % [int(stats.get("attack_damage", 0)), int(stats.get("max_hp", 0))], 23)
		var divider := HSeparator.new()
		box.add_child(divider)
		label(box, "전투 소환 조건", 22).add_theme_color_override("font_color", EMERALD)
		label(box, DATA.describe(id).replace(" 및 ", "\n+ ") + "\n조건 달성 후 무료 · 전투당 1회", 21)
		var maxed := COLLECTION.is_maxed(id, state)
		var can_upgrade: bool = unlocked and not maxed and COLLECTION.get_shards(id, state) >= lobby.MONSTER_CATALOG.get_shards_required(id)
		var progress := HBoxContainer.new()
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(progress)
		var shards := label(progress, "조각 %d / %d" % [COLLECTION.get_shards(id, state), lobby.MONSTER_CATALOG.get_shards_required(id)], 22)
		shards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var badge := label(progress, "최대 초월" if maxed else "초월 가능" if can_upgrade else "등록 중" if chosen else "미획득" if not unlocked else "", 21)
		badge.name = "UpgradeBadge"
		badge.add_theme_color_override("font_color", EMERALD)
		badge.custom_minimum_size = Vector2(128, 28)
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var register_button := button(actions, "등록 해제" if chosen else "등록하기", _register.bind("" if chosen else id))
	register_button.name = "RegisterButton"
	register_button.disabled = not unlocked or (not chosen and DATA.MONSTERS.get_scene(id) == null)
	if registered_card:
		register_button.custom_minimum_size.y = 48
	else:
		var maxed := COLLECTION.is_maxed(id, state)
		var action := button(box, "최대 초월 완료" if maxed else "초월  ·  조각 1개", _upgrade.bind(id))
		action.name = "TranscendButton"
		action.disabled = not unlocked or maxed or COLLECTION.get_shards(id, state) < lobby.MONSTER_CATALOG.get_shards_required(id)
		action.tooltip_text = "최대 Lv.5 · 초월 조각 1개 · 초과 조각 1개당 연구 1,000 P"
	if not unlocked:
		portrait.self_modulate = Color(0.45, 0.45, 0.45, 1)
		# The identity and summon rule stay readable even before acquisition.

func _add_banner(frame: Control, id: String) -> bool:
	var path := COSMETICS.path(id, "banner")
	if path.is_empty():
		return false
	var texture: Texture2D = lobby.get_node("/root/PresentationWarmup").get_texture(path)
	if texture == null:
		texture = load(path) as Texture2D
	if texture == null:
		return false
	var background := Control.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(background)
	var art := TextureRect.new()
	art.name = "ProfileBanner"
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 16
	art.offset_top = 16
	art.offset_right = -16
	art.offset_bottom = -16
	var shader_material := ShaderMaterial.new()
	shader_material.shader = BANNER_SHADER
	art.material = shader_material
	art.resized.connect(func():
		if art.size.x > 0:
			shader_material.set_shader_parameter("crop_height", clampf(art.size.y / art.size.x * texture.get_width() / texture.get_height(), 0.01, 0.90)))
	return true

func _can_register(id: String) -> bool:
	return id in DATA.get_ids() and COLLECTION.is_unlocked(id, collection_state) and DATA.MONSTERS.get_scene(id) != null

func _register(id: String) -> void:
	if STORE.save_id(id):
		lobby.get_node("/root/GameAudio").feedback("formation")
		refresh(true)
	else:
		lobby.team_status_label.text = "초월 등록을 저장하지 못했습니다. 다시 시도해 주세요."
		lobby.team_status_label.show()

func _upgrade(id: String) -> void:
	var result: Dictionary = lobby._upgrade_team_monster(id)
	refresh(true)
	lobby.team_status_label.show()
	if not bool(result.get("success", false)):
		return
	for card in grid.get_children():
		if card.get_meta("monster_id", "") != id:
			continue
		if not is_instance_valid(feedback):
			feedback = lobby.MONSTER_UPGRADE_FEEDBACK.new()
			card.add_child(feedback)
		else:
			feedback.reparent(card, false)
		feedback.restart(int(result.get("level", 0)), true)
		return

func _toggle_sort() -> void:
	descending = not descending
	content.get_node("HBoxContainer/LevelSort").text = "레벨 높은순 ▾" if descending else "레벨 낮은순 ▴"
	refresh(true)
