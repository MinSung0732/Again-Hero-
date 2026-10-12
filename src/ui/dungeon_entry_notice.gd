extends Control

# Reusable in-game modal using the same authored frame and buttons as the lobby.
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
var _host: Control
var _panel: PanelContainer
var _message: Label
var _confirm: Button
var _title: Label
var _cancel: Button
var _action := Callable()
var _previous_focus: WeakRef

func install(host: Control) -> void:
	_host = host
	theme = host.theme
	var layer := CanvasLayer.new()
	layer.name = "DungeonEntryNoticeLayer"
	layer.layer = 130
	host.add_child(layer)
	layer.add_child(self)
	name = "DungeonEntryNotice"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.78)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "Frame"
	var frame := host.panel_style.duplicate() as StyleBox
	frame.set_content_margin_all(36)
	_panel.add_theme_stylebox_override("panel", frame)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	_panel.add_child(box)
	var title := Label.new()
	_title = title
	title.name = "Title"
	title.text = "던전 입장 안내"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("ffe29a"))
	box.add_child(title)
	_message = Label.new()
	_message.name = "Message"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 28)
	_message.add_theme_color_override("font_color", Color("eee7f2"))
	_message.add_theme_constant_override("line_spacing", 8)
	box.add_child(_message)
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.text = "확인"
	_confirm.custom_minimum_size.y = 82
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	_cancel = Button.new()
	_cancel.text = "취소"
	_cancel.custom_minimum_size.y = 82
	_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_cancel)
	host._apply_lobby_button_skin(_cancel, false, 28)
	_cancel.pressed.connect(close)
	_cancel.hide()
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_confirm)
	host._apply_lobby_button_skin(_confirm, true, 28)
	_confirm.pressed.connect(_on_confirm)
	SKIN.apply(_panel)
	host.resized.connect(_resize)
	_resize()
	hide()

func _resize() -> void:
	_panel.custom_minimum_size.x = minf(760, maxf(0, _host.get_viewport_rect().size.x - 48))

func open(message: String, title: String = "던전 입장 안내") -> void:
	if not visible:
		_previous_focus = weakref(get_viewport().gui_get_focus_owner())
	_message.text = message
	_title.text = title
	_confirm.text = "확인"
	_cancel.hide()
	_action = Callable()
	_resize()
	show()
	_confirm.grab_focus()

func close() -> void:
	hide()
	_action = Callable()
	var previous = _previous_focus.get_ref() if _previous_focus != null else null
	if is_instance_valid(previous) and previous is Control and previous.is_visible_in_tree():
		previous.grab_focus()
	_previous_focus = null

func open_confirmation(message: String, title: String, action: Callable) -> void:
	open(message, title)
	_action = action
	_cancel.show()
	_confirm.text = "초기화"
	_cancel.grab_focus()

func _on_confirm() -> void:
	var action := _action
	close()
	if action.is_valid(): action.call()

func blocks_lobby_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	return true
