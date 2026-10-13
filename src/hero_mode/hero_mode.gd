extends Control
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
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
var build: Label
var overlay: PanelContainer
var overlay_rows: VBoxContainer
var choice_generation := 0
var choosing := false
var paused := false
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
var roulette_tween: Tween
var roulette_label: Label
var roulette_reel: Control
var roulette_pool: Array = []
var roulette_receipt: Dictionary = {}
var roulette_index := -1
var finished_won := false
var finished_message := ""
func _ready() -> void:
	set_process(false)
	GameAudio.enter_frontend(self,"lobby")
	stage = STORE.selected_battle_stage()
	initial_owner = STORE.owner()
	var options: Dictionary = SceneTransition.consume_entry_options()
	stage = String(options.get("stage_id",stage))
	player_hero_id = String(options.get("hero_id",STORE.selected_hero()))
	_build_ui()
	if not STORE.character_unlocked(player_hero_id) or not STORE.battle_stage_unlocked(stage):
		var original_ticket: Dictionary = options.get("hero_entry",{})
		var refunded := original_ticket.is_empty() or STAMINA.refund_failed_entry(original_ticket)
		_show_blocked("용사 해금 조건 또는 이전 용사 스테이지 클리어를 확인하세요." if refunded else "잠긴 입장 실패 · 스테미너 반환 저장을 확인하세요.")
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
	view.offset_top = 330; view.offset_bottom = 0
	view.stretch = true
	add_child(view); move_child(view,1)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080,1590)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	view.add_child(viewport)
	battle = BATTLE_SCENE.instantiate()
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
	header.offset_left = 20; header.offset_right = -20; header.offset_top = 20; header.offset_bottom = 310
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("192633"); frame.border_color = Color("c9a45e"); frame.set_border_width_all(3); frame.set_content_margin_all(14)
	header.add_theme_stylebox_override("panel",SKIN.skin_style(frame))
	var top := VBoxContainer.new(); top.add_theme_constant_override("separation",4); header.add_child(top)
	var title_row := HBoxContainer.new(); top.add_child(title_row)
	HUD.logo(title_row)
	timer = _label(title_row,"용사 모드 · 15분 생존",23); timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var menu := Button.new(); menu.text = "설정"; menu.custom_minimum_size = Vector2(120,50); title_row.add_child(menu)
	menu.add_theme_font_size_override("font_size",23); _skin_action_button(menu); menu.pressed.connect(_pause)
	hp = HUD.bar(top,"HP",Color(0.08,0.92,0.25,1),32)
	xp = HUD.bar(top,"EXP",Color(0.08,0.55,1,1),24)
	status = _label(top,"이동 직접 · 공격 자동 · Lv.10 무기 + 상자 = 진화",20)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); top.add_child(row)
	for index in range(WEAPONS.WEAPON_SLOTS):
		var button := Button.new(); button.custom_minimum_size.y = 64; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.expand_icon = true; button.add_theme_constant_override("icon_max_width",40); button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_font_size_override("font_size",21); _skin_action_button(button); row.add_child(button); button.pressed.connect(_show_weapon_info.bind(index)); weapon_buttons.append(button)
	build = _label(top,"보조 증강 없음",19)
	build.autowrap_mode = TextServer.AUTOWRAP_OFF; build.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	build.clip_text = true
	pad = MOVE_PAD.new(); pad.name = "MovePad"; add_child(pad)
	pad.set_mode(pad_mode)
	overlay = PanelContainer.new(); add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 65; overlay.offset_right = -65; overlay.offset_top = 390; overlay.offset_bottom = -150
	var style := StyleBoxFlat.new(); style.bg_color = Color("122b3a"); style.border_color = Color("d9c77c"); style.set_border_width_all(3); style.set_content_margin_all(28)
	overlay.add_theme_stylebox_override("panel",SKIN.skin_style(style))
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
	hp.get_node("Caption").text = "HP %d / %d" % [hero.current_hp,hero.max_hp]
	$HeroBGMManager.update_hero_hp(hero.current_hp,hero.max_hp)
	xp.max_value = hero.exp_to_next_level; xp.value = hero.current_exp
	xp.get_node("Caption").text = "EXP %d / %d" % [hero.current_exp,hero.exp_to_next_level]
	timer.text = "Stage %d · %s Lv.%d\n남은 시간 %02d:%02d" % [int(battle.current_stage_data.get("number",1)),String(battle.current_hero_profile.get("display_name","용사")),hero.level,int(battle.run_metrics.get_remaining_seconds())/60,int(battle.run_metrics.get_remaining_seconds())%60]
	status.text = "처치 %d · %s · 공격 자동" % [_kill_count(),String(DATA.phase_at(battle.run_metrics.elapsed_seconds).name)]
	if hero.player_weapons != null and hero.player_weapons.identity != null:
		status.text = "처치 %d · %s" % [_kill_count(),hero.player_weapons.identity.summary()]
	if hero.player_weapons != null:
		var runtime = hero.player_weapons
		for index in weapon_buttons.size():
			var button: Button = weapon_buttons[index]
			if index >= runtime.weapon_ids.size(): button.text = "빈 무기 슬롯"; button.disabled = true; continue
			var id := String(runtime.weapon_ids[index]); button.disabled = false
			button.icon = ICONS.texture(id)
			button.text = WEAPONS.GROWTH.evolution_name(id) if runtime.evolved.has(id) else String(WEAPONS.WEAPONS[id].name)+" Lv.%d/10" % int(runtime.levels[id])
		var parts: PackedStringArray = []
		for id in runtime.passives: parts.append(String(WEAPONS.PASSIVES[id].name)+" %d" % int(runtime.passives[id]))
		build.text = "보조 %d/%d · " % [runtime.passives.size(),WEAPONS.PASSIVE_SLOTS]+("없음 / 이동: 패드·WASD" if parts.is_empty() else " · ".join(parts))
		build.tooltip_text = build.text
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
	await get_tree().create_timer(0.25).timeout
	if revision != choice_generation or not choosing or battle.battle_over: return
	for button in buttons:
		if is_instance_valid(button): button.disabled = false
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
	_clear_overlay(); _label(overlay_rows,"일시정지 · 용사 모드",32)
	_label(overlay_rows,"생존 %.1f초 · 처치 %d · Lv.%d\n%s" % [battle.run_metrics.elapsed_seconds,_kill_count(),battle.hero.level,battle.hero.get_build_summary()],23)
	_button("계속 플레이",_resume); _button("다시 시작",_restart_from_pause)
	_button("설정",_open_settings); _button("로비로 돌아가기",_leave)
