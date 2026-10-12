extends RefCounted
const DATA := preload("res://src/data/lizardman_fighter_behavior_catalog.gd")
const VISUAL := preload("res://src/monsters/monster_visual.gd")
var battle: Node2D
var eaters: Dictionary = {}
var active: Dictionary = {}
var spare: Array = []
var expired: Array[int] = []

func setup(authority: Node2D) -> void:
	battle = authority

func reset() -> void:
	for state in active.values():
		var node = state.visual
		if is_instance_valid(node): node.queue_free()
	for node in spare:
		if is_instance_valid(node): node.queue_free()
	active.clear()
	spare.clear()
	eaters.clear()
	expired.clear()

func register_eater(actor: Node2D) -> void:
	eaters[actor.get_instance_id()] = weakref(actor)
	# Registration and creation are events; no per-frame whole-army search.
	for tail_id in active.keys():
		_try_consume(int(tail_id))

func unregister_eater(actor: Node) -> void:
	eaters.erase(actor.get_instance_id())

func spawn_tail(point: Vector2, facing: int = 1) -> int:
	if not is_instance_valid(battle): return 0
	var node = spare.pop_back() if not spare.is_empty() else VISUAL.new()
	if node.get_parent() == null:
		battle.add_child(node)
		node.apply_visual_profile(DATA.TAIL_VISUAL)
	node.global_position = point
	node.flip_h = facing < 0
	node.show()
	node.set_meta("lizard_tail",true)
	node.play("idle")
	node.set_frame_and_progress(0,0.0)
	var id: int = node.get_instance_id()
	active[id] = {"visual":node,"elapsed":0.0,"point":point}
	_try_consume(id)
	return id

func _try_consume(tail_id: int) -> void:
	if not active.has(tail_id): return
	var state: Dictionary = active[tail_id]
	var nearest: Node2D
	var distance := INF
	for id in eaters:
		var actor = eaters[id].get_ref()
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or int(actor.get("current_hp")) <= 0: continue
		var d: float = actor.global_position.distance_squared_to(state.point)
		if nearest == null or d < distance or (is_equal_approx(d,distance) and actor.get_instance_id() < nearest.get_instance_id()):
			nearest = actor
			distance = d
	if nearest != null:
		_recycle(tail_id)
		nearest.call("consume_lizard_tail")

func _recycle(tail_id: int) -> void:
	if not active.has(tail_id): return
	var node = active[tail_id].visual
	active.erase(tail_id)
	if is_instance_valid(node):
		node.hide()
		node.stop()
		spare.append(node)

func tick(delta: float) -> void:
	expired.clear()
	for id in active:
		var state: Dictionary = active[id]
		state.elapsed += delta
		var node = state.visual
		if not is_instance_valid(node) or state.elapsed >= DATA.TAIL_LIFETIME:
			expired.append(int(id))
			continue
		node.visible = state.elapsed < DATA.TAIL_BLINK_START or int((state.elapsed-DATA.TAIL_BLINK_START)/DATA.TAIL_BLINK_SECONDS) % 2 == 0
	for id in expired: _recycle(id)
