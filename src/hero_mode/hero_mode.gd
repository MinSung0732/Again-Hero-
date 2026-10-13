extends Control
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const BATTLE_SCENE := preload("res://src/battle/Battle.tscn")
const MOVE_PAD := preload("res://src/hero_mode/hero_move_pad.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
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
var initial_owner := ""
var account_invalid := false
var hud_remaining := 0.0
var entry_started_ms := -1
var entry_started_unix := 0.0
var finished_won := false
var finished_message := ""
func _ready() -> void:
	set_process(false)
	GameAudio.enter_frontend(self,"lobby")
	stage = STORE.selected_stage()
	initial_owner = STORE.owner()
	var options: Dictionary = SceneTransition.consume_entry_options()
	stage = String(options.get("stage_id",stage))
	_build_ui()
	if not UNLOCKS.unlocked("hero",stage) or STAGES.get_stage(stage).is_empty():
		_show_blocked("용사 모드는 쉬움 Stage 10 클리어 후 개방됩니다.")
		return
	entry = STAMINA.claim_battle_entry(stage)
	if entry.is_empty():
		var original_entry: Dictionary = options.get("hero_entry",{})
		var refunded := original_entry.is_empty() or STAMINA.refund_failed_entry(original_entry)
		_show_blocked("입장 기록을 확인하지 못했습니다. 로비에서 다시 입장하세요." if refunded else "입장 실패 · 스테미너 반환 저장도 실패했습니다. 로비에서 저장 상태를 확인하세요.")
		return
	entry_started_ms = Time.get_ticks_msec(); entry_started_unix = Time.get_unix_time_from_system()
	var view := SubViewportContainer.new()
	view.name = "BattleView"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.offset_top = 225; view.offset_bottom = -360
	view.stretch = true
	add_child(view); move_child(view,1)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080,1335)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	view.add_child(viewport)
	battle = BATTLE_SCENE.instantiate()
	battle.hero_player_mode = true; battle.hero_player_stage = stage
	viewport.add_child(battle)
	GameAudio.attach_battle(battle)
	$HeroBGMManager.start_stage(stage)
	$HeroBGMManager.set_user_bgm_level(AudioSettings.bgm_level)
	$HeroBGMManager.set_user_bgm_muted(AudioSettings.bgm_muted)
	battle.hero.set_camera_view_locked(true)
	battle.hero.player_augment_requested.connect(_show_choices)
	battle.battle_finished.connect(_on_finished)
	director = DIRECTOR.new()
	director.install(battle)
	pad.movement_changed.connect(func(value: Vector2):
		if is_instance_valid(battle) and is_instance_valid(battle.hero): battle.hero.set_player_move_input(value))
	_refresh_hud()
	set_process(true)
func _build_ui() -> void:
	var background := ColorRect.new(); background.color = Color("101e2c")
	background.name = "HeroBackground"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	# HeroBGMManager is already a child: index 1 must stay above this backdrop.
	move_child(background,0)
	var top := VBoxContainer.new(); add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 30; top.offset_right = -30; top.offset_top = 24; top.offset_bottom = 220
	timer = _label(top,"용사 모드 · 3분 생존",30)
	hp = ProgressBar.new(); hp.custom_minimum_size.y = 34; hp.show_percentage = false; top.add_child(hp)
	xp = ProgressBar.new(); xp.custom_minimum_size.y = 22; xp.show_percentage = false; top.add_child(xp)
	status = _label(top,"목표 · 3분 생존 / 공격 자동 / 레벨업 증강 직접 선택",22)
	var menu := Button.new(); menu.text = "설정 / 일시정지"; add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	menu.offset_left = -275; menu.offset_right = -25; menu.offset_top = 24; menu.offset_bottom = 90
	menu.pressed.connect(_pause)
	pad = MOVE_PAD.new(); pad.name = "MovePad"; add_child(pad)
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.offset_left = 30; pad.offset_right = 300; pad.offset_top = -315; pad.offset_bottom = -45
	build = _label(self,"이동 · 왼쪽 패드 / WASD / 방향키\n공격·고유 기술은 자동 발동",23)
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	build.offset_left = 335; build.offset_right = -30; build.offset_top = -315; build.offset_bottom = -35
	overlay = PanelContainer.new(); add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 65; overlay.offset_right = -65; overlay.offset_top = 300; overlay.offset_bottom = -400
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
	overlay_rows.add_child(button); button.pressed.connect(action); return button
