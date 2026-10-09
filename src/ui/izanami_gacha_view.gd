extends Control
## Presentation only. Never rolls, pays, awards or changes battle state.
const RIG := preload("res://src/ui/izanami_portrait_rig.gd")
const REVEAL := preload("res://src/ui/zeus_silhouette_reveal.gdshader")
const ART := "res://assets/art/Transcendent_monster/Izanami/frames/"
var stage: Node2D
var rig: Node2D
var background: Sprite2D
var name_label: Label
var reveal_material: ShaderMaterial
var effects: Array[Sprite2D] = []
var packs: Array = []
var atlas_fx: Array[Sprite2D] = []
var name_backing: ColorRect
var elapsed := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage = Node2D.new()
	add_child(stage)
	background = Sprite2D.new()
	background.texture = load("res://assets/art/effects/gatcha/izanami/yomi_shrine.png")
	background.position = Vector2(270,480)
	background.scale = Vector2(540,960)/background.texture.get_size()
	stage.add_child(background)
	for group in ["effect1","effect3"]:
		var frames: Array[Texture2D] = []
		for i in range(1,9): frames.append(load(ART+group+"/effect_%02d.png"%i))
		packs.append(frames)
	for i in range(5):
		var sprite := Sprite2D.new()
		sprite.z_index = 1 if i<3 else 3
		stage.add_child(sprite)
		effects.append(sprite)
	var atlas: Texture2D = load("res://assets/art/effects/gatcha/izanami/spirit_vfx_atlas.png")
	var regions := [Rect2(0,0,630,640),Rect2(640,0,640,640),Rect2(0,650,850,620),Rect2(850,650,430,620)]
	for i in range(4):
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.region_enabled = true
		sprite.region_rect = Rect2(regions[i].position*atlas.get_size()/1280.0,regions[i].size*atlas.get_size()/1280.0)
		sprite.z_index = 1 if i==1 else 3
		stage.add_child(sprite)
		atlas_fx.append(sprite)
	rig = RIG.new()
	rig.z_index = 2
	# One common scale; source bounds44..724,264..1017 remain within stage.
	rig.scale = Vector2.ONE*0.64
	rig.position = Vector2(270,785)-Vector2(384,1017)*0.64
	stage.add_child(rig)
	reveal_material = ShaderMaterial.new()
	reveal_material.shader = REVEAL
	reveal_material.set_shader_parameter("silhouette_color",Color("130c24"))
	rig.mesh.material = reveal_material
	name_backing = ColorRect.new()
	name_backing.position = Vector2(0,820)
	name_backing.size = Vector2(540,140)
	name_backing.color = Color(0.03,0.01,0.06,0.8)
	name_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_backing.z_index = 3
	stage.add_child(name_backing)
	name_label = Label.new()
	name_label.text = "이자나미"
	name_label.z_index = 4
	name_label.position = Vector2(60,835)
	name_label.size = Vector2(420,76)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font",load("res://assets/fonts/Galmuri11.ttf"))
	name_label.add_theme_font_size_override("font_size",32)
	name_label.add_theme_color_override("font_color",Color("ffe9cb"))
	name_label.add_theme_color_override("font_outline_color",Color("160b22"))
	name_label.add_theme_constant_override("outline_size",4)
	stage.add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_process(false)
	set_time(0.0)
func _layout() -> void:
	if stage==null: return
	var factor := minf(size.x/540.0,size.y/960.0)
	stage.scale = Vector2.ONE*factor
	stage.position = (size-Vector2(540,960)*factor)*0.5
func set_time(seconds: float) -> void:
	elapsed = maxf(0.0,seconds)
	rig.set_time(elapsed)
	rig.modulate.a = smoothstep(0.35,0.8,elapsed)
	reveal_material.set_shader_parameter("reveal_edge",lerpf(-0.08,1.1,smoothstep(1.05,2.3,elapsed)))
	var light := lerpf(0.22,0.82,smoothstep(1.3,2.5,elapsed))
	background.modulate = Color(light,light,light)
	var hold := smoothstep(0.2,1.0,elapsed)*(1.0-smoothstep(4.0,4.8,elapsed))
	for i in range(5):
		var sprite := effects[i]
		var kind := 0 if i<3 else 1
		var age := elapsed-(0.3 if i<3 else 2.4+float(i-3)*0.16)
		sprite.visible = age>=0.0 and (i<3 or age<1.4)
		if not sprite.visible: continue
		sprite.texture = packs[kind][int(age*10.0)%8]
		var width := 300.0 if i==0 else 135.0 if i<3 else 180.0
		sprite.scale = Vector2.ONE*width/sprite.texture.get_width()
		if i==0:
			sprite.position = Vector2(270,650)
			sprite.modulate.a = hold*0.4
		elif i<3:
			sprite.position = Vector2(90 if i==1 else 450,590+sin(elapsed*1.6+i)*10)
			sprite.modulate.a = hold*0.5
		else:
			var side := -1.0 if i==3 else 1.0
			sprite.position = Vector2(280+side*(65+age*125),535-age*20)
			sprite.modulate.a = smoothstep(0.0,0.15,age)*(1.0-smoothstep(0.8,1.4,age))*0.8
	var charge := smoothstep(1.3,2.1,elapsed)*(1.0-smoothstep(2.4,2.8,elapsed))
	atlas_fx[0].position = rig.position+Vector2(400,570)*0.64
	atlas_fx[0].scale = Vector2.ONE*0.18
	atlas_fx[0].modulate.a = charge*0.85
	atlas_fx[1].position = Vector2(270,505)
	atlas_fx[1].scale = Vector2.ONE*0.65
	atlas_fx[1].rotation = elapsed*0.08
	atlas_fx[1].modulate.a = smoothstep(1.5,2.5,elapsed)*(1.0-smoothstep(3.4,4.4,elapsed))*0.55
	var age := clampf(elapsed-2.4,0.0,1.2)
	var release := smoothstep(2.4,2.55,elapsed)*(1.0-smoothstep(3.1,3.6,elapsed))
	atlas_fx[2].position = Vector2(280,525)+Vector2(age*100,age*35)
	atlas_fx[2].scale = Vector2.ONE*0.46
	atlas_fx[2].modulate.a = release*0.75
	atlas_fx[3].position = Vector2(280,525)+Vector2(-age*110,-age*25)
	atlas_fx[3].scale = Vector2.ONE*0.24
	atlas_fx[3].modulate.a = release*0.7
	name_backing.modulate.a = smoothstep(3.8,4.3,elapsed)
	name_label.modulate.a = smoothstep(3.8,4.3,elapsed)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("090611"))
