extends RefCounted
## Bounded scrolling content; buttons remain outside the content minimum size.
static func install(host: Control, reward: Label, status: Label, repeat: Label, entry: Button) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "StageEntryInfo"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(scroll)
	scroll.anchor_left = 0.06
	scroll.anchor_right = 0.94
	scroll.anchor_top = 0.28
	scroll.anchor_bottom = 0.60
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	scroll.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",12)
	margin.add_child(rows)
	move_label(reward,rows)
	var divider := HSeparator.new()
	rows.add_child(divider)
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation",16)
	rows.add_child(details)
	move_label(status,details)
	move_label(repeat,details)
	status.size_flags_stretch_ratio = 1.0
	repeat.size_flags_stretch_ratio = 1.0
	reward.add_theme_color_override("font_color",Color("ffe399"))
	var resize := fit.bind(host,scroll,entry)
	host.resized.connect(resize)
	resize.call_deferred()

static func move_label(label: Label, parent: Container) -> void:
	if label.get_parent() != null: label.get_parent().remove_child(label)
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
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

static func fit(host: Control, scroll: ScrollContainer, entry: Button) -> void:
	# The real button minimum must be reserved before sizing the scroll viewport.
	var bottom := host.size.y*0.79
	var height := maxf(entry.get_combined_minimum_size().y,host.size.y*0.15)
	var top := maxf(bottom-height,0.0)
	entry.anchor_top = 0.0
	entry.anchor_bottom = 0.0
	entry.offset_top = top
	entry.offset_bottom = top+height
	scroll.anchor_bottom = 0.0
	scroll.offset_bottom = maxf(host.size.y*0.28,minf(host.size.y*0.60,top-10.0))
