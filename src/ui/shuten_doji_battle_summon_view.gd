extends Control
## Full-color battle cut-in; presentation clock is independent of combat time.
const RIG := preload("res://src/ui/shuten_doji_portrait_rig.gd")
const BACKGROUND := preload("res://assets/art/effects/gatcha/shuten_doji/sake_hall_v1.png")
const CLOSED_EYES := preload("res://assets/art/effects/gatcha/shuten_doji/rig_v1/closed_eyes_v1.png")
const FOCUS := preload("res://src/ui/shuten_doji_focus.gdshader")
const FX := preload("res://src/ui/shuten_doji_combat_effects.gd")
var corner_triangle := true
var backdrop: Polygon2D
var rig: Node2D
var eyes: ShaderMaterial
var name_label: Label
var effects: Node2D
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
	eyes = ShaderMaterial.new()
	eyes.shader = FOCUS
	eyes.set_shader_parameter("closed_eyes",CLOSED_EYES)
	rig.mesh.material = eyes
	effects = Node2D.new()
	effects.z_index = -1
	add_child(effects)
	effects.draw.connect(_draw_effects)
	for kind in range(4): FX.prepare(kind)
	name_label = Label.new()
	name_label.text = "슈텐-도지"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font",load("res://assets/fonts/Galmuri11.ttf"))
	name_label.add_theme_color_override("font_color",Color("ffdf91"))
	name_label.add_theme_color_override("font_outline_color",Color("170c21"))
	name_label.add_theme_constant_override("outline_size",4)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_time(0.0)
func _layout() -> void:
	if rig == null: return
	backdrop.polygon = PackedVector2Array([Vector2(size.x,0),size,Vector2(0,size.y)])
	var factor := maxf(size.x/BACKGROUND.get_width(),size.y/BACKGROUND.get_height())
	var extent := size/factor
	var offset := (BACKGROUND.get_size()-extent)*0.5
	backdrop.uv = PackedVector2Array([offset+Vector2(extent.x,0),offset+extent,offset+Vector2(0,extent.y)])
	base_scale = minf(size.x*0.88/580.0,size.y*0.90/660.0)
	name_label.position = Vector2(size.x*0.35,size.y*0.93)
	name_label.size = Vector2(size.x*0.63,size.y*0.07)
	name_label.add_theme_font_size_override("font_size",maxi(18,int(size.y*0.045)))
	set_time(elapsed)
func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(seconds)
	var focus := smoothstep(0.65,1.65,seconds)*(1.0-smoothstep(2.75,3.85,seconds))
	var zoom := base_scale*(1.0+1.35*focus)
	var full := Vector2(size.x*0.59,size.y*0.94)-Vector2(335,1192)*zoom
	var face := Vector2(size.x*0.63,size.y*0.43)-Vector2(381,677)*zoom
	rig.scale = Vector2.ONE*zoom
	rig.position = full.lerp(face,focus)
	eyes.set_shader_parameter("closed",smoothstep(0.35,0.65,seconds)*(1.0-smoothstep(1.8,2.12,seconds)))
	name_label.modulate.a = smoothstep(3.8,4.15,seconds)
	backdrop.color = Color(0.58,0.35,0.64,0.94).lerp(Color(0.91,0.75,0.56,0.96),smoothstep(1.8,2.15,seconds))
	effects.queue_redraw()
func _draw_effects() -> void:
	var center := Vector2(size.x*0.61,size.y*0.72)
	var factor := minf(size.x/540.0,size.y/960.0)
	var charge := smoothstep(0.5,1.7,elapsed)*(1.0-smoothstep(2.15,2.5,elapsed))
	effects.draw_arc(center,125.0*factor,0,TAU,64,Color(1.0,0.18,0.1,charge*0.8),2.0,false)
	for i in range(6):
		var age := elapsed-1.95-i*0.055
		if age >= 0.0 and age <= 0.6:
			FX.draw_frame(effects,1,2+mini(5,int(age*10.0)),center+Vector2.RIGHT.rotated(TAU*i/6.0)*110.0*factor,factor)
