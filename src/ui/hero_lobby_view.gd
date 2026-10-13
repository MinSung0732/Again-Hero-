extends RefCounted
const STORE := preload("res://src/systems/hero_mode_store.gd")
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const ART := "res://assets/art/UI/hero_mode/hero_guild_lobby.png"
var lobby
var active := false
var panels: Dictionary = {}
var bodies: Dictionary = {}
var original_visibility: Dictionary = {}
var original_nav_text: Dictionary = {}
var original_team_disabled := false
var original_team_icon: Texture2D
var original_background: Texture2D
var original_background_modulate := Color.WHITE
var original_dim := Color.WHITE
var hero_background: Texture2D
var message := ""
var hero_cards: Dictionary = {}
var selected_hero_panel: PanelContainer
var hero_roster_panel: PanelContainer
var selected_hero_label: Label

func install(host) -> void:
	lobby = host
	original_team_disabled = lobby.team_button.disabled
	var icon := lobby.team_button.get_node_or_null("NavIcon") as TextureRect
	if icon != null: original_team_icon = icon.texture
	for button in [lobby.shop_button,lobby.team_button,lobby.research_button]: original_nav_text[button] = button.text
	var backdrop := lobby.get_node_or_null("LobbyBackground") as TextureRect
	if backdrop != null: original_background = backdrop.texture; original_background_modulate = backdrop.modulate
	original_dim = lobby.get_node("Background").color
	for pair in [["shop",lobby.shop_tab],["team",lobby.team_tab],["research",lobby.research_tab]]:
		var root: Control = pair[1]
		for child in root.get_children():
			if child is CanvasItem: original_visibility[child] = child.visible
		var panel := PanelContainer.new(); panel.name = "HeroContent"; root.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 40; panel.offset_right = -40; panel.offset_top = 20; panel.offset_bottom = -20
		_skin(panel)
		var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",16)
		if pair[0] == "team": panel.add_child(body)
		else:
			var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll); scroll.add_child(body)
		panels[pair[0]] = panel; bodies[pair[0]] = body; panel.hide()

func set_active(enabled: bool) -> void:
	lobby.team_button.disabled = false if enabled else original_team_disabled
	if active == enabled: return
	active = enabled
	lobby.title_label.text = "용사 원정대" if enabled else "용사, 또 너야?"
	for child in original_visibility:
		if is_instance_valid(child): child.visible = false if enabled else original_visibility[child]
	for panel in panels.values(): panel.visible = enabled
	for button in original_nav_text: button.text = original_nav_text[button]
	if enabled:
		lobby.shop_button.text = "용사상점"; lobby.team_button.text = "캐릭터 편성"; lobby.research_button.text = "성장"
	var icon := lobby.team_button.get_node_or_null("NavIcon") as TextureRect
	if icon != null: icon.texture = lobby.main_modes_view.icons.get("hero",original_team_icon) if enabled else original_team_icon
	lobby.team_button.tooltip_text = "플레이할 용사를 편성하세요." if enabled else ""
	for pair in [[lobby.shop_button,"shop"],[lobby.team_button,"team"],[lobby.main_button,"main"],[lobby.research_button,"research"],[lobby.other_button,"other"]]: lobby._refresh_nav_button(pair[0],lobby.current_tab == pair[1])
	var backdrop := lobby.get_node_or_null("LobbyBackground") as TextureRect
	if enabled and hero_background == null: hero_background = lobby._load_png_texture_direct(ART)
	if backdrop != null:
		backdrop.texture = hero_background if enabled and hero_background != null else original_background
		backdrop.modulate = Color.WHITE if enabled else original_background_modulate
	lobby.get_node("Background").color = Color(0.02,0.08,0.13,0.45) if enabled else original_dim
	if enabled: rebuild(lobby.current_tab)

func _skin(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.045,0.13,0.19,0.94); style.border_color = Color("7bacba"); style.set_border_width_all(2); style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",SKIN.skin_style(style))
func _label(body: Node,text: String,size_px: int = 26) -> Label:
	var result := Label.new(); result.text = text; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size",size_px); result.add_theme_color_override("font_color",Color("e8e4cb")); body.add_child(result); return result
func _button(body: Node,text: String,callback: Callable,selected: bool = false) -> Button:
	var result := Button.new(); result.text = text; result.custom_minimum_size.y = 100; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",24)
	var style := StyleBoxFlat.new(); style.bg_color = Color("24556b") if selected else Color("162f42"); style.border_color = Color("edcf7b") if selected else Color("608b9b"); style.set_border_width_all(2); style.set_content_margin_all(14)
	for state in ["normal","hover","pressed","disabled"]: result.add_theme_stylebox_override(state,SKIN.skin_style(style))
	body.add_child(result); result.pressed.connect(callback); return result
func _portrait(parent: Node,id: String,dimensions: Vector2) -> TextureRect:
	var result := TextureRect.new(); result.custom_minimum_size = dimensions; result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stage: Dictionary = STAGES.get_stage(CHARACTERS.stage_for_hero(id))
	var path := String(stage.get("portrait_path",""))
	var texture: Texture2D = lobby._portrait_texture_cache.get(path)
	if texture == null:
		texture = lobby._normalize_hero_portrait_texture(lobby._load_texture(path))
		if texture != null: lobby._portrait_texture_cache[path] = texture
	result.texture = texture; parent.add_child(result); return result

