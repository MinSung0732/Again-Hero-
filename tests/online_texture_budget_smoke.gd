extends SceneTree
const VIEW := preload("res://src/online/battle_view.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
class QueueSpy extends VIEW:
	var queued: Array[String] = []
	func _request_texture(path: String) -> void: queued.append(path)
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var spy := QueueSpy.new()
	spy._load_actor_texture(String(RULES.ROSTER[0]))
	check(spy.queued.size()==1 and spy.textures.is_empty(),"first sight queues card texture instead of synchronous cold load")
	spy._load_actor_texture(String(RULES.ROSTER[0]))
	check(spy.queued.size()==1,"repeated sightings share one texture request")
	spy.free()
	var view := VIEW.new(); root.add_child(view)
	# Retain completed requests until a manual display frame consumes them.
	while not view.pending_textures.is_empty(): await process_frame
	var paths: Array[String] = []
	var batch := ART.TEXTURE_FINALIZE_PER_FRAME*2+1
	for index in batch:
		var image := Image.create(8,8,false,Image.FORMAT_RGBA8); image.fill(Color.WHITE)
		var texture := ImageTexture.create_from_image(image)
		var path := "user://texture_budget_"+str(index)+".tres"
		check(ResourceSaver.save(texture,path)==OK,"temporary texture fixture saved")
		paths.append(path)
		view._request_texture(path)
	view.set_process(false)
	var deadline := Time.get_ticks_msec()+6000
	var all_ready := false
	while not all_ready and Time.get_ticks_msec()<deadline:
		all_ready=true
		for path in paths:
			if ResourceLoader.load_threaded_get_status(path)!=ResourceLoader.THREAD_LOAD_LOADED: all_ready=false
		if not all_ready: await process_frame
	check(all_ready and view.pending_textures.size()==batch,"complete cold-load batch held for display processing")
	var before: int = view.pending_textures.size()
	view.set_process(true)
	view._process(0.0)
	var consumed := before-view.pending_textures.size()
	check(consumed>0 and consumed<=ART.TEXTURE_FINALIZE_PER_FRAME and not view.pending_textures.is_empty(),"one frame respects finalize count budget")
	check(view.is_processing(),"remaining completed requests keep display processing active")
	deadline=Time.get_ticks_msec()+6000
	while not view.pending_textures.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	check(view.pending_textures.is_empty(),"later frames drain all requests")
	for path in paths:
		check(view.art_textures.get(path) is Texture2D,"completed texture retained")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	view.free()
	print("ONLINE_TEXTURE_BUDGET checks=",checks," failures=",failures)
	quit(1 if failures else 0)
