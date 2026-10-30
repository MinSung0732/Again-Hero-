extends PanelContainer
const PIXEL := preload("res://src/ui/pixel_panel_skin.gd")
const RIGHT_INSET := 178.0
const VERTICAL_PADDING := 8.0
var title := Label.new()
var advice := Label.new()
var detail_button: Button
func install(hud: Node,open_details: Callable) -> void:
	name = "CombatInsight"
	hud.add_child(self)
	# GUI hit testing follows sibling order, independently of drawing z_index.
	# Keep this background shortcut behind the existing detail panels and modals.
	hud.move_child(self,0)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 18; offset_right = -RIGHT_INSET; offset_top = 340; offset_bottom = 414
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21182f"); style.border_color = Color("89739e"); style.set_border_width_all(1)
	style.content_margin_left = 12; style.content_margin_right = 12; style.content_margin_top = VERTICAL_PADDING; style.content_margin_bottom = VERTICAL_PADDING
	add_theme_stylebox_override("panel",PIXEL.skin_style(style))
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation",0); add_child(rows)
	for label in [title,advice]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size",22 if label == title else 20)
		label.add_theme_color_override("font_color",Color("ffe09a") if label == title else Color("eee8f5"))
		rows.add_child(label)
	var tap := Button.new(); tap.flat = true; tap.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND; add_child(tap)
	detail_button = tap
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.tooltip_text = "용사의 선택과 현재 빌드 보기"
	for state in ["normal","hover","pressed","focus"]: tap.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	tap.pressed.connect(open_details)
func update_copy(headline: String,hint: String) -> void:
	if title.text != headline: title.text = headline
	if advice.text != hint: advice.text = hint
func update_details(copy: String) -> void:
	if is_instance_valid(detail_button): detail_button.tooltip_text = copy+"\n눌러서 현재 용사 빌드 보기"
