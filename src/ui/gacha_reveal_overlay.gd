extends Control
class_name GachaRevealOverlay

signal confirmed

const SHOP_CATALOG := preload("res://src/data/shop_catalog.gd")
const REVEAL_AURA := preload("res://src/ui/gacha_reveal_aura.gd")
const CHAMBER_PATH := "res://assets/art/effects/gatcha/summoning_chamber.png"
const PANEL_FRAME_PATH := "res://assets/art/UI/uicardframes/ui10_clean_frame.png"
const BUTTON_FRAME_PATH := "res://assets/art/UI/lobby_stage/enter_button.svg"
const CARD_FRAME_PATH := "res://assets/art/UI/lobby_stage/portrait_frame.svg"
const DOOR_FRAME_SIZE := Vector2(512.0, 512.0)
const DOOR_COLUMNS := 6
const DOOR_FRAME_COUNT := 30
const DOOR_FPS := 10.0
const ANTICIPATION_SECONDS := 0.75

var _results: Array = []
var _reveal_index: int = -1
var _sequence_token: int = 0
var _phase: String = "idle"
var _shake_tween: Tween
var _flash_tween: Tween
var _reveal_tween: Tween
var _aura_tween: Tween

var _background: ColorRect
var _chamber: TextureRect
var _ambient_glow: ColorRect
var _door_sprite: AnimatedSprite2D
var _flash: ColorRect
var _skip_button: Button
var _continue_button: Button
var _reveal_panel: PanelContainer
var _reveal_badge: Label
var _reveal_icon: TextureRect
var _reveal_name: Label
var _reveal_hint: Label
var _reveal_aura: GachaRevealAura
var _result_summary: Label
var _result_panel: PanelContainer
var _result_grid: GridContainer
var _confirm_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 500
	_build_ui()
	hide()


func is_presenting() -> bool:
	return visible and _phase != "idle"


func present(results: Array) -> void:
	if results.is_empty():
		return
	_sequence_token += 1
	_results = results.duplicate(true)
	_reveal_index = -1
	_phase = "door"
	_reset_visual_state()
	show()
	move_to_front()
	_play_opening(_sequence_token)


func skip_to_results() -> void:
	if not is_presenting() or _phase == "result":
		return
	_sequence_token += 1
	_stop_active_tweens()
	_door_sprite.stop()
	_show_final_results()


func _play_opening(token: int) -> void:
	var rarity_id := _highest_rarity_id()
	var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
	var flash_color: Color = rarity_data.get("color", Color.WHITE)
	_background.color = Color("08060f")
	_ambient_glow.color = Color("080512", 0.14)

	await get_tree().process_frame
	if token != _sequence_token:
		return

	if _chamber.texture == null:
		_chamber.texture = await _load_texture_threaded(CHAMBER_PATH)
		if token != _sequence_token:
			return

	var sheet_path := String(rarity_data.get("door_sheet_path", ""))
	var sheet: Texture2D = await _load_texture_threaded(sheet_path)
	if token != _sequence_token:
		return

	if sheet != null:
		_door_sprite.sprite_frames = _build_door_frames(sheet)
		_door_sprite.animation = "open"
		_door_sprite.frame = 0
		_layout_door()
		_door_sprite.show()

	await get_tree().create_timer(ANTICIPATION_SECONDS).timeout
	if token != _sequence_token:
		return

	if sheet != null:
		_start_door_shake()
		_door_sprite.play("open")
		await get_tree().create_timer(float(DOOR_FRAME_COUNT) / DOOR_FPS).timeout
	else:
		await get_tree().create_timer(0.25).timeout
	if token != _sequence_token:
		return

	await _play_flash(flash_color)
	if token != _sequence_token:
		return
	_show_reveal(0)


