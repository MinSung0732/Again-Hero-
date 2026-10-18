extends RefCounted
## A retained wallet display beside the existing upgrade action.
static func install(balance: Label, cost: Label) -> void:
	var action := cost.get_parent() as HBoxContainer
	var panel := PanelContainer.new()
	panel.name = "ResearchWallet"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21172d")
	style.border_color = Color("caa253")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style)
	action.add_child(panel)
	action.move_child(panel,0)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",4)
	panel.add_child(rows)
	var caption := Label.new()
	caption.text = "보유 연구 포인트"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",24)
	caption.add_theme_color_override("font_color",Color("d8cadf"))
	rows.add_child(caption)
	for label in [balance,cost]:
		label.get_parent().remove_child(label)
		rows.add_child(label)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = false
	balance.add_theme_font_size_override("font_size",40)
	balance.add_theme_color_override("font_color",Color("ffe399"))
	cost.add_theme_font_size_override("font_size",26)
	cost.add_theme_color_override("font_color",Color("e8dcec"))
