extends SceneTree
## Query CPU benchmark only. Synthetic density above the gameplay cap is explicit.
const CACHE := preload("res://src/systems/spatial_candidate_cache.gd")
const RUNS := 7
var rows: Array = []
func _initialize() -> void: run.call_deferred()
func work(old,cache,optimized: bool,reuse: bool = true) -> void:
	var scratch: Array = []
	for frame in 12:
		for query in 48:
			var radius: float = [12.0,65.0,270.0,590.0][query%4]
			var origin := Vector2((query%3)*15,0) if reuse else Vector2((query%8-4)*270,(query/8-3)*270)
			if optimized:
				cache.fill(old.monster_spatial_grid,old._spatial_cell_for_position(origin-Vector2.ONE*radius)-Vector2i.ONE,old._spatial_cell_for_position(origin+Vector2.ONE*radius)+Vector2i.ONE,frame,scratch)
			else: old.fill_monsters_near(origin,radius,scratch)
func run() -> void:
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase1/battle_spatial.gd.txt")
	if script.reload() != OK: quit(1); return
	for dense in [false,true]:
		for count in [100,300,600]:
			var old = script.new(); var cache := CACHE.new(); var actors: Array[Node2D] = []
			for index in count:
				var actor := Node2D.new(); actors.append(actor)
				actor.position = Vector2(index%25-12,index/25-12)*(10.0 if dense else 120.0)
				var cell: Vector2i = old._spatial_cell_for_position(actor.position)
				if not old.monster_spatial_grid.has(cell): old.monster_spatial_grid[cell] = []
				old.monster_spatial_grid[cell].append(actor)
			var before: Array[float] = []; var after: Array[float] = []
			work(old,cache,true); work(old,cache,false)
			for trial in RUNS:
				# Alternate order to reduce systematic warmup/clock bias.
				for mode in ([false,true] if trial%2 == 0 else [true,false]):
					cache.reset()
					var begin := Time.get_ticks_usec(); work(old,cache,mode)
					(after if mode else before).append((Time.get_ticks_usec()-begin)/1000.0)
			before.sort(); after.sort()
			var row := {"kind":"query_cpu","actors":count,"dense":dense,"queries_per_trial":576,"runs":RUNS,"before_median_ms":before[RUNS/2],"after_median_ms":after[RUNS/2],"before_samples_ms":before,"after_samples_ms":after,"cache_hits":cache.hits,"requests":cache.requests,"bucket_reads":cache.bucket_reads}
			rows.append(row); print("PHASE1_BENCH ",JSON.stringify(row))
			for actor in actors: actor.free()
	var old = script.new(); var cache := CACHE.new()
	var before_unique: Array[float] = []; var after_unique: Array[float] = []
	for trial in RUNS:
		for mode in ([false,true] if trial%2 == 0 else [true,false]):
			cache.reset(); var begin := Time.get_ticks_usec(); work(old,cache,mode,false)
			(after_unique if mode else before_unique).append((Time.get_ticks_usec()-begin)/1000.0)
	before_unique.sort(); after_unique.sort()
	var unique_row := {"kind":"unique_empty_queries","queries_per_trial":576,"runs":RUNS,"before_median_ms":before_unique[RUNS/2],"after_median_ms":after_unique[RUNS/2],"before_samples_ms":before_unique,"after_samples_ms":after_unique,"cache_hits":cache.hits,"requests":cache.requests}
	rows.append(unique_row); print("PHASE1_BENCH ",JSON.stringify(unique_row))
	var file := FileAccess.open("user://combat_phase1_query_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"cpu_only":true,"rows":rows},"\t")); file.close()
	print("PHASE1_BENCH_PATH ",ProjectSettings.globalize_path("user://combat_phase1_query_benchmark.json")); quit()