func _resume() -> void:
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
	rolling = false; pending_chests = 0
	$HeroBGMManager.stop_bgm()
	GameAudio.battle_result(self,won)
	finished_message = message; finished_won = won; pad.enabled = false; pad.reset()
	choosing = false; choice_generation += 1
	_show_result()
func _show_result() -> void:
	_clear_overlay()
	var reward := {"success":true,"research":0,"gold":0}
	if not settled:
		reward = STORE.award_run(stage,entry,battle.run_metrics.elapsed_seconds,_kill_count(),finished_won)
		settled = bool(reward.get("success",false))
	_label(overlay_rows,finished_message,30)
	_label(overlay_rows,"생존 %.1f초 · 처치 %d · 용사 Lv.%d\n%s" % [battle.run_metrics.elapsed_seconds,_kill_count(),battle.hero.level,battle.hero.get_build_summary()],24)
	if not settled:
		_label(overlay_rows,"보상 저장에 실패했습니다. 재시도 후 이동하세요.",24)
		_button("보상 저장 재시도",_show_result); return
	_label(overlay_rows,"연구 포인트 +%d · 골드 +%d\n다른 증강 조합과 이동 경로를 시험하세요." % [int(reward.get("research",0)),int(reward.get("gold",0))],24)
	var next_stage := String(STAGES.get_stage(stage).get("next_stage_id",""))
	if finished_won and STORE.battle_stage_unlocked(next_stage): _button("다음 스테이지 도전",_next_stage.bind(next_stage))
	_button("같은 용사로 다시 도전",_retry); _button("로비로",_leave)
func _retry() -> void:
	if leaving or not settled: return
	var ticket := STAMINA.try_enter(stage,LocalTestMode.active,-1,false)
	if not bool(ticket.get("success",false)):
		_label(overlay_rows,"스테미너 또는 저장 상태를 확인하세요.",23); return
	leaving = true
	if not SceneTransition.change_scene(DATA.SCENE,"용사 도전 준비 중...",{"stage_id":stage,"hero_id":player_hero_id,"hero_entry":ticket}):
		STAMINA.refund_failed_entry(ticket); leaving = false
		_label(overlay_rows,"입장 실패 · 스테미너 반환을 확인하세요.",23)
