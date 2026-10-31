extends SceneTree
## Regression: elite arcs and pooled visuals can outlive their scene nodes.
const RUNTIME := preload("res://src/systems/elite_monster_skill_runtime.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ELITE_FREED_REF: "+label)

func run() -> void:
	var runtime := RUNTIME.new()

	var dead_slime := Node2D.new()
	runtime._slime_arcs.append({"monster":dead_slime,"elapsed":0.0})
	dead_slime.free()
	runtime._tick_slime_arcs(0.016)
	check(runtime._slime_arcs.is_empty(),"freed slime arc is discarded before cast")

	var dying_slime := Node2D.new()
	root.add_child(dying_slime)
	runtime._begin_slime_arc(dying_slime,Vector2.ZERO,Vector2(30,0),1.0,10.0)
	dying_slime.queue_free()
	runtime._tick_slime_arcs(0.016)
	check(runtime._slime_arcs.is_empty(),"queued-for-deletion arc is discarded")

	var alive_slime := Node2D.new()
	root.add_child(alive_slime)
	runtime._begin_slime_arc(alive_slime,Vector2.ZERO,Vector2(30,0),0.25,10.0)
	runtime._tick_slime_arcs(0.25)
	check(runtime._slime_arcs.is_empty(),"finished live arc is released")
	check(alive_slime.global_position == Vector2(30,0),"live arc landing unchanged")
	check(not bool(alive_slime.get_meta("elite_skill_movement_lock",true)),"live arc unlock unchanged")

	var dead_arrow := Sprite2D.new()
	runtime._skeleton_archer_rain_arrows.append({"sprite":dead_arrow,"elapsed":0.0})
	dead_arrow.free()
	runtime._tick_skeleton_archer_rain_arrows(0.016)
	check(runtime._skeleton_archer_rain_arrows.is_empty(),"freed arrow visual is discarded")

	var dead_line := Line2D.new()
	var skill := {"_line_fx":dead_line,"_active":true}
	dead_line.free()
	runtime._finish_goblin_commander(skill)
	check(skill._line_fx == null and not skill._active,"freed aura line cleans up without cast")

	alive_slime.queue_free()
	await process_frame
	print("ELITE_FREED_REF checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
