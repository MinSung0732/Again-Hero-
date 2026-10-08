extends Control
const RIG := preload("res://src/ui/bulgasal_portrait_rig.gd")
const EXPRESSION := preload("res://src/ui/bulgasal_expression.gdshader")
const BACKGROUND := preload("res://assets/art/effects/gatcha/bulgasal/forge_background.png")
const CLOSED := preload("res://assets/art/effects/gatcha/bulgasal/closed_eyes_reference.png")
const ATLAS := preload("res://assets/art/effects/gatcha/bulgasal/forge_vfx_atlas.png")
var corner_triangle := true
var rig: Node2D
var backdrop: Polygon2D
var expression: ShaderMaterial
var name_label: Label
var flames: Array[Sprite2D] = []
var elapsed := 0.0
var border := PackedVector2Array()
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
	expression = ShaderMaterial.new()
	expression.shader = EXPRESSION
	expression.set_shader_parameter("closed_eyes",CLOSED)
	rig.mesh.material = expression
	for index in range(2):
		var flame := Sprite2D.new()
		flame.texture = ATLAS
		flame.region_enabled = true
		flame.region_rect = Rect2(Vector2.ZERO,ATLAS.get_size()*0.5)
		flame.z_index = -1
		add_child(flame)
		flames.append(flame)
	name_label = Label.new()
	name_label.text = "불가살"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color",Color("ffe3a0"))
	name_label.add_theme_color_override("font_outline_color",Color("180d05"))
	name_label.add_theme_constant_override("outline_size",4)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_time(0.0)

func _layout() -> void:
	if rig == null:
		return
	border = PackedVector2Array([Vector2(size.x,0),size,Vector2(0,size.y)])
	backdrop.polygon = border
	var texture_size := BACKGROUND.get_size()
	var cover := maxf(size.x/texture_size.x,size.y/texture_size.y)
	var extent := size/cover
	var origin := (texture_size-extent)*0.5
	backdrop.uv = PackedVector2Array([origin+Vector2(extent.x,0),origin+extent,origin+Vector2(0,extent.y)])
	# Shoulder/neck/face focus from the start; uniform camera framing, no anatomy stretch.
	base_scale = minf(size.x/365.0,size.y/365.0)
	name_label.position = Vector2(size.x*0.36,size.y*0.9)
	name_label.size = Vector2(size.x*0.6,size.y*0.08)
	name_label.add_theme_font_size_override("font_size",maxi(18,int(size.y*0.048)))
	set_time(elapsed)

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(seconds)
	var eye_open := smoothstep(1.78,1.92,seconds)
	expression.set_shader_parameter("eye_closed",1.0-eye_open)
	expression.set_shader_parameter("reveal_edge",lerpf(-0.1,1.1,smoothstep(0.25,1.3,seconds)))
	var impact := smoothstep(1.78,1.88,seconds)*(1.0-smoothstep(2.05,2.45,seconds))
	var zoom := base_scale*(1.0+impact*0.045)
	rig.scale = Vector2.ONE*zoom
	# The fixed face center is mapped from original texture space through the shared rig fit.
	var face: Vector2 = rig.portrait.position+Vector2(345,410)*rig.portrait.scale
	rig.position = Vector2(size.x*0.60,size.y*0.38)-face*zoom
	backdrop.color = Color(0.38,0.23,0.09,0.94).lerp(Color(1.0,0.7,0.25,0.98),impact)
	for index in range(flames.size()):
		var flame := flames[index]
		flame.position = Vector2(size.x*(0.12 if index==0 else 0.96),size.y*0.85)
		flame.scale = Vector2(size.x*0.45,size.y*0.75)/flame.region_rect.size
		flame.modulate.a = impact*0.85
	name_label.modulate.a = smoothstep(2.25,2.65,seconds)
	queue_redraw()

func _draw() -> void:
	if border.size()!=3:
		return
	draw_line(border[0],border[2],Color("ffc64f"),2.0,false)