func _load_texture_threaded(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var request_error := ResourceLoader.load_threaded_request(path, "Texture2D")
	if request_error != OK:
		var fallback = load(path)
		return fallback as Texture2D

	var status := ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	return ResourceLoader.load_threaded_get(path) as Texture2D


func _build_door_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("open")
	frames.set_animation_loop("open", false)
	frames.set_animation_speed("open", DOOR_FPS)
	for index in range(DOOR_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			float(index % DOOR_COLUMNS) * DOOR_FRAME_SIZE.x,
			float(floori(float(index) / float(DOOR_COLUMNS))) * DOOR_FRAME_SIZE.y,
			DOOR_FRAME_SIZE.x,
			DOOR_FRAME_SIZE.y
		)
		frames.add_frame("open", atlas)
	return frames


func _highest_rarity_id() -> String:
	var highest_id := "common"
	var highest_rank := -1
	for raw_result in _results:
		if typeof(raw_result) != TYPE_DICTIONARY:
			continue
		var rarity_id := String(raw_result.get("rarity", "common"))
		var rank := SHOP_CATALOG.get_rarity_rank(rarity_id)
		if rank > highest_rank:
			highest_rank = rank
			highest_id = rarity_id
	return highest_id


func _start_door_shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var center := size * Vector2(0.5, 0.53)
	_shake_tween = create_tween()
	for index in range(24):
		var strength := 12.0 * (1.0 - float(index) / 30.0)
		var x_offset := strength if index % 2 == 0 else -strength
		var y_offset := -strength * 0.35 if index % 3 == 0 else strength * 0.20
		_shake_tween.tween_property(
			_door_sprite,
			"position",
			center + Vector2(x_offset, y_offset),
			0.045
		)
		_shake_tween.parallel().tween_property(
			_chamber, "position", Vector2(x_offset, y_offset) * 0.35, 0.045
		)
	_shake_tween.tween_property(_door_sprite, "position", center, 0.06)
	_shake_tween.parallel().tween_property(_chamber, "position", Vector2.ZERO, 0.06)


func _play_flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.color = Color(color.r, color.g, color.b, 0.0)
	_flash.show()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.96, 0.11)
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.34)
	await get_tree().create_timer(0.45).timeout


func _show_reveal(index: int) -> void:
	if index < 0 or index >= _results.size():
		_show_final_results()
		return
	_phase = "reveal"
	_flash.hide()
	_reveal_index = index
	_door_sprite.hide()
	_reveal_panel.show()
	_result_panel.hide()
	_continue_button.show()
	_skip_button.show()

	var entry: Dictionary = _results[index]
	var rarity_id := String(entry.get("rarity", "common"))
	var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
	var rarity_color: Color = rarity_data.get("color", Color.WHITE)
	_reveal_badge.text = SHOP_CATALOG.get_rarity_label(rarity_id)
	_reveal_badge.add_theme_color_override("font_color", rarity_color)
	_reveal_icon.texture = entry.get("icon") as Texture2D
	_reveal_name.text = "%s 등장!" % String(entry.get("name", "몬스터"))
	_reveal_name.add_theme_color_override("font_color", rarity_color)
	_reveal_hint.text = "화면을 터치해 계속  ·  %d / %d" % [
		index + 1,
		_results.size(),
	]
	_apply_reveal_panel_color(rarity_color)
	_reveal_aura.set_accent(rarity_color)
	_play_reveal_emphasis()


func _advance_reveal() -> void:
	if _phase != "reveal":
		return
	_show_reveal(_reveal_index + 1)


func _play_reveal_emphasis() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_icon.scale = Vector2(0.72, 0.72)
	_reveal_icon.modulate = Color(1.8, 1.8, 1.8, 0.0)
	_reveal_icon.pivot_offset = _reveal_icon.size * 0.5
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_reveal_icon, "scale", Vector2.ONE, 0.34)
	_reveal_tween.tween_property(_reveal_icon, "modulate", Color.WHITE, 0.28)
	if _aura_tween != null and _aura_tween.is_valid():
		_aura_tween.kill()
	_reveal_aura.modulate.a = 0.45
	_aura_tween = create_tween().set_loops()
	_aura_tween.tween_property(_reveal_aura, "modulate:a", 1.0, 0.50)
	_aura_tween.tween_property(_reveal_aura, "modulate:a", 0.45, 0.65)


func _show_final_results() -> void:
	_phase = "result"
	_stop_active_tweens()
	_door_sprite.stop()
	_door_sprite.hide()
	_flash.hide()
	_reveal_panel.hide()
	_continue_button.hide()
	_skip_button.hide()
	_result_panel.show()
	var total_shards := 0
	for entry in _results:
		total_shards += maxi(int(entry.get("shards", 0)), 0)
	_result_summary.text = "%d회 소환 · 총 %d조각 획득" % [_results.size(), total_shards]
	_rebuild_result_grid()


func _rebuild_result_grid() -> void:
	for child in _result_grid.get_children():
		_result_grid.remove_child(child)
		child.queue_free()
	_result_grid.columns = mini(4, maxi(_results.size(), 1))

	for raw_result in _results:
		if typeof(raw_result) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_result
		_result_grid.add_child(_create_result_card(entry))


