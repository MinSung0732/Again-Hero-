extends Control

var player: Control
var _regions: Dictionary = {}

func _draw() -> void:
	if player == null or player._data.is_empty():
		return
	var stage_size: Vector2 = player._data.get("stage_size", Vector2(1280, 720))
	var stage: Rect2 = player.stage_rect(size, stage_size)
	var factor := stage.size.x / stage_size.x
	draw_set_transform(stage.position, 0.0, Vector2.ONE * factor)
	var t: float = player._elapsed
	var frame := int(t * float(player._data.effect_fps))
	_draw_frame(player._circle, frame, player._data.get("circle_rect", Rect2(410, 444, 460, 240)), 0.55 + 0.35 * sin(t * 4.0) ** 2, true)
	var strike := smoothstep(0.9, 1.12, t) * (1.0 - smoothstep(2.1, 2.75, t))
	_draw_frame(player._pillar, frame, player._data.get("pillar_rect", Rect2(390, 20, 500, 650)), strike * 0.65)
	var electric_alpha := (0.25 + 0.65 * smoothstep(0.4, 1.1, t)) * (1.0 - 0.75 * smoothstep(4.0, 4.8, t))
	_draw_frame(player._electric, frame, player._data.get("electric_left_rect", Rect2(220, 325, 340, 290)), electric_alpha)
	_draw_frame(player._electric, frame + 3, player._data.get("electric_right_rect", Rect2(750, 300, 340, 290)), electric_alpha)

static func fitted_rect(region_size: Vector2, box: Rect2) -> Rect2:
	var factor := minf(box.size.x / region_size.x, box.size.y / region_size.y)
	var extent := region_size * factor
	return Rect2(box.position + (box.size - extent) * 0.5, extent)

func _draw_frame(frames: Array[Texture2D], index: int, rect: Rect2, alpha: float, ground_perspective: bool = false) -> void:
	if frames.is_empty() or alpha <= 0.0:
		return
	var texture := frames[index % frames.size()]
	var key := frames[0].get_instance_id()
	if not _regions.has(key):
		var common := Rect2()
		for frame_texture in frames:
			var image := frame_texture.get_image()
			var used := Rect2(image.get_used_rect()) if image != null else Rect2(Vector2.ZERO, frame_texture.get_size())
			if used.has_area():
				common = common.merge(used) if common.has_area() else used
		_regions[key] = common
	var region: Rect2 = _regions[key]
	if region.size.x <= 0 or region.size.y <= 0:
		return
	# Only a ground circle uses intentional perspective; lightning stays proportional.
	var destination := rect if ground_perspective else fitted_rect(region.size, rect)
	draw_texture_rect_region(texture, destination, region, Color(1, 1, 1, alpha))
