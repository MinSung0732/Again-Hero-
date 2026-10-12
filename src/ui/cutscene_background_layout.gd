extends RefCounted
## Character stages contain their authored layout; environment art covers the actual Control.
static func cover_sprite(background: Sprite2D, view_size: Vector2, stage_offset: Vector2, stage_factor: float) -> void:
	if not is_instance_valid(background) or background.texture == null or stage_factor <= 0.0 or view_size.x <= 0.0 or view_size.y <= 0.0: return
	var texture_size := background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0: return
	background.position = (view_size*0.5-stage_offset)/stage_factor
	var cover_factor := maxf(view_size.x/texture_size.x,view_size.y/texture_size.y)/stage_factor
	background.scale = Vector2.ONE*cover_factor

static func cover_overlay(overlay: Control, view_size: Vector2, stage_offset: Vector2, stage_factor: float) -> void:
	if not is_instance_valid(overlay) or stage_factor <= 0.0 or view_size.x <= 0.0 or view_size.y <= 0.0: return
	overlay.position = -stage_offset/stage_factor
	overlay.size = view_size/stage_factor
