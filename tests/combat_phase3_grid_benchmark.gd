extends SceneTree
const GRID := preload("res://src/systems/monster_local_grid.gd")
const BASE := preload("res://tests/combat_phase3_grid_smoke.gd")
func _initialize() -> void: run.call_deferred()
func work(grid,actors: Dictionary) -> void:
	for repeat in 12:
		for id in actors: grid.separation_bias(actors[id],25.0)
func run() -> void:
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase3/monster_local_grid_before.gd.txt")
	if script.reload() != OK: quit(1); return
	var rows: Array = []
	for dense in [false,true]:
		for count in [48,120,208]:
			var host := Node2D.new(); root.add_child(host); var actors := {}
			for index in count:
				var actor := BASE.Actor.new(); host.add_child(actor); actors[actor.get_instance_id()] = actor
				actor.position = Vector2(index%16,index/16)*(3.0 if dense else 35.0)
				actor.set_meta("noncollision_family","lizardman" if index%3 == 0 else "")
			var old = script.new(); var current := GRID.new(); old.ensure(actors,0); current.ensure(actors,0)
			work(old,actors); work(current,actors)
			var before: Array = []; var after: Array = []
			for trial in 7:
				for optimized in ([false,true] if trial%2 == 0 else [true,false]):
					var begin := Time.get_ticks_usec(); work(current if optimized else old,actors)
					(after if optimized else before).append((Time.get_ticks_usec()-begin)/1000.0)
			before.sort(); after.sort()
			var row := {"actors":count,"dense":dense,"queries_per_trial":12*count,"runs":7,"before_median_ms":before[3],"after_median_ms":after[3],"before_samples_ms":before,"after_samples_ms":after}
			rows.append(row); print("PHASE3_GRID_BENCH ",JSON.stringify(row)); host.free()
	var file := FileAccess.open("user://combat_phase3_grid_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cpu_only":true,"engine":Engine.get_version_info().string,"rows":rows},"\t")); file.close(); quit()
