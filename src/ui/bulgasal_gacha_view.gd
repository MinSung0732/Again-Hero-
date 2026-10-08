extends Control
## Presentation-only gacha view; shared original rig, no reward authority.
const RIG := preload("res://src/ui/bulgasal_portrait_rig.gd")
const ROOT := "res://assets/art/effects/gatcha/bulgasal/"
var rig: Node2D
var stage: Node2D
var background: Sprite2D
var effects_behind: Array[Sprite2D] = []
var effects_front: Array[Sprite2D] = []
var label: Label
var elapsed := 0.0
var _textures: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage = Node2D.new()
	add_child(stage)
	background = Sprite2D.new()
	background.z_index = 0
	background.texture = _texture(ROOT + "forge_background.png")
	background.position = Vector2(270, 480)
	background.scale = Vector2(540, 960) / background.texture.get_size()
	stage.add_child(background)
	rig = RIG.new()
	rig.z_index = 2
	rig.scale = Vector2.ONE * 0.58
	rig.position = Vector2(47.28, 35.8)
	stage.add_child(rig)
	var tex := _texture(ROOT + "forge_vfx_atlas.png")
	for i in range(4):
		effects_behind.append(_fx_sprite(tex, i, 1))
	for i in range(10):
		effects_front.append(_fx_sprite(tex, 3 if i < 6 else 1, 3))
	label = Label.new()
	label.z_index = 4
	label.text = "불가살"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(90, 825)
	label.size = Vector2(360, 76)
	var font := FontFile.new()
	font.load_dynamic_font("res://assets/fonts/Galmuri11.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color("ffe4a4"))
	label.add_theme_color_override("font_outline_color", Color("100b09"))
	label.add_theme_constant_override("outline_size", 3)
	stage.add_child(label)
	resized.connect(_layout)
	_layout()
	set_process(false)
	set_time(0.0)

func _texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("Missing imported texture: " + path)
		return null
	_textures[path] = tex
	return tex

func _fx_sprite(tex: Texture2D, cell: int, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.region_enabled = true
	var half := tex.get_size() * 0.5
	sprite.region_rect = Rect2(Vector2(cell % 2, cell / 2) * half, half)
	sprite.z_index = z
	stage.add_child(sprite)
	return sprite

func _layout() -> void:
	var factor := minf(size.x / 540.0, size.y / 960.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - Vector2(540, 960) * factor) * 0.5

func set_time(seconds: float) -> void:
	elapsed = seconds
	rig.set_time(seconds)
	var reveal := smoothstep(0.75, 1.95, seconds)
	var brightness := lerpf(0.025, 1.0, reveal)
	rig.modulate = Color(brightness, brightness, brightness, smoothstep(0.05, 0.3, seconds))
	var background_light := lerpf(0.20, 0.64, reveal)
	background.modulate = Color(background_light, background_light, background_light)
	var charge := smoothstep(1.75, 2.35, seconds) * (1.0 - smoothstep(2.9, 3.6, seconds))
	var hold := smoothstep(0.4, 1.4, seconds) * (1.0 - smoothstep(3.7, 4.8, seconds))
	for i in range(2):
		var flame := effects_behind[i]
		flame.region_rect.position = Vector2.ZERO
		flame.position = Vector2(100 if i == 0 else 440, 570)
		flame.scale = Vector2(190, 395) / flame.region_rect.size
		flame.rotation = (0.18 if i == 0 else -0.18) + sin(seconds * 1.7) * 0.025
		flame.modulate.a = 0.2 * hold + 0.65 * charge
	for i in range(2, 4):
		var swirl := effects_behind[i]
		swirl.region_rect.position = Vector2(0, swirl.region_rect.size.y)
		swirl.position = Vector2(270, 695 if i == 2 else 430)
		swirl.scale = Vector2(430, 145 if i == 2 else 430) / swirl.region_rect.size
		swirl.rotation = 0.0 if i == 2 else sin(seconds) * 0.05
		swirl.modulate.a = 0.18 * hold + 0.4 * charge
	for i in range(6):
		var spark := effects_front[i]
		var angle := float(i) * 2.399 + seconds * 0.25
		spark.position = Vector2(270 + cos(angle) * 185, 715 - fposmod(float(i) / 6.0 + seconds * 0.15, 1.0) * 570)
		spark.scale = Vector2.ONE * 0.08
		spark.modulate.a = 0.25 * hold
	for i in range(6, 10):
		var shard := effects_front[i]
		var age := seconds - (2.3 if i < 8 else 2.48)
		shard.visible = age >= 0.0 and age < 0.9
		if not shard.visible:
			continue
		var side := -1.0 if i % 2 == 0 else 1.0
		shard.position = Vector2(270 + side * (105 + age * 110), 490 - age * 100 + age * age * 80)
		shard.scale = Vector2(160, 240) / shard.region_rect.size
		shard.rotation = side * 0.35
		shard.modulate.a = pow(1.0 - age / 0.9, 1.5) * 0.9
	label.modulate.a = smoothstep(3.95, 4.45, seconds)
