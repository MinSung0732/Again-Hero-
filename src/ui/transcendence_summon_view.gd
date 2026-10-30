extends Control
var host: Control
var state_provider: Callable
var icon_provider: Callable
var summon_callback: Callable
var unlock_callback: Callable
var light_paused := false
var pause_provider: Callable
var button: Button
var unlock_button: Button
var title: Label
var icon: TextureRect
var tween: Tween
var shown_id := ""
var visible_once := false
const WIDTH := 144.0
const READY_SHEET := preload("res://assets/art/UI/transcendence_ready/ready_spritesheet.png")
const READY_CELL := Vector2(164, 176)
const READY_FPS := 6.0
var ready_light: TextureRect
var ready_frames: Array[AtlasTexture] = []
var ready_elapsed := 0.0
var ready_announced := false
var ready_frame := -1

func install(main: Control) -> void:
	host = main
	state_provider = _solo_state
	pause_provider = _solo_paused
	icon_provider = main._load_monster_card_icon
	summon_callback = main.battle.try_summon_transcendent
	unlock_callback = main.battle.debug_unlock_transcendence
	_build(main.hud_layer, main.monster_info_bookmark)
	main.battle.transcendence_changed.connect(_changed)
	main.battle.command_changed.connect(_command_changed)
	main.battle.population_changed.connect(func(_count, _capacity): refresh())
	main.battle.stats_changed.connect(_stats_changed)
	main.battle.battle_finished.connect(_finished)
	refresh()

func install_adapter(parent: Control, provider: Callable, icon_loader: Callable, summon: Callable, unlock: Callable) -> void:
	state_provider = provider
	icon_provider = icon_loader
	summon_callback = summon
	unlock_callback = unlock
	_build(parent)
	refresh()

func _build(parent: Node, style_source: Button = null) -> void:
	name = "TranscendenceSummon"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
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
	if style_source != null:
		for state in ["normal","hover","pressed","disabled"]:
			button.add_theme_stylebox_override(state,style_source.get_theme_stylebox(state).duplicate())
	add_child(button)
	_frame(button)
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
	ready_light = TextureRect.new()
	ready_light.name = "ReadyLight"
	ready_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ready_light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ready_light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	button.add_child(ready_light)
	ready_light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ready_light.offset_left = -10
	ready_light.offset_top = -10
	ready_light.offset_right = 10
	ready_light.offset_bottom = 10
	for index in range(12):
		var frame := AtlasTexture.new()
		frame.atlas = READY_SHEET
		frame.region = Rect2(Vector2(index * READY_CELL.x, 0), READY_CELL)
		frame.filter_clip = true
		ready_frames.append(frame)
	ready_light.hide()
	set_process(false)
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
	_frame(unlock_button)
	unlock_button.pressed.connect(unlock_callback)
	button.pressed.connect(summon_callback)
	hide()

func _frame(target: Button) -> void:
	if host != null:
		host._replace_button_frame(target,host.BATTLE_PIXEL_FRAME_MEDIUM_DIR,0.25,host.BATTLE_PIXEL_CENTER_DARK,18)
	else:
		var frame = preload("res://src/ui/battle_pixel_frame_assembler.gd")
		frame.clear_button_style(target)
		frame.add_split_frame(target,"res://assets/art/UI/03_middle_right_panel",0.25,"res://assets/art/UI/05_right_bars/part_02.png",18)

func _solo_paused() -> bool:
	return not is_instance_valid(host) or not is_instance_valid(host.battle) or host.battle.external_pause or host.battle.demon_augment_selection_active

func _solo_state() -> Dictionary:
	if not is_instance_valid(host) or not is_instance_valid(host.battle): return {}
	var battle = host.battle
	var state = battle.transcendence
	var paused: bool = battle.external_pause or battle.demon_augment_selection_active
	var local_test: bool = get_node("/root/LocalTestMode").active
	return {"id":state.monster_id,"ready":state.ready,"used":state.used,"finished":battle.battle_over,
		"show_locked":local_test,"show_unlock":local_test,"paused":paused,
		"disabled":battle.is_population_full() or paused or battle.command_power + 0.001 < battle.get_monster_cost(state.monster_id)}

func _changed(_id: String, _ready: bool, _used: bool) -> void:
	refresh()

func _command_changed(_value: float,_maximum: float) -> void:
	refresh()

func _stats_changed(_hp: int, _max_hp: int, _monsters: int) -> void:
	refresh()

func _finished(_message: String, _won: bool) -> void:
	_stop_ready_light()
	hide()

func refresh() -> void:
	if not state_provider.is_valid(): return
	var state: Dictionary = state_provider.call()
	if state.is_empty(): return
	var id := String(state.get("id", ""))
	var ready := bool(state.get("ready", false))
	var used := bool(state.get("used", false))
	var show_locked := bool(state.get("show_locked", false))
	var show_unlock := bool(state.get("show_unlock", false))
	light_paused = bool(state.get("paused", false))
	if id != shown_id or (not ready and not used and visible_once and not show_locked):
		_stop_ready_light()
		shown_id = id
		visible_once = false
		if tween != null and tween.is_valid(): tween.kill()
		button.offset_left = 0
		button.offset_right = WIDTH
	if id.is_empty() or used or bool(state.get("finished", false)):
		button.hide()
		unlock_button.hide()
		_stop_ready_light()
		hide()
		return
	var show_summon := ready or show_locked
	if not show_summon and not show_unlock:
		button.hide()
		unlock_button.hide()
		_stop_ready_light()
		hide()
		return
	show()
	button.visible = show_summon
	unlock_button.visible = show_unlock
	unlock_button.text = "해제 완료" if ready else "잠금 해제"
	title.text = String(state.get("title", "초월 소환")) if ready else "잠김"
	icon.modulate = Color.WHITE if ready else Color(0.45, 0.45, 0.45, 0.65)
	unlock_button.disabled = ready or light_paused
	if show_summon and not visible_once:
		visible_once = true
		icon.texture = icon_provider.call(id)
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(button,"offset_left",-WIDTH-12,0.24)
		tween.tween_property(button,"offset_right",-12.0,0.24)
	button.disabled = not ready or bool(state.get("disabled", false))
	if not ready:
		_stop_ready_light()
	else:
		if not ready_announced:
			ready_announced = true
			ready_elapsed = 0.0
			ready_frame = -1
		set_process(true)
		_process(0.0)

func _stop_ready_light() -> void:
	ready_announced = false
	ready_elapsed = 0.0
	ready_frame = -1
	if is_instance_valid(ready_light):
		ready_light.hide()
	set_process(false)

func _process(delta: float) -> void:
	if not ready_announced or not is_visible_in_tree():
		return
	if (pause_provider.call() if pause_provider.is_valid() else light_paused):
		ready_light.hide()
		return
	ready_elapsed += delta
	ready_light.show()
	var index := int(ready_elapsed * READY_FPS) % ready_frames.size()
	if index != ready_frame:
		ready_frame = index
		ready_light.texture = ready_frames[index]
	# First three seconds draw attention; later keep a restrained availability cue.
	ready_light.modulate.a = (1.0 if ready_elapsed < 3.0 else 0.55) * (0.45 if button.disabled else 1.0)
