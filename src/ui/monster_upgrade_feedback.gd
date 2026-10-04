extends Node2D

# One clock drives portrait, light and copy without changing layout or hit regions.
const DURATION := 0.65
const GATHER_TIME := 0.09
var elapsed := DURATION
var level := 0
var _caption: Label
var _portrait: TextureRect
var _badge: Label
var _portrait_tint := Color.WHITE
var _portrait_scale := Vector2.ONE
var _portrait_pivot := Vector2.ZERO
var _badge_tint := Color.WHITE
var _center := Vector2.ZERO
var _radius := 38.0

func _ready() -> void:
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 21)
	_caption.add_theme_color_override("font_color", Color("fff0ad"))
	_caption.add_theme_color_override("font_outline_color", Color("261137"))
	_caption.add_theme_constant_override("outline_size", 4)
	add_child(_caption)
	stop()

func restart(new_level: int) -> void:
	stop()
	var card := get_parent() as Control
	_portrait = card.find_child("MonsterPortrait", true, false) as TextureRect
	_badge = card.find_child("UpgradeBadge", true, false) as Label
	if is_instance_valid(_portrait):
		_portrait_tint = _portrait.self_modulate
		_portrait_scale = _portrait.scale
		_portrait_pivot = _portrait.pivot_offset
	if is_instance_valid(_badge):
		_badge_tint = _badge.modulate
		# Alpha preserves layout, unlike hiding the badge.
		_badge.modulate.a = 0.0
	level = new_level
	elapsed = 0.0
	_caption.text = "강화 성공 · Lv.%d" % level
	show()
	set_process(true)
	_update_visuals()
	queue_redraw()

func stop() -> void:
	if is_instance_valid(_portrait):
		_portrait.self_modulate = _portrait_tint
		_portrait.scale = _portrait_scale
		_portrait.pivot_offset = _portrait_pivot
	if is_instance_valid(_badge):
		_badge.modulate = _badge_tint
	_portrait = null
	_badge = null
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
	_update_visuals()
	queue_redraw()

func _burst() -> float:
	return clampf((elapsed - GATHER_TIME) / (DURATION - GATHER_TIME), 0.0, 1.0)

func _pulse() -> float:
	if elapsed < GATHER_TIME:
		return elapsed / GATHER_TIME * 0.35
	return pow(1.0 - _burst(), 2.0)

func _update_visuals() -> void:
	var card := get_parent() as Control
	var inverse := card.get_global_transform().affine_inverse()
	var pulse := _pulse()
	_center = Vector2(card.size.x * 0.25, card.size.y * 0.35)
	if is_instance_valid(_portrait):
		# Follow the container's final bounds on the next frame.
		_center = inverse * (_portrait.get_global_transform() * (_portrait.size * 0.5))
		_radius = minf(_portrait.size.x, _portrait.size.y) * 0.40
		_portrait.pivot_offset = _portrait.size * 0.5
		_portrait.scale = _portrait_scale * (1.0 + 0.045 * pulse)
		_portrait.self_modulate = _portrait_tint * Color(1.0 + 0.7 * pulse, 1.0 + 0.5 * pulse, 1.0 + 0.2 * pulse)
	_caption.position = Vector2(8.0, 8.0)
	_caption.size = Vector2(maxf(card.size.x - 16.0, 0.0), 30.0)
	if is_instance_valid(_badge):
		_caption.position = inverse * _badge.global_position
		_caption.size = _badge.size
	_caption.position.y -= 3.0 * _burst()
	_caption.modulate.a = 0.0 if elapsed < GATHER_TIME else minf((1.0 - _burst()) * 2.2, 1.0)

func _draw() -> void:
	if elapsed >= DURATION:
		return
	var pulse := _pulse()
	var burst := _burst()
	var card := get_parent() as Control
	# Restrained light at the monster, not over the card's copy and buttons.
	for layer in range(4):
		draw_circle(_center, _radius * (0.65 + float(layer) * 0.14), Color(1.0, 0.75, 0.32, pulse * 0.035))
	if elapsed >= GATHER_TIME:
		draw_arc(_center, _radius * (0.65 + burst * 0.40), 0.0, TAU, 24,
			Color(1.0, 0.86, 0.45, pulse * 0.55), 2.0)
		draw_rect(Rect2(Vector2(3, 3), (card.size - Vector2(6, 6)).max(Vector2.ZERO)),
			Color(1.0, 0.84, 0.42, pulse * 0.5), false, 2.0)
	# Fixed pixel glints gather then release on the same beat as success copy.
	for index in range(6):
		var angle := TAU * float(index) / 6.0 - PI * 0.5
		var distance := lerpf(1.15, 0.60, elapsed / GATHER_TIME) if elapsed < GATHER_TIME else lerpf(0.60, 1.12, burst)
		var point := _center + Vector2.from_angle(angle) * _radius * distance
		var radius := 2.0 + 2.0 * pulse
		var color := Color(1.0, 0.94, 0.70, pulse * 0.9)
		draw_rect(Rect2(point - Vector2(radius, 1), Vector2(radius * 2.0, 2)), color)
		draw_rect(Rect2(point - Vector2(1, radius), Vector2(2, radius * 2.0)), color)
