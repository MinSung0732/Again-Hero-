extends RefCounted
## Late-battle visual preparation: at most one texture request and one
## completed texture/frame attachment per interval. Never block on a worker.
const VISUAL := preload("res://src/monsters/monster_visual.gd")
const LEAD_SECONDS := 40.0
const STEP_SECONDS := 0.12
const MAX_PENDING_REQUESTS := 4

var total_frames := 0
var requested := 0
var completed := 0
var failed_frames := 0
var finished := false
var success := false
var max_step_ms := 0.0

var _profile: Dictionary = {}
var _tasks: Array[Dictionary] = []
var _frames: SpriteFrames
var _visual
var _begin_at := 0.0
var _next_request_at := 0.0
var _next_complete_at := 0.0
var _started := false

func configure(profile: Dictionary, boss_at: float) -> void:
	_profile = profile
	_begin_at = boss_at-LEAD_SECONDS

func tick(elapsed: float, profiling_enabled: bool = false) -> void:
	if finished or elapsed < _begin_at: return
	if not _started: _start(elapsed)
	if finished: return
	var started_us := Time.get_ticks_usec()
	if requested < total_frames and requested-completed < MAX_PENDING_REQUESTS and elapsed >= _next_request_at:
		_request_one()
		_next_request_at = elapsed+STEP_SECONDS
	if completed < requested and elapsed >= _next_complete_at:
		_consume_one(elapsed)
	var step_ms := float(Time.get_ticks_usec()-started_us)/1000.0
	max_step_ms = maxf(max_step_ms,step_ms)
	if finished and profiling_enabled:
		print("[HeroPerf] boss_visual_prewarm_done elapsed=%.1f frames=%d success=%s max_step_ms=%.2f" % [
			elapsed,total_frames,str(success),max_step_ms
		])

func _start(elapsed: float) -> void:
	_started = true
	_next_request_at = elapsed
	_next_complete_at = elapsed
	_visual = VISUAL.new()
	if _visual.has_cached_profile(_profile):
		success = true
		finished = true
		_visual.free()
		_visual = null
		return
	var animations = _profile.get("animations",{})
	if String(_profile.get("mode","")) != "frames" or typeof(animations) != TYPE_DICTIONARY:
		_abort()
		return
	var directory := String(_profile.get("asset_dir",""))
	if directory.is_empty():
		_abort()
		return
	_frames = SpriteFrames.new()
	if _frames.has_animation(&"default"): _frames.remove_animation(&"default")
	for raw_name in animations.keys():
		var animation_name := StringName(String(raw_name))
		var spec: Dictionary = animations[raw_name]
		var count := int(spec.get("count",0))
		if count <= 0: continue
		var files: Array = spec.get("files",[])
		var prefix := String(spec.get("prefix",String(raw_name)))
		_frames.add_animation(animation_name)
		_frames.set_animation_speed(animation_name,float(spec.get("fps",10.0)))
		_frames.set_animation_loop(animation_name,bool(spec.get("loop",false)))
		for frame_index in range(1,count+1):
			var filename := String(files[frame_index-1]) if files.size() >= frame_index else "%s_%02d.png" % [prefix,frame_index]
			_tasks.append({"name":animation_name,"path":"%s/%s" % [directory,filename],"threaded":false})
	total_frames = _tasks.size()
	if total_frames == 0: _abort()

func _request_one() -> void:
	var task: Dictionary = _tasks[requested]
	var path := String(task.path)
	if ResourceLoader.exists(path,"Texture2D"):
		task["threaded"] = ResourceLoader.load_threaded_request(path,"Texture2D",false) == OK
	requested += 1

func _consume_one(elapsed: float) -> void:
	var task: Dictionary = _tasks[completed]
	var path := String(task.path)
	var texture: Texture2D
	if bool(task.threaded):
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			texture = ResourceLoader.load_threaded_get(path) as Texture2D
	if texture == null:
		# Missing/failed import still has the same one-frame fallback as live visuals.
		texture = _visual._load_texture(path)
	if texture != null:
		_frames.add_frame(task.name,texture)
	else:
		failed_frames += 1
	completed += 1
	_next_complete_at = elapsed+STEP_SECONDS
	if completed == total_frames: _finish()

func _finish() -> void:
	success = failed_frames == 0 and _visual.cache_prebuilt_profile(_profile,_frames)
	finished = true
	_tasks.clear()
	_visual.free()
	_visual = null
	_frames = null

func _abort() -> void:
	finished = true
	_tasks.clear()
	if _visual != null:
		_visual.free()
		_visual = null
	_frames = null
