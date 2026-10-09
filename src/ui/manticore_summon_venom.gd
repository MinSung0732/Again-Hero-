extends Node2D
## Visual-only poisonous corona around the real actor, never a damage authority.
const FX := preload("res://src/ui/manticore_combat_effects.gd")
var elapsed := 0.0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	FX.prepare(1)
	FX.prepare(2)
func set_time(seconds: float) -> void:
	elapsed = seconds
	queue_redraw()
func _draw() -> void:
	var charge := smoothstep(0.15,1.5,elapsed)*(1.0-smoothstep(1.9,2.15,elapsed))
	draw_arc(Vector2.ZERO,70.0+charge*40.0,0,TAU,64,Color(0.6,1.0,0.28,charge*0.85),2.0,false)
	for ring in range(3):
		var age := elapsed-1.9-ring*0.18
		if age < 0.0 or age >= 0.7: continue
		var radius := 35.0+age*260.0
		draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(0.65,1.0,0.28,(1.0-age/0.7)*0.85),2.0,false)
		for ray in range(6):
			FX.draw_frame(self,1,2+mini(5,int(age*9.0)),Vector2.RIGHT.rotated(TAU*ray/6.0+ring*0.22)*radius,0.7)
