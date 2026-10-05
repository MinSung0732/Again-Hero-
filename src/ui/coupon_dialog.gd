extends RefCounted

func install(lobby: Control) -> void:
	var button := Button.new()
	button.name = "CouponButton"
	button.text = "쿠폰 입력"
	button.custom_minimum_size.y = 82
	button.add_theme_font_size_override("font_size", 30)
	lobby.other_account_panel.add_child(button)
	var overlay := ColorRect.new()
	overlay.name = "CouponOverlay"
	overlay.color = Color(0,0,0,0.78)
	lobby.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	var panel := PanelContainer.new()
	panel.name = "Panel"
	overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -245
	panel.offset_bottom = 245
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,32)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",26)
	margin.add_child(box)
	var title := Label.new()
	title.text = "쿠폰 입력"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	box.add_child(title)
	var entry := LineEdit.new()
	entry.name = "CouponNumber"
	entry.placeholder_text = "쿠폰 번호를 입력하세요"
	entry.custom_minimum_size.y = 85
	entry.max_length = 64
	entry.add_theme_font_size_override("font_size",30)
	box.add_child(entry)
	var notice := Label.new()
	notice.name = "Notice"
	notice.text = "normaltest는 진행도를 초기화합니다."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size",25)
	box.add_child(notice)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	box.add_child(row)
	var close := Button.new()
	close.text = "취소"
	close.add_theme_font_size_override("font_size",30)
	for state in ["normal","hover","pressed","disabled"]:
		close.add_theme_stylebox_override(state,lobby.secondary_button_style)
	close.custom_minimum_size.y = 80
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(close)
	var submit := Button.new()
	submit.name = "Submit"
	submit.text = "적용"
	submit.add_theme_font_size_override("font_size",30)
	for state in ["normal","hover","pressed","disabled"]:
		submit.add_theme_stylebox_override(state,lobby.primary_button_style)
	submit.custom_minimum_size.y = 80
	submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(submit)
	button.pressed.connect(func(): overlay.show(); entry.clear(); entry.grab_focus())
	close.pressed.connect(overlay.hide)
	submit.pressed.connect(func():
		var code := entry.text.strip_edges().to_lower()
		if code not in ["localtest","normaltest"]:
			notice.text = "사용할 수 없는 쿠폰입니다."
			return
		submit.disabled = true
		close.disabled = true
		notice.text = "저장 확인 및 모드 전환 중…"
		if not await lobby.get_node("/root/LocalTestMode").apply_coupon(code):
			notice.text = "전환 실패 · 저장/동기화 상태를 확인하고 다시 시도하세요."
			submit.disabled = false
			close.disabled = false
			return
		lobby.get_tree().change_scene_to_file("res://src/startup/Startup.tscn")
	)
	var skin := preload("res://src/ui/pixel_panel_skin.gd")
	button.add_theme_stylebox_override("normal", lobby.primary_button_style)
	panel.add_theme_stylebox_override("panel", lobby.panel_style)
	skin.apply_tree(overlay)
	skin.apply(button)
