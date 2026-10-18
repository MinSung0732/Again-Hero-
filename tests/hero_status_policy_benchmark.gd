extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const DATA = preload("res://src/data/hero_presentation_catalog.gd")
class NullDraw extends RefCounted:
	func draw_rect(_rect: Rect2, _color: Color, _filled: bool):
		pass
func _initialize():
	call_deferred("run")
func sample(node, count):
	var keys = DATA.VISUAL_PROFILES.keys()
	var start = Time.get_ticks_usec()
	for iteration in range(count):
		for archetype in keys:
			node.hero_archetype = archetype
			node._draw_combat_status_overlay()
			node.bar_queries.clear()
	return float(Time.get_ticks_usec() - start) / float(count * keys.size())
func run():
	var a = BEFORE.new()
	var b = AFTER.new()
	root.add_child(a)
	root.add_child(b)
	a.status_overlay = NullDraw.new()
	b.status_overlay = NullDraw.new()
	sample(a, 100)
	sample(b, 100)
	var before: Array = []
	var after: Array = []
	for i in range(5):
		if i % 2 == 0:
			before.append(sample(a, 3000))
			after.append(sample(b, 3000))
		else:
			after.append(sample(b, 3000))
			before.append(sample(a, 3000))
	before.sort()
	after.sort()
	print("STATUS_CPU_ONLY before_us=%s after_us=%s delta_us=%s; null draw sink, no GPU/whole game" % [before[2], after[2], after[2] - before[2]])
	a.free()
	b.free()
	quit()
