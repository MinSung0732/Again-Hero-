extends Control
## Eight stepped pixels keep moving even when a save pauses the game.
var step := 0
var _timer: Timer
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer = Timer.new()
	_timer.wait_time = 0.12
	_timer.timeout.connect(func(): step = (step + 1) % 8; queue_redraw())
	add_child(_timer)
	visibility_changed.connect(_sync)
	_sync()
func _sync() -> void:
	if is_visible_in_tree(): _timer.start()
	else: _timer.stop()
func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.34
	for index in 8:
		var angle := float(index) * TAU / 8.0
		var point := (size * 0.5 + Vector2(cos(angle), sin(angle)) * radius).round()
		var age := (step - index + 8) % 8
		draw_rect(Rect2(point - Vector2(4,4), Vector2(8,8)), Color("e7c3ff") if age == 0 else Color(0.58,0.3,0.8,0.85-float(age)*0.09))
