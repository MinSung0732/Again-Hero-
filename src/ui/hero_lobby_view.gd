extends RefCounted
const STORE := preload("res://src/systems/hero_mode_store.gd")
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const AUGMENTS := preload("res://src/data/hero_weapon_catalog.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
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
var subtab := "character"
var message := ""
func install(host) -> void:
	lobby = host
	original_team_disabled = lobby.team_button.disabled
	var team_icon := lobby.team_button.get_node_or_null("NavIcon") as TextureRect
	if team_icon != null: original_team_icon = team_icon.texture
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
		panel.offset_left = 55; panel.offset_right = -55; panel.offset_top = 25; panel.offset_bottom = -20
		var style := StyleBoxFlat.new(); style.bg_color = Color(0.045,0.13,0.19,0.94); style.border_color = Color("7bacba"); style.set_border_width_all(3); style.set_content_margin_all(28)
		panel.add_theme_stylebox_override("panel",SKIN.skin_style(style))
		var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll)
		var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",20); scroll.add_child(body)
		panels[pair[0]] = panel; bodies[pair[0]] = body; panel.hide()
func set_active(enabled: bool) -> void:
	# Refresh must reassert the lock even when the perspective did not change.
	lobby.team_button.disabled = enabled or original_team_disabled
	if enabled and lobby.current_tab == "team": lobby._switch_tab("main")
	if active == enabled: return
	active = enabled
	lobby.title_label.text = "용사 원정대" if enabled else "용사, 또 너야?"
	for child in original_visibility:
		if is_instance_valid(child): child.visible = false if enabled else original_visibility[child]
	for panel in panels.values(): panel.visible = enabled
	for button in original_nav_text:
		button.text = original_nav_text[button]
	if enabled:
		lobby.shop_button.text = "용사상점"; lobby.team_button.text = "팀편성 🔒"; lobby.research_button.text = "성장"
	var team_icon := lobby.team_button.get_node_or_null("NavIcon") as TextureRect
	if team_icon != null: team_icon.texture = lobby.main_modes_view.icons.get("lock",original_team_icon) if enabled else original_team_icon
	lobby.team_button.disabled = enabled or original_team_disabled
	lobby.team_button.tooltip_text = "용사 모드에서는 팀편성을 사용할 수 없습니다. 용사는 메인 화면에서 선택하세요." if enabled else ""
	for pair in [[lobby.shop_button,"shop"],[lobby.team_button,"team"],[lobby.main_button,"main"],[lobby.research_button,"research"],[lobby.other_button,"other"]]:
		lobby._refresh_nav_button(pair[0],lobby.current_tab == pair[1])
	var backdrop := lobby.get_node_or_null("LobbyBackground") as TextureRect
	if enabled and hero_background == null: hero_background = lobby._load_png_texture_direct(ART)
	if backdrop != null:
		backdrop.texture = hero_background if enabled and hero_background != null else original_background
		backdrop.modulate = Color.WHITE if enabled else original_background_modulate
	lobby.get_node("Background").color = Color(0.02,0.08,0.13,0.45) if enabled else original_dim
	if enabled: rebuild(lobby.current_tab)
func _label(body: Node,text: String,size_px: int = 26) -> Label:
	var result := Label.new(); result.text = text; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",size_px); result.add_theme_color_override("font_color",Color("e8e4cb")); body.add_child(result); return result
func _button(body: Node,text: String,callback: Callable,selected: bool = false) -> Button:
	var result := Button.new(); result.text = text; result.custom_minimum_size.y = 110; result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",25)
	var style := StyleBoxFlat.new(); style.bg_color = Color("24556b") if selected else Color("162f42"); style.border_color = Color("edcf7b") if selected else Color("608b9b"); style.set_border_width_all(2); style.set_content_margin_all(18)
	result.add_theme_stylebox_override("normal",SKIN.skin_style(style)); body.add_child(result); result.pressed.connect(callback); return result
