extends CanvasLayer

const LOADING_LOGO := preload("res://assets/art/UI/loading/loadingframes/loading_logo_01.png")

var _pending: bool = false
var _scene_path: String = ""
var _message_label: Label


func _ready() -> void:
	layer = 10000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	visible = false


func is_transitioning() -> bool:
	return _pending or visible


func change_scene(path: String, message: String = "불러오는 중...") -> bool:
	if _pending or path.is_empty():
		return false

	_pending = true
	_scene_path = path
	if is_instance_valid(_message_label):
		_message_label.text = message
	visible = true

	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		return _change_scene_direct(path)
	return true


func _process(_delta: float) -> void:
	if not _pending:
		return

	var status := ResourceLoader.load_threaded_get_status(_scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed = ResourceLoader.load_threaded_get(_scene_path)
		if packed is PackedScene:
			_pending = false
			var error := get_tree().change_scene_to_packed(packed)
			if error == OK:
				call_deferred("_finish_after_scene_change")
			else:
				_fail_transition(error)
			return
		_change_scene_direct(_scene_path)
	elif (
		status == ResourceLoader.THREAD_LOAD_FAILED
		or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	):
		_change_scene_direct(_scene_path)


func _change_scene_direct(path: String) -> bool:
	_pending = false
	var error := get_tree().change_scene_to_file(path)
	if error == OK:
		call_deferred("_finish_after_scene_change")
		return true
	_fail_transition(error)
	return false


func _finish_after_scene_change() -> void:
	# Keep the persistent overlay above the new scene for two rendered frames.
	# Any unavoidable _ready() hitch is therefore hidden behind the loading UI.
	if get_tree() == null:
		visible = false
		_scene_path = ""
		return
	await get_tree().process_frame
	await get_tree().process_frame
	visible = false
	_scene_path = ""


func _fail_transition(error: int) -> void:
	push_warning("Scene transition failed: %s / error=%d" % [_scene_path, error])
	_pending = false
	_scene_path = ""
	visible = false


func _build_overlay() -> void:
	var blocker := ColorRect.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0.035, 0.025, 0.05, 1.0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)

	var logo := TextureRect.new()
	logo.texture = LOADING_LOGO
	logo.custom_minimum_size = Vector2(220.0, 220.0)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)

	_message_label = Label.new()
	_message_label.text = "불러오는 중..."
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 30)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_message_label)
