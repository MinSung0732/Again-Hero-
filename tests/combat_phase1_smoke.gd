extends SceneTree
const CACHE := preload("res://src/systems/spatial_candidate_cache.gd")
const PROBE := preload("res://src/systems/combat_performance_probe.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var source := GDScript.new()
	source.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase1/battle_spatial.gd.txt")
	check(source.reload() == OK,"frozen original spatial methods compile")
	var old = source.new()
	var cache := CACHE.new()
	var host := Node2D.new(); root.add_child(host)
	var nodes: Array[Node2D] = []
	for i in 320:
		var actor := Node2D.new(); host.add_child(actor); nodes.append(actor)
		actor.position = Vector2((i%20-10)*113,(i/20-8)*107)
		var cell: Vector2i = old._spatial_cell_for_position(actor.position)
		if not old.monster_spatial_grid.has(cell): old.monster_spatial_grid[cell] = []
		old.monster_spatial_grid[cell].append(actor)
	var expected: Array = []; var actual: Array = []
	seed(1794680)
	for iteration in 400:
		var origin := Vector2(randf_range(-1300,1300),randf_range(-1300,1300))
		var radius := randf_range(0,800)
		var low: Vector2i = old._spatial_cell_for_position(origin-Vector2.ONE*radius)-Vector2i.ONE
		var high: Vector2i = old._spatial_cell_for_position(origin+Vector2.ONE*radius)+Vector2i.ONE
		old.fill_monsters_near(origin,radius,expected)
		cache.fill(old.monster_spatial_grid,low,high,iteration/40,actual)
		check(actual == expected,"exact original ordered circle candidates "+str(iteration))
		cache.fill(old.monster_spatial_grid,low,high,iteration/40,actual)
		check(actual == expected,"cache hit has identical order "+str(iteration))
		actual.clear(); actual.append(null)
		cache.fill(old.monster_spatial_grid,low,high,iteration/40,actual)
		check(actual == expected,"caller mutation never changes cache")
		check(cache.index.size() <= CACHE.CAPACITY and cache.entries.size() == CACHE.CAPACITY,"cache storage bounded")
		var rect := Rect2(origin,Vector2(radius*.7,radius*1.3))
		old.fill_monsters_in_rect(rect,expected)
		low = old._spatial_cell_for_position(rect.position)-Vector2i.ONE
		high = old._spatial_cell_for_position(rect.end)+Vector2i.ONE
		cache.fill(old.monster_spatial_grid,low,high,iteration/40,actual)
		check(actual == expected,"exact original ordered rectangle candidates")
	# Cached candidates still exclude queued/freed Nodes, without caching HP/visibility.
	var low := Vector2i(-8,-8); var high := Vector2i(8,8)
	cache.fill(old.monster_spatial_grid,low,high,100,actual)
	nodes[0].queue_free(); nodes[1].free()
	old.fill_monsters_near(Vector2.ZERO,1800,expected)
	cache.fill(old.monster_spatial_grid,low,high,100,actual)
	check(not actual.has(nodes[0]) and actual.size() == 318,"cached liveness rechecked")
	var newcomer := Node2D.new(); host.add_child(newcomer)
	old.monster_spatial_grid[Vector2i.ZERO].append(newcomer)
	cache.fill(old.monster_spatial_grid,low,high,101,actual)
	check(actual.has(newcomer),"snapshot revision reveals new pooled life/spawn")
	cache.enabled = false
	cache.fill(old.monster_spatial_grid,low,high,101,expected)
	check(actual == expected,"uncached rollback uses same candidate contract")
	var probe := PROBE.new(); probe.record_elapsed(PROBE.Scope.QUERY,100)
	check(probe.calls[PROBE.Scope.QUERY] == 0,"probe disabled by default")
	probe.start()
	for i in 600: probe.record_elapsed(PROBE.Scope.QUERY,i); probe.frame(.016)
	var report := probe.report()
	check(report.scopes.spatial_query.calls == 600 and report.scopes.spatial_query.retained_samples == 512,"probe bounded samples")
	check(report.scopes.spatial_query.max_us == 599 and report.scopes.spatial_query.p95_us == 574,"probe statistics exact")
	probe.stop(); probe.record_elapsed(PROBE.Scope.QUERY,9999)
	check(probe.calls[PROBE.Scope.QUERY] == 600,"disabled probe leaves counters unchanged")
	probe.start(); check(probe.calls[PROBE.Scope.QUERY] == 0 and probe.frame_count == 0,"new capture clears previous session")
	host.queue_free(); await process_frame
	print("COMBAT_PHASE1_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
