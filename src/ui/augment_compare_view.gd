extends RefCounted

const NEXT_COLOR := "#75dc85"

static func add(parent: Control, rows: Array, font_size: int = 17) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.name = "AugmentCompare"
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size",font_size)
	parent.add_child(label)
	update(label,rows)
	return label

static func update(label: RichTextLabel, rows: Array) -> void:
	var lines: Array[String] = []
	for raw_row in rows:
		if not raw_row is Dictionary: continue
		var row: Dictionary = raw_row
		lines.append("%s 현재 수치: %s → [color=%s]강화 수치: %s[/color]" % [_safe(String(row.get("label",""))),_safe(String(row.get("current",""))),NEXT_COLOR,_safe(String(row.get("next","")))])
	label.text = "\n".join(lines)
	label.visible = not lines.is_empty()

static func _safe(value: String) -> String:
	return value.replace("[","［").replace("]","］")
