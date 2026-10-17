extends Control

signal finished
const PROFILE := preload("res://src/systems/player_profile.gd")
const DATA := preload("res://src/data/profile_gender_catalog.gd")
const CLOUD := preload("res://src/network/cloud_store.gd")
const FRAMES := preload("res://src/ui/commerce_frame_skin.gd")
const TAP := preload("res://src/ui/drag_safe_button.gd")

var cloud: Node
var owner_id := ""
var selected := ""
var operation_id := ""
var busy := false
var submitted := false
var choices := {}
var confirm: Button
var cancel: Button
var notice: Label
var portrait: TextureRect

func _ready() -> void:
	owner_id = PROFILE.SCOPE.user_id
	selected = String(PROFILE.get_profile().get("gender", "male"))
	if cloud == null: cloud = get_node("/root/CloudStore")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.08; panel.anchor_right = 0.92
	panel.anchor_top = 0.13; panel.anchor_bottom = 0.87
	panel.add_theme_stylebox_override("panel", FRAMES.style("shop_button_frame", 20))
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_"+side, 28)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 24)
	scroll.add_child(column)
	_label(column, DATA.TITLE, 38)
	_label(column, DATA.GUIDE % DATA.LINKED_CHANGES, 28)
	portrait = TextureRect.new()
	portrait.custom_minimum_size.y = 260
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(portrait)
	var row := HBoxContainer.new(); column.add_child(row)
	for value in DATA.OPTIONS:
		var button := _button(row, DATA.OPTIONS[value])
		button.toggle_mode = true
		button.connect("confirmed", _select.bind(value))
		choices[value] = button
	notice = _label(column, "", 28)
	confirm = _button(column, "")
	confirm.connect("confirmed", _submit)
	cancel = _button(column, "취소")
	cancel.connect("confirmed", _close)
	_update()

func _label(parent: Control, text: String, size: int) -> Label:
	var label := Label.new(); label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func _button(parent: Control, text: String) -> Button:
	var button := TAP.new(); button.text = text
	button.custom_minimum_size.y = 96
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 30)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, FRAMES.style("shop_button_frame", 14))
	parent.add_child(button)
	return button

func _select(value: String) -> void:
	if busy or submitted or not DATA.OPTIONS.has(value): return
	selected = value
	notice.text = ""
	_update()

func _update() -> void:
	for value in choices:
		choices[value].set_pressed_no_signal(value == selected)
		choices[value].disabled = busy or submitted
	portrait.texture = load(PROFILE.PORTRAITS[selected])
	confirm.text = DATA.CONFIRM % DATA.OPTIONS[selected]
	confirm.disabled = busy or owner_id != PROFILE.SCOPE.user_id or not PROFILE.can_change_gender() or selected == String(PROFILE.get_profile().get("gender", "male"))
	cancel.disabled = busy

func _submit() -> void:
	if busy or confirm.disabled: return
	if operation_id.is_empty(): operation_id = CLOUD.new_operation_id()
	submitted = true # Once sent, retries must keep exactly this gender and UUID.
	busy = true
	notice.text = DATA.SAVING
	_update()
	var result := await PROFILE.change_gender(cloud, selected, operation_id)
	if not is_instance_valid(self) or not is_inside_tree(): return
	busy = false
	if result.get("ok") == true:
		finished.emit()
		return
	var error := String(result.get("error", "default"))
	notice.text = DATA.ERRORS.get(error, DATA.ERRORS.default)
	_update()

func _close() -> void:
	if not busy: finished.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
