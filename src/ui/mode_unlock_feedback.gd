extends CanvasLayer

signal dismissed
var ready_to_close := false
var confirm: Button

class OpeningLock extends Control:
	var openness := 0.0:
		set(value):
			openness = value
			queue_redraw()
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0, Vector2(2, 2))
		var gold := Color("f4cc71")
		draw_arc(Vector2(32 - openness * 7, 26 - openness * 14), 16, PI, TAU - openness * 0.5, 18, gold, 7)
		draw_rect(Rect2(8, 28, 48, 36), Color("755025"))
		draw_rect(Rect2(11, 31, 42, 30), gold)
		draw_rect(Rect2(14, 33, 36, 4), Color("fff0b0"))
		draw_circle(Vector2(32, 43), 5, Color("251432"))
		draw_rect(Rect2(30, 43, 4, 10), Color("251432"))
		if openness > 0.4:
			for point in [Vector2(3, 10), Vector2(62, 18), Vector2(59, 62)]:
				draw_line(point - Vector2(4, 0), point + Vector2(4, 0), Color("fff1ac"), 2)
				draw_line(point - Vector2(0, 4), point + Vector2(0, 4), Color("fff1ac"), 2)

func present(heading: String, description: String) -> void:
	layer = 160
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.01, 0.045, 0.82)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	dim.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 790
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d102e")
	style.border_color = Color("f2cc71")
	style.set_border_width_all(3)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 30)
	panel.add_child(column)
	var title := Label.new()
	title.text = heading + " 개방!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("ffdf91"))
	column.add_child(title)
	var lock_area := CenterContainer.new()
	lock_area.custom_minimum_size.y = 180
	column.add_child(lock_area)
	var lock := OpeningLock.new()
	lock.custom_minimum_size = Vector2(128, 160)
	lock_area.add_child(lock)
	var body := Label.new()
	body.text = description + "\n새로운 도전의 문이 열렸습니다."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 28)
	column.add_child(body)
	confirm = Button.new()
	confirm.text = "확인"
	confirm.custom_minimum_size.y = 88
	confirm.add_theme_font_size_override("font_size", 30)
	var button_style := style.duplicate() as StyleBoxFlat
	button_style.bg_color = Color("58247b")
	for state in ["normal", "hover", "pressed", "disabled"]:
		confirm.add_theme_stylebox_override(state, button_style)
	column.add_child(confirm)
	confirm.disabled = true
	confirm.pressed.connect(close)
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(lock, "openness", 1.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.3)
	tween.tween_callback(func(): ready_to_close = true; confirm.disabled = false)

func close() -> void:
	if not ready_to_close:
		return
	dismissed.emit()
	queue_free()
