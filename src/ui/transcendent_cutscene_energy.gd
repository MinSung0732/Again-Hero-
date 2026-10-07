extends RefCounted

# Bounded immediate drawing: independent energy, no spawned nodes or frame arrays.
static func strike_strength(t: float) -> float:
	return smoothstep(0.95, 1.12, t) * (1.0 - smoothstep(2.3, 2.85, t))

static func bolt(canvas: CanvasItem, start: Vector2, end: Vector2, seed_value: float, t: float, alpha: float, width: float = 5.0) -> void:
	if alpha <= 0.01:
		return
	var axis := end - start
	var normal := Vector2(-axis.y, axis.x).normalized()
	var previous := start
	var tick := floorf(t * 18.0)
	for index in range(1, 13):
		var progress := float(index) / 12.0
		var jitter := sin(float(index) * 13.7 + seed_value * 19.3 + tick * 2.1) * 48.0 * sin(progress * PI)
		var point := (start + axis * progress + normal * jitter).floor()
		canvas.draw_line(previous, point, Color(0.15, 0.45, 1.0, alpha * 0.35), width * 3.0, false)
		canvas.draw_line(previous, point, Color(0.5, 0.85, 1.0, alpha), width, false)
		canvas.draw_line(previous, point, Color(0.94, 0.99, 1.0, alpha), maxf(2.0, width * 0.4), false)
		if index == 4 or index == 8:
			canvas.draw_line(point, point + normal * sin(seed_value + index) * 95.0 + axis * 0.07, Color(0.48, 0.78, 1.0, alpha * 0.65), 3.0, false)
		previous = point

static func behind(canvas: CanvasItem, t: float, data: Dictionary, origin: Vector2, factor: float) -> void:
	var center: Vector2 = data.get("halo_center", Vector2(540, 860))
	var ground: Vector2 = data.get("particle_center", Vector2(540, 1570))
	var charge := smoothstep(0.0, 0.9, t) * (1.0 - smoothstep(1.05, 1.4, t))
	for index in range(10):
		var angle := float(index) * TAU / 10.0 + t * 1.4
		var radius := lerpf(390.0, 100.0, smoothstep(0.0, 1.05, t))
		var point := ground + Vector2(cos(angle) * radius, sin(angle) * radius * 0.3)
		bolt(canvas, point, ground, float(index), t, charge * 0.55, 3.0)
	var strike := strike_strength(t)
	bolt(canvas, Vector2(540, -40), ground, 1.0, t, strike, 11.0)
	bolt(canvas, Vector2(80, 40), ground + Vector2(-160, 0), 2.0, t, strike * 0.65, 6.0)
	bolt(canvas, Vector2(1000, -80), ground + Vector2(180, 0), 3.0, t, strike * 0.65, 6.0)
	# Two elliptical shockwaves race across the ground after impact.
	for index in range(2):
		var age := t - 1.12 - index * 0.18
		if age >= 0.0 and age < 1.0:
			var radius := 60.0 + age * 800.0
			canvas.draw_set_transform(origin + ground * factor, 0.0, Vector2(1, 0.32) * factor)
			canvas.draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.65, 0.9, 1, (1.0 - age) * 0.85), 7, false)
			canvas.draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	var reveal := smoothstep(2.6, 3.55, t)
	if reveal <= 0.0:
		return
	var release := 1.0 - 0.4 * smoothstep(4.1, 4.9, t)
	for index in range(24):
		var angle := float(index) * TAU / 24.0 + t * 0.14
		var direction := Vector2(cos(angle), sin(angle))
		var radius := float(data.get("halo_radius", 350.0))
		var inner := radius * (0.58 + 0.06 * sin(t * 3.0 + index))
		var outer := radius * (1.1 + 0.13 * sin(t * 2.0 + index))
		canvas.draw_line(center + direction * inner, center + direction * outer, Color(1, 0.82, 0.4, reveal * release * 0.7), 5, false)
	# A short gold release burst, then two independently orbiting energy ribbons.
	var burst := maxf(0.0, 1.0 - absf(t - 3.15) / 0.55)
	for index in range(20):
		var angle := float(index) * TAU / 20.0
		var direction := Vector2(cos(angle), sin(angle))
		var radius := 300.0 + maxf(0.0, t - 2.65) * 450.0
		canvas.draw_line(center + direction * radius, center + direction * (radius + 180.0), Color(1, 0.9, 0.6, burst * 0.8), 7, false)
	for index in range(2):
		var orbit_center := ground + Vector2(0, -360.0 - index * 380.0)
		canvas.draw_set_transform(origin + orbit_center * factor, 0.0, Vector2(1, 0.3) * factor)
		var angle := t * (3.5 if index == 0 else -3.0)
		canvas.draw_arc(Vector2.ZERO, 410.0, angle, angle + PI * 1.2, 48, Color(0.5, 0.82, 1, reveal * release * 0.75), 6, false)
		canvas.draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	for index in range(3):
		var radius := float(data.get("halo_radius", 350.0)) + float(index) * 22.0
		var angle := t * (0.35 if index % 2 == 0 else -0.3) + index
		canvas.draw_arc(center, radius, angle, angle + TAU * 0.73, 64, Color(1, 0.85, 0.48, reveal * 0.65), 3, false)

static func front(canvas: CanvasItem, t: float, data: Dictionary) -> void:
	var ground: Vector2 = data.get("particle_center", Vector2(540, 1570))
	var alpha := smoothstep(1.0, 1.35, t) * (1.0 - smoothstep(4.1, 4.9, t))
	# Side arcs frame the full body; the face and central costume stay readable.
	for index in range(4):
		var side := -1.0 if index % 2 == 0 else 1.0
		var height := 300.0 + index * 220.0
		var start := ground + Vector2(side * (370.0 + sin(t * 4 + index) * 30.0), -height)
		var end := ground + Vector2(side * 230.0, -height - 200.0)
		bolt(canvas, start, end, 6.0 + index, t, alpha * (0.45 + 0.25 * sin(t * 9 + index)), 4.0)
	for index in range(48):
		var phase := t * 0.9 + float(index) * 2.4
		var radius := 180.0 + float(index % 9) * 34.0
		var position := ground + Vector2(sin(phase) * radius, -fmod(t * (135 + index % 7 * 12) + index * 91, 1200.0))
		var brightness := 0.4 + 0.6 * absf(sin(t * 4 + index))
		var color := Color(1, 0.88, 0.5, brightness * 0.8) if index % 3 == 0 else Color(0.55, 0.86, 1, brightness * 0.8)
		canvas.draw_rect(Rect2(position.floor(), Vector2(4, 7)), color)
