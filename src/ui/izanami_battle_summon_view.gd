extends Control
## Prayer cut-in: full color immediately, closed original eyes, no combat authority.
const RIG := preload("res://src/ui/izanami_portrait_rig.gd")
const BACKGROUND := preload("res://assets/art/effects/gatcha/izanami/yomi_shrine.png")
const ATLAS := preload("res://assets/art/effects/gatcha/izanami/spirit_vfx_atlas.png")
var corner_triangle := true
var backdrop: Polygon2D
var rig: Node2D
var name_label: Label
var flame: Sprite2D
var wreath: Sprite2D
var elapsed := 0.0
var base_scale := 1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop = Polygon2D.new()
	backdrop.z_index = -3
	backdrop.texture = BACKGROUND
	add_child(backdrop)
	rig = RIG.new()
	add_child(rig)
	for region in [Rect2(0,0,630,640),Rect2(640,0,640,640)]:
		var sprite := Sprite2D.new()
		sprite.texture = ATLAS
		sprite.region_enabled = true
		sprite.region_rect = Rect2(region.position*ATLAS.get_size()/1280.0,region.size*ATLAS.get_size()/1280.0)
		add_child(sprite)
		if flame==null:flame=sprite
		else:wreath=sprite
	wreath.z_index=-1
	name_label = Label.new()
	name_label.text = "이자나미"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font",load("res://assets/fonts/Galmuri11.ttf"))
	name_label.add_theme_color_override("font_color",Color("ffe7c9"))
	name_label.add_theme_color_override("font_outline_color",Color("130b21"))
	name_label.add_theme_constant_override("outline_size",4)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_time(0)
func _layout() -> void:
	if rig==null:return
	var border := PackedVector2Array([Vector2(size.x,0),size,Vector2(0,size.y)])
	backdrop.polygon=border
	var factor := maxf(size.x/BACKGROUND.get_width(),size.y/BACKGROUND.get_height())
	var extent := size/factor
	var offset := (BACKGROUND.get_size()-extent)*0.5
	backdrop.uv=PackedVector2Array([offset+Vector2(extent.x,0),offset+extent,offset+Vector2(0,extent.y)])
	base_scale=minf(size.x/720.0,size.y/880.0)
	name_label.position=Vector2(size.x*0.35,size.y*0.91)
	name_label.size=Vector2(size.x*0.63,size.y*0.08)
	name_label.add_theme_font_size_override("font_size",maxi(16,int(size.y*0.045)))
	set_time(elapsed)
func set_time(seconds: float) -> void:
	elapsed=seconds
	rig.set_time(seconds)
	# Gentle uniform illustration camera focus, not breathing by body scaling.
	var focus:=smoothstep(0.4,1.7,seconds)*(1.0-smoothstep(3.1,4.2,seconds))
	var zoom:=base_scale*(1.0+focus*0.22)
	rig.scale=Vector2.ONE*zoom
	var center:=Vector2(400,700).lerp(Vector2(400,480),focus)
	rig.position=Vector2(size.x*0.60,size.y*0.55)-center*zoom
	rig.position.x=minf(rig.position.x,size.x-724.0*zoom-6.0)
	var pulse:=smoothstep(2.05,2.15,seconds)*(1.0-smoothstep(2.2,2.6,seconds))
	backdrop.color=Color(0.7+pulse*0.2,0.5+pulse*0.15,0.8+pulse*0.2,0.94)
	flame.position=rig.position+Vector2(400,570)*zoom
	flame.scale=Vector2.ONE*zoom*0.22
	flame.modulate.a=smoothstep(0.5,1.6,seconds)*(1.0-smoothstep(2.15,2.5,seconds))*0.9
	wreath.position=rig.position+Vector2(400,550)*zoom
	wreath.scale=Vector2.ONE*zoom*0.8
	wreath.rotation=seconds*0.08
	wreath.modulate.a=pulse*0.7
	name_label.modulate.a=smoothstep(4.0,4.3,seconds)
