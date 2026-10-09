extends Control
## Presentation only; cached by the common cutscene player, no reward mutation.
const RIG := preload("res://src/ui/shuten_doji_portrait_rig.gd")
const REVEAL := preload("res://src/ui/shuten_doji_silhouette_reveal.gdshader")
const AURA := preload("res://src/ui/shuten_doji_sake_aura.gdshader")
const ART := "res://assets/art/Transcendent_monster/Shuten-doji/frames/"
const RIG_ORIGIN := Vector2(270, 805) - Vector2(335,1192) * 0.88
var stage: Node2D
var rig: Node2D
var background: Sprite2D
var name_label: Label
var name_backing: ColorRect
var reveal_material: ShaderMaterial
var effects: Array[Sprite2D] = []
var packs: Array = []
var elapsed := 0.0
var aura_materials: Array[ShaderMaterial] = []
var impact_flash: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage = Node2D.new()
	add_child(stage)
	background = Sprite2D.new()
	background.texture = load("res://assets/art/effects/gatcha/shuten_doji/sake_hall_v1.png")
	background.position = Vector2(270, 480)
	background.scale = Vector2(540, 960) / background.texture.get_size()
	stage.add_child(background)
	_add_aura(0.0, 1)
	for group in ["effect1", "effect2", "effect3"]:
		var frames: Array[Texture2D] = []
		for i in range(1, 9):
			frames.append(load(ART + group + "/effect_%02d.png" % i))
		packs.append(frames)
	for i in range(10):
		var sprite := Sprite2D.new()
		sprite.z_index = 1 if i < 4 else 3
		stage.add_child(sprite)
		effects.append(sprite)
	rig = RIG.new()
	rig.z_index = 2
	rig.scale = Vector2.ONE * 0.88
	# Center actual visible bounds, not the asymmetric transparent canvas.
	rig.position = RIG_ORIGIN
	stage.add_child(rig)
	reveal_material = ShaderMaterial.new()
	reveal_material.shader = REVEAL
	rig.mesh.material = reveal_material
	_add_aura(1.0, 3)
	impact_flash = ColorRect.new()
	impact_flash.size = Vector2(540, 820)
	impact_flash.color = Color("ff7358")
	impact_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_flash.z_index = 3
	stage.add_child(impact_flash)
	name_backing = ColorRect.new()
	name_backing.position = Vector2(0, 825)
	name_backing.size = Vector2(540, 135)
	name_backing.color = Color(0.045, 0.02, 0.06, 0.85)
	name_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_backing.z_index = 4
	stage.add_child(name_backing)
	name_label = Label.new()
	name_label.text = "슈텐-도지"
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

func _add_aura(front: float, layer: int) -> void:
	var quad := ColorRect.new()
	quad.size = Vector2(540, 820)
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quad.z_index = layer
	var material := ShaderMaterial.new()
	material.shader = AURA
	material.set_shader_parameter("foreground", front)
	quad.material = material
	aura_materials.append(material)
	stage.add_child(quad)

func _layout() -> void:
	if stage == null:
		return
	var factor := minf(size.x / 540.0, size.y / 960.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - Vector2(540, 960) * factor) * 0.5

func set_time(seconds: float) -> void:
	elapsed = maxf(0.0, seconds)
	rig.set_time(elapsed)
	# Short portrait push-in and damped release kick; viewport/layout stays fixed.
	var focus := smoothstep(1.35, 1.95, elapsed) * (1.0 - smoothstep(2.3, 3.2, elapsed))
	var scale_value := 0.88 * (1.0 + focus * 0.045)
	rig.scale = Vector2.ONE * scale_value
	var anchor := Vector2(335,1192)
	var kick_age := maxf(elapsed - 2.2, 0.0)
	var kick := sin(kick_age * 46.0) * exp(-kick_age * 9.0) * 3.5 if elapsed >= 2.2 else 0.0
	rig.position = Vector2(270 + kick, 805) - anchor * scale_value
	for material in aura_materials:
		material.set_shader_parameter("clock", elapsed)
	impact_flash.modulate.a = maxf(0.0, 1.0 - kick_age / 0.17) * 0.28 if elapsed >= 2.2 else 0.0
	rig.modulate.a = smoothstep(0.3, 0.75, elapsed)
	reveal_material.set_shader_parameter("reveal_edge", lerpf(-0.08, 1.1, smoothstep(1.3, 2.6, elapsed)))
	var light := lerpf(0.3, 0.85, smoothstep(1.3, 2.6, elapsed))
	background.modulate = Color(light, light, light)
	for i in range(effects.size()):
		var sprite := effects[i]
		var kind := 0 if i < 4 else 1 if i < 8 else 2
		var start := 0.35 if i < 4 else 2.2 if i < 8 else 2.48
		var age := elapsed - start - float(i % 2) * 0.12
		var duration := 4.0 if i < 4 else 0.8
		sprite.visible = age >= 0.0 and age < duration
		if not sprite.visible:
			continue
		sprite.texture = packs[kind][int(age * 10.0) % 8]
		var side := -1.0 if i % 2 == 0 else 1.0
		if i < 4:
			var upper := i >= 2
			sprite.position = Vector2(270 + side * (185 + sin(age * 1.5 + i) * 15), (470.0 if upper else 735.0) - age * 23)
			sprite.flip_h = side > 0
			sprite.scale = Vector2.ONE * (195.0 if upper else 245.0) / sprite.texture.get_width()
			sprite.modulate.a = smoothstep(0.0, 0.3, age) * (1.0 - smoothstep(3.2, 4.0, age)) * (0.50 if upper else 0.72)
		else:
			var outer := i >= 6
			sprite.position = Vector2(270 + side * (190 if outer else 90), 755 if i < 8 else 675)
			sprite.scale = Vector2.ONE * (255.0 if i < 8 else 210.0) / sprite.texture.get_width()
			sprite.modulate.a = smoothstep(0.0, 0.1, age) * (1.0 - smoothstep(0.5, 0.8, age)) * 0.85
	name_backing.modulate.a = smoothstep(3.8, 4.3, elapsed)
	name_label.modulate.a = name_backing.modulate.a

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("08060d"))
