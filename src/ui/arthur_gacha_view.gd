extends Control
const BACKGROUND_LAYOUT := preload("res://src/ui/cutscene_background_layout.gd")
# Sword oath: dark cathedral -> twelve-seat halo -> golden revelation.
const RIG := preload("res://src/ui/arthur_portrait_rig.gd")
const FX := preload("res://src/ui/arthur_combat_effects.gd")
var stage: Node2D
var rig: Node2D
var reveal: ShaderMaterial
var hall: ShaderMaterial
var background_art: Sprite2D
var background_overlay: ColorRect
var effects: Node2D
var label: Label
var elapsed := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage = Node2D.new()
	add_child(stage)
	var background_root := Node2D.new()
	stage.add_child(background_root)
	background_art = Sprite2D.new()
	background_art.texture = load("res://assets/art/effects/gatcha/reveal_v2/arthur_avalon_background.png")
	background_art.position = Vector2(270,480)
	background_art.scale = Vector2(540,960)/background_art.texture.get_size()
	background_root.add_child(background_art)
	background_overlay = ColorRect.new()
	background_overlay.size = Vector2(540,960)
	background_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hall = ShaderMaterial.new()
	hall.shader = preload("res://src/ui/arthur_holy_hall.gdshader")
	background_overlay.material = hall
	background_overlay.modulate.a = 0.16
	background_root.add_child(background_overlay)
	effects = Node2D.new()
	stage.add_child(effects)
	effects.draw.connect(_draw_effects)
	for i in range(4): FX.prepare(i)
	rig = RIG.new()
	stage.add_child(rig)
	reveal = ShaderMaterial.new()
	reveal.shader = preload("res://src/ui/arthur_holy_reveal.gdshader")
	reveal.set_shader_parameter("closed_eyes_art",load("res://assets/art/effects/gatcha/reveal_v2/arthur_closed_eyes_source.png"))
	rig.mesh.material = reveal
	label = Label.new()
	label.text = "초월 · 아서왕"
	label.position = Vector2(40,845)
	label.size = Vector2(460,75)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",load("res://assets/fonts/Galmuri11.ttf"))
	label.add_theme_font_size_override("font_size",34)
	label.add_theme_color_override("font_color",Color("ffe7a0"))
	label.add_theme_color_override("font_outline_color",Color("0a1530"))
	label.add_theme_constant_override("outline_size",5)
	stage.add_child(label)
	resized.connect(_layout)
	_layout()
	set_time(0)
func _layout() -> void:
	if stage==null: return
	var factor := minf(size.x/540,size.y/960)
	stage.scale = Vector2.ONE*factor
	stage.position = (size-Vector2(540,960)*factor)*0.5
	BACKGROUND_LAYOUT.cover_sprite(background_art,size,stage.position,factor)
	BACKGROUND_LAYOUT.cover_overlay(background_overlay,size,stage.position,factor)

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(seconds)
	var wake := smoothstep(1.95,2.30,seconds)
	var factor := lerpf(0.82,0.88,smoothstep(1.2,2.5,seconds))
	rig.scale = Vector2.ONE*factor
	rig.position = Vector2(270,835)-Vector2(380,1192)*factor
	reveal.set_shader_parameter("revealed",wake)
	reveal.set_shader_parameter("closed",1.0-smoothstep(2.0,2.25,seconds))
	hall.set_shader_parameter("seconds",seconds)
	var background_light := lerpf(0.24,0.78,smoothstep(0.5,2.4,seconds))
	background_art.modulate = Color(background_light,background_light,background_light)
	label.modulate.a = smoothstep(3.35,3.8,seconds)
	effects.queue_redraw()
func _draw_effects() -> void:
	var charge := smoothstep(0.1,1.9,elapsed)*(1-smoothstep(3,4.4,elapsed))
	var center := Vector2(270,670)
	for ring in range(3):
		effects.draw_arc(center,125+ring*22,0,TAU,80,Color(1,0.8,0.35,charge*0.65),2)
	for seat in range(12):
		var point := center+Vector2.RIGHT.rotated(TAU*seat/12+elapsed*0.15)*160
		effects.draw_circle(point,5,Color(1,0.88,0.55,charge))
	var burst := elapsed-2.05
	if burst>=0 and burst<0.8:
		FX.draw_frame(effects,2,mini(7,int(burst*10)),Vector2(270,660),2.2)
		for ray in range(12):
			var direction := Vector2.UP.rotated(TAU*ray/12)
			effects.draw_line(center+direction*100,center+direction*(120+burst*650),Color(1,0.91,0.65,1-burst/0.8),3)
	FX.draw_frame(effects,1,4+int(elapsed*4)%2,Vector2(270,850),1.5,charge*0.8)
