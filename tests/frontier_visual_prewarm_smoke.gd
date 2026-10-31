extends SceneTree
## A scene-only warmup leaves FrontierMonster's first frame build in the battle.
const DATA := preload("res://src/data/frontier_monster_catalog.gd")
const VISUAL := preload("res://src/monsters/monster_visual.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FRONTIER_VISUAL_WARM: "+label)

func run() -> void:
	var id := "cave_ant"
	var profile: Dictionary = DATA.DEFINITIONS[id].normal_visual
	var first := VISUAL.new()
	check(first.apply_visual_profile(profile),"normal frontier profile can load before first spawn")
	var cached: SpriteFrames = first.sprite_frames
	check(cached != null and cached.get_frame_count(&"idle") > 0,"idle animation is populated")
	var spawned := VISUAL.new()
	check(spawned.apply_visual_profile(profile),"later live monster profile remains loadable")
	check(spawned.sprite_frames == cached,"first live monster reuses prewarmed SpriteFrames object")
	first.free()
	spawned.free()
	VISUAL.clear_cached_frames()
	print("FRONTIER_VISUAL_WARM checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
