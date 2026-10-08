extends RefCounted
## Exact damage-radius outlines: preparation time is supplied by existing combat state.
const HOSTILE := Color("ffbd75")
const HERO := Color("a4cfff")
static func draw_area(target: Node2D, center: Vector2, radius: float, progress: float, color: Color = HOSTILE) -> void:
	if radius <= 0.0:
		return
	var t := clampf(progress,0.0,1.0)
	var fill := color
	fill.a = lerpf(0.025,0.065,t)
	target.draw_circle(center,radius,fill)
	var outline := color
	outline.a = lerpf(0.45,0.95,t)
	target.draw_arc(center,radius,0,TAU,72,outline,1.5,false)
	outline.a *= 0.65
	target.draw_arc(center,radius,-PI*0.5,-PI*0.5+TAU*t,72,outline,2.5,false)
