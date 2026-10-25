extends RefCounted

const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const GAME_THEME := preload("res://src/ui/game_theme.tres")

const NEXT_COLOR := "#75dc85"
const LABEL_COLOR := "#c9bfd8"
# Default sizes per surface keep the line close to the card description size.
const SOLO_DEMON_FONT := 18
const SOLO_HERO_FONT := 20
const ONLINE_FONT := 19

static func add(parent: Control, rows: Array, font_size: int = 17, centered: bool = false) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.name = "AugmentCompare"
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size",font_size)
	if centered: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	update(label,rows)
	return label

const MAX_CARD_ROWS := 4

static func meaningful_rows(rows: Array) -> Array[Dictionary]:
	var valid: Array[Dictionary] = []
	for raw in rows:
		if not raw is Dictionary: continue
		var current := String(raw.get("current",""))
		var next := String(raw.get("next",""))
		if current == next: continue
		if current == "없음" and _is_zero(next): continue
		valid.append(raw)
	return valid

static func _is_zero(value: String) -> bool:
	var number := value.strip_edges().trim_prefix("+")
	for suffix in ["%","초","개","발"]:
		number = number.trim_suffix(suffix)
	return number.is_valid_float() and is_zero_approx(number.to_float())

static func _lines(rows: Array, limit: int = -1) -> Array[String]:
	var lines: Array[String] = []
	for row in meaningful_rows(rows):
		if limit >= 0 and lines.size() >= limit: break
		var stat := _safe(String(row.get("label","")))
		var current := String(row.get("current",""))
		var next := _safe(String(row.get("next","")))
		if current == "없음":
			lines.append("[color=%s]%s[/color] [color=%s]%s · 신규[/color]" % [LABEL_COLOR,stat,NEXT_COLOR,next])
		else:
			lines.append("[color=%s]%s[/color] %s → [color=%s]%s[/color]" % [LABEL_COLOR,stat,_safe(current),NEXT_COLOR,next])
	return lines

static func update(label: RichTextLabel, rows: Array) -> void:
	label.text = "\n".join(_lines(rows,MAX_CARD_ROWS))
	label.visible = not label.text.is_empty()

# Separate STOP input prevents details from selecting the enclosing card.
static func details(parent: Control, candidate: Dictionary) -> Button:
	var button := parent.get_node_or_null("AugmentDetails") as Button
	if button == null:
		button = Button.new()
		button.name = "AugmentDetails"
		button.text = "상세 보기"
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size",20)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		parent.add_child(button)
		button.pressed.connect(func(): _open_details(button))
	button.set_meta("candidate",candidate.duplicate(true))
	return button

static func _open_details(button: Button) -> void:
	var candidate: Dictionary = button.get_meta("candidate",{})
	var dialog := PopupPanel.new()
	dialog.name = "AugmentDetailsPopup"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.exclusive = true
	dialog.theme = GAME_THEME
	button.add_child(dialog)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("281832")
	panel_style.border_color = Color("d9b45b")
	panel_style.set_border_width_all(3)
	panel_style.set_content_margin_all(28)
	dialog.add_theme_stylebox_override("panel",SKIN.skin_style(panel_style))
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation",24)
	dialog.add_child(content)
	var title := Label.new()
	title.name = "Title"
	title.text = String(candidate.get("name","증강 상세"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("efe5c9"))
	content.add_child(title)
	var body := RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size",24)
	body.add_theme_color_override("default_color",Color("e5ead4"))
	body.text = _safe(String(candidate.get("description","")))
	var rows: Array = candidate.get("compare",[])
	var lines := _lines(rows)
	if not lines.is_empty(): body.text += "\n\n" + "\n".join(lines)
	content.add_child(body)
	var close := Button.new()
	close.name = "Close"
	close.text = "닫기"
	close.custom_minimum_size.y = 84
	close.add_theme_font_size_override("font_size",26)
	for state in ["normal","hover","pressed","disabled"]:
		var style := panel_style.duplicate() as StyleBoxFlat
		style.bg_color = Color("45304f") if state in ["hover","pressed"] else Color("281832")
		close.add_theme_stylebox_override(state,SKIN.button_style(style))
	close.add_theme_color_override("font_color",Color("efe5c9"))
	content.add_child(close)
	close.pressed.connect(dialog.hide)
	dialog.close_requested.connect(dialog.hide)
	dialog.popup_hide.connect(dialog.queue_free)
	var viewport_size := button.get_viewport_rect().size
	dialog.popup_centered(Vector2i(minf(760,viewport_size.x-48),minf(900,viewport_size.y-120)))
	close.grab_focus()

static func _safe(value: String) -> String:
	return value.replace("[","［").replace("]","］")
