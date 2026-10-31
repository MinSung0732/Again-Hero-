extends SceneTree
## Stage 10's gumiho boss transforms 5s after spawning; its 29 fox
## textures must be attached over many ticks, not on the 905s cast.
const WARM := preload("res://src/hero_mode/hero_boss_visual_prewarm.gd")
const GUMIHO := preload("res://src/data/gumiho_behavior_catalog.gd")
const VISUAL := preload("res://src/monsters/monster_visual.gd")
const SURVIVAL := preload("res://src/data/hero_mode_catalog.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BOSS_FOX_PREWARM: "+label)

func run() -> void:
	check(SURVIVAL.boss_for(10,"easy") == "gumiho","stage 10 easy uses the fox boss")
	var warm := WARM.new()
	warm.configure(GUMIHO.FOX_VISUAL,SURVIVAL.DURATION)
	var begin_at := SURVIVAL.DURATION-WARM.LEAD_SECONDS
	warm.tick(begin_at-0.01)
	check(warm.requested == 0 and not warm.finished,"no texture loading before scheduled lead")
	warm.tick(begin_at)
	check(warm.total_frames == 29,"entire fox profile is scheduled")
	check(warm.requested == 1,"only one texture requested per interval")
	check(not warm.finished,"profile is not published partway through")
	var clock := begin_at
	var concurrent_safe := true
	for index in 600:
		if warm.finished: break
		clock += WARM.STEP_SECONDS+0.01
		await create_timer(0.02).timeout
		warm.tick(clock)
		if warm.requested-warm.completed > WARM.MAX_PENDING_REQUESTS:
			concurrent_safe = false
	check(concurrent_safe,"at most four texture requests are pending")
	check(warm.finished and warm.success,"all 29 fox frames load and publish successfully")
	check(warm.completed == 29 and warm.failed_frames == 0,"no missing fox textures")

	var first := VISUAL.new()
	check(first.has_cached_profile(GUMIHO.FOX_VISUAL),"normal gameplay detects the cached fox variant")
	check(first.apply_visual_profile(GUMIHO.FOX_VISUAL),"preloaded fox visuals activate normally")
	var cached := first.sprite_frames
	check(cached != null and cached.get_frame_count(&"idle") == 5,"fox idle animation unchanged")
	check(cached.get_frame_count(&"attack") == 6 and cached.get_frame_count(&"skill") == 4,"fox attack and skill frame counts unchanged")
	check(cached.get_animation_loop(&"idle") and not cached.get_animation_loop(&"skill"),"fox loop settings unchanged")
	var second := VISUAL.new()
	check(second.apply_visual_profile(GUMIHO.FOX_VISUAL) and second.sprite_frames == cached,"second activation reuses prepared cache")
	var repeat := WARM.new()
	repeat.configure(GUMIHO.FOX_VISUAL,SURVIVAL.DURATION)
	repeat.tick(begin_at)
	check(repeat.finished and repeat.success and repeat.requested == 0,"cached profile is not loaded again")
	first.free()
	second.free()
	VISUAL.clear_cached_frames()
	print("BOSS_FOX_PREWARM checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
