extends Control
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const STAMINA_NOTICE := preload("res://src/ui/stamina_notice.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const BATTLE_SCENE := preload("res://src/battle/Battle.tscn")
const MOVE_PAD := preload("res://src/hero_mode/hero_move_pad.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
const SETTINGS := preload("res://src/ui/BattleSettings.tscn")
const HUD := preload("res://src/ui/hero_survival_hud.gd")
const REEL := preload("res://src/ui/hero_chest_reel.gd")
const LOADING := preload("res://src/ui/startup_loading_view.gd")
const RESULT_VIEW := preload("res://src/ui/hero_result_view.gd")
const PAUSE_VIEW := preload("res://src/ui/hero_pause_view.gd")
const INVENTORY_DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
var inventory_dim: ColorRect
var overlay_default_style: StyleBox
signal presentation_prepared
signal entry_started
var presentation_ready := false
var presentation_preparing := false
var entry_ready := false
var settings_panel: Control
var battle_frame: Control
var battle_frame_enabled := true
var pad_mode := MOVE_PAD.MODE_FIXED
var pad_mode_selector: OptionButton
var gameplay_settings_path := "user://gameplay_settings.cfg"
var battle
var director
var pad
var status: Label
var hp: ProgressBar
var xp: ProgressBar
var timer: Label
var hero_title: Label
var kills_label: Label
var population_label: Label
var stats_panel: PanelContainer
var passive_buttons: Array[Button] = []
var overlay: PanelContainer
var overlay_rows: VBoxContainer
var choice_generation := 0
var choosing := false
var paused := false
var run_abandoned := false
var run_chest_gold := 0
var chest_gold_saved := false
var settled := false
var leaving := false
var entry: Dictionary = {}
var stage := "stage_1"
var player_hero_id := "ranged_rookie"
var initial_owner := ""
var account_invalid := false
var hud_remaining := 0.0
var entry_started_ms := -1
var entry_started_unix := 0.0
var weapon_buttons: Array[Button] = []
var rolling := false
var pending_chests := 0
var opening_chest_claimed := false
var roulette_tween: Tween
var roulette_details: VBoxContainer
var roulette_continue: Button
var roulette_label: Label
var roulette_reel: Control
var roulette_pool: Array = []
var roulette_receipt: Dictionary = {}
var roulette_index := -1
var finished_won := false
var result_reward: Dictionary = {}
var finished_message := ""
var run_difficulty := "easy"
func _ready() -> void:
	set_process(false)
	GameAudio.enter_frontend(self,"lobby")
	stage = STORE.selected_battle_stage()
	initial_owner = STORE.owner()
	var options: Dictionary = SceneTransition.consume_entry_options()
	stage = String(options.get("stage_id",stage))
	player_hero_id = String(options.get("hero_id",STORE.selected_hero()))
	run_difficulty = String(options.get("difficulty",STORE.difficulty()))
	_build_ui()
	if not STORE.character_unlocked(player_hero_id) or not STORE.can_enter(stage,run_difficulty):
		var original_ticket: Dictionary = options.get("hero_entry",{})
		var refunded := original_ticket.is_empty() or STAMINA.refund_failed_entry(original_ticket)
		_show_blocked("마왕 쉬움 10스테이지 또는 해당 용사 스테이지 쉬움 클리어를 확인하세요." if refunded else "잠긴 입장 실패 · 스테미너 반환 저장을 확인하세요.")
		return
	entry = STAMINA.claim_battle_entry(stage)
	if entry.is_empty():
		var original_entry: Dictionary = options.get("hero_entry",{})
		var refunded := original_entry.is_empty() or STAMINA.refund_failed_entry(original_entry)
		_show_blocked("입장 기록을 확인하지 못했습니다. 로비에서 다시 입장하세요." if refunded else "입장 실패 · 스테미너 반환 저장도 실패했습니다. 로비에서 저장 상태를 확인하세요.")
		return
	pad.enabled = false
	call_deferred("_begin_prepared_entry")

func prepare_presentation() -> void:
	if presentation_ready or entry.is_empty(): return
	if presentation_preparing:
		await presentation_prepared
		return
	presentation_preparing = true
	await PresentationWarmup.prepare_common()
	await PresentationWarmup.prepare_scene("res://src/hero_mode/HeroMode.tscn", {"hero_id":player_hero_id,"stage_id":stage})
	if not is_inside_tree(): return
	_create_battle()
	await battle.prepare_spawn_resources()
	# Layout/animation frame preparation stays under the loading overlay.
	await get_tree().process_frame
	if not is_inside_tree(): return
	presentation_ready = true
	presentation_preparing = false
	presentation_prepared.emit()

func _begin_prepared_entry() -> void:
	var local_loading: CanvasLayer
	if SceneTransition.is_transitioning():
		await SceneTransition.transition_completed
	else:
		# Editor/direct-scene entry has the same loading gate as lobby entry.
		local_loading = CanvasLayer.new(); local_loading.layer = 10000
		add_child(local_loading)
		var loading_view := LOADING.new(); local_loading.add_child(loading_view)
		loading_view.configure("던전 준비 중", "용사와 몬스터의 전투 리소스를 미리 준비합니다.")
		var update_progress := func(done: int, total: int): loading_view.set_progress(0.9*float(done)/maxi(total,1))
		PresentationWarmup.progress_changed.connect(update_progress)
		await get_tree().process_frame
		await prepare_presentation()
		PresentationWarmup.progress_changed.disconnect(update_progress)
		loading_view.set_progress(1.0)
		local_loading.queue_free()
	if not is_inside_tree() or not presentation_ready or not is_instance_valid(battle): return
	entry_ready = true
	entry_started_ms = Time.get_ticks_msec(); entry_started_unix = Time.get_unix_time_from_system()
	pad.enabled = true
	battle.set_external_pause(false)
	set_process(true)
	entry_started.emit()

func _create_battle() -> void:
	var view := SubViewportContainer.new()
	view.name = "BattleView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.offset_top = HUD.BATTLE_TOP; view.offset_bottom = 0
	view.stretch = true
	add_child(view); move_child(view,1)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080,1920-int(HUD.BATTLE_TOP))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	view.add_child(viewport)
	battle = BATTLE_SCENE.instantiate()
	battle.campaign_difficulty = run_difficulty
	battle.hero_player_mode = true; battle.hero_player_stage = stage; battle.hero_player_hero_id = player_hero_id
	pad.input_surface = view
	viewport.add_child(battle)
	battle.set_external_pause(true)
	_install_battle_settings()
	GameAudio.attach_battle(battle)
	$HeroBGMManager.start_hero_loop(player_hero_id)
	$HeroBGMManager.set_user_bgm_level(AudioSettings.bgm_level)
	$HeroBGMManager.set_user_bgm_muted(AudioSettings.bgm_muted)
	battle.hero.set_camera_view_locked(true)
	battle.hero.player_augment_requested.connect(_show_choices)
	battle.battle_finished.connect(_on_finished)
	battle.hero_chest_opened.connect(_queue_chest)
	director = DIRECTOR.new()
	director.install(battle)
	pad.movement_changed.connect(func(value: Vector2):
		if is_instance_valid(battle) and is_instance_valid(battle.hero): battle.hero.set_player_move_input(value))
	_refresh_hud()
func _build_ui() -> void:
	var background := ColorRect.new(); background.color = Color("101e2c")
	background.name = "HeroBackground"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	# HeroBGMManager is already a child: index 1 must stay above this backdrop.
	move_child(background,0)
	var header := PanelContainer.new(); header.name = "HeroHUD"; add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 20; header.offset_right = -20; header.offset_top = 16; header.offset_bottom = HUD.BATTLE_TOP-20
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("171b29"); frame.border_color = Color("c9a45e"); frame.set_border_width_all(3); frame.set_content_margin_all(12)
	header.add_theme_stylebox_override("panel",SKIN.skin_style(frame))
	var top := VBoxContainer.new(); top.add_theme_constant_override("separation",6); header.add_child(top)
	var summary := HBoxContainer.new(); summary.name = "HeroSummary"; summary.add_theme_constant_override("separation",14); top.add_child(summary)
	HUD.portrait(summary,player_hero_id)
	var vitals := VBoxContainer.new(); vitals.name = "HeroVitals"; vitals.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vitals.add_theme_constant_override("separation",6); summary.add_child(vitals)
	var title_row := HBoxContainer.new(); title_row.add_theme_constant_override("separation",12); vitals.add_child(title_row)
	hero_title = _label(title_row,"용사\nLv.1",30); hero_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; hero_title.add_theme_color_override("font_color",Color("f4f1e9"))
	timer = _label(title_row,"남은 시간\n15:00",26); timer.custom_minimum_size.x = 160
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer.add_theme_color_override("font_color",Color("add5ff"))
	var menu := Button.new(); menu.text = "설정"; menu.custom_minimum_size = Vector2(90,72); title_row.add_child(menu)
	menu.add_theme_font_size_override("font_size",26); _skin_action_button(menu); menu.pressed.connect(_pause)
	hp = HUD.bar(vitals,"HP",Color("29cf79"),40)
	xp = HUD.bar(vitals,"EXP",Color("6b9aef"),32)
	var situation := HBoxContainer.new(); situation.name = "BattleCounters"; situation.add_theme_constant_override("separation",10); vitals.add_child(situation)
	kills_label = HUD.counter(situation,"처치",Color("f6d68c"),HUD.ART.icon("damage"))
	population_label = HUD.counter(situation,"현재 적",Color("d8e6ff"),HUD.MONSTER_ICON)
	status = _label(situation,"전투 준비",23); status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; status.add_theme_color_override("font_color",Color("aab4c9"))
	status.autowrap_mode = TextServer.AUTOWRAP_OFF; status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; status.clip_text = true
	weapon_buttons = HUD.inventory_row(top,"무기",WEAPONS.WEAPON_SLOTS)
	for index in weapon_buttons.size(): weapon_buttons[index].pressed.connect(_show_weapon_info.bind(index))
	passive_buttons = HUD.inventory_row(top,"보조",WEAPONS.PASSIVE_SLOTS)
	for index in passive_buttons.size(): passive_buttons[index].pressed.connect(_show_passive_info.bind(index))
	stats_panel = preload("res://src/ui/hero_compact_stats.gd").new(); add_child(stats_panel)
	stats_panel.position = Vector2(HUD.FRAME_WIDTH+10,HUD.BATTLE_TOP+12)
	pad = MOVE_PAD.new(); pad.name = "MovePad"; add_child(pad)
	pad.set_mode(pad_mode)
	pad.input_exclusions.append(stats_panel)
	inventory_dim = ColorRect.new(); inventory_dim.name = "InventoryModalDim"; inventory_dim.color = Color(0,0,0,0.58)
	inventory_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); inventory_dim.mouse_filter = Control.MOUSE_FILTER_STOP; add_child(inventory_dim); inventory_dim.hide()
	overlay = PanelContainer.new(); add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 65; overlay.offset_right = -65; overlay.offset_top = 390; overlay.offset_bottom = -150
	var style := StyleBoxFlat.new(); style.bg_color = Color("122b3a"); style.border_color = Color("d9c77c"); style.set_border_width_all(3); style.set_content_margin_all(28)
	overlay_default_style = SKIN.skin_style(style)
	overlay.add_theme_stylebox_override("panel",overlay_default_style)
	overlay_rows = VBoxContainer.new(); overlay_rows.add_theme_constant_override("separation",22); overlay.add_child(overlay_rows)
	overlay.hide()
