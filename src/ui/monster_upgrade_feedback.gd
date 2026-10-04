extends Node2D

# A single reusable, input-transparent decoration. Never changes card minimum size.
const DURATION := 0.65
var elapsed := DURATION
var level := 0
var _caption: Label

func _ready() -> void:
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 24)
	_caption.add_theme_color_override("font_color", Color("fff0ad"))
	_caption.add_theme_color_override("font_outline_color", Color("261137"))
	_caption.add_theme_constant_override("outline_size", 5)
	add_child(_caption)
	stop()

func restart(new_level: int) -> void:
	level = new_level
	elapsed = 0.0
	_caption.text = "강화! Lv.%d" % level
	show()
	set_process(true)
	_update_caption()
	queue_redraw()

func stop() -> void:
	elapsed = DURATION
	hide()
	set_process(false)

func _process(delta: float) -> void:
	if not (get_parent() as CanvasItem).is_visible_in_tree():
		stop()
		return
	elapsed = minf(elapsed + delta, DURATION)
	if elapsed >= DURATION:
		stop()
		return
	_update_caption()
	queue_redraw()

func _update_caption() -> void:
	var card := get_parent() as Control
	var progress := elapsed / DURATION
	_caption.position = Vector2(6.0, 10.0 - 4.0 * progress)
	_caption.size = Vector2(maxf(card.size.x - 12.0, 0.0), 36.0)
	_caption.modulate.a = minf((1.0 - progress) * 2.0, 1.0)

func _draw() -> void:
	if elapsed >= DURATION:
		return
	var card := get_parent() as Control
	if card == null:
		return
	var progress := elapsed / DURATION
	var fade := 1.0 - progress
	var bounds := Rect2(Vector2(4, 4), (card.size - Vector2(8, 8)).max(Vector2.ZERO))
	draw_rect(bounds, Color(1.0, 0.82, 0.35, fade * 0.12))
	draw_rect(bounds, Color(1.0, 0.86, 0.42, fade * 0.9), false, 3.0)
	# Use the badge strip, not the portrait/info rows, for the temporary level copy.
	draw_rect(Rect2(_caption.position, _caption.size),
		Color(0.13, 0.07, 0.19, minf(fade * 2.0, 1.0)))
	# Fixed tiny pixel crosses rise around the portrait, entirely within the card.
	for index in range(7):
		var fraction := float(index) / 6.0
		var point := Vector2(14.0 + fraction * maxf(card.size.x - 28.0, 0.0),
			card.size.y * (0.24 + 0.12 * sin(float(index) * 2.4)) - progress * 18.0)
		var radius := 3.0 + 3.0 * sin(progress * PI)
		var color := Color(1.0, 0.92, 0.65, fade)
		draw_rect(Rect2(point - Vector2(radius, 1.5), Vector2(radius * 2.0, 3.0)), color)
		draw_rect(Rect2(point - Vector2(1.5, radius), Vector2(3.0, radius * 2.0)), color)