func _leave() -> void:
	if leaving: return
	if is_instance_valid(battle) and not account_invalid:
		if not battle.battle_over:
			var elapsed := maxi(Time.get_ticks_msec()-entry_started_ms,int((Time.get_unix_time_from_system()-entry_started_unix)*1000.0))
			var refund := STAMINA.refund_early_exit(entry,elapsed)
			if not bool(refund.get("success",false)):
				_label(overlay_rows,"스테미너 반환 저장에 실패했습니다. 다시 눌러 주세요.",23); return
			battle.finish_abandoned_run()
		if not settled: return
	leaving = true
	get_tree().set_meta("hero_lobby_return",true)
	if not SceneTransition.change_scene("res://src/lobby/Lobby.tscn","용사 로비로..."):
		leaving = false

func _show_weapon_info(index: int) -> void:
	if choosing or rolling or not is_instance_valid(battle) or battle.battle_over: return
	var runtime = battle.hero.player_weapons
	if index >= runtime.weapon_ids.size(): return
	_pause(); _clear_overlay()
	var id := String(runtime.weapon_ids[index])
	_label(overlay_rows,WEAPONS.GROWTH.evolution_name(id) if runtime.evolved.has(id) else String(WEAPONS.WEAPONS[id].name),32)
	_label(overlay_rows,WEAPONS.GROWTH.description(id,int(runtime.levels[id]),runtime.evolved.has(id)),24)
	_label(overlay_rows,"상자: Lv.10 무기 중 하나 진화 → 없으면 보유 무기 +1레벨",23)
	_button("계속 플레이",_resume)

func _queue_chest() -> void:
	if not battle.battle_over: pending_chests = mini(pending_chests+1,4)

func _begin_roulette() -> void:
	pending_chests -= 1; rolling = true
	battle.set_external_pause(true); pad.enabled = false; pad.reset()
	roulette_receipt = battle.hero.player_weapons.roll_chest()
	roulette_pool = battle.hero.player_weapons.weapon_ids.duplicate()
	roulette_index = -1
	_clear_overlay()
	overlay.name = "HeroChestOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.offset_left = -450; overlay.offset_right = 450; overlay.offset_top = -310; overlay.offset_bottom = 310
	overlay_rows.add_theme_constant_override("separation",14)
	var title := _label(overlay_rows,"보물상자 · 무기 진화" if bool(roulette_receipt.evolution) else "보물상자 · 무기 강화",34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var guide := _label(overlay_rows,"빛나는 중앙 칸에 멈춘 보상이 적용됩니다",23)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roulette_reel = REEL.new(); overlay_rows.add_child(roulette_reel)
	roulette_reel.configure(roulette_pool,roulette_receipt)
	roulette_label = roulette_reel.center_label
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
	if bool(roulette_receipt.get("applied",false)): return
	_roulette_tick(1.0)
	if not battle.hero.player_weapons.apply_chest(roulette_receipt):
		roulette_label.text = "무기 강화 적용 실패"; _button("계속 플레이",_close_roulette); return
	roulette_label.modulate = Color("ffe09a")
	var description := _label(overlay_rows,String(roulette_receipt.description),25)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameAudio.play_battle("chest",self)
	_refresh_hud(); _button("계속 플레이",_close_roulette).custom_minimum_size.y = 76

func _close_roulette() -> void:
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
	pad_mode_selector.custom_minimum_size.y = 58
	pad_mode_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad_mode_selector.add_theme_font_size_override("font_size",23)
	pad_mode_selector.add_item("고정형 패드",0); pad_mode_selector.add_item("자유형 패드",1)
	_skin_action_button(pad_mode_selector); pad_row.add_child(pad_mode_selector)
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
	view.offset_left = 90 if battle_frame_enabled else 0
	view.offset_right = -90 if battle_frame_enabled else 0
func _restart_from_pause() -> void:
	if leaving or not paused or battle.battle_over: return
	var elapsed := maxi(Time.get_ticks_msec()-entry_started_ms,int((Time.get_unix_time_from_system()-entry_started_unix)*1000.0))
	if not bool(STAMINA.refund_early_exit(entry,elapsed).get("success",false)):
		_label(overlay_rows,"스테미너 반환 저장 실패 · 다시 시도하세요.",23); return
	battle.finish_abandoned_run()
	if settled: _retry()
func _next_stage(id: String) -> void:
	if leaving or not settled or not finished_won or not STORE.battle_stage_unlocked(id): return
	var previous := stage
	stage = id; _retry()
	if not leaving: stage = previous

func _skin_action_button(button: Button) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = Color("223d50"); style.border_color = Color("c9a45e"); style.set_border_width_all(2); style.set_content_margin_all(10)
	for state in ["normal","hover","pressed","disabled"]: button.add_theme_stylebox_override(state,SKIN.skin_style(style))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",Color("efe5c9"))
