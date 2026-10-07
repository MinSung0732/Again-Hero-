extends Control

signal finished

const CATALOG := preload("res://src/data/transcendent_cutscene_catalog.gd")
const EFFECT_LAYER := preload("res://src/ui/transcendent_cutscene_effect_layer.gd")
const EFFECT_SHADER := preload("res://src/ui/transcendent_cutscene_effects.gdshader")
const STAGE_SIZE := Vector2(1280, 720)
static var _texture_cache: Dictionary = {}
var _data: Dictionary = {}
var _character: Array[Texture2D] = []
var _circle: Array[Texture2D] = []
var _electric: Array[Texture2D] = []
var _pillar: Array[Texture2D] = []
var _halo: Texture2D
var _background: Texture2D
var _effects: Control
var _elapsed := 0.0
var _last_tick_usec := 0
var _running := false
var _generation := 0
var _name_label: Label
var _skip: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_effects = EFFECT_LAYER.new()
	_effects.player = self
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var effect_material := ShaderMaterial.new()
	effect_material.shader = EFFECT_SHADER
	_effects.material = effect_material
	add_child(_effects)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color("e9d9ac"))
	_name_label.add_theme_color_override("font_shadow_color", Color("101b30", 0.8))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	_skip = Button.new()
	_skip.text = "스킵 ››"
	_skip.custom_minimum_size = Vector2(120, 56)
	_skip.pressed.connect(skip)
	add_child(_skip)
	resized.connect(_layout)
	set_process(false)
	hide()


func play(monster_id: String) -> void:
	cancel()
	_data = CATALOG.get_entry(monster_id)
	if _data.is_empty():
		finished.emit()
		return
	var token := _generation
	_character.clear()
	_circle.clear()
	_electric.clear()
	_pillar.clear()
	_background = null
	_halo = null
	_elapsed = 0.0
	_name_label.text = String(_data.name)
	_name_label.modulate.a = 0.0
	show()
	move_to_front()
	_layout()
	var character_frames := await _load_frames("character", token)
	if token != _generation:
		return
	_character = character_frames
	var circle_frames := await _load_frames("circle", token)
	if token != _generation:
		return
	_circle = circle_frames
	var electric_frames := await _load_frames("electric", token)
	if token != _generation:
		return
	_electric = electric_frames
	var pillar_frames := await _load_frames("pillar", token)
	if token != _generation:
		return
	_pillar = pillar_frames
	var background_texture := await _load_texture(String(_data.get("background_path", "")))
	if token != _generation:
		return
	_background = background_texture
	var halo_texture := await _load_texture(String(_data.get("halo_path", "")))
	if token != _generation:
		return
	_halo = halo_texture
	_last_tick_usec = Time.get_ticks_usec()
	_running = true
	set_process(true)
	queue_redraw()
	_effects.queue_redraw()


func cancel() -> void:
	_generation += 1
	_running = false
	set_process(false)
	hide()



func skip() -> void:
	if not visible:
		return
	cancel()
	finished.emit()


func _exit_tree() -> void:
	cancel()


func _process(_delta: float) -> void:
	# Visual duration uses real time, independent of combat time_scale or headless FPS.
	var now := Time.get_ticks_usec()
	advance(float(now - _last_tick_usec) / 1000000.0)
	_last_tick_usec = now


# Deterministic clock also used by the presentation regression fixture.
func advance(delta: float) -> void:
	if not _running:
		return
	_elapsed += maxf(delta, 0.0)
	_name_label.modulate.a = smoothstep(4.15, 4.65, _elapsed)
	queue_redraw()
	_effects.queue_redraw()
	if _elapsed >= float(_data.duration):
		cancel()
		finished.emit()


static func stage_rect(view_size: Vector2, stage_size: Vector2 = STAGE_SIZE) -> Rect2:
	var factor := minf(view_size.x / stage_size.x, view_size.y / stage_size.y)
	var extent := stage_size * factor
	return Rect2((view_size - extent) * 0.5, extent)


static func cover_region(texture_size: Vector2, target_size: Vector2) -> Rect2:
	var factor := maxf(target_size.x / texture_size.x, target_size.y / texture_size.y)
	var region_size := target_size / factor
	return Rect2((texture_size - region_size) * 0.5, region_size)


func _layout() -> void:
	if not is_instance_valid(_name_label):
		return
	var stage_size: Vector2 = _data.get("stage_size", STAGE_SIZE)
	var stage := stage_rect(size, stage_size)
	var factor := stage.size.x / stage_size.x
	var name_rect: Rect2 = _data.get("name_rect", Rect2(340, 630, 600, 54))
	_name_label.position = stage.position + name_rect.position * factor
	_name_label.size = name_rect.size * factor
	_name_label.add_theme_font_size_override("font_size", maxi(12, int(float(_data.get("name_font_size", 24)) * factor)))
	var ui_scale := maxf(1.0, factor)
	_skip.position = Vector2(size.x - 192 * ui_scale, 16 * ui_scale)
	_skip.size = Vector2(176, 88) * ui_scale
	_skip.add_theme_font_size_override("font_size", int(20 * ui_scale))


