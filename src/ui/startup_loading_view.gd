extends Control

const CATALOG := preload("res://src/data/startup_catalog.gd")
const CASTLE := preload("res://assets/art/UI/startup/moon_castle.png")
const CAMP := preload("res://assets/art/UI/startup/moon_camp.png")
const LOGO := preload("res://assets/art/UI/logo/AgainHeroLogo.png")
const PIXEL_PANEL_SKIN := preload("res://src/ui/pixel_panel_skin.gd")

var background: TextureRect
var heading: Label
var detail: Label
var progress_bar: ProgressBar
var progress_label: Label
var tip_label: Label
var _tip_index := 0
var _tip_timer: Timer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = texture(self, CAMP, Rect2(0, 0, 1, 1), true)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.015, 0.065, 0.15)
	place(self, shade, Rect2(0, 0, 1, 1))
	texture(self, LOGO, Rect2(0.08, 0.055, 0.84, 0.20))
	heading = label(self, "로비 준비 중", 42, Rect2(0.1, 0.29, 0.8, 0.05))
	detail = label(self, "필요한 리소스를 불러오고 있습니다.", 25, Rect2(0.1, 0.345, 0.8, 0.055))
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.add_theme_stylebox_override("background", plate(Color("100c20")))
	progress_bar.add_theme_stylebox_override("fill", plate(Color("a348d3"), Color("e4bcff")))
	place(self, progress_bar, Rect2(0.1, 0.735, 0.8, 0.035))
	progress_label = label(self, "0%", 28, Rect2(0.1, 0.735, 0.8, 0.035))
	var tip_panel := Panel.new()
	tip_panel.add_theme_stylebox_override("panel", plate(Color(0.05, 0.03, 0.1, 0.93)))
	place(self, tip_panel, Rect2(0.1, 0.8, 0.8, 0.115))
	label(tip_panel, "◆  TIP  ◆", 27, Rect2(0.07, 0.10, 0.86, 0.28), Color("e8c2ff"))
	tip_label = label(tip_panel, CATALOG.TIPS[0], 24, Rect2(0.08, 0.40, 0.84, 0.47))
	PIXEL_PANEL_SKIN.apply(tip_panel)
	_tip_timer = Timer.new()
	_tip_timer.wait_time = 4.0
	_tip_timer.timeout.connect(_next_tip)
	add_child(_tip_timer)
	visibility_changed.connect(_sync_tip_timer)
	_sync_tip_timer()


func configure(title: String, description: String, resource_screen: bool = false) -> void:
	heading.text = title
	detail.text = description
	background.texture = CASTLE if resource_screen else CAMP
	set_progress(0.0)


func set_progress(value: float) -> void:
	progress_bar.value = clampf(value, 0.0, 1.0) * 100.0
	progress_label.text = "%d%%" % int(progress_bar.value)


func _sync_tip_timer() -> void:
	if is_visible_in_tree():
		_tip_timer.start()
	else:
		_tip_timer.stop()


func _next_tip() -> void:
	_tip_index = (_tip_index + 1) % CATALOG.TIPS.size()
	tip_label.text = CATALOG.TIPS[_tip_index]


static func place(parent: Node, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.anchor_left = rect.position.x
	child.anchor_top = rect.position.y
	child.anchor_right = rect.end.x
	child.anchor_bottom = rect.end.y
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func texture(parent: Node, image: Texture2D, rect: Rect2, cover: bool = false) -> TextureRect:
	var node := TextureRect.new()
	node.texture = image
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	place(parent, node, rect)
	return node


static func label(parent: Node, text: String, font_size: int, rect: Rect2, ink: Color = Color("f6eafc")) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", ink)
	node.add_theme_color_override("font_shadow_color", Color("140b21"))
	node.add_theme_constant_override("shadow_offset_y", 2)
	place(parent, node, rect)
	return node


static func plate(fill: Color, border: Color = Color("dfb44b")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