func _create_result_card(entry: Dictionary) -> Control:
	var rarity_id := String(entry.get("rarity", "common"))
	var rarity_data := SHOP_CATALOG.get_rarity(rarity_id)
	var rarity_color: Color = rarity_data.get("color", Color.WHITE)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160.0, 246.0)
	card.add_theme_stylebox_override("panel", _make_panel_style(
		Color("171220"), rarity_color, 3, 18
	))
	_add_frame_texture(card, CARD_FRAME_PATH, rarity_color)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0.0, 124.0)
	icon.texture = entry.get("icon") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vbox.add_child(icon)

	var name_label := Label.new()
	name_label.text = String(entry.get("name", "몬스터"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(name_label)

	var shard_label := Label.new()
	shard_label.text = "+%d 조각" % maxi(int(entry.get("shards", 0)), 0)
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shard_label.add_theme_font_size_override("font_size", 20)
	shard_label.add_theme_color_override("font_color", Color("f6e3aa"))
	vbox.add_child(shard_label)

	if bool(entry.get("unlocked", false)):
		var unlock_label := Label.new()
		unlock_label.text = "신규 해금"
		unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_label.add_theme_font_size_override("font_size", 16)
		unlock_label.add_theme_color_override("font_color", Color("72e29a"))
		vbox.add_child(unlock_label)
	return card


func _confirm() -> void:
	if _phase != "result":
		return
	_sequence_token += 1
	_phase = "idle"
	_stop_active_tweens()
	_results.clear()
	_door_sprite.sprite_frames = SpriteFrames.new()
	hide()
	confirmed.emit()


func _reset_visual_state() -> void:
	_stop_active_tweens()
	_door_sprite.stop()
	_door_sprite.hide()
	_flash.hide()
	_reveal_panel.hide()
	_result_panel.hide()
	_continue_button.hide()
	_skip_button.show()


func _stop_active_tweens() -> void:
	for tween in [_shake_tween, _flash_tween, _reveal_tween, _aura_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_layout_door()
	if _chamber != null:
		_chamber.position = Vector2.ZERO


func _layout_door() -> void:
	if _door_sprite == null:
		return
	_door_sprite.position = size * Vector2(0.5, 0.53)
	var target_width := maxf(size.x * 0.94, 1.0)
	var scale_value := target_width / DOOR_FRAME_SIZE.x
	_door_sprite.scale = Vector2(scale_value, scale_value)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_door()


func _apply_reveal_panel_color(color: Color) -> void:
	_reveal_panel.add_theme_stylebox_override("panel", _make_panel_style(
		Color("120d1b", 0.91), color, 0, 0
	))


func _add_frame_texture(target: Control, path: String, tint: Color = Color.WHITE) -> void:
	if not ResourceLoader.exists(path):
		return
	var frame := TextureRect.new()
	frame.texture = load(path) as Texture2D
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.modulate = tint
	frame.z_index = 1
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(frame)


func _style_decorated_button(button: Button) -> void:
	if not ResourceLoader.exists(BUTTON_FRAME_PATH):
		return
	var texture := load(BUTTON_FRAME_PATH) as Texture2D
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxTexture.new()
		style.texture = texture
		style.texture_margin_left = 52.0
		style.texture_margin_right = 52.0
		style.texture_margin_top = 24.0
		style.texture_margin_bottom = 24.0
		style.modulate_color = Color("d9a7e7") if state == "pressed" else Color.WHITE
		button.add_theme_stylebox_override(state, style)


func _make_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style


func _build_ui() -> void:
	_background = ColorRect.new()
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.color = Color("08060f")
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_chamber = TextureRect.new()
	_chamber.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chamber.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chamber.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_chamber.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_chamber.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chamber)

	_ambient_glow = ColorRect.new()
	_ambient_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ambient_glow.color = Color("21142f")
	_ambient_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ambient_glow)

	_door_sprite = AnimatedSprite2D.new()
	_door_sprite.centered = true
	_door_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_door_sprite)

	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 20
	add_child(_flash)

	_build_reveal_panel()
	_build_result_panel()

	_continue_button = Button.new()
	_continue_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_continue_button.flat = true
	_continue_button.text = ""
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.z_index = 40
	_continue_button.pressed.connect(_advance_reveal)
	add_child(_continue_button)

	_skip_button = Button.new()
	_skip_button.text = "SKIP  »"
	_skip_button.anchor_left = 1.0
	_skip_button.anchor_top = 0.0
	_skip_button.anchor_right = 1.0
	_skip_button.anchor_bottom = 0.0
	_skip_button.offset_left = -220.0
	_skip_button.offset_top = 54.0
	_skip_button.offset_right = -34.0
	_skip_button.offset_bottom = 124.0
	_skip_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_button.add_theme_font_size_override("font_size", 25)
	_skip_button.add_theme_color_override("font_color", Color("fff0bd"))
	_skip_button.add_theme_stylebox_override(
		"normal", _make_panel_style(Color("261d31"), Color("d7ad47"), 2, 16)
	)
	_skip_button.add_theme_stylebox_override(
		"hover", _make_panel_style(Color("4a3158"), Color("ffd45f"), 3, 16)
	)
	_skip_button.add_theme_stylebox_override(
		"pressed", _make_panel_style(Color("17101e"), Color("ffd45f"), 3, 16)
	)
	_skip_button.z_index = 60
	_style_decorated_button(_skip_button)
	_skip_button.pressed.connect(skip_to_results)
	add_child(_skip_button)


