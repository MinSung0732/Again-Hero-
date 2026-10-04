extends CanvasLayer

signal transition_completed

const LOADING_VIEW := preload("res://src/ui/startup_loading_view.gd")

var _pending := false
var _scene_path := ""
var _view: Control
var _progress: Array = []
var _message := ""
var _retry: Button


func _ready() -> void:
	layer = 10000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = LOADING_VIEW.new()
	add_child(_view)
	_retry = Button.new()
	_retry.text = "다시 시도"
	_retry.add_theme_font_size_override("font_size", 30)
	_retry.add_theme_stylebox_override("normal", LOADING_VIEW.plate(Color("522b75")))
	LOADING_VIEW.place(_view, _retry, Rect2(0.28, 0.62, 0.44, 0.065))
	_retry.mouse_filter = Control.MOUSE_FILTER_STOP
	_retry.pressed.connect(_retry_transition)
	visible = false
	_view.hide()
	set_process(false)


func is_transitioning() -> bool:
	return _pending or visible


func change_scene(path: String, message: String = "불러오는 중...") -> bool:
	if is_transitioning() or path.is_empty() or not ResourceLoader.exists(path):
		return false
	_scene_path = path
	_message = message
	return _start_load()


func _start_load() -> bool:
	_view.configure(_message, "필요한 화면과 리소스를 불러오고 있습니다.")
	_retry.hide()
	visible = true
	_view.show()
	var error := ResourceLoader.load_threaded_request(_scene_path, "PackedScene")
	if error != OK:
		_fail_transition(error)
		return true # Accepted: keep retry UI instead of triggering caller's fallback.
	_pending = true
	set_process(true)
	return true


func _process(_delta: float) -> void:
	if not _pending:
		return
	var status := ResourceLoader.load_threaded_get_status(_scene_path, _progress)
	if not _progress.is_empty():
		_view.set_progress(float(_progress[0]) * 0.5)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(_scene_path) as PackedScene
		_pending = false
		set_process(false)
		if packed == null:
			_fail_transition(ERR_INVALID_DATA)
			return
		call_deferred("_prepare_destination_and_change", packed)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fail_transition(ERR_CANT_OPEN)


func _prepare_destination_and_change(packed: PackedScene) -> void:
	_view.detail.text = "이미지와 화면 표시 리소스를 미리 준비합니다."
	PresentationWarmup.progress_changed.connect(_on_warmup_progress)
	await PresentationWarmup.prepare_common()
	await PresentationWarmup.prepare_scene(_scene_path)
	PresentationWarmup.progress_changed.disconnect(_on_warmup_progress)
	_view.set_progress(0.9)
	var error := get_tree().change_scene_to_packed(packed)
	if error == OK:
		call_deferred("_finish_after_scene_change")
	else:
		_fail_transition(error)


func _on_warmup_progress(completed: int, total: int) -> void:
	_view.set_progress(0.5 + 0.4 * float(completed) / maxi(total, 1))


func _finish_after_scene_change() -> void:
	# New scene _ready() finishes beneath this persistent full-screen overlay.
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("prepare_presentation"):
		_view.detail.text = "카드와 연출의 첫 화면 표시를 준비합니다."
		await scene.call("prepare_presentation")
	await get_tree().process_frame
	_view.set_progress(1.0)
	visible = false
	_view.hide()
	_scene_path = ""
	_progress.clear()
	transition_completed.emit()


func _fail_transition(error: int) -> void:
	push_warning("Scene transition failed: %s / error=%d" % [_scene_path, error])
	_pending = false
	set_process(false)
	_view.detail.text = "화면을 불러오지 못했습니다. 다시 시도해 주세요."
	_retry.show()


func _retry_transition() -> void:
	if not _pending and not _scene_path.is_empty():
		_start_load()
