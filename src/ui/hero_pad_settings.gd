extends RefCounted
## Shared hero-mode movement-pad settings row.
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")

static func install(gameplay: Control, selected: Callable) -> OptionButton:
	var pad_row := HBoxContainer.new(); pad_row.name = "PadModeRow"
	pad_row.add_theme_constant_override("separation",16); gameplay.add_child(pad_row)
	var label := Label.new(); label.text = "이동 패드"; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",23); label.add_theme_color_override("font_color",Color("e5ead4"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.custom_minimum_size.x = 165; pad_row.add_child(label)
	var selector := OptionButton.new(); selector.name = "PadMode"
	selector.custom_minimum_size.y = 88; selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_theme_font_size_override("font_size",30)
	selector.add_item("고정형 패드",0); selector.add_item("자유형 패드",1)
	var style := StyleBoxFlat.new(); style.bg_color = Color("223d50"); style.border_color = Color("c9a45e")
	style.set_border_width_all(2); style.set_content_margin_all(10)
	for state in ["normal","hover","pressed","disabled"]: selector.add_theme_stylebox_override(state,SKIN.skin_style(style))
	selector.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	selector.add_theme_color_override("font_color",Color("efe5c9")); pad_row.add_child(selector)
	var popup := selector.get_popup()
	popup.add_theme_font_size_override("font_size",32)
	popup.add_theme_constant_override("v_separation",64)
	popup.add_theme_stylebox_override("panel",DETAIL.style(Color("20192e"),Color("dfb86a"),16))
	popup.add_theme_color_override("font_color",Color("efe5ce"))
	popup.add_theme_color_override("font_hover_color",Color("ffda86"))
	selector.item_selected.connect(selected)
	var guide := Label.new(); guide.text = "고정형: 하단 중앙 · 자유형: 전투 화면 터치 위치\n변경 즉시 적용 · 자동 저장"
	guide.name = "PadGuide"; guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.add_theme_font_size_override("font_size",18); guide.add_theme_color_override("font_color",Color("e5ead4"))
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE; gameplay.add_child(guide)
	return selector
