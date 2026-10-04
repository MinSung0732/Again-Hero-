extends Control

# Reuse the original bitmap regions. Corners and the central jewels keep their
# proportions instead of stretching one whole image over every HUD element.
const PATH := "res://assets/art/UI/battle_castle_v3/gold_panel.png"
var art: Texture2D

static func install(target: Control, texture: Texture2D) -> void:
	if texture == null:
		return
	var old := target.get_node_or_null("PixelAssetFrame")
	if old != null:
		target.remove_child(old)
		old.queue_free()
	if target is TextureRect:
		target.texture = null
	var panel = load("res://src/ui/illustrated_battle_panel.gd").new()
	panel.name = "IllustratedBattlePanel"
	panel.art = texture
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.show_behind_parent = true
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	target.add_child(panel)
	target.move_child(panel, 0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.resized.connect(panel.queue_redraw)
	if target is Button:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		target.button_down.connect(func(): panel.modulate = Color(0.8, 0.7, 1.0))
		target.button_up.connect(func(): panel.modulate = Color.WHITE)
	panel.queue_redraw()

func piece(destination: Rect2, source: Rect2) -> void:
	draw_texture_rect_region(art, destination, Rect2(source.position * art.get_size(), source.size * art.get_size()))

func _draw() -> void:
	if art == null or size.x < 1 or size.y < 1:
		return
	var c := minf(38.0, minf(size.x, size.y) * 0.26)
	var w := size.x
	var h := size.y
	piece(Rect2(c, c, w-c*2, h-c*2), Rect2(0.18, 0.25, 0.64, 0.5))
	piece(Rect2(0, 0, c, c), Rect2(0.01, 0.055, 0.13, 0.22))
	piece(Rect2(w-c, 0, c, c), Rect2(0.86, 0.055, 0.13, 0.22))
	piece(Rect2(0, h-c, c, c), Rect2(0.01, 0.725, 0.13, 0.22))
	piece(Rect2(w-c, h-c, c, c), Rect2(0.86, 0.725, 0.13, 0.22))
	piece(Rect2(c, 0, w-c*2, c), Rect2(0.18, 0.055, 0.22, 0.22))
	piece(Rect2(c, h-c, w-c*2, c), Rect2(0.18, 0.725, 0.22, 0.22))
	piece(Rect2(0, c, c, h-c*2), Rect2(0.01, 0.32, 0.13, 0.30))
	piece(Rect2(w-c, c, c, h-c*2), Rect2(0.86, 0.32, 0.13, 0.30))
	if w > 260:
		piece(Rect2(w*0.5-18, 0, 36, c), Rect2(0.455, 0.055, 0.09, 0.22))
		piece(Rect2(w*0.5-18, h-c, 36, c), Rect2(0.455, 0.725, 0.09, 0.22))