func rebuild(tab: String) -> void:
	if not active or not bodies.has(tab): return
	var body: VBoxContainer = bodies[tab]
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	var stage := STORE.selected_stage(String(lobby.stage_ids[lobby.selected_stage_index]))
	# The host is dynamic; its method return cannot be inferred by Godot's compiler.
	var profile: Dictionary = PROFILES.get_profile(String(STAGES.get_stage(stage).get("hero_id","")))
	var name := String(profile.get("display_name","용사"))
	if tab == "shop":
		_label(body,"용사상점",40); _label(body,"준비 중",32)
		_label(body,"용사 전용 상품을 준비하고 있습니다.\n용사는 메인 화면에서 선택하고, 무기와 보조 증강은 전투 중 레벨업으로 습득합니다. 성장에서 능력을 강화할 수 있습니다.")
		return
	if tab == "team":
		_label(body,"용사 편성",40)
		var tabs := HBoxContainer.new(); body.add_child(tabs)
		for pair in [["character","캐릭 편성"],["skill","스킬 편성"]]:
			var id := String(pair[0]); _button(tabs,String(pair[1]),_set_subtab.bind(id),subtab == id).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(body,"선택 용사 · "+name,28)
		if not message.is_empty(): _label(body,message,23)
		if subtab == "character":
			for id in lobby.stage_ids:
				var data: Dictionary = lobby.STAGE_CATALOG.get_stage(id)
				if not lobby.STAGE_PROGRESS.is_stage_unlocked(int(data.number)): continue
				var hero: Dictionary = lobby.HERO_PROFILES.get_profile(String(data.hero_id))
				var card := _button(body,String(hero.get("display_name","용사"))+"\n15분 생존 / 이동·무기 선택 직접 / 무기 자동 공격",_select.bind(String(id)),id == stage)
				card.icon = lobby._load_texture(String(data.get("portrait_path","")))
				card.expand_icon = true; card.add_theme_constant_override("icon_max_width",85)
		else:
			var selected := STORE.skills(stage)
			_label(body,"시작 무기 · %d / %d\n기본 무기 + 편성 무기를 Lv.1에 습득합니다. 무기 3칸 · 보조 3칸 · 무기별 Lv.10 상자 진화." % [selected.size(),DATA.SKILL_SLOTS],24)
			for raw in STORE.skill_pool(stage):
				var id := String(raw); var skill := AUGMENTS.WEAPONS.get(id,{})
				_button(body,("✓ " if id in selected else "")+String(skill.get("name",id))+"\n"+AUGMENTS.description(id,1),_toggle_skill.bind(stage,id),id in selected)
		return
	_label(body,"성장 · "+name,40)
	_label(body,"연구 포인트 %d\n캐릭터별 성장 · 다음 용사 도전부터 적용" % lobby.STAGE_PROGRESS.get_research_points(),25)
	if not message.is_empty(): _label(body,message,23)
	for id in DATA.GROWTH:
		var level := STORE.growth_level(stage,id); var data: Dictionary = DATA.GROWTH[id]
		var cost := DATA.growth_cost(id,level)
		var text := "%s · %d / %d\n%s\n%s" % [data.name,level,int(data.max),data.description,"최대 성장" if level >= int(data.max) else "성장 비용 · 연구 포인트 %d" % cost]
		var button := _button(body,text,_grow.bind(stage,String(id)))
		button.disabled = level >= int(data.max) or cost > lobby.STAGE_PROGRESS.get_research_points()
func _select(id: String) -> void:
	message = "캐릭터 편성 저장 완료" if STORE.select_stage(id) else "편성을 저장하지 못했습니다. 다시 시도하세요."
	if message == "캐릭터 편성 저장 완료":
		lobby.selected_stage_index = maxi(lobby.stage_ids.find(id),0)
		lobby._refresh_stage_card()
	rebuild("team")
func _set_subtab(id: String) -> void:
	subtab = id
	message = ""
	rebuild("team")
func _toggle_skill(stage: String,id: String) -> void:
	var selected := STORE.skills(stage)
	if id in selected: selected.erase(id)
	elif selected.size() < DATA.SKILL_SLOTS: selected.append(id)
	else: message = "시작 무기는 2개까지 편성할 수 있습니다. 기존 스킬을 먼저 해제하세요."; rebuild("team"); return
	message = "스킬 편성 저장 완료" if STORE.set_skills(stage,selected) else "편성을 저장하지 못했습니다. 선택한 무기를 확인하세요."
	rebuild("team")
func _grow(stage: String,id: String) -> void:
	message = "성장 완료 · 다음 도전부터 적용" if STORE.purchase_growth(stage,id) else "성장 저장 실패 또는 연구 포인트 부족"
	lobby._refresh_header(); rebuild("research")
