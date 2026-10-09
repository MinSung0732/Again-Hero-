extends Node2D
## Fixed cached atlas pieces projected at the summoned actor; purely visual.
const ATLAS := preload("res://assets/art/effects/gatcha/izanami/spirit_vfx_atlas.png")
var flames: AtlasTexture
var wreath: AtlasTexture
var elapsed := 0.0
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	flames=AtlasTexture.new()
	flames.atlas=ATLAS
	flames.region=Rect2(Vector2.ZERO,Vector2(630,640)*ATLAS.get_size()/1280.0)
	flames.filter_clip=true
	wreath=AtlasTexture.new()
	wreath.atlas=ATLAS
	wreath.region=Rect2(Vector2(640,0)*ATLAS.get_size()/1280.0,Vector2(640,640)*ATLAS.get_size()/1280.0)
	wreath.filter_clip=true
func set_time(seconds: float) -> void:
	elapsed=seconds
	queue_redraw()
func _draw() -> void:
	var age:=elapsed-2.15
	if age<0.0 or age>2.35:return
	var alpha:=smoothstep(0.0,0.18,age)*(1.0-smoothstep(1.3,2.35,age))
	var radius:=lerpf(36.0,135.0,smoothstep(0.0,0.65,age))
	# Talisman wreath unfolds on the ground, then six separate spirit flames rise.
	draw_texture_rect(wreath,Rect2(-radius,-radius*0.52,radius*2,radius*1.04),false,Color(1,1,1,alpha*0.7))
	for i in range(6):
		var angle:=i*TAU/6+age*0.2
		var center:=Vector2(cos(angle)*radius,sin(angle)*radius*0.52-age*22)
		draw_texture_rect(flames,Rect2(center-Vector2(15,48),Vector2(30,60)),false,Color(1,1,1,alpha*0.7))
	var wave:=smoothstep(0.0,0.1,age)*(1.0-smoothstep(0.35,1.15,age))
	draw_arc(Vector2.ZERO,25+age*175,0,TAU,64,Color(0.65,0.32,1,wave*0.8),2,false)
