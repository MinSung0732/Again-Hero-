extends Control
var host: Control
var button: Button
var unlock_button: Button
var title: Label
var icon: TextureRect
var tween: Tween
var shown_id := ""
var visible_once := false
const WIDTH := 144.0

func install(main: Control) -> void:
	host = main
	name = "TranscendenceSummon"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.hud_layer.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 80
	button = Button.new()
	button.name = "Summon"
	button.focus_mode = Control.FOCUS_NONE
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.63
	button.anchor_bottom = 0.63
	button.offset_left = 0
	button.offset_right = WIDTH
	button.offset_top = 0
	button.offset_bottom = 156
	for state in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state,host.monster_info_bookmark.get_theme_stylebox(state).duplicate())
	add_child(button)
	host._replace_button_frame(button,host.BATTLE_PIXEL_FRAME_MEDIUM_DIR,0.25,host.BATTLE_PIXEL_CENTER_DARK,18)
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 12
	body.offset_right = -12
	body.offset_top = 12
	body.offset_bottom = -12
	icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size.y = 86
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(icon)
	title = Label.new()
	title.text = "초월 소환"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",Color("f0cb68"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(title)
	unlock_button = Button.new()
	unlock_button.name = "TestUnlock"
	unlock_button.text = "잠금 해제"
	unlock_button.focus_mode = Control.FOCUS_NONE
	unlock_button.anchor_left = 1.0
	unlock_button.anchor_right = 1.0
	unlock_button.anchor_top = 0.63
	unlock_button.anchor_bottom = 0.63
	unlock_button.offset_left = -WIDTH - 12
	unlock_button.offset_right = -12
	unlock_button.offset_top = -66
	unlock_button.offset_bottom = -10
	unlock_button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "disabled"]:
		unlock_button.add_theme_stylebox_override(state, button.get_theme_stylebox(state).duplicate())
	add_child(unlock_button)
	host._replace_button_frame(unlock_button,host.BATTLE_PIXEL_FRAME_MEDIUM_DIR,0.25,host.BATTLE_PIXEL_CENTER_DARK,18)
	unlock_button.pressed.connect(host.battle.debug_unlock_transcendence)
	button.pressed.connect(host.battle.try_summon_transcendent)
	host.battle.transcendence_changed.connect(_changed)
	host.battle.command_changed.connect(_command_changed)
	host.battle.stats_changed.connect(_stats_changed)
	host.battle.battle_finished.connect(_finished)
	hide()
	refresh()

func _changed(_id: String, _ready: bool, _used: bool) -> void:
	refresh()

func _command_changed(_value: float,_maximum: float) -> void:
	refresh()

func _stats_changed(_hp: int, _max_hp: int, _monsters: int) -> void:
	refresh()

func _finished(_message: String, _won: bool) -> void:
	hide()

func refresh() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.battle):
		return
	var state = host.battle.transcendence
	var local_test := LocalTestMode.active
	if state.monster_id != shown_id or (not state.ready and not state.used and visible_once and not local_test):
		shown_id = state.monster_id
		visible_once = false
		if tween != null and tween.is_valid():
			tween.kill()
		button.offset_left = 0
		button.offset_right = WIDTH
	if state.monster_id.is_empty() or (not state.ready and not local_test) or state.used or host.battle.battle_over:
		hide()
		return
	show()
	unlock_button.visible = local_test
	var unlocked: bool = state.ready and (not local_test or state.test_unlock_confirmed)
	unlock_button.text = "해제 완료" if state.test_unlock_confirmed else "잠금 해제"
	title.text = "초월 소환" if unlocked else "잠김"
	icon.modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.45, 0.65)
	unlock_button.disabled = state.test_unlock_confirmed or host.battle.external_pause or host.battle.demon_augment_selection_active
	if not visible_once:
		visible_once = true
		icon.texture = host._load_monster_card_icon(state.monster_id)
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(button,"offset_left",-WIDTH-12,0.24)
		tween.tween_property(button,"offset_right",-12.0,0.24)
	button.disabled = not unlocked or host.battle.external_pause or host.battle.demon_augment_selection_active or host.battle.command_power + 0.001 < host.battle.get_monster_cost(state.monster_id)
