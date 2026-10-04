extends RefCounted

# Compact nine-patch metalwork for formerly plain UI boxes. Existing illustrated
# frames and transparent backings are left alone. No decorative nodes/hit regions.
static var _textures: Dictionary = {}
const PATCH := 16.0
const TEMPLATE := """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
<path d="M8 0H56V2H62V8H64V56H62V62H56V64H8V62H2V56H0V8H2V2H8Z" fill="#$SHADOW"/>
<path d="M8 2H56V4H60V8H62V56H60V60H56V62H8V60H4V56H2V8H4V4H8Z" fill="#$EDGE"/>
<path d="M10 5H54V7H57V10H59V54H57V57H54V59H10V57H7V54H5V10H7V7H10Z" fill="#$SHADOW"/>
<path d="M11 7H53V9H55V11H57V53H55V55H53V57H11V55H9V53H7V11H9V9H11Z" fill="#$FILL" fill-opacity="$ALPHA"/>
<path d="M8 2H56V3H8ZM4 8H5V56H4ZM8 5H13V6H8ZM5 8H6V13H5ZM51 5H56V6H51ZM58 8H59V13H58Z" fill="#$LIGHT"/>
<path d="M8 60H56V62H8ZM60 8H62V56H60Z" fill="#$LOW"/>
<path d="M8 8H12V10H10V12H8ZM52 8H56V12H54V10H52ZM8 52H10V54H12V56H8ZM54 52H56V56H52V54H54Z" fill="#$LIGHT"/>
<path d="M10 14H14V15H10ZM50 14H54V15H50ZM10 49H14V50H10ZM50 49H54V50H50Z" fill="#$LOW"/>
</svg>"""

static func skin_style(source: StyleBox) -> StyleBox:
	if not source is StyleBoxFlat:
		return source
	var flat := source as StyleBoxFlat
	if not flat.draw_center or flat.bg_color.a <= 0.0 or flat.border_color.a <= 0.0 or flat.get_border_width_min() <= 0:
		return source
	var key := flat.bg_color.to_html() + ":" + flat.border_color.to_html()
	if not _textures.has(key):
		var edge := flat.border_color
		var svg := TEMPLATE.replace("$FILL", flat.bg_color.to_html(false)).replace("$ALPHA", str(flat.bg_color.a))
		svg = svg.replace("$EDGE", edge.to_html(false)).replace("$SHADOW", edge.darkened(0.72).to_html(false))
		svg = svg.replace("$LIGHT", edge.lightened(0.28).to_html(false)).replace("$LOW", edge.darkened(0.35).to_html(false))
		var image := Image.new()
		if image.load_svg_from_string(svg) != OK:
			return source # Optional presentation must never disable a control.
		_textures[key] = ImageTexture.create_from_image(image)
	var result := StyleBoxTexture.new()
	result.texture = _textures[key]
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
	elif control is TabContainer:
		keys = ["panel", "tab_selected", "tab_unselected", "tab_hovered"]
	elif control is Label and control.has_theme_stylebox_override("normal"):
		keys = ["normal"]
	for key in keys:
		var source := control.get_theme_stylebox(key)
		var style := skin_style(source)
		if style != source:
			control.add_theme_stylebox_override(key, style)

static func apply_tree(root: Node) -> void:
	if root is Control:
		apply(root as Control)
	for child in root.get_children():
		apply_tree(child)
