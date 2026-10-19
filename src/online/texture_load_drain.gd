extends Node
## Finish outstanding loads after their view leaves, then release all references.
## No blocking scene transition and no permanent texture cache.
var paths: Array[String] = []
var view_ref: WeakRef
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(not paths.is_empty())
func _process(_delta: float) -> void:
	var view = view_ref.get_ref() if view_ref != null else null
	if is_instance_valid(view) and view.is_inside_tree():
		if paths.is_empty(): set_process(false)
		return
	var index := paths.size()
	while index > 0:
		index -= 1
		var path := paths[index]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
		if status == ResourceLoader.THREAD_LOAD_LOADED: ResourceLoader.load_threaded_get(path)
		paths[index] = paths[-1]; paths.pop_back()
	if paths.is_empty(): queue_free()
func _exit_tree() -> void:
	# Only application shutdown can remove an unfinished drain. Consume its
	# requests here so the loader cannot retain orphaned resources at exit.
	for path in paths:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED: ResourceLoader.load_threaded_get(path)
	paths.clear()
