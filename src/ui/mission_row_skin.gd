extends RefCounted

static func style(fill: String, edge: String, padding: int = 20) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(edge)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(padding)
	return box


static func apply_button(button: Button) -> void:
	button.custom_minimum_size.y = 64
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", style("32233e", "776184", 12))
	button.add_theme_stylebox_override("hover", style("493550", "eac14d", 12))
	button.add_theme_stylebox_override("pressed", style("604724", "f7d579", 12))
	button.add_theme_stylebox_override("disabled", style("29262e", "524c59", 12))
