extends RefCounted
## One layout owns every vertical boundary. Only the reading area scrolls.
static func install(host: Control, description: Label, reward: Label, status: Label, repeat: Label, entry: Button) -> PanelContainer:
	var margin := MarginContainer.new()
	margin.name = "StageEntryLayout"
	host.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.grow_horizontal = Control.GROW_DIRECTION_END
	margin.grow_vertical = Control.GROW_DIRECTION_END
	for side in ["left","right"]:
		margin.add_theme_constant_override("margin_"+side,12)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	margin.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.name = "StageEntryInfo"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	layout.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12)
	scroll.add_child(rows)
	move_label(description,card(rows))
	var rewards := card(rows)
	move_label(reward,rewards)
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation",16)
	rewards.add_child(HSeparator.new())
	rewards.add_child(details)
	move_label(status,details)
	move_label(repeat,details)
	reward.add_theme_color_override("font_color",Color("ffe399"))
	if entry.get_parent() != null: entry.get_parent().remove_child(entry)
	layout.add_child(entry)
	entry.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	entry.grow_horizontal = Control.GROW_DIRECTION_END
	entry.grow_vertical = Control.GROW_DIRECTION_END
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.custom_minimum_size.y = 76
	var modes := PanelContainer.new()
	modes.name = "ModeSelectorTray"
	modes.custom_minimum_size.y = 72
	layout.add_child(modes)
	return modes

static func card(parent: VBoxContainer) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21152d")
	style.border_color = Color("785b83")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",10)
	panel.add_child(rows)
	return rows

static func move_label(label: Label, parent: Container) -> void:
	if label.get_parent() != null: label.get_parent().remove_child(label)
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	label.grow_horizontal = Control.GROW_DIRECTION_END
	label.grow_vertical = Control.GROW_DIRECTION_END
	label.custom_minimum_size = Vector2.ZERO
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.max_lines_visible = -1
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",22)
