extends SceneTree

const REGISTRY := preload("res://src/systems/battle_entity_registry.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var registry := REGISTRY.new()
	var a := Node2D.new()
	var b := Node2D.new()
	root.add_child(a)
	root.add_child(b)
	check(registry.activate(a) == Vector3i.ZERO, "no epoch no activation")
	check(not registry.begin_session(0), "zero epoch denied")
	check(not registry.begin_session(-1), "negative epoch denied")
	check(registry.begin_session(1), "start epoch")
	var first := registry.activate(a)
	var second := registry.activate(b)
	check(first.x == 1 and first.y > 0 and first.z == 1, "explicit transport handle")
	check(first != second and registry.active_count == 2, "distinct live identities")
	check(registry.activate(a) == first and registry.active_count == 2, "duplicate registration idempotent")
	check(registry.get_handle(a) == first and registry.resolve(first) == a, "constant-time lookup")
	for invalid in [Vector3i.ZERO, Vector3i(2, first.y, first.z), Vector3i(1, 0, 1), Vector3i(1, 99, 1), Vector3i(1, first.y, 0), Vector3i(1, first.y, first.z + 1)]:
		check(registry.resolve(invalid) == null and not registry.retire(invalid), "invalid handle")
	check(not registry.begin_session(1) and registry.resolve(first) == a, "same epoch cannot reset/revive")
	check(registry.retire(first), "retire life")
	check(not registry.retire(first) and registry.resolve(first) == null, "double retire / stale lookup")
	check(registry.get_handle(a) == Vector3i.ZERO and registry.active_count == 1, "retired node not live")
	var reused := registry.activate(a)
	check(reused.y == first.y and reused.z == first.z + 1, "pool activation increments generation")
	check(not registry.retire(first) and registry.resolve(reused) == a, "old callback cannot retire new life")
	for iteration in range(2000):
		var old := reused
		registry.retire(old)
		reused = registry.activate(a)
		if iteration % 100 == 0:
			check(registry.resolve(old) == null and registry.resolve(reused) == a, "repeated pool reuse")
			check(registry.snapshot().slot_count == 2 and registry.active_count == 2, "metadata bounded by concurrent peak")
	check(registry.begin_session(2), "restart")
	check(registry.resolve(reused) == null and registry.resolve(second) == null, "old epoch rejected")
	check(registry.snapshot().slot_count == 0 and registry.active_count == 0, "restart releases metadata")
	var current := registry.activate(a)
	check(current.x == 2 and current.y == 1 and current.z == 1, "new epoch compact slots")
	check(not registry.retire(reused) and registry.resolve(current) == a, "old epoch cannot affect reused slot")
	var freed := registry.activate(b)
	b.free()
	check(registry.resolve(freed) == null and registry.active_count == 1, "weak refs do not retain freed Node")
	var queued := Node2D.new()
	root.add_child(queued)
	var queued_handle := registry.activate(queued)
	queued.queue_free()
	check(registry.activate(queued) == Vector3i.ZERO, "queued node not reactivated")
	check(registry.resolve(queued_handle) == null, "queued deletion invalid immediately")
	check(registry.retire_instance(a.get_instance_id()), "local instance lookup retire")
	check(not registry.retire_instance(a.get_instance_id()) and registry.active_count == 0, "instance retire idempotent")
	check(not registry.begin_session(REGISTRY.MAX_COMPONENT + 1), "epoch overflow refused")
	check(registry.begin_session(3), "generation overflow fixture epoch")
	var last := registry.activate(a)
	registry._generations[last.y - 1] = REGISTRY.MAX_COMPONENT
	last.z = REGISTRY.MAX_COMPONENT
	check(registry.retire(last), "retire saturated generation")
	var next := registry.activate(a)
	check(next.y != last.y and next.z == 1, "saturated slot never wraps")
	check(registry.resolve(last) == null and registry.resolve(next) == a, "overflow no stale resurrection")
	a.free()
	check(registry.resolve(next) == null and registry.active_count == 0, "final weak reference cleanup")
	await process_frame
	print("battle_entity_registry_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