func rebuild(tab: String) -> void:
	if not active or not bodies.has(tab): return
	var body: VBoxContainer = bodies[tab]
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	var id := STORE.selected_hero()
	var character: Dictionary = CHARACTERS.get_character(id)
	if tab == "team": _build_formation(body,id); return
	if tab == "shop":
		_label(body,"용사상점",40); _label(body,"준비 중",32)
		_label(body,"캐릭터 편성에서 플레이할 용사를 선택하세요.\n용사별 전용 무기는 전투 중 레벨업으로 습득합니다.")
		return
	_label(body,"성장 · "+String(character.name),36)
	_label(body,"연구 포인트 %d\n편성한 용사의 성장 · 다음 도전부터 적용" % lobby.STAGE_PROGRESS.get_research_points(),24)
	if not message.is_empty(): _label(body,message,23)
	for growth_id in DATA.GROWTH:
		var level := STORE.growth_level(id,growth_id); var data: Dictionary = DATA.GROWTH[growth_id]
		var cost := DATA.growth_cost(growth_id,level)
		var text := "%s · %d / %d\n%s\n%s" % [data.name,level,int(data.max),data.description,"최대 성장" if level >= int(data.max) else "연구 포인트 %d" % cost]
		var button := _button(body,text,_grow.bind(id,String(growth_id)))
		button.disabled = level >= int(data.max) or cost > lobby.STAGE_PROGRESS.get_research_points()

func _build_formation(body: VBoxContainer,id: String) -> void:
	hero_cards.clear()
	_label(body,"캐릭터 편성",36)
	selected_hero_panel = PanelContainer.new(); selected_hero_panel.name = "SelectedHeroPanel"; selected_hero_panel.custom_minimum_size.y = 360; body.add_child(selected_hero_panel); _skin(selected_hero_panel)
	var top := HBoxContainer.new(); top.add_theme_constant_override("separation",18); selected_hero_panel.add_child(top)
	_portrait(top,id,Vector2(190,250))
	var details := VBoxContainer.new(); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL; details.add_theme_constant_override("separation",8); top.add_child(details)
	var character: Dictionary = CHARACTERS.get_character(id)
	selected_hero_label = _label(details,"편성 중 · "+String(character.name),30)
	_label(details,String(character.style),22)
	_label(details,"전용 무기 %d종 · 전투에서 최대 %d개 습득" % [WEAPONS.weapon_pool(id).size(),WEAPONS.WEAPON_SLOTS],22)
	var weapons := GridContainer.new(); weapons.columns = 2; weapons.add_theme_constant_override("h_separation",12); weapons.add_theme_constant_override("v_separation",8); details.add_child(weapons)
	for weapon_id in WEAPONS.weapon_pool(id):
		var data: Dictionary = WEAPONS.WEAPONS[weapon_id]
		var name := _label(weapons,String(data.name)+"\n"+String(data.effect),20); name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not message.is_empty(): _label(details,message,21)
	hero_roster_panel = PanelContainer.new(); hero_roster_panel.name = "HeroRosterPanel"; hero_roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(hero_roster_panel); _skin(hero_roster_panel)
	var bottom := VBoxContainer.new(); bottom.add_theme_constant_override("separation",10); hero_roster_panel.add_child(bottom)
	_label(bottom,"용사 목록 · 10종",28)
	_label(bottom,"로컬 테스트 · 모든 용사 선택 가능" if STORE.all_characters_unlocked_for_test() else "견습마도사 기본 개방 · 나머지는 해당 스테이지 어려움 클리어",20)
	var scroll := ScrollContainer.new(); scroll.name = "RosterScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; bottom.add_child(scroll)
	var grid := GridContainer.new(); grid.name = "HeroRosterGrid"; grid.columns = 3; grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); scroll.add_child(grid)
	for hero_id in CHARACTERS.ORDER:
		var data: Dictionary = CHARACTERS.get_character(hero_id)
		var unlocked := STORE.character_unlocked(hero_id)
		var card := _button(grid,"",_select_character.bind(hero_id),hero_id == id)
		card.custom_minimum_size = Vector2(210,250); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.disabled = not unlocked
		card.tooltip_text = String(data.style); hero_cards[hero_id] = card
		var rows := VBoxContainer.new(); card.add_child(rows); rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rows.offset_left = 12; rows.offset_right = -12; rows.offset_top = 12; rows.offset_bottom = -12; rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := _portrait(rows,hero_id,Vector2(128,132))
		portrait.self_modulate = Color.WHITE if unlocked else Color(0.35,0.35,0.40,1.0)
		var name := _label(rows,String(data.name),22); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var condition := "◆ 편성 중" if hero_id == id else "선택 가능" if unlocked else "잠김 · Stage %s\n어려움 클리어" % String(data.stage).trim_prefix("stage_")
		var state := _label(rows,condition,19); state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not unlocked:
			var lock := TextureRect.new(); lock.texture = lobby.main_modes_view.icons.get("lock"); lock.mouse_filter = Control.MOUSE_FILTER_IGNORE; portrait.add_child(lock); lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER); lock.offset_left = -20; lock.offset_right = 20; lock.offset_top = -20; lock.offset_bottom = 20; lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

func _select_character(id: String) -> void:
	if not STORE.character_unlocked(id): return
	if not STORE.select_hero(id): message = "편성을 저장하지 못했습니다. 다시 시도하세요."; rebuild("team"); return
	message = "캐릭터 편성 저장 완료"
	lobby._refresh_stage_card()
	rebuild("team")
func _grow(id: String,growth_id: String) -> void:
	message = "성장 완료 · 다음 도전부터 적용" if STORE.purchase_growth(id,growth_id) else "성장 저장 실패 또는 연구 포인트 부족"
	lobby._refresh_header(); rebuild("research")
