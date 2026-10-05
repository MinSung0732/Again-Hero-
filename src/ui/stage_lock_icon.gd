extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func _draw() -> void:
	draw_arc(Vector2(32,28),18,PI,TAU,24,Color("f4cc71"),8)
	draw_style_box(_body(),Rect2(6,28,52,46))
	draw_circle(Vector2(32,47),6,Color("241529"))
	draw_rect(Rect2(29,47,6,13),Color("241529"))

func _body() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4cc71")
	style.border_color = Color("7e502a")
	style.set_border_width_all(3)
	return style
