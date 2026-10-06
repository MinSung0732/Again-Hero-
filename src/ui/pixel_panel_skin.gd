extends RefCounted

# Reuse the lobby's authored gold/purple pixel frame. Compose its atlas pieces
# once, then cache nine-patch textures by fill; controls retain their hit regions.
static var _textures: Dictionary = {}
static var _frame: Image
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
	return _frame

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
		image.fill(flat.bg_color)
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
		var style := skin_style(source)
		if style != source:
			control.add_theme_stylebox_override(key, style)

static func apply_tree(root: Node) -> void:
	if root is Control:
		apply(root as Control)
	for child in root.get_children():
		apply_tree(child)
