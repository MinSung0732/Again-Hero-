extends RefCounted
## Shared right-side concentration bar. Progress increases toward release.
static func draw_on(layer: Node2D, point: Vector2, progress: float) -> void:
	layer.draw_rect(Rect2(point,Vector2(7,50)),Color("17122b"))
	var fill := clampf(progress,0.0,1.0)*46.0
	layer.draw_rect(Rect2(point+Vector2(2,48-fill),Vector2(3,fill)),Color("ffdf76"))
	layer.draw_rect(Rect2(point,Vector2(7,50)),Color("ba9862"),false,1.0)
