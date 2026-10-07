extends Control

const FX := preload("res://src/data/zeus_lightning_catalog.gd")
var host: Control
var frames: Array[AtlasTexture] = []
var _sheet: Texture2D
var origin := Vector2.ZERO
var stage_scale := 1.0
var stage_offset := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet = preload("res://assets/art/effects/gatcha/zeus/lightning_v2/lightning_sheet.png")
	for index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = _sheet
		frame.region = Rect2(Vector2(index % 2, index / 2) * FX.CELL, FX.CELL)
		frame.filter_clip = true
		frames.append(frame)

func update_origin() -> void:
	origin = get_global_transform().affine_inverse() * host.rig.spell_origin()
	stage_scale = minf(size.x / 540.0, size.y / 960.0)
	stage_offset = (size - Vector2(540, 960) * stage_scale) * 0.5

func _draw() -> void:
	if host == null:
		return
	update_origin()
	var t: float = host.elapsed
	var charge := smoothstep(0.3, 1.65, t) * (1.0 - smoothstep(1.9, 2.25, t))
	# Concentric charge rings contract into the same moving gem that releases the PNG.
	for index in range(4):
		var radius := (62.0 - charge * 40.0 + index * 8.0) * stage_scale
		draw_arc(origin, radius, t * 5.0 + index, t * 5.0 + index + TAU * 0.72,
			40, Color(0.45, 0.8, 1.0, charge * 0.65), 2.0 * stage_scale, false)
	draw_circle(origin, (3.0 + charge * 11.0) * stage_scale, Color(0.75, 0.95, 1.0, charge))
	var release := FX.discharge(t)
	if not frames.is_empty() and release > 0.0:
		for index in range(FX.TARGETS.size()):
			var target: Vector2 = stage_offset + FX.TARGETS[index] * stage_scale
			_draw_bolt(target, t, index, release * (1.0 - index * 0.22))
	# Ring at actual discharge endpoint and a separate floor ripple, bounded fixed work.
	var age := maxf(0.0, t - FX.RELEASE)
	var impact := smoothstep(FX.RELEASE, 2.02, t) * (1.0 - smoothstep(2.25, 3.2, t))
	var ground := stage_offset + FX.TARGETS[0] * stage_scale
	for index in range(3):
		var radius := (15.0 + age * 175.0 + index * 18.0) * stage_scale
		draw_set_transform(ground, 0.0, Vector2(1.0, 0.28))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64,
			Color(0.35, 0.8, 1.0, impact * (1.0 - index * 0.22)), 5.0 * stage_scale, false)
	draw_set_transform(Vector2.ZERO)
	for index in range(40):
		var angle := index * 2.399
		var direction := Vector2(cos(angle), sin(angle))
		var point := origin + direction * age * (95.0 + index * 3.0) * stage_scale
		draw_rect(Rect2(point.floor(), Vector2.ONE * (2 + index % 3) * stage_scale),
			Color(0.6, 0.9, 1.0, impact * 0.8))
	var flash := FX.flash(t)
	if flash > 0.0:
		if host.get("corner_triangle") == true:
			draw_colored_polygon(host.border, Color(0.85, 0.95, 1.0, flash))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.85, 0.95, 1.0, flash))

func _draw_bolt(target: Vector2, t: float, index: int, alpha: float) -> void:
	var direction := target - origin
	var factor := direction.length() / FX.START.distance_to(FX.END)
	var frame_index := (int(t * FX.FPS) + index) % frames.size()
	# Uniform scale preserves the generated lightning proportion, no narrow pillar stretch.
	draw_set_transform(origin, direction.angle() - PI * 0.5, Vector2.ONE * factor)
	draw_texture_rect(frames[frame_index], Rect2(-FX.START, FX.CELL), false,
		Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO)
