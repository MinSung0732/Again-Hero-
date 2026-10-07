extends Control

const RIG := preload("res://src/ui/zeus_portrait_rig.gd")
const ENERGY := preload("res://src/ui/transcendent_cutscene_energy.gd")
var rig: Node2D
var background: Texture2D
var effects: Control
var name_label: Label
var elapsed := 0.0
var paused := false
var _last_tick := 0

class AttachedEffects extends Control:
	var host: Control
	func _draw() -> void:
		if host == null:
			return
		var t: float = host.elapsed
		var origin: Vector2 = host.rig.spell_origin()
		origin = get_global_transform().affine_inverse() * origin
		var charge := smoothstep(0.4,1.4,t)*(1.0-smoothstep(1.8,2.3,t))
		for index in range(3):
			var radius := 12.0 + index*7.0 + sin(t*9+index)*2
			draw_arc(origin,radius,t*3+index,t*3+index+TAU*0.8,32,Color(0.5,0.85,1,charge),2,false)
		var release := smoothstep(1.7,1.88,t)*(1.0-smoothstep(2.35,2.8,t))
		var target := Vector2(size.x*0.84,size.y*0.88)
		host.ENERGY.bolt(self,origin,target,1,t,release,6)
		host.ENERGY.bolt(self,origin,Vector2(size.x*0.92,0),2,t,release*0.65,4)
		for index in range(20):
			var age := maxf(0,t-1.9)
			var direction := Vector2(cos(index*2.399),sin(index*2.399))
			var point := origin + direction*age*(70+index*4)
			draw_rect(Rect2(point.floor(),Vector2(3,3)),Color(0.7,0.9,1,release*0.7))
		var flash := maxf(0,1.0-absf(t-1.9)/0.11)*0.65
		if flash>0:
			draw_rect(Rect2(Vector2.ZERO,size),Color(0.8,0.93,1,flash))

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background = ImageTexture.create_from_image(Image.load_from_file("res://assets/art/effects/gatcha/zeus/celestial_temple.png"))
	rig = RIG.new()
	add_child(rig)
	effects = AttachedEffects.new()
	effects.host = self
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effects)
	name_label = Label.new()
	name_label.text = "제우스"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color",Color("fff0bf"))
	name_label.add_theme_color_override("font_outline_color",Color("102039"))
	name_label.add_theme_constant_override("outline_size",4)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	_last_tick = Time.get_ticks_usec()

func _layout() -> void:
	if rig == null:
		return
	var factor := minf(size.x/540.0,size.y/960.0)
	var offset := (size-Vector2(540,960)*factor)*0.5
	rig.scale = Vector2.ONE*0.72*factor
	rig.position = offset+Vector2(270-384*0.72,800-1200*0.72)*factor
	effects.size = size
	name_label.position = offset+Vector2(120,865)*factor
	name_label.size = Vector2(300,60)*factor
	name_label.add_theme_font_size_override("font_size",maxi(16,int(28*factor)))

func _process(_delta: float) -> void:
	var tick := Time.get_ticks_usec()
	if not paused:
		set_time(fmod(elapsed+float(tick-_last_tick)/1000000.0,5.7))
	_last_tick = tick

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(minf(elapsed,5.0))
	name_label.modulate.a = smoothstep(3.8,4.1,elapsed)
	queue_redraw()
	effects.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		paused = not paused

func _draw() -> void:
	if background == null:
		return
	var region := preload("res://src/ui/transcendent_cutscene_player.gd").cover_region(background.get_size(),size)
	var light := lerpf(0.4,0.9,smoothstep(0.2,2.2,elapsed))
	draw_texture_rect_region(background,Rect2(Vector2.ZERO,size),region,Color(light,light,light))