func _label(parent: Node,text: String,size_px: int) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px); label.add_theme_color_override("font_color",Color("e5ead4")); label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label); return label
func _button(text: String,action: Callable) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = 96; button.add_theme_font_size_override("font_size",25)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skin_action_button(button)
	overlay_rows.add_child(button); button.pressed.connect(action); return button
func _clear_overlay() -> void:
	if is_instance_valid(inventory_dim): inventory_dim.hide()
	if overlay_default_style != null: overlay.add_theme_stylebox_override("panel",overlay_default_style)
	overlay_rows.add_theme_constant_override("separation",22)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 65; overlay.offset_right = -65; overlay.offset_top = 390; overlay.offset_bottom = -150
	for child in overlay_rows.get_children(): overlay_rows.remove_child(child); child.queue_free()
	overlay.show(); overlay.move_to_front()
func _show_blocked(message: String) -> void:
	_clear_overlay(); _label(overlay_rows,message,30); _button("로비로",_leave)
func _process(delta: float) -> void:
	if not is_instance_valid(battle): return
	if STORE.owner() != initial_owner:
		account_invalid = true
		battle.set_external_pause(true); pad.enabled = false; pad.reset(); _show_blocked("계정이 변경되었습니다. 로비로 돌아가세요.")
		set_process(false); return
	if pending_chests > 0 and not paused and not choosing and not rolling and not battle.battle_over: _begin_roulette()
	if not paused and not choosing and not rolling and not battle.battle_over:
		if pad.touch_id < 0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
			battle.hero.set_player_move_input(direction.limit_length(1.0))
		director.tick(delta)
	hud_remaining -= delta
	if hud_remaining <= 0.0: hud_remaining = 0.25; _refresh_hud()
