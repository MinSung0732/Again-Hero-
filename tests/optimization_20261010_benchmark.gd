extends SceneTree

# CPU microbenchmarks only; these are not Android FPS/GPU measurements.
const BUFFER := preload("res://src/systems/timed_event_buffer.gd")
const WARMUP := preload("res://src/systems/presentation_warmup.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const RUNS := 7
var results: Array = []


func _initialize() -> void:
	call_deferred("run")


func sample(label: String, work: Callable) -> void:
	work.call() # Warm-up excluded.
	var times: Array[float] = []
	for trial in range(RUNS):
		var started := Time.get_ticks_usec()
		work.call()
		times.append(float(Time.get_ticks_usec() - started) / 1000.0)
	times.sort()
	var row := {"label": label, "median_ms": times[RUNS / 2], "min_ms": times.front(), "max_ms": times.back(), "samples": times}
	results.append(row)
	print("OPT_BENCH " + JSON.stringify(row))


func prune_batch(count: int, optimized: bool) -> void:
	var array: Array = []
	var buffer := BUFFER.new()
	for i in range(count):
		var event := {"time": float(i)}
		if optimized:
			buffer.append(event)
		else:
			array.append(event)
	if optimized:
		buffer.prune_before(INF)
	else:
		while not array.is_empty():
			array.pop_front()


func rolling_window(count: int, optimized: bool) -> void:
	var array: Array = []
	var buffer := BUFFER.new()
	for i in range(count):
		var event := {"time": float(i)}
		var cutoff := float(i - 1024)
		if optimized:
			buffer.append(event)
			buffer.prune_before(cutoff)
		else:
			array.append(event)
			while not array.is_empty() and float(array[0].time) < cutoff:
				array.pop_front()


func old_unique(paths: Array[String]) -> void:
	var unique: Array[String] = []
	for path in paths:
		if not path.is_empty() and not unique.has(path):
			unique.append(path)


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	for count in [1024, 8192, 32768]:
		sample("prune_%d_before" % count, prune_batch.bind(count, false))
		sample("prune_%d_after" % count, prune_batch.bind(count, true))
	sample("rolling_32768_before", rolling_window.bind(32768, false))
	sample("rolling_32768_after", rolling_window.bind(32768, true))
	for count in [128, 1024, 4096]:
		var paths: Array[String] = []
		for i in range(count):
			paths.append("res://test/texture_%d.png" % (i % (count * 3 / 4)))
		sample("dedupe_%d_before" % count, old_unique.bind(paths))
		sample("dedupe_%d_after" % count, func(): WARMUP.unique_paths(paths))
	var old_pool := GDScript.new()
	old_pool.source_code = FileAccess.get_file_as_string("res://tests/fixtures/optimization_20261010/damage_number_spawner.gd.txt")
	if old_pool.reload() != OK:
		quit(1)
		return
	var host := Node2D.new()
	var pool: Array = []
	for i in range(48):
		var node := Node2D.new()
		host.add_child(node)
		pool.append(node)
	host.set_meta(POPUPS.POOL_META, pool)
	sample("popup_pool_20000_before", func():
		for i in range(20000): old_pool._get_compacted_pool(host))
	sample("popup_pool_20000_after", func():
		for i in range(20000): POPUPS._get_compacted_pool(host))
	host.free()
	var payload := {"engine": Engine.get_version_info().string, "platform": OS.get_name(), "display": DisplayServer.get_name(), "runs": RUNS, "rows": results}
	var output := FileAccess.open("user://optimization_20261010_benchmark.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(payload, "\t"))
	output.close()
	print("OPT_BENCH_PATH " + ProjectSettings.globalize_path("user://optimization_20261010_benchmark.json"))
	quit()
