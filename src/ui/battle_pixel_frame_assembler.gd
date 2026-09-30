extends RefCounted
class_name BattlePixelFrameAssembler

const FRAME_NODE_NAME := "PixelAssetFrame"

static func add_split_frame(
	target: Control,
	frame_dir: String,
	scale: float,
	center_texture_path: String = "",
	center_patch_margin: int = 20,
	clean_center_color: Color = Color(0.0, 0.0, 0.0, 0.0),
	clean_center_inset: float = 0.0
) -> void:
	if target == null:
		return
	if scale <= 0.0:
		return

	var existing := target.get_node_or_null(FRAME_NODE_NAME)
	if existing != null:
		existing.queue_free()

	var textures := {
		"top_left": _load_texture(frame_dir + "/part_01.png"),
		"top_right": _load_texture(frame_dir + "/part_02.png"),
		"top": _load_texture(frame_dir + "/part_03.png"),
		"left": _load_texture(frame_dir + "/part_05.png"),
		"right": _load_texture(frame_dir + "/part_06.png"),
		"bottom_left": _load_texture(frame_dir + "/part_07.png"),
		"bottom_right": _load_texture(frame_dir + "/part_08.png"),
		"bottom": _load_texture(frame_dir + "/part_09.png"),
	}
	for texture in textures.values():
		if texture == null:
			return

	var overlay := Control.new()
	overlay.name = FRAME_NODE_NAME
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(overlay)
	target.move_child(overlay, 0)

	if clean_center_color.a > 0.0:
		_add_clean_center_panel(
			overlay,
			clean_center_color,
			maxf(clean_center_inset, 0.0)
		)

	if not center_texture_path.is_empty():
		_add_center_panel(
			overlay,
			center_texture_path,
			maxi(center_patch_margin, 0)
		)

	var top_left: Texture2D = textures["top_left"]
	var top_right: Texture2D = textures["top_right"]
	var top: Texture2D = textures["top"]
	var left: Texture2D = textures["left"]
	var right: Texture2D = textures["right"]
	var bottom_left: Texture2D = textures["bottom_left"]
	var bottom_right: Texture2D = textures["bottom_right"]
	var bottom: Texture2D = textures["bottom"]

	var top_left_size := top_left.get_size() * scale
	var top_right_size := top_right.get_size() * scale
	var bottom_left_size := bottom_left.get_size() * scale
	var bottom_right_size := bottom_right.get_size() * scale
	var top_height := top.get_height() * scale
	var bottom_height := bottom.get_height() * scale
	var left_width := left.get_width() * scale
	var right_width := right.get_width() * scale

	_add_corner(
		overlay,
		top_left,
		Vector2.ZERO,
		top_left_size,
		Vector2.ZERO
	)
	_add_corner(
		overlay,
		top_right,
		Vector2(1.0, 0.0),
		top_right_size,
		Vector2(-top_right_size.x, 0.0)
	)
	_add_tiled_piece(
		overlay,
		top,
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(top_left_size.x, 0.0),
		Vector2(-top_right_size.x, top_height)
	)
	_add_tiled_piece(
		overlay,
		left,
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(0.0, top_left_size.y),
		Vector2(left_width, -bottom_left_size.y)
	)
	_add_tiled_piece(
		overlay,
		right,
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(-right_width, top_right_size.y),
		Vector2(0.0, -bottom_right_size.y)
	)
	_add_corner(
		overlay,
		bottom_left,
		Vector2(0.0, 1.0),
		bottom_left_size,
		Vector2(0.0, -bottom_left_size.y)
	)
	_add_corner(
		overlay,
		bottom_right,
		Vector2(1.0, 1.0),
		bottom_right_size,
		Vector2(-bottom_right_size.x, -bottom_right_size.y)
	)
	_add_tiled_piece(
		overlay,
		bottom,
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(bottom_left_size.x, -bottom_height),
		Vector2(-bottom_right_size.x, 0.0)
	)


static func clear_button_style(button: Button) -> void:
	if button == null:
		return
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)