func _load_frames(kind: String, token: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var directory := String(_data.get(kind + "_dir", ""))
	var prefix := String(_data.get(kind + "_prefix", ""))
	var count := int(_data.get(kind + "_count", 0))
	for index in range(count):
		var texture := await _load_texture("%s%s_%02d.png" % [directory, prefix, index + 1])
		if token != _generation:
			return []
		if texture != null:
			frames.append(texture)
	return frames


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var texture: Texture2D
	if ResourceLoader.exists(path):
		var err := ResourceLoader.load_threaded_request(path, "Texture2D")
		if err == OK:
			while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
				texture = ResourceLoader.load_threaded_get(path) as Texture2D
		else:
			texture = load(path) as Texture2D
	# Raw PNG fallback supports a fresh clone/dev preview before editor imports.
	if texture == null and FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	if texture != null:
		_texture_cache[path] = texture
	return texture


func _draw() -> void:
	if _data.is_empty():
		return
	var t := _elapsed
	var light := lerpf(0.24, 1.0, smoothstep(1.0, 3.7, t))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.16, 0.28) * Color(light, light, light))
	var stage_size: Vector2 = _data.get("stage_size", STAGE_SIZE)
	var stage := stage_rect(size, stage_size)
	var factor := stage.size.x / stage_size.x
	if _background != null:
		# Cover only the environment. The character stage always uses contain.
		draw_texture_rect_region(_background, Rect2(Vector2.ZERO, size), cover_region(_background.get_size(), size), Color(light, light, light))
	draw_set_transform(stage.position, 0.0, Vector2.ONE * factor)
	if _background == null:
		_draw_temporary_temple(light, t)
	var halo_alpha := smoothstep(3.0, 3.7, t)
	if halo_alpha > 0.0:
		# Thin geometric halo, not a badge/title; independent of the character.
		if _halo != null:
			draw_texture_rect(_halo, _data.get("halo_rect", Rect2(378, 68, 524, 524)), false, Color(1, 1, 1, halo_alpha))
		else:
			draw_arc(_data.get("halo_center", Vector2(640, 330)), float(_data.get("halo_radius", 242)), 0, TAU, 80, Color(1, 0.81, 0.38, halo_alpha * 0.7), 3, false)
	if t >= 2.0 and not _character.is_empty():
		var index := int(t * float(_data.character_fps)) % _character.size()
		var reveal := smoothstep(3.0, 3.9, t)
		var opacity := smoothstep(2.0, 2.6, t)
		var region: Rect2 = _data.character_region
		var feet: Array = _data.feet_y
		var uniform_scale := float(_data.character_scale)
		var anchor: Vector2 = _data.anchor
		var position := anchor - Vector2(region.size.x * 0.5, feet[index] - region.position.y) * uniform_scale
		var color := Color(0.05, 0.09, 0.18, opacity).lerp(Color(1, 1, 1, opacity), reveal)
		draw_texture_rect_region(_character[index], Rect2(position, region.size * uniform_scale), region, color)
	var electric_alpha := (0.25 + 0.65 * smoothstep(0.4, 1.1, t)) * (1.0 - 0.75 * smoothstep(4.0, 4.8, t))
	# Fixed particle count, deterministic trajectories, no per-frame nodes/arrays.
	var particle_center: Vector2 = _data.get("particle_center", Vector2(640, 560))
	var particle_height := float(_data.get("particle_height", 390))
	for index in range(18):
		var phase := t * 0.4 + float(index) * 0.61
		var x := particle_center.x + sin(phase) * (210 + index * 7)
		var y := particle_center.y - fmod(t * 72 + index * 61, particle_height)
		draw_rect(Rect2(Vector2(x, y).floor(), Vector2(3, 3)), Color(0.65, 0.88, 1, electric_alpha))
	draw_set_transform(Vector2.ZERO)
	var flash := maxf(0.0, 1.0 - absf(t - 1.18) / 0.17) * 0.75
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.92, 1, flash))


func _draw_temporary_temple(light: float, t: float) -> void:
	# Explicit placeholder architecture: replace background_path with finished pixel art.
	var stone := Color(0.88, 0.90, 0.88) * Color(light, light, light)
	var gold := Color(0.91, 0.72, 0.32) * Color(light, light, light)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.3, 0.48, 0.72) * Color(light, light, light))
	for index in range(9):
		var x := float(index) * 160 - 90 + sin(t * 0.15 + index) * 5
		var y := 390.0 + float(index % 3) * 25
		draw_rect(Rect2(x, y, 210, 100), stone.darkened(0.15))
		draw_rect(Rect2(x + 25, y - 20, 140, 140), stone)
	for index in range(6):
		var x := 100.0 + index * 210
		draw_rect(Rect2(x, 110, 40, 385), stone)
		draw_rect(Rect2(x - 10, 100, 60, 18), gold)
		draw_rect(Rect2(x - 14, 490, 68, 22), gold)
	draw_rect(Rect2(66, 72, 1148, 24), stone)
	draw_rect(Rect2(55, 62, 1170, 10), gold)
	for index in range(4):
		draw_rect(Rect2(170 - index * 40, 544 + index * 26, 940 + index * 80, 24), stone.darkened(0.05 * index))
		draw_rect(Rect2(170 - index * 40, 544 + index * 26, 940 + index * 80, 3), gold)