func _refresh_hud() -> void:
	if not is_instance_valid(battle) or not is_instance_valid(battle.hero): return
	var hero = battle.hero
	hp.max_value = hero.max_hp; hp.value = hero.current_hp
	hp.get_node("Caption").text = "체력 %d / %d" % [hero.current_hp,hero.max_hp]
	$HeroBGMManager.update_hero_hp(hero.current_hp,hero.max_hp)
	xp.max_value = hero.exp_to_next_level; xp.value = hero.current_exp
	xp.get_node("Caption").text = "경험치 %d / %d" % [hero.current_exp,hero.exp_to_next_level]
	hero_title.text = "%s\nLv.%d · Stage %d" % [String(battle.current_hero_profile.get("display_name","용사")),hero.level,int(battle.current_stage_data.get("number",1))]
	timer.text = "남은 시간\n%02d:%02d" % [int(battle.run_metrics.get_remaining_seconds())/60,int(battle.run_metrics.get_remaining_seconds())%60]
	kills_label.text = "처치 %d" % _kill_count()
	population_label.text = "현재 적 %d" % battle.active_monsters.size()
	status.text = "공세 · "+String(DATA.phase_at(battle.run_metrics.elapsed_seconds).name)
	if hero.player_weapons != null and hero.player_weapons.identity != null:
		status.text = "자원 · "+hero.player_weapons.identity.summary()
	if is_instance_valid(director.encounters):
		var objective := DATA.opening_objective(battle.run_metrics.elapsed_seconds,opening_chest_claimed,director.encounters.next_event)
		if not objective.is_empty(): timer.text = objective
		if director.encounters.finale:
			timer.text = "최종 보스\n격파 시 클리어"
			status.text = "보스 체력 %d / %d" % [director.encounters.boss.current_hp,director.encounters.boss.max_hp] if is_instance_valid(director.encounters.boss) else director.encounters.notice
		elif not director.encounters.notice.is_empty(): status.text = director.encounters.notice
	var hp_ratio := float(hero.current_hp)/maxf(1.0,hero.max_hp)
	hp.get_theme_stylebox("fill").bg_color = Color("ec6464") if hp_ratio <= 0.25 else Color("e4b84f") if hp_ratio <= 0.5 else Color("29cf79")
	if hero.player_weapons != null:
		var runtime = hero.player_weapons
		for index in weapon_buttons.size():
			var button: Button = weapon_buttons[index]
			if index >= runtime.weapon_ids.size():
				HUD.update_slot(button,null,"+","빈 무기 슬롯"); button.disabled = true; continue
			var id := String(runtime.weapon_ids[index]); button.disabled = false
			HUD.update_slot(button,ICONS.texture(id),"MAX" if runtime.evolved.has(id) else "Lv.%d" % int(runtime.levels[id]),WEAPONS.GROWTH.evolution_name(id) if runtime.evolved.has(id) else String(WEAPONS.WEAPONS[id].name))
		var index := 0
		for id in runtime.passives:
			var rank := int(runtime.passives[id])
			passive_buttons[index].disabled = false
			HUD.update_slot(passive_buttons[index],ICONS.texture(id),"MAX" if rank >= WEAPONS.passive_limit(id) else "Lv.%d" % rank,String(WEAPONS.PASSIVES[id].name)+"\n"+WEAPONS.description(id,rank))
			index += 1
		while index < passive_buttons.size():
			HUD.update_slot(passive_buttons[index],null,"+","빈 보조 슬롯"); passive_buttons[index].disabled = true; index += 1
		stats_panel.refresh(hero,runtime)

