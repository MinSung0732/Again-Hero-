extends RefCounted

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

static func update(label: RichTextLabel, rows: Array) -> void:
	var valid: Array[Dictionary] = []
	for raw_row in rows:
		if raw_row is Dictionary: valid.append(raw_row)
	var lines: Array[String] = []
	if valid.size() == 1:
		# One stat: stacked lines read well even on narrow cards.
		var row := valid[0]
		var stat := _safe(String(row.get("label","")))
		if not stat.is_empty(): lines.append("[color=%s]%s[/color]" % [LABEL_COLOR,stat])
		lines.append("현재 수치: %s" % _safe(String(row.get("current",""))))
		lines.append("[color=%s]강화 수치: %s[/color]" % [NEXT_COLOR,_safe(String(row.get("next","")))])
	else:
		# Several stats: one compact line each so the card does not scroll.
		for row in valid:
			lines.append("[color=%s]%s[/color] %s → [color=%s]%s[/color]" % [LABEL_COLOR,_safe(String(row.get("label",""))),_safe(String(row.get("current",""))),NEXT_COLOR,_safe(String(row.get("next","")))])
	label.text = "\n".join(lines)
	label.visible = not lines.is_empty()

static func _safe(value: String) -> String:
	return value.replace("[","［").replace("]","］")
