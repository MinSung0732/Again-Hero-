extends Node2D
## Visual-only blood-sake mist and chain spirits around the real actor, never a damage authority.
const FX := preload("res://src/ui/shuten_doji_combat_effects.gd")
var elapsed := 0.0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	FX.prepare(0)
	FX.prepare(1)
	FX.prepare(2)
func set_time(seconds: float) -> void:
	elapsed = seconds
	queue_redraw()
func _draw() -> void:
	for side in range(6):
		var angle := TAU*side/6.0
		var age := elapsed-0.2-side*0.09
		if age >= 0 and elapsed < 2.5:
			var radius := 50.0+minf(age,1.5)*55.0
			FX.draw_frame(self,0,int(age*8)%8,Vector2.RIGHT.rotated(angle)*radius,0.7,0.5*(1-smoothstep(1.9,2.5,elapsed)))
		if elapsed >= 1.2 and elapsed < 2.0:
			FX.draw_frame(self,2,2+int(elapsed*6)%2,Vector2.RIGHT.rotated(angle)*lerpf(160,30,(elapsed-1.2)/0.8),0.7)
	var charge := smoothstep(0.15,1.5,elapsed)*(1.0-smoothstep(1.9,2.15,elapsed))
	draw_arc(Vector2.ZERO,70.0+charge*40.0,0,TAU,64,Color(1.0,0.12,0.1,charge*0.85),2.0,false)
	for ring in range(3):
		var age := elapsed-1.9-ring*0.18
		if age < 0.0 or age >= 0.7: continue
		var radius := 35.0+age*260.0
		draw_arc(Vector2.ZERO,radius,0,TAU,64,Color(1.0,0.25,0.12,(1.0-age/0.7)*0.85),2.0,false)
		for ray in range(6):
			FX.draw_frame(self,1,2+mini(5,int(age*9.0)),Vector2.RIGHT.rotated(TAU*ray/6.0+ring*0.22)*radius,0.7)
