extends RefCounted
## Shared static art, built during UI setup; no image work while fighting.
const BADGE_PATH := "res://assets/art/UI/hero_hud/held_augment_badge.png"
const LOWER_PATH := "res://assets/art/UI/hero_hud/augment_lower_button.png"
const BADGE_SIZE := Vector2(84,84)
const BADGE_GAP := 12.0
const LOWER_REGION := Rect2(0,85,1983,620)
static var textures := {}
static func apply(button: Button,path: String) -> void:
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not textures.has(path):
		var source: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if source != null and path == LOWER_PATH:
			var region := AtlasTexture.new(); region.atlas = source; region.region = LOWER_REGION; region.filter_clip = true
			textures[path] = region
		else: textures[path] = source
	var texture: Texture2D = textures[path]
	if texture == null: return
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxTexture.new(); style.texture = texture
		style.content_margin_left = 12; style.content_margin_right = 12
		style.content_margin_top = 8; style.content_margin_bottom = 8
		style.modulate_color = Color(1.15,1.15,1.15) if state=="hover" else Color(.72,.72,.8) if state=="pressed" else Color(.55,.55,.6) if state=="disabled" else Color.WHITE
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",Color("fff1bd"))
	button.add_theme_color_override("font_hover_color",Color.WHITE)
	button.add_theme_color_override("font_pressed_color",Color("ffe39b"))
	button.add_theme_color_override("font_outline_color",Color("11101d"))
	button.add_theme_constant_override("outline_size",3)
