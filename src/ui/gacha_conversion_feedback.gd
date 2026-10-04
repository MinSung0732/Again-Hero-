extends Node2D

# Presentation only: rewards were committed before opening the gacha sequence.
const WAIT := 0.55
const DURATION := 0.55
var points := 0
var elapsed := -WAIT
var amount_label: Label
var icon: TextureRect
var _stamp: Node2D
var _label: Label

func _ready() -> void:
	_stamp = Node2D.new()
	_stamp.rotation = -PI / 8.0
	_stamp.modulate.a = 0.0
	add_child(_stamp)
	_label = Label.new()
	_label.text = "변환"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-64, -19)
	_label.size = Vector2(128, 38)
	_label.add_theme_font_size_override("font_size", 25)
	_label.add_theme_color_override("font_color", Color("fff0b4"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("38184f", 0.96)
	style.border_color = Color("e3bd62")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	_label.add_theme_stylebox_override("normal", style)
	_stamp.add_child(_label)

func _process(delta: float) -> void:
	if not (get_parent() as CanvasItem).is_visible_in_tree():
		set_process(false)
		return
	elapsed += delta
	var card := get_parent() as Control
	_stamp.position = card.get_global_transform().affine_inverse() * (icon.get_global_transform() * (icon.size * 0.5))
	if elapsed < 0.0:
		return
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	_stamp.modulate.a = minf(progress * 7.0, 1.0)
	_stamp.scale = Vector2.ONE * (1.0 + 0.25 * pow(1.0 - progress, 3.0))
	icon.self_modulate = Color.WHITE.lerp(Color("81728d"), minf(progress * 2.0, 1.0))
	if progress >= 0.6:
		amount_label.text = "연구 +%d P" % points
		amount_label.add_theme_color_override("font_color", Color("d7b5ff"))
	queue_redraw()
	if progress >= 1.0:
		set_process(false)

func _draw() -> void:
	if elapsed < 0.0 or elapsed >= DURATION:
		return
	var fade := 1.0 - elapsed / DURATION
	for index in range(4):
		var direction := Vector2.from_angle(PI * 0.25 + float(index) * PI * 0.5)
		var point := _stamp.position + direction * (36.0 + elapsed * 40.0)
		draw_line(point - direction * 3.0, point + direction * 3.0, Color(1.0, 0.86, 0.55, fade), 2.0)
