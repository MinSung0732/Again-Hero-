extends RefCounted

const PATHS := {
	"common": "res://assets/art/UI/clean_frames/formation_common_frame.png",
	"uncommon": "res://assets/art/UI/clean_frames/formation_uncommon_frame.png",
	"rare": "res://assets/art/UI/clean_frames/formation_rare_frame.png",
	"legendary": "res://assets/art/UI/clean_frames/formation_legendary_frame.png",
	"transcendent": "res://assets/art/UI/clean_frames/transcendent_card_frame.png",
}
static var _textures: Dictionary = {}

static func apply(parent: Control, rarity: String) -> void:
	var border := parent.get_node_or_null("FormationRarityFrame") as NinePatchRect
	if not PATHS.has(rarity):
		if border != null: border.hide()
		return
	var path: String = PATHS[rarity]
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D
	var texture := _textures[path] as Texture2D
	if texture == null:
		return
	if border == null:
		border = NinePatchRect.new()
		border.name = "FormationRarityFrame"
		border.draw_center = false
		border.patch_margin_left = 32
		border.patch_margin_top = 32
		border.patch_margin_right = 32
		border.patch_margin_bottom = 32
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(border)
		parent.move_child(border, 0)
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.texture = texture
	border.set_meta("rarity", rarity)
	border.show()
	# Retain hit regions/content margins and button-state feedback; the PNG
	# owns the ornament instead of drawing another flat border beneath it.
	var states := ["normal", "hover", "pressed", "disabled"] if parent is Button else ["panel"]
	for state in states:
		var source := parent.get_theme_stylebox(state)
		if source is StyleBoxFlat:
			var style := source.duplicate() as StyleBoxFlat
			style.set_border_width_all(0)
			style.shadow_size = 0
			parent.add_theme_stylebox_override(state, style)