static func clear_panel_style(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


static func apply_clean_panel_background(
	panel: PanelContainer,
	bg_color: Color = Color(0.035, 0.032, 0.075, 0.98),
	content_margin: float = 0.0
) -> void:
	if panel == null:
		return

	var background := StyleBoxFlat.new()
	background.bg_color = bg_color
	var safe_margin := maxf(content_margin, 0.0)
	background.content_margin_left = safe_margin
	background.content_margin_top = safe_margin
	background.content_margin_right = safe_margin
	background.content_margin_bottom = safe_margin
	panel.add_theme_stylebox_override("panel", background)


static func apply_progress_background(
	bar: ProgressBar,
	texture_path: String,
	horizontal_margin: float = 18.0,
	vertical_margin: float = 7.0
) -> void:
	if bar == null:
		return
	var texture := _load_texture(texture_path)
	if texture == null:
		return

	var background := StyleBoxTexture.new()
	background.texture = texture
	background.texture_margin_left = maxf(horizontal_margin, 0.0)
	background.texture_margin_top = maxf(vertical_margin, 0.0)
	background.texture_margin_right = maxf(horizontal_margin, 0.0)
	background.texture_margin_bottom = maxf(vertical_margin, 0.0)
	background.draw_center = true
	bar.add_theme_stylebox_override("background", background)


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _add_center_panel(
	parent: Control,
	texture_path: String,
	patch_margin: int
) -> void:
	var texture := _load_texture(texture_path)
	if texture == null:
		return

	var panel := NinePatchRect.new()
	panel.name = "Center"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture = texture
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.draw_center = true
	panel.patch_margin_left = patch_margin
	panel.patch_margin_top = patch_margin
	panel.patch_margin_right = patch_margin
	panel.patch_margin_bottom = patch_margin
	panel.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	panel.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(panel)


static func _add_clean_center_panel(
	parent: Control,
	color: Color,
	inset: float
) -> void:
	var panel := ColorRect.new()
	panel.name = "Center"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.color = color
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = inset
	panel.offset_top = inset
	panel.offset_right = -inset
	panel.offset_bottom = -inset
	parent.add_child(panel)


static func _add_corner(
	parent: Control,
	texture: Texture2D,
	anchor: Vector2,
	piece_size: Vector2,
	offset: Vector2
) -> void:
	var piece := TextureRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.texture = texture
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_SCALE
	piece.anchor_left = anchor.x
	piece.anchor_top = anchor.y
	piece.anchor_right = anchor.x
	piece.anchor_bottom = anchor.y
	piece.offset_left = offset.x
	piece.offset_top = offset.y
	piece.offset_right = offset.x + piece_size.x
	piece.offset_bottom = offset.y + piece_size.y
	parent.add_child(piece)


static func _add_tiled_piece(
	parent: Control,
	texture: Texture2D,
	anchor_start: Vector2,
	anchor_end: Vector2,
	offset_start: Vector2,
	offset_end: Vector2
) -> void:
	var piece := TextureRect.new()
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tiles_horizontally := not is_equal_approx(
		anchor_start.x,
		anchor_end.x
	)
	piece.texture = _make_seamless_edge_strip(
		texture,
		tiles_horizontally
	)
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_TILE
	piece.anchor_left = anchor_start.x
	piece.anchor_top = anchor_start.y
	piece.anchor_right = anchor_end.x
	piece.anchor_bottom = anchor_end.y
	piece.offset_left = offset_start.x
	piece.offset_top = offset_start.y
	piece.offset_right = offset_end.x
	piece.offset_bottom = offset_end.y
	parent.add_child(piece)


static func _make_seamless_edge_strip(
	texture: Texture2D,
	tiles_horizontally: bool
) -> Texture2D:
	var texture_size := texture.get_size()
	var strip := AtlasTexture.new()
	strip.atlas = texture
	if tiles_horizontally:
		var strip_width := minf(8.0, texture_size.x)
		strip.region = Rect2(
			floorf((texture_size.x - strip_width) * 0.5),
			0.0,
			strip_width,
			texture_size.y
		)
	else:
		var strip_height := minf(8.0, texture_size.y)
		strip.region = Rect2(
			0.0,
			floorf((texture_size.y - strip_height) * 0.5),
			texture_size.x,
			strip_height
		)
	return strip
