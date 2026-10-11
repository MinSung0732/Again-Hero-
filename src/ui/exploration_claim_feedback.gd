extends Control
# One retained overlay, two labels and fixed draw particles per cached modal.
const RULES := preload("res://src/data/exploration_reward_catalog.gd")
var textures: Array[Texture2D] = []
var labels: Array[Label] = []
var origins := PackedVector2Array([Vector2.ZERO,Vector2.ZERO])
var amounts := PackedInt32Array([0,0])
var elapsed := 0.0
var active := false
var effect_scale := 1.0
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
func configure(gold: Texture2D, research: Texture2D) -> void:
	textures = [gold,research]
	for i in range(2):
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(300,64)
		label.add_theme_font_size_override("font_size",42)
		label.add_theme_color_override("font_color",Color("ffe383") if i==0 else Color("bceaff"))
		label.add_theme_color_override("font_outline_color",Color("160e24"))
		label.add_theme_constant_override("outline_size",8)
		add_child(label)
		labels.append(label)
	stop()
func play(gold: int, research: int, gold_icon: Control, research_icon: Control, ratio: float) -> void:
	amounts[0] = gold
	amounts[1] = research
	effect_scale = ratio
	# Canvas transforms include the scaled/centered modal on portrait/mobile.
	var inverse := get_global_transform_with_canvas().affine_inverse()
	origins[0] = inverse*(gold_icon.get_global_transform_with_canvas()*(gold_icon.size*0.5))
	origins[1] = inverse*(research_icon.get_global_transform_with_canvas()*(research_icon.size*0.5))
	elapsed = 0
	active = true
	for i in range(2):
		labels[i].text = "+%d" % amounts[i]
		labels[i].visible = amounts[i]>0
	show()
	set_process(true)
	_process(0)
func stop() -> void:
	active = false
	set_process(false)
	hide()
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= RULES.CLAIM_FEEDBACK_SECONDS:
		stop()
		return
	var fade := 1.0-smoothstep(0.9,RULES.CLAIM_FEEDBACK_SECONDS,elapsed)
	var pop := lerpf(0.7,1.0,sin(clampf(elapsed/0.18,0,1)*PI*0.5))
	for i in range(2):
		var label := labels[i]
		label.scale = Vector2.ONE*effect_scale*pop
		label.position = origins[i]+Vector2(0,-(70+elapsed*50)*effect_scale)-label.size*label.scale*0.5
		label.modulate.a = fade
	queue_redraw()
func _draw() -> void:
	if not active: return
	for kind in range(2):
		if textures[kind]==null or amounts[kind]<=0: continue
		for particle in range(RULES.CLAIM_PARTICLES_PER_CURRENCY):
			var age := elapsed-float(particle)*0.045
			if age<0 or age>0.95: continue
			var spread := float(particle)-float(RULES.CLAIM_PARTICLES_PER_CURRENCY-1)*0.5
			var point := origins[kind]+Vector2(spread*34*age,-150*age+80*age*age)*effect_scale
			var icon_size := Vector2.ONE*44*effect_scale
			var alpha := 0.9*(1.0-smoothstep(0.55,0.95,age))
			draw_texture_rect(textures[kind],Rect2(point-icon_size*0.5,icon_size),false,Color(1,1,1,alpha))
