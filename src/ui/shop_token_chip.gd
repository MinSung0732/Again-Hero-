extends RefCounted
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const DEFINITIONS := "res://src/data/token_currencies.json"
const CHIP_SIZE := Vector2(300, 58)
const ICON_SIZE := Vector2(42, 42)
const FONT_SIZE := 25
const PADDING := 8.0

static func build(parent: Container, currency: String) -> PanelContainer:
	var definitions: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEFINITIONS))
	var data: Dictionary = definitions.get(currency, {}) if definitions is Dictionary else {}
	var chip := PanelContainer.new()
	chip.name = "ShopTokenChip"
	chip.set_meta("currency", currency)
	chip.set_meta("currency_name", String(data.get("name", "")))
	chip.custom_minimum_size = CHIP_SIZE
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chip.add_theme_stylebox_override("panel", FRAMES.style("header_frame", PADDING))
	parent.add_child(chip)
	var row := HBoxContainer.new()
	row.name = "TokenRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path := String(data.get("icon_path", ""))
	var image := Image.new()
	if FileAccess.file_exists(path) and image.load(path) == OK:
		icon.texture = ImageTexture.create_from_image(image)
	elif ResourceLoader.exists(path):
		icon.texture = load(path)
	row.add_child(icon)
	var label := Label.new()
	label.name = "Value"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color("ffe293"))
	row.add_child(label)
	refresh(chip)
	return chip

static func refresh(chip: Control) -> void:
	if not is_instance_valid(chip): return
	var currency := String(chip.get_meta("currency", ""))
	var label := chip.get_node("TokenRow/Value") as Label
	label.text = "%s %d" % [String(chip.get_meta("currency_name", "")), PROGRESS.get_token(currency)]
