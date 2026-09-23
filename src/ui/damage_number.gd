extends Node2D

const LIFETIME := 0.72
const RISE_DISTANCE := 78.0
const FADE_START := 0.52
const MERGE_WINDOW := 0.11

@onready var value_label: Label = $Value

var elapsed: float = 0.0
var start_position: Vector2 = Vector2.ZERO
var horizontal_drift: float = 0.0
var numeric_amount: int = 0
var is_numeric: bool = false

func setup(amount: int, text_color: Color = Color.WHITE) -> void:
	numeric_amount = maxi(amount, 0)
	is_numeric = true
	value_label.text = str(numeric_amount)
	value_label.add_theme_font_size_override("font_size", 32)
	value_label.add_theme_color_override("font_color", text_color)
	_start_float()

func setup_text(
	message: String,
	text_color: Color = Color(1.0, 0.58, 0.42, 1.0)
) -> void:
	is_numeric = false
	value_label.text = message
	value_label.add_theme_font_size_override("font_size", 23)
	value_label.add_theme_color_override("font_color", text_color)
	_start_float()

func can_merge_damage() -> bool:
	return is_numeric and elapsed <= MERGE_WINDOW and not is_queued_for_deletion()

func add_damage(amount: int, text_color: Color = Color.WHITE) -> void:
	if not can_merge_damage():
		return
	numeric_amount += maxi(amount, 0)
	value_label.text = str(numeric_amount)
	value_label.add_theme_color_override("font_color", text_color)
	elapsed = minf(elapsed, MERGE_WINDOW * 0.35)
	scale = Vector2.ONE * 1.08

func _start_float() -> void:
	elapsed = 0.0
	start_position = position
	horizontal_drift = randf_range(-10.0, 10.0)
	scale = Vector2(0.85, 0.85)

func _process(delta: float) -> void:
	elapsed += delta
	var progress := clampf(elapsed / LIFETIME, 0.0, 1.0)

	position = start_position + Vector2(
		horizontal_drift * progress,
		-RISE_DISTANCE * progress
	)

	var pop_scale := 1.0
	if progress < 0.18:
		pop_scale = lerpf(0.85, 1.08, progress / 0.18)
	else:
		pop_scale = lerpf(1.08, 1.0, (progress - 0.18) / 0.82)
	scale = Vector2.ONE * pop_scale

	if progress > FADE_START:
		modulate.a = 1.0 - (
			(progress - FADE_START) / (1.0 - FADE_START)
		)

	if elapsed >= LIFETIME:
		queue_free()
