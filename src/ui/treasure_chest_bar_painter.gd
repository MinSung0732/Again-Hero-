extends RefCounted
## Original solo chest bar geometry/colors shared by the online mirror.
const BACKGROUND := Rect2(-28,-38,56,5)
const FILL := Rect2(-27,-37,54,3)
const BACKGROUND_COLOR := Color(0.10,0.08,0.06,0.90)
const FILL_COLOR := Color(0.94,0.70,0.20)
static func fill_rect(current: int, maximum: int) -> Rect2:
	return Rect2(FILL.position,Vector2(FILL.size.x*clampf(float(current)/maxi(maximum,1),0.0,1.0),FILL.size.y))
static func draw(canvas: Node2D,current: int,maximum: int) -> void:
	canvas.draw_rect(BACKGROUND,BACKGROUND_COLOR,true)
	canvas.draw_rect(fill_rect(current,maximum),FILL_COLOR,true)
