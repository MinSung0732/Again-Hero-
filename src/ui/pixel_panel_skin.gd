extends RefCounted

# Reuse the lobby's authored gold/purple pixel frame. Compose its atlas pieces
# once, then cache nine-patch textures by fill; controls retain their hit regions.
const CLEAN_BUTTON_FRAME := preload("res://assets/art/UI/clean_frames/button_frame.tres")
static var _textures: Dictionary = {}
static var _frame: Image
static var _outside := PackedByteArray()
const PATCH := 16.0
const FRAME_PATH := "res://assets/art/UI/newUI_frame/frame_06.png"

static func _frame_image() -> Image:
	if _frame != null:
		return _frame
	var texture := load(FRAME_PATH) as Texture2D
	var sheet := texture.get_image() if texture != null else null
	if sheet == null:
		return null
	_frame = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_frame.fill(Color.TRANSPARENT)
	# Atlas gutters are excluded; only corners and edge strips are stretched.
	var regions := [Rect2i(0, 0, 56, 58), Rect2i(64, 0, 204, 58), Rect2i(276, 0, 56, 58),
		Rect2i(0, 66, 56, 71), Rect2i(276, 66, 56, 71),
		Rect2i(0, 144, 56, 64), Rect2i(64, 144, 204, 64), Rect2i(276, 144, 56, 64)]
	var destinations := [Rect2i(0, 0, 16, 16), Rect2i(16, 0, 32, 16), Rect2i(48, 0, 16, 16),
		Rect2i(0, 16, 16, 32), Rect2i(48, 16, 16, 32),
		Rect2i(0, 48, 16, 16), Rect2i(16, 48, 32, 16), Rect2i(48, 48, 16, 16)]
	for index in regions.size():
		var piece := sheet.get_region(regions[index])
		piece.resize(destinations[index].size.x, destinations[index].size.y, Image.INTERPOLATE_NEAREST)
		_frame.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), destinations[index].position)
	_build_fill_mask()
	return _frame

static func _build_fill_mask() -> void:
	# Flood only transparent pixels connected to the outside. Interior gaps and
	# the center retain their fill; cut corners keep the authored transparency.
	# This bounded 64x64 mask is built once, not per control or per frame.
	_outside.resize(4096)
	_outside.fill(0)
	var queue := PackedInt32Array()
	for y in 64:
		for x in 64:
			if (x == 0 or x == 63 or y == 0 or y == 63) and _frame.get_pixel(x, y).a <= 0.5:
				var index := y * 64 + x
				_outside[index] = 1
				queue.append(index)
	var offsets := PackedInt32Array([-1, 1, -64, 64])
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		for offset in offsets:
			var next := index + offset
			if next < 0 or next >= 4096 or _outside[next] != 0:
				continue
			if absi(next % 64 - index % 64) + absi(next / 64 - index / 64) != 1:
				continue
			if _frame.get_pixel(next % 64, next / 64).a <= 0.5:
				_outside[next] = 1
				queue.append(next)

static func skin_style(source: StyleBox) -> StyleBox:
	if not source is StyleBoxFlat:
		return source
	var flat := source as StyleBoxFlat
	if not flat.draw_center or flat.bg_color.a <= 0.0 or flat.border_color.a <= 0.0 or flat.get_border_width_min() <= 0:
		return source
	var key := flat.bg_color.to_html()
	if not _textures.has(key):
		var frame := _frame_image()
		if frame == null:
			return source # Optional decoration must never disable a control.
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in 64:
			for x in 64:
				if _outside[y * 64 + x] == 0:
					image.set_pixel(x, y, flat.bg_color)
		image.blend_rect(frame, Rect2i(0, 0, 64, 64), Vector2i.ZERO)
		_textures[key] = ImageTexture.create_from_image(image)
	var result := StyleBoxTexture.new()
	result.texture = _textures[key]
	# Retain a subdued frame for disabled/secondary states and a bright focus.
	if flat.border_color.s < 0.15:
		result.modulate_color = Color(0.65, 0.65, 0.72, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, PATCH)
		# Preserve effective margins even when the old box used border defaults.
		result.set_content_margin(side, flat.get_margin(side))
	return result

static func button_style(source: StyleBox) -> StyleBox:
	# One continuous border; panel artwork and invisible input hit regions stay separate.
	if source is StyleBoxEmpty:
		return source
	var result := CLEAN_BUTTON_FRAME.duplicate() as StyleBoxFlat
	result.bg_color = Color("281832")
	result.border_color = Color("d9b45b")
	result.set_border_width_all(2)
	if source is StyleBoxFlat:
		var flat := source as StyleBoxFlat
		if not flat.draw_center or flat.bg_color.a <= 0.0:
			return source
		result.bg_color = flat.bg_color
		if flat.border_color.a > 0:
			result.border_color = flat.border_color
	elif source is StyleBoxTexture:
		var tint := (source as StyleBoxTexture).modulate_color
		result.bg_color *= tint
		result.border_color *= tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_content_margin(side, source.get_margin(side))
	return result

static func apply(control: Control) -> void:
	var keys: Array[String] = []
	if control is PanelContainer or control is Panel:
		keys = ["panel"]
	elif control is Button:
		keys = ["normal", "hover", "pressed", "disabled", "focus"]
	elif control is LineEdit:
		keys = ["normal", "focus", "read_only"]
	elif control is TabContainer:
		keys = ["panel", "tab_selected", "tab_unselected", "tab_hovered"]
	elif control is Label and control.has_theme_stylebox_override("normal"):
		keys = ["normal"]
	for key in keys:
		if control is LineEdit and not control.has_theme_stylebox_override(key):
			var input := StyleBoxFlat.new()
			input.bg_color = Color("241430") if key != "focus" else Color("38204d")
			input.border_color = Color("eac14d")
			input.set_border_width_all(2)
			input.set_content_margin_all(16)
			control.add_theme_stylebox_override(key, input)
		var source := control.get_theme_stylebox(key)
		var style := button_style(source) if control is Button else skin_style(source)
		if style != source:
			control.add_theme_stylebox_override(key, style)

static func apply_tree(root: Node) -> void:
	if root is Control:
		apply(root as Control)
	for child in root.get_children():
		apply_tree(child)
