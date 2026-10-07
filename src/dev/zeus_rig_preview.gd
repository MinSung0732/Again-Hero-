extends Control

const RIG := preload("res://src/ui/zeus_portrait_rig.gd")
const EFFECTS := preload("res://src/ui/zeus_attached_lightning.gd")
const FX := preload("res://src/data/zeus_lightning_catalog.gd")
const REVEAL := preload("res://src/ui/zeus_silhouette_reveal.gdshader")
var rig: Node2D
var background: Texture2D
var effects: Control
var name_label: Label
var reveal_material: ShaderMaterial
var elapsed := 0.0
var paused := false
var _last_tick := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background = ImageTexture.create_from_image(Image.load_from_file("res://assets/art/effects/gatcha/zeus/celestial_temple.png"))
	rig = RIG.new()
	add_child(rig)
	reveal_material = ShaderMaterial.new()
	reveal_material.shader = REVEAL
	for mesh in rig.meshes:
		mesh.material = reveal_material
	effects = EFFECTS.new()
	effects.host = self
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effects)
	name_label = Label.new()
	name_label.text = "제우스"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color",Color("fff3d2"))
	name_label.add_theme_color_override("font_outline_color",Color("080d20"))
	name_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
	name_label.add_theme_constant_override("outline_size",3)
	name_label.add_theme_constant_override("shadow_offset_y",3)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_time(0.0)
	_last_tick = Time.get_ticks_usec()

func _layout() -> void:
	if rig == null:
		return
	var factor := minf(size.x/540.0,size.y/960.0)
	var offset := (size-Vector2(540,960)*factor)*0.5
	rig.scale = Vector2.ONE*0.72*factor
	rig.position = offset+Vector2(270-384*0.72,800-1200*0.72)*factor
	effects.size = size
	name_label.position = offset+Vector2(90,850)*factor
	name_label.size = Vector2(360,76)*factor
	name_label.add_theme_font_size_override("font_size",maxi(18,int(36*factor)))

func _process(_delta: float) -> void:
	var tick := Time.get_ticks_usec()
	if not paused:
		set_time(fmod(elapsed+float(tick-_last_tick)/1000000.0,5.7))
	_last_tick = tick

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(minf(elapsed,5.0))
	rig.modulate.a = FX.silhouette_alpha(elapsed)
	reveal_material.set_shader_parameter("reveal_edge",FX.reveal_edge(elapsed))
	name_label.modulate.a = FX.name_alpha(elapsed)
	queue_redraw()
	effects.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		paused = not paused

func _draw() -> void:
	if background == null:
		return
	var region := preload("res://src/ui/transcendent_cutscene_player.gd").cover_region(background.get_size(),size)
	var light := lerpf(0.23,0.9,smoothstep(1.8,2.2,elapsed))
	var factor := minf(size.x/540.0,size.y/960.0)
	var shake := FX.shake(elapsed)*factor
	draw_texture_rect_region(background,Rect2(shake-Vector2.ONE*6*factor,size+Vector2.ONE*12*factor),region,Color(light,light,light))
	# Behind the portrait: gold halo opens on release; foreground bolts stay gem-attached.
	var halo := smoothstep(1.8,2.15,elapsed)*(1.0-smoothstep(4.6,5.0,elapsed))
	var offset := (size-Vector2(540,960)*factor)*0.5
	# Native name has its own dark lower backing; no text baked into character art.
	for index in range(12):
		var fade := float(index+1)/12.0
		draw_rect(Rect2(offset+Vector2(0,828+index*11)*factor,Vector2(540,11)*factor),
			Color(0.02,0.025,0.065,fade*0.72*FX.name_alpha(elapsed)))
	var center := offset+Vector2(270,430)*factor
	for index in range(3):
		draw_arc(center,(110+index*14)*factor,elapsed*0.35+index,
			elapsed*0.35+index+TAU*0.9,80,Color(1,0.79,0.3,halo*(0.65-index*0.14)),2*factor,false)
	for index in range(16):
		var angle := index*TAU/16+elapsed*0.1
		var direction := Vector2(cos(angle),sin(angle))
		draw_line(center+direction*148*factor,center+direction*(165+halo*24)*factor,
			Color(1,0.82,0.4,halo*0.5),2*factor,false)
