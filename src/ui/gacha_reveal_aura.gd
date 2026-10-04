extends Control
class_name GachaRevealAura

var accent := Color.WHITE


func set_accent(color: Color) -> void:
	accent = color
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var center := size * Vector2(0.5, 0.46)
	var radius := minf(size.x * 0.46, size.y * 0.48)
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var ray := PackedVector2Array([
			center,
			center + Vector2.from_angle(angle - 0.045) * radius,
			center + Vector2.from_angle(angle + 0.045) * radius,
		])
		draw_colored_polygon(ray, Color(accent, 0.10))
	var circle_center := center + Vector2(0.0, radius * 0.72)
	for ring_index in range(3):
		var ring := PackedVector2Array()
		var ring_radius := radius * (0.70 + float(ring_index) * 0.10)
		for point_index in range(49):
			var direction := Vector2.from_angle(TAU * float(point_index) / 48.0)
			ring.append(circle_center + direction * Vector2(ring_radius, ring_radius * 0.19))
		draw_polyline(ring, Color(accent, 0.40), 2.0)
	for index in range(7):
		var angle := TAU * float(index) / 7.0 - 0.45
		var star_center := center + Vector2.from_angle(angle) * radius * 0.78
		var extent := 9.0 if index % 2 == 0 else 5.0
		var star := PackedVector2Array([
			star_center + Vector2(0.0, -extent * 1.8),
			star_center + Vector2(extent * 0.3, -extent * 0.3),
			star_center + Vector2(extent, 0.0),
			star_center + Vector2(extent * 0.3, extent * 0.3),
			star_center + Vector2(0.0, extent * 1.8),
			star_center + Vector2(-extent * 0.3, extent * 0.3),
			star_center + Vector2(-extent, 0.0),
			star_center + Vector2(-extent * 0.3, -extent * 0.3),
		])
		draw_colored_polygon(star, Color(accent, 0.90))