func _show_choices(candidates: Array) -> void:
	if battle.battle_over: return
	choosing = true; choice_generation += 1
	var revision := choice_generation
	battle.set_external_pause(true); pad.enabled = false; pad.reset()
	_clear_overlay()
	overlay.name = "HeroAugmentOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.offset_left = -480; overlay.offset_right = 480; overlay.offset_top = -365; overlay.offset_bottom = 365
	var title := _label(overlay_rows,"레벨업 · 증강을 선택하세요",32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slots := _label(overlay_rows,"무기 %d/%d · 보조 %d/%d · 선택 후 전투 재개" % [battle.hero.player_weapons.weapon_ids.size(),WEAPONS.WEAPON_SLOTS,battle.hero.player_weapons.passives.size(),WEAPONS.PASSIVE_SLOTS],20)
	slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var choices := HBoxContainer.new(); choices.name = "HorizontalAugmentCards"
	choices.add_theme_constant_override("separation",16); choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL; overlay_rows.add_child(choices)
	var buttons: Array[Button] = []
	for candidate in candidates:
		var id := String(candidate.get("id",""))
		var button := _choice_card(choices,candidate,_choose.bind(id,revision))
		button.disabled = true; buttons.append(button)
	var refresh := Button.new(); refresh.name = "AugmentReroll"
	refresh.text = "새로고침 · 남은 %d/%d회" % [battle.hero.player_weapons.rerolls_remaining(),battle.hero.player_weapons.reroll_limit]
	refresh.custom_minimum_size = Vector2(0,64); refresh.add_theme_font_size_override("font_size",26)
	_skin_action_button(refresh); overlay_rows.add_child(refresh)
	refresh.disabled = true; refresh.pressed.connect(_reroll_choices.bind(revision))
	await get_tree().create_timer(0.25).timeout
	if revision != choice_generation or not choosing or battle.battle_over: return
	for button in buttons:
		if is_instance_valid(button): button.disabled = false
	if is_instance_valid(refresh): refresh.disabled = battle.hero.player_weapons.rerolls_remaining() <= 0
func _choice_card(parent: HBoxContainer, candidate: Dictionary, action: Callable) -> Button:
	var id := String(candidate.get("id",""))
	var button := Button.new(); button.name = id; button.custom_minimum_size = Vector2(280,500)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_skin_action_button(button); parent.add_child(button); button.pressed.connect(action)
	var margin := MarginContainer.new(); margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	button.add_child(margin)
	var rows := VBoxContainer.new(); rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation",18); margin.add_child(rows)
	var icon := TextureRect.new(); icon.name = "AugmentIcon"; icon.texture = ICONS.texture(id)
	icon.custom_minimum_size = Vector2(120,120); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; rows.add_child(icon)
	var name_label := _label(rows,String(candidate.get("name",id)),26)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var description := _label(rows,String(candidate.get("description","")),22)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hint := _label(rows,"탭하여 선택",20); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

func _reroll_choices(revision: int) -> void:
	if not choosing or revision != choice_generation or battle.battle_over: return
	if not battle.hero.reroll_player_augment():
		var refresh := overlay_rows.get_node_or_null("AugmentReroll") as Button
		if refresh != null:
			refresh.disabled = true; refresh.text = "새로고침 불가 · 다른 후보 없음"
func _choose(id: String,revision: int) -> void:
	if not choosing or revision != choice_generation or battle.battle_over: return
	choosing = false; overlay.hide(); pad.reset()
	battle.set_external_pause(paused)
	if not battle.hero.choose_player_augment(id):
		_show_choices(battle.hero.player_augment_candidates); return
	pad.enabled = not choosing and not paused
func _pause() -> void:
	if not entry_ready or not is_instance_valid(battle) or battle.battle_over or choosing or rolling: return
	paused = true; battle.set_external_pause(true); pad.enabled = false; pad.reset()
	_clear_overlay()
	inventory_dim.show(); inventory_dim.move_to_front(); overlay.move_to_front()
	overlay.offset_left = maxf(24,(size.x-920)*0.5); overlay.offset_right = -overlay.offset_left
	overlay.offset_top = minf(HUD.BATTLE_TOP+12,size.y*0.24); overlay.offset_bottom = -24
	overlay.add_theme_stylebox_override("panel",INVENTORY_DETAIL.style(Color("171226"),Color("e3bc69"),24))
	var runtime = battle.hero.player_weapons
	var equipped: Array = runtime.weapon_ids.slice(0,4) if runtime != null else []
	PAUSE_VIEW.build(overlay_rows,{"seconds":battle.run_metrics.elapsed_seconds,"kills":_kill_count(),"level":battle.hero.level,"weapons":equipped,"chest_gold":run_chest_gold},{"resume":_resume,"restart":_restart_from_pause,"settings":_open_settings,"leave":_leave})

func _resume() -> void:
	if is_instance_valid(inventory_dim): inventory_dim.hide()
	if is_instance_valid(settings_panel): settings_panel.hide()
	paused = false; overlay.hide(); pad.reset(); pad.enabled = true
	battle.hero.set_camera_view_locked(true); battle.set_external_pause(false)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(battle):
		if choosing or rolling: pad.reset()
		else: _pause()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(settings_panel) and settings_panel.visible: settings_panel.hide()
		elif paused: _resume()
		else: _pause()
		get_viewport().set_input_as_handled()
func _kill_count() -> int:
	var total := 0
	for value in battle.run_metrics.monster_death_counts.values(): total += int(value)
	return total
func _on_finished(message: String,won: bool) -> void:
	if roulette_tween != null: roulette_tween.kill()
	rolling = false; pending_chests = 0; paused = false
	$HeroBGMManager.stop_bgm()
	GameAudio.battle_result(self,won)
	finished_message = message; finished_won = won; pad.enabled = false; pad.reset()
	choosing = false; choice_generation += 1
	_show_result()
func _show_result() -> void:
	_clear_overlay()
	inventory_dim.show(); inventory_dim.move_to_front(); overlay.move_to_front()
	overlay.offset_left = maxf(24,(size.x-920)*0.5); overlay.offset_right = -overlay.offset_left
	overlay.anchor_top = 0.5; overlay.anchor_bottom = 0.5
	var initial_half_height := minf(460,maxf(1,(size.y-48)*0.5))
	overlay.offset_top = -initial_half_height; overlay.offset_bottom = initial_half_height
	overlay.add_theme_stylebox_override("panel",INVENTORY_DETAIL.style(Color("171226"),Color("e3bc69") if finished_won else Color("d7828d"),24))
	if not settled:
		result_reward = STORE.award_run(stage,entry,battle.run_metrics.elapsed_seconds,_kill_count(),finished_won,run_difficulty,"abandon" if run_abandoned else "victory" if finished_won else "defeat",float(battle.hero.player_weapons.gold_bonus))
		settled = bool(result_reward.get("success",false))
	var equipped: Array = []
	var runtime = battle.hero.player_weapons
	if runtime != null:
		for id in runtime.weapon_ids:
			equipped.append({"id":id,"rank":"MAX" if runtime.evolved.has(id) else "Lv.%d" % int(runtime.levels.get(id,1))})
	var next_stage := String(STAGES.get_stage(stage).get("next_stage_id",""))
	var model := {"won":finished_won,"message":finished_message,"seconds":battle.run_metrics.elapsed_seconds,"kills":_kill_count(),"level":battle.hero.level,"weapons":equipped,"settled":settled,"research":int(result_reward.get("research",0)),"gold":int(result_reward.get("gold",0)),"chest_earned":int(result_reward.get("chest_earned",0)),"chest_paid":int(result_reward.get("chest_paid",0)),"chest_rate":float(result_reward.get("chest_rate",0)),"next_available":finished_won and STORE.can_enter(next_stage,run_difficulty)}
	RESULT_VIEW.build(overlay_rows,model,{"settle":_show_result,"next":_next_stage.bind(next_stage),"retry":_retry,"leave":_leave})

func _retry() -> void:
	if leaving or not settled or not STORE.can_enter(stage,run_difficulty): return
	var ticket := STAMINA.try_enter(stage,LocalTestMode.active,-1,false)
	if not bool(ticket.get("success",false)):
		_show_stamina_notice(STAMINA_NOTICE.INSUFFICIENT if ticket.get("reason") == "insufficient" else "저장을 완료하지 못했습니다. 다시 시도해 주세요."); return
	leaving = true
	if not SceneTransition.change_scene(DATA.SCENE,"용사 도전 준비 중...",{"stage_id":stage,"hero_id":player_hero_id,"hero_entry":ticket,"difficulty":run_difficulty}):
		STAMINA.refund_failed_entry(ticket); leaving = false
		_show_stamina_notice("입장 실패 · 스테미너 반환을 확인하세요.")
func _leave() -> void:
	if leaving: return
	if is_instance_valid(battle) and not account_invalid:
		if not battle.battle_over:
			var elapsed := maxi(Time.get_ticks_msec()-entry_started_ms,int((Time.get_unix_time_from_system()-entry_started_unix)*1000.0))
			var refund := STAMINA.refund_early_exit(entry,elapsed)
			if not bool(refund.get("success",false)):
				_show_stamina_notice("스테미너 반환 저장에 실패했습니다. 다시 눌러 주세요."); return
			run_abandoned = true
			battle.finish_abandoned_run()
		if not settled: return
	leaving = true
	get_tree().set_meta("hero_lobby_return",true)
	if not SceneTransition.change_scene("res://src/lobby/Lobby.tscn","용사 로비로..."):
		leaving = false

func _show_passive_info(index: int) -> void:
	if choosing or rolling or not is_instance_valid(battle) or battle.battle_over: return
	var runtime = battle.hero.player_weapons
	if index < 0 or index >= runtime.passives.size(): return
	var id := String(runtime.passives.keys()[index])
	_show_inventory_detail(INVENTORY_DETAIL.passive_model(runtime,id))

func _show_weapon_info(index: int) -> void:
	if choosing or rolling or not is_instance_valid(battle) or battle.battle_over: return
	var runtime = battle.hero.player_weapons
	if index < 0 or index >= runtime.weapon_ids.size(): return
	var id := String(runtime.weapon_ids[index])
	_show_inventory_detail(INVENTORY_DETAIL.weapon_model(runtime,battle.hero,id))

func _show_inventory_detail(model: Dictionary) -> void:
	if not entry_ready or account_invalid or not is_instance_valid(battle) or battle.battle_over: return
	paused = true; battle.set_external_pause(true); pad.enabled = false; pad.reset()
	_clear_overlay()
	inventory_dim.show(); inventory_dim.move_to_front(); overlay.move_to_front()
	overlay.offset_left = maxf(24,(size.x-920)*0.5); overlay.offset_right = -overlay.offset_left
	overlay.offset_top = minf(HUD.BATTLE_TOP+12,size.y*0.30); overlay.offset_bottom = -40
	overlay.add_theme_stylebox_override("panel",INVENTORY_DETAIL.style(Color("111322"),Color("e3bc69"),24))
	INVENTORY_DETAIL.build(overlay_rows,model,_resume)

func _queue_chest() -> void:
	if not battle.battle_over: pending_chests = mini(pending_chests+1,4)

func _begin_roulette() -> void:
	pending_chests -= 1; rolling = true; chest_gold_saved = false
	battle.set_external_pause(true); pad.enabled = false; pad.reset()
	roulette_receipt = battle.hero.player_weapons.roll_chest()
	roulette_pool = roulette_receipt.pool.duplicate()
	roulette_index = -1
	_clear_overlay()
	overlay.name = "HeroChestOverlay"
	inventory_dim.show(); inventory_dim.move_to_front(); overlay.move_to_front()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var half_width := minf(460,maxf(1,(size.x-48)*0.5))
	var half_height := minf(370,maxf(1,(size.y-48)*0.5))
	overlay.offset_left = -half_width; overlay.offset_right = half_width
	overlay.offset_top = -half_height; overlay.offset_bottom = half_height
	overlay.add_theme_stylebox_override("panel",INVENTORY_DETAIL.style(Color("111322"),Color("e3bc69"),24))
	overlay_rows.add_theme_constant_override("separation",14)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay_rows.add_child(scroll)
	roulette_details = VBoxContainer.new(); roulette_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roulette_details.add_theme_constant_override("separation",14); scroll.add_child(roulette_details)
	var title := _label(roulette_details,"보물상자 · 무기 진화" if bool(roulette_receipt.evolution) else "보물상자 · 보조 강화" if String(roulette_receipt.kind) == "passive" else "보물상자 · 회복" if String(roulette_receipt.kind) == "recovery" else "보물상자 · 무기 강화",34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_color_override("font_color",Color("ffce78"))
	var guide := _label(roulette_details,"빛나는 중앙 칸에 멈춘 보상이 적용됩니다",23)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roulette_reel = REEL.new(); roulette_details.add_child(roulette_reel)
	var ranks := {}
	var runtime = battle.hero.player_weapons
	for id in roulette_pool:
		ranks[id] = "MAX" if runtime.evolved.has(id) else "Lv.%d" % int(runtime.levels.get(id,runtime.passives.get(id,0))) if id != "survival_restore" else "회복"
	roulette_reel.configure(roulette_pool,roulette_receipt,ranks)
	roulette_label = roulette_reel.center_label
	roulette_continue = _button("보상 확인 중…",_close_roulette)
	roulette_continue.name = "ChestContinue"; roulette_continue.custom_minimum_size.y = 76; roulette_continue.disabled = true
	roulette_continue.add_theme_font_size_override("font_size",30)
	var button_skin := StyleBoxFlat.new(); button_skin.bg_color = Color("39234f"); button_skin.border_color = Color("edc16c")
	button_skin.set_border_width_all(3); button_skin.set_content_margin_all(18)
	roulette_continue.add_theme_stylebox_override("normal",SKIN.skin_style(button_skin))
	GameAudio.play_battle("chest",self)
	roulette_tween = create_tween()
	roulette_tween.tween_method(_roulette_tick,0.0,1.0,2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	roulette_tween.tween_callback(_finish_roulette)

func _roulette_tick(progress: float) -> void:
	if is_instance_valid(roulette_reel):
		roulette_reel.advance(progress)
		roulette_index = roulette_reel.last_index

func _finish_roulette() -> void:
	if not rolling or battle.battle_over: return
	if chest_gold_saved: return
	_roulette_tick(1.0)
	if not bool(roulette_receipt.get("applied",false)) and not battle.hero.player_weapons.apply_chest(roulette_receipt):
		chest_gold_saved = true
		roulette_label.text = "상자 보상 적용 실패"; roulette_continue.text = "계속 플레이"; roulette_continue.disabled = false; return
	var saved: Dictionary = STORE.record_chest(entry,int(roulette_receipt.get("serial",0)),float(battle.hero.player_weapons.gold_bonus))
	if not bool(saved.get("success",false)):
		roulette_label.text = "상자 골드 저장 실패"; roulette_continue.text = "골드 저장 재시도"; roulette_continue.disabled = false; return
	chest_gold_saved = true; run_chest_gold = int(saved.pending)
	opening_chest_claimed = true
	roulette_label.modulate = Color("ffe09a")
	_roulette_tick(1.0)
	var reward_name := _label(roulette_details,String(roulette_receipt.name),28)
	reward_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; reward_name.add_theme_color_override("font_color",Color("ffce78"))
	var description := _label(roulette_details,String(roulette_receipt.description),25)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gold_note := _label(roulette_details,"상자 골드 누적 %d · 승리100%% / 패배40%% / 중단30%%" % run_chest_gold,22)
	gold_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameAudio.play_battle("chest",self)
	_refresh_hud(); roulette_continue.text = "계속 플레이"; roulette_continue.disabled = false

func _close_roulette() -> void:
	if not rolling or not is_instance_valid(roulette_continue) or roulette_continue.disabled: return
	if not chest_gold_saved: _finish_roulette(); return
	if is_instance_valid(inventory_dim): inventory_dim.hide()
	rolling = false; overlay.hide(); pad.reset(); pad.enabled = true
	battle.set_external_pause(false)

func _install_battle_settings() -> void:
	battle_frame = preload("res://src/ui/hero_battle_frame.gd").new()
	battle_frame.name = "HeroBattleFrame"; add_child(battle_frame); move_child(battle_frame,2)
	battle_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_panel = SETTINGS.instantiate(); add_child(settings_panel)
	var rows := settings_panel.get_node("Panel/Margin/VBox")
	var tabs: TabContainer = rows.get_node("SettingsTabs")
	tabs.set_tab_title(0,"사운드"); tabs.set_tab_title(1,"게임플레이")
	rows.get_node("CloseButton").pressed.connect(settings_panel.hide)
	var camera: CheckBox = tabs.get_node("Gameplay/CameraLock")
	camera.set_pressed_no_signal(true); camera.disabled = true
	camera.tooltip_text = "용사 모드에서는 시야 고정이 필수입니다."
	tabs.get_node("Gameplay/CameraGuide").text = "용사 모드에서는 항상 용사를 추적합니다. 시야 고정을 해제할 수 없습니다."
	tabs.get_node("Gameplay/BattleFrame").toggled.connect(_set_battle_frame)
	var pad_row := HBoxContainer.new(); pad_row.name = "PadModeRow"
	pad_row.add_theme_constant_override("separation",16)
	tabs.get_node("Gameplay").add_child(pad_row)
	_label(pad_row,"이동 패드",23).custom_minimum_size.x = 165
	pad_mode_selector = OptionButton.new(); pad_mode_selector.name = "PadMode"
	pad_mode_selector.custom_minimum_size.y = 88
	pad_mode_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad_mode_selector.add_theme_font_size_override("font_size",30)
	pad_mode_selector.add_item("고정형 패드",0); pad_mode_selector.add_item("자유형 패드",1)
	_skin_action_button(pad_mode_selector); pad_row.add_child(pad_mode_selector)
	var pad_popup := pad_mode_selector.get_popup()
	pad_popup.add_theme_font_size_override("font_size",32)
	pad_popup.add_theme_constant_override("v_separation",64)
	pad_popup.add_theme_stylebox_override("panel",INVENTORY_DETAIL.style(Color("20192e"),Color("dfb86a"),16))
	pad_popup.add_theme_color_override("font_color",Color("efe5ce"))
	pad_popup.add_theme_color_override("font_hover_color",Color("ffda86"))
	pad_mode_selector.item_selected.connect(_set_pad_mode)
	var pad_guide := _label(tabs.get_node("Gameplay"),"고정형: 하단 중앙 · 자유형: 전투 화면 터치 위치\n변경 즉시 적용 · 자동 저장",18)
	pad_guide.name = "PadGuide"
	for pair in [["BGMRow",true],["SFXRow",false]]:
		tabs.get_node("Sound/"+String(pair[0])+"/Slider").value_changed.connect(_set_audio_level.bind(bool(pair[1])))
	tabs.get_node("Sound/BGMMute").toggled.connect(_set_audio_mute.bind(true))
	tabs.get_node("Sound/SFXMute").toggled.connect(_set_audio_mute.bind(false))
	var config := ConfigFile.new(); config.load(gameplay_settings_path)
	battle_frame_enabled = bool(config.get_value("gameplay","battle_frame_enabled",true))
	pad_mode = String(config.get_value("gameplay","hero_pad_mode",MOVE_PAD.MODE_FIXED))
	if pad_mode not in MOVE_PAD.MODES: pad_mode = MOVE_PAD.MODE_FIXED
	pad.set_mode(pad_mode)
	_apply_battle_frame(); _sync_settings()
func _open_settings() -> void:
	_sync_settings(); settings_panel.show(); settings_panel.move_to_front()
func _sync_settings() -> void:
	var tabs := settings_panel.get_node("Panel/Margin/VBox/SettingsTabs")
	for pair in [["BGMRow",AudioSettings.bgm_level],["SFXRow",AudioSettings.sfx_level]]:
		tabs.get_node("Sound/"+String(pair[0])+"/Slider").set_value_no_signal(float(pair[1]))
		tabs.get_node("Sound/"+String(pair[0])+"/Value").text = str(pair[1])
	tabs.get_node("Sound/BGMMute").set_pressed_no_signal(AudioSettings.bgm_muted)
	tabs.get_node("Sound/SFXMute").set_pressed_no_signal(AudioSettings.sfx_muted)
	tabs.get_node("Gameplay/CameraLock").set_pressed_no_signal(true)
	tabs.get_node("Gameplay/BattleFrame").set_pressed_no_signal(battle_frame_enabled)
	pad_mode_selector.select(MOVE_PAD.MODES.find(pad_mode))
func _set_pad_mode(index: int) -> void:
	if index < 0 or index >= MOVE_PAD.MODES.size(): return
	var value: String = MOVE_PAD.MODES[index]
	var config := ConfigFile.new(); config.load(gameplay_settings_path)
	config.set_value("gameplay","hero_pad_mode",value)
	if config.save(gameplay_settings_path) != OK: _sync_settings(); return
	pad_mode = value; pad.set_mode(value)
	_sync_settings()
func _set_audio_level(value: float,bgm: bool) -> void:
	if bgm:
		AudioSettings.set_bgm_level(roundi(value)); $HeroBGMManager.set_user_bgm_level(roundi(value))
	else: AudioSettings.set_sfx_level(roundi(value))
	_sync_settings()
func _set_audio_mute(value: bool,bgm: bool) -> void:
	if bgm:
		AudioSettings.set_bgm_muted(value); $HeroBGMManager.set_user_bgm_muted(value)
	else: AudioSettings.set_sfx_muted(value)
func _set_battle_frame(enabled: bool) -> void:
	var config := ConfigFile.new(); config.load(gameplay_settings_path)
	config.set_value("gameplay","battle_frame_enabled",enabled)
	if config.save(gameplay_settings_path) != OK: _sync_settings(); return
	battle_frame_enabled = enabled; _apply_battle_frame()
func _apply_battle_frame() -> void:
	battle_frame.visible = battle_frame_enabled
	var view: SubViewportContainer = get_node("BattleView")
	view.offset_left = HUD.FRAME_WIDTH if battle_frame_enabled else 0
	view.offset_right = -HUD.FRAME_WIDTH if battle_frame_enabled else 0
	stats_panel.position.x = view.offset_left+10
func _restart_from_pause() -> void:
	if leaving or not paused or battle.battle_over: return
	var elapsed := maxi(Time.get_ticks_msec()-entry_started_ms,int((Time.get_unix_time_from_system()-entry_started_unix)*1000.0))
	if not bool(STAMINA.refund_early_exit(entry,elapsed).get("success",false)):
		_show_stamina_notice("스테미너 반환 저장 실패 · 다시 시도하세요."); return
	run_abandoned = true
	battle.finish_abandoned_run()
	if settled: _retry()
func _next_stage(id: String) -> void:
	if leaving or not settled or not finished_won or not STORE.can_enter(id,run_difficulty): return
	var previous := stage
	stage = id; _retry()
	if not leaving: stage = previous

func _skin_action_button(button: Button) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = Color("223d50"); style.border_color = Color("c9a45e"); style.set_border_width_all(2); style.set_content_margin_all(10)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,SKIN.skin_style(style))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",Color("efe5c9"))

func _show_stamina_notice(message: String) -> void:
	STAMINA_NOTICE.show_notice(self,message)