func _clear_overlay() -> void:
	for child in overlay_rows.get_children(): overlay_rows.remove_child(child); child.queue_free()
	overlay.show(); overlay.move_to_front()
func _show_blocked(message: String) -> void:
	_clear_overlay(); _label(overlay_rows,message,30); _button("로비로",_leave)
func _process(delta: float) -> void:
	if not is_instance_valid(battle): return
	if STORE.owner() != initial_owner:
		account_invalid = true
		battle.set_external_pause(true); pad.reset(); _show_blocked("계정이 변경되었습니다. 로비로 돌아가세요.")
		set_process(false); return
	if not paused and not choosing and not battle.battle_over:
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
	$HeroBGMManager.update_hero_hp(hero.current_hp,hero.max_hp)
	xp.max_value = hero.exp_to_next_level; xp.value = hero.current_exp
	timer.text = "%s · Lv.%d · 생존 남은 %d초" % [String(battle.current_hero_profile.get("display_name","용사")),hero.level,ceili(battle.run_metrics.get_remaining_seconds())]
	status.text = "HP %d / %d · %s" % [hero.current_hp,hero.max_hp,director.plan if director != null else "공세 준비"]
	build.text = "이동 · 패드 / WASD / 방향키\n"+hero.get_build_summary()
func _show_choices(candidates: Array) -> void:
	if battle.battle_over: return
	choosing = true; choice_generation += 1
	var revision := choice_generation
	battle.set_external_pause(true); pad.enabled = false; pad.reset()
	_clear_overlay(); _label(overlay_rows,"레벨업 · 증강을 직접 선택하세요",32)
	var buttons: Array[Button] = []
	for candidate in candidates:
		var id := String(candidate.get("id",""))
		var description := String(candidate.get("description",""))
		var button := _button(String(candidate.get("name",id))+"\n"+description,_choose.bind(id,revision))
		button.disabled = true; buttons.append(button)
	await get_tree().create_timer(0.25).timeout
	if revision != choice_generation or not choosing or battle.battle_over: return
	for button in buttons:
		if is_instance_valid(button): button.disabled = false
func _choose(id: String,revision: int) -> void:
	if not choosing or revision != choice_generation or battle.battle_over: return
	choosing = false; overlay.hide(); pad.reset()
	battle.set_external_pause(paused)
	if not battle.hero.choose_player_augment(id):
		_show_choices(battle.hero.player_augment_candidates); return
	pad.enabled = not choosing and not paused
func _pause() -> void:
	if not is_instance_valid(battle) or battle.battle_over or choosing: return
	paused = true; battle.set_external_pause(true); pad.enabled = false; pad.reset()
	_clear_overlay(); _label(overlay_rows,"게임 설정 · 용사 모드",32)
	var camera := CheckBox.new(); camera.text = "화면 고정 · 용사 추적 (필수)"; camera.button_pressed = true; camera.disabled = true
	camera.tooltip_text = "용사 모드에서는 시야 고정을 해제할 수 없습니다."
	camera.add_theme_font_size_override("font_size",25); overlay_rows.add_child(camera)
	_button("계속 플레이",_resume); _button("로비로 돌아가기",_leave)
func _resume() -> void:
	paused = false; overlay.hide(); pad.reset(); pad.enabled = true
	battle.hero.set_camera_view_locked(true); battle.set_external_pause(false)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(battle):
		if choosing: pad.reset()
		else: _pause()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if paused: _resume()
		else: _pause()
		get_viewport().set_input_as_handled()
func _kill_count() -> int:
	var total := 0
	for value in battle.run_metrics.monster_death_counts.values(): total += int(value)
	return total
func _on_finished(message: String,won: bool) -> void:
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
	_button("같은 용사로 다시 도전",_retry); _button("로비로",_leave)
func _retry() -> void:
	if leaving or not settled: return
	var ticket := STAMINA.try_enter(stage,LocalTestMode.active)
	if not bool(ticket.get("success",false)):
		_label(overlay_rows,"스테미너 또는 저장 상태를 확인하세요.",23); return
	leaving = true
	if not SceneTransition.change_scene(DATA.SCENE,"용사 도전 준비 중...",{"stage_id":stage,"hero_entry":ticket}):
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
