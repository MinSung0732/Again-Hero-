extends RefCounted

const CARD_FRAME := preload("res://assets/art/UI/clean_frames/rarity_card_frame.tres")
const RARITY_FRAMES := preload("res://src/ui/formation_rarity_frames.gd")

func apply_card_frame(card: Control, rarity: String) -> void:
	RARITY_FRAMES.apply(card, rarity)

func rarity_card_style(rarity: String, source: StyleBoxFlat) -> StyleBoxFlat:
	var style := CARD_FRAME.duplicate() as StyleBoxFlat
	var color := rarity_border_color(rarity)
	style.bg_color = source.bg_color
	style.border_color = color
	style.shadow_color = Color(color, 0.16)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, source.get_margin(side))
	return style

const SHOP := preload("res://src/data/shop_catalog.gd")
const PIXEL := preload("res://src/ui/pixel_panel_skin.gd")

static func rarity_border_color(rarity: String) -> Color:
	return Color("92929c") if rarity == "common" else SHOP.get_rarity(rarity).get("color", Color("685276"))

func apply_slot_border(button: Button, rarity: String) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := PIXEL.button_style(button.get_theme_stylebox(state)) as StyleBoxFlat
		style.border_color = rarity_border_color(rarity) if not rarity.is_empty() else Color("685276")
		if rarity.is_empty(): style.set_border_width_all(3)
		button.add_theme_stylebox_override(state, rarity_card_style(rarity, style) if not rarity.is_empty() else style)
	RARITY_FRAMES.apply(button, rarity)

const PATH := "SafeArea/Layout/Content/TeamTab/TeamLayout"

func panel_style(gold: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171020", 0.96)
	style.border_color = Color("d8ad55") if gold else Color("685276")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	return style

func label(parent: Control, text: String, size: int) -> Label:
	var result := Label.new()
	result.text = text
	# Slot copy must not push the parent layout wider when an empty slot appears.
	result.clip_text = true
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Color("eee3f4"))
	parent.add_child(result)
	return result

func apply(lobby: Control) -> void:
	var layout := lobby.get_node(PATH) as VBoxContainer
	layout.offset_left = 78.0
	layout.offset_right = -78.0
	layout.add_theme_constant_override("separation", 12)
	(layout.get_node("Guide") as Label).text = "몬스터와 마왕 스킬을 각각 최대 3종 편성합니다."
	(layout.get_node("Summary") as Label).clip_text = true
	var slots := layout.get_node("SlotRow") as HBoxContainer
	var area := PanelContainer.new()
	area.name = "EquippedArea"
	area.add_theme_stylebox_override("panel", panel_style())
	var box := VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	layout.add_child(area)
	layout.move_child(area, slots.get_index())
	area.add_child(margin)
	margin.add_child(box)
	var heading := label(box, "◇  편성된 몬스터  ◇", 26)
	heading.name = "EquippedHeading"
	slots.reparent(box, false)
	for index in range(3):
		var button := slots.get_child(index) as Button
		button.custom_minimum_size.y = 244.0
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, panel_style(true))
		var body := VBoxContainer.new()
		body.name = "SlotBody"
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(body)
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.offset_left = 12.0
		body.offset_right = -12.0
		body.offset_top = 18.0
		body.offset_bottom = -12.0
		var icon := TextureRect.new()
		icon.name = "Portrait"
		icon.custom_minimum_size.y = 106.0
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(icon)
		label(body, "", 25).name = "Name"
		label(body, "", 19).name = "Info"
		var remove := Button.new()
		remove.name = "RemoveButton"
		remove.text = "×"
		remove.focus_mode = Control.FOCUS_NONE
		remove.add_theme_font_size_override("font_size", 32)
		remove.custom_minimum_size = Vector2(48, 48)
		remove.add_theme_stylebox_override("normal", panel_style())
		button.add_child(remove)
		remove.anchor_left = 1.0
		remove.anchor_right = 1.0
		remove.offset_left = -52.0
		remove.offset_right = -4.0
		remove.offset_top = 4.0
		remove.offset_bottom = 52.0
		remove.pressed.connect(lobby._remove_formation_slot.bind(index))
	var tabs := layout.get_node("ModeTabs") as HBoxContainer
	tabs.custom_minimum_size.y = 76.0
	var grid := lobby.get("team_monster_grid") as GridContainer
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)

func refresh_slot(button: Button, icon: Texture2D, title: String, info: String, can_remove: bool, rarity: String = "") -> void:
	apply_slot_border(button, rarity)
	button.text = ""
	button.icon = null
	(button.get_node("SlotBody/Portrait") as TextureRect).texture = icon
	(button.get_node("SlotBody/Name") as Label).text = title
	(button.get_node("SlotBody/Info") as Label).text = info
	var remove := button.get_node("RemoveButton") as Button
	remove.visible = not title.contains("빈 슬롯")
	remove.disabled = not can_remove

func heading(lobby: Control, text: String) -> void:
	(lobby.get_node(PATH + "/EquippedArea/Margin/Content/EquippedHeading") as Label).text = text

func fit_action(button: Button) -> void:
	# Shared large lobby buttons have excessive padding for half-width card actions.
	# Duplicate overrides so the shared theme and other screens remain untouched.
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_left = 4.0
		style.content_margin_right = 4.0
		button.add_theme_stylebox_override(state, style)
