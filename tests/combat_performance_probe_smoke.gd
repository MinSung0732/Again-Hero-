extends SceneTree
## The monster hot path needs frame aggregates, not just single-call p95 values.
const PROBE := preload("res://src/systems/combat_performance_probe.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT_PROBE: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var probe := PROBE.new()
	var monster := PROBE.Scope.MONSTER_PHYSICS
	var separation := PROBE.Scope.SEPARATION
	probe.start()
	probe.record_elapsed(monster,100)
	probe.record_elapsed(monster,200)
	probe.record_elapsed(separation,50)
	probe.frame(0.016)
	probe.record_elapsed(monster,25)
	probe.frame(0.018)
	var report := probe.report()
	var scope: Dictionary = report.scopes.monster_base_physics
	check(scope.calls == 3 and scope.total_us == 325,"existing per-call totals preserved")
	check(scope.p95_us == 200 and scope.max_us == 200,"existing single-call percentiles preserved")
	check(is_equal_approx(float(scope.frame_mean_us),162.5),"frame average sums monster instances")
	check(scope.frame_p95_us == 300 and scope.frame_max_us == 300,"frame spike captures all monster calls")
	var other: Dictionary = report.scopes.monster_separation
	check(other.frame_p95_us == 50 and other.frame_max_us == 50,"nested scope separately reported")
	check(report.nested_scopes_overlap,"nested timings must not be added")
	probe.stop()
	probe.record_elapsed(monster,1000)
	check(probe.report().scopes.monster_base_physics.total_us == 325,"stopped probe records nothing")
	probe.start()
	probe.frame(0.016)
	scope = probe.report().scopes.monster_base_physics
	check(scope.calls == 0 and scope.frame_max_us == 0 and scope.frame_p95_us == 0,"restart resets aggregates")
	print("COMBAT_PROBE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
