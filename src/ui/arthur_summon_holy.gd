extends Node2D
# Visual support pulse; the actual arrival shield is granted by Arthur once.
const FX := preload("res://src/ui/arthur_combat_effects.gd")
var elapsed := 0.0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	FX.prepare(1)
	FX.prepare(2)
func set_time(seconds: float) -> void:
	elapsed = seconds
	queue_redraw()
func _draw() -> void:
	var alpha := smoothstep(0.1,1.5,elapsed)*(1-smoothstep(2.8,4.2,elapsed))
	FX.draw_frame(self,1,mini(4,int(elapsed*8)) if elapsed<0.625 else 4+int(elapsed*5)%2,Vector2.ZERO,1.2,alpha)
	for ring in range(3):
		var age := elapsed-1.95-ring*0.12
		if age>=0 and age<1.1:
			draw_arc(Vector2.ZERO,30+age*240,0,TAU,72,Color(1,0.88,0.46,(1-age/1.1)*0.8),2)
	if elapsed>=1.95 and elapsed<2.75: FX.draw_frame(self,2,mini(7,int((elapsed-1.95)*10)),Vector2(0,-30),1.5)