func _build_reveal_panel() -> void:
	_reveal_panel = PanelContainer.new()
	_reveal_panel.anchor_left = 0.10
	_reveal_panel.anchor_top = 0.24
	_reveal_panel.anchor_right = 0.90
	_reveal_panel.anchor_bottom = 0.76
	_reveal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_panel.z_index = 30
	add_child(_reveal_panel)
	_add_frame_texture(_reveal_panel, PANEL_FRAME_PATH)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_bottom", 140)
	_reveal_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	_reveal_badge = Label.new()
	_reveal_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_badge.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_reveal_badge)

	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0.0, 470.0)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stage)
	_reveal_aura = REVEAL_AURA.new()
	_reveal_aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_reveal_aura)

	_reveal_icon = TextureRect.new()
	_reveal_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_icon.offset_left = 110.0
	_reveal_icon.offset_right = -110.0
	_reveal_icon.offset_top = 65.0
	_reveal_icon.offset_bottom = -65.0
	_reveal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reveal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reveal_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reveal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_reveal_icon)

	_reveal_name = Label.new()
	_reveal_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_name.add_theme_font_size_override("font_size", 46)
	_reveal_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_reveal_name)

	_reveal_hint = Label.new()
	_reveal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_hint.add_theme_font_size_override("font_size", 23)
	_reveal_hint.add_theme_color_override("font_color", Color("c9bed2"))
	vbox.add_child(_reveal_hint)


func _build_result_panel() -> void:
	_result_panel = PanelContainer.new()
	_result_panel.anchor_left = 0.05
	_result_panel.anchor_top = 0.18
	_result_panel.anchor_right = 0.95
	_result_panel.anchor_bottom = 0.90
	_result_panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("100c18", 0.94), Color("d7ad47"), 0, 0)
	)
	_result_panel.z_index = 50
	add_child(_result_panel)
	_add_frame_texture(_result_panel, PANEL_FRAME_PATH)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_top", 140)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_bottom", 140)
	_result_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "소환 결과"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ffe09a"))
	vbox.add_child(title)
	_result_summary = Label.new()
	_result_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_summary.add_theme_font_size_override("font_size", 24)
	_result_summary.add_theme_color_override("font_color", Color("e4cdec"))
	vbox.add_child(_result_summary)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var result_center := CenterContainer.new()
	result_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(result_center)

	_result_grid = GridContainer.new()
	_result_grid.columns = 4
	_result_grid.add_theme_constant_override("h_separation", 12)
	_result_grid.add_theme_constant_override("v_separation", 12)
	result_center.add_child(_result_grid)

	_confirm_button = Button.new()
	_confirm_button.custom_minimum_size = Vector2(0.0, 82.0)
	_confirm_button.text = "확인"
	_confirm_button.add_theme_font_size_override("font_size", 30)
	_confirm_button.add_theme_color_override("font_color", Color("fff1ba"))
	_confirm_button.add_theme_stylebox_override(
		"normal", _make_panel_style(Color("56316e"), Color("e1b94e"), 3, 18)
	)
	_confirm_button.add_theme_stylebox_override(
		"hover", _make_panel_style(Color("71408f"), Color("ffe16d"), 4, 18)
	)
	_confirm_button.add_theme_stylebox_override(
		"pressed", _make_panel_style(Color("3d254d"), Color("ffe16d"), 4, 18)
	)
	_confirm_button.pressed.connect(_confirm)
	_style_decorated_button(_confirm_button)
	vbox.add_child(_confirm_button)
