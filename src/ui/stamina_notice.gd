extends RefCounted

const INSUFFICIENT := "스테미너가 부족합니다.\n로비에서 충전하거나 회복 후 다시 도전하세요."

static func show_notice(host: Node, message: String) -> AcceptDialog:
	# Kept outside result/pause VBox containers. Repeated failures only replace
	# the text; they never add rows, rebuild rewards or move action buttons.
	var panel := host.get_node_or_null("StaminaNotice") as AcceptDialog
	if panel == null:
		panel = AcceptDialog.new(); panel.name = "StaminaNotice"
		panel.process_mode = Node.PROCESS_MODE_ALWAYS
		panel.title = "도전 안내"; panel.dialog_autowrap = true
		panel.exclusive = true; panel.ok_button_text = "확인"
		panel.add_theme_font_size_override("font_size",28)
		var style := StyleBoxFlat.new(); style.bg_color = Color("160e24")
		style.border_color = Color("eac14d"); style.set_border_width_all(3)
		style.set_corner_radius_all(12); style.set_content_margin_all(24)
		panel.add_theme_stylebox_override("panel",style)
		var button := panel.get_ok_button(); button.custom_minimum_size.y = 84
		button.add_theme_font_size_override("font_size",28)
		for state in ["normal","hover","pressed"]: button.add_theme_stylebox_override(state,style)
		host.add_child(panel)
	panel.dialog_text = message
	if not panel.visible:
		var bounds := host.get_viewport().get_visible_rect().size
		panel.popup_centered(Vector2i(maxi(240,mini(700,int(bounds.x)-48)),maxi(180,mini(260,int(bounds.y)-48))))
	return panel
