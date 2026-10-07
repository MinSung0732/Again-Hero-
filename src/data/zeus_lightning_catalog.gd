extends RefCounted

const SHEET := "res://assets/art/effects/gatcha/zeus/lightning_v2/lightning_sheet.png"
const CELL := Vector2(512, 512)
const START := Vector2(256, 48)
const END := Vector2(256, 464)
const FPS := 24.0
const RELEASE := 1.9
const TARGETS := [Vector2(474, 842), Vector2(510, 30), Vector2(520, 500)]

static func discharge(t: float) -> float:
	return smoothstep(1.72, RELEASE, t) * (1.0 - smoothstep(2.22, 2.75, t))

static func flash(t: float) -> float:
	return maxf(0.0, 1.0 - absf(t - RELEASE) / 0.07) * 0.72

static func shake(t: float) -> Vector2:
	var strength := maxf(0.0, 1.0 - (t - RELEASE) / 0.35)
	if t < RELEASE:
		return Vector2.ZERO
	return Vector2(sin(t * 97.0), cos(t * 83.0)) * strength * 5.0
