extends RefCounted
## Hero-only battle visuals preferences. Keep shared BattleSettings.tscn unchanged.
## The original gameplay controls are moved into a scrollable column so the
## mobile settings panel remains usable after adding new rows.

static func install(gameplay: VBoxContainer, example_slider: HSlider, example_toggle: CheckBox, on_transparency: Callable, on_range: Callable) -> Dictionary:
	var existing := gameplay.get_children()
	var scroll := ScrollContainer.new()
	scroll.name = "HeroGameplayScroll"
	scroll.custom_minimum_size = Vector2(0,300)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",20)
	for child in existing:
		gameplay.remove_child(child)
		rows.add_child(child)
	gameplay.add_child(scroll)
	scroll.add_child(rows)

	var opacity_row := HBoxContainer.new()
	opacity_row.name = "EffectTransparencyRow"
	opacity_row.custom_minimum_size.y = 70
	opacity_row.add_theme_constant_override("separation",12)
	rows.add_child(opacity_row)
	var caption := Label.new()
	caption.text = "자신 이펙트 투명도"
	caption.custom_minimum_size.x = 230
	caption.add_theme_font_size_override("font_size",21)
	caption.add_theme_color_override("font_color",Color("f5eaff"))
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opacity_row.add_child(caption)

	var slider := HSlider.new()
	slider.name = "TransparencySlider"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 0.0
	slider.custom_minimum_size.y = 52
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for style in ["slider","grabber_area","grabber_area_highlight"]:
		slider.add_theme_stylebox_override(style,example_slider.get_theme_stylebox(style))
	for icon in ["grabber","grabber_highlight","grabber_disabled"]:
		slider.add_theme_icon_override(icon,example_slider.get_theme_icon(icon))
	opacity_row.add_child(slider)
	var amount := Label.new()
	amount.name = "TransparencyValue"
	amount.text = "0%"
	amount.custom_minimum_size.x = 75
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size",23)
	amount.add_theme_color_override("font_color",Color("f6c44d"))
	opacity_row.add_child(amount)
	slider.value_changed.connect(on_transparency)

	var guide := Label.new()
	guide.name = "EffectTransparencyGuide"
	guide.text = "0%: 선명하게 · 100%: 이펙트 숨김"
	guide.add_theme_font_size_override("font_size",18)
	guide.add_theme_color_override("font_color",Color("c0b5d1"))
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(guide)

	var range_toggle := CheckBox.new()
	range_toggle.name = "AttackRangeVisible"
	range_toggle.text = "공격 범위 표시"
	range_toggle.button_pressed = true
	range_toggle.custom_minimum_size.y = 72
	range_toggle.add_theme_font_size_override("font_size",24)
	range_toggle.add_theme_color_override("font_color",Color("f5eaff"))
	for icon in ["checked","unchecked","checked_disabled","unchecked_disabled"]:
		range_toggle.add_theme_icon_override(icon,example_toggle.get_theme_icon(icon))
	rows.add_child(range_toggle)
	range_toggle.toggled.connect(on_range)
	var range_guide := Label.new()
	range_guide.text = "공격 범위 안내선만 표시하거나 숨깁니다.\n판정은 그대로 유지 · 변경 즉시 적용 · 자동 저장"
	range_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	range_guide.add_theme_font_size_override("font_size",18)
	range_guide.add_theme_color_override("font_color",Color("c0b5d1"))
	rows.add_child(range_guide)
	return {
		"camera":rows.get_node("CameraLock"),
		"battle_frame":rows.get_node("BattleFrame"),
		"transparency_slider":slider,
		"transparency_value":amount,
		"range_checkbox":range_toggle,
		"scroll":scroll
	}
