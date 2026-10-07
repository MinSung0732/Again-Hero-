extends Node2D

# Visual-only burst centered on the actual summoned Zeus; no collision or damage.
const CONFIG := preload("res://src/data/battle_summon_cinematic_catalog.gd").ZEUS_RADIAL
const FX := preload("res://src/data/zeus_lightning_catalog.gd")
const SHEET := preload("res://assets/art/effects/gatcha/zeus/lightning_v2/lightning_sheet.png")
var frames: Array[AtlasTexture] = []
var elapsed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = Rect2(Vector2(index % 2, index / 2) * FX.CELL, FX.CELL)
		frame.filter_clip = true
		frames.append(frame)

func set_time(seconds: float) -> void:
	elapsed = seconds
	queue_redraw()

func burst_strength(age: float) -> float:
	return smoothstep(0.0, 0.035, age) * (1.0 - smoothstep(0.12, float(CONFIG.burst_duration), age))

func _draw() -> void:
	if frames.is_empty():
		return
	for burst_index in range(CONFIG.bursts.size()):
		var age := elapsed - float(CONFIG.bursts[burst_index])
		if age < 0.0 or age >= float(CONFIG.burst_duration):
			continue
		var strength := burst_strength(age)
		var extension := lerpf(0.22, 1.0, smoothstep(0.0, 0.085, age))
		for ray in range(int(CONFIG.rays)):
			var angle := TAU * ray / float(CONFIG.rays)
			var reach := float(CONFIG.radius) * extension * (1.0 + burst_index * 0.10)
			var factor := reach / FX.START.distance_to(FX.END)
			var frame_index := (int(age * FX.FPS) + ray + burst_index) % frames.size()
			# Rotate and scale uniformly, retaining the authored PNG lightning shape.
			draw_set_transform(Vector2.ZERO, angle - PI * 0.5, Vector2.ONE * factor)
			draw_texture_rect(frames[frame_index], Rect2(-FX.START, FX.CELL), false,
				Color(0.8, 0.93, 1.0, strength * (1.0 - burst_index * 0.10)))
		draw_set_transform(Vector2.ZERO)
		draw_arc(Vector2.ZERO, 12.0 + age * 200.0, 0.0, TAU, 48,
			Color(0.45, 0.8, 1.0, strength * 0.6), 3.0, false)
		draw_circle(Vector2.ZERO, 7.0 * strength, Color(0.9, 0.97, 1.0, strength))
