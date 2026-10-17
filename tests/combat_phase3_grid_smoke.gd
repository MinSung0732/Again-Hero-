extends SceneTree
const GRID := preload("res://src/systems/monster_local_grid.gd")
var checks := 0
var failures := 0
class Actor extends CharacterBody2D:
	var current_hp := 100
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func baseline():
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase3/monster_local_grid_before.gd.txt")
	check(script.reload() == OK,"frozen grid compiles"); return script.new()
func run() -> void:
	var old = baseline(); var current := GRID.new(); var actors := {}; var host := Node2D.new(); root.add_child(host)
	var rng := RandomNumberGenerator.new(); rng.seed = 78445
	for index in 208:
		var actor := Actor.new(); host.add_child(actor); actors[actor.get_instance_id()] = actor
		actor.add_to_group("phase3_actor")
	for step in 40:
		var index := 0
		for id in actors:
			var actor = actors[id]
			actor.position = Vector2(rng.randf_range(-250,250),rng.randf_range(-250,250)) if step%3 == 0 else Vector2(index%8,index/8)*(.01 if step%3 == 1 else 3.0)
			actor.velocity = Vector2(rng.randf_range(-5000,5000),0) if index%23 == 0 else Vector2.ZERO
			actor.current_hp = 0 if index%31 == 0 else 100
			actor.set_meta("noncollision_family","lizardman" if index%3 == 0 else "")
			actor.set_meta("ignore_monster_separation",index%17 == 0)
			index += 1
		old.ensure(actors,step); current.ensure(actors,step)
		index = 0
		for id in actors:
			var actor = actors[id]
			# All consumers must see current positions/flags, even after grid build.
			if index%19 == 0: actor.position += Vector2(10,-7)
			if index%7 == 0: actor.set_meta("noncollision_family","changed")
			var radius: float = [18.0,25.0,65.0][index%3]
			check(old.separation_bias(actor,radius) == current.separation_bias(actor,radius),"exact steering and dense sample order")
			if index%13 == 0:
				check(old.count_group_near(actor.position,radius,"phase3_actor",actor,3) == current.count_group_near(actor.position,radius,"phase3_actor",actor,3),"group query unchanged")
				var a: Array = []; var b: Array = []; var rect := Rect2(actor.position-Vector2.ONE*radius,Vector2.ONE*radius*2)
				old.fill_rect(rect,a); current.fill_rect(rect,b); check(a == b,"complete rect candidates/order unchanged")
			index += 1
	var gone = actors.values()[0]; gone.queue_free()
	var owner = actors.values()[1]
	check(old.separation_bias(owner,25) == current.separation_bias(owner,25),"queued neighbor")
	gone.free()
	check(old.separation_bias(owner,25) == current.separation_bias(owner,25),"freed neighbor still in snapshot")
	old.clear(); current.clear(); check(current.buckets.is_empty() and current.revision == -1,"reset releases snapshot")
	host.free(); print("COMBAT_PHASE3_GRID checks=",checks," failures=",failures); quit(1 if failures else 0)
