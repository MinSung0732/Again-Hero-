extends Control

var player: Control

func _draw() -> void:
	if player == null or player._data.is_empty():
		return
	var stage: Rect2 = player.stage_rect(size)
	var factor := stage.size.x / 1280.0
	draw_set_transform(stage.position, 0.0, Vector2.ONE * factor)
	var t: float = player._elapsed
	var frame := int(t * float(player._data.effect_fps))
	_draw_frame(player._circle, frame, Rect2(410, 444, 460, 240), 0.7)
	var strike := smoothstep(0.9, 1.12, t) * (1.0 - smoothstep(2.1, 2.75, t))
	_draw_frame(player._pillar, frame, Rect2(390, 20, 500, 650), strike)
	var electric_alpha := (0.25 + 0.65 * smoothstep(0.4, 1.1, t)) * (1.0 - 0.75 * smoothstep(4.0, 4.8, t))
	_draw_frame(player._electric, frame, Rect2(220, 325, 340, 290), electric_alpha)
	_draw_frame(player._electric, frame + 3, Rect2(750, 300, 340, 290), electric_alpha)

func _draw_frame(frames: Array[Texture2D], index: int, rect: Rect2, alpha: float) -> void:
	if not frames.is_empty() and alpha > 0.0:
		draw_texture_rect(frames[index % frames.size()], rect, false, Color(1, 1, 1, alpha))
