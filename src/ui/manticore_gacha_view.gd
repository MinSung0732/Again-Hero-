extends Control
## Presentation only; cached by the common cutscene player, no reward mutation.
const RIG := preload("res://src/ui/manticore_portrait_rig.gd")
const REVEAL := preload("res://src/ui/manticore_silhouette_reveal.gdshader")
const ART := "res://assets/art/Transcendent_monster/manticore/frames/"
var stage: Node2D
var rig: Node2D
var background: Sprite2D
var name_label: Label
var name_backing: ColorRect
var reveal_material: ShaderMaterial
var effects: Array[Sprite2D] = []
var packs: Array = []
var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage = Node2D.new()
	add_child(stage)
	background = Sprite2D.new()
	background.texture = load("res://assets/art/effects/gatcha/manticore/venom_sanctuary.png")
	background.position = Vector2(270, 480)
	background.scale = Vector2(540, 960) / background.texture.get_size()
	stage.add_child(background)
	for group in ["effect2", "effect3", "effect4"]:
		var frames: Array[Texture2D] = []
		for i in range(1, 9):
			frames.append(load(ART + group + "/effect_%02d.png" % i))
		packs.append(frames)
	for i in range(6):
		var sprite := Sprite2D.new()
		sprite.z_index = 1 if i < 4 else 3
		stage.add_child(sprite)
		effects.append(sprite)
	rig = RIG.new()
	rig.z_index = 2
	rig.scale = Vector2.ONE * 0.69
	# Center actual visible bounds, not the asymmetric transparent canvas.
	rig.position = Vector2(270, 805) - Vector2(329, 1223) * 0.69
	stage.add_child(rig)
	reveal_material = ShaderMaterial.new()
	reveal_material.shader = REVEAL
	rig.mesh.material = reveal_material
	name_backing = ColorRect.new()
	name_backing.position = Vector2(0, 825)
	name_backing.size = Vector2(540, 135)
	name_backing.color = Color(0.045, 0.02, 0.06, 0.85)
	name_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_backing.z_index = 4
	stage.add_child(name_backing)
	name_label = Label.new()
	name_label.text = "만티코어"
	name_label.position = Vector2(60, 835)
	name_label.size = Vector2(420, 76)
	name_label.z_index = 5
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font", load("res://assets/fonts/Galmuri11.ttf"))
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", Color("ffe6a6"))
	name_label.add_theme_color_override("font_outline_color", Color("1a0c20"))
	name_label.add_theme_constant_override("outline_size", 4)
	stage.add_child(name_label)
	resized.connect(_layout)
	_layout()
	set_process(false)
	set_time(0.0)

func _layout() -> void:
	if stage == null:
		return
	var factor := minf(size.x / 540.0, size.y / 960.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - Vector2(540, 960) * factor) * 0.5

func set_time(seconds: float) -> void:
	elapsed = maxf(0.0, seconds)
	rig.set_time(elapsed)
	rig.modulate.a = smoothstep(0.3, 0.75, elapsed)
	reveal_material.set_shader_parameter("reveal_edge", lerpf(-0.08, 1.1, smoothstep(1.3, 2.6, elapsed)))
	var light := lerpf(0.3, 0.85, smoothstep(1.3, 2.6, elapsed))
	background.modulate = Color(light, light, light)
	for i in range(effects.size()):
		var sprite := effects[i]
		var kind := 0 if i < 2 else 1 if i < 4 else 2
		var start := 0.5 if i < 2 else 2.2 if i < 4 else 2.5
		var age := elapsed - start - float(i % 2) * 0.12
		var duration := 3.3 if i < 2 else 0.8
		sprite.visible = age >= 0.0 and age < duration
		if not sprite.visible:
			continue
		sprite.texture = packs[kind][int(age * 10.0) % 8]
		var side := -1.0 if i % 2 == 0 else 1.0
		if i < 2:
			sprite.position = Vector2(270 + side * (155 + sin(age * 1.5) * 12), 660 - age * 16)
			sprite.flip_h = side > 0
			sprite.scale = Vector2.ONE * 180.0 / sprite.texture.get_width()
			sprite.modulate.a = smoothstep(0.0, 0.3, age) * (1.0 - smoothstep(2.5, 3.3, age)) * 0.55
		else:
			sprite.position = Vector2(270 + side * (125 if i < 4 else 175), 770)
			sprite.scale = Vector2.ONE * (190.0 if i < 4 else 140.0) / sprite.texture.get_width()
			sprite.modulate.a = smoothstep(0.0, 0.1, age) * (1.0 - smoothstep(0.5, 0.8, age)) * 0.85
	name_backing.modulate.a = smoothstep(3.8, 4.3, elapsed)
	name_label.modulate.a = name_backing.modulate.a

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("08060d"))
