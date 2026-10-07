extends Control

const POSE := preload("res://src/ui/zeus_battle_pose.gd")
const EFFECTS := preload("res://src/ui/zeus_attached_lightning.gd")
var corner_triangle := true
var portrait_window: Control
var rig: Node2D
var elapsed := 0.0
var background: Polygon2D
var effects: Control
var name_label: Label
var base_pose_position := Vector2.ZERO
var base_pose_scale := 1.0
var border := PackedVector2Array()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background = Polygon2D.new()
	background.texture = preload("res://assets/art/effects/gatcha/zeus/celestial_temple.png")
	background.color = Color(0.45, 0.6, 0.85, 0.92)
	add_child(background)
	portrait_window = Control.new()
	portrait_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Let the portrait extend beyond the corner backdrop; the battle panel clips it.
	portrait_window.clip_contents = false
	add_child(portrait_window)
	rig = POSE.new()
	portrait_window.add_child(rig)
	effects = EFFECTS.new()
	effects.host = self
	add_child(effects)
	name_label = Label.new()
	name_label.text = "제우스"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color",Color("fff3d2"))
	name_label.add_theme_color_override("font_outline_color",Color("080d20"))
	name_label.add_theme_constant_override("outline_size",4)
	add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_time(0.0)

func _layout() -> void:
	if not is_instance_valid(rig):
		return
	# Only the corner triangle has a backdrop. Portrait/FX are independent layers.
	border = PackedVector2Array([Vector2(size.x,0),size,Vector2(0,size.y)])
	background.polygon = border
	var texture_size: Vector2 = background.texture.get_size()
	var cover := maxf(size.x/texture_size.x,size.y/texture_size.y)
	var extent := size/cover
	var origin := (texture_size-extent)*0.5
	background.uv = PackedVector2Array([origin+Vector2(extent.x,0),origin+extent,origin+Vector2(0,extent.y)])
	var canvas: Vector2 = rig.canvas_size()
	base_pose_scale = minf(size.x * 0.9/canvas.x,size.y * 0.91/canvas.y)
	base_pose_position = Vector2(size.x*0.56,size.y*0.94)-Vector2(canvas.x*0.5,canvas.y)*base_pose_scale
	rig.scale = Vector2.ONE * base_pose_scale
	rig.position = base_pose_position
	portrait_window.size = size
	effects.size = size
	name_label.add_theme_font_size_override("font_size",maxi(18,int(size.y*0.038)))
	name_label.position = Vector2(size.x*0.3,size.y*0.94)
	name_label.size = Vector2(size.x*0.65,size.y*0.06)
	queue_redraw()

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(seconds)
	# Fully visible at t=0. Small entry/recoil translation; constant scale and pose.
	var entry := 1.0-smoothstep(0.0,0.3,seconds)
	var recoil := sin(maxf(0.0,seconds-1.9)*12.0)*(1.0-smoothstep(1.9,2.3,seconds)) if seconds>=1.9 else 0.0
	var focus := smoothstep(0.65,1.65,seconds)*(1.0-smoothstep(2.75,3.85,seconds))
	var zoom := base_pose_scale*(1.0+2.1*focus)
	var face_point := Vector2(450,545)
	var full_position := base_pose_position+Vector2((entry*12.0+recoil*2.0)*base_pose_scale,0)
	var focused_position := Vector2(size.x*0.62,size.y*0.43)-face_point*zoom
	rig.scale = Vector2.ONE*zoom
	rig.position = full_position.lerp(focused_position,focus)
	var closed := smoothstep(0.35,0.65,seconds)*(1.0-smoothstep(1.8,2.12,seconds))
	rig.set_eye_closed(closed)
	effects.modulate.a = lerpf(0.55,0.12,focus)
	rig.modulate = Color.WHITE
	name_label.modulate.a = smoothstep(3.5,3.85,seconds)
	background.color = Color(0.45,0.6,0.85,0.92).lerp(Color(0.9,0.95,1.0,0.94),smoothstep(1.5,2.0,seconds))
	effects.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if border.size() != 3:
		return
	# The diagonal edge marks a battle cut-in instead of a floating rectangular card.
	draw_line(border[0],border[2],Color(0.5,0.85,1.0,0.9),2.0,false)
