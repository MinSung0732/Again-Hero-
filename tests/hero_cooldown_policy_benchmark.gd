extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")
func _initialize(): call_deferred("run")
func sample(node, count):
	var archetypes = BINDINGS.PROPERTY_COOLDOWNS.keys()
	archetypes.append("archmage_elementalist")
	var start = Time.get_ticks_usec()
	for i in range(count):
		for archetype in archetypes:
			node.hero_archetype = archetype
			node._tick_fear_skill_cooldowns(0.016)
			node.trace.clear()
	return float(Time.get_ticks_usec() - start) / float(count * archetypes.size())
func run():
	var a = BEFORE.new()
	var b = AFTER.new()
	root.add_child(a)
	root.add_child(b)
	for node in [a, b]:
		for profile in BINDINGS.PROPERTY_COOLDOWNS.values():
			for property in profile.properties:
				node.timers[property] = 3.0
	sample(a, 100)
	sample(b, 100)
	var before: Array = []
	var after: Array = []
	for i in range(5):
		if i % 2 == 0:
			before.append(sample(a, 2000))
			after.append(sample(b, 2000))
		else:
			after.append(sample(b, 2000))
			before.append(sample(a, 2000))
	before.sort()
	after.sort()
	print("COOLDOWN_CPU_ONLY before_us=%s after_us=%s delta_us=%s; synthetic properties/trace, no whole game" % [before[2], after[2], after[2] - before[2]])
	a.free()
	b.free()
	quit()
